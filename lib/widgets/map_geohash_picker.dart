import 'dart:math';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:wherostr_social/widgets/map_ui.dart';

class MapGeohashPicker extends StatefulWidget {
  final void Function(String? geohash)? onGeohashUpdate;
  final String? initialGeohash;
  const MapGeohashPicker(
      {super.key, this.initialGeohash, this.onGeohashUpdate});

  @override
  State createState() => _MapGeohashPickerState();
}

class _MapGeohashPickerState extends State<MapGeohashPicker> {
  MapLibreMapController? _mapController;
  String? _geohash;
  CameraPosition? _cameraPosition;
  Placemark? _placemark;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  _initialize() async {
    CameraPosition? cameraPosition;
    Placemark? placemark;
    if (widget.initialGeohash != null) {
      var geohash = GeoHash(widget.initialGeohash!);
      var coordinates = LatLng(
        geohash.latitude(decimalAccuracy: 6),
        geohash.longitude(decimalAccuracy: 6),
      );
      cameraPosition = CameraPosition(zoom: 16, target: coordinates);
      placemark = Placemark(
          name:
              '${coordinates.latitude.toStringAsFixed(5)}, ${coordinates.longitude.toStringAsFixed(5)}');
    }
    setState(() {
      _placemark = placemark;
      _cameraPosition = cameraPosition;
      _geohash = widget.initialGeohash;
    });
  }

  _onMapCreated(MapLibreMapController mapController) {
    _mapController = mapController;
  }

  _onMapClick(Point point, LatLng coordinates) async {
    // _updateGeohashFromCoordinates(coordinates);
    _mapController?.animateCamera(CameraUpdate.newLatLng(coordinates));
  }

  _onCameraMove(CameraPosition? cam) {
    _updateGeohashFromCoordinates(cam?.target);
  }

  _updateGeohashFromCoordinates(LatLng? coordinates) async {
    String? geohash;
    Placemark? placemark;
    if (coordinates != null) {
      geohash = GeoHash.fromDecimalDegrees(
        coordinates.longitude,
        coordinates.latitude,
        precision: 9,
      ).geohash;
      placemark = Placemark(
          name:
              '${coordinates.latitude.toStringAsFixed(5)}, ${coordinates.longitude.toStringAsFixed(5)}');
    }

    setState(() {
      _placemark = placemark;
      _geohash = geohash;
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: MapUI(
            key: const Key('map_geohash_picker'),
            myLocationEnabled: true,
            crosshairEnabled: true,
            cameraPosition: _cameraPosition,
            onMapCreated: _onMapCreated,
            onMapClick: _onMapClick,
            onCameraMove: _onCameraMove,
          ),
        ),
        if (_placemark != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(_placemark!.name!),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () {
              widget.onGeohashUpdate?.call(_geohash);
            },
            child: const Text("Tag this location"),
          ),
        ),
        if (widget.initialGeohash != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: themeData.colorScheme.error),
              ),
              onPressed: () {
                widget.onGeohashUpdate?.call(null);
              },
              child: Text(
                "Unset",
                style: TextStyle(
                  color: themeData.colorScheme.error,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
