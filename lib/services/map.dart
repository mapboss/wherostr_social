import 'dart:convert';
import 'dart:io';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:wherostr_social/models/map.dart';

const searchServiceUrl = 'https://nominatim.openstreetmap.org/search';
const reverseGeocodeServiceUrl = 'https://nominatim.openstreetmap.org/reverse';

class MapService {
  static Future<List<MapSearchResult>> search(String? payload) async {
    if (payload == null) {
      return [];
    }
    final request = http.Request(
        'GET',
        Uri.parse(searchServiceUrl).replace(queryParameters: {
          'accept-language': 'en',
          'format': 'jsonv2',
          'q': payload,
          'limit': '10'
        }));

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> result = List.from(jsonResponse);
      final List<MapSearchResult> items = [];
      for (var item in result) {
        items.add(MapSearchResult.fromJson(item));
      }
      return items;
    } else {
      throw Exception('Failed to request search');
    }
  }

  static Future<Placemark> reverse(LatLng ll) async {
    if (Platform.isIOS || Platform.isAndroid) {
      var placemarks =
          await placemarkFromCoordinates(ll.latitude, ll.longitude);
      var placemark = placemarks.first;
      if (placemark.country!.isEmpty && placemark.name!.isEmpty) {
        placemark = Placemark(
            name:
                '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}');
      }
      return placemark;
    } else {
      final request = http.Request(
          'GET',
          Uri.parse(reverseGeocodeServiceUrl).replace(queryParameters: {
            'accept-language': 'en',
            'format': 'jsonv2',
            'lat': ll.latitude.toString(),
            'lon': ll.longitude.toString()
          }));

      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final result = MapReverseGeocodeResult.fromJson(jsonResponse);
        return Placemark(
          country: result.address?.country,
          isoCountryCode: result.address?.countryCode,
          administrativeArea: result.address?.state ??
              result.address?.province ??
              result.address?.city,
          subAdministrativeArea: result.address?.suburb ?? result.address?.town,
          postalCode: result.address?.postcode,
        );
      } else {
        throw Exception('Failed to request reverse');
      }
    }
  }
}
