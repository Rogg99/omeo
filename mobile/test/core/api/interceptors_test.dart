import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/global_errors.dart';
import 'package:omeo/core/api/interceptors.dart';
import 'package:omeo/core/api/token_store.dart';

/// Serveur factice : répond selon le jeton reçu.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body, {Map<String, String>? headers}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/problem+json'],
        for (final h in (headers ?? {}).entries) h.key: [h.value],
      },
    );

Map<String, Object> _problem(
  int status,
  String code, [
  Map<String, Object>? meta,
]) => {
  'type': 'https://my-omeo.app/errors/$code',
  'title': code,
  'status': status,
  'code': code,
  'meta': ?meta,
};

void main() {
  late MemoryTokenStore tokens;
  late GlobalErrorBus bus;
  late List<GlobalErrorEvent> events;

  setUp(() async {
    tokens = MemoryTokenStore();
    await tokens.write((access: 'old', refresh: 'r1'));
    bus = GlobalErrorBus();
    events = [];
    bus.events.listen(events.add);
  });

  Dio buildDio(_FakeAdapter adapter, RefreshCall refresh) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    dio.interceptors.addAll([
      ClientHeadersInterceptor(
        languageTag: () => 'fr',
        timezone: () => 'Africa/Abidjan',
        clientId: 'mobile/1.0.0 (test)',
      ),
      AuthInterceptor(dio: dio, tokens: tokens, refresh: refresh, errors: bus),
      GlobalErrorInterceptor(bus),
    ]);
    return dio;
  }

  test('en-têtes communs et jeton sur chaque requête', () async {
    final adapter = _FakeAdapter((_) => _json(200, {'ok': true}));
    final dio = buildDio(adapter, (_) async => throw StateError('inutile'));
    await dio.get<Object?>('/me');
    final h = adapter.requests.single.headers;
    expect(h['Authorization'], 'Bearer old');
    expect(h['Accept-Language'], 'fr');
    expect(h['X-Timezone'], 'Africa/Abidjan');
    expect(h['X-Client'], 'mobile/1.0.0 (test)');
  });

  test(
    'token_expired : un seul refresh pour des requêtes simultanées',
    () async {
      var refreshCalls = 0;
      final adapter = _FakeAdapter(
        (o) => o.headers['Authorization'] == 'Bearer new'
            ? _json(200, {'ok': true})
            : _json(401, _problem(401, 'token_expired')),
      );
      final dio = buildDio(adapter, (refresh) async {
        refreshCalls++;
        expect(refresh, 'r1');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return (access: 'new', refresh: 'r2');
      });

      final results = await Future.wait([
        dio.get<Object?>('/me/home'),
        dio.get<Object?>('/me/quotas'),
        dio.get<Object?>('/me/notifications'),
      ]);

      expect(results.map((r) => r.statusCode), everyElement(200));
      expect(refreshCalls, 1);
      expect(await tokens.read(), (access: 'new', refresh: 'r2'));
    },
  );

  test('refresh refusé : déconnexion propre', () async {
    final adapter = _FakeAdapter(
      (_) => _json(401, _problem(401, 'token_expired')),
    );
    final dio = buildDio(adapter, (_) async => throw StateError('révoqué'));
    await expectLater(dio.get<Object?>('/me'), throwsA(isA<DioException>()));
    await pumpEventQueue();
    expect(await tokens.read(), isNull);
    expect(events, [isA<SignedOut>()]);
  });

  test('not_authenticated : déconnexion sans refresh', () async {
    var refreshCalls = 0;
    final adapter = _FakeAdapter(
      (_) => _json(401, _problem(401, 'not_authenticated')),
    );
    final dio = buildDio(adapter, (_) async {
      refreshCalls++;
      return (access: 'x', refresh: 'y');
    });
    await expectLater(dio.get<Object?>('/me'), throwsA(isA<DioException>()));
    await pumpEventQueue();
    expect(refreshCalls, 0);
    expect(await tokens.read(), isNull);
    expect(events.whereType<SignedOut>(), hasLength(1));
  });

  test('codes globaux publiés sur le bus', () async {
    final responses = [
      _json(426, _problem(426, 'upgrade_required')),
      _json(403, _problem(403, 'plan_required', {'feature': 'voice_input'})),
      _json(
        429,
        _problem(429, 'quota_exceeded', {
          'feature': 'photo_analysis',
          'resets_at': '2026-11-10T00:00:00Z',
          'upgrade': true,
        }),
      ),
      _json(
        403,
        _problem(403, 'consent_required', {
          'documents': ['terms'],
        }),
      ),
      _json(
        403,
        _problem(403, 'account_suspended', {
          'support_url': 'https://my-omeo.app/support',
        }),
      ),
      _json(422, _problem(422, 'analysis_rejected', {'reason': 'blurry'})),
    ];
    var i = 0;
    final dio = buildDio(
      _FakeAdapter((_) => responses[i++]),
      (_) async => throw StateError('inutile'),
    );
    for (var n = 0; n < responses.length; n++) {
      await expectLater(dio.get<Object?>('/x'), throwsA(isA<DioException>()));
    }
    await pumpEventQueue();
    expect(events, [
      isA<UpgradeRequired>(),
      isA<PlanRequired>().having((e) => e.feature, 'feature', 'voice_input'),
      isA<QuotaExceeded>()
          .having((e) => e.canUpgrade, 'canUpgrade', isTrue)
          .having((e) => e.resetsAt, 'resetsAt', DateTime.utc(2026, 11, 10)),
      isA<ConsentRequired>().having((e) => e.documents, 'documents', ['terms']),
      isA<AccountSuspended>(),
    ]);
  });

  group('failureFromDio', () {
    RequestOptions req() => RequestOptions(path: '/x');

    test('problem+json avec Retry-After et erreurs par champ', () {
      final f = failureFromDio(
        DioException(
          requestOptions: req(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: req(),
            statusCode: 400,
            headers: Headers.fromMap({
              'retry-after': ['30'],
            }),
            data: {
              ..._problem(400, 'validation_error'),
              'errors': {
                'email': [
                  {'code': 'invalid', 'message': 'Email invalide'},
                ],
              },
            },
          ),
        ),
      );
      expect(f, isA<ProblemFailure>());
      f as ProblemFailure;
      expect(f.code, 'validation_error');
      expect(f.fieldErrors, {
        'email': ['invalid'],
      });
      expect(f.retryAfter, const Duration(seconds: 30));
    });

    test('corps illisible : erreur serveur', () {
      final f = failureFromDio(
        DioException(
          requestOptions: req(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: req(),
            statusCode: 502,
            data: '<html>',
          ),
        ),
      );
      expect(f.code, 'server_error');
    });

    test('réseau et délai', () {
      expect(
        failureFromDio(
          DioException(
            requestOptions: req(),
            type: DioExceptionType.connectionError,
          ),
        ),
        isA<NetworkFailure>(),
      );
      expect(
        failureFromDio(
          DioException(
            requestOptions: req(),
            type: DioExceptionType.receiveTimeout,
          ),
        ),
        isA<TimeoutFailure>(),
      );
    });
  });
}
