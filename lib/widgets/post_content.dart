// ignore_for_file: type_literal_in_constant_pattern
import 'package:any_link_preview/any_link_preview.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:text_parser/text_parser.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_bech32.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/utils/text_parser.dart';
import 'package:wherostr_social/widgets/audio_player.dart';
import 'package:wherostr_social/widgets/hashtag_search.dart';
import 'package:wherostr_social/widgets/post_details.dart';
import 'package:wherostr_social/widgets/profile_display_name.dart';
import 'package:wherostr_social/widgets/post_item_loader.dart';
import 'package:wherostr_social/widgets/video_player.dart';

class PostContent extends StatefulWidget {
  final String content;
  final List<String>? tags;
  final bool enableElementTap;
  final bool enablePreview;
  final bool enableMedia;
  final int depth;
  final Widget? contentLeading;

  const PostContent({
    super.key,
    required this.content,
    this.tags,
    this.enableElementTap = true,
    this.enablePreview = true,
    this.enableMedia = true,
    this.depth = 0,
    this.contentLeading,
  });

  @override
  State createState() => _PostContentState();
}

class _PostContentState extends State<PostContent> {
  List<InlineSpan> _elementWidgets = [];
  List<ImageProvider> _imageProviders = [];

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    _elementWidgets = [TextSpan(text: widget.content)];
    if (widget.content != '') {
      textParser(widget.content).then((textElements) {
        if (mounted) {
          final elementWidgets = getElementWidgets(textElements);
          setState(() {
            _elementWidgets = elementWidgets;
          });
        }
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

  List<InlineSpan> getElementWidgets(List<TextElement> elements) {
    ThemeData themeData = Theme.of(context);
    List<InlineSpan> widgets = [];
    if (widget.contentLeading != null) {
      widgets.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: widget.contentLeading!,
      ));
    }
    List<ImageProvider> imageProviders = [];
    double maxMediaHeight = (MediaQuery.sizeOf(context).width - 32) * (4 / 3);
    int maxImageCacheSize = MediaQuery.sizeOf(context).height.toInt();
    for (var element in elements) {
      switch (element.matcherType) {
        case ImageUrlMatcher:
          final imageProvider =
              AppUtils.getCachedImageProvider(element.text, maxImageCacheSize);
          imageProviders.add(imageProvider);
          if (widget.enableMedia) {
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
          if (widget.enableMedia) {
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
          if (widget.enableMedia) {
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
          if (widget.enablePreview) {
            widgets.add(
              WidgetSpan(
                child: InkWell(
                  onTap: widget.enableElementTap
                      ? () => launchUrl(Uri.parse(element.text))
                      : null,
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinkPreview(
                          url: element.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else {
            widgets.add(
              LinkElement(
                text: element.text,
                style: TextStyle(color: themeData.colorScheme.primary),
                enableElementTap: widget.enableElementTap,
              ),
            );
          }
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
          } else if (nostrUrl.startsWith('note')) {
            eventId =
                NostrService.instance.utilsService.decodeBech32(nostrUrl)[0];
          } else if (nostrUrl.startsWith('naddr') ||
              nostrUrl.startsWith('nevent')) {
            final data = DataBech32.fromString(nostrUrl);
            eventId = data.getId();
            relays = data.relays;
          }
          if (eventId != null) {
            if (widget.depth < 1) {
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
    return Text.rich(
      TextSpan(
        children: _elementWidgets,
      ),
    );
  }
}

class LinkPreview extends StatefulWidget {
  final String url;

  const LinkPreview({
    super.key,
    required this.url,
  });

  @override
  State<LinkPreview> createState() => _LinkPreviewState();
}

class _LinkPreviewState extends State<LinkPreview> {
  Metadata? _metadata;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    try {
      if (widget.url.startsWith('https://')) {
        final metadata = await AnyLinkPreview.getMetadata(
          link: widget.url.replaceFirst('https://www.', 'https://'),
        );
        if (mounted) {
          setState(() {
            _metadata = metadata;
          });
        }
      }
    } catch (error) {}
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final image = _metadata?.image;
    final title = _metadata?.title;
    final desc = _metadata?.desc;
    return Container(
      color: themeData.colorScheme.surfaceDim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null)
            Center(
              child: FadeInImage(
                placeholder: MemoryImage(kTransparentImage),
                image: AppUtils.getImageProvider(image),
                fadeInDuration: const Duration(milliseconds: 300),
                fadeInCurve: Curves.easeInOutCubic,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.link),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.url,
                    style: TextStyle(
                      color: themeExtension.textDimColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: themeData.textTheme.titleMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (desc != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                desc,
                style: TextStyle(
                  color: themeExtension.textDimColor,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class LinkElement extends TextSpan {
  LinkElement({
    required String text,
    super.style,
    bool enableElementTap = true,
    TextDecoration decoration = TextDecoration.none,
  }) : super(
            text: text.length > 28 ? '${text.substring(0, 28)}...' : text,
            recognizer: TapGestureRecognizer()
              ..onTap =
                  enableElementTap ? () => launchUrl(Uri.parse(text)) : null);
}
