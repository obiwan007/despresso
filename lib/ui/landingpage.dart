import 'dart:async';
import 'dart:developer';

import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/espresso_screen.dart';
import 'package:despresso/ui/screens/profiles_screen.dart';
import 'package:despresso/ui/screens/water_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/services/ble/ble_service.dart';
import '../model/services/ble/machine_service.dart';
import 'theme.dart' as theme;

class LandingPage extends StatefulWidget {
  LandingPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  bool available = false;

  late CoffeeService coffeeSelection;
  late ProfileService profileService;
  late EspressoMachineService machineService;

  late BLEService bleService;
  late final _tabController = TabController(length: 4, vsync: this, initialIndex: 0);

  EspressoMachineState? lastState;

  int selectedPage = 0;

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    coffeeSelection = getIt<CoffeeService>();

    machineService.addListener(updatedMachine);

    bleService = getIt<BLEService>();

    profileService = getIt<ProfileService>();
    // profileService.addListener(() {
    //   setState(() {});
    // });
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
    machineService.removeListener(updatedMachine);
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
    Widget coffee;
    var currentCoffee = coffeeSelection.currentCoffee;
    if (currentCoffee != null) {
      coffee = Row(children: [
        const Spacer(
          flex: 2,
        ),
        Text(
          currentCoffee.roaster,
          style: theme.TextStyles.tabSecondary,
        ),
        const Spacer(
          flex: 1,
        ),
        Text(
          currentCoffee.name,
          style: theme.TextStyles.tabSecondary,
        ),
        const Spacer(
          flex: 2,
        ),
      ]);
    } else {
      coffee = const Text(
        'No Coffee selected',
        style: theme.TextStyles.tabSecondary,
      );
    }
    Widget profile;
    var currentProfile = profileService.currentProfile;

    return DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                const Tab(
                  icon: const Icon(Icons.coffee),
                  child: const Text(
                    "Espresso",
                    style: theme.TextStyles.tabLabel,
                  ),
                ),
                const Tab(
                  icon: Icon(Icons.filter_list),
                  child: Text(
                    'Steam',
                    style: theme.TextStyles.tabLabel,
                  ),
                ),
                const Tab(
                  icon: Icon(Icons.water),
                  child: Text(
                    "Flush",
                    style: theme.TextStyles.tabLabel,
                  ),
                ),
                const Tab(
                  icon: Icon(Icons.water_drop),
                  child: Text(
                    'Water',
                    style: theme.TextStyles.tabLabel,
                  ),
                )
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              EspressoScreen(),
              const Icon(Icons.coffee),
              const Icon(Icons.directions_bike),
              WaterScreen(),
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
                  child: Text('Drawer Header'),
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
        ));
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

  void updatedMachine() {
    if (lastState != machineService.state.coffeeState) {
      log("Machine state: ${machineService.state.coffeeState}");
      lastState = machineService.state.coffeeState;
      setState(() {
        switch (lastState) {
          case EspressoMachineState.espresso:
            selectedPage = 0;
            break;
          case EspressoMachineState.steam:
            selectedPage = 1;
            break;
          case EspressoMachineState.flush:
            selectedPage = 2;
            break;
          case EspressoMachineState.water:
            selectedPage = 3;
            break;
          case EspressoMachineState.idle:
            // TODO: Handle this case.
            break;
          case EspressoMachineState.sleep:
            // TODO: Handle this case.
            break;
          case EspressoMachineState.disconnected:
            // TODO: Handle this case.
            break;
          case EspressoMachineState.refill:
            // TODO: Handle this case.
            break;
          default:
            // TODO: Handle this case.
            break;
        }
        _tabController.index = selectedPage;
      });
    }
  }
}
