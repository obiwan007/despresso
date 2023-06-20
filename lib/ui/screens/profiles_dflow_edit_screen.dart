import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/ui/widgets/editable_text.dart';
import 'package:despresso/ui/widgets/profile_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinbox/material.dart';
import 'package:logging/logging.dart';
import '../../model/services/ble/machine_service.dart';

class DFlowEditScreen extends StatefulWidget {
  final De1ShotProfile profile;

  const DFlowEditScreen(this.profile, {Key? key}) : super(key: key);

  @override
  DFlowEditScreenState createState() {
    return DFlowEditScreenState();
  }
}

class DFlowEditScreenState extends State<DFlowEditScreen> with SingleTickerProviderStateMixin {
  final log = Logger('DFlowEditScreenState');

  late ProfileService profileService;

  late EspressoMachineService machineService;

  late De1ShotProfile _profile;

  De1ShotFrameClass? infusion;
  // De1ShotFrameClass? forcedRise;
  De1ShotFrameClass? pouring;

  De1ShotFrameClass? forcedRise;

  late TabController _tabController;
  late TextEditingController helpDialogController;
  List<String> helpTexts = [];

  List<MaterialColor> phaseColors = [Colors.blue, Colors.purple, Colors.green, Colors.brown];

  DFlowEditScreenState() {
    _profile = widget.profile;
  }

