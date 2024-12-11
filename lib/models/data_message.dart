import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/utils/safe_parser.dart';

class DataMessage {
  static const String tableName = 'encrypted_message';
  static late Database database;
  final String id;
  final String sender;
  final String plainText;
  final String receiver;
  final int createdAt;
  final String? replyId;

  DataMessage({
    required this.id,
    required this.plainText,
    required this.sender,
    required this.receiver,
    required this.createdAt,
    this.replyId,
  });

  static Future<void> init() async {
    final dbpath = join(await getDatabasesPath(), '$tableName.db');
    // await deleteDatabase(dbpath);
    DataMessage.database = await openDatabase(
      dbpath,
      onCreate: (db, version) async {
        print('onCreate');
        await db.execute(
            'CREATE TABLE $tableName(id TEXT PRIMARY KEY, plain_text TEXT, sender TEXT, receiver TEXT, reply_id TEXT, created_at INTEGER, sig TEXT)');
        await db.execute(
            'CREATE UNIQUE INDEX ${tableName}_id_idx ON $tableName (id);');
        await db.execute(
            'CREATE INDEX ${tableName}_sender_idx ON $tableName (sender);');
        await db.execute(
            'CREATE INDEX ${tableName}_receiver_idx ON $tableName (receiver);');
        await db.execute(
            'CREATE INDEX ${tableName}_sender_receiver_idx ON $tableName (sender,receiver);');
      },
      version: 1,
    );
  }

  factory DataMessage.fromMap(Map<String, Object?> data) {
    return DataMessage(
      id: SafeParser.parseString(data['id'])!,
      plainText: SafeParser.parseString(data['plain_text'])!,
      sender: SafeParser.parseString(data['sender'])!,
      receiver: SafeParser.parseString(data['receiver'])!,
      replyId: SafeParser.parseString(data['reply_id']),
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
      "receiver": receiver,
      "created_at": createdAt,
      "reply_id": replyId
    };
  }

  // Convert a Dog into a Map. The keys must correspond to the names of the
  // columns in the database.
  String toSqlInsert() {
    return 'INSERT INTO encrypted_message("$id","$plainText","$sender","$receiver","$replyId",$createdAt)';
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
        if (replyId?.isNotEmpty == true) ["e", replyId!],
        ["p", receiver]
      ],
    );
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'EncryptedMessage{"id":"$id","plain_text":"$plainText","sender":"$sender","receiver":"$receiver","reply_id":"$replyId","created_at":$createdAt}';
  }
}
