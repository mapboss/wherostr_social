import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/widgets/profile.dart';
import 'package:wherostr_social/widgets/profile_valid_badge.dart';

class ProfileDisplayName extends StatefulWidget {
  final NostrUser? user;
  final String? pubkey;
  final TextStyle? textStyle;
  final bool withAtSign;
  final bool withBadge;
  final bool enableShowProfileAction;

  const ProfileDisplayName({
    super.key,
    this.user,
    this.pubkey,
    this.textStyle,
    this.withAtSign = false,
    this.withBadge = false,
    this.enableShowProfileAction = false,
  });

  @override
  State createState() => _ProfileDisplayNameState();
}

class _ProfileDisplayNameState extends State<ProfileDisplayName> {
  NostrUser? _user;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    NostrUser? user;
    if (widget.user != null) {
      user = widget.user;
    } else if (widget.pubkey != null) {
      user = await NostrService.fetchUser(widget.pubkey!);
    }
    if (mounted && user != null) {
      setState(() {
        _user = user;
      });
    }
  }

  void _showProfile() {
    context.read<AppStatesProvider>().navigatorPush(
          widget: Profile(
            user: _user!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Row(
        children: [
          Flexible(
            child: InkWell(
              onTap: widget.enableShowProfileAction && _user != null
                  ? _showProfile
                  : null,
              child: Text(
                '${widget.withAtSign ? '@' : ''}${_user?.displayName ?? ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: widget.textStyle,
              ),
            ),
          ),
          if (widget.withBadge && _user != null) ...[
            const SizedBox(width: 4),
            ProfileValidBadge(
              user: _user!,
              size: widget.textStyle?.fontSize ??
                  DefaultTextStyle.of(context).style.fontSize,
            ),
          ],
        ],
      ),
    );
  }
}
