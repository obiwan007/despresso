import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:logging/logging.dart';

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
  final log = Logger('_StartStopButtonState');

  late EspressoMachineService machineService;

  _StartStopButtonState();

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    // machineService.addListener(updateMachine);

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
    // profileService.removeListener(updateProfile);
    // coffeeSelectionService.removeListener(updateCoffeeSelection);
    // log.info('Disposed espresso');
  }

  updateMachine() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var mode = Colors.green;

    return StreamBuilder<EspressoMachineFullState>(
        stream: machineService.streamState,
        initialData: machineService.currentFullState,
        builder: (context, snapshot) {
          var isBusy = snapshot.data?.state == EspressoMachineState.espresso ||
              snapshot.data?.state == EspressoMachineState.water ||
              snapshot.data?.state == EspressoMachineState.steam ||
              snapshot.data?.state == EspressoMachineState.flush;

          var mainState = snapshot.data?.state.name.toUpperCase() ?? "disconnected";
          var subState = snapshot.data?.subState ?? '';
          var title = isBusy ? "Stop" : "Start";
          mode = isBusy ? Colors.red : Colors.green;

          switch (subState) {
            case "no_state":
              subState = "";
              break;
            case "idle":
              subState = "heated up";
              break;
            case "heat_water_tank":
              subState = "Heating";
              title = "Wait";
              mode = Colors.orange;
              break;
            case "heat_water_heater":
              subState = "Heating";
              title = "Wait";
              mode = Colors.orange;
              break;
          }
          switch (snapshot.data?.state) {
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
            case null:
              break;
          }

          return Column(
            children: [
              SizedBox(
                height: 180,
                width: 180,
                child: ElevatedButton(
                  onPressed: () {
                    if (snapshot.data?.state == EspressoMachineState.sleep) {
                      machineService.de1?.switchOn();
                    } else {
                      if (!isBusy) {
                        log.info("Start");
                        machineService.de1?.requestState(De1StateEnum.espresso);
                      } else {
                        machineService.de1?.setIdleState();
                      }
                    }
                  },
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all(CircleBorder(side: BorderSide(width: 10, color: mode))),
                    padding: MaterialStateProperty.all(const EdgeInsets.all(10)),
                    // backgroundColor: MaterialStateProperty.all(theme.Colors.backgroundColor), // <-- Button color
                    foregroundColor: MaterialStateProperty.all(Colors.black),
                    overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(MaterialState.pressed)) return Colors.red;
                      return null; // <-- Splash color
                    }),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        mainState,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        subState,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
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
        });
  }
}
