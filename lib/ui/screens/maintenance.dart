import 'dart:async';

import 'package:despresso/devices/decent_de1.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/ui/widgets/start_stop_button.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:logging/logging.dart';

import '../../service_locator.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({Key? key}) : super(key: key);

  @override
  MaintenanceScreenState createState() => MaintenanceScreenState();
}

class MaintenanceScreenState extends State<MaintenanceScreen> {
  final log = Logger('MaintenanceScreen');

  late SettingsService settingsService;
  late EspressoMachineService machineService;

  @override
  initState() {
    super.initState();
    settingsService = getIt<SettingsService>();
    machineService = getIt<EspressoMachineService>();

    settingsService.addListener(settingsServiceListener);

    machineService.addListener(settingsServiceListener);

    // _streamRefresh = machineService.streamState;
  }

  @override
  void dispose() {
    super.dispose();

    settingsService.notifyDelayed();
    settingsService.removeListener(settingsServiceListener);
    machineService.removeListener(settingsServiceListener);

    log.info('Disposed settingspage');
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      title: "Maintenance",
      children: [
        SettingsGroup(
          title: "de1 Machine Care",
          children: [
            SimpleSettingsTile(
              title: 'Descale de1',
              leading: const Icon(Icons.build),
              child: SettingsScreen(
                title: 'Descaling',
                children: const [
                  DescaleWidget(),
                ],
              ),
            ),
            SimpleSettingsTile(
              title: 'Clean Grouphead of de1',
              leading: const Icon(Icons.build),
              child: SettingsScreen(
                title: 'Clean',
                children: const [
                  CleanWidget(),
                ],
              ),
            ),
            SimpleSettingsTile(
              title: 'Remove water for transport',
              leading: const Icon(Icons.build),
              child: SettingsScreen(
                title: 'Transport preparation',
                children: const [
                  TransportWidget(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void settingsServiceListener() {
    setState(() {});
    updateView();
    // handleAnimationState(machineService.state.coffeeState);
  }

  void updateView() {}
}

class DescaleWidget extends StatefulWidget {
  const DescaleWidget({
    super.key,
  });

  @override
  State<DescaleWidget> createState() => _DescaleWidgetState();
}

class _DescaleWidgetState extends State<DescaleWidget> with TickerProviderStateMixin {
  late Stream<int> _streamRefresh;
  Logger log = Logger("Descale");
  late AnimationController _animController;

  late StreamController<int> _controllerRefresh;

  late EspressoMachineService machineService;

  @override
  initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    machineService.addListener(settingsServiceListener);

    _controllerRefresh = StreamController<int>();
    _streamRefresh = _controllerRefresh.stream.asBroadcastStream();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 12, seconds: 5),
    )..addListener(() {
        _controllerRefresh.add(0);
        // setState(() {});
      });

    _animController.stop();
  }

  @override
  void dispose() {
    super.dispose();
    machineService.removeListener(settingsServiceListener);
    _animController.dispose();
    _controllerRefresh.close();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object>(
        stream: _streamRefresh,
        builder: (context, snapshot) {
          return SettingsContainer(
            leftPadding: 16,
            children: [
              if (!_animController.isAnimating)
                Text(
                  "How to prepare:",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              if (!_animController.isAnimating)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text("Remove the trip tray and it's cover.", style: Theme.of(context).textTheme.labelLarge),
                      Text("In the water tank, mix 1.5 liter hot water with 300g citric acid powder.",
                          style: Theme.of(context).textTheme.labelLarge),
                      Text("Let it resolve fully.", style: Theme.of(context).textTheme.labelLarge),
                      Text("Put in a blind basket in the portafilter and lower the steam wand.",
                          style: Theme.of(context).textTheme.labelLarge),
                      Text("Push back the water tank. ", style: Theme.of(context).textTheme.labelLarge),
                      Text("Place the drip tray back without its cover.",
                          style: Theme.of(context).textTheme.labelLarge),
                      Text("You can repeat this procedure a few times if needed.",
                          style: Theme.of(context).textTheme.labelSmall),
                      Text(
                          "Make sure to flush the machine and steam until no acid is detectable. You could run the descale process without acid at least one time.",
                          style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
              if (_animController.isAnimating)
                SizedBox(
                  height: 100,
                  child: Text(
                    "Descale in progress. Please wait.",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              const SizedBox(
                width: 300,
                height: 300,
                child: StartStopButton(requestedState: De1StateEnum.descale),
              ),
              if (_animController.isAnimating)
                LinearProgressIndicator(
                  value: _animController.value,
                )
            ],
          );
        });
  }

  void settingsServiceListener() {
    setState(() {});

    handleAnimationState(machineService.state.coffeeState);
  }

  void handleAnimationState(EspressoMachineState state) {
    if (state == EspressoMachineState.descale) {
      if (_animController.isAnimating == false) {
        log.info("Trigger start of animation");
        _animController.forward(from: 0.0);
      }
    }
    if (state == EspressoMachineState.idle) {
      _animController.stop();
    }
  }
}

class CleanWidget extends StatefulWidget {
  const CleanWidget({
    super.key,
  });

  @override
  State<CleanWidget> createState() => _CleanWidgetState();
}

class _CleanWidgetState extends State<CleanWidget> with TickerProviderStateMixin {
  late Stream<int> _streamRefresh;
  Logger log = Logger("Clean");
  late AnimationController _animController;

  late StreamController<int> _controllerRefresh;

  late EspressoMachineService machineService;

  @override
  initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    machineService.addListener(settingsServiceListener);

    _controllerRefresh = StreamController<int>();
    _streamRefresh = _controllerRefresh.stream.asBroadcastStream();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 2, seconds: 45),
    )..addListener(() {
        _controllerRefresh.add(0);
        // setState(() {});
      });
    _animController.stop();
  }

  @override
  void dispose() {
    super.dispose();
    machineService.removeListener(settingsServiceListener);
    _animController.dispose();
    _controllerRefresh.close();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object>(
        stream: _streamRefresh,
        builder: (context, snapshot) {
          return SettingsContainer(
            leftPadding: 16,
            children: [
              if (!_animController.isAnimating)
                Text(
                  "How to prepare:",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              if (!_animController.isAnimating)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text("Remove the trip tray and it's cover. Make it empty",
                          style: Theme.of(context).textTheme.labelLarge),
                      Text("In the water tank, make sure enough water is inside.",
                          style: Theme.of(context).textTheme.labelLarge),
                      Text("Put in a blind basket in the portafilter and lower the steam wand.",
                          style: Theme.of(context).textTheme.labelLarge),
                      Text("Add some Detergent into the portafilter. Put the portafilter back on the machine.",
                          style: Theme.of(context).textTheme.labelLarge),
                      Text("Place the drip tray back without its cover.",
                          style: Theme.of(context).textTheme.labelLarge),
                      Text("You can repeat this procedure a few times if needed.",
                          style: Theme.of(context).textTheme.labelSmall),
                      Text("Make sure to flush the machine and steam until no acid is detectable.",
                          style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
              if (_animController.isAnimating)
                SizedBox(
                  height: 100,
                  child: Text(
                    "Cleaning in progress. Please wait.",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              const SizedBox(
                width: 300,
                height: 300,
                child: StartStopButton(requestedState: De1StateEnum.clean),
              ),
              if (_animController.isAnimating)
                LinearProgressIndicator(
                  value: _animController.value,
                )
            ],
          );
        });
  }

  void settingsServiceListener() {
    setState(() {});

    handleAnimationState(machineService.state.coffeeState);
  }

  void handleAnimationState(EspressoMachineState state) {
    if (state == EspressoMachineState.clean) {
      if (_animController.isAnimating == false) {
        log.info("Trigger start of animation");
        _animController.forward(from: 0.0);
      }
    }
    if (state == EspressoMachineState.idle) {
      _animController.stop();
    }
  }
}

class TransportWidget extends StatefulWidget {
  const TransportWidget({
    super.key,
  });

  @override
  State<TransportWidget> createState() => _TransportWidgetState();
}

class _TransportWidgetState extends State<TransportWidget> with TickerProviderStateMixin {
  late Stream<int> _streamRefresh;
  Logger log = Logger("Clean");
  late AnimationController _animController;

  late StreamController<int> _controllerRefresh;

  late EspressoMachineService machineService;

  @override
  initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    machineService.addListener(settingsServiceListener);

    _controllerRefresh = StreamController<int>();
    _streamRefresh = _controllerRefresh.stream.asBroadcastStream();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 2, seconds: 45),
    )..addListener(() {
        _controllerRefresh.add(0);
        // setState(() {});
      });
    _animController.stop();
  }

  @override
  void dispose() {
    super.dispose();
    machineService.removeListener(settingsServiceListener);
    _animController.dispose();
    _controllerRefresh.close();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object>(
        stream: _streamRefresh,
        builder: (context, snapshot) {
          return SettingsContainer(
            leftPadding: 16,
            children: [
              if (!_animController.isAnimating)
                Text(
                  "How to prepare:",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              if (!_animController.isAnimating)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text("Remove the trip tray and it's cover. Make it empty.",
                          style: Theme.of(context).textTheme.labelLarge),
                      Text("Move the water tank halfway forward under the portafilter/water screen.",
                          style: Theme.of(context).textTheme.labelLarge),
                      Text("Remove portafilter.", style: Theme.of(context).textTheme.labelLarge),
                      Text("Press Start if you are ready to go.", style: Theme.of(context).textTheme.labelLarge),
                    ],
                  ),
                ),
              if (_animController.isAnimating)
                SizedBox(
                  height: 100,
                  child: Text(
                    "Removing water and preparing for transport in progress. Please wait.",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              const SizedBox(
                width: 300,
                height: 300,
                child: StartStopButton(requestedState: De1StateEnum.airPurge),
              ),
              if (_animController.isAnimating)
                LinearProgressIndicator(
                  value: _animController.value,
                )
            ],
          );
        });
  }

  void settingsServiceListener() {
    setState(() {});

    handleAnimationState(machineService.state.coffeeState);
  }

  void handleAnimationState(EspressoMachineState state) {
    if (state == EspressoMachineState.airPurge) {
      if (_animController.isAnimating == false) {
        _animController.forward(from: 0.0);
      }
    }
    if (state == EspressoMachineState.idle) {
      _animController.stop();
    }
  }
}
