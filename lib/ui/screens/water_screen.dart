import 'package:despresso/devices/decent_de1.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:despresso/generated/l10n.dart';

import '../../model/shotstate.dart';
import '../widgets/start_stop_button.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  WaterScreenState createState() => WaterScreenState();
}

class WaterScreenState extends State<WaterScreen> {
  late EspressoMachineService machineService;
  late ScaleService scaleService;
  late SettingsService settings;

  List<ShotState> dataPoints = [];
  EspressoMachineState currentState = EspressoMachineState.disconnected;

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    settings = getIt<SettingsService>();
    machineService.addListener(machineStateListener);

    // Scale services is consumed as stream
    scaleService = getIt<ScaleService>();
  }

  @override
  void dispose() {
    super.dispose();
    machineService.removeListener(machineStateListener);
  }

  machineStateListener() {
    setState(() => currentState = machineService.state.coffeeState);
    // machineService.de1?.setIdleState();
  }

  Widget _buildControls() {
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
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Text(S.of(context).screenHotWaterTemperaturs(settings.targetHotWaterTemp),
                              style: Theme.of(context).textTheme.labelLarge),
                          Slider(
                            value: settings.targetHotWaterTemp.toDouble(),
                            max: 100,
                            min: 30,
                            divisions: 100,
                            label: "${settings.targetHotWaterTemp} °C",
                            onChanged: (double value) {
                              setState(() {
                                settings.targetHotWaterTemp = value.toInt();
                                machineService.updateSettings();
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
                              child: SizedBox(
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
                            Text(S.of(context).screenSteamTimerS(settings.targetHotWaterLength),
                                style: Theme.of(context).textTheme.labelLarge),
                            Slider(
                              value: settings.targetHotWaterLength.toDouble(),
                              max: 100,
                              min: 5,
                              divisions: 200,
                              label: "${settings.targetHotWaterLength} s",
                              onChanged: (double value) {
                                setState(() {
                                  settings.targetHotWaterLength = value.toInt();
                                  machineService.updateSettings();
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
                                child: SizedBox(
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
                            Text(S.of(context).screenWaterWeightG(settings.targetHotWaterWeight),
                                style: Theme.of(context).textTheme.labelLarge),
                            Slider(
                              value: settings.targetHotWaterWeight.toDouble(),
                              max: 200,
                              min: 0,
                              divisions: 200,
                              label: "${settings.targetHotWaterWeight} g",
                              onChanged: (double value) {
                                setState(() {
                                  settings.targetHotWaterWeight = value.toInt();
                                  settings.targetHotWaterVol = (value * 1.1).toInt();
                                  machineService.updateSettings();
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
                                child: SizedBox(
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
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: StartStopButton(requestedState: De1StateEnum.hotWater),
              ),
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
