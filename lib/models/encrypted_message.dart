import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class EncryptedMessage {
  static late Database database;
  final String id;
  final String sender;
  final String encryptedContent;
  final String reciever;
  final int createdAt;
  final String sig;

  EncryptedMessage({
    required this.id,
    required this.encryptedContent,
    required this.sender,
    required this.reciever,
    required this.createdAt,
    required this.sig,
  });

  static Future<void> init() async {
    final dbpath = join(await getDatabasesPath(), 'encrypted_message.db');
    await deleteDatabase(dbpath);
    EncryptedMessage.database = await openDatabase(
      dbpath,
      onCreate: (db, version) async {
        print('onCreate');
        await db.execute('''BEGIN;
CREATE TABLE encrypted_message(id TEXT PRIMARY KEY, encryptedContent TEXT, sender TEXT, reciever TEXT, createdAt INTEGER, sig TEXT);
CREATE UNIQUE INDEX encrypted_message_id_idx ON encrypted_message (id);
CREATE INDEX encrypted_message_sender_idx ON encrypted_message (sender);
CREATE INDEX encrypted_message_reciever_idx ON encrypted_message (reciever);
CREATE INDEX encrypted_message_sender_reciever_idx ON encrypted_message (sender,reciever);
COMMIT;''');
      },
      version: 1,
    );
  }

  // Convert a Dog into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, Object?> toMap() {
    return {
      "id": id,
      "encryptedContent": encryptedContent,
      "sender": sender,
      "reciever": reciever,
      "createdAt": createdAt,
      "sig": sig,
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'EncryptedMessage{"id":"$id","encryptedContent":"$encryptedContent","sender":"$sender","reciever":"$reciever","createdAt":$createdAt,"sig":"$sig"}';
  }
}
