import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanner extends StatefulWidget {
  final FutureOr<bool> Function(BarcodeCapture data) onScan;

  const QrScanner({
    super.key,
    required this.onScan,
  });

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> with WidgetsBindingObserver {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  StreamSubscription<Object?>? _scannerSubscription;

  @override
  void initState() {
    super.initState();
    // Start listening to lifecycle changes.
    WidgetsBinding.instance.addObserver(this);
    // Start listening to the barcode events.
    _scannerSubscription = _controller.barcodes.listen(_handleScanned);
    // Finally, start the scanner itself.
    unawaited(_controller.start());
  }

  @override
  void dispose() {
    // Stop listening to lifecycle changes.
    WidgetsBinding.instance.removeObserver(this);
    // Stop listening to the barcode events.
    unawaited(_scannerSubscription?.cancel());
    _scannerSubscription = null;
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the controller is not ready, do not try to start or stop it.
    // Permission dialogs can trigger lifecycle changes before the controller is ready.
    if (!_controller.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // Restart the scanner when the app is resumed.
        // Don't forget to resume listening to the barcode events.
        _scannerSubscription = _controller.barcodes.listen(_handleScanned);

        unawaited(_controller.start());
      case AppLifecycleState.inactive:
        // Stop the scanner when the app is paused.
        // Also stop the barcode events subscription.
        unawaited(_scannerSubscription?.cancel());
        _scannerSubscription = null;
        unawaited(_controller.stop());
    }
  }

  void _handleScanned(BarcodeCapture data) async {
    _scannerSubscription?.pause();
    if (await widget.onScan(data)) {
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      _scannerSubscription?.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.sizeOf(context).topCenter(const Offset(0, 192)),
      width: 240,
      height: 240,
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            fit: BoxFit.cover,
            controller: _controller,
            scanWindow: scanWindow,
            errorBuilder: (context, error, child) {
              return ScannerErrorWidget(error: error);
            },
          ),
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, child) {
              if (!state.isInitialized ||
                  !state.isRunning ||
                  state.error != null) {
                return const SizedBox();
              }

              return CustomPaint(
                painter:
                    ScannerOverlay(context: context, scanWindow: scanWindow),
              );
            },
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  ToggleFlashlightButton(controller: _controller),
                ],
              ),
            ),
          ),
          ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                if (!state.isInitialized ||
                    !state.isRunning ||
                    state.error != null) {
                  return const SizedBox.shrink();
                }
                return const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 328, 16, 8),
                    child: Text(
                      'Scan Nostr public key (npub) QR code.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }),
        ],
      ),
    );
  }
}

class ScannerErrorWidget extends StatelessWidget {
  const ScannerErrorWidget({super.key, required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    String errorMessage;

    switch (error.errorCode) {
      case MobileScannerErrorCode.controllerUninitialized:
        errorMessage = 'Controller not ready.';
      case MobileScannerErrorCode.permissionDenied:
        errorMessage = 'Permission denied';
      case MobileScannerErrorCode.unsupported:
        errorMessage = 'Scanning is unsupported on this device';
      default:
        errorMessage = 'Generic Error';
        break;
    }

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Icon(Icons.error, color: Colors.white),
            ),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              error.errorDetails?.message ?? '',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class ToggleFlashlightButton extends StatelessWidget {
  const ToggleFlashlightButton({required this.controller, super.key});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning || state.error != null) {
          return const SizedBox.shrink();
        }

        switch (state.torchState) {
          case TorchState.auto:
            return IconButton(
              color: Colors.white,
              icon: const Icon(Icons.flash_auto),
              onPressed: () async {
                await controller.toggleTorch();
              },
            );
          case TorchState.off:
            return IconButton(
              color: Colors.white,
              icon: const Icon(Icons.flash_off),
              onPressed: () async {
                await controller.toggleTorch();
              },
            );
          case TorchState.on:
            return IconButton(
              color: Colors.white,
              icon: const Icon(Icons.flash_on),
              onPressed: () async {
                await controller.toggleTorch();
              },
            );
          case TorchState.unavailable:
            return const Icon(
              Icons.no_flash,
              color: Colors.grey,
            );
        }
      },
    );
  }
}

class ScannerOverlay extends CustomPainter {
  final BuildContext context;
  final Rect scanWindow;
  final double borderRadius;

  const ScannerOverlay({
    required this.context,
    required this.scanWindow,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(context.findRenderObject()?.paintBounds ?? Rect.largest);

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          scanWindow,
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.87)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final borderRect = RRect.fromRectAndCorners(
      scanWindow,
      topLeft: Radius.circular(borderRadius),
      topRight: Radius.circular(borderRadius),
      bottomLeft: Radius.circular(borderRadius),
      bottomRight: Radius.circular(borderRadius),
    );

    canvas.drawPath(backgroundWithCutout, backgroundPaint);
    canvas.drawRRect(borderRect, borderPaint);
  }

  @override
  bool shouldRepaint(ScannerOverlay oldDelegate) {
    return scanWindow != oldDelegate.scanWindow ||
        borderRadius != oldDelegate.borderRadius;
  }
}
