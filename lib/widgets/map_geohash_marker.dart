import 'dart:io';

import 'package:appcheck/appcheck.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/geojson.dart';
import 'package:wherostr_social/widgets/map_ui.dart';

const layerId = 'map_event_marker';

class MapEventMarker extends StatefulWidget {
  final DataEvent? event;
  const MapEventMarker({super.key, this.event});

  @override
  State createState() => _MapEventMarkerState();
}

class _MapEventMarkerState extends State<MapEventMarker> {
  MapLibreMapController? _mapController;
  CameraPosition? _cameraPosition;
  Placemark? _placemark;
  final geojson = GeoJson();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  _initSource() async {
    await _updateSource();
    await _updateLayer();
  }

  _initialize() {
    CameraPosition? cameraPosition;
    Placemark? placemark;
    if (widget.event != null) {
      final gTags = widget.event!.getTagValues('g');
      gTags!.sort((a, b) => b.length.compareTo(a.length));
      final geohash = GeoHash(gTags.elementAt(0));
      final coordinates = LatLng(
        geohash.latitude(decimalAccuracy: 6),
        geohash.longitude(decimalAccuracy: 6),
      );
      cameraPosition = CameraPosition(zoom: 16, target: coordinates);
      placemark = Placemark(
          name:
              '${coordinates.latitude.toStringAsFixed(5)}, ${coordinates.longitude.toStringAsFixed(5)}');
      geojson.features.add(Feature.fromMap({
        'properties': {
          "id": widget.event!.id,
          "pubkey": widget.event!.pubkey,
          "content": widget.event!.content,
          "kind": widget.event!.kind,
          "sig": widget.event!.sig,
          "tags": widget.event!.tags,
          "createdAt": widget.event!.createdAt?.millisecondsSinceEpoch,
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [coordinates.longitude, coordinates.latitude]
        }
      }));
      setState(() {
        _placemark = placemark;
        _cameraPosition = cameraPosition;
      });
    }
  }

  _onMapCreated(MapLibreMapController mapController) {
    _mapController = mapController;
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

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return Stack(
      children: [
        MapUI(
          key: const Key('map_geohash_marker'),
          myLocationEnabled: false,
          crosshairEnabled: false,
          searchEnabled: false,
          cameraPosition: _cameraPosition,
          onMapCreated: _onMapCreated,
          onStyleLoaded: _initSource,
        ),
        if (_placemark != null) ...[
          // Padding(
          //   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          //   child: Text(_placemark!.name!),
          // ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FilledButton.icon(
                onPressed: () async {
                  final appCheck = AppCheck();
                  if (Platform.isIOS) {
                    final isInstalled =
                        await appCheck.isAppInstalled('comgooglemaps://');
                    if (isInstalled) {
                      final url =
                          Uri.parse("comgooglemaps://?q=${_placemark!.name!}");
                      launchUrl(url);
                      return;
                    }
                  }
                  launchUrl(Uri.parse(
                      "https://maps.google.com/?q=${_placemark!.name!}"));
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.minPositive, 48),
                ),
                icon: const Icon(Icons.map),
                label: const Text('Google Maps'),
                iconAlignment: IconAlignment.start,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
