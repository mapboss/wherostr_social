import 'package:flutter/material.dart';
import 'package:flutter_lazy_indexed_stack/flutter_lazy_indexed_stack.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/widgets/main_feed_container.dart';
import 'package:wherostr_social/widgets/post_compose.dart';
import 'package:wherostr_social/widgets/search_container.dart';
import 'package:wherostr_social/widgets/settings_container.dart';
import 'package:wherostr_social/widgets/social_map_container.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const MainFeedContainer(),
    const SearchContainer(),
    const SizedBox.shrink(),
    const SocialMapContainer(),
    const SettingsContainer(),
  ];

  void popToHome() {
    Navigator.popUntil(AppStatesProvider.homeNavigatorKey.currentContext!,
        (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    final appState = context.watch<AppStatesProvider>();
    final homeScaffoldKey = AppStatesProvider.homeScaffoldKey;
    final homeNavigatorKey = AppStatesProvider.homeNavigatorKey;
    return BackButtonListener(
      onBackButtonPressed: () {
        context.read<AppStatesProvider>().navigatorPop();
        return Future.value(true);
      },
      child: Stack(
        children: [
          Scaffold(
            key: homeScaffoldKey,
            body: HeroControllerScope(
              controller: MaterialApp.createMaterialHeroController(),
              child: Navigator(
                key: homeNavigatorKey,
                onGenerateRoute: (routeSettings) {
                  return MaterialPageRoute(
                    builder: (context) => LazyIndexedStack(
                      index: _selectedIndex,
                      children: _screens,
                    ),
                  );
                },
              ),
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                boxShadow: kElevationToShadow[1],
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                indicatorColor: themeData.colorScheme.primary.withOpacity(0.38),
                onDestinationSelected: (index) async {
                  if (_selectedIndex != index) {
                    popToHome();
                    setState(() {
                      _selectedIndex = index;
                    });
                  } else if (index == 0) {
                    if (Navigator.of(homeNavigatorKey.currentContext!)
                            .canPop() ||
                        Navigator.of(homeNavigatorKey.currentContext!,
                                rootNavigator: true)
                            .canPop()) {
                      popToHome();
                    } else {
                      AppStatesProvider
                          .mainFeedKey.currentState?.nostrFeedKey.currentState
                          ?.scrollToFirstItem();
                    }
                  } else if (index == 1) {
                    popToHome();
                  }
                },
                height: 64,
                destinations: [
                  NavigationDestination(
                    icon: Icon(
                      Icons.home,
                      color: themeData.textTheme.bodyMedium!.color,
                    ),
                    label: "Home",
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.search,
                      color: themeData.textTheme.bodyMedium!.color,
                    ),
                    label: "Search",
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(12),
                      ),
                      child: Container(
                        color: themeData.colorScheme.primary.withOpacity(0.38),
                        child: InkWell(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.add,
                              color: themeData.textTheme.bodyMedium!.color,
                            ),
                          ),
                          onTap: () => appState.navigatorPush(
                            widget: const PostCompose(),
                            rootNavigator: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.map,
                      color: themeData.textTheme.bodyMedium!.color,
                    ),
                    label: "Map",
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.settings,
                      color: themeData.textTheme.bodyMedium!.color,
                    ),
                    label: "Settings",
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).padding.top,
            child: GestureDetector(
              excludeFromSemantics: true,
              onTap: () {
                if (_selectedIndex == 0) {
                  AppStatesProvider
                      .mainFeedKey.currentState?.nostrFeedKey.currentState
                      ?.scrollToFirstItem();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
