import 'package:flutter/material.dart';
import 'package:wherostr_social/models/map.dart';
import 'package:wherostr_social/services/map.dart';

class PlacesSearchBox extends StatefulWidget {
  final Future<void> Function(MapSearchResult location)? onLocated;
  const PlacesSearchBox({
    super.key,
    this.onLocated,
  });

  @override
  State createState() => _PlacesSearchBoxState();
}

class _PlacesSearchBoxState extends State<PlacesSearchBox> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _searchLocation(String query) async {
    try {
      List<MapSearchResult> locations = await MapService.search(query);
      print(
          '_searchLocation.locations: ${locations.map((e) => e.displayName)}');
      if (locations.isNotEmpty) {
        widget.onLocated?.call(locations.first);
      }
    } catch (e) {
      print('_searchLocation.Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Search for places',
        border: InputBorder.none,
        icon: Icon(Icons.search),
      ),
      onSubmitted: _searchLocation,
    );
  }
}
