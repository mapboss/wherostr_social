// ignore_for_file: type_literal_in_constant_pattern
import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:text_parser/text_parser.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/widgets/facebook_preview.dart';
import 'package:wherostr_social/widgets/http_url_display.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/utils/text_parser.dart';
import 'package:wherostr_social/widgets/audio_player.dart';
import 'package:wherostr_social/widgets/hashtag_search.dart';
import 'package:wherostr_social/widgets/post_details.dart';
import 'package:wherostr_social/widgets/profile_display_name.dart';
import 'package:wherostr_social/widgets/post_item_loader.dart';
import 'package:wherostr_social/widgets/rumble_preview.dart';
import 'package:wherostr_social/widgets/tiktok_preview.dart';
import 'package:wherostr_social/widgets/twitch_preview.dart';
import 'package:wherostr_social/widgets/video_player.dart';
import 'package:wherostr_social/widgets/youtube_preview.dart';

class PostContent extends StatefulWidget {
  final String content;
  final List<String>? tags;
  final bool enableElementTap;
  final bool enablePreview;
  final int depth;
  final bool wantKeepAlive;

  const PostContent({
    super.key,
    required this.content,
    this.tags,
    this.enableElementTap = true,
    this.enablePreview = true,
    this.depth = 0,
    this.wantKeepAlive = true,
  });

  @override
  State createState() => _PostContentState();
}

