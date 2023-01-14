import 'dart:async';
import 'dart:developer';

import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/coffee_selection.dart';
import 'package:despresso/ui/screens/espresso_screen.dart';
import 'package:despresso/ui/screens/profiles_screen.dart';
import 'package:despresso/ui/screens/steam_screen.dart';
import 'package:despresso/ui/screens/water_screen.dart';
import 'package:despresso/ui/widgets/machine_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/services/ble/ble_service.dart';
import '../model/services/ble/machine_service.dart';
import 'screens/flush_screen.dart';
import 'theme.dart' as theme;

class LandingPage extends StatefulWidget {
  LandingPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  bool available = false;
  int currentPageIndex = 0;

  late CoffeeService coffeeSelection;
  late ProfileService profileService;
  late EspressoMachineService machineService;

  late BLEService bleService;

  EspressoMachineState? lastState;

  int selectedPage = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    machineService = getIt<EspressoMachineService>();
    coffeeSelection = getIt<CoffeeService>();

    machineService.addListener(updatedMachine);

    bleService = getIt<BLEService>();

    profileService = getIt<ProfileService>();
    profileService.addListener(updatedProfile);
    // Timer timer = Timer.periodic(const Duration(seconds: 5), (timer) {
    //   log("Print after 5 seconds");
    //   selectedPage++;
    //   if (selectedPage > 2) selectedPage = 0;
    //   _tabController.index = selectedPage;
    // });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _tabController.dispose();
    machineService.removeListener(updatedMachine);
    profileService.removeListener(updatedProfile);
  }

  Widget _buildButton(child, onpress) {
    var color = theme.Colors.backgroundColor;
    return Container(
        padding: const EdgeInsets.all(10.0),
        child: TextButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(theme.Colors.primaryColor),
            backgroundColor: MaterialStateProperty.all<Color>(color),
          ),
          onPressed: onpress,
          child: Container(
            height: 50,
            padding: const EdgeInsets.all(10.0),
            child: child,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: scaffoldNewLayout(context),
    );
  }

  Scaffold scaffoldNewLayout(BuildContext context) {
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
                  MaterialPageRoute(builder: (context) => CoffeeSelectionTab()),
                );
              },
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () {
                // Update the state of the app
                // ...
                bleService.startScan();
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
          ],
        ),
      ),
    );
  }

  Scaffold scaffoldOldLayout(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: MediaQuery.of(context).orientation == Orientation.portrait ? createNavbar() : null,
      appBar: AppBar(
        title: Row(
          children: [
            Text("${widget.title} ", style: theme.TextStyles.appBarTitle),
            Text(" ${profileService.currentProfile?.title ?? ''}", style: theme.TextStyles.appBarTitleProfile),
          ],
        ),
        actions: <Widget>[
          IconButton(
            iconSize: 40,
            isSelected: machineService.state.coffeeState == EspressoMachineState.sleep,
            icon: const Icon(Icons.power_settings_new, color: Colors.green),
            selectedIcon: const Icon(
              Icons.power_off,
              color: Colors.red,
            ),
            tooltip: 'Switch on/off decent de1',
            onPressed: () {
              if (machineService.state.coffeeState == EspressoMachineState.sleep) {
                machineService.de1?.switchOn();
              } else {
                machineService.de1?.switchOff();
              }
            },
          ),
        ],
      ),
      body: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          if (MediaQuery.of(context).orientation == Orientation.landscape) createNavRail(),
          Expanded(
              child: <Widget>[
            //CoffeeSelectionTab(),
            EspressoScreen(),
            SteamScreen(),
            FlushScreen(),
            WaterScreen(),
          ][currentPageIndex]),
        ],
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
                // Update the state of the app
                // ...
                // Then close the drawer
                configureCoffee();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () {
                // Update the state of the app
                // ...
                bleService.startScan();
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
          ],
        ),
      ),
    );
  }

  NavigationBar createNavbar() {
    return NavigationBar(
      onDestinationSelected: (int index) {
        setState(() {
          currentPageIndex = index;
        });
      },
      selectedIndex: currentPageIndex,
      destinations: const <Widget>[
        NavigationDestination(
          icon: Icon(Icons.coffee),
          label: 'Coffee',
        ),
        NavigationDestination(
          icon: Icon(Icons.coffee),
          label: 'Espresso',
        ),
        NavigationDestination(
          icon: Icon(Icons.filter_list),
          label: 'Steam',
        ),
        NavigationDestination(
          icon: Icon(Icons.water),
          label: 'Flush',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.bookmark),
          icon: Icon(Icons.water_drop),
          label: 'Water',
        ),
      ],
    );
  }

  Container createTabBar() {
    var tb = Container(
      height: 70,
      child: TabBar(
        controller: _tabController,
        indicator: const BoxDecoration(color: Colors.brown),
        // indicator:
        //     UnderlineTabIndicator(borderSide: BorderSide(width: 5.0), insets: EdgeInsets.symmetric(horizontal: 16.0)),
        tabs: const <Widget>[
          Tab(
            child: Text("Espresso"),
          ),
          Tab(
            child: Text("Steam"),
          ),
          Tab(
            child: Text("Water"),
          ),
          Tab(
            child: Text("Flush"),
          ),
        ],
      ),
    );
    return tb;
  }

  NavigationRail createNavRail() {
    return NavigationRail(
      minExtendedWidth: 100,
      minWidth: 100,
      labelType: NavigationRailLabelType.all,
      onDestinationSelected: (int index) {
        setState(() {
          currentPageIndex = index;
        });
      },
      selectedIndex: currentPageIndex,
      destinations: const <NavigationRailDestination>[
        NavigationRailDestination(
          icon: Icon(Icons.coffee),
          label: Text('Coffee'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.coffee),
          label: Text('Espresso'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.filter_list),
          label: Text('Steam'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.water),
          label: Text('Flush'),
        ),
        NavigationRailDestination(
          selectedIcon: Icon(Icons.bookmark),
          icon: Icon(Icons.water_drop),
          label: Text('Water'),
        ),
      ],
    );
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
      log("Machine state: ${machineService.state.coffeeState}");
      lastState = machineService.state.coffeeState;
      setState(() {
        switch (lastState) {
          case EspressoMachineState.espresso:
            currentPageIndex = 0;
            break;
          case EspressoMachineState.steam:
            currentPageIndex = 1;
            break;
          case EspressoMachineState.flush:
            currentPageIndex = 3;
            break;
          case EspressoMachineState.water:
            currentPageIndex = 2;
            break;
          case EspressoMachineState.idle:
            break;
          case EspressoMachineState.sleep:
            break;
          case EspressoMachineState.disconnected:
            break;
          case EspressoMachineState.refill:
            break;
          default:
            break;
        }
        log("Switch to $currentPageIndex");
        _tabController.index = currentPageIndex;
        // DefaultTabController.of(context)!
        //     .animateTo(currentPageIndex, duration: const Duration(milliseconds: 100), curve: Curves.ease);
      });
    }
  }
}
