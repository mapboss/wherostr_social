import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';

class ProofOfWorkAdjustment extends StatefulWidget {
  final Function(int? value)? onChange;
  final int? value;
  final int? min;
  final int? max;
  final int? step;
  const ProofOfWorkAdjustment({
    super.key,
    this.value,
    this.onChange,
    this.min = 0,
    this.max = 48,
    this.step = 4,
  });

  @override
  State<StatefulWidget> createState() => _ProofOfWorkAdjustmentState();
}

class _ProofOfWorkAdjustmentState extends State<ProofOfWorkAdjustment> {
  int _pow = 8;

  @override
  void initState() {
    super.initState();
    _setValue(widget.value);
  }

  @override
  void didUpdateWidget(covariant ProofOfWorkAdjustment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _setValue(widget.value);
    }
  }

  _handleChange(double value) {
    setState(() {
      _pow = value.toInt();
    });
  }

  _setValue(int? value) {
    setState(() {
      _pow = value ?? 8;
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final appState = context.watch<AppStatesProvider>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: themeData.textTheme.titleMedium!
                        .copyWith(color: themeExtension.textDimColor),
                    children: [
                      const TextSpan(
                        text: 'Proof of Work difficulty level: ',
                      ),
                      TextSpan(
                        text: _pow.round().toString(),
                        style: themeData.textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: themeData.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  divisions: widget.max! ~/ widget.step!,
                  value: _pow.toDouble(),
                  label: _pow.round().toString(),
                  min: widget.min!.toDouble(),
                  max: widget.max!.toDouble(),
                  inactiveColor: themeData.colorScheme.surfaceDim,
                  onChanged: _handleChange,
                ),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    text:
                        'Proof of Work (PoW) reduces spam by requiring clients to solve a computational puzzle before submitting messages. This involves finding a nonce that meets a difficulty target when hashed with the message. While it helps prevent spam and manage relay load, PoW also consumes computational resources, which may impact users with limited device capabilities.',
                    style: TextStyle(color: themeExtension.textDimColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                appState.navigatorPop();
                if (_pow == 0) {
                  widget.onChange?.call(null);
                } else {
                  widget.onChange?.call(_pow.toInt());
                }
              },
              child: const Text("Confirm"),
            ),
            if (widget.value != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: BorderSide(color: themeData.colorScheme.error),
                ),
                onPressed: () {
                  appState.navigatorPop();
                  widget.onChange?.call(null);
                },
                child: Text(
                  "Unset",
                  style: TextStyle(
                    color: themeData.colorScheme.error,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
