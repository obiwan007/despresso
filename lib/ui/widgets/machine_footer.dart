import 'package:despresso/generated/l10n.dart';
import 'package:despresso/helper/message.dart';
import 'package:despresso/model/services/ble/ble_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/ble/temperature_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:logging/logging.dart';
import 'package:despresso/model/services/state/screen_saver.dart';

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
  final log = Logger('MachineFooterState');
  late EspressoMachineService machineService;
  late ScaleService scaleService;
  late SettingsService settingsService;
  late BLEService bleService;

  _MachineFooterState();

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    scaleService = getIt<ScaleService>();
    settingsService = getIt<SettingsService>();
    settingsService.addListener(updateMachine);

    bleService = getIt<BLEService>();
    bleService.addListener(checkError);
    // scaleService.addListener();

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
    settingsService.removeListener(updateMachine);
    bleService.removeListener(checkError);
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
    if (bleService.error.isNotEmpty) {
      showError(context, bleService.error);
      bleService.error = "";
    }
    return Container(
      height: 70,
      color: settingsService.screenDarkTheme ? Colors.white12 : Colors.black12,
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
                          machineService.currentFullState.state == EspressoMachineState.refill
                              ? Container(
                                  color: Colors.red,
                                  child: FooterValue(
                                      value: S.of(context).footerRefillWater,
                                      label: S.of(context).footerWater,
                                      width: 200),
                                )
                              : FooterValue(
                                  value: "${snapshot.data?.getLevelML()} ml",
                                  label: S.of(context).footerWater,
                                  width: 200)
                        ]
                      : [],
                );
              }),
          const Spacer(),
          if (settingsService.hasScale) ScaleFooter(machineService: machineService),
          if (settingsService.hasSteamThermometer) ThermprobeFooter(machineService: machineService),
          const Spacer(),
          StreamBuilder<ShotState>(
              stream: machineService.streamShotState,
              builder: (context, snapshot) {
                return Row(
                  children: snapshot.data != null && machineService.currentFullState.state != EspressoMachineState.sleep
                      ? [
                          FooterValue(
                              value: "${snapshot.data?.headTemp.toStringAsFixed(1)} °C",
                              label: S.of(context).footerGroup),
                          if (machineService.currentFullState.state != EspressoMachineState.idle)
                            FooterValue(
                                value: "${snapshot.data?.groupPressure.toStringAsFixed(1)} bar",
                                label: S.of(context).pressure),
                          if (machineService.currentFullState.state != EspressoMachineState.idle)
                            FooterValue(
                                value: "${snapshot.data?.groupFlow.toStringAsFixed(1)} ml/s",
                                label: S.of(context).flow),
                        ]
                      : [],
                );
              }),
          const Spacer(),
          StreamBuilder<EspressoMachineFullState>(
              stream: machineService.streamState,
              builder: (context, snapshot) {
                return (snapshot.hasData &&
                        snapshot.data?.state != EspressoMachineState.disconnected &&
                        snapshot.data?.state != EspressoMachineState.connecting)
                    ? Row(
                        children: [
                          Text(isOn(snapshot.data?.state) ? S.of(context).on : S.of(context).off),
                          Switch(
                            value: isOn(snapshot.data?.state), //set true to enable switch by default
                            onChanged: (bool value) {
                              if (value) {
                                machineService.de1?.switchOn();
                              } else {
                                if (settingsService.screensaverOnIfIdle) {
                                  var screensaver = getIt<ScreensaverService>();
                                  screensaver.activateScreenSaver();
                                }
                                // screensaver.notifyDelayed();
                                machineService.de1?.switchOff();
                              }
                            },
                          ),
                        ],
                      )
                    : const Row();
              }),
        ],
      ),
    );
  }

  void checkError() {
    setState(() {});
  }
}

class ThermprobeFooter extends StatelessWidget {
  const ThermprobeFooter({
    Key? key,
    required this.machineService,
  }) : super(key: key);

