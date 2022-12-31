import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;

import '../../devices/decent_de1.dart';
import '../../model/services/ble/machine_service.dart';
import '../../service_locator.dart';

class StartStopButton extends StatefulWidget {
  const StartStopButton({
    Key? key,
  }) : super(key: key);

  @override
  State<StartStopButton> createState() => _StartStopButtonState();
}

class _StartStopButtonState extends State<StartStopButton> {
  late EspressoMachineService machineService;

  _StartStopButtonState();

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

    var mainState = machineService.state.coffeeState.name.toUpperCase();
    var subState = machineService.state.subState;
    var title = isBusy ? "Stop" : "Start";
    mode = isBusy ? Colors.red : Colors.green;

    switch (subState) {
      case "no_state":
        subState = "...";
        break;
      case "heat_water_tank":
        subState = "Heating";
        title = "Wait";
        mode = Colors.orange;
        break;
    }
    switch (machineService.state.coffeeState) {
      case EspressoMachineState.sleep:
        mode = Colors.blue;
        title = "Switch on";
        break;

      case EspressoMachineState.idle:
        break;
      case EspressoMachineState.espresso:
        break;
      case EspressoMachineState.water:
        break;
      case EspressoMachineState.steam:
        break;
      case EspressoMachineState.disconnected:
        mode = Colors.orange;
        title = "Reconnect";
        break;
      case EspressoMachineState.connecting:
        break;
      case EspressoMachineState.refill:
        break;
      case EspressoMachineState.flush:
        break;
    }
    return Column(
      children: [
        SizedBox(
          height: 180,
          width: 180,
          child: ElevatedButton(
            onPressed: () {
              if (machineService.state.coffeeState == EspressoMachineState.sleep) {
                machineService.de1?.switchOn();
              } else {
                if (!isBusy) {
                  machineService.de1?.requestState(De1StateEnum.Espresso);
                } else {
                  machineService.de1?.setIdleState();
                }
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: theme.TextStyles.tabStatusbutton,
                ),
                Text(
                  mainState,
                  style: theme.TextStyles.tabPrimary,
                ),
                Text(
                  subState,
                  style: theme.TextStyles.tabPrimary,
                ),
              ],
            ),
            style: ButtonStyle(
              shape: MaterialStateProperty.all(CircleBorder(side: BorderSide(width: 10, color: mode))),
              padding: MaterialStateProperty.all(EdgeInsets.all(10)),
              // backgroundColor: MaterialStateProperty.all(theme.Colors.backgroundColor), // <-- Button color
              foregroundColor: MaterialStateProperty.all(Colors.black),
              overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
                if (states.contains(MaterialState.pressed)) return Colors.red; // <-- Splash color
              }),
            ),
          ),
        ),
        // IconButton(
        //     iconSize: 150,
        //     isSelected: isSelected,
        //     icon: const Icon(Icons.play_circle),
        //     selectedIcon: const Icon(Icons.stop),
        //     tooltip: 'Water',
        //     onPressed: () {
        //       if (!isSelected) {
        //         widget.machineService.de1?.requestState(De1StateEnum.Espresso);
        //       } else {
        //         widget.machineService.de1?.setIdleState();
        //       }
        //     }),
        // Text(
        //   isSelected ? "Stop" : "Start",
        //   style: theme.TextStyles.tabSecondary,
        // ),
      ],
    );
  }
}
