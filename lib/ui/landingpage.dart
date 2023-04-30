import 'dart:async';
import 'dart:io';

import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/services/state/screen_saver.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/ui/screens/recipe_screen.dart';
import 'package:despresso/ui/screens/settings_screen.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/coffee_selection.dart';
import 'package:despresso/ui/screens/espresso_screen.dart';
import 'package:despresso/ui/screens/profiles_screen.dart';
import 'package:despresso/ui/screens/shot_selection.dart';
import 'package:despresso/ui/screens/steam_screen.dart';
import 'package:despresso/ui/screens/water_screen.dart';
import 'package:despresso/ui/widgets/machine_footer.dart';
import 'package:despresso/ui/widgets/screen_saver.dart';
import 'package:feedback_sentry/feedback_sentry.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/services/ble/ble_service.dart';
import '../model/services/ble/machine_service.dart';
import 'screens/flush_screen.dart';
import 'package:despresso/generated/l10n.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  final log = Logger('LandingPageState');

  bool available = false;
  int currentPageIndex = 1;

  late CoffeeService coffeeSelection;
  late ProfileService profileService;
  late EspressoMachineService machineService;

  late BLEService bleService;

  EspressoMachineState? lastState;

  late TabController _tabController;

  late ScreensaverService _screensaver;

  BuildContext? _saverContext;

  late SettingsService _settings;

  @override
  void initState() {
    super.initState();
    _settings = getIt<SettingsService>();
    // var l = _settings.steamHeaterOff ? 3 : 4;
    // if (_settings.showFlushScreen) l++;
    _tabController = TabController(length: calcTabs(), vsync: this, initialIndex: 1);
    machineService = getIt<EspressoMachineService>();
    coffeeSelection = getIt<CoffeeService>();

    machineService.addListener(updatedMachine);

    bleService = getIt<BLEService>();

    profileService = getIt<ProfileService>();
    profileService.addListener(updatedProfile);

    _screensaver = getIt<ScreensaverService>();
    _screensaver.addListener(screenSaverEvent);

    _settings.addListener(updatedSettings);
    // Timer timer = Timer.periodic(const Duration(seconds: 5), (timer) {
    //   log.info("Print after 5 seconds");
    //   selectedPage++;
    //   if (selectedPage > 2) selectedPage = 0;
    //   _tabController.index = selectedPage;
    // });
    Future.delayed(
      const Duration(seconds: 1),
      () {
        _settings.startCounter = _settings.startCounter + 1;
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
    machineService.removeListener(updatedMachine);
    profileService.removeListener(updatedProfile);
    _screensaver.removeListener(screenSaverEvent);
    _settings.removeListener(updatedSettings);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _screensaver.handleTap();
          },
          child: scaffoldNewLayout(context)),
    );
  }

  Widget scaffoldNewLayout(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      body: SizedBox(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  child: Builder(builder: (context) {
                    return IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.menu, color: Colors.grey),
                      tooltip: 'Options Menu',
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    );
                  }),
                ),
                Expanded(child: createTabBar()),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const RecipeScreen(),
                  const EspressoScreen(),
                  if (_settings.useSteam) const SteamScreen(),
                  if (_settings.useWater) const WaterScreen(),
                  if (_settings.showFlushScreen) const FlushScreen(),
                ],
              ),
            ),
            const MachineFooter(),
          ],
        ),
      ),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF4F378B),
              ),
              child: Column(
                children: [
                  Image.asset("assets/iconStore.png", height: 80),
                  const Text("despresso"),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.auto_graph_outlined),
              title: Text(S.of(context).mainMenuEspressoDiary),
              onTap: () {
                _screensaver.pause();
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShotSelectionTab()),
                ).then((value) => _screensaver.resume());
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(S.of(context).profiles),
              onTap: () {
                _screensaver.pause();
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProfilesScreen(
                            saveToRecipe: false,
                          )),
                ).then((value) => _screensaver.resume());
              },
            ),
            ListTile(
              leading: const Icon(Icons.coffee),
              title: Text(S.of(context).beans),
              onTap: () {
                _screensaver.pause();
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CoffeeSelectionTab(
                            saveToRecipe: false,
                          )),
                ).then((value) => _screensaver.resume());
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(S.of(context).settings),
              onTap: () {
                _screensaver.pause();
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AppSettingsScreen()),
                ).then((value) {
                  _screensaver.resume();
                  machineService.updateFlush();
                });
                // Then close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: Text(S.of(context).mainMenuFeedback),
              onTap: () async {
                Navigator.pop(context);
                var settings = getIt<SettingsService>();
                if (!settings.useSentry) {
                  _showMyDialog("Feedback currently disabled",
                      "Please enable the option 'Feedback and crashreporting' in the Settings menu.");

                  return;
                }
                BetterFeedback.of(context).showAndUploadToSentry(
                  name: S.of(context).mainMenuDespressoFeedback, // optional
                  email: 'foo_bar@example.com', // optional
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: Text(S.of(context).privacy),
              onTap: () async {
                Navigator.pop(context);
                final Uri url = Uri.parse("https://obiwan007.github.io/myagbs/");
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  throw "Could not launch $url";
                }
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.privacy_tip),
            //   title: const Text('Test'),
            //   onTap: () async {
            //     Navigator.pop(context);
            //     showScreenSaver();
            //   },
            // ),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.done:
                    return AboutListTile(
                      icon: const Icon(Icons.info),
                      applicationIcon: Image.asset("assets/iconStore.png", height: 80),
                      applicationName: 'despresso',
                      applicationVersion: "Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})",
                      applicationLegalese: '\u{a9} 2023 MMMedia Markus Miertschink',
                      // aboutBoxChildren: aboutBoxChildren,
                    );
                  default:
                    return const SizedBox();
                }
              },
            ),
            if (Platform.isAndroid)
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: Text(S.of(context).exit),
                onTap: () {
                  Navigator.pop(context);
                  var snackBar = SnackBar(
                      content: const Text('Going to sleep'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          // Some code to undo the change.
                        },
                      ));
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  machineService.de1?.switchOff();
                  // Then close the drawer
                  Future.delayed(const Duration(milliseconds: 2000), () {
                    exit(0);
                    // SystemNavigator.pop();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  SizedBox createTabBar() {
    var tb = SizedBox(
      height: 75,
      child: TabBar(
        controller: _tabController,

        // indicator: const BoxDecoration(color: Colors.black38),
        // indicator:
        //     UnderlineTabIndicator(borderSide: BorderSide(width: 5.0), insets: EdgeInsets.symmetric(horizontal: 16.0)),
        tabs: <Widget>[
          Tab(
            icon: const Icon(Icons.document_scanner),
            child: Text(S.of(context).tabHomeRecipe),
          ),
          Tab(
            icon: const Icon(Icons.coffee),
            child: Text(S.of(context).tabHomeEspresso),
          ),
          if (_settings.useSteam)
            Tab(
              icon: const Icon(Icons.stream),
              child: Text(S.of(context).tabHomeSteam),
            ),
          if (_settings.useWater)
            Tab(
              icon: const Icon(Icons.water_drop),
              child: Text(S.of(context).tabHomeWater),
            ),
          if (_settings.showFlushScreen)
            Tab(
              icon: const Icon(Icons.water),
              child: Text(S.of(context).tabHomeFlush),
            ),
        ],
      ),
    );
    return tb;
  }

  // void configureCoffee() {
  //   var snackBar = SnackBar(
  //       content: const Text('Configure your coffee'),
  //       action: SnackBarAction(
  //         label: 'Undo',
  //         onPressed: () {
  //           // Some code to undo the change.
  //         },
  //       ));
  //   ScaffoldMessenger.of(context).showSnackBar(snackBar);
  // }

  void updatedProfile() {
    setState(() {});
  }

  int calcTabs() {
    var count = 5;
    if (!_settings.useSteam) {
      count--;
      log.info("No Steam");
    }
    if (!_settings.useWater) {
      count--;
      log.info("No Water");
    }
    if (!_settings.showFlushScreen) {
      count--;
      log.info("No Flush");
    }
    log.info("Number of Tabs $count ${_settings.useSteam} ${_settings.useWater} ${_settings.showFlushScreen}");
    return count;
  }

  void updatedSettings() {
    var newTabCount = calcTabs();

    if (_tabController.length != newTabCount) {
      log.info("New tab size: $newTabCount");
      _tabController = TabController(length: newTabCount, vsync: this, initialIndex: 0);
      setState(() {});
    }
  }

  Future<void> _showMyDialog(String title, String content) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(content),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void updatedMachine() {
    if (lastState != machineService.state.coffeeState) {
      log.info("Machine state: ${machineService.state.coffeeState}");
      lastState = machineService.state.coffeeState;
      var offset = 1; // _settings.useSteam == true ? -1 : 0;

      var steam = _settings.useSteam ? 1 : 0;
      var water = _settings.useWater ? steam + 1 : 0;
      var flush = _settings.showFlushScreen ? water + 1 : 0;

      setState(() {
        switch (lastState) {
          case EspressoMachineState.espresso:
            currentPageIndex = 1;
            break;
          case EspressoMachineState.steam:
            currentPageIndex = steam + offset;
            break;
          case EspressoMachineState.water:
            currentPageIndex = water + offset;
            break;
          case EspressoMachineState.flush:
            currentPageIndex = flush + offset;
            break;
          case EspressoMachineState.idle:
            break;
          case EspressoMachineState.sleep:
            currentPageIndex = 0;
            if (_settings.screensaverOnIfIdle) {
              var screensaver = getIt<ScreensaverService>();
              screensaver.activateScreenSaver();
            }
            break;
          case EspressoMachineState.disconnected:
            break;
          case EspressoMachineState.refill:
            break;
          default:
            break;
        }
        log.info("Switch to $currentPageIndex");
        _tabController.index = currentPageIndex;
        // DefaultTabController.of(context)!
        //     .animateTo(currentPageIndex, duration: const Duration(milliseconds: 100), curve: Curves.ease);
      });
    }
  }

  void screenSaverEvent() {
    if (_screensaver.screenSaverOn == true) {
      var settings = getIt<SettingsService>();
      if (settings.screenTimoutGoToRecipe) {
        setState(() {
          _tabController.index = 0;
        });
      }
      showScreenSaver();
      setState(() {});
    } else {
      if (_saverContext != null) {
        Navigator.pop(_saverContext!);
        _saverContext = null;
      }
    }
  }

  showScreenSaver() {
    return showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        _saverContext = context;
        return Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                Navigator.pop(context);
                _saverContext = null;
                _screensaver.handleTap();
              },
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        Expanded(child: ScreenSaver()),
                      ],
                    ),
                  ),
                ],
              )),
        );
      },
    );
  }
}
