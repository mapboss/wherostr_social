import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/app_utils.dart';

class EmojiPicker extends StatefulWidget {
  final ValueChanged<List<String>>? onChanged;

  const EmojiPicker({
    super.key,
    this.onChanged,
  });

  @override
  State<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker> {
  static List<List<String>>? emojiList;
  List<List<String>>? _emojiList = emojiList;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    if (_emojiList == null) {
      final me = context.read<AppStatesProvider>().me;
      final [
        userEmojiList as List<List<String>>,
        wherostrEmojiEvent as DataEvent,
      ] = await Future.wait([
        me.fetchEmojiList(),
        NostrService.fetchEventById(
            "30030:fc43cb888ec0fbb74a75c19e80738a88706eab2e9959616b94624a718a60fa73:Wherostr"),
      ]);
      Set<String> seenSecondStrings = {};
      List<List<String>> uniqueLists = [];
      for (List<String> innerList in [
        ...(wherostrEmojiEvent.tags
                ?.where((item) => item.firstOrNull == 'emoji') ??
            []),
        ...userEmojiList,
      ]) {
        if (innerList.length >= 2 &&
            !seenSecondStrings.contains(innerList[1])) {
          seenSecondStrings.add(innerList[1]);
          uniqueLists.add(innerList);
        }
      }
      setState(() {
        _emojiList = uniqueLists;
      });
      emojiList = uniqueLists;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        height: 160,
        child: _emojiList == null
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Loading emoji sets'),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Center(
                    child: Wrap(
                      children: _emojiList!
                          .map(
                            (item) => IconButton(
                              onPressed: () => widget.onChanged?.call(item),
                              icon: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image(
                                  width: 24,
                                  height: 24,
                                  image: AppUtils.getCachedImageProvider(
                                      item.elementAt(2), 80),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
