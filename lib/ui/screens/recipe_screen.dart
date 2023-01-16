import 'package:despresso/devices/decent_de1.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
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
    machineService.addListener(machineStateListener);

    // Scale services is consumed as stream
    scaleService = getIt<ScaleService>();
    profileService = getIt<ProfileService>();
    coffeeService = getIt<CoffeeService>();
  }

  @override
  void dispose() {
    super.dispose();
    machineService.removeListener(machineStateListener);
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
                Row(
                  children: [
                    Text("Recipe"),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Text("Temperatur ${settings.targetHotWaterTemp}°C", style: theme.TextStyles.tabHeading),
                          Slider(
                            value: settings.targetHotWaterTemp.toDouble(),
                            max: 100,
                            min: 30,
                            divisions: 100,
                            label: "${settings.targetHotWaterTemp} °C",
                            onChanged: (double value) {
                              setState(() {
                                settings.targetHotWaterTemp = value.toInt();
                                machineService.updateSettings(settings);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: Stack(
                        children: <Widget>[
                          if (machineService.state.coffeeState == EspressoMachineState.water) ...[
                            Center(
                              child: Container(
                                width: 200,
                                height: 200,
                                child: CircularProgressIndicator(
                                  strokeWidth: 15,
                                  value: machineService.state.shot?.mixTemp ?? 0 / settings.targetHotWaterTemp,
                                ),
                              ),
                            ),
                            Center(child: Text("${machineService.state.shot?.mixTemp.toStringAsFixed(0)} °C")),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(
                  height: 20,
                  thickness: 5,
                  indent: 20,
                  endIndent: 0,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Text("Timer ${settings.targetHotWaterLength} s", style: theme.TextStyles.tabHeading),
                            Slider(
                              value: settings.targetHotWaterLength.toDouble(),
                              max: 100,
                              min: 5,
                              divisions: 200,
                              label: "${settings.targetHotWaterLength} s",
                              onChanged: (double value) {
                                setState(() {
                                  settings.targetHotWaterLength = value.toInt();
                                  machineService.updateSettings(settings);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: Stack(
                          children: <Widget>[
                            if (machineService.state.coffeeState == EspressoMachineState.water) ...[
                              Center(
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 15,
                                    value: machineService.state.coffeeState == EspressoMachineState.water
                                        ? machineService.timer.inSeconds / settings.targetHotWaterLength
                                        : 0,
                                  ),
                                ),
                              ),
                              Center(child: Text("${machineService.timer.inSeconds.toStringAsFixed(0)}s")),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 20,
                  thickness: 5,
                  indent: 20,
                  endIndent: 0,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Text("Weight ${settings.targetHotWaterWeight} g", style: theme.TextStyles.tabHeading),
                            Slider(
                              value: settings.targetHotWaterWeight.toDouble(),
                              max: 200,
                              min: 10,
                              divisions: 200,
                              label: "${settings.targetHotWaterWeight} g",
                              onChanged: (double value) {
                                setState(() {
                                  settings.targetHotWaterWeight = value.toInt();
                                  machineService.updateSettings(settings);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: Stack(
                          children: <Widget>[
                            if (machineService.state.coffeeState == EspressoMachineState.water) ...[
                              Center(
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 15,
                                    value: machineService.scaleService.weight / settings.targetHotWaterWeight,
                                  ),
                                ),
                              ),
                              Center(child: Text("${machineService.scaleService.weight.toStringAsFixed(0)} g")),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const StartStopButton(),
            ],
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
}
