import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wherostr_social/models/data_message.dart';

class MessageService {
  static late Isar isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    MessageService.isar = Isar.openSync(
      [DataMessageSchema],
      directory: dir.path,
    );
  }
}
