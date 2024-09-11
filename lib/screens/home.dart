import 'package:flutter/material.dart';
import 'package:flutter_lazy_indexed_stack/flutter_lazy_indexed_stack.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/constant.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/widgets/main_feed_container.dart';
import 'package:wherostr_social/widgets/notification_center_container.dart';
import 'package:wherostr_social/widgets/post_compose.dart';
import 'package:wherostr_social/widgets/profile.dart';
import 'package:wherostr_social/widgets/profile_avatar.dart';
import 'package:wherostr_social/widgets/profile_display_name.dart';
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
    const NotificationCenterContainer(),
  ];

  void popToHome() {
    Navigator.popUntil(AppStatesProvider.homeNavigatorKey.currentContext!,
        (route) => route.isFirst);
  }

  void handleDestinationSelected(index) async {
    final homeNavigatorKey = AppStatesProvider.homeNavigatorKey;
    if (_selectedIndex != index) {
      popToHome();
      setState(() {
        _selectedIndex = index;
      });
    } else if (index == 0) {
      if (Navigator.of(homeNavigatorKey.currentContext!).canPop() ||
          Navigator.of(homeNavigatorKey.currentContext!, rootNavigator: true)
              .canPop()) {
        popToHome();
      } else {
        AppStatesProvider.mainFeedKey.currentState?.nostrFeedKey.currentState
            ?.scrollToFirstItem();
      }
    } else if (index == 1) {
      popToHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLargeDisplay =
        MediaQuery.sizeOf(context).width >= Constants.largeDisplayWidth;
    final isDarkMode =
        context.read<AppThemeProvider>().themeMode == ThemeMode.dark;
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final appState = context.watch<AppStatesProvider>();
    final homeScaffoldKey = AppStatesProvider.homeScaffoldKey;
    final homeNavigatorKey = AppStatesProvider.homeNavigatorKey;
    final child = Stack(
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
          bottomNavigationBar: isLargeDisplay
              ? null
              : Material(
                  elevation: 1,
                  child: NavigationBar(
                    selectedIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
                    indicatorColor:
                        themeData.colorScheme.primary.withOpacity(0.38),
                    onDestinationSelected: handleDestinationSelected,
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
                            color:
                                themeData.colorScheme.primary.withOpacity(0.38),
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
    );
    return BackButtonListener(
      onBackButtonPressed: () {
        context.read<AppStatesProvider>().navigatorPop();
        return Future.value(true);
      },
      child: isLargeDisplay
          ? Container(
              color: themeData.colorScheme.surfaceDim,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Drawer(
                      elevation: 24,
                      child: Column(
                        children: [
                          Material(
                            color: themeData.colorScheme.primary,
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        16,
                                        MediaQuery.of(context).padding.top + 8,
                                        16,
                                        8),
                                    child: const Image(
                                      image: AssetImage(
                                          'assets/app/app-bar-icon.png'),
                                      width: 44,
                                    ),
                                  ),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.elliptical(24, 32),
                                      ),
                                      child: Container(
                                        color: themeData.colorScheme.surface,
                                        child: Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              16,
                                              MediaQuery.of(context)
                                                      .padding
                                                      .top +
                                                  8,
                                              16,
                                              8),
                                          child: Image(
                                            image: AssetImage(
                                                'assets/app/app-bar-name-${isDarkMode ? 'dark' : 'light'}.png'),
                                            height: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.only(top: 8),
                              children: [
                                ListTile(
                                  onTap: () => handleDestinationSelected(0),
                                  leading: const SizedBox(
                                    width: 36,
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(Icons.home),
                                    ),
                                  ),
                                  title: const Text("Home"),
                                  selected: _selectedIndex == 0,
                                ),
                                ListTile(
                                  onTap: () => handleDestinationSelected(1),
                                  leading: const SizedBox(
                                    width: 36,
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(Icons.search),
                                    ),
                                  ),
                                  title: const Text("Search"),
                                  selected: _selectedIndex == 1,
                                ),
                                ListTile(
                                  onTap: () => handleDestinationSelected(3),
                                  leading: const SizedBox(
                                    width: 36,
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(Icons.map),
                                    ),
                                  ),
                                  title: const Text("Map"),
                                  selected: _selectedIndex == 3,
                                ),
                                ListTile(
                                  onTap: () => handleDestinationSelected(5),
                                  leading: const SizedBox(
                                    width: 36,
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(Icons.notifications),
                                    ),
                                  ),
                                  title: const Text("Notifications"),
                                  selected: _selectedIndex == 5,
                                ),
                                ListTile(
                                  onTap: () => handleDestinationSelected(4),
                                  leading: const SizedBox(
                                    width: 36,
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(Icons.settings),
                                    ),
                                  ),
                                  title: const Text("Settings"),
                                  selected: _selectedIndex == 4,
                                ),
                                ListTile(
                                  onTap: () => appState.navigatorPush(
                                    widget: const PostCompose(),
                                    rootNavigator: true,
                                  ),
                                  horizontalTitleGap: 8,
                                  leading: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                      child: Container(
                                        color: themeData.colorScheme.primary
                                            .withOpacity(0.38),
                                        child: Icon(
                                          Icons.add,
                                          color: themeData
                                              .textTheme.bodyMedium!.color,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: const Text("Post"),
                                ),
                              ],
                            ),
                          ),
                          ListTile(
                            horizontalTitleGap: 8,
                            leading: ProfileAvatar(url: appState.me.picture),
                            title: Text(
                              "Hello!",
                              style: themeData.textTheme.bodySmall!
                                  .apply(color: themeExtension.textDimColor),
                            ),
                            subtitle: ProfileDisplayName(
                              user: appState.me,
                              textStyle: themeData.textTheme.bodyMedium,
                              withBadge: true,
                            ),
                            onTap: () => appState.navigatorPush(
                              widget: Profile(
                                user: appState.me,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: Constants.largeDisplayContentWidth,
                    child: child,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    flex: 1,
                    child: SizedBox.shrink(),
                  ),
                ],
              ),
            )
          : child,
    );
  }
}
