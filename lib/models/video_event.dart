/*
## Video View

A video event view is a response to a video event to track a user's view or progress viewing the video.

### Format

The format uses a parameterized replaceable event kind `34237`.

The `.content` of these events is optional and could be a free-form note that acts like a bookmark for the user.

The list of tags are as follows:
* `a` (required) reference tag to kind `34235` or `34236` video event being viewed
* `d` (required) same as `a` reference tag value
* `viewed` (optional, repeated) timestamp of the user's start time in seconds, timestamp of the user's end time in seconds 


```json
{
  "id": <32-bytes lowercase hex-encoded SHA-256 of the the serialized event data>,
  "pubkey": <32-bytes lowercase hex-encoded public key of the event creator>,
  "created_at": <Unix timestamp in seconds>,
  "kind": 34237,
  "content": "<note>",
  "tags": [
    ["a", "<34235 | 34236>:<video event author pubkey>:<d-identifier of video event>", "<optional relay url>"],
    ["e", "<event-id", "<relay-url>"]
    ["d", "<34235 | 34236>:<video event author pubkey>:<d-identifier of video event>"],
    ["viewed", <start>, <end>],
  ]
}
```
*/
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/user_tag.dart';
import 'package:wherostr_social/utils/safe_parser.dart';

const kindVideoEvent = 34235;
const kindViewedVideoEvent = 34236;
const kindVideoView = 34237;

class SegmentVideoEvent {
  String? start;
  String? end;
  String? title;
  String? thumbnailUrl;

  SegmentVideoEvent({
    this.start,
    this.end,
    this.title,
    this.thumbnailUrl,
  });

  static SegmentVideoEvent? fromTag(List<String>? tag) {
    if (tag == null) return null;
    return SegmentVideoEvent(
      start: tag.elementAtOrNull(1),
      end: tag.elementAtOrNull(2),
      title: tag.elementAtOrNull(3),
      thumbnailUrl: tag.elementAtOrNull(4),
    );
  }

  List<String> toTag() {
    final tag = ['segment'];
    if (start != null) {
      tag.add(start!);
    }
    if (end != null) {
      tag.add(end!);
    }
    if (title != null) {
      tag.add(title!);
    }
    if (thumbnailUrl != null) {
      tag.add(thumbnailUrl!);
    }
    return tag;
  }
}

class VideoEvent {
  String? id;
  int? kind;
  String? content;
  String? title;
  String? thumb;
  DateTime? publishedAt;
  String? alt;
  String? url;
  String? mimeType;
  String? sha256;
  String? size;
  String? duration;
  String? dim;
  String? magnet;
  String? torrentHash;
  String? textTrack;
  String? contentWarning;
  SegmentVideoEvent? segment;
  List<UserTag>? userTags;
  List<List<String>>? hashTags;
  List<List<String>>? refTags;

  VideoEvent({
    this.kind,
    this.content,
    this.id,
    this.title,
    this.thumb,
    this.publishedAt,
    this.alt,
    this.url,
    this.mimeType,
    this.sha256,
    this.size,
    this.duration,
    this.dim,
    this.magnet,
    this.torrentHash,
    this.textTrack,
    this.contentWarning,
    this.segment,
    this.userTags,
    this.hashTags,
    this.refTags,
  });

  factory VideoEvent.fromEvent(DataEvent event) {
    if (![kindVideoEvent, kindViewedVideoEvent].contains(event.kind)) {
      throw Exception('Invalid kind');
    }
    int? publishedAt = SafeParser.parseInt(event.getTagValue('published_at'));

    return VideoEvent(
      kind: event.kind!,
      id: event.getId()!,
      content: event.content,
      title: event.getTagValue('title'),
      thumb: event.getTagValue('thumb'),
      publishedAt: publishedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(publishedAt)
          : null,
      alt: event.getTagValue('alt'),
      url: event.getTagValue('url'),
      mimeType: event.getTagValue('m'),
      sha256: event.getTagValue('x'),
      size: event.getTagValue('size'),
      duration: event.getTagValue('duration'),
      dim: event.getTagValue('dim'),
      magnet: event.getTagValue('magnet'),
      torrentHash: event.getTagValue('i'),
      textTrack: event.getTagValue('text-track'),
      contentWarning: event.getTagValue('content-warning'),
      segment: SegmentVideoEvent.fromTag(event.getMatchedTag('segment')),
      userTags:
          event.getMatchedTags('p')?.map((e) => UserTag.fromTag(e)).toList(),
      hashTags: event.getMatchedTags('t'),
      refTags: event.getMatchedTags('r'),
    );
  }

  toTags() {
    List<List<String>> tags = [];
    if (id != null) {
      tags.add(['d', id!]);
    }
    if (title != null) {
      tags.add(['title', title!]);
    }
    if (thumb != null) {
      tags.add(['thumb', thumb!]);
    }
    if (publishedAt != null) {
      tags.add(['publishedAt', publishedAt!.millisecondsSinceEpoch.toString()]);
    }
    if (alt != null) {
      tags.add(['alt', alt!]);
    }
    if (url != null) {
      tags.add(['url', url!]);
    }
    if (mimeType != null) {
      tags.add(['m', mimeType!]);
    }
    if (sha256 != null) {
      tags.add(['x', sha256!]);
    }
    if (size != null) {
      tags.add(['size', size!]);
    }
    if (duration != null) {
      tags.add(['duration', duration!]);
    }
    if (dim != null) {
      tags.add(['dim', dim!]);
    }
    if (magnet != null) {
      tags.add(['magnet', magnet!]);
    }
    if (torrentHash != null) {
      tags.add(['i', torrentHash!]);
    }
    if (textTrack != null) {
      tags.add(['text-track', textTrack!]);
    }
    if (contentWarning != null) {
      tags.add(['content-warning', contentWarning!]);
    }
    if (segment != null) {
      tags.add(segment!.toTag());
    }
    if (userTags != null) {
      for (final tag in userTags!) {
        tags.add(tag.toTag());
      }
    }
    if (hashTags != null) {
      for (final tag in hashTags!) {
        tags.add(tag);
      }
    }
    if (refTags != null) {
      for (final tag in refTags!) {
        tags.add(tag);
      }
    }
    return tags;
  }

  toEvent() {
    return DataEvent(
      content: content,
      kind: kind ?? kindVideoEvent,
      tags: toTags(),
    );
  }
}
