import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:wherostr_social/models/custom_keypairs.dart';

const secretStorageKey = '_sec';
const nwcStorageKey = '_nwc';
const secretStorageName = 'nostr-secret';

IOSOptions _getIOSOptionsV1() => const IOSOptions(
      accountName: secretStorageName,
      accessibility: KeychainAccessibility.passcode,
    );

IOSOptions _getIOSOptions() => const IOSOptions(
      accountName: secretStorageName,
      accessibility: KeychainAccessibility.unlocked,
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
    String? privateKey = await secureStorage.read(key: secretStorageKey);
    if (privateKey == null) {
      String? oldPrivateKey = await secureStorage.read(
        key: secretStorageKey,
        iOptions: _getIOSOptionsV1(),
      );
      privateKey = oldPrivateKey;
    }
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
        .catchError((err) async {
      await clear();
      await write(privateKey);
    });
  }

  static Future<void> writeCustomKeyPairs(NostrKeyPairs customKeyPairs) async {
    print(
        'writeCustomKeyPairs: ${customKeyPairs.private}|${customKeyPairs.public}');
    await secureStorage
        .write(
            value: '${customKeyPairs.private}|${customKeyPairs.public}',
            key: secretStorageKey)
        .catchError((err) => print('writeCustomKeyPairs: $err'));
  }

  static Future<void> delete() async {
    return secureStorage
        .delete(key: secretStorageKey)
        .catchError((err) => print('deletePrivateKey: $err'));
  }

  static Future<void> clear() async {
    await Future.wait(KeychainAccessibility.values.map((e) {
      return secureStorage
          .delete(
            key: secretStorageKey,
            iOptions: IOSOptions(
              accountName: secretStorageName,
              accessibility: e,
            ),
          )
          .catchError((err) => print('deletePrivateKey: $err'));
    }));
  }

  static Future<void> writeNWC(String key) async {
    await secureStorage
        .write(value: key, key: nwcStorageKey)
        .catchError((err) async {
      await clear();
      await writeNWC(key);
    });
  }

  static Future<String?> readNWC() async {
    String? key = await secureStorage.read(key: nwcStorageKey);
    if (key == null) {
      String? oldKey = await secureStorage.read(
        key: nwcStorageKey,
        iOptions: _getIOSOptionsV1(),
      );
      key = oldKey;
    }
    return key;
  }

  static Future<void> deleteNWC() async {
    return secureStorage
        .delete(key: nwcStorageKey)
        .catchError((err) => print('deleteNWC: $err'));
  }

  static Future<void> clearNWC() async {
    await Future.wait(KeychainAccessibility.values.map((e) {
      return secureStorage
          .delete(
            key: nwcStorageKey,
            iOptions: IOSOptions(
              accountName: secretStorageName,
              accessibility: e,
            ),
          )
          .catchError((err) => print('clearNWC: $err'));
    }));
  }
}
