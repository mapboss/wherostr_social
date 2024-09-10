import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:wherostr_social/models/custom_keypairs.dart';

const secretStorageKey = '_sec';
const nwcStorageKey = '_nwc';
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
    final splitKeys = privateKey.split('|');
    final sec = splitKeys.elementAt(0);
    final pub = splitKeys.elementAtOrNull(1);
    if (pub?.isEmpty ?? true) {
      return Nostr.instance.keysService
          .generateKeyPairFromExistingPrivateKey(sec);
    } else {
      final keyPairs = CustomKeyPairs(private: sec, public: pub!);
      return keyPairs;
    }
  }

  static Future<void> write(String privateKey) async {
    await secureStorage
        .write(value: privateKey, key: secretStorageKey)
        .catchError((err) => print('writePrivateKey: $err'));
  }

  static Future<void> writeCustomKeyPairs(NostrKeyPairs customKeyPairs) async {
    print(
        'writeCustomKeyPairs: ${customKeyPairs.private}|${customKeyPairs.public}');
    await secureStorage
        .write(
            value: '${customKeyPairs.private}|${customKeyPairs.public}',
            key: secretStorageKey)
        .catchError((err) => print('writePrivateKey: $err'));
  }

  static Future<void> delete() async {
    return secureStorage
        .delete(key: secretStorageKey)
        .catchError((err) => print('_deletePrivateKey: $err'));
  }

  static Future<void> writeNWC(String privateKey) async {
    await secureStorage
        .write(value: privateKey, key: nwcStorageKey)
        .catchError((err) => print('writePrivateKey: $err'));
  }

  static Future<String?> readNWC() async {
    return secureStorage.read(key: nwcStorageKey).catchError((err) {
      secureStorage.delete(key: nwcStorageKey);
      print('readNWC: $err');
    });
  }

  static Future<void> deleteNWC() async {
    return secureStorage
        .delete(key: nwcStorageKey)
        .catchError((err) => print('_deletePrivateKey: $err'));
  }
}
