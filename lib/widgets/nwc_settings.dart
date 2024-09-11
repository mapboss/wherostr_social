import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nwc/nwc.dart';
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
  NostrWalletConnectUri? _nwcParsed;

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
    setState(() {
      _nwcString = text;
      _nwcParsed = nwc;
    });
    // print('pubkey: ${nwc.pubkey}');
    // print('relay: ${nwc.relay}');
    // print('lud16: ${nwc.lud16}');
    // await AppSecret.writeNWC(text);
    // await initNWC(text);
  }

  void _connect(String nwcString) async {
    // print('pubkey: ${nwc.pubkey}');
    // print('relay: ${nwc.relay}');
    // print('lud16: ${nwc.lud16}');
    await AppSecret.writeNWC(nwcString);
    await initNWC(nwcString);
    setState(() {
      _nwcString = nwcString;
      _nwcParsed = null;
    });
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
        title: const Text('Seamless Zapping'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(64),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: themeExtension.shimmerBaseColor,
                      foregroundImage:
                          const AssetImage('assets/app/ic_launcher.png'),
                    ),
                    const Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.chevron_right),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      backgroundColor: themeExtension.shimmerBaseColor,
                      foregroundColor: Colors.orange,
                      child: const Icon(Icons.electric_bolt),
                    ),
                  ],
                ),
                if (_nwcParsed != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Are you sure you want to connect to this service?",
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _nwcParsed!.relay,
                            style:
                                TextStyle(color: themeExtension.textDimColor),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _nwcParsed!.lud16!,
                            style:
                                TextStyle(color: themeExtension.textDimColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Seamless Zapping Service",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Connect your app for seamless zapping via NWC.",
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: themeExtension.textDimColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_nwcParsed == null && _nwcString == null) ...[
                  FilledButton(
                    onPressed: () async {
                      final clipboardData =
                          await Clipboard.getData('text/plain');
                      if (clipboardData?.text?.isEmpty ?? true) return;
                      _onConnectionURIChange(clipboardData?.text);
                    },
                    iconAlignment: IconAlignment.start,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.paste),
                        Padding(padding: EdgeInsets.fromLTRB(4, 0, 4, 0)),
                        Text("Paste NWC Address"),
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
                ] else if (_nwcParsed != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: _nwcString != null
                            ? () => _connect(_nwcString!)
                            : null,
                        child: const Text('Connect'),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: themeData.colorScheme.error),
                        ),
                        onPressed: () {
                          setState(() {
                            _nwcParsed = null;
                            _nwcString = null;
                          });
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: themeData.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (_nwcString != null)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: themeData.colorScheme.error),
                    ),
                    onPressed: () async {
                      await disposeNWC();
                      await AppSecret.deleteNWC();
                      setState(() {
                        _nwcString = null;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Disconnect",
                          style: TextStyle(
                            color: themeData.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
