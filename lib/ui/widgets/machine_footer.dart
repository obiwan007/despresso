import 'dart:developer';

import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;

import '../../devices/decent_de1.dart';
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

  _MachineFooterState();

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    machineService.addListener(updateMachine);

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
    machineService.removeListener(updateMachine);
    // profileService.removeListener(updateProfile);
    // coffeeSelectionService.removeListener(updateCoffeeSelection);
    // log('Disposed espresso');
  }

  updateMachine() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var mode = Colors.green;
    var isBusy = machineService.state.coffeeState == EspressoMachineState.espresso ||
        machineService.state.coffeeState == EspressoMachineState.water ||
        machineService.state.coffeeState == EspressoMachineState.steam ||
        machineService.state.coffeeState == EspressoMachineState.flush;

    mode = isBusy ? Colors.red : Colors.green;

    // switch (subState) {
    //   case "no_state":
    //     subState = "...";
    //     break;
    //   case "heat_water_tank":
    //     subState = "Heating";
    //     title = "Wait";
    //     mode = Colors.orange;
    //     break;
    // }
    // switch (machineService.state.coffeeState) {
    //   case EspressoMachineState.sleep:
    //     mode = Colors.blue;
    //     title = "on";
    //     break;

    //   case EspressoMachineState.idle:
    //     break;
    //   case EspressoMachineState.espresso:
    //     break;
    //   case EspressoMachineState.water:
    //     break;
    //   case EspressoMachineState.steam:
    //     break;
    //   case EspressoMachineState.disconnected:
    //     mode = Colors.orange;
    //     title = "Reconnect";
    //     break;
    //   case EspressoMachineState.connecting:
    //     break;
    //   case EspressoMachineState.refill:
    //     break;
    //   case EspressoMachineState.flush:
    //     break;
    // }
    var isOn = machineService.state.coffeeState != EspressoMachineState.sleep &&
        machineService.state.coffeeState != EspressoMachineState.disconnected;
    var shot = machineService.state.shot ?? ShotState(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "");
    return Container(
      height: 70,
      color: Colors.white10,
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "${machineService.state.water?.getLevelPercent()}%",
                  style: theme.TextStyles.headingFooter,
                ),
                const Text(
                  'Water',
                  style: theme.TextStyles.subHeadingFooter,
                ),
              ],
            ),
          ),
          Spacer(),
          Container(color: Colors.black38, child: _scaleBuilder()),
          Spacer(),
          SizedBox(
            width: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "${shot.headTemp.toStringAsFixed(1)} °C",
                  style: theme.TextStyles.headingFooter,
                ),
                const Text(
                  'Group',
                  style: theme.TextStyles.subHeadingFooter,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "${shot.mixTemp.toStringAsFixed(1)} °C",
                  style: theme.TextStyles.headingFooter,
                ),
                const Text(
                  'Mix',
                  style: theme.TextStyles.subHeadingFooter,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "${shot.groupPressure.toStringAsFixed(1)} bar",
                  style: theme.TextStyles.headingFooter,
                ),
                const Text(
                  'Pressure',
                  style: theme.TextStyles.subHeadingFooter,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "${shot.groupFlow.toStringAsFixed(1)} ml/s",
                  style: theme.TextStyles.headingFooter,
                ),
                const Text(
                  'Flow',
                  style: theme.TextStyles.subHeadingFooter,
                ),
              ],
            ),
          ),
          Spacer(),
          Row(
            children: [
              Text(isOn ? 'On' : 'Off'),
              Switch(
                value: isOn, //set true to enable switch by default
                onChanged: (bool value) {
                  value ? machineService.de1!.switchOn() : machineService.de1!.switchOff();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  SizedBox _scaleBuilder() {
    return SizedBox(
      width: 310,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    machineService.scaleService.state == ScaleState.connected
                        ? machineService.scaleService.tare()
                        : machineService.scaleService.connect();
                    ;
                  },
                  child: Text(
                    machineService.scaleService.state == ScaleState.connected ? "  Tare  " : "Connect",
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Text(
                    textAlign: TextAlign.right,
                    machineService.scaleService.state == ScaleState.connected
                        ? "${machineService.scaleService.weight.toStringAsFixed(1)} g"
                        : machineService.scaleService.state.name,
                    style: machineService.scaleService.state == ScaleState.connected
                        ? theme.TextStyles.headingFooter
                        : theme.TextStyles.headingFooterSmall,
                  ),
                ),
                if (machineService.scaleService.state == ScaleState.connected)
                  ElevatedButton(
                    onPressed: () => {},
                    child: const Text("To Shot"),
                  ),
              ],
            ),
          ),
          const Text(
            'Scale',
            style: theme.TextStyles.subHeadingFooter,
          ),
        ],
      ),
    );
  }
}
