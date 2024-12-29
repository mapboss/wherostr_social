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
      List<File> files, NostrKeyPairs? keyPairs) async {
    keyPairs = keyPairs ?? NostrKeyPairs.generate();
    final nip96Request = http.MultipartRequest(
        'GET', Uri.parse('$mediaServer/.well-known/nostr/nip96.json'));
    final nip96Response =
        await http.Response.fromStream(await nip96Request.send());
    if (nip96Response.statusCode != 200) {
      throw Exception('Failed to upload files');
    }
    final server = Nip96.decodeServerAdaptation(nip96Response.body);
    var apiUrl = '';
    if (server.apiURL!.startsWith('/')) {
      apiUrl = '$mediaServer${server.apiURL}';
    } else {
      apiUrl = server.apiURL!;
    }
    final httpAuth = Nip98.base64Event(apiUrl, 'POST', keyPairs);
    final futures = files.map((file) async {
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
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
          // file: REQUIRED the file to upload
          // caption: RECOMMENDED loose description;
          // expiration: UNIX timestamp in seconds. Empty string if file should be stored forever. The server isn't required to honor this.
          // size: File byte size. This is just a value the server can use to reject early if the file size exceeds the server limits.
          // alt: RECOMMENDED strict description text for visibility-impaired users.
          // media_type: "avatar" or "banner". Informs the server if the file will be used as an avatar or banner. If absent, the server will interpret it as a normal upload, without special treatment.
          // content_type: mime type such as "image/jpeg". This is just a value the server can use to reject early if the mime type isn't supported.
          // no_transform: "true" asks server not to transform the file and serve the uploaded file as is, may be rejected.
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            img.encodePng(resizedImage),
            filename: 'resized_image.png',
          ));
        } else {
          request.files
              .add(await http.MultipartFile.fromPath('file', file.path));
        }
      } catch (error) {}
      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final imeta = IMetaTag.fromNIP94(jsonResponse['nip94_event']);
        return imeta;
      }
      throw Exception('Failed to upload files');
    });
    final urls = await Future.wait(futures);
    return urls.whereType<IMetaTag>().toList();
  }
}
