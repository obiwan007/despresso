import 'package:despresso/devices/decent_de1.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;

import '../../model/shotstate.dart';
import '../widgets/start_stop_button.dart';

class FlushScreen extends StatefulWidget {
  const FlushScreen({super.key});

  @override
  FlushScreenState createState() => FlushScreenState();
}

class FlushScreenState extends State<FlushScreen> {
  late EspressoMachineService machineService;

  late SettingsService settings;

  List<ShotState> dataPoints = [];
  EspressoMachineState currentState = EspressoMachineState.disconnected;

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();

    settings = getIt<SettingsService>();

    machineService.addListener(machineStateListener);
    settings.addListener(machineStateListener);

    // Scale services is consumed as stream
  }

  @override
  void dispose() {
    super.dispose();
    machineService.removeListener(machineStateListener);
    settings.removeListener(machineStateListener);
  }

  machineStateListener() {
    setState(() => {currentState = machineService.state.coffeeState});
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Text("Timer ${settings.targetFlushTime.toInt()} s",
                                style: Theme.of(context).textTheme.labelLarge),
                            Slider(
                              value: settings.targetFlushTime.toDouble(),
                              max: 60,
                              min: 0,
                              divisions: 60,
                              label: "${settings.targetFlushTime.toInt()} s",
                              onChanged: (double value) {
                                setState(() {
                                  settings.targetFlushTime = value;
                                  settings.notifyDelayed();
                                });
                              },
                            ),
                            Text("Second Timer ${settings.targetFlushTime2.toInt()} s",
                                style: Theme.of(context).textTheme.labelLarge),
                            Slider(
                              value: settings.targetFlushTime2.toDouble(),
                              max: 60,
                              min: 0,
                              divisions: 60,
                              label: "${settings.targetFlushTime2.toInt()} s",
                              onChanged: (double value) {
                                setState(() {
                                  settings.targetFlushTime2 = value;
                                  settings.notifyDelayed();
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
                            if (machineService.state.coffeeState == EspressoMachineState.flush) ...[
                              Center(
                                child: SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 15,
                                    value: machineService.state.coffeeState == EspressoMachineState.flush
                                        ? machineService.timer.inSeconds.toDouble() /
                                            (machineService.flushCounter == 1
                                                ? settings.targetFlushTime
                                                : settings.targetFlushTime2)
                                        : 0,
                                  ),
                                ),
                              ),
                              Center(child: Text("${machineService.timer.inSeconds.toStringAsFixed(0)}s")),
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
                child: StartStopButton(requestedState: De1StateEnum.hotWaterRinse),
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
