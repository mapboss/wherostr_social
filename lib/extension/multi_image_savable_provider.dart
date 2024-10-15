import 'dart:ui' as ui;
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wherostr_social/constant.dart';
import 'package:wherostr_social/utils/app_utils.dart';

class MultiImageSavableProvider extends EasyImageProvider {
  Function(ImageProvider<Object> imageProvider)? onLongPress;
  final List<ImageProvider> imageProviders;
  final String? imageUrl;
  @override
  final int initialIndex;

  MultiImageSavableProvider(this.imageProviders,
      {this.imageUrl, this.onLongPress, this.initialIndex = 0}) {
    if (initialIndex < 0 || initialIndex >= imageProviders.length) {
      throw ArgumentError.value(initialIndex, 'initialIndex',
          'The initialIndex value must be between 0 and ${imageProviders.length - 1}.');
    }

    if (imageProviders.isEmpty) {
      throw ArgumentError.value(initialIndex, 'imageProviders',
          'The imageProviders list must not be empty.');
    }
  }

  @override
  ImageProvider imageBuilder(BuildContext context, int index) {
    if (index < 0 || index >= imageProviders.length) {
      throw ArgumentError.value(initialIndex, 'index',
          'The index value must be between 0 and ${imageProviders.length - 1}.');
    }

    return imageProviders[index];
  }

  @override
  int get imageCount => imageProviders.length;

  @override
  Widget imageWidgetBuilder(BuildContext context, int index) {
    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          showDragHandle: true,
          useRootNavigator: true,
          useSafeArea: true,
          clipBehavior: Clip.hardEdge,
          constraints: const BoxConstraints(
            maxWidth: Constants.largeDisplayContentWidth,
          ),
          context: context,
          builder: (context) {
            return SafeArea(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('Copy Image URL'),
                    onTap: () async {
                      Navigator.of(context).pop(); // Close the bottom sheet
                      _copyImageUrlToClipboard(imageUrl);
                    },
                  ),
                  // ListTile(
                  //   leading: Icon(Icons.copy),
                  //   title: Text('Copy Image'),
                  //   onTap: () async {
                  //     Navigator.of(context).pop(); // Close the bottom sheet
                  //     _downloadImage(context, imageProviders[index]);
                  //   },
                  // ),
                  ListTile(
                    leading: Icon(Icons.download),
                    title: Text('Save Image'),
                    onTap: () async {
                      Navigator.of(context).pop(); // Close the bottom sheet
                      _downloadImage(context, imageProviders[index]);
                    },
                  ),
                  // ListTile(
                  //   leading: Icon(Icons.cancel),
                  //   title: Text('Cancel'),
                  //   onTap: () {
                  //     Navigator.of(context).pop(); // Close the bottom sheet
                  //   },
                  // ),
                ],
              ),
            );
          },
        );
      },
      child: super.imageWidgetBuilder(context, index),
    );
  }

  Future<void> _downloadImage(
      BuildContext context, ImageProvider imageProvider) async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      try {
        AppUtils.showSnackBar(
          text: 'Saving an image...',
          withProgressBar: true,
        );
        final Uint8List imageBytes = await _getImageBytes(imageProvider);
        final result =
            await ImageGallerySaver.saveImage(imageBytes, quality: 100);
        if (result['isSuccess'] == true) {
          AppUtils.showSnackBar(text: 'Image saved successfully.');
        } else {
          AppUtils.showSnackBar(
              text: 'Failed to save image.', status: AppStatus.error);
        }
      } catch (e) {
        AppUtils.handleError();
      }
    } else {
      AppUtils.showSnackBar(
        text: 'Storage permission is required to save the image.',
        status: AppStatus.warning,
      );
    }
  }

  Future<void> _copyImageUrlToClipboard(String? imageUrl) async {
    await Clipboard.setData(ClipboardData(
      text: imageUrl ?? '',
    ));
  }

  Future<Uint8List> _getImageBytes(ImageProvider imageProvider) async {
    // Create a completer to capture the image rendering process
    late Completer<ui.Image> completer = Completer<ui.Image>();
    if (imageProvider is MemoryImage) {
      return imageProvider.bytes;
    } else if (imageProvider is NetworkImage) {
      final rs = await Dio().get<List<int>>(
        imageProvider.url,
        options: Options(
            responseType:
                ResponseType.bytes), // Set the response type to `bytes`.
      );
      return Uint8List.fromList(rs.data!);
    }

    // Get ImageStream from the image provider
    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
    final ImageStreamListener listener =
        ImageStreamListener((ImageInfo info, bool synchronousCall) {
      completer.complete(info.image); // Capture the image
    });

    stream.addListener(listener);

    // Wait for the image to be ready
    final ui.Image image = await completer.future;

    // Convert the ui.Image to byte data
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
}