  @override
  void initState() {
    super.initState();
    helpDialogController = TextEditingController();

    log.info('Init State ${_profile.shotHeader.title}');

    _tabController = TabController(length: 11, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    super.dispose();

    // machineService.removeListener(profileListener);
    log.info('Disposed d-flow profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: IconEditableText(
          initialValue: "${_profile.shotHeader.title} (D-Flow Editor)",
          onChanged: (value) {
            setState(() {
              _profile.shotHeader.title = value;
            });
          },
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () {
              setState(() {
                profileService.save(_profile);
                Navigator.pop(context);
              });
            },
          ),
        ],
      ),
      body: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: IntrinsicHeight(
                child: ProfileGraphWidget(selectedProfile: _profile),
              ),
            ),
            Expanded(
              child: IntrinsicHeight(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SizedBox(height: 195, child: createTabBar()),
                    // ...handleChanges (preInfusion)
                    // ...handleChanges(preInfusion!),
                    // ...handleChanges(riseAndHold!),
                    // ...handleChanges(decline!),
                    // changeValue(
                    //     unit: "ml",
                    //     title: "Max. Volume",
                    //     min: 0,
                    //     max: 100,
                    //     De1ShotFrameClass(),
                    //     _profile.shotHeader.targetVolume, (value) {
                    //   var v = (value * 10).round() / 10;
                    //   setState(() => _profile.shotHeader.targetVolume = v);
                    // }),
                    // changeValue(
                    //     unit: "g",
                    //     title: "Max. Weight",
                    //     min: 0,
                    //     max: 100,
                    //     De1ShotFrameClass(),
                    //     _profile.shotHeader.targetWeight, (value) {
                    //   var v = (value * 10).round() / 10;
                    //   setState(() => _profile.shotHeader.targetWeight = v);
                    // }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  createTabBar() {
    var tb = Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: ColoredBox(
                color: phaseColors[0],
                child: const SizedBox(
                  height: 20,
                  width: 100,
                  child: Expanded(
                    flex: 1,
                    child: Center(child: Text("Dose")),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: ColoredBox(
                color: phaseColors[1],
                child: const SizedBox(
                  height: 20,
                  width: 100,
                  child: Expanded(
                    flex: 5,
                    child: Center(
                        child: Text(
                      "Infuse",
                    )),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: ColoredBox(
                color: phaseColors[2],
                child: const SizedBox(
                  height: 20,
                  width: 100,
                  child: Expanded(
                    flex: 5,
                    child: Center(
                      child: Text("Pour \t 1:2"), // update ratio if input or output is changed
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        TabBar(
          controller: _tabController,
          tabs: <Widget>[
            // ...createTabs(preInfusion, color: phaseColors[0]),
            // ...createTabs(riseAndHold, color: phaseColors[1]),
            // ...createTabs(decline, color: phaseColors[2]),
            Tab(
              height: 210,
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Text("weight",
                        style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                  ),
                  SpinBox(
                    min: 1,
                    max: 200,
                    value: _profile.shotHeader.targetWeight,
                    decimals: 1,
                    step: 0.1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: const TextStyle(fontSize: 15),
                    incrementIcon: const Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: const InputDecoration(labelText: 'g'),
                    // onChanged: (value) => null,
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Text("temperature",
                        style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                  ),
                  SpinBox(
                    min: 1,
                    max: 200,
                    value: _profile.shotHeader.targetWeight,
                    decimals: 1,
                    step: 0.5,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: const TextStyle(fontSize: 15),
                    incrementIcon: const Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: const InputDecoration(labelText: '°C'),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Text("pressure",
                        style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                  ),
                  SpinBox(
                    min: 1,
                    max: 200,
                    value: _profile.shotHeader.targetWeight,
                    decimals: 1,
                    step: 0.1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: const TextStyle(fontSize: 15),
                    incrementIcon: const Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: const InputDecoration(labelText: 'bar'),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Text("time",
                        style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                  ),
                  SpinBox(
                    min: 1,
                    max: 200,
                    value: _profile.shotHeader.targetWeight,
                    decimals: 0,
                    step: 1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: const TextStyle(fontSize: 15),
                    incrementIcon: const Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: const InputDecoration(labelText: 's'),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Text("volume",
                        style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                  ),
                  SpinBox(
                    min: 1,
                    max: 200,
                    value: _profile.shotHeader.targetWeight,
                    decimals: 1,
                    step: 0.1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: const TextStyle(fontSize: 15),
                    incrementIcon: const Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: const InputDecoration(labelText: 'ml'),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Text("weight",
                        style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                  ),
                  SpinBox(
                    min: 1,
                    max: 200,
                    value: _profile.shotHeader.targetWeight,
                    decimals: 1,
                    step: 0.1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: const TextStyle(fontSize: 15),
                    incrementIcon: const Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: const InputDecoration(labelText: 'g'),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Text("temperature",
                        style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                  ),
                  SpinBox(
                    min: 1,
                    max: 200,
                    value: _profile.shotHeader.targetWeight,
                    decimals: 1,
                    step: 0.5,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: const TextStyle(fontSize: 15),
                    incrementIcon: const Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: const InputDecoration(labelText: '°C'),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Text("flow",
                        style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                  ),
                  SpinBox(
                    min: 1,
                    max: 200,
                    value: _profile.shotHeader.targetWeight,
                    decimals: 1,
                    step: 0.1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: const TextStyle(fontSize: 15),
                    incrementIcon: const Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: const InputDecoration(labelText: 'ml/s'),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      showHelp("pour_stop");
                    },
                    child: SizedBox(
                      height: 30,
                      child: Text("pressure",
                          style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                    ),
                  ),
                  SpinBox(
                    min: 1,
                    max: 200,
                    value: _profile.shotHeader.targetWeight,
                    decimals: 1,
                    step: 0.1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: const TextStyle(fontSize: 15),
                    incrementIcon: const Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: const InputDecoration(labelText: 'bar'),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Text("volume",
                        style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                  ),
                  SpinBox(
                    min: 1,
                    max: 200,
                    value: _profile.shotHeader.targetWeight,
                    decimals: 1,
                    step: 0.1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: const TextStyle(fontSize: 15),
                    incrementIcon: const Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: const InputDecoration(labelText: 'ml'),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Text("weight",
                        style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                  ),
                  SpinBox(
                    min: 1,
                    max: 200,
                    value: _profile.shotHeader.targetWeight,
                    decimals: 1,
                    step: 0.1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: const TextStyle(fontSize: 15),
                    incrementIcon: const Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: const InputDecoration(labelText: 'g'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
    return tb;
  }

  Future<String?> showHelp(inputName) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Information'),
          content: const Text(
              "The extraction ratio   (Dose : Extraction)   is shown above the setting dial. \n Increasing the extraction ratio will shift the taste from \n Sour  >  Sweet  >  Bitter \n The ideal extraction ratio can vary between beans, water alkalinity, puck prep methods and how evenly the pack is extracted. \n You should adjusted this setting for your taste."),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                // Navigator.of(context).pop(helpDialogController.text);
                helpDialogController.clear();
              },
            ),
          ],
        );
      },
    );
  }

  loadDefaultProfile() {}
}
