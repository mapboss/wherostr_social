import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/utils/safe_parser.dart';

class DataMessage {
  static final String tableName = 'encrypted_message';
  static late Database database;
  final String id;
  final String sender;
  final String plainText;
  final String reciever;
  final int createdAt;

  DataMessage({
    required this.id,
    required this.plainText,
    required this.sender,
    required this.reciever,
    required this.createdAt,
  });

  static Future<void> init() async {
    final dbpath = join(await getDatabasesPath(), '$tableName.db');
    // await deleteDatabase(dbpath);
    DataMessage.database = await openDatabase(
      dbpath,
      onCreate: (db, version) async {
        print('onCreate');
        await db.execute(
            'CREATE TABLE $tableName(id TEXT PRIMARY KEY, plain_text TEXT, sender TEXT, reciever TEXT, created_at INTEGER, sig TEXT)');
        await db.execute(
            'CREATE UNIQUE INDEX ${tableName}_id_idx ON $tableName (id);');
        await db.execute(
            'CREATE INDEX ${tableName}_sender_idx ON $tableName (sender);');
        await db.execute(
            'CREATE INDEX ${tableName}_reciever_idx ON $tableName (reciever);');
        await db.execute(
            'CREATE INDEX ${tableName}_sender_reciever_idx ON $tableName (sender,reciever);');
      },
      version: 1,
    );
  }

  factory DataMessage.fromMap(Map<String, Object?> data) {
    return DataMessage(
      id: SafeParser.parseString(data['id'])!,
      plainText: SafeParser.parseString(data['plain_text'])!,
      sender: SafeParser.parseString(data['sender'])!,
      reciever: SafeParser.parseString(data['reciever'])!,
      createdAt: SafeParser.parseInt(data['created_at'])!,
    );
  }

  // Convert a Dog into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, Object?> toMap() {
    return {
      "id": id,
      "plain_text": plainText,
      "sender": sender,
      "reciever": reciever,
      "created_at": createdAt,
    };
  }

  // Convert a Dog into a Map. The keys must correspond to the names of the
  // columns in the database.
  String toSqlInsert() {
    return 'INSERT INTO encrypted_message("$id","$plainText","$sender","$reciever",$createdAt)';
  }

  // Convert a Dog into a Map. The keys must correspond to the names of the
  // columns in the database.
  DataEvent toEvent() {
    return DataEvent(
      id: id,
      kind: 14,
      pubkey: sender,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      content: plainText,
      tags: [
        ["p", reciever]
      ],
    );
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'EncryptedMessage{"id":"$id","plain_text":"$plainText","sender":"$sender","reciever":"$reciever","created_at":$createdAt}';
  }
}
