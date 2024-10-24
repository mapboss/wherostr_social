import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/utils/formatter.dart';
import 'package:wherostr_social/utils/nostr_event.dart';
import 'package:wherostr_social/widgets/message_item.dart';
import 'package:wherostr_social/widgets/nostr_feed.dart';
import 'package:wherostr_social/widgets/post_action_bar.dart';
import 'package:wherostr_social/widgets/post_activity.dart';
import 'package:wherostr_social/widgets/post_composer.dart';
import 'package:wherostr_social/widgets/post_item.dart';
import 'package:wherostr_social/widgets/profile.dart';
import 'package:wherostr_social/widgets/profile_avatar.dart';
import 'package:wherostr_social/widgets/video_player.dart';
import 'package:wherostr_social/widgets/zap_form.dart';

class LiveActivity extends StatefulWidget {
  final DataEvent event;

  const LiveActivity({
    super.key,
    required this.event,
  });

  @override
  State<LiveActivity> createState() => _LiveActivityState();
}

class _LiveActivityState extends State<LiveActivity> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  NostrUser? _user;
  DataEvent? _quotedEvent;
  bool _isEmpty = true;
  bool _isLoading = false;
  bool _showLiveChat = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_checkIfTextIsNotEmpty);
    initialize();
  }

  void initialize() async {
    NostrUser user = await NostrService.fetchUser(
        widget.event.getMatchedTag('p')?.elementAtOrNull(1) ??
            widget.event.pubkey);
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_checkIfTextIsNotEmpty);
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleOnReplyTap(DataEvent event) {
    _focusNode.unfocus();
    setState(() {
      _quotedEvent = event;
      Future.delayed(Duration(milliseconds: 300)).then((_) {
        _focusNode.requestFocus();
      });
    });
  }

  void _checkIfTextIsNotEmpty() {
    setState(() {
      _isEmpty = !_messageController.text.trim().isNotEmpty;
    });
  }

  void _handleSendPressed() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _focusNode.unfocus();
      String content = _messageController.text;
      final event = DataEvent(kind: 1311);
      if (_quotedEvent != null) {
        content = 'nostr:${NostrService.instance.utilsService.encodeNevent(
          eventId: _quotedEvent!.id!,
          pubkey: _quotedEvent!.pubkey,
        )}\n$content';
        event.addTagIfNew(['e', _quotedEvent!.id!, '', 'reply']);
        event.addTagIfNew(['p', _quotedEvent!.pubkey]);
      }
      event.content = content.trim();
      event.addTagIfNew(['a', widget.event.getAddressId()!]);
      final me = context.read<AppStatesProvider>().me;
      await event.publish(
        autoGenerateTags: true,
        relays: me.relayList,
      );
      setState(() {
        _quotedEvent = null;
      });
      _messageController.clear();
    } catch (error) {
      AppUtils.handleError();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final appState = context.watch<AppStatesProvider>();
    final relayList = context.read<AppStatesProvider>().me.relayList.clone();
    final url = widget.event.getTagValue('streaming') ??
        widget.event.getTagValue('recording') ??
        '';
    final eventId = widget.event.getAddressId();
    final title = widget.event.tags
        ?.where((tag) => tag.firstOrNull == 'title')
        .firstOrNull
        ?.elementAtOrNull(1);
    final isLive = widget.event.tags
            ?.where((tag) => tag.firstOrNull == 'status')
            .firstOrNull
            ?.elementAtOrNull(1) ==
        'live';
    final starts = widget.event.tags
        ?.where((tag) => tag.firstOrNull == 'starts')
        .firstOrNull
        ?.elementAtOrNull(1);
    final ends = widget.event.tags
        ?.where((tag) => tag.firstOrNull == 'ends')
        .firstOrNull
        ?.elementAtOrNull(1);
    final startDateTime = starts == null
        ? widget.event.createdAt!
        : DateTime.fromMillisecondsSinceEpoch(int.parse(starts) * 1000);
    final endDateTime = ends == null
        ? widget.event.createdAt!
        : DateTime.fromMillisecondsSinceEpoch(int.parse(ends) * 1000);
    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      body: DismissiblePage(
        onDismissed: () {
          Navigator.of(context).pop();
        },
        direction: DismissiblePageDismissDirection.down,
        dismissThresholds: {
          DismissiblePageDismissDirection.down: .4,
        },
        startingOpacity: 0,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: VideoPlayer(
                  url: url,
                  autoPlay: true,
                ),
              ),
              Expanded(
                child: Container(
                  color: themeData.colorScheme.surfaceDim,
                  child: _showLiveChat
                      ? Stack(
                          children: [
                            Positioned.fill(
                              child: Column(
                                children: [
                                  Material(
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 4, 4, 4),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Live chat',
                                                  style: themeData
                                                      .textTheme.titleLarge,
                                                ),
                                              ),
                                              if (_user != null &&
                                                  (_user!.lud06 != null ||
                                                      _user!.lud16 != null))
                                                IconButton.outlined(
                                                  onPressed: () =>
                                                      appState.navigatorPush(
                                                    widget: ZapForm(
                                                      user: _user!,
                                                      event: widget.event,
                                                    ),
                                                    rootNavigator: true,
                                                  ),
                                                  icon: const Icon(
                                                    Icons.electric_bolt,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              IconButton(
                                                onPressed: _isLoading
                                                    ? null
                                                    : () => setState(() {
                                                          _showLiveChat = false;
                                                        }),
                                                icon: Icon(Icons.close),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (_user != null &&
                                            (_user!.lud06 != null ||
                                                _user!.lud16 != null))
                                          SizedBox(
                                            width: double.infinity,
                                            height: 44,
                                            child: NostrFeed(
                                              backgroundColor:
                                                  themeData.colorScheme.surface,
                                              relays: relayList,
                                              scrollDirection: Axis.horizontal,
                                              kinds: const [9735],
                                              a: [eventId!],
                                              disablePullToRefresh: true,
                                              autoRefresh: true,
                                              disableLimit: true,
                                              itemSorting: (a, b) {
                                                String? descA =
                                                    a.getTagValue('bolt11');
                                                String? descB =
                                                    b.getTagValue('bolt11');
                                                final boltB =
                                                    Bolt11PaymentRequest(
                                                        descB!);
                                                return boltB.amount.compareTo(
                                                    Bolt11PaymentRequest(descA!)
                                                        .amount);
                                              },
                                              itemBuilder: (context, event) =>
                                                  ZapChip(event: event),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: NostrFeed(
                                      backgroundColor: themeData
                                          .colorScheme.primary
                                          .withOpacity(0.054),
                                      relays: relayList,
                                      kinds: const [9735, 1311],
                                      a: [eventId!],
                                      disablePullToRefresh: true,
                                      autoRefresh: true,
                                      reverse: true,
                                      isDynamicHeight: true,
                                      itemBuilder: (context, event) => Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 0, 16, 8),
                                        child: MessageItem(
                                          event: event,
                                          isCompact: true,
                                          onReplyTap: () =>
                                              _handleOnReplyTap(event),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(16, 8, 4, 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _messageController,
                                            focusNode: _focusNode,
                                            decoration: InputDecoration(
                                              border:
                                                  const OutlineInputBorder(),
                                              isDense: true,
                                              filled: true,
                                              fillColor: themeData
                                                  .colorScheme.surfaceDim,
                                              prefixIcon: const Icon(
                                                  Icons.comment_outlined),
                                              hintText: 'Send a message',
                                            ),
                                            readOnly: _isLoading,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        _isLoading
                                            ? Padding(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                child: Center(
                                                  child: SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                ))
                                            : IconButton(
                                                onPressed: _isEmpty
                                                    ? null
                                                    : _handleSendPressed,
                                                icon: Icon(Icons.send),
                                                color: _isEmpty
                                                    ? null
                                                    : themeData
                                                        .colorScheme.primary,
                                              ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_quotedEvent != null)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 60,
                                child: Material(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(16, 4, 4, 4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: Container(
                                              foregroundDecoration:
                                                  BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: themeData
                                                      .colorScheme.primary,
                                                ),
                                              ),
                                              child: LimitedBox(
                                                maxHeight: 108,
                                                child: SingleChildScrollView(
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  primary: false,
                                                  child: PostItem(
                                                    key: ValueKey(
                                                        _quotedEvent!.id),
                                                    event: _quotedEvent!,
                                                    enableTap: false,
                                                    enableElementTap: false,
                                                    enableMenu: false,
                                                    enableActionBar: false,
                                                    enableLocation: false,
                                                    enableProofOfWork: false,
                                                    enableShowProfileAction:
                                                        false,
                                                    depth: 1,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        IconButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () => setState(() {
                                                    _quotedEvent = null;
                                                  }),
                                          icon: Icon(Icons.close),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Column(
                          children: [
                            Material(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: PostComposer(
                                      event: widget.event,
                                    ),
                                  ),
                                  if (title != null) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Text(
                                        title,
                                        style: themeData.textTheme.titleLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: isLive
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 8),
                                                  color: Colors.red,
                                                  child: const Row(
                                                    children: [
                                                      Icon(
                                                        Icons.circle,
                                                        color: Colors.white,
                                                        size: 10,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Live',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                formatTimeAgo(startDateTime),
                                                style: themeData
                                                    .textTheme.bodySmall!
                                                    .apply(
                                                        color: themeExtension
                                                            .textDimColor),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            '${isLive ? null : 'Streamed '}${formatTimeAgo(endDateTime)}',
                                            style: themeData
                                                .textTheme.bodySmall!
                                                .apply(
                                                    color: themeExtension
                                                        .textDimColor),
                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: PostActionBar(
                                      event: widget.event,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  FilledButton.icon(
                                    onPressed: () => setState(() {
                                      _showLiveChat = true;
                                    }),
                                    icon: const Icon(Icons.comment_outlined),
                                    label: const Text('Live chat'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => appState.navigatorPush(
                                      widget: PostActivity(
                                        event: widget.event,
                                      ),
                                    ),
                                    label: const Text('View activity'),
                                    icon: const Icon(Icons.navigate_next),
                                    iconAlignment: IconAlignment.end,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ZapChip extends StatefulWidget {
  final DataEvent event;

  const ZapChip({super.key, required this.event});

  @override
  State<ZapChip> createState() => _ZapChipState();
}

class _ZapChipState extends State<ZapChip> {
  NostrUser? _user;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    NostrUser user = await NostrService.fetchUser(
        getZappee(event: widget.event) ?? widget.event.pubkey);
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    double? zapAmount = getZapAmount(event: widget.event);
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: InkWell(
        onTap: () => context.read<AppStatesProvider>().navigatorPush(
              widget: Profile(
                user: _user!,
              ),
            ),
        child: Chip(
          backgroundColor: themeData.colorScheme.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.all(4),
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          avatar: ProfileAvatar(
            url: _user?.picture,
            borderSize: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          label: Text.rich(
            style: const TextStyle(color: Colors.white),
            TextSpan(
              children: [
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    Icons.electric_bolt,
                    color: Colors.orange,
                  ),
                ),
                TextSpan(
                  text: ' ${NumberFormat.compact().format(zapAmount)} ',
                  style: themeData.textTheme.titleMedium!
                      .apply(color: Colors.white),
                ),
                const TextSpan(
                  text: 'sats',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
