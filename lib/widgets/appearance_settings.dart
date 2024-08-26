import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_theme.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    setState(() {
      _isDarkMode =
          context.read<AppThemeProvider>().themeMode == ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: SingleChildScrollView(
        child: Material(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Theme',
                  style: TextStyle(color: themeExtension.textDimColor),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark mode'),
                trailing: Switch(
                  value: _isDarkMode,
                  onChanged: (value) {
                    context
                        .read<AppThemeProvider>()
                        .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                    setState(() {
                      _isDarkMode = value;
                    });
                  },
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
