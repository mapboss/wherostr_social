import 'package:wherostr_social/utils/safe_parser.dart';

final matcher = RegExp(r'(\w+)\s(.*)');

class IMetadata {
  final String url;
  final String mimeType;
  final String? blurhash;
  final String? dim;
  final String? alt;
  final String? sha256;
  final String? originalSHA256;
  final String? thumbnail;
  final String? preview;
  final int? size;
  final List<String>? fallback;

  IMetadata({
    required this.url,
    required this.mimeType,
    this.blurhash,
    this.dim,
    this.alt,
    this.sha256,
    this.originalSHA256,
    this.thumbnail,
    this.preview,
    this.size,
    this.fallback,
  });

  factory IMetadata.fromNostrBuildAPI(Map<String, dynamic> data) {
    return IMetadata(
      url: data['url']?.toString().toLowerCase() ?? "",
      mimeType: data['mime']?.toString().toLowerCase() ?? "",
      blurhash: SafeParser.parseString(data['blurhash']),
      dim: SafeParser.parseString(data['dimensionsString']),
      alt: SafeParser.parseString(data['name']),
      sha256: SafeParser.parseString(data['sha256']),
      originalSHA256: SafeParser.parseString(data['original_sha256']),
      thumbnail: SafeParser.parseString(data['thumbnail']),
      preview: SafeParser.parseString(data['responsive']['1080p']),
      size: SafeParser.parseInt(data['size']),
    );
  }

  factory IMetadata.fromNIP94(Map<String, dynamic> data) {
    return IMetadata(
      url: data['url']?.toString().toLowerCase() ?? "",
      mimeType: data['m']?.toString().toLowerCase() ?? "",
      blurhash: SafeParser.parseString(data['blurhash']),
      dim: SafeParser.parseString(data['dim']),
      alt: SafeParser.parseString(data['alt']),
      sha256: SafeParser.parseString(data['x']),
      originalSHA256: SafeParser.parseString(data['ox']),
      thumbnail: SafeParser.parseString(data['thumb']),
      preview: SafeParser.parseString(data['image']),
      size: SafeParser.parseInt(data['size']),
    );
  }
  factory IMetadata.fromTag(List<String> tag) {
    try {
      if (tag.elementAtOrNull(0) != 'imeta') throw Exception('Invalid tag');
      Map<String, dynamic> data = {};
      tag.where((e) => e != 'imeta').forEach((e) {
        final match = matcher.matchAsPrefix(e);
        final key = match?.group(1);
        final value = match?.group(2);
        if (key == null || value == null) return;
        data[key] = value;
      });
      return IMetadata.fromNIP94(data);
    } catch (err) {
      print('fromTag: ERROR: $err');
      rethrow;
    }
  }

  List<String> toTag() {
    return [
      "imeta",
      "url $url",
      "m $mimeType",
      if (sha256 != null) "x $sha256",
      if (originalSHA256 != null) "ox $originalSHA256",
      if (blurhash != null) "blurhash $blurhash",
      if (dim != null) "dim $dim",
      if (alt != null) "alt $alt",
      if (thumbnail != null) "thumb $thumbnail",
      if (preview != null) "image $preview",
      if (size != null) "size $size",
    ];
  }
}


// [
//     {
//         "id": 0,
//         "input_name": "APIv2",
//         "name": "f4d01804d6a2be9eeeafac3c7a4e0806683d74b20d44f1bb25844dacfd39145f.jpg",
//         "url": "https://image.nostr.build/f4d01804d6a2be9eeeafac3c7a4e0806683d74b20d44f1bb25844dacfd39145f.jpg",
//         "thumbnail": "https://image.nostr.build/thumb/f4d01804d6a2be9eeeafac3c7a4e0806683d74b20d44f1bb25844dacfd39145f.jpg",
//         "responsive": {
//             "240p": "https://image.nostr.build/resp/240p/f4d01804d6a2be9eeeafac3c7a4e0806683d74b20d44f1bb25844dacfd39145f.jpg",
//             "360p": "https://image.nostr.build/resp/360p/f4d01804d6a2be9eeeafac3c7a4e0806683d74b20d44f1bb25844dacfd39145f.jpg",
//             "480p": "https://image.nostr.build/resp/480p/f4d01804d6a2be9eeeafac3c7a4e0806683d74b20d44f1bb25844dacfd39145f.jpg",
//             "720p": "https://image.nostr.build/resp/720p/f4d01804d6a2be9eeeafac3c7a4e0806683d74b20d44f1bb25844dacfd39145f.jpg",
//             "1080p": "https://image.nostr.build/resp/1080p/f4d01804d6a2be9eeeafac3c7a4e0806683d74b20d44f1bb25844dacfd39145f.jpg"
//         },
//         "blurhash": "LDI56@.9_3bEiKDhoMo2~q-;E1M{",
//         "sha256": "ab0d36b5827e46241aa9503f9ac8305c1824a40ce7aadec89f8f91ae8a06f2b4",
//         "original_sha256": "f4d01804d6a2be9eeeafac3c7a4e0806683d74b20d44f1bb25844dacfd39145f",
//         "type": "picture",
//         "media_type": "image",
//         "mime": "image/jpeg",
//         "size": 835317,
//         "metadata": {
//             "date:create": "2024-08-25T04:57:49+00:00",
//             "date:modify": "2024-08-25T04:57:49+00:00",
//             "jpeg": "sampling-factor: 2x2,1x1,1x1"
//         },
//         "dimensions": {
//             "width": 1920,
//             "height": 1440
//         },
//         "dimensionsString": "1920x1440"
//     }
// ]