  final EspressoMachineService machineService;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 36,
            child: StreamBuilder<TempMeassurement>(
                stream: machineService.tempService.stream,
                builder: (context, snapshot) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (machineService.tempService.state == TempState.disconnected)
                        OutlinedButton(
                          onPressed: () {
                            machineService.tempService.connect();
                          },
                          child: Text(
                            S.of(context).footerConnect,
                          ),
                        ),
                      if (machineService.tempService.state == TempState.connected)
                        SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: FittedBox(
                                  fit: BoxFit.fitHeight,
                                  child: machineService.tempService.state == TempState.connected
                                      ? Text(
                                          textAlign: TextAlign.right,
                                          "${snapshot.data?.temp1.toStringAsFixed(1)} °C",
                                          style: Theme.of(context).textTheme.headlineSmall,
                                        )
                                      : FittedBox(
                                          fit: BoxFit.fitWidth,
                                          child: Text(
                                            textAlign: TextAlign.right,
                                            machineService.tempService.state.name,
                                            style: Theme.of(context).textTheme.headlineSmall,
                                          ),
                                        ),
                                ),
                              ),
                              // SizedBox(
                              //   width: 90,
                              //   child: Text(
                              //     textAlign: TextAlign.right,
                              //     machineService.tempService.state == TempState.connected
                              //         ? "${snapshot.data?.temp2.toStringAsFixed(1)} °C"
                              //         : "",
                              //     style: theme.TextStyles.headingFooterSmall,
                              //   ),
                              // ),
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
          Text(
            S.of(context).footerProbe,
            style: theme.TextStyles.subHeadingFooter,
          ),
          StreamBuilder<Object>(
              stream: machineService.tempService.streamBattery,
              builder: (context, snapshot) {
                var bat = snapshot.hasData ? (snapshot.data as int) / 100.0 : 0.0;
                return LinearProgressIndicator(
                  backgroundColor: Colors.black38,
                  color: bat < 40 ? Theme.of(context).progressIndicatorTheme.linearTrackColor : Colors.red,
                  value: bat,
                  semanticsLabel: S.of(context).footerBattery,
                );
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
      child: StreamBuilder<WeightMeassurement>(
          stream: machineService.scaleService.stream,
          builder: (context, snapshot) {
            return Container(
              color: machineService.scaleService.state != ScaleState.connecting
                  ? machineService.scaleService.state != ScaleState.connected
                      ? Colors.red
                      : null
                  : Colors.orange.shade900,
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
                              if (machineService.scaleService.state != ScaleState.connecting &&
                                  machineService.scaleService.state == ScaleState.connected)
                                OutlinedButton(
                                  onPressed: () async {
                                    await machineService.scaleService.tare();
                                  },
                                  child: Text(S.of(context).footerTare),
                                ),
                              if (machineService.scaleService.state != ScaleState.connecting &&
                                  machineService.scaleService.state != ScaleState.connected)
                                ElevatedButton(
                                  onPressed: () {
                                    machineService.scaleService.connect();
                                  },
                                  child: Text(
                                    S.of(context).footerConnect,
                                  ),
                                ),

                              if (machineService.scaleService.state == ScaleState.connecting)
                                Text(
                                  textAlign: TextAlign.right,
                                  machineService.scaleService.state.name,
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                              if (machineService.scaleService.state == ScaleState.connected)
                                SizedBox(
                                  width: 190,
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 100,
                                        child: FittedBox(
                                          fit: BoxFit.fitHeight,
                                          child: machineService.scaleService.state == ScaleState.connected
                                              ? Text(
                                                  textAlign: TextAlign.right,
                                                  "${snapshot.data?.weight.toStringAsFixed(1)} g",
                                                  style: Theme.of(context).textTheme.headlineSmall,
                                                )
                                              : machineService.scaleService.state != ScaleState.disconnected
                                                  ? FittedBox(
                                                      fit: BoxFit.fitWidth,
                                                      child: Text(
                                                        textAlign: TextAlign.right,
                                                        machineService.scaleService.state.name,
                                                        style: Theme.of(context).textTheme.labelSmall,
                                                      ),
                                                    )
                                                  : const Text(""),
                                        ),
                                      ),
                                      machineService.state.coffeeState == EspressoMachineState.idle ||
                                              machineService.state.coffeeState == EspressoMachineState.disconnected
                                          ? SizedBox(
                                              width: 90,
                                              child: OutlinedButton(
                                                onPressed: () {
                                                  Feedback.forTap(context);
                                                  var coffeeService = getIt<CoffeeService>();
                                                  var settingsService = getIt<SettingsService>();
                                                  var r = coffeeService.currentRecipe;
                                                  if (r != null) {
                                                    r.grinderDoseWeight = machineService.scaleService.weight;
                                                    r.adjustedWeight =
                                                        machineService.scaleService.weight * (r.ratio2 / r.ratio1);
                                                    coffeeService.updateRecipe(r);
                                                    settingsService.targetEspressoWeight = r.adjustedWeight;
                                                  }
                                                },
                                                child: const FittedBox(child: Text("set-in")),
                                              ),
                                            )
                                          : SizedBox(
                                              width: 90,
                                              child: Text(
                                                textAlign: TextAlign.right,
                                                machineService.scaleService.state == ScaleState.connected
                                                    ? "${snapshot.data?.flow.toStringAsFixed(1)} g/s"
                                                    : "",
                                                style: Theme.of(context).textTheme.bodyMedium,
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
                  Text(
                    S.of(context).footerScale,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  if (machineService.scaleService.state == ScaleState.connected)
                    StreamBuilder<Object>(
                        stream: machineService.scaleService.streamBattery,
                        builder: (context, snapshot) {
                          var bat = snapshot.hasData ? (snapshot.data as int) / 100.0 : 0.0;
                          return LinearProgressIndicator(
                            backgroundColor: Colors.black38,
                            color: bat < 40 ? Theme.of(context).progressIndicatorTheme.linearTrackColor : Colors.red,
                            value: bat,
                            semanticsLabel: S.of(context).footerBattery,
                          );
                        }),
                ],
              ),
            );
          }),
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
            // style: theme.TextStyles.headingFooter,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            label,
            // style: theme.TextStyles.subHeadingFooter,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
