import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Petit stockage clé-valeur local (réglages d'affichage, brouillon de
/// l'onboarding). Chiffré : le brouillon contient des données de santé
/// (poids, date de naissance) avant même la création du compte.
abstract interface class LocalStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Trousseau iOS ou Keystore Android.
final class SecureLocalStore implements LocalStore {
  SecureLocalStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Stockage en mémoire (flavor mock et tests).
final class MemoryLocalStore implements LocalStore {
  MemoryLocalStore([Map<String, String>? initial]) : _values = {...?initial};

  final Map<String, String> _values;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

final localStoreProvider = Provider<LocalStore>((ref) => SecureLocalStore());
