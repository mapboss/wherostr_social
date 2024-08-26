import 'package:flutter/material.dart';
import 'package:wherostr_social/models/nostr_user.dart';

class ProfileValidBadge extends StatefulWidget {
  final NostrUser user;
  final double? size;

  const ProfileValidBadge({super.key, required this.user, this.size});

  @override
  State createState() => _ProfileValidBadgeState();
}

class _ProfileValidBadgeState extends State<ProfileValidBadge> {
  bool? _isValid;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    final isValid = await widget.user.verifyNostrAddress();
    if (mounted) {
      setState(() {
        _isValid = isValid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return _isValid == null
        ? const SizedBox.shrink()
        : _isValid == true
            ? ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (Rect bounds) => RadialGradient(
                  colors: [
                    themeData.colorScheme.secondary,
                    themeData.colorScheme.primary,
                  ],
                  stops: const [0.38, 0.87],
                ).createShader(bounds),
                child: Icon(
                  Icons.check_circle_outline_outlined,
                  color: themeData.colorScheme.primary,
                  size: widget.size,
                ),
              )
            : Icon(
                Icons.error_outline_outlined,
                color: themeData.colorScheme.error,
                size: widget.size,
              );
  }
}
