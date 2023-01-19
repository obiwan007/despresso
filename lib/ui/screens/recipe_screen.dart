import 'package:despresso/devices/decent_de1.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:despresso/ui/screens/coffee_selection.dart';
import 'package:despresso/ui/screens/profiles_screen.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;

import '../../model/shotstate.dart';
import '../widgets/start_stop_button.dart';

class RecipeScreen extends StatefulWidget {
  @override
  RecipeScreenState createState() => RecipeScreenState();
}

class RecipeScreenState extends State<RecipeScreen> {
  late EspressoMachineService machineService;
  late ProfileService profileService;
  late CoffeeService coffeeService;
  late ScaleService scaleService;

  double _currentTemperature = 60;
  double _currentAmount = 100;
  double _currentSteamAutoOff = 45;
  double _currentFlushAutoOff = 15;
  List<ShotState> dataPoints = [];
  EspressoMachineState currentState = EspressoMachineState.disconnected;

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();

    // Scale services is consumed as stream
    scaleService = getIt<ScaleService>();
    profileService = getIt<ProfileService>();
    coffeeService = getIt<CoffeeService>();
    coffeeService.addListener(coffeeServiceListener);
    profileService.addListener(profileServiceListener);
  }

  @override
  void dispose() {
    super.dispose();
    coffeeService.removeListener(coffeeServiceListener);
    profileService.removeListener(profileServiceListener);
  }

  machineStateListener() {
    setState(() => {currentState = machineService.state.coffeeState});
    // machineService.de1?.setIdleState();
  }

  Widget _buildControls() {
    var settings = machineService.settings;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text("Current Shot Recipe"),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Container(
                        color: Colors.black38,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: Text("Selected Base Profile")),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => const ProfilesScreen()),
                                              );
                                            },
                                            child: Text(profileService.currentProfile?.title ?? "No Profile selected"),
                                          ),
                                          Text(
                                              "Stop weight: ${profileService.currentProfile?.shotHeader.target_weight.toStringAsFixed(1)} g")
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // Row(
                                //   children: [
                                //     Expanded(child: Text("Dial In Layer")),
                                //     Expanded(
                                //       child: ElevatedButton(
                                //         onPressed: () {},
                                //         child: Text("Reduced Flow"),
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                Divider(),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: Text("Selected Bean")),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => CoffeeSelectionTab()),
                                              );
                                            },
                                            child: Text(coffeeService.currentCoffee?.name ?? "No Coffee selected"),
                                          ),
                                          Text(
                                              "Dose: ${coffeeService.currentCoffee?.grinderDoseWeight.toStringAsFixed(1)} g"),
                                          Text("Grind Settings: ${coffeeService.currentCoffee?.grinderSettings ?? ''}"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(),
                              ]),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Details"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: Text("Graph")),
                        Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                Text("Description"),
                                Text(profileService.currentProfile?.shotHeader.notes ?? ""),
                                Text(coffeeService.currentCoffee?.description ?? ""),
                              ],
                            )),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _buildControls(),
    );
  }

  void coffeeServiceListener() {
    setState(() {});
  }

  void profileServiceListener() {
    setState(() {});
  }
}
