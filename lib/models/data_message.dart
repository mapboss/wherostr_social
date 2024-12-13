import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/utils/safe_parser.dart';
import 'package:isar/isar.dart';

part 'data_message.g.dart';

@collection
class DataMessage {
  Id id = Isar.autoIncrement;

  static const String tableName = 'encrypted_message';

  @Index(unique: true, replace: true)
  String eventId;

  @Index(unique: false)
  String sender;

  String plainText;

  @Index(unique: false)
  String receiver;

  @Index(unique: false)
  int createdAt;

  String? replyId;

  DataMessage({
    required this.eventId,
    required this.plainText,
    required this.sender,
    required this.receiver,
    required this.createdAt,
    this.replyId,
  });

  factory DataMessage.fromMap(Map<String, Object?> data) {
    return DataMessage(
      eventId: SafeParser.parseString(data['id'])!,
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
      "event_id": eventId,
      "plain_text": plainText,
      "sender": sender,
      "receiver": receiver,
      "created_at": createdAt,
      "reply_id": replyId
    };
  }

  // Convert a Dog into a Map. The keys must correspond to the names of the
  // columns in the database.
  DataEvent toEvent() {
    return DataEvent(
      id: eventId,
      kind: 14,
      pubkey: sender,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      content: plainText,
      tags: [
        ["p", receiver],
        if (replyId?.isNotEmpty == true) ["e", replyId!, '', 'reply'],
      ],
    );
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'EncryptedMessage{"event_id":"$eventId","plain_text":"$plainText","sender":"$sender","receiver":"$receiver","reply_id":"$replyId","created_at":$createdAt}';
  }
}
