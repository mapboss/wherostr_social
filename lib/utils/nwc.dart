import 'dart:async';
import 'dart:convert';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:nwc/nwc.dart';
import 'package:nwc/src/utils/exceptions.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/models/nostr_user.dart';

Nostr nwcInstance = Nostr();
NWC nwc = NWC();
late NostrWalletConnectUri parsedUri;
final completers = <String, Completer<String>>{};

Future<void> initNWC(String connectionURI) async {
  await nwc.dispose();
  await nwcInstance.dispose();
  nwc = NWC();
  nwcInstance = Nostr();
  parsedUri = nwc.nip47.parseNostrConnectUri(connectionURI);
  await nwcInstance.relaysService.init(relaysUrl: [parsedUri.relay]);

  final subToFilter = NostrRequest(
    filters: [
      NostrFilter(
        kinds: const [23195],
        authors: [parsedUri.pubkey],
        since: DateTime.now(),
      )
    ],
  );

  final nostrStream = nwcInstance.relaysService.startEventsSubscription(
    request: subToFilter,
    onEose: (relay, eose) =>
        print('[+] subscriptionId: ${eose.subscriptionId}, relay: $relay'),
  );

  nostrStream.stream.listen((NostrEvent event) {
    if (event.kind == 23195 && event.content != null) {
      try {
        final decryptedContent = nwc.nip04.decrypt(
          parsedUri.secret,
          parsedUri.pubkey,
          event.content!,
        );

        final content = nwc.nip47.parseResponseResult(decryptedContent);
        if (content.resultType == NWCResultType.get_balance) {
          final result = content.result as Get_Balance_Result;
          print('[+] Balance: ${result.balance} msat');
        } else if (content.resultType == NWCResultType.make_invoice) {
          final result = content.result as Make_Invoice_Result;
          print('[+] Invoice: ${result.invoice}');
          completers[result.resultType]?.complete(result.invoice);
        } else if (content.resultType == NWCResultType.pay_invoice) {
          final result = content.result as Pay_Invoice_Result;
          print('[+] Preimage: ${result.preimage}');
          print('[+] Result: ${result.props}');
          completers[result.resultType]?.complete(result.preimage);
        } else if (content.resultType == NWCResultType.list_transactions) {
          final result = content.result as List_Transactions_Result;
          print(
              '[+] First Tx description: ${result.transactions.first.description}');
        } else if (content.resultType == NWCResultType.error) {
          final result = content.result as NWC_Error_Result;
          print('[+] Preimage: ${result.errorMessage}');
        } else {
          print('[+] content: $decryptedContent');
        }
      } catch (e) {
        if (e is DecipherFailedException) {
          print('$e');
        }
      }
    }
  });

  // await getBalance();
  // await makeInvoice(nwc, parsedUri);
  // await payInvoice(nwc, parsedUri);
  // await listTransactions();
}

NostrWalletConnectUri parseNostrConnectUri(String connectionURI) {
  return nwc.nip47.parseNostrConnectUri(connectionURI);
}

Future<void> getBalance() async {
  final message = {"method": "get_balance"};

  final content = nwc.nip04.encrypt(
    parsedUri.secret,
    parsedUri.pubkey,
    jsonEncode(message),
  );

  final request = NostrEvent.fromPartialData(
    kind: 23194,
    content: content,
    tags: [
      ['p', parsedUri.pubkey]
    ],
    createdAt: DateTime.now(),
    keyPairs: NostrKeyPairs(private: parsedUri.secret),
  );

  final okCommand = await nwcInstance.relaysService.sendEventToRelaysAsync(
    request,
    timeout: const Duration(seconds: 3),
  );

  print('[+] getBalance() => okCommand: $okCommand');
}

Future<String?> makeInvoice({
  required int amount,
  required NostrUser targetUser,
  required DataRelayList relays,
  DataEvent? targetEvent,
  String? content,
}) async {
  final message = {
    "method": "make_invoice",
    "params": {
      "amount": amount * 1000, // value in msats
      "description": content, // invoice's description, optional
    }
  };
  completers['make_invoice'] = Completer();
  final ncryptedContent = nwc.nip04.encrypt(
    parsedUri.secret,
    parsedUri.pubkey,
    jsonEncode(message),
  );

  final eventId = targetEvent?.getId();

  final request = NostrEvent.fromPartialData(
    kind: 23194,
    content: ncryptedContent,
    tags: [
      if (eventId != null && (targetEvent?.kind ?? 0) < 30000) ['e', eventId],
      if (eventId != null && (targetEvent?.kind ?? 0) > 30000) ['a', eventId],
      ['p', targetUser.pubkey]
    ],
    createdAt: DateTime.now(),
    keyPairs: NostrKeyPairs(private: parsedUri.secret),
  );
  print('request: $request');

  final okCommand = await nwcInstance.relaysService.sendEventToRelaysAsync(
    request,
    timeout: const Duration(seconds: 3),
  );
  print('[+] makeInvoice() => okCommand: $okCommand');
  return completers['make_invoice']
      ?.future
      .timeout(const Duration(seconds: 5))
      .whenComplete(() {
    completers.remove('make_invoice');
  });
}

Future<String?> payInvoice(String invoice) async {
  final message = {
    "method": "pay_invoice",
    "params": {
      "invoice": invoice,
    }
  };
  completers['pay_invoice'] = Completer();
  final content = nwc.nip04.encrypt(
    parsedUri.secret,
    parsedUri.pubkey,
    jsonEncode(message),
  );

  final request = NostrEvent.fromPartialData(
    kind: 23194,
    content: content,
    tags: [
      ['p', parsedUri.pubkey]
    ],
    createdAt: DateTime.now(),
    keyPairs: NostrKeyPairs(private: parsedUri.secret),
  );

  final okCommand = await nwcInstance.relaysService.sendEventToRelaysAsync(
    request,
    timeout: const Duration(seconds: 3),
  );

  print('[+] payInvoice() => okCommand: $okCommand');
  return completers['pay_invoice']
      ?.future
      .timeout(const Duration(seconds: 5))
      .whenComplete(() {
    completers.remove('pay_invoice');
  });
}

Future<void> listTransactions() async {
  final message = {
    "method": "list_transactions",
    "params": {
      "limit": 10,
    }
  };

  final content = nwc.nip04.encrypt(
    parsedUri.secret,
    parsedUri.pubkey,
    jsonEncode(message),
  );

  final request = NostrEvent.fromPartialData(
    kind: 23194,
    content: content,
    tags: [
      ['p', parsedUri.pubkey]
    ],
    createdAt: DateTime.now(),
    keyPairs: NostrKeyPairs(private: parsedUri.secret),
  );

  final okCommand = await nwcInstance.relaysService.sendEventToRelaysAsync(
    request,
    timeout: const Duration(seconds: 3),
  );

  print('[+] listTransactions() => okCommand: $okCommand');
}

Future<void> dispose() async {
  await Future.wait([
    nwc.dispose(),
    nwcInstance.dispose(),
  ]);
}
