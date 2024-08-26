import 'package:flutter/material.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/widgets/map_events_filter.dart';

class SocialMapContainer extends StatefulWidget {
  const SocialMapContainer({super.key});

  @override
  State createState() => _SocialMapContainerState();
}

class _SocialMapContainerState extends State<SocialMapContainer> {
  @override
  Widget build(BuildContext context) {
    final topPadding =
        MediaQuery.of(AppStatesProvider.homeScaffoldKey.currentContext!)
            .viewPadding
            .top;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(topPadding),
        child: SizedBox(height: topPadding),
      ),
      body: const MapEventsFilter(),
    );
  }
}
