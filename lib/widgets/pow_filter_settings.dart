import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/constant.dart';
import 'package:wherostr_social/models/app_feed.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/pow_filter.dart';
import 'package:wherostr_social/utils/app_utils.dart';

class PowFilterSettings extends StatefulWidget {
  const PowFilterSettings({super.key});

  @override
  State<PowFilterSettings> createState() => _PowFilterSettingsState();
}

class _PowFilterSettingsState extends State<PowFilterSettings> {
  late PoWfilter _powPost;
  late PoWfilter _powComment;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    final appFeed = context.read<AppFeedProvider>();
    setState(() {
      _powPost = PoWfilter.fromString(appFeed.powPostFilter.toString());
      _powComment = PoWfilter.fromString(appFeed.powCommentFilter.toString());
    });
  }

  _handlePostChange(double value) {
    _setPostValue(value.toInt());
  }

  _setPostValue(int? value) {
    setState(() {
      _powPost.value = value ?? 16;
    });
  }

  _handleCommentChange(double value) {
    _setCommentValue(value.toInt());
  }

  _setCommentValue(int? value) {
    setState(() {
      _powComment.value = value ?? 8;
    });
  }

  save() async {
    final appFeed = context.read<AppFeedProvider>();
    AppUtils.showLoading();
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 200)),
      appFeed.setPoWPostFilter(_powPost),
      appFeed.setPoWCommentFilter(_powComment)
    ]);
    AppUtils.showSnackBar(
      text: 'Saved successfully.',
      status: AppStatus.success,
    );
    AppUtils.hideLoading();
  }

  @override
  Widget build(BuildContext context) {
    final isLargeDisplay =
        MediaQuery.sizeOf(context).width >= Constants.largeDisplayWidth;
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('PoW filters'),
      ),
      bottomNavigationBar: Material(
        borderRadius: isLargeDisplay
            ? const BorderRadiusDirectional.vertical(
                top: Radius.circular(12),
              )
            : null,
        elevation: 1,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () => save(),
              child: const Text("Save"),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Post filter',
                  style: themeData.textTheme.titleMedium,
                ),
              ),
              Text.rich(
                TextSpan(
                  text:
                      'Set the PoW difficulty level to filter incoming posts. Posts that do not meet the specified difficulty will be hidden, ensuring that only high-quality content is shown.',
                  style: TextStyle(color: themeExtension.textDimColor),
                ),
              ),
              ListTile(
                leading: Text(
                  _powPost.value.round().toString(),
                  style: themeData.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _powPost.enabled
                        ? themeData.colorScheme.primary
                        : themeExtension.textDimColor,
                  ),
                ),
                title: Slider(
                  divisions: 48 ~/ 8,
                  value: _powPost.value.toDouble(),
                  label: _powPost.value.round().toString(),
                  min: 0,
                  max: 48,
                  inactiveColor: themeData.colorScheme.surfaceDim,
                  onChanged: _powPost.enabled ? _handlePostChange : null,
                ),
                trailing: Switch(
                  value: _powPost.enabled,
                  onChanged: (value) {
                    setState(() {
                      _powPost.enabled = value;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Comment filter',
                  style: themeData.textTheme.titleMedium,
                ),
              ),
              Text.rich(
                TextSpan(
                  text:
                      'Set the PoW difficulty level to filter incoming comments. Comments that fail to meet the required difficulty will be hidden, helping to reduce spam and low-quality responses.',
                  style: TextStyle(color: themeExtension.textDimColor),
                ),
              ),
              ListTile(
                leading: Text(
                  _powComment.value.round().toString(),
                  style: themeData.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _powComment.enabled
                        ? themeData.colorScheme.primary
                        : themeExtension.textDimColor,
                  ),
                ),
                title: Slider(
                  divisions: 48 ~/ 8,
                  value: _powComment.value.toDouble(),
                  label: _powComment.value.round().toString(),
                  min: 0,
                  max: 48,
                  inactiveColor: themeData.colorScheme.surfaceDim,
                  onChanged: _powComment.enabled ? _handleCommentChange : null,
                ),
                trailing: Switch(
                  value: _powComment.enabled,
                  onChanged: (value) {
                    setState(() {
                      _powComment.enabled = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
