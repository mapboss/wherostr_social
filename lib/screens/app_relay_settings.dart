import 'package:flutter/material.dart';
import 'package:wherostr_social/models/app_relays.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_relay.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/utils/app_utils.dart';

final wssDNSPattern =
    RegExp(r'^wss?:\/\/(?:[A-Za-z0-9-]+.)+[A-Za-z]{2,6}(?::[0-9]{1,5})?$');
final wssIPPattern =
    RegExp(r'^(wss?:\/\/)([0-9]{1,3}(?:\.[0-9]{1,3}){3}|[^\/]+):([0-9]{1,5})$');

class AppRelaySettings extends StatefulWidget {
  const AppRelaySettings({super.key});

  @override
  State<AppRelaySettings> createState() => _AppRelaySettingsState();
}

class _AppRelaySettingsState extends State<AppRelaySettings> {
  final _formKey = GlobalKey<FormState>();
  String? _relayUrl;
  DataRelayList? _relays;
  String? _urlError;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    setState(() {
      _relays = AppRelays.relays;
      _relays?.sort((a, b) => a.url.compareTo(b.url));
    });
  }

  void addRelay(String relayUrl) async {
    try {
      final relays = _relays;
      final relay = DataRelay(url: relayUrl);
      await relay.getRelayInformation();
      relays?.add(relay);
      await AppRelays.setRelays(relays);
      setState(() {
        _relays = relays;
        _formKey.currentState?.reset();
      });
    } catch (err) {
      setState(() {
        _urlError = 'Unable to connect to the URL';
      });
    }
  }

  Future<void> deleteRelay(DataRelay relay) async {
    try {
      final relays = _relays;
      relays?.remove(relay);
      await AppRelays.setRelays(relays);
      setState(() {
        _relays = relays;
      });
    } catch (err) {
      AppUtils.handleError();
    }
  }

  void resetToDefault() async {
    try {
      await AppRelays.resetRelays();
      setState(() {
        _relays = AppRelays.relays;
        _relays?.sort((a, b) => a.url.compareTo(b.url));
      });
    } catch (err) {
      AppUtils.handleError();
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('App relays'),
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
                  const SizedBox(height: 8),
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
                            if (_relays != null &&
                                _relays!.any((e) => e.url == 'wss://$value')) {
                              return 'Already exists';
                            }
                            if (!wssDNSPattern.hasMatch('wss://$value') &&
                                !wssIPPattern.hasMatch('wss://$value')) {
                              return 'Invalid relay URL';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: FilledButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() != true) {
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
                  const SizedBox(height: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => resetToDefault(),
                  child: const Text("Restore default relays"),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        children: _relays == null
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
            : _relays?.map((relay) {
                  return Card(
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                    child: ListTile(
                      title: Text(
                        relay.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: themeData.textTheme.titleMedium,
                      ),
                      trailing: Transform.translate(
                        offset: const Offset(16, 0),
                        child: IconButton(
                          style: const ButtonStyle(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          color: themeExtension.errorColor,
                          onPressed: _relays?.length == 1
                              ? null
                              : () {
                                  deleteRelay(relay);
                                },
                          icon: const Icon(Icons.delete),
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
