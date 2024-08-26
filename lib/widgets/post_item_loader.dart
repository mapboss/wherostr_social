import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/widgets/post_item.dart';

const pubkey =
    'd67e88b9279a53626c9f716c976718ad245c45ffe2463119424d19b34bf845ac';

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
    initialize();
  }

  void initialize() async {
    final event = await NostrService.fetchEventById(
      widget.eventId,
      relays: widget.relays,
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
    return _loading && _event == null
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
        : _event != null
            ? PostItem(
                event: _event!,
                enableShowProfileAction: widget.enableShowProfileAction,
                enableMenu: widget.enableMenu,
                enableTap: widget.enableTap,
                enableElementTap: widget.enableElementTap,
                enableActionBar: widget.enableActionBar,
                enableLocation: widget.enableLocation,
                enableProofOfWork: widget.enableProofOfWork,
                enablePreview: widget.enablePreview,
                contentPadding: widget.contentPadding,
                depth: widget.depth,
                maxHeight: widget.maxHeight,
              )
            : const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text('Event not found.'),
                ),
              );
  }
}
