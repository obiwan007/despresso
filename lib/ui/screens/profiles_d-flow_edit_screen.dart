import 'dart:ffi';

import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/ui/widgets/editable_text.dart';
import 'package:despresso/ui/widgets/profile_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinbox/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:flutter_spinbox/material.dart';
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import '../../model/services/ble/machine_service.dart';
import '../../service_locator.dart';

class DFlowEditScreen extends StatefulWidget {
  De1ShotProfile profile;

  DFlowEditScreen(this.profile, {Key? key}) : super(key: key);

  @override
  DFlowEditScreenState createState() {
    return DFlowEditScreenState(profile);
  }
}

class DFlowEditScreenState extends State<DFlowEditScreen> with SingleTickerProviderStateMixin {
  final log = Logger('DFlowEditScreenState');

  late ProfileService profileService;

  late EspressoMachineService machineService;

  final De1ShotProfile _profile;

  De1ShotFrameClass? infusion;
  // De1ShotFrameClass? forcedRise;
  De1ShotFrameClass? pouring;

  De1ShotFrameClass? forcedRise;

  late TabController _tabController;
  late TextEditingController helpDialogController;
  static Map helpTexts = {
    "dose":
        "Dose - means the weight of the beans or the weight of the coffee puck. \n \n The dose weight is used in calcultating the extraction ratio.\nSee pour stop setting for information of extraction ratio \n \n Being consistant with your grind, dose and puck prep will greatly help you repeatedly extract great espresso.",
    "infuseTemp":
        "Infuse temperature allows you to emulate various machine where the group temperature may start cooler than the water being added. \n See pour temperature for information on how temperature effects extraction and taste.",
    "infusePressure":
        "A higher infusion pressure will increase puck resistance \n \n The default is 3 bar, the same as used by LRv2, LRv3 profiles and others, it is tyipcally the upper level used by machines that use preinfusion. \n\n Some manual lever machines like a LA Pavoni have a boiler pressure of 0.8 to 1 bar, infusing is done by raising, fill the group with water at boiler pressure. to emulater this you would set a 1 bar infuse pressure.\n \n Some machines use pressures anywhere in between.\n \n Other machines may not hold an infusion presure at all, like a common E61 pump machines where it apply water straight to extraction pressure, typically 8 or 9 bar.",
    "infuseStop":
        "Infuse will move on to the pour stage when any one of these settings are reached. \n For best consistancy I recommend using weight. In cases where a scale is not available, you could use volume, however for those situations and where you you may want to end infuse before first drops in the cup, using time is likely the better option.\n \nA longer infusion increases body, but it also reduces puck resistance during the pour. \n Which means we would need to grind finer to maintain the same pour pressure/flow rates.\nFiner grinds also reduce body and can increase bitterness, so the aim is to find a ballence for your prefered taste. \n A longer infusion also means we have a higher pecentage of the shot being at 3 bar. \n 0.2g to 4g is a good starting range to experiment with.",
    "pourTemp":
        "Higher temperature helps extract the soluble compounds, however it also increases harsher tasts that may exist too. \n \n Higher temperatures usually results in lower body with more pronounced acidity, wine, fruity, vegetal flavours. Lower temperatures often work better with slower extraction rates.",
    "pourLimits":
        "D-Flow uses flow with pressure limits, allows for a greater grind range, giving better control and resulting in less wasted shots. \n \n Increasing pressure will shift taste from wine like to a more syrupy texture, it also shifts tastes from clear delicate flavours to more muddled flavours. \n \n Faster flows can increase clarity in ligher roasts and may help reduce channeling. Slower flow can help increase intensity and body in darker than light roasts.",
    "pourStop":
        "The extraction ratio   (Dose : Extraction)   is shown above the setting dial. \n Increasing the extraction ratio will shift the taste from \n Sour  >  Sweet  >  Bitter \n The ideal extraction ratio can vary between beans, water alkalinity, puck prep methods and how evenly the pack is extracted. \n You should adjusted this setting for your taste.",
  };

  List<MaterialColor> phaseColors = [Colors.blue, Colors.purple, Colors.green, Colors.brown];

