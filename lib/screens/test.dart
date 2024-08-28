import 'package:flutter/material.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/widgets/post_item.dart';

final testEvent = DataEvent.fromJson(const {
  "created_at": 1700837012,
  "content": "GitNestr alpha version",
  "tags": [
    [
      "relays",
      "wss://relay.damus.io",
      "wss://nos.lol",
      "wss://relayable.org",
      "wss://frens.nostr1.com",
      "wss://nostr-relay.app"
    ],
    ["amount", "10000000000"],
    [
      "summary",
      "We have been building a git platform on Nostr with the Hornet Storage team for months. The goal is to enable truly sovereign code development. The project will of course be 100% FOSS after we publish the alpha version.\n\nColby Serpa mentioned the project on Nostrasia at his presentation about the H.O.R.N.E.T. Storage Multimedia Nostr Relay which powers the GitNestr project:\nhttps://yewtu.be/watch?v=hlgsZyuO8sA \n\nHornet Storage on GitHub:\nhttps://github.com/HORNET-Storage/"
    ],
    ["r", "https://hornetstorage.com"]
  ],
  "kind": 9041,
  "pubkey": "e17273fbad387f52e0c8102dcfc8d8310e56afb8f4ac4e7653e58c8d5f8abf12",
  "id": "2bd1eec04d14d53d13355de7ed3729c803ef3d402846ce02b2e572937692d103",
  "sig":
      "fa690c3c2d0c033ea66c6f775b5b6d099945869a6151e8b70e521ed76c4359f7345e5d7e6b2dab0b1ac6db0957d29f3e341e89845e26a1b481d44168322102a1"
});

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text("หน้าเทส"),
      ),
      body: DecoratedBox(
        decoration: wherostrBackgroundDecoration,
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PostItem(event: testEvent),
                      ],
                    ),
                  ),
                ),
              ),
              Material(
                elevation: 1,
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                                onPressed: () {},
                                child: const Text("Let's get started!"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
