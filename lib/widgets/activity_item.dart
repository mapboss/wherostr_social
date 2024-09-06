import 'dart:ui' as ui;

import 'package:dart_nostr/nostr/model/event/event.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/utils/nostr_event.dart';
import 'package:wherostr_social/utils/text_parser.dart';
import 'package:wherostr_social/widgets/post_content.dart';
import 'package:wherostr_social/widgets/post_details.dart';
import 'package:wherostr_social/widgets/post_item_loader.dart';
import 'package:wherostr_social/widgets/profile.dart';
import 'package:wherostr_social/widgets/profile_avatar.dart';
import 'package:wherostr_social/widgets/profile_display_name.dart';

class ActivityItem extends StatefulWidget {
  final NostrEvent event;
  final bool enableViewReferencedEventTap;
  final bool showFollowButton;
  final bool showReferencedEvent;

  const ActivityItem({
    super.key,
    required this.event,
    this.enableViewReferencedEventTap = false,
    this.showFollowButton = true,
    this.showReferencedEvent = false,
  });

  @override
  State<ActivityItem> createState() => _ActivityItemState();
}

class _ActivityItemState extends State<ActivityItem> {
  final String _profileHeroTag = UniqueKey().toString();
  NostrUser? _user;
  bool _isMe = false;
  bool _isFollowing = false;
  String? _referencedEventId;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    final me = context.read<AppStatesProvider>().me;
    String userPubkey;
    switch (widget.event.kind) {
      case 9735:
        userPubkey = getZappee(event: widget.event) ?? widget.event.pubkey;
        break;
      default:
        userPubkey = widget.event.pubkey;
        break;
    }
    NostrUser user = await NostrService.fetchUser(userPubkey);
    if (mounted) {
      setState(() {
        _user = user;
        _isMe = me.pubkey == user.pubkey;
        _isFollowing = me.following.contains(user.pubkey);
        _referencedEventId = getReferencedEventId(widget.event) ??
            (widget.event.kind == 1 ? widget.event.id : null);
      });
    }
  }

  Widget? _activityIcon() {
    ThemeData themeData = Theme.of(context);
    switch (widget.event.kind) {
      case 1:
        return const Icon(Icons.comment);
      case 6:
        return Icon(
          Icons.repeat,
          color: themeData.colorScheme.secondary,
        );
      case 7:
        if (widget.event.content == '+') {
          return Icon(
            Icons.thumb_up,
            color: themeData.colorScheme.secondary,
          );
        } else if (widget.event.content != null) {
          final matches = RegExp(const CustomEmojiMatcher().pattern)
              .firstMatch(widget.event.content!);
          if (matches?[0] != null) {
            String? emoji = getEmojiUrl(
              event: widget.event,
              emoji: widget.event.content!,
            );
            if (emoji != null) {
              return Image(
                width: 24,
                image: AppUtils.getCachedImageProvider(emoji, 80),
              );
            } else {
              return Text(
                widget.event.content!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }
          } else {
            return Text(
              widget.event.content!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 24),
            );
          }
        }
      case 9735:
        double? zapAmount = getZapAmount(event: widget.event);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.electric_bolt,
              color: Colors.orange,
            ),
            if (zapAmount != null)
              Text(
                NumberFormat.compact().format(zapAmount),
                style: const TextStyle(color: Colors.orange),
              ),
          ],
        );
    }
    return null;
  }

  String getEllipsisText({
    required String text,
    required double maxWidth,
    required int maxLines,
    TextStyle? style,
    String? ellipsisText = '...',
  }) {
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style,
      ),
      maxLines: maxLines,
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout(maxWidth: maxWidth);
    if (!textPainter.didExceedMaxLines) {
      return text;
    }
    final textSize = textPainter.size;
    final ellipsisTextPainter = TextPainter(
      text: TextSpan(
        text: ellipsisText,
        style: style,
      ),
      maxLines: maxLines,
      textDirection: ui.TextDirection.ltr,
    );
    ellipsisTextPainter.layout(maxWidth: maxWidth);
    final ellipsisWidth = ellipsisTextPainter.size.width;
    if (textPainter.didExceedMaxLines &&
        textSize.width + ellipsisWidth > maxWidth) {
      final textOffsetPosition = textPainter.getOffsetBefore(textPainter
              .getPositionForOffset(
                  Offset(textSize.width - ellipsisWidth, textSize.height))
              .offset) ??
          0;
      return '${text.substring(0, textOffsetPosition)}$ellipsisText';
    } else {
      return text;
    }
  }

  Widget? _activityContentWidget() {
    switch (widget.event.kind) {
      case 1:
      case 9735:
        if ((widget.event.content ?? '') != '') {
          final content = getEllipsisText(
            text: widget.event.content!,
            maxWidth: MediaQuery.sizeOf(context).width - 76,
            maxLines: 5,
          );
          return Padding(
            padding: const EdgeInsets.fromLTRB(60, 0, 0, 16),
            child: PostContent(
              content: content,
              enableMedia: false,
              enablePreview: false,
              enableElementTap: false,
              depth: 1,
            ),
          );
        }
        break;
    }
    return null;
  }

  // Widget? _referenceTypeMessageWidget() {
  //   ThemeData themeData = Theme.of(context);
  //   MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
  //   final me = context.read<AppStatesProvider>().me!;
  //   String? referenceTypeMessage;
  //   if (_referencedEventId != null) {
  //     switch (widget.event.kind) {
  //       case 1:
  //         referenceTypeMessage = isMention(widget.event, me.pubkey)
  //             ? 'Mentioned you in a post'
  //             : 'Replied your post';
  //       case 6:
  //         referenceTypeMessage = 'Reposted your post';
  //       case 7:
  //         referenceTypeMessage = 'Reacted to your post';
  //       case 9735:
  //         referenceTypeMessage = 'Zapped your post';
  //     }
  //   }
  //   if (referenceTypeMessage != null) {
  //     return Padding(
  //       padding: const EdgeInsets.fromLTRB(60, 0, 0, 16),
  //       child: Text(
  //         referenceTypeMessage,
  //         style: TextStyle(
  //           color: themeExtension.textDimColor,
  //         ),
  //       ),
  //     );
  //   } else {
  //     return null;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final appState = context.watch<AppStatesProvider>();
    final activityContentWidget = _activityContentWidget();
    // final referenceTypeMessageWidget =
    //     widget.showReferencedEvent ? _referenceTypeMessageWidget() : null;
    return _user == null
        ? Shimmer.fromColors(
            baseColor: themeExtension.shimmerBaseColor!,
            highlightColor: themeExtension.shimmerHighlightColor!,
            child: ListTile(
              contentPadding: const EdgeInsets.all(0),
              minTileHeight: 64.0,
              horizontalTitleGap: 8,
              leading: const CircleAvatar(),
              title: Container(
                height: 16,
                color: Colors.white,
              ),
              subtitle: Container(
                height: 12,
                color: Colors.white,
              ),
            ),
          )
        : InkWell(
            onTap: widget.enableViewReferencedEventTap &&
                    _referencedEventId != null
                ? () => appState.navigatorPush(
                      widget: PostDetails(
                        eventId: widget.event.kind == 1
                            ? widget.event.id
                            : _referencedEventId,
                      ),
                    )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(0),
                  minTileHeight: 64,
                  horizontalTitleGap: 8,
                  leading: IntrinsicWidth(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: Center(
                            child: _activityIcon(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () =>
                              context.read<AppStatesProvider>().navigatorPush(
                                    widget: Profile(
                                      heroTag: _profileHeroTag,
                                      user: _user!,
                                    ),
                                  ),
                          child: Hero(
                            tag: _profileHeroTag,
                            child: ProfileAvatar(url: _user!.picture),
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: ProfileDisplayName(
                    user: _user!,
                    textStyle: themeData.textTheme.titleMedium,
                    withBadge: true,
                    enableShowProfileAction: true,
                  ),
                  subtitle: _user!.nip05 == null
                      ? null
                      : Text(
                          _user!.nip05!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: Transform.translate(
                    offset: const Offset(4, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_user != null &&
                            !_isMe &&
                            widget.showFollowButton) ...[
                          if (_isFollowing) ...[
                            MenuAnchor(
                              builder: (BuildContext context,
                                  MenuController controller, Widget? child) {
                                return OutlinedButton(
                                  onPressed: () {
                                    if (controller.isOpen) {
                                      controller.close();
                                    } else {
                                      controller.open();
                                    }
                                  },
                                  child: const Text('Following'),
                                );
                              },
                              menuChildren: [
                                MenuItemButton(
                                  onPressed: () async {
                                    await appState.me.unfollow(_user!.pubkey);
                                    setState(() {
                                      _isFollowing = false;
                                    });
                                  },
                                  leadingIcon: Icon(
                                    Icons.person_remove,
                                    color: themeData.colorScheme.error,
                                  ),
                                  child: Text(
                                    'Unfollow',
                                    style: TextStyle(
                                        color: themeData.colorScheme.error),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            FilledButton(
                              onPressed: () async {
                                await appState.me.follow(_user!.pubkey);
                                setState(() {
                                  _isFollowing = true;
                                });
                              },
                              child: const Text('Follow'),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                // if (referenceTypeMessageWidget != null)
                //   referenceTypeMessageWidget,
                if (activityContentWidget != null) activityContentWidget,
                if (widget.showReferencedEvent && _referencedEventId != null)
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(60, 0, 0, 8),
                          child: Container(
                            foregroundDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: themeData.colorScheme.primary,
                              ),
                            ),
                            child: LimitedBox(
                              maxHeight: 108,
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                primary: false,
                                child: PostItemLoader(
                                  eventId: _referencedEventId!,
                                  enableMenu: false,
                                  enableTap: false,
                                  enableElementTap: false,
                                  enableActionBar: false,
                                  enableLocation: false,
                                  enableProofOfWork: false,
                                  enablePreview: false,
                                  enableMedia: false,
                                  depth: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
  }
}
