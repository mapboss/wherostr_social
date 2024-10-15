import 'package:text_parser/text_parser.dart';

const MATCH_URL_YOUTUBE =
    r'(?:youtu\.be\/|youtube(?:-nocookie|education)?\.com\/(?:embed\/|v\/|watch\/|watch\?v=|watch\?.+&v=|shorts\/|live\/))((\w|-){11})|youtube\.com\/playlist\?list=|youtube\.com\/user\/';
const MATCH_URL_SOUNDCLOUD = r'(?:soundcloud\.com|snd\.sc)\/[^.]+$';
const MATCH_URL_VIMEO = r'vimeo\.com\/(?!progressive_redirect).+';
// Match Mux m3u8 URLs without the extension so users can use hls.js with Mux by adding the `.m3u8` extension. https://regexr.com/7um5f
const MATCH_URL_MUX = r'stream\.mux\.com\/(?!\w+\.m3u8)(\w+)';
const MATCH_URL_FACEBOOK =
    r'^https?:\/\/(www\.)?facebook\.com.*\/(video(s)?|watch|story)(\.php?|\/).+$';
const MATCH_URL_FACEBOOK_WATCH = r'^https?:\/\/fb\.watch\/.+$';
const MATCH_URL_STREAMABLE = r'streamable\.com\/([a-z0-9]+)$';
const MATCH_URL_WISTIA =
    r'(?:wistia\.(?:com|net)|wi\.st)\/(?:medias|embed)\/(?:iframe\/)?([^?]+)';
const MATCH_URL_TWITCH_VIDEO =
    r'(?:www\.|go\.)?twitch\.tv\/videos\/(\d+)($|\?)';
const MATCH_URL_TWITCH_CHANNEL =
    r'(?:www\.|go\.)?twitch\.tv\/([a-zA-Z0-9_]+)($|\?)';
const MATCH_URL_DAILYMOTION =
    r'^(?:(?:https?):)?(?:\/\/)?(?:www\.)?(?:(?:dailymotion\.com(?:\/embed)?\/video)|dai\.ly)\/([a-zA-Z0-9]+)(?:_[\w_-]+)?(?:[\w.#_-]+)?';
const MATCH_URL_MIXCLOUD = r'mixcloud\.com\/([^/]+\/[^/]+)';
const MATCH_URL_VIDYARD = r'vidyard.com\/(?:watch\/)?([a-zA-Z0-9-_]+)';
const MATCH_URL_KALTURA =
    r'^https?:\/\/[a-zA-Z]+\.kaltura.(com|org)\/p\/([0-9]+)\/sp\/([0-9]+)00\/embedIframeJs\/uiconf_id\/([0-9]+)\/partner_id\/([0-9]+)(.*)entry_id.([a-zA-Z0-9-_].*)$';
const AUDIO_EXTENSIONS =
    r'\.(m4a|m4b|mp4a|mpga|mp2|mp2a|mp3|m2a|m3a|wav|weba|aac|oga|spx)($|\?)';
const VIDEO_EXTENSIONS = r'\.(mp4|og[gv]|webm|mov|m4v)(#t=[,\d+]+)?($|\?)';
const HLS_EXTENSIONS = r'\.(m3u8)($|\?)';
const DASH_EXTENSIONS = r'\.(mpd)($|\?)';
const FLV_EXTENSIONS = r'\.(flv)($|\?)';

const MATCH_URL_TIKTOK =
    r'^.*https:\/\/(?:m|www|vm)?\.?tiktok\.com\/((?:.*\b(?:(?:usr|v|embed|user|video)\/|\?shareId=|\&item_id=)(\d+))|\w+)';

const MATCH_URL_RUMBLE = r'/(?<=rumble.com\/).*?\b';

class HashTagMatcher extends TextMatcher {
  const HashTagMatcher() : super(r'(#[^\s!@#$%^&*()=+.\/,\[{\]};:"?><]+)');
}

class NostrNPubMatcher extends TextMatcher {
  const NostrNPubMatcher()
      : super(r'(@|nostr:n)pub1([acdefghjklmnpqrstuvwxyz023456789]+)');
}

class NostrNProfileMatcher extends TextMatcher {
  const NostrNProfileMatcher()
      : super(r'(@|nostr:n)profile1([acdefghjklmnpqrstuvwxyz023456789]+)');
}

class NostrNEventMatcher extends TextMatcher {
  const NostrNEventMatcher()
      : super(r'(@|nostr:n)event1([acdefghjklmnpqrstuvwxyz023456789]+)');
}

class NostrNoteMatcher extends TextMatcher {
  const NostrNoteMatcher()
      : super(r'(@|nostr:n)ote1([acdefghjklmnpqrstuvwxyz023456789]+)');
}

