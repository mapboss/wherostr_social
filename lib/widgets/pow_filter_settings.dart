import 'package:flutter/material.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/utils/app_utils.dart';

class PowFilterSettings extends StatefulWidget {
  const PowFilterSettings({super.key});

  @override
  State<PowFilterSettings> createState() => _PowFilterSettingsState();
}

class _PowFilterSettingsState extends State<PowFilterSettings> {
  int _powPost = 16;
  int _powReply = 8;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {}

  _handlePostChange(double value) {
    _setPostValue(value.toInt());
  }

  _setPostValue(int? value) {
    setState(() {
      _powPost = value ?? 16;
    });
  }

  _handleReplyChange(double value) {
    _setReplyValue(value.toInt());
  }

  _setReplyValue(int? value) {
    setState(() {
      _powReply = value ?? 8;
    });
  }

  save() async {
    AppUtils.showLoading();
    await Future.delayed(const Duration(milliseconds: 500));
    AppUtils.showSnackBar(
      text: 'Saved successfully.',
      status: AppStatus.success,
    );
    AppUtils.hideLoading();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('PoW Filters'),
      ),
      bottomNavigationBar: Material(
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
        child: Material(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Post',
                  style: TextStyle(color: themeExtension.textDimColor),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.memory),
                title: Slider(
                  divisions: 48 ~/ 8,
                  value: _powPost.toDouble(),
                  label: _powPost.round().toString(),
                  min: 0,
                  max: 48,
                  inactiveColor: themeData.colorScheme.surfaceDim,
                  onChanged: _handlePostChange,
                ),
                trailing: Text(
                  _powPost.round().toString(),
                  style: themeData.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeData.colorScheme.primary,
                  ),
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Comment',
                  style: TextStyle(color: themeExtension.textDimColor),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.memory),
                title: Slider(
                  divisions: 48 ~/ 8,
                  value: _powReply.toDouble(),
                  label: _powReply.round().toString(),
                  min: 0,
                  max: 48,
                  inactiveColor: themeData.colorScheme.surfaceDim,
                  onChanged: _handleReplyChange,
                ),
                trailing: Text(
                  _powReply.round().toString(),
                  style: themeData.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeData.colorScheme.primary,
                  ),
                ),
              ),
              // const Divider(),
              // Padding(
              //   padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              //   child: Text(
              //     'Language',
              //     style: TextStyle(color: themeExtension.textDimColor),
              //   ),
              // ),
              // ListTile(
              //   leading: const Icon(Icons.key),
              //   title: const Text('Language'),
              //   trailing: const Icon(Icons.arrow_forward_ios),
              //   onTap: () {
              //     var appLocale = context.read<AppLocaleProvider>();
              //     if (appLocale.locale == const Locale('th')) {
              //       appLocale.setLocale(const Locale('en'));
              //     } else {
              //       appLocale.setLocale(const Locale('th'));
              //     }
              //   },
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
