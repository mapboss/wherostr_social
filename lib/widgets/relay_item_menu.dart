import 'package:flutter/material.dart';
import 'package:wherostr_social/models/app_theme.dart';

class RelayItemMenu extends StatefulWidget {
  final String? value;
  final Function(String? value)? onValueChange;

  const RelayItemMenu({super.key, this.value, this.onValueChange});

  @override
  State createState() => _RelayItemMenuState();
}

class _RelayItemMenuState extends State<RelayItemMenu> {
  String? _value;
  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    setState(() {
      _value = widget.value;
    });
  }

  @override
  void didUpdateWidget(covariant RelayItemMenu oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() {
        _value = widget.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return MenuAnchor(
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.more_horiz),
        );
      },
      menuChildren: [
        if (_value != null)
          MenuItemButton(
            onPressed: () {
              widget.onValueChange?.call(null);
            },
            leadingIcon: SizedBox(
              height: 24,
              width: 24,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      Icons.south,
                      color: themeExtension.infoColor,
                      size: 16,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.north,
                      color: themeExtension.warningColor,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            child: const Text('Read and Write'),
          ),
        if (_value != 'read')
          MenuItemButton(
            onPressed: () {
              widget.onValueChange?.call('read');
            },
            leadingIcon: Icon(
              Icons.download,
              color: themeExtension.infoColor,
            ),
            child: const Text('Read only'),
          ),
        if (_value != 'write')
          MenuItemButton(
            onPressed: () {
              widget.onValueChange?.call('write');
            },
            leadingIcon: Icon(
              Icons.upload,
              color: themeExtension.warningColor,
            ),
            child: const Text('Write only'),
          ),
        MenuItemButton(
          onPressed: () {
            widget.onValueChange?.call('delete');
          },
          leadingIcon: Icon(
            Icons.delete,
            color: themeData.colorScheme.error,
          ),
          child: Text(
            'Delete relay',
            style: TextStyle(color: themeData.colorScheme.error),
          ),
        ),
      ],
    );
  }
}
