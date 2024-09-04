import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/widgets/post_item.dart';

class PostItemLoader extends StatefulWidget {
  final String eventId;
  final DataRelayList? relays;
  final bool enableShowProfileAction;
  final bool enableMenu;
  final bool enableTap;
  final bool enableElementTap;
  final bool enableActionBar;
  final bool enableLocation;
  final bool enableProofOfWork;
  final bool enablePreview;
  final bool enableMedia;
  final EdgeInsetsGeometry? contentPadding;
  final int depth;
  final double? maxHeight;

  const PostItemLoader({
    super.key,
    required this.eventId,
    this.relays,
    this.enableShowProfileAction = true,
    this.enableMenu = true,
    this.enableTap = true,
    this.enableElementTap = true,
    this.enableActionBar = true,
    this.enableLocation = true,
    this.enableProofOfWork = true,
    this.enablePreview = true,
    this.enableMedia = true,
    this.contentPadding,
    this.depth = 0,
    this.maxHeight,
  });

  @override
  State createState() => _PostItemLoaderState();
}

class _PostItemLoaderState extends State<PostItemLoader> {
  bool _loading = true;
  DataEvent? _event;

  @override
  void initState() {
    super.initState();
    fetchEvent();
  }

  void fetchEvent() async {
    final me = context.read<AppStatesProvider>().me;
    final event = await NostrService.fetchEventById(
      widget.eventId,
      relays: me.relayList.concat(widget.relays),
    );
    if (mounted) {
      setState(() {
        _loading = false;
        _event = event;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return _loading
        ? Shimmer.fromColors(
            baseColor: themeExtension.shimmerBaseColor!,
            highlightColor: themeExtension.shimmerHighlightColor!,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      ListTile(
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
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        : _event == null
            ? SizedBox(
                width: double.infinity,
                height: 108,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text('Sorry, unable to retrieve the post.'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                          });
                          Future.delayed(const Duration(milliseconds: 300),
                              () => fetchEvent());
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : PostItem(
                event: _event!,
                enableShowProfileAction: widget.enableShowProfileAction,
                enableMenu: widget.enableMenu,
                enableTap: widget.enableTap,
                enableElementTap: widget.enableElementTap,
                enableActionBar: widget.enableActionBar,
                enableLocation: widget.enableLocation,
                enableProofOfWork: widget.enableProofOfWork,
                enablePreview: widget.enablePreview,
                enableMedia: widget.enableMedia,
                contentPadding: widget.contentPadding,
                depth: widget.depth,
                maxHeight: widget.maxHeight,
              );
  }
}