  DFlowEditScreenState(this._profile);

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
    double grinderDoseWeight = 18;
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
    double grinderDoseWeight = 18.0;
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
                      child: Text("Pour \t 1:2"),
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
                  new GestureDetector(
                    onTap: () {
                      showHelp("dose");
                    },
                    child: SizedBox(
                      height: 30,
                      child: Text("weight",
                          style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                    ),
                  ),
                  SpinBox(
                    min: 10.0,
                    max: 30.0,
                    value: grinderDoseWeight,
                    decimals: 1,
                    step: 0.1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: TextStyle(fontSize: 15),
                    incrementIcon: Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: InputDecoration(labelText: 'g'),
                    onChanged: (value) => print(value),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  new GestureDetector(
                    onTap: () {
                      showHelp("infuseTemp");
                    },
                    child: SizedBox(
                      height: 30,
                      child: Text("temperature",
                          style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                    ),
                  ),
                  SpinBox(
                    min: 80,
                    max: 100,
                    value: _profile.shotFrames[0].temp,
                    decimals: 0,
                    step: 1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: TextStyle(fontSize: 15),
                    incrementIcon: Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: InputDecoration(labelText: '°C'),
                    onChanged: (value) => print(value),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  new GestureDetector(
                    onTap: () {
                      showHelp("infusePressure");
                    },
                    child: SizedBox(
                      height: 30,
                      child: Text("pressure",
                          style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                    ),
                  ),
                  SpinBox(
                    min: 0.1,
                    max: 10,
                    value: 0,
                    decimals: 1,
                    step: 0.1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: TextStyle(fontSize: 15),
                    incrementIcon: Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: InputDecoration(labelText: 'bar'),
                    onChanged: (value) => print(value),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  new GestureDetector(
                    onTap: () {
                      showHelp("infuseStop");
                    },
                    child: SizedBox(
                      height: 30,
                      child: Text("time",
                          style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                    ),
                  ),
                  SpinBox(
                    min: 0,
                    max: 60,
                    value: _profile.shotFrames[1].frameLen,
                    decimals: 0,
                    step: 1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: TextStyle(fontSize: 15),
                    incrementIcon: Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: InputDecoration(labelText: 's'),
                    onChanged: (value) => print(value),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  new GestureDetector(
                    onTap: () {
                      showHelp("infuseStop");
                    },
                    child: SizedBox(
                      height: 30,
                      child: Text("volume",
                          style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                    ),
                  ),
                  SpinBox(
                    min: 1,
                    max: 200,
                    value: _profile.shotFrames[0].maxVol,
                    decimals: 0,
                    step: 1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: TextStyle(fontSize: 15),
                    incrementIcon: Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: InputDecoration(labelText: 'ml'),
                    onChanged: (value) => print(value),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  new GestureDetector(
                    onTap: () {
                      showHelp("infuseStop");
                    },
                    child: SizedBox(
                      height: 30,
                      child: Text("weight",
                          style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                    ),
                  ),
                  SpinBox(
                    min: 1,
                    max: 200,
                    value: 0,
                    decimals: 1,
                    step: 0.1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: TextStyle(fontSize: 15),
                    incrementIcon: Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: InputDecoration(labelText: 'g'),
                    onChanged: (value) => print(value),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  new GestureDetector(
                    onTap: () {
                      showHelp("pourTemp");
                    },
                    child: SizedBox(
                      height: 30,
                      child: Text("temperature",
                          style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                    ),
                  ),
                  SpinBox(
                    min: 80,
                    max: 100,
                    value: _profile.shotFrames[2].temp,
                    decimals: 0,
                    step: 1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: TextStyle(fontSize: 15),
                    incrementIcon: Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: InputDecoration(labelText: '°C'),
                    onChanged: (value) => print(value),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  new GestureDetector(
                    onTap: () {
                      showHelp("pourLimits");
                    },
                    child: SizedBox(
                      height: 30,
                      child: Text("flow",
                          style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                    ),
                  ),
                  SpinBox(
                    min: 0.1,
                    max: 10,
                    value: 0,
                    decimals: 1,
                    step: 0.1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: TextStyle(fontSize: 15),
                    incrementIcon: Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: InputDecoration(labelText: 'ml/s'),
                    onChanged: (value) => print(value),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  new GestureDetector(
                    onTap: () {
                      showHelp("pourLimits");
                    },
                    child: SizedBox(
                      height: 30,
                      child: Text("pressure",
                          style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                    ),
                  ),
                  SpinBox(
                    min: 0,
                    max: 12,
                    value: _profile.shotFrames[1].setVal,
                    decimals: 1,
                    step: 0.1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: TextStyle(fontSize: 15),
                    incrementIcon: Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: InputDecoration(labelText: 'bar'),
                    onChanged: (value) => print(value),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  new GestureDetector(
                    onTap: () {
                      showHelp("pourStop");
                    },
                    child: SizedBox(
                      height: 30,
                      child: Text("volume",
                          style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 12)),
                    ),
                  ),
                  SpinBox(
                    min: 1,
                    max: 200,
                    value: 0,
                    decimals: 1,
                    step: 0.1,
                    spacing: 10,
                    direction: Axis.vertical,
                    textStyle: TextStyle(fontSize: 15),
                    incrementIcon: Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: InputDecoration(labelText: 'ml'),
                    onChanged: (value) => print(value),
                  ),
                ],
              ),
            ),
            Tab(
              height: 210,
              child: Column(
                children: [
                  new GestureDetector(
                    onTap: () {
                      showHelp("pourStop");
                    },
                    child: SizedBox(
                      height: 30,
                      child: Text("weight",
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
                    textStyle: TextStyle(fontSize: 15),
                    incrementIcon: Icon(Icons.keyboard_arrow_up, size: 20),
                    decrementIcon: Icon(Icons.keyboard_arrow_down, size: 20),
                    decoration: InputDecoration(labelText: 'g'),
                    onChanged: (value) => print(value),
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
          content: Text(helpTexts[inputName]),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
                helpDialogController.clear();
              },
            ),
          ],
        );
      },
    );
  }

  loadDefaultProfile() {}

  calculateRatio(grinderWeight, weightGoal) {
    return "1 : " + weightGoal / grinderWeight;
  }
}
