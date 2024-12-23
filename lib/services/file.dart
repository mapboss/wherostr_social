import 'dart:convert';
import 'dart:io';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:wherostr_social/models/imeta_tag.dart';
import 'package:wherostr_social/nips/nip096.dart';
import 'package:wherostr_social/nips/nip098.dart';

const mediaServer = 'https://nostr.build';

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

  static Future<XFile?> pickAMedia() async {
    final file = await _imagePicker.pickMedia();
    return file;
  }

  static Future<List<IMetaTag>> uploadMultiple(
      List<File> files, NostrKeyPairs keyPairs) async {
    final nip96Request = http.MultipartRequest(
        'GET', Uri.parse('$mediaServer/.well-known/nostr/nip96.json'));
    final nip96Response =
        await http.Response.fromStream(await nip96Request.send());
    if (nip96Response.statusCode != 200) {
      throw Exception('Failed to upload files');
    }
    final server = Nip96.decodeServerAdaptation(nip96Response.body);
    final httpAuth = Nip98.base64Event(server.apiURL!, 'POST', keyPairs);
    final futures = files.map((file) async {
      final request = http.MultipartRequest('POST', Uri.parse(server.apiURL!));
      request.headers['Authorization'] = 'Nostr $httpAuth';
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
            'file',
            img.encodePng(resizedImage),
            filename: 'resized_image.png',
          ));
        }
      } catch (error) {}
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final imeta = IMetaTag.fromNIP94(jsonResponse['nip94_event']);
        return imeta;
      }
    });
    final urls = await Future.wait(futures);
    return urls.whereType<IMetaTag>().toList();
  }
}
