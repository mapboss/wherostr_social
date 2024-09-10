import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wherostr_social/models/app_secret.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/utils/nwc.dart';
import 'package:wherostr_social/widgets/qr_scanner.dart';

class NWCSettings extends StatefulWidget {
  const NWCSettings({super.key});

  @override
  State<NWCSettings> createState() => _NWCSettingsState();
}

class _NWCSettingsState extends State<NWCSettings> {
  String? _nwcString;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    final connectionString = await AppSecret.readNWC();
    getBalance();
    setState(() {
      _nwcString = connectionString;
    });
  }

  void _onConnectionURIChange(String? text) async {
    if (text?.isEmpty ?? true) return;
    final nwc = parseNostrConnectUri(text!);
    print('pubkey: ${nwc.pubkey}');
    print('relay: ${nwc.relay}');
    print('lud16: ${nwc.lud16}');
    await AppSecret.writeNWC(text);
    setState(() {
      _nwcString = text;
    });
    await initNWC(text);
  }

  bool _handleScanned(BarcodeCapture data) {
    final text = data.barcodes.firstOrNull?.displayValue;
    if (text == null) return false;
    _onConnectionURIChange(text);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('NWC'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                // crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: themeExtension.shimmerBaseColor,
                    child: Icon(Icons.abc),
                  ),
                  Row(
                    children: [
                      Icon(Icons.chevron_right),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: themeExtension.shimmerBaseColor,
                    child: Icon(Icons.wallet),
                  ),
                ],
              ),
              Text("Nostr Wallet Connect"),
              if (_nwcString == null) ...[
                FilledButton(
                  onPressed: () async {
                    final clipboardData = await Clipboard.getData('text/plain');
                    if (clipboardData?.text?.isEmpty ?? true) return;
                    _onConnectionURIChange(clipboardData?.text);
                  },
                  iconAlignment: IconAlignment.start,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.paste),
                      Padding(padding: EdgeInsets.fromLTRB(4, 0, 4, 0)),
                      Text("Past NWC Address"),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      useRootNavigator: true,
                      enableDrag: true,
                      showDragHandle: true,
                      context: context,
                      builder: (context) {
                        return FractionallySizedBox(
                          heightFactor: 0.75,
                          child: QrScanner(
                            text: "Scan NWC address QR code.",
                            onScan: _handleScanned,
                          ),
                        );
                      },
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code),
                      Padding(padding: EdgeInsets.fromLTRB(4, 0, 4, 0)),
                      Text("Scan NWC Address"),
                    ],
                  ),
                ),
              ] else
                FilledButton(
                  onPressed: () async {
                    await dispose();
                    await AppSecret.deleteNWC();
                    setState(() {
                      _nwcString = null;
                    });
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Disconnect"),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
