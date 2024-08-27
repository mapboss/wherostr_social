import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/map.dart';
import 'package:wherostr_social/widgets/places_search_box.dart';

const mapStyleDark = 'assets/app/map-style-dark.json';
const mapStyleLight = 'assets/app/map-style-light.json';

class MapUI extends StatefulWidget {
  final OnMapClickCallback? onMapClick;
  final MapCreatedCallback? onMapCreated;
  final OnStyleLoadedCallback? onStyleLoaded;
  final void Function(CameraPosition? cameraPosition)? onCameraMove;
  final bool myLocationEnabled;
  final bool searchEnabled;
  final bool? crosshairEnabled;
  final CameraPosition? cameraPosition;
  final OnUserLocationUpdated? onUserLocationUpdated;
  const MapUI({
    super.key,
    this.onUserLocationUpdated,
    this.cameraPosition,
    this.searchEnabled = true,
    this.myLocationEnabled = false,
    this.crosshairEnabled = false,
    this.onMapClick,
    this.onMapCreated,
    this.onCameraMove,
    this.onStyleLoaded,
  });

  @override
  State createState() => _MapUIState();
}

class _MapUIState extends State<MapUI> with AutomaticKeepAliveClientMixin {
  MapLibreMapController? _mapController;

  @override
  bool get wantKeepAlive => true;

  // @override
  // void didUpdateWidget(covariant MapUI oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (oldWidget.myLocationEnabled != widget.myLocationEnabled) {
  //     _mapController?.updateMyLocationTrackingMode(widget.myLocationEnabled
  //         ? MyLocationTrackingMode.trackingGps
  //         : MyLocationTrackingMode.none);
  //   }
  // }

  @override
  void dispose() {
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    widget.onMapCreated?.call(controller);
  }

  Future<void> _zoomToLocation(MapSearchResult location) async {
    try {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(double.parse(location.lat!), double.parse(location.lon!)),
          16.0,
        ),
      );
    } catch (e) {}
  }

  Future<void> _gotoCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    var currentPosition = await Geolocator.getCurrentPosition();
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(currentPosition.latitude, currentPosition.longitude),
          zoom: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ThemeData themeData = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.searchEnabled == true)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PlacesSearchBox(
              onLocated: _zoomToLocation,
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              MapLibreMap(
                styleString: themeData.brightness == Brightness.light
                    ? mapStyleLight
                    : mapStyleDark,
                compassEnabled: false,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                initialCameraPosition: widget.cameraPosition ??
                    const CameraPosition(target: LatLng(0, 0), zoom: 0),
                // myLocationEnabled: widget.myLocationEnabled,
                // onUserLocationUpdated:
                //     widget.myLocationEnabled ? widget.onUserLocationUpdated : null,
                // myLocationRenderMode: MyLocationRenderMode.normal,
                // myLocationTrackingMode: MyLocationTrackingMode.none,
                attributionButtonPosition: AttributionButtonPosition.topLeft,
                attributionButtonMargins: const Point(-32, -32),
                trackCameraPosition: true,
                onCameraIdle: () =>
                    widget.onCameraMove?.call(_mapController?.cameraPosition),
                onMapClick: widget.onMapClick,
                onStyleLoadedCallback: widget.onStyleLoaded,
                onMapCreated: _onMapCreated,
              ),
              if (widget.crosshairEnabled == true) ...[
                Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CustomPaint(
                      painter: CrosshairPainter(context),
                    ),
                  ),
                )
              ],
              if (widget.myLocationEnabled) ...[
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: ElevatedButton(
                    onPressed: _gotoCurrentPosition,
                    style: const ButtonStyle(
                      minimumSize: WidgetStatePropertyAll(Size(40, 40)),
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 0),
                      ),
                    ),
                    child: const Icon(Icons.my_location),
                    // color: themeExtension.textDimColor,
                  ),
                ),
              ],
              Positioned(
                bottom: 2,
                left: 2,
                child: InkWell(
                  onTap: () {
                    launchUrl(Uri.parse('https://mapboss.co.th'));
                  },
                  child: const Image(
                    height: 40,
                    image: AssetImage('assets/app/logo-mb-poweredby.png'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CrosshairPainter extends CustomPainter {
  final BuildContext context;
  CrosshairPainter(this.context);

  @override
  void paint(Canvas canvas, Size size) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;

    final paint = Paint()
      ..color = themeExtension.warningColor
      ..strokeWidth = 1.25;

    // Draw horizontal line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Draw vertical line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
