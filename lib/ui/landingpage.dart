import 'dart:async';

import 'package:despresso/logger_util.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/ui/screens/recipe_screen.dart';
import 'package:despresso/ui/screens/settings_screen.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/coffee_selection.dart';
import 'package:despresso/ui/screens/espresso_screen.dart';
import 'package:despresso/ui/screens/profiles_screen.dart';
import 'package:despresso/ui/screens/steam_screen.dart';
import 'package:despresso/ui/screens/water_screen.dart';
import 'package:despresso/ui/widgets/machine_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/services/ble/ble_service.dart';
import '../model/services/ble/machine_service.dart';
import 'screens/flush_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  final log = getLogger();
  bool available = false;
  int currentPageIndex = 1;

  late CoffeeService coffeeSelection;
  late ProfileService profileService;
  late EspressoMachineService machineService;

  late BLEService bleService;

  EspressoMachineState? lastState;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 1);
    machineService = getIt<EspressoMachineService>();
    coffeeSelection = getIt<CoffeeService>();

    machineService.addListener(updatedMachine);

    bleService = getIt<BLEService>();

    profileService = getIt<ProfileService>();
    profileService.addListener(updatedProfile);
    // Timer timer = Timer.periodic(const Duration(seconds: 5), (timer) {
    //   log.i("Print after 5 seconds");
    //   selectedPage++;
    //   if (selectedPage > 2) selectedPage = 0;
    //   _tabController.index = selectedPage;
    // });
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
    machineService.removeListener(updatedMachine);
    profileService.removeListener(updatedProfile);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: scaffoldNewLayout(context),
    );
  }

  Widget scaffoldNewLayout(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
                  children: const [
                    RecipeScreen(),
                    EspressoScreen(),
                    SteamScreen(),
                    WaterScreen(),
                    FlushScreen(),
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
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text("despresso settings"),
              ),
              ListTile(
                title: const Text('Profiles'),
                onTap: () {
                  // Update the state of the app
                  // ...
                  // Then close the drawer
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilesScreen()),
                  );
                },
              ),
              ListTile(
                title: const Text('Coffees'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CoffeeSelectionTab()),
                  );
                },
              ),
              ListTile(
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AppSettingsScreen()),
                  );
                  // Then close the drawer
                },
              ),
              ListTile(
                title: const Text('Exit'),
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
                    SystemNavigator.pop();
                  });
                },
              ),
              ListTile(
                title: const Text('Privacy'),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri url = Uri.parse("https://obiwan007.github.io/myagbs/");
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else
                    // can't launch url, there is some error
                    throw "Could not launch $url";
                },
              ),
              const AboutListTile(
                icon: Icon(Icons.info),
                applicationIcon: FlutterLogo(),
                applicationName: 'About despresso',
                applicationVersion: 'August 2023',
                applicationLegalese: '\u{a9} 2023 MMMedia Markus Miertschink',
                // aboutBoxChildren: aboutBoxChildren,
              ),
            ],
          ),
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
        tabs: const <Widget>[
          Tab(
            icon: Icon(Icons.document_scanner),
            child: Text("Recipe"),
          ),
          Tab(
            icon: Icon(Icons.coffee),
            child: Text("Espresso"),
          ),
          Tab(
            icon: Icon(Icons.stream),
            child: Text("Steam"),
          ),
          Tab(
            icon: Icon(Icons.water_drop),
            child: Text("Water"),
          ),
          Tab(
            icon: Icon(Icons.water),
            child: Text("Flush"),
          ),
        ],
      ),
    );
    return tb;
  }

  void configureCoffee() {
    var snackBar = SnackBar(
        content: const Text('Configure your coffee'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Some code to undo the change.
          },
        ));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void updatedProfile() {
    setState(() {});
  }

  void updatedMachine() {
    if (lastState != machineService.state.coffeeState) {
      log.i("Machine state: ${machineService.state.coffeeState}");
      lastState = machineService.state.coffeeState;
      setState(() {
        switch (lastState) {
          case EspressoMachineState.espresso:
            currentPageIndex = 1;
            break;
          case EspressoMachineState.steam:
            currentPageIndex = 2;
            break;
          case EspressoMachineState.flush:
            currentPageIndex = 4;
            break;
          case EspressoMachineState.water:
            currentPageIndex = 3;
            break;
          case EspressoMachineState.idle:
            break;
          case EspressoMachineState.sleep:
            currentPageIndex = 0;
            break;
          case EspressoMachineState.disconnected:
            break;
          case EspressoMachineState.refill:
            break;
          default:
            break;
        }
        log.i("Switch to $currentPageIndex");
        _tabController.index = currentPageIndex;
        // DefaultTabController.of(context)!
        //     .animateTo(currentPageIndex, duration: const Duration(milliseconds: 100), curve: Curves.ease);
      });
    }
  }
}