class NostrNAddressMatcher extends TextMatcher {
  const NostrNAddressMatcher()
      : super(r'(@|nostr:n)addr1([acdefghjklmnpqrstuvwxyz023456789]+)');
}

class NostrLinkMatcher extends TextMatcher {
  const NostrLinkMatcher()
      : super(
            r'(@|nostr:n|n)(pub|profile|event|ote|addr)1([acdefghjklmnpqrstuvwxyz023456789]+)');
}

class ImageUrlMatcher extends TextMatcher {
  const ImageUrlMatcher()
      : super(
            r'(http(s?):)([/|.|\w|\s|-])*\.(?:gif|jpg|jpeg|jfif|png|bmp|webp)');
}

class VideoUrlMatcher extends TextMatcher {
  const VideoUrlMatcher()
      : super(
            r'(http(s?):)([/|.|\w|\s|-])*\.(?:mp4|mov|mkv|avi|m4v|webm|m3u8)');
}

class AudioUrlMatcher extends TextMatcher {
  const AudioUrlMatcher()
      : super(r'(http(s?):)([/|.|\w|\s|-])*\.(?:wav|mp3|ogg)');
}

class CustomEmojiMatcher extends TextMatcher {
  const CustomEmojiMatcher() : super(r':([\w\t-]+):');
}

class YouTubeMatcher extends TextMatcher {
  const YouTubeMatcher() : super(MATCH_URL_YOUTUBE);
}

class FacebookMatcher extends TextMatcher {
  const FacebookMatcher() : super(MATCH_URL_FACEBOOK);
}

class TwitchMatcher extends TextMatcher {
  const TwitchMatcher() : super(MATCH_URL_TWITCH_VIDEO);
}

class SoundCloudMatcher extends TextMatcher {
  const SoundCloudMatcher() : super(MATCH_URL_SOUNDCLOUD);
}

class StreamableMatcher extends TextMatcher {
  const StreamableMatcher() : super(MATCH_URL_STREAMABLE);
}

class VimeoMatcher extends TextMatcher {
  const VimeoMatcher() : super(MATCH_URL_VIMEO);
}

class WistiaMatcher extends TextMatcher {
  const WistiaMatcher() : super(MATCH_URL_WISTIA);
}

class MixcloudMatcher extends TextMatcher {
  const MixcloudMatcher() : super(MATCH_URL_MIXCLOUD);
}

class DailyMotionMatcher extends TextMatcher {
  const DailyMotionMatcher() : super(MATCH_URL_DAILYMOTION);
}

class KalturaMatcher extends TextMatcher {
  const KalturaMatcher() : super(MATCH_URL_KALTURA);
}

class TiktokMatcher extends TextMatcher {
  const TiktokMatcher() : super(MATCH_URL_TIKTOK);
}

class RumbleMatcher extends TextMatcher {
  const RumbleMatcher() : super(MATCH_URL_RUMBLE);
}

class LightningInvoiceMatcher extends TextMatcher {
  const LightningInvoiceMatcher() : super(r'(lnbc\w+)');
}

class LightningUrlMatcher extends TextMatcher {
  const LightningUrlMatcher()
      : super(r'(lnurl1)([acdefghjklmnpqrstuvwxyz023456789]+)');
}

class CashuMatcher extends TextMatcher {
  const CashuMatcher() : super(r'(cashuA[A-Za-z0-9_-]{0,10000}={0,3})');
}

Future<List<TextElement>> textParser(String content) {
  return TextParser(matchers: [
    // standard media video & live provider url
    // const ImageUrlMatcher(),
    // const VideoUrlMatcher(),
    // const AudioUrlMatcher(),

    // // video & live provider url
    // const YouTubeMatcher(),
    // const FacebookMatcher(),
    // const TwitchMatcher(),
    // const SoundCloudMatcher(),
    // const StreamableMatcher(),
    // const VimeoMatcher(),
    // const WistiaMatcher(),
    // const MixcloudMatcher(),
    // const DailyMotionMatcher(),
    // const KalturaMatcher(),
    // const TiktokMatcher(),
    // const RumbleMatcher(),

    // // lightning invoice
    const LightningInvoiceMatcher(),
    const CashuMatcher(),

    // Nostr Link
    const NostrLinkMatcher(),
    // const NostrNAddressMatcher(),

    const CustomEmojiMatcher(),

    // Common Text matcher
    // const EmailMatcher(),
    const HashTagMatcher(),
    const UrlMatcher(),
    // const UrlLikeMatcher(),
  ]).parse(content, useIsolate: false);
}
