import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

const secretStorageKey = '_sec';
const secretStorageName = 'nostr-secret';

IOSOptions _getIOSOptions() => const IOSOptions(
      accountName: secretStorageName,
      accessibility: KeychainAccessibility.passcode,
    );

AndroidOptions _getAndroidOptions() => const AndroidOptions(
      sharedPreferencesName: secretStorageName,
      encryptedSharedPreferences: true,
    );

class AppSecret with ChangeNotifier {
  static final LocalAuthentication auth = LocalAuthentication();
  static FlutterSecureStorage secureStorage = FlutterSecureStorage(
      iOptions: _getIOSOptions(), aOptions: _getAndroidOptions());

  static Future<NostrKeyPairs?> read() async {
    String? privateKey =
        await secureStorage.read(key: secretStorageKey).catchError((err) {
      secureStorage.delete(key: secretStorageKey);
      print('readPrivateKey: $err');
    });
    if (privateKey == null) return null;
    return Nostr.instance.keysService
        .generateKeyPairFromExistingPrivateKey(privateKey);
  }

  static Future<void> write(String privateKey) async {
    await secureStorage
        .write(value: privateKey, key: secretStorageKey)
        .catchError((err) => print('writePrivateKey: $err'));
  }

  static Future<void> delete() async {
    return secureStorage
        .delete(key: secretStorageKey)
        .catchError((err) => print('_deletePrivateKey: $err'));
  }
}
