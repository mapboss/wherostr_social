import 'package:dart_geohash/dart_geohash.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/services/map.dart';
import 'package:wherostr_social/widgets/map_ui.dart';

class PostLocationChip extends StatefulWidget {
  final NostrEvent? event;
  final String? geohash;
  final bool enableShowMapAction;

  const PostLocationChip({
    super.key,
    this.event,
    this.geohash,
    this.enableShowMapAction = true,
  });

  @override
  State createState() => _PostLocationChipState();
}

class _PostLocationChipState extends State<PostLocationChip> {
  String? _locationName;
  LatLng? _latLng;

  @override
  void didUpdateWidget(covariant PostLocationChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.geohash != widget.geohash) {
      _readGeohash();
    }
  }

  @override
  void initState() {
    super.initState();
    _readGeohash();
  }

  void _readGeohash() async {
    try {
      GeoHash? geohash;
      if (widget.geohash != null) {
        geohash = GeoHash(widget.geohash!);
      } else if (widget.event?.tags != null) {
        List<List<String>> tagG =
            widget.event!.tags!.where((tag) => tag.firstOrNull == 'g').toList();
        tagG.sort((a, b) => b[1].length.compareTo(a[1].length));
        if (tagG.isEmpty) return;
        geohash = GeoHash(tagG[0][1]);
      }
      if (geohash != null) {
        var latlng = LatLng(geohash.latitude(decimalAccuracy: 6),
            geohash.longitude(decimalAccuracy: 6));
        final result = await MapService.reverse(latlng);
        if (mounted) {
          setState(() {
            _latLng = latlng;
            if (result.country != null && result.country!.isNotEmpty) {
              _locationName =
                  '${result.administrativeArea ?? result.subAdministrativeArea}, ${result.country}';
            } else if (result.name != null) {
              _locationName = result.name;
            }
          });
        }
      }
    } catch (error) {
      print('MapService.reverse: ERROR: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return _locationName == null
        ? const SizedBox.shrink()
        : InkWell(
            onTap: widget.enableShowMapAction
                ? () => showModalBottomSheet(
                      isScrollControlled: true,
                      useRootNavigator: true,
                      enableDrag: false,
                      showDragHandle: true,
                      context: context,
                      builder: (BuildContext context) {
                        return FractionallySizedBox(
                          heightFactor: 0.75,
                          child: MapUI(
                            key: const Key('post_location_chip'),
                            searchEnabled: false,
                            crosshairEnabled: true,
                            cameraPosition: _latLng != null
                                ? CameraPosition(target: _latLng!, zoom: 16)
                                : null,
                          ),
                        );
                      },
                    )
                : null,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.share_location,
                    size: themeData.textTheme.labelLarge?.fontSize,
                    color: themeExtension.textDimColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _locationName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: themeData.textTheme.labelMedium
                        ?.copyWith(color: themeData.colorScheme.primary),
                  ),
                ],
              ),
            ),
          );
  }
}
