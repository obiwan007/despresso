import 'package:despresso/devices/decent_de1.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;

import '../../model/shotstate.dart';
import '../widgets/start_stop_button.dart';

class FlushScreen extends StatefulWidget {
  const FlushScreen({super.key});

  @override
  _FlushScreenState createState() => _FlushScreenState();
}

class _FlushScreenState extends State<FlushScreen> {
  late EspressoMachineService machineService;
  late ScaleService scaleService;

  List<ShotState> dataPoints = [];
  EspressoMachineState currentState = EspressoMachineState.disconnected;

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Text("Timer ${settings.targetFlushTime} s", style: theme.TextStyles.tabHeading),
                            Slider(
                              value: settings.targetFlushTime.toDouble(),
                              max: 100,
                              min: 1,
                              divisions: 100,
                              label: "${settings.targetFlushTime} s",
                              onChanged: (double value) {
                                setState(() {
                                  settings.targetFlushTime = value.toInt();
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
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 15,
                                    value: machineService.state.coffeeState == EspressoMachineState.flush
                                        ? machineService.timer.inSeconds / settings.targetFlushTime
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
