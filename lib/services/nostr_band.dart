import 'dart:convert';
import 'package:http/http.dart' as http;

const serviceUrl = 'https://api.nostr.band';

class NostrBandService {
  static Future<Map<String, dynamic>> profileStats(String? pubkey) async {
    if (pubkey == null) {
      return {};
    }
    final url =
        Uri.parse(serviceUrl).replace(path: '/v0/stats/profile/$pubkey');
    final request = http.Request('GET', url);
    print('url: $url');

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      final Map<String, dynamic> result = jsonDecode(response.body);
      print('result: ${result['stats'][pubkey]}');
      return result['stats'][pubkey];
    } else {
      throw Exception('Failed to request search');
    }
  }
}

// {
//   "stats": {
//     "3db5e1b9daa57cc6a7d552a86a87574eea265e0759ddeb87d44e0727f79ed88d": {
//       "pubkey": "3db5e1b9daa57cc6a7d552a86a87574eea265e0759ddeb87d44e0727f79ed88d",
//       "pub_note_count": 1223,
//       "pub_post_count": 154,
//       "pub_reply_count": 1069,
//       "pub_reaction_count": 5809,
//       "pub_repost_count": 106,
//       "pub_report_count": 3,
//       "pub_note_ref_event_count": 1177,
//       "pub_note_ref_pubkey_count": 262,
//       "pub_reaction_ref_event_count": 5760,
//       "pub_reaction_ref_pubkey_count": 366,
//       "pub_report_ref_event_count": 1,
//       "pub_report_ref_pubkey_count": 3,
//       "pub_repost_ref_event_count": 108,
//       "pub_repost_ref_pubkey_count": 73,
//       "pub_mute_ref_pubkey_count": 71,
//       "pub_bookmark_ref_event_count": 6,
//       "pub_profile_badge_ref_event_count": 10,
//       "pub_following_pubkey_count": 114,
//       "reaction_count": 3955,
//       "reaction_pubkey_count": 448,
//       "repost_count": 277,
//       "repost_pubkey_count": 110,
//       "reply_count": 1942,
//       "reply_pubkey_count": 217,
//       "report_count": 1,
//       "report_pubkey_count": 1,
//       "mute_pubkey_count": 8,
//       "followers_pubkey_count": 717,
//       "zaps_sent": {
//         "count": 727,
//         "zapper_count": 1,
//         "target_event_count": 470,
//         "target_pubkey_count": 129,
//         "provider_count": 13,
//         "msats": 185335000,
//         "min_msats": 1000,
//         "max_msats": 5000000,
//         "avg_msats": 254931,
//         "median_msats": 50000
//       },
//       "zaps_received": {
//         "count": 720,
//         "zapper_count": 163,
//         "target_event_count": 317,
//         "target_pubkey_count": 1,
//         "provider_count": 4,
//         "msats": 337847000,
//         "min_msats": 1000,
//         "max_msats": 210000000,
//         "avg_msats": 469231,
//         "median_msats": 27000
//       }
//     }
//   }
// }