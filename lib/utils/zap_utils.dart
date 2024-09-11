import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:convert/convert.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wherostr_social/constant.dart';
import 'package:wherostr_social/models/app_relays.dart';
import 'package:wherostr_social/models/app_secret.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:http/http.dart' as http;
import 'package:appcheck/appcheck.dart';
import 'package:wherostr_social/utils/app_utils.dart';

final appCheck = AppCheck();
Future<(NostrEvent?, String?)> createInvoice({
  required int amount,
  required NostrUser targetUser,
  required DataRelayList relays,
  NostrEvent? targetEvent,
  String? content,
}) async {
  final keyPairs = await AppSecret.read();
  final millisats = amount * 1000;
  final zapEndpoint = await getZapEndpoint(targetUser);
  if (zapEndpoint != null) {
    final lnurl = encodeLNUrl(zapEndpoint);
    final zapRequest = makeZapRequest(
      keyPairs: keyPairs!,
      relays: relays,
      pubkey: targetUser.pubkey,
      lnurl: lnurl,
      eventId: targetEvent?.id,
      amount: millisats,
      content: content ?? '',
    );
    final invoice = await getInvoice(
      zapRequest: zapRequest,
      amount: millisats,
      zapEndpoint: zapEndpoint,
    );

    return (zapRequest, invoice);
  }
  return (null, null);
}

String encodeLNUrl(String zapEndpoint) {
  return Nostr.instance.utilsService
      .encodeBech32(hex.encode(ascii.encode(zapEndpoint)), 'lnurl');
}

Completer<NostrEvent> waitZapReceipt(NostrEvent zapRequest, String invoice) {
  Completer<NostrEvent> completer = Completer();
  try {
    var e = zapRequest.tags
        ?.where((e) => e.first == 'e')
        .map((e) => e.elementAt(1))
        .toList();
    var a = zapRequest.tags
        ?.where((e) => e.first == 'a')
        .map((e) => e.elementAt(1))
        .toList();
    var p = zapRequest.tags
        ?.where((e) => e.first == 'p')
        .map((e) => e.elementAt(1))
        .toList();

    var request = NostrFilter(
      e: e?.isNotEmpty == true ? e! : null,
      a: a?.isNotEmpty == true ? a! : null,
      p: p?.isNotEmpty == true ? p! : null,
      kinds: const [9735],
      since: DateTime.now(),
    );
    var sub = NostrService.subscribe([request]);
    var listener = sub.stream.listen((NostrEvent event) {
      String? description = event.tags
          ?.singleWhere((e) => e.firstOrNull == 'description')
          .elementAtOrNull(1);
      if (description != null) {
        var mapdesc = jsonDecode(description);
        if (mapdesc['sig'] == zapRequest.sig) {
          completer.complete(event);
        }
      }
    });
    completer.future.whenComplete(() {
      listener.cancel();
      sub.close();
    });
  } catch (err) {
    completer.completeError(err);
  }
  return completer;
}

Future<String?> getZapEndpoint(NostrUser user) async {
  try {
    Uri? lnurl;
    if (user.lud16 != null) {
      var [name, domain] = user.lud16!.split('@');
      lnurl = Uri.parse('https://$domain/.well-known/lnurlp/$name');
    } else if (user.lud06 != null) {
      var [hexdata, hrp] =
          NostrService.instance.utilsService.decodeBech32(user.lud06!);
      var bytes = Uint8List.fromList(hex.decode(hexdata));
      lnurl = Uri.parse(ascii.decode(bytes));
    } else {
      return null;
    }

    var request = http.Request('GET', lnurl);
    final response = await http.Response.fromStream(
            await request.send().timeout(const Duration(seconds: 5)))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse["allowsNostr"] == true &&
          jsonResponse["nostrPubkey"] != null) {
        return jsonResponse['callback'];
      }
    }

    // let res = await _fetch(lnurl)
    // let body = await res.json()

    // if (body.allowsNostr && body.nostrPubkey) {
    //   return body.callback
    // }
  } catch (err) {
    /*-*/
  }

  return null;
}

NostrEvent makeZapRequest({
  required NostrKeyPairs keyPairs,
  required String pubkey,
  required String lnurl,
  required int amount,
  required DataRelayList relays,
  List<List<String>>? extraTags,
  String? eventId,
  String content = '',
}) {
  final writeRelays = relays
      .clone()
      .leftCombine(AppRelays.relays)
      .leftCombine(AppRelays.defaults)
      .writeRelays;
  return NostrEvent.fromPartialData(
    kind: 9734,
    content: content,
    keyPairs: keyPairs,
    tags: [
      ['relays', ...?writeRelays],
      ['amount', amount.toString()],
      ['lnurl', lnurl],
      ...?extraTags,
      ['p', pubkey],
      if (eventId != null) ...[
        [!eventId.contains(":") ? 'e' : 'a', eventId]
      ]
    ],
  );
}

Future<String?> getInvoice({
  required NostrEvent zapRequest,
  required int amount,
  required String zapEndpoint,
}) async {
  var url = Uri.parse(zapEndpoint).replace(queryParameters: {
    "amount": amount.toString(),
    "nostr": jsonEncode(zapRequest.toMap())
  });
  var request = http.Request('GET', url);
  final response = await http.Response.fromStream(await request.send());
  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    return jsonResponse['pr'];
  }

  return null;
}

Future<void> showQRInvoiceModal(BuildContext context, String invoice) async {
  ThemeData themeData = Theme.of(context);
  final TextEditingController invoiceTextController = TextEditingController();
  invoiceTextController.text = invoice;
  return showModalBottomSheet(
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    context: context,
    constraints: const BoxConstraints(
      maxWidth: Constants.largeDisplayContentWidth,
    ),
    builder: (context) {
      double qrSize =
          (MediaQuery.sizeOf(context).height < MediaQuery.sizeOf(context).width
                  ? MediaQuery.sizeOf(context).height
                  : MediaQuery.sizeOf(context).width) *
              0.5;
      if (qrSize > 240) {
        qrSize = 240;
      }
      return DecoratedBox(
        decoration: wherostrBackgroundDecoration,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lightning invoice',
                  style: themeData.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  readOnly: true,
                  controller: invoiceTextController,
                  decoration: InputDecoration(
                    filled: true,
                    suffix: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: invoiceTextController.text,
                          ),
                        );
                        AppUtils.showSnackBar(
                          text: 'Invoice copied',
                          status: AppStatus.success,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                QrImageView(
                  size: qrSize,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  data: invoice,
                  embeddedImage: const AssetImage('assets/app/logo-light.png'),
                ),
                const SizedBox(height: 16),
                const Text('Waiting for Zapping Confirmation to Proceed.'),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class MyAppInfo extends AppInfo {
  final String? appStoreUrl;
  final String? bundleName;
  final String? googlePlayUrl;
  final String? appIcon;
  MyAppInfo({
    required super.packageName,
    required this.bundleName,
    this.appStoreUrl,
    this.googlePlayUrl,
    this.appIcon,
    super.appName,
    super.isSystemApp,
    super.versionName,
  });
}

final List<MyAppInfo> walletApps = [
  MyAppInfo(
    packageName: "walletofsatoshi:",
    bundleName: "com.livingroomofsatoshi.wallet",
    appName: "Wallet of Satoshi",
    appStoreUrl: 'https://apps.apple.com/au/app/wallet-of-satoshi/id1438599608',
    googlePlayUrl:
        'https://play.google.com/store/apps/details?id=com.livingroomofsatoshi.wallet',
  ),
  MyAppInfo(
    packageName: "zeusln:",
    bundleName: "app.zeusln.zeus",
    appName: "Zeus Wallet",
    appStoreUrl: 'https://apps.apple.com/th/app/zeus-wallet/id1456038895',
    googlePlayUrl:
        'https://play.google.com/store/apps/details?id=app.zeusln.zeus',
  ),
  MyAppInfo(
    packageName: "lifpay:",
    bundleName: "flutter.android.LifePay",
    appName: "LifPay ",
    appStoreUrl:
        'https://apps.apple.com/th/app/lifpay/id1645840182?platform=iphone',
    googlePlayUrl:
        'https://play.google.com/store/apps/details?id=flutter.android.LifePay&hl=en&gl=US',
  ),
  MyAppInfo(
    packageName: "phoenix:",
    bundleName: "fr.acinq.phoenix.mainnet",
    appName: "Phoenix",
    appStoreUrl: 'https://apps.apple.com/au/app/phoenix-wallet/id1544097028',
    googlePlayUrl:
        'https://play.google.com/store/apps/details?id=fr.acinq.phoenix.mainnet',
  ),
  MyAppInfo(
    packageName: "muun:",
    bundleName: "io.muun.apollo",
    appName: "Muun",
    appStoreUrl: 'https://apps.apple.com/au/app/muun-wallet/id1482037683',
    googlePlayUrl:
        'https://play.google.com/store/apps/details?id=io.muun.apollo',
  ),
  MyAppInfo(
    packageName: "breez:",
    bundleName: "com.breez.client",
    appName: "Breez",
    appStoreUrl:
        'https://apps.apple.com/au/app/breez-lightning-client-pos/id1463604142',
    googlePlayUrl:
        'https://play.google.com/store/apps/details?id=com.breez.client',
  ),
  MyAppInfo(
    packageName: "bluewallet:",
    bundleName: 'io.bluewallet.bluewallet',
    appName: "BlueWallet",
    appStoreUrl:
        "https://apps.apple.com/au/app/bluewallet-bitcoin-wallet/id1376878040",
    googlePlayUrl:
        'https://play.google.com/store/apps/details?id=io.bluewallet.bluewallet',
  ),
  MyAppInfo(
    packageName: "zebedee:",
    bundleName: 'io.zebedee.wallet',
    appName: "Zebedee",
    appStoreUrl:
        'https://apps.apple.com/au/app/zbd-earn-bitcoin-rewards/id1484394401',
    googlePlayUrl:
        'https://play.google.com/store/apps/details?id=io.zebedee.wallet',
  ),
];
Future<void> showWalletSelector(BuildContext context, String invoice) async {
  List<MyAppInfo> availableApps = [];
  await Future.wait(walletApps.map((e) async {
    bool isAppInstalled = false;
    if (Platform.isIOS) {
      isAppInstalled = await appCheck.isAppInstalled(e.packageName);
    } else if (Platform.isAndroid) {
      isAppInstalled = await appCheck.isAppInstalled(e.bundleName!);
    }
    if (isAppInstalled) {
      availableApps.add(e);
    }
  }));
  if (availableApps.length == 1) {
    await launchUrl(Uri.parse(availableApps[0].packageName + invoice));
    return;
  }
  if (Platform.isAndroid && availableApps.isNotEmpty) {
    await launchUrl(Uri.parse('lightning:$invoice'));
    return;
  }
  ThemeData themeData = Theme.of(context);
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    enableDrag: true,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return Container(
        color: themeData.colorScheme.surfaceDim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select a lightning wallet',
                  style: themeData.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                ...availableApps.map(
                  (e) {
                    return Card(
                      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                      child: ListTile(
                        title: Text(e.appName!),
                        trailing: FilledButton(
                          onPressed: () async {
                            var appState = context.read<AppStatesProvider>();
                            appState.navigatorPop();
                            await Future.delayed(
                                const Duration(milliseconds: 300));
                            await launchUrl(
                                Uri.parse('${e.packageName}$invoice'));
                          },
                          child: const Text("Open"),
                        ),
                      ),
                    );
                  },
                ),
                ...walletApps.where((e) => !availableApps.contains(e)).map((e) {
                  return Card(
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                    child: ListTile(
                      title: Text(e.appName!),
                      trailing: FilledButton(
                        onPressed: () async {
                          var appState = context.read<AppStatesProvider>();
                          appState.navigatorPop();
                          await Future.delayed(
                              const Duration(milliseconds: 300));
                          if (Platform.isIOS) {
                            await launchUrl(Uri.parse(e.appStoreUrl!));
                          } else if (Platform.isAndroid) {
                            await launchUrl(Uri.parse(e.googlePlayUrl!));
                          }
                        },
                        child: const Text("Get"),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    },
  );
}
