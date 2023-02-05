import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;

import '../../model/services/ble/machine_service.dart';
import '../../service_locator.dart';

class MachineFooter extends StatefulWidget {
  const MachineFooter({
    Key? key,
  }) : super(key: key);

  @override
  State<MachineFooter> createState() => _MachineFooterState();
}

class _MachineFooterState extends State<MachineFooter> {
  late EspressoMachineService machineService;
  late ScaleService scaleService;
  _MachineFooterState();

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    scaleService = getIt<ScaleService>();
    // machineService.addListener(updateMachine);
    // scaleService.addListener(updateMachine);

    // profileService = getIt<ProfileService>();
    // profileService.addListener(updateProfile);

    // coffeeSelectionService = getIt<CoffeeService>();
    // coffeeSelectionService.addListener(updateCoffeeSelection);
    // // Scale services is consumed as stream
    // scaleService = getIt<ScaleService>();
  }

  @override
  void dispose() {
    super.dispose();
    // machineService.removeListener(updateMachine);
    // scaleService.removeListener(updateMachine);
    // profileService.removeListener(updateProfile);
    // coffeeSelectionService.removeListener(updateCoffeeSelection);
    // log.info('Disposed espresso');
  }

  updateMachine() {
    setState(() {});
  }

  bool isOn(EspressoMachineState? state) {
    return state != EspressoMachineState.sleep && state != EspressoMachineState.disconnected;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      color: Colors.white10,
      child: Row(
        children: [
          StreamBuilder<WaterLevel>(
              stream: machineService.streamWaterLevel,
              builder: (context, snapshot) {
                return Row(
                  children: snapshot.data != null &&
                          machineService.currentFullState.state != EspressoMachineState.espresso &&
                          machineService.currentFullState.state != EspressoMachineState.water &&
                          machineService.currentFullState.state != EspressoMachineState.steam
                      ? [
                          FooterValue(
                              value: "${snapshot.data?.getLevelML()} ml / ${snapshot.data?.getLevelPercent()} %",
                              label: "Water",
                              width: 200),
                        ]
                      : [],
                );
              }),
          const Spacer(),
          Container(color: Colors.black38, child: ScaleFooter(machineService: machineService)),
          const Spacer(),
          StreamBuilder<ShotState>(
              stream: machineService.streamShotState,
              builder: (context, snapshot) {
                return Row(
                  children: snapshot.data != null && machineService.currentFullState.state != EspressoMachineState.sleep
                      ? [
                          FooterValue(value: "${snapshot.data?.headTemp.toStringAsFixed(1)} °C", label: "Group"),
                          if (machineService.currentFullState.state != EspressoMachineState.idle)
                            FooterValue(
                                value: "${snapshot.data?.groupPressure.toStringAsFixed(1)} bar", label: "Pressure"),
                          if (machineService.currentFullState.state != EspressoMachineState.idle)
                            FooterValue(value: "${snapshot.data?.groupFlow.toStringAsFixed(1)} ml/s", label: "Flow"),
                        ]
                      : [],
                );
              }),
          const Spacer(),
          StreamBuilder<EspressoMachineFullState>(
              stream: machineService.streamState,
              builder: (context, snapshot) {
                return (snapshot.data?.state != EspressoMachineState.disconnected)
                    ? Row(
                        children: [
                          Text(isOn(snapshot.data?.state) ? 'On' : 'Off'),
                          Switch(
                            value: isOn(snapshot.data?.state), //set true to enable switch by default
                            onChanged: (bool value) {
                              value ? machineService.de1!.switchOn() : machineService.de1!.switchOff();
                            },
                          ),
                        ],
                      )
                    : Row();
              }),
        ],
      ),
    );
  }
}

class ScaleFooter extends StatelessWidget {
  const ScaleFooter({
    Key? key,
    required this.machineService,
  }) : super(key: key);

  final EspressoMachineService machineService;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 310,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 36,
            child: StreamBuilder<WeightMeassurement>(
                stream: machineService.scaleService.stream,
                builder: (context, snapshot) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (machineService.scaleService.state != ScaleState.connecting)
                        OutlinedButton(
                          onPressed: () {
                            machineService.scaleService.state == ScaleState.connected
                                ? machineService.scaleService.tare()
                                : machineService.scaleService.connect();
                          },
                          child: Text(
                            machineService.scaleService.state == ScaleState.connected ? "  Tare  " : "Connect",
                          ),
                        ),
                      SizedBox(
                        width: 190,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                textAlign: TextAlign.right,
                                machineService.scaleService.state == ScaleState.connected
                                    ? "${snapshot.data?.weight.toStringAsFixed(1)} g"
                                    : machineService.scaleService.state.name,
                                style: machineService.scaleService.state == ScaleState.connected
                                    ? theme.TextStyles.headingFooter
                                    : Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: Text(
                                textAlign: TextAlign.right,
                                machineService.scaleService.state == ScaleState.connected
                                    ? "${snapshot.data?.flow.toStringAsFixed(1)} g/s"
                                    : "",
                                style: theme.TextStyles.headingFooterSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // if (machineService.scaleService.state == ScaleState.connected)
                      //   ElevatedButton(
                      //     onPressed: () => {},
                      //     child: const Text("To Shot"),
                      //   ),
                    ],
                  );
                }),
          ),
          const Text(
            'Scale',
            style: theme.TextStyles.subHeadingFooter,
          ),
          StreamBuilder<Object>(
              stream: machineService.scaleService.streamBattery,
              builder: (context, snapshot) {
                var bat = snapshot.hasData ? (snapshot.data as int) / 100.0 : 0.0;
                return LinearProgressIndicator(
                  backgroundColor: Colors.black38,
                  color: bat < 40 ? Theme.of(context).progressIndicatorTheme.linearTrackColor : Colors.red,
                  value: bat,
                  semanticsLabel: 'Battery',
                );
              }),
        ],
      ),
    );
  }
}

class FooterValue extends StatelessWidget {
  const FooterValue({Key? key, required this.value, required this.label, this.width = 120}) : super(key: key);

  final String value;
  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: theme.TextStyles.headingFooter,
          ),
          Text(
            label,
            style: theme.TextStyles.subHeadingFooter,
          ),
        ],
      ),
    );
  }
}
