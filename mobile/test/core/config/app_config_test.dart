import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/config/app_config.dart';

void main() {
  final pin = 'a' * 64;
  final backup = 'b' * 64;

  AppConfig config(Flavor flavor, String url, List<String> pins) => AppConfig(
    flavor: flavor,
    dataSource: DataSource.api,
    apiBaseUrl: url,
    pinnedCertificates: pins,
  );

  test('mock et dev démarrent sans épinglage', () {
    expect(
      () => const AppConfig(
        flavor: Flavor.mock,
        dataSource: DataSource.mock,
        apiBaseUrl: '',
      ).validate(),
      returnsNormally,
    );
    expect(
      () => config(Flavor.dev, 'http://10.0.2.2/api/v1', []).validate(),
      returnsNormally,
    );
  });

  test('prod exige HTTPS et deux empreintes valides', () {
    const url = 'https://api.my-omeo.app/api/v1';
    expect(
      () => config(Flavor.prod, url, [pin, backup]).validate(),
      returnsNormally,
    );
    expect(() => config(Flavor.prod, url, [pin]).validate(), throwsStateError);
    expect(
      () => config(Flavor.prod, url, [pin, 'A_RENSEIGNER']).validate(),
      throwsStateError,
    );
    expect(
      () => config(Flavor.staging, 'http://api.my-omeo.app', [
        pin,
        backup,
      ]).validate(),
      throwsStateError,
    );
  });

  test('dev sans URL refusé', () {
    expect(() => config(Flavor.dev, '', []).validate(), throwsStateError);
  });

  test('outils de développement en mock et dev seulement', () {
    expect(config(Flavor.dev, 'x', []).devToolsEnabled, isTrue);
    expect(config(Flavor.prod, 'x', []).devToolsEnabled, isFalse);
  });
}
