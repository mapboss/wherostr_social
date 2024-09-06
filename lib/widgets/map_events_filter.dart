import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_debouncer/flutter_debouncer.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
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

class GeoJson {
  final String type = 'FeatureCollection';
  final List<Feature> features = [];

  Map<String, dynamic> toMap() {
    return {"type": type, "features": features.map((e) => e.toMap()).toList()};
  }
}

class Feature {
  final String type = "Feature";
  Map<String, dynamic>? properties = {};
  Map<String, dynamic>? geometry = {};

  Feature({this.properties, this.geometry});
  factory Feature.fromMap(Map<String, dynamic> data) {
    return Feature(properties: data['properties'], geometry: data['geometry']);
  }

  Map<String, dynamic> toMap() {
    return {"type": type, "properties": properties, "geometry": geometry};
  }
}

class GeometryPoint {
  final List<double>? cooridnates;
  final String type = 'Point';
  const GeometryPoint([this.cooridnates]);

  factory GeometryPoint.fromMap(Map<String, dynamic> data) {
    return GeometryPoint(data['cooridnates'].map((e) => e));
  }
  Map<String, dynamic> toMap() {
    return {"type": type, "cooridnates": cooridnates};
  }
}

class _MapEventsFilterState extends State<MapEventsFilter> {
  MapLibreMapController? _mapController;
  bool _loading = true;
  NostrEventsStream? _newEventStream;
  StreamSubscription? _newEventListener;
  final GeoJson geojson = GeoJson();

  void _subscribe() {
    const duration = Duration(milliseconds: 300);
    final Debouncer debouncer = Debouncer();
    final relays = context.read<AppStatesProvider>().me.relayList.clone();
    final filter = NostrFilter(
      since: DateTime.now().subtract(const Duration(days: 30)),
      kinds: const [1],
      additionalFilters: {
        "#g": fullExtentGeohash,
      },
    );
    _newEventStream = NostrService.subscribe(
      [filter],
      relays: relays,
      onEose: (relay, ease) async {
        if (_loading && mounted) {
          setState(() {
            _loading = false;
          });
        }
        debouncer.debounce(
          duration: duration,
          onDebounce: () {
            if (mounted) {
              geojson.features.sort((a, b) =>
                  b.properties?['createdAt'] - a.properties?['createdAt']);
              _updateSource();
            }
          },
        );
      },
    );
    _newEventListener = _newEventStream!.stream.listen((event) {
      if (isReply(event: event)) return;
      final geohash =
          GeoHash(event.tags!.where((e) => e.first == 'g').first.elementAt(1));
      final feature = Feature.fromMap({
        'properties': {
          "id": event.id,
          "pubkey": event.pubkey,
          "content": event.content,
          "kind": event.kind,
          "sig": event.sig,
          "tags": event.tags,
          "createdAt": event.createdAt?.millisecondsSinceEpoch,
        },
        'geometry': {
          "type": "Point",
          "coordinates": [
            geohash.longitude(decimalAccuracy: 6),
            geohash.latitude(decimalAccuracy: 6)
          ]
        },
      });
      geojson.features.add(feature);
    });
  }

  Future<void> _unsubscribe() async {
    try {
      if (_newEventListener != null) {
        await _newEventListener!.cancel();
        _newEventListener = null;
      }
      if (_newEventStream != null) {
        _newEventStream!.close();
        _newEventStream = null;
      }
    } catch (err) {
      print('unsubscribe: $err');
    }
  }

  _onMapCreated(MapLibreMapController mapController) {
    _mapController = mapController;
    _mapController?.onFeatureTapped.add(_queryRenderedFeatures);
  }

  Future<void> _updateSource() async {
    try {
      var isHasSource =
          (await _mapController?.getSourceIds())?.contains(layerId);
      if (isHasSource != true) {
        await _mapController?.addGeoJsonSource(layerId, geojson.toMap());
      } else {
        await _mapController?.setGeoJsonSource(layerId, geojson.toMap());
      }
    } catch (err) {
      print('err: $err');
    }
  }

  Future<void> _updateLayer() async {
    var isHasLayer = (await _mapController?.getLayerIds())?.contains(layerId);
    if (isHasLayer != true) {
      await _mapController?.addLayer(
        layerId,
        layerId,
        SymbolLayerProperties(
          iconAllowOverlap: true,
          iconImage: 'assets/app/app-icon-circle.png',
          iconSize: Platform.isIOS ? 0.25 : 0.3,
          symbolSortKey: 'createdAt',
        ),
      );
    }
  }

  _initSource() async {
    await _updateSource();
    await _updateLayer();
    _subscribe();
  }

  void _queryRenderedFeatures(
      dynamic id, Point<double> point, LatLng coordinates) async {
    try {
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
    } catch (err) {
      print('_onFeatureTapped.ERROR: $err');
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapUI(
          // searchEnabled: false,
          key: const Key('map_event_filter'),
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