class _PostContentState extends State<PostContent>
    with AutomaticKeepAliveClientMixin {
  List<TextElement> _elements = [];
  List<ImageProvider> _imageProviders = [];

  @override
  bool get wantKeepAlive => widget.wantKeepAlive;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    setState(() {
      _elements = [TextElement(widget.content)];
    });
    var textElements = await textParser(widget.content);
    if (mounted) {
      setState(() {
        _elements = textElements;
      });
    }
  }

  void _handleImageTap(ImageProvider imageProvider) {
    showImageViewerPager(
      context,
      MultiImageProvider(
        _imageProviders,
        initialIndex: _imageProviders.indexOf(imageProvider),
      ),
      useSafeArea: true,
      swipeDismissible: true,
      doubleTapZoomable: true,
    );
  }

  List<InlineSpan> getElementWidgets() {
    ThemeData themeData = Theme.of(context);
    List<InlineSpan> widgets = [];
    List<ImageProvider> imageProviders = [];
    double maxMediaHeight = (MediaQuery.sizeOf(context).width - 32) * (4 / 3);
    for (var element in _elements) {
      switch (element.matcherType) {
        case ImageUrlMatcher:
          final imageProvider = AppUtils.getImageProvider(element.text);
          imageProviders.add(imageProvider);
          if (widget.enablePreview) {
            widgets.add(
              WidgetSpan(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          constraints: BoxConstraints(
                            maxHeight: maxMediaHeight,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: widget.enableElementTap
                                  ? () => _handleImageTap(imageProvider)
                                  : null,
                              child: Image(
                                image: imageProvider,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          } else {
            widgets.add(TextSpan(
              text: element.text.length > 28
                  ? '${element.text.substring(0, 28)}...'
                  : element.text,
              style: TextStyle(color: themeData.colorScheme.primary),
              recognizer: TapGestureRecognizer()
                ..onTap = widget.enableElementTap
                    ? () => _handleImageTap(imageProvider)
                    : null,
            ));
          }
          continue;
        case VideoUrlMatcher:
          if (widget.enablePreview) {
            widgets.add(
              WidgetSpan(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: maxMediaHeight,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: VideoPlayer(url: element.text),
                  ),
                ),
              ),
            );
          } else {
            widgets.add(TextSpan(
              text: element.text.length > 28
                  ? '${element.text.substring(0, 28)}...'
                  : element.text,
              style: TextStyle(color: themeData.colorScheme.primary),
              recognizer: TapGestureRecognizer()
                ..onTap = widget.enableElementTap
                    ? () => launchUrl(Uri.parse(element.text))
                    : null,
            ));
          }
          continue;
        case AudioUrlMatcher:
          if (widget.enablePreview) {
            widgets.add(
              WidgetSpan(
                child: AudioPlayer(url: element.text),
              ),
            );
          } else {
            widgets.add(TextSpan(
              text: element.text.length > 28
                  ? '${element.text.substring(0, 28)}...'
                  : element.text,
              style: TextStyle(color: themeData.colorScheme.primary),
              recognizer: TapGestureRecognizer()
                ..onTap = widget.enableElementTap
                    ? () => launchUrl(Uri.parse(element.text))
                    : null,
            ));
          }
          continue;
        // case YouTubeMatcher:
        // case FacebookMatcher:
        // case TwitchMatcher:
        // case SoundCloudMatcher:
        // case StreamableMatcher:
        // case VimeoMatcher:
        // case WistiaMatcher:
        // case MixcloudMatcher:
        // case DailyMotionMatcher:
        // case KalturaMatcher:
        // case TiktokMatcher:
        // case RumbleMatcher:
        case UrlMatcher:
          if (widget.enablePreview &&
              RegExp(YouTubeMatcher().pattern).hasMatch(element.text)) {
            widgets.add(YoutubePreviewElement(url: element.text));
            continue;
          }
          if (widget.enablePreview &&
              RegExp(FacebookMatcher().pattern).hasMatch(element.text)) {
            widgets.add(FacebookPreviewElement(url: element.text));
            continue;
          }
          if (widget.enablePreview &&
              RegExp(RumbleMatcher().pattern).hasMatch(element.text)) {
            widgets.add(RumblePreviewElement(url: element.text));
            continue;
          }
          if (widget.enablePreview &&
              RegExp(TiktokMatcher().pattern).hasMatch(element.text)) {
            widgets.add(TiktokPreviewElement(url: element.text));
            continue;
          }
          if (widget.enablePreview &&
              RegExp(TwitchMatcher().pattern).hasMatch(element.text)) {
            widgets.add(TwitchPreviewElement(url: element.text));
            continue;
          }
          widgets.add(
            HttpUrlDisplayElement(
                text: element.text,
                style: TextStyle(color: themeData.colorScheme.primary),
                enableElementTap: widget.enableElementTap),
          );
          continue;
        // case NostrNEventMatcher:
        // case NostrNoteMatcher:
        // case NostrNPubMatcher:
        // case NostrNProfileMatcher:
        // case NostrNAddressMatcher:
        case NostrLinkMatcher:
          final nostrUrl = element.text.startsWith('nostr:')
              ? element.text.substring(6)
              : element.text.startsWith('@')
                  ? element.text.substring(1)
                  : null;
          if (nostrUrl == null) continue;
          String? eventId;
          List<String>? relays;
          if (nostrUrl.startsWith('npub')) {
            String pubkey =
                NostrService.instance.utilsService.decodeBech32(nostrUrl)[0];
            widgets.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: ProfileDisplayName(
                  pubkey: pubkey,
                  textStyle: themeData.textTheme.bodyMedium!.apply(
                    color: themeData.colorScheme.primary,
                  ),
                  withAtSign: true,
                  enableShowProfileAction: true,
                ),
              ),
            );
            continue;
          } else if (nostrUrl.startsWith('nprofile')) {
            var data = NostrService.instance.utilsService
                .decodeNprofileToMap(nostrUrl);
            widgets.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: ProfileDisplayName(
                  pubkey: data['pubkey'],
                  textStyle: themeData.textTheme.bodyMedium!.apply(
                    color: themeData.colorScheme.primary,
                  ),
                  withAtSign: true,
                  enableShowProfileAction: true,
                ),
              ),
            );
            continue;
          } else if (nostrUrl.startsWith('nevent')) {
            eventId = NostrService.instance.utilsService
                .decodeNeventToMap(nostrUrl)['eventId'];
          } else if (nostrUrl.startsWith('note')) {
            eventId =
                NostrService.instance.utilsService.decodeBech32(nostrUrl)[0];
          } else if (nostrUrl.startsWith('naddr')) {
            var hexdata =
                NostrService.instance.utilsService.decodeBech32(nostrUrl)[0];
            var data = Uint8List.fromList(hex.decode(hexdata));
            var tlvList = NostrService.instance.utilsService.tlv.decode(data);

            String? identifier;
            String? pubkey;
            int? kind;
            relays = [];
            for (final tlv in tlvList) {
              if (tlv.type == 0) {
                try {
                  identifier = ascii.decode(tlv.value);
                } catch (err) {
                  eventId = hex.encode(tlv.value);
                }
              } else if (tlv.type == 1) {
                relays.add(ascii.decode(tlv.value));
              } else if (tlv.type == 2) {
                pubkey = hex.encode(tlv.value);
              } else if (tlv.type == 3) {
                kind = int.parse(hex.encode(tlv.value), radix: 16);
              }
            }
            eventId = eventId ?? '$kind:$pubkey:$identifier';
          }
          if (eventId != null) {
            if (widget.depth < 2) {
              double maxHeight = MediaQuery.sizeOf(context).height * 0.25;
              if (maxHeight < 108) {
                maxHeight = 108;
              }
              widgets.add(
                WidgetSpan(
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          foregroundDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: themeData.colorScheme.primary,
                            ),
                          ),
                          child: PostItemLoader(
                            relays: DataRelayList.fromListString(relays),
                            eventId: eventId,
                            enableMenu: false,
                            enableTap: widget.enableElementTap,
                            enableActionBar: false,
                            enableLocation: false,
                            enableProofOfWork: false,
                            depth: widget.depth + 1,
                            maxHeight: maxHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            } else {
              widgets.add(TextSpan(
                text: element.text,
                style: TextStyle(color: themeData.colorScheme.primary),
                recognizer: TapGestureRecognizer()
                  ..onTap = widget.enableElementTap
                      ? () => context.read<AppStatesProvider>().navigatorPush(
                            widget: PostDetails(
                              eventId: eventId,
                            ),
                          )
                      : null,
              ));
            }
          }
          continue;
        case LightningInvoiceMatcher:
        case CashuMatcher:
          widgets.add(TextSpan(
            text: element.text.length > 28
                ? '${element.text.substring(0, 28)}...'
                : element.text,
            style: TextStyle(color: themeData.colorScheme.primary),
            recognizer: TapGestureRecognizer()
              ..onTap = () => print(element.text),
          ));
          continue;
        case CustomEmojiMatcher:
          widgets.add(TextSpan(
            text: element.text,
          ));
          continue;
        case HashTagMatcher:
          widgets.add(TextSpan(
            text: element.text,
            style: TextStyle(color: themeData.colorScheme.primary),
            recognizer: TapGestureRecognizer()
              ..onTap = widget.enableElementTap
                  ? () => context.read<AppStatesProvider>().navigatorPush(
                        widget: HashtagSearch(
                          hashtag: element.text.substring(1),
                        ),
                      )
                  : null,
          ));
          continue;
        case EmailMatcher:
        default:
          widgets.add(TextSpan(text: element.text));
      }
    }
    setState(() {
      _imageProviders = imageProviders;
    });
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Text.rich(
      TextSpan(
        children: getElementWidgets(),
      ),
    );
  }
}
