import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:wherostr_social/models/imeta_tag.dart';

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

  static Future<List<IMetaTag>> uploadMultiple(List<File> files) async {
    final request = http.MultipartRequest('POST', Uri.parse(uploadServiceUrl));
    for (var file in files) {
      try {
        final image = await img.decodeImageFile(file.path);
        img.Image? resizedImage;
        if (image != null &&
            image.height > image.width &&
            image.height > 1920) {
          resizedImage = img.copyResize(image, height: 1920);
        } else if (image != null && image.width > 1920) {
          resizedImage = img.copyResize(image, width: 1920);
        }
        if (resizedImage != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'file[]',
            img.encodePng(resizedImage),
            filename: 'resized_image.png',
          ));
          continue;
        }
      } catch (error) {}
      request.files.add(await http.MultipartFile.fromPath('file[]', file.path));
    }
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final List<IMetaTag> urls = [];
      for (var item in jsonResponse['data']) {
        urls.add(IMetaTag.fromNostrBuildAPI(item));
      }
      return urls;
    } else {
      throw Exception('Failed to upload files');
    }
  }
}
