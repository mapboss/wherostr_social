import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/extension/nostr_instance.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/nostr_event.dart';
import 'package:wherostr_social/widgets/map_ui.dart';
import 'package:wherostr_social/widgets/post_details.dart';

final fullExtentGeohash = '0123456789bcdefghjkmnpqrstuvwxyz'.split('');
const layerId = 'map_events_filter';
const pinSvg = '''
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg
  width="56"
  height="56"
  xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
  viewBox="0 0 24 24"
>
  <defs>
    <mask id="pinmask">
      <rect x="0" y="0" width="24" height="24" fill="black"></rect>
      <circle cx="50%" cy="46%" r="8.5" fill="white"></circle>
    </mask>  
  </defs>
  <path
    fill="#fc6a03"
    d="M12 2c-4.97 0-9 4.03-9 9 0 4.17 2.84 7.67 6.69 8.69L12 22l2.31-2.31C18.16 18.67 21 15.17 21 11c0-4.97-4.03-9-9-9zm0 2c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 14.3c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08 1.99 0 5.97 1.09 6 3.08-1.29 1.94-3.5 3.22-6 3.22z"
  />
  <image xlink:href="{URL}" height="17" width="17" x="3.5" y="2.5" preserveAspectRatio="xMidYMid slice" mask="url(#pinmask)" />
</svg>
''';

Uint8List convertSvgToDataUrl(String svgString) {
  // Encode the SVG string to UTF-8 bytes
  final bytes = utf8.encode(svgString);

  // // Convert the bytes to a base64 encoded string
  // final base64String = base64Encode(bytes);

  // Create the Data URL
  // return 'data:image/svg+xml;base64,$base64String';
  return bytes;
}

class MapEventsFilter extends StatefulWidget {
  const MapEventsFilter({
    super.key,
  });

  @override
  State createState() => _MapEventsFilterState();
}

class _MapEventsFilterState extends State<MapEventsFilter> {
  MapLibreMapController? _mapController;
  bool _loading = true;
  Completer<Map<String, dynamic>>? _sourceLoaded;

  Future<Map<String, dynamic>> _fetchSource() {
    final relays = context.read<AppStatesProvider>().me.relayList.clone();
    _sourceLoaded = Completer<Map<String, dynamic>>();
    print('MapEventsFilter._fetchSource');
    setState(() {
      _loading = true;
    });
    DateTime since = DateTime.timestamp().subtract(const Duration(days: 30));
    NostrFilter filter = NostrFilter(
      since: since,
      kinds: const [1],
      additionalFilters: {
        "#g": fullExtentGeohash,
      },
    );
    NostrService.instance.fetchEvents(
      [filter],
      eoseRatio: 1,
      relays: relays,
    ).then((newItems) async {
      if (newItems.isNotEmpty) {
        newItems = newItems.where((e) => (!isReply(event: e))).toList();
        // await Future.wait([
        //   _fetchUsersFromEvents(newItems),
        // ]);
      }
      Map<String, dynamic> geojson = {
        'type': 'FeatureCollection',
        'features': newItems.map(
          (item) {
            var geohash = GeoHash(
                item.tags!.where((e) => e.first == 'g').first.elementAt(1));
            return {
              'type': 'Feature',
              'properties': {
                "id": item.id,
                "pubkey": item.pubkey,
                "content": item.content,
                "kind": item.kind,
                "sig": item.sig,
                "tags": item.tags,
                "createdAt": item.createdAt?.millisecondsSinceEpoch,
              },
              'geometry': {
                "type": "Point",
                "coordinates": [
                  geohash.longitude(decimalAccuracy: 6),
                  geohash.latitude(decimalAccuracy: 6)
                ]
              },
            };
          },
        ).toList()
      };
      _sourceLoaded!.complete(geojson);
    });
    return _sourceLoaded!.future;
  }

  _onMapCreated(MapLibreMapController mapController) {
    _mapController = mapController;
    _mapController?.onFeatureTapped.add(_queryRenderedFeatures);
    if (_sourceLoaded == null) {
      _fetchSource();
    }
  }

  _updateSource(Map<String, dynamic>? geojson) async {
    var isHasSource = (await _mapController?.getSourceIds())?.contains(layerId);
    if (isHasSource != true) {
      await _mapController?.addGeoJsonSource(layerId, geojson ?? {});
    } else {
      await _mapController?.setGeoJsonFeature(layerId, geojson ?? {});
    }
  }

  _updateLayer() async {
    var isHasLayer = (await _mapController?.getLayerIds())?.contains(layerId);
    if (isHasLayer != true) {
      await _mapController?.addLayer(
        layerId,
        layerId,
        const SymbolLayerProperties(
          iconAllowOverlap: true,
          iconImage: 'assets/app/app-icon-circle.png',
          iconSize: 0.3,
          symbolSortKey: 'createdAt',
        ),
      );
    }
  }

  _initSource() async {
    try {
      var geojson = await _sourceLoaded?.future;
      await _updateSource(geojson);
      await _updateLayer();
      setState(() {
        _loading = false;
      });
    } catch (err) {
      print('MapEventsFilter._initSource: ERROR: $err');
      await Future.delayed(const Duration(seconds: 3));
      await _initSource();
    }
  }

  void _queryRenderedFeatures(
      dynamic id, Point<double> point, LatLng coordinates) async {
    try {
      print('_onFeatureTapped.id: $id');
      var feats =
          await _mapController?.queryRenderedFeatures(point, [layerId], null);
      if (mounted) {
        var feat = feats?.elementAt(0);
        var event = DataEvent.fromJson(feat['properties']);
        var appState = context.read<AppStatesProvider>();
        appState.navigatorPush(
          widget: PostDetails(event: event),
        );
      }
      print('_onFeatureTapped.feats: $feats');
    } catch (err) {
      print('_onFeatureTapped.ERROR: $err');
    }
  }

  Future<void> _fetchUsersFromEvents(List<NostrEvent> events) async {
    Set<String> pubkeySet = <String>{};
    for (var e in events) {
      pubkeySet.add(e.pubkey);
      e.tags?.where((t) => t.firstOrNull == 'p').forEach((t) {
        pubkeySet.add(t[1]);
      });
    }
    print(
        '_fetchUsersFromEvents: events: ${events.length}, pubkey: ${pubkeySet.length}');
    if (pubkeySet.isEmpty) return;
    await NostrService.fetchUsers(pubkeySet.toList());
    // await Future.wait(users.map((u) async {
    //   try {
    //     if (u.picture != null) {
    //       print('_fetchUsersFromEvents.SvgPicture');
    //       var picture = SvgPicture.string(
    //         pinSvg.replaceAll('{URL}', u.picture!),
    //         width: 24,
    //         height: 24,
    //       );
    //       print('_fetchUsersFromEvents.loadBytes');
    //       var bytes = await picture.bytesLoader.loadBytes(null);
    //       print('_fetchUsersFromEvents.bytes: ${bytes.buffer.lengthInBytes}');
    //       await _mapController?.addImage(u.pubkey, bytes.buffer.asUint8List());
    //       print('_fetchUsersFromEvents.addImage: DONE');
    //     }
    //   } catch (err) {
    //     print('_fetchUsersFromEvents.addImage: $err');
    //   }
    // }));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapUI(
          // searchEnabled: false,
          key: const Key('map_event_filter_'),
          onMapCreated: _onMapCreated,
          onStyleLoaded: _initSource,
        ),
        if (_loading) ...[
          const Positioned(
            right: 16,
            bottom: 16,
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(),
            ),
          ),
        ]
      ],
    );
  }
}
