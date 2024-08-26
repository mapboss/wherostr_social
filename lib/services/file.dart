import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:wherostr_social/models/nip92.dart';

const uploadServiceUrl = 'https://nostr.build/api/v2/upload/files';

class FileService {
  static final _imagePicker = ImagePicker();

  static Future<XFile?> pickAPhoto() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    return file;
  }

  static Future<XFile?> takeAPhoto() async {
    final file = await _imagePicker.pickImage(source: ImageSource.camera);
    return file;
  }

  static Future<List<IMetadata>> uploadMultiple(List<File> files) async {
    final request = http.MultipartRequest('POST', Uri.parse(uploadServiceUrl));
    for (var file in files) {
      request.files.add(await http.MultipartFile.fromPath('file[]', file.path));
    }
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final List<IMetadata> urls = [];
      for (var item in jsonResponse['data']) {
        urls.add(IMetadata.fromNostrBuildAPI(item));
      }
      return urls;
    } else {
      throw Exception('Failed to upload files');
    }
  }
}
