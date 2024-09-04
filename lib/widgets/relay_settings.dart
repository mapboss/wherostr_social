import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/extension/nostr_instance.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_relay.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/widgets/relay_item_menu.dart';

final wssDNSPattern =
    RegExp(r'^wss?:\/\/(?:[A-Za-z0-9-]+.)+[A-Za-z]{2,6}(?::[0-9]{1,5})?$');
final wssIPPattern =
    RegExp(r'^(wss?:\/\/)([0-9]{1,3}(?:\.[0-9]{1,3}){3}|[^\/]+):([0-9]{1,5})$');

class RelaySettings extends StatefulWidget {
  const RelaySettings({super.key});

  @override
  State<RelaySettings> createState() => _RelaySettingsState();
}

class _RelaySettingsState extends State<RelaySettings> {
  final _formKey = GlobalKey<FormState>();
  String? _relayUrl;
  DataRelayList? _relays;
  String? _urlError;
  bool _isLoading = true;
  bool _isInitialzed = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    final appState = context.read<AppStatesProvider>();
    final relays = await appState.me.fetchRelayList();
    setState(() {
      _isInitialzed = true;
      _isLoading = false;
      _relays = relays.clone();
      _relays?.sort((a, b) => a.url.compareTo(b.url));
    });
  }

  void addRelay(String url, [String? marker]) async {
    try {
      final relay = DataRelay(url: url, marker: marker);
      await relay.getRelayInformation();
      setState(() {
        _relays?.add(relay);
        _relays?.sort((a, b) => a.url.compareTo(b.url));
        _formKey.currentState?.reset();
      });
    } catch (err) {
      setState(() {
        _urlError = 'Unable to connect to the URL';
      });
    }
  }

  void updateRelay(String relay, [String? marker]) async {
    if (_relays == null) return;
    int? index = _relays?.indexWhere((e) => e.url == relay);
    if (index == null || index == -1) return;
    setState(() {
      _relays?[index].marker = marker;
    });
  }

  Future<void> deleteRelay(String relay) async {
    setState(() {
      _relays?.removeWhere((e) => e.url == relay);
    });
  }

  Future<void> save() async {
    try {
      final appState = context.read<AppStatesProvider>();
      final instance = NostrService.instance;
      AppUtils.showLoading();
      if (_relays != null) {
        final relaysList = instance.relaysService.relaysList?.toList() ?? [];
        instance.enableLogs();
        await instance.relaysService.init(
          relaysUrl: _relays!.toListString(),
          connectionTimeout: const Duration(seconds: 5),
          retryOnError: true,
          shouldReconnectToRelayOnNotice: true,
        );
        instance.disableLogs();
        await appState.setRelays(_relays!);
        await Future.wait(relaysList.map((e) async {
          final index = _relays?.indexWhere((item) => item.url == e);
          if (index != null && index > -1) return;
          return instance.disposeRelay(e);
        }));
      }
      AppUtils.showSnackBar(
        text: 'Saved successfully.',
        status: AppStatus.success,
      );
    } catch (err) {
      AppUtils.handleError();
    } finally {
      AppUtils.hideLoading();
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relays'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Container(
              color: themeData.colorScheme.surfaceDim,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Add a relay',
                    style: themeData.textTheme.titleMedium!
                        .copyWith(color: themeExtension.textDimColor),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: _isLoading,
                          decoration: InputDecoration(
                            errorText: _urlError,
                            filled: true,
                            helperText: " ",
                            hintText: 'relay.example.com',
                            prefixIconConstraints: const BoxConstraints(),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                "wss://",
                                style: TextStyle(
                                    color: themeExtension.textDimColor,
                                    fontSize: 18),
                              ),
                            ),
                          ),
                          initialValue: '',
                          onSaved: (value) => _relayUrl = 'wss://$value',
                          onChanged: (value) {
                            setState(() {
                              _urlError = null;
                            });
                          },
                          validator: (value) {
                            if (value?.isEmpty != false) {
                              return 'Please enter the URL';
                            }
                            if (!wssDNSPattern.hasMatch('wss://$value') &&
                                !wssIPPattern.hasMatch('wss://$value')) {
                              return 'Invalid relay URL';
                            }
                            if (_relays != null &&
                                _relays!
                                    .contains(DataRelay(url: 'wss://$value'))) {
                              return 'Already exists';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: FilledButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  if (_formKey.currentState?.validate() !=
                                      true) {
                                    return;
                                  }
                                  _formKey.currentState?.save();
                                  addRelay(_relayUrl!);
                                },
                          child: const Text("Add"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
              onPressed:
                  _relays?.isEmpty != false || _isLoading ? null : () => save(),
              child: const Text("Save"),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        children: !_isInitialzed
            ? const [
                ListTile(
                  title: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(),
                        ),
                        SizedBox(width: 16),
                        Text('Loading'),
                      ],
                    ),
                  ),
                ),
              ]
            : _relays?.map((e) {
                  final name = e.url;
                  final marker = e.marker;
                  return Card(
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                    child: ListTile(
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: themeData.textTheme.titleMedium,
                      ),
                      // isThreeLine: true,
                      enabled: !_isLoading,
                      subtitle: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (marker == null || marker == 'read') ...[
                            Chip(
                              side: BorderSide.none,
                              labelStyle: const TextStyle(fontSize: 12),
                              labelPadding: const EdgeInsets.only(right: 8),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              avatar: Icon(Icons.download,
                                  color: themeExtension.infoColor),
                              padding: const EdgeInsets.all(0),
                              visualDensity: VisualDensity.compact,
                              label: const Text('Read'),
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (marker == null || marker == 'write')
                            Chip(
                              side: BorderSide.none,
                              labelStyle: const TextStyle(fontSize: 12),
                              labelPadding: const EdgeInsets.only(right: 8),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              avatar: Icon(Icons.upload,
                                  color: themeExtension.warningColor),
                              padding: const EdgeInsets.all(0),
                              visualDensity: VisualDensity.compact,
                              label: const Text('Write'),
                            )
                        ],
                      ),
                      trailing: Transform.translate(
                        offset: const Offset(16, 0),
                        child: RelayItemMenu(
                          value: marker,
                          onValueChange: (value) {
                            if (value != 'delete') {
                              return updateRelay(name, value);
                            }
                            deleteRelay(name);
                          },
                        ),
                      ),
                    ),
                  );
                }).toList() ??
                [],
      ),
    );
  }
}
