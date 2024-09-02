import 'dart:async';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/utils/zap_utils.dart';
import 'package:wherostr_social/widgets/post_item.dart';
import 'package:wherostr_social/widgets/profile_avatar.dart';
import 'package:wherostr_social/widgets/profile_display_name.dart';

const List<int> zapAmountPresets = [
  5,
  10,
  50,
  100,
  500,
  1000,
  5000,
  10000,
  50000,
  100000,
];

class ZapForm extends StatefulWidget {
  final NostrUser user;
  final DataEvent? event;

  const ZapForm({
    super.key,
    required this.user,
    this.event,
  });

  @override
  State createState() => _ZapFormState();
}

class _ZapFormState extends State<ZapForm> {
  final TextEditingController _commentTextController = TextEditingController();
  final TextEditingController _amountTextController = TextEditingController();
  int? _zapAmount;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentTextController.dispose();
    _amountTextController.dispose();
    super.dispose();
  }

  Future<void> _handleZapPressed([bool useQr = false]) async {
    Completer<NostrEvent>? zapCompleter;
    final appState = context.read<AppStatesProvider>();
    setState(() {
      _isLoading = true;
    });
    AppUtils.showSnackBar(
      text: 'Generating invoice...',
      withProgressBar: true,
      autoHide: false,
    );
    try {
      final (zapRequest, invoice) = await createInvoice(
        relays: appState.me.relayList,
        content: _commentTextController.text,
        amount: _zapAmount!,
        targetUser: widget.user,
        targetEvent: widget.event,
      ).timeout(
        const Duration(seconds: 10),
      );
      if (zapRequest == null || invoice?.isNotEmpty != true) {
        AppUtils.showSnackBar(
          text: 'Unable to generate invoice.',
          status: AppStatus.error,
        );
        return;
      }
      AppUtils.hideSnackBar();
      zapCompleter = waitZapReceipt(zapRequest, invoice!);
      if (useQr) {
        showQRInvoiceModal(context, invoice).whenComplete(() {
          if (zapCompleter?.isCompleted != true) {
            zapCompleter?.completeError(Exception());
            if (mounted) {
              setState(() => _isLoading = false);
            }
          }
        });
      } else {
        showDialog(
          context: context,
          useRootNavigator: true,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Zapping'),
              content:
                  const Text('Waiting for Zapping Confirmation to Proceed.'),
              actions: [
                TextButton(
                  onPressed: () {
                    appState.navigatorPop();
                    zapCompleter?.completeError(Exception());
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        ).whenComplete(() {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        });
        await showWalletSelector(context, invoice);
      }
      await zapCompleter.future;
      AppUtils.showSnackBar(
        text: 'Zapped successfully.',
        status: AppStatus.success,
      );
      if (mounted) {
        appState.navigatorPop();
        appState.navigatorPop();
      }
    } on Exception {
    } catch (error) {
      AppUtils.hideSnackBar();
      AppUtils.handleError();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Zap'),
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      if (widget.event == null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              foregroundDecoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: themeData.colorScheme.primary,
                                ),
                              ),
                              child: Material(
                                child: ListTile(
                                  minTileHeight: 64,
                                  horizontalTitleGap: 8,
                                  leading:
                                      ProfileAvatar(url: widget.user.picture),
                                  title: ProfileDisplayName(
                                    user: widget.user,
                                    textStyle: themeData.textTheme.titleMedium,
                                    withBadge: true,
                                  ),
                                  subtitle: widget.user.nip05 == null
                                      ? null
                                      : Text(
                                          widget.user.nip05!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              foregroundDecoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: themeData.colorScheme.primary,
                                ),
                              ),
                              child: Material(
                                child: LimitedBox(
                                  maxHeight: 108,
                                  child: SingleChildScrollView(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    primary: false,
                                    child: PostItem(
                                      event: widget.event!,
                                      enableTap: false,
                                      enableElementTap: false,
                                      enableMenu: false,
                                      enableActionBar: false,
                                      enableLocation: false,
                                      enableProofOfWork: false,
                                      enableShowProfileAction: false,
                                      depth: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                'Comment',
                                style: themeData.textTheme.titleMedium!
                                    .copyWith(
                                        color: themeExtension.textDimColor),
                              ),
                            ),
                            TextField(
                              controller: _commentTextController,
                              decoration: const InputDecoration(
                                filled: true,
                                hintText: 'Add a comment',
                              ),
                              readOnly: _isLoading,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
                              child: Text(
                                'Amount',
                                style: themeData.textTheme.titleMedium!
                                    .copyWith(
                                        color: themeExtension.textDimColor),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                alignment: WrapAlignment.center,
                                children: zapAmountPresets
                                    .map((item) => FilledButton.icon(
                                          onPressed: _isLoading
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _zapAmount = item;
                                                  });
                                                  _amountTextController.text =
                                                      item.toString();
                                                },
                                          icon: const Icon(
                                            Icons.electric_bolt,
                                            color: Colors.orange,
                                          ),
                                          label: Text(
                                              NumberFormat.decimalPattern()
                                                  .format(item)),
                                        ))
                                    .toList(),
                              ),
                            ),
                            TextField(
                              controller: _amountTextController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              maxLength: 8,
                              decoration: const InputDecoration(
                                counterText: '',
                                hintText: 'Zap amount',
                                filled: true,
                                prefixIcon: Icon(
                                  Icons.electric_bolt,
                                  color: Colors.orange,
                                ),
                                suffixText: 'sats',
                              ),
                              readOnly: _isLoading,
                              onChanged: (value) {
                                final zapAmount = int.tryParse(value);
                                if (zapAmount != null && zapAmount > 0) {
                                  setState(() {
                                    _zapAmount = zapAmount;
                                  });
                                } else {
                                  _amountTextController.text = '';
                                  setState(() {
                                    _zapAmount = null;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Material(
                elevation: 1,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: _isLoading || _zapAmount == null
                              ? null
                              : () => _handleZapPressed(true),
                          icon: const Icon(Icons.qr_code),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            onPressed: _isLoading || _zapAmount == null
                                ? null
                                : () => _handleZapPressed(),
                            icon: const Icon(Icons.electric_bolt),
                            label: Text(
                              'Zap ${_zapAmount == null ? '?' : NumberFormat.decimalPattern().format(_zapAmount)} sats',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
