import 'package:wherostr_social/utils/safe_parser.dart';

class MapAddress {
  MapAddress({
    this.province,
    this.town,
    this.city,
    this.quarter,
    this.suburb,
    this.state,
    this.postcode,
    this.country,
    this.countryCode,
  });
  final String? province;
  final String? town;
  final String? city;
  final String? quarter;
  final String? suburb;
  final String? state;
  final String? postcode;
  final String? country;
  final String? countryCode;

  factory MapAddress.fromJson(Map<String, dynamic>? data) {
    if (data == null) {
      return MapAddress();
    }
    String? province = SafeParser.parseString(data['province']);
    String? town = SafeParser.parseString(data['town']);
    String? city = SafeParser.parseString(data['city']);
    String? quarter = SafeParser.parseString(data['quarter']);
    String? suburb = SafeParser.parseString(data['suburb']);
    String? state = SafeParser.parseString(data['state']);
    String? postcode = SafeParser.parseString(data['postcode']);
    String? country = SafeParser.parseString(data['country']);
    String? countryCode = SafeParser.parseString(data['country_code']);

    return MapAddress(
      province: province,
      town: town,
      city: city,
      quarter: quarter,
      suburb: suburb,
      state: state,
      postcode: postcode,
      country: country,
      countryCode: countryCode,
    );
  }
}

class MapSearchResult {
  MapSearchResult({
    this.placeId,
    this.licence,
    this.osmType,
    this.osmId,
    this.lat,
    this.lon,
    this.category,
    this.type,
    this.placeRank,
    this.importance,
    this.addresstype,
    this.name,
    this.displayName,
    this.boundingbox,
  });

  final int? placeId;
  final String? licence;
  final String? osmType;
  final int? osmId;
  final String? lat;
  final String? lon;
  final String? category;
  final String? type;
  final int? placeRank;
  final int? importance;
  final String? addresstype;
  final String? name;
  final String? displayName;
  final List<String>? boundingbox;

  factory MapSearchResult.fromJson(Map<String, dynamic> data) {
    int? placeId = SafeParser.parseInt(data['place_id']);
    String? licence = SafeParser.parseString(data['licence']);
    String? osmType = SafeParser.parseString(data['osm_type']);
    int? osmId = SafeParser.parseInt(data['osm_id']);
    String? lat = SafeParser.parseString(data['lat']);
    String? lon = SafeParser.parseString(data['lon']);
    String? category = SafeParser.parseString(data['category']);
    String? type = SafeParser.parseString(data['type']);
    int? placeRank = SafeParser.parseInt(data['place_rank']);
    int? importance = SafeParser.parseInt(data['importance']);
    String? addresstype = SafeParser.parseString(data['addresstype']);
    String? name = SafeParser.parseString(data['name']);
    String? displayName = SafeParser.parseString(data['display_name']);
    // List<String>? boundingbox = data['boundingbox'];

    return MapSearchResult(
      placeId: placeId,
      licence: licence,
      osmType: osmType,
      osmId: osmId,
      lat: lat,
      lon: lon,
      category: category,
      type: type,
      placeRank: placeRank,
      importance: importance,
      addresstype: addresstype,
      name: name,
      displayName: displayName,
      // boundingbox: boundingbox,
    );
  }
}

class MapReverseGeocodeResult {
  MapReverseGeocodeResult({
    this.placeId,
    this.licence,
    this.osmType,
    this.osmId,
    this.lat,
    this.lon,
    this.category,
    this.type,
    this.placeRank,
    this.importance,
    this.addresstype,
    this.name,
    this.displayName,
    this.address,
    this.boundingbox,
  });

  final int? placeId;
  final String? licence;
  final String? osmType;
  final int? osmId;
  final String? lat;
  final String? lon;
  final String? category;
  final String? type;
  final int? placeRank;
  final int? importance;
  final String? addresstype;
  final String? name;
  final String? displayName;
  final MapAddress? address;
  final List<String>? boundingbox;

  factory MapReverseGeocodeResult.fromJson(Map<String, dynamic> data) {
    try {
      int? placeId = SafeParser.parseInt(data['place_id']);
      String? licence = SafeParser.parseString(data['licence']);
      String? osmType = SafeParser.parseString(data['osm_type']);
      int? osmId = SafeParser.parseInt(data['osm_id']);
      String? lat = SafeParser.parseString(data['lat']);
      String? lon = SafeParser.parseString(data['lon']);
      String? category = SafeParser.parseString(data['category']);
      String? type = SafeParser.parseString(data['type']);
      int? placeRank = SafeParser.parseInt(data['place_rank']);
      int? importance = SafeParser.parseInt(data['importance']);
      String? addresstype = SafeParser.parseString(data['addresstype']);
      String? name = SafeParser.parseString(data['name']);
      String? displayName = SafeParser.parseString(data['display_name']);
      MapAddress? address =
          data['address'] != null ? MapAddress.fromJson(data['address']) : null;
      // List<String>? boundingbox = data['boundingbox'];

      return MapReverseGeocodeResult(
        placeId: placeId,
        licence: licence,
        osmType: osmType,
        osmId: osmId,
        lat: lat,
        lon: lon,
        category: category,
        type: type,
        placeRank: placeRank,
        importance: importance,
        addresstype: addresstype,
        name: name,
        displayName: displayName,
        address: address,
        // boundingbox: boundingbox,
      );
    } catch (err) {
      print('MapReverseGeocodeResult.fromJson: $err');
    }
    return MapReverseGeocodeResult();
  }
}
