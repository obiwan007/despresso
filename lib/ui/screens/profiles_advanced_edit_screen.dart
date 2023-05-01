import 'dart:ffi';
import 'dart:typed_data';

import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/ui/widgets/editable_text.dart';
import 'package:despresso/ui/widgets/key_value.dart';
import 'package:despresso/ui/widgets/profile_graph.dart';
import 'package:despresso/ui/widgets/selectable_steps.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:flutter_spinbox/material.dart';
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import '../../model/services/ble/machine_service.dart';
import '../../service_locator.dart';

class AdvancedProfilesEditScreen extends StatefulWidget {
  De1ShotProfile profile;

  AdvancedProfilesEditScreen(this.profile, {Key? key}) : super(key: key);

  @override
  AdvancedProfilesEditScreenState createState() {
    return AdvancedProfilesEditScreenState(profile);
  }
}

class AdvancedProfilesEditScreenState extends State<AdvancedProfilesEditScreen> with SingleTickerProviderStateMixin {
  final log = Logger('ProfilesEditScreenState');

  late ProfileService profileService;

  late EspressoMachineService machineService;

  final De1ShotProfile _profile;

  De1ShotFrameClass? preInfusion;
  // De1ShotFrameClass? forcedRise;
  De1ShotFrameClass? riseAndHold;
  De1ShotFrameClass? decline;

  De1ShotFrameClass? forcedRise;

  late TabController _tabController;

  List<MaterialColor> phaseColors = [Colors.blue, Colors.purple, Colors.green, Colors.brown];

  List<KeyValueWidget> _steps = [];

  int _selectedStepIndex = 0;

  De1ShotFrameClass _selectedStep = De1ShotFrameClass();

  AdvancedProfilesEditScreenState(this._profile);

  @override
  void initState() {
    super.initState();

    log.info('Init State ${_profile.shotHeader.title}');
    _selectedStep = _profile.shotFrames[_selectedStepIndex];
    machineService = getIt<EspressoMachineService>();
    profileService = getIt<ProfileService>();

    profileService.addListener(profileListener);
    // _tabController = TabController(length: 5, vsync: this, initialIndex: 1);
    for (var element in _profile.shotFrames) {
      log.info("Profile: $element");
    }

    var declineObject = De1ShotFrameClass();
    declineObject.frameToWrite = _profile.shotFrames.length;
    declineObject.temp = _profile.shotFrames.first.temp;
    try {
      var pre = _profile.shotFrames.where((element) => (element.name == "preinfusion"));
      preInfusion = pre.toList().first;

      var riseW = _profile.shotFrames.where((element) => (element.name == "rise and hold" || element.name == "hold"));
      riseAndHold = riseW.isNotEmpty ? riseW.first : null;
      var forcedRiseWhere = _profile.shotFrames.where((element) => (element.name == "forced rise without limit"));
      forcedRise = forcedRiseWhere.isNotEmpty ? forcedRiseWhere.first : null;
      var declineArray = _profile.shotFrames.where((element) => (element.name == "decline")).toList();
      if (declineArray.isNotEmpty) {
        decline = declineArray.first;
      } else {
        _profile.shotFrames.add(declineObject);
        decline = declineObject;
      }
      log.info("Decline: $decline");
    } catch (e) {
      log.severe("Preparing edit failed: $e");
    }

    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    super.dispose();

    machineService.removeListener(profileListener);
    log.info('Disposed profile');
  }

  @override
  Widget build(BuildContext context) {
    // var items = profileService.profiles
    //     .map((p) => DropdownMenuItem(
    //           value: p,
    //           child: Text(p.shotHeader.title),
    //         ))
    //     .toList();

    return Scaffold(
      appBar: AppBar(
        title: IconEditableText(
          initialValue: "${_profile.shotHeader.title}",
          onChanged: (value) {
            setState(() {
              _profile.shotHeader.title = value;
            });
          },
        ),
        //Text('Profile Edit: ${_profile.shotHeader.title}'),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Save as'),
            onPressed: () {
              setState(() {
                profileService.saveAsNew(_profile);
                Navigator.pop(context);
              });
            },
          ),
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
              flex: 1,
              child: IntrinsicHeight(
                child: ProfileGraphWidget(
                  selectedProfile: _profile,
                  selectedPhase: _selectedStepIndex,
                ),
              ),
            ),
            Expanded(
                flex: 2,
                child: IntrinsicHeight(
                    child: Row(
                  children: [
                    SizedBox(
                      width: 280,
                      child: SelectableSteps(
                        profile: _profile,
                        selected: _selectedStepIndex,
                        onSelected: (p0) {
                          _selectedStepIndex = p0;
                          _selectedStep = _profile.shotFrames[p0];
                          log.info("New Step $p0");
                          setState(() {});
                        },
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          SizedBox(height: 105, child: createTabBar()),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Text("Hallo")
                                ...handleChanges(_selectedStep),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ))),
          ],
        ),
      ),
    );
  }

  createTabBar() {
    var tb = Column(
      children: [
        TabBar(
          controller: _tabController,

          // indicator: BoxDecoration(color: _tabController.index < 4 ? Colors.red : Colors.green),
          // indicator:
          //     UnderlineTabIndicator(borderSide: BorderSide(width: 5.0), insets: EdgeInsets.symmetric(horizontal: 16.0)),
          tabs: <Widget>[
            ...createTabs(_selectedStep, color: phaseColors[0]),
          ],
        ),
      ],
    );
    return tb;
  }

  createTabs(De1ShotFrameClass frame, {required MaterialColor color}) {
    var h = 30.0;
    var hTab = 95.0;
    var fontsize = 20.0;
    var style1 = TextStyle(color: color, fontWeight: FontWeight.normal, fontSize: fontsize);
    var style2 = TextStyle(fontWeight: FontWeight.normal, fontSize: fontsize);
    var style3 = TextStyle(color: color);
    bool isComparing = ((frame!.flag & De1ShotFrameClass.DoCompare) > 0);
    bool isGt = (frame!.flag & De1ShotFrameClass.DC_GT) > 0;
    bool isFlow = (frame!.flag & De1ShotFrameClass.DC_CompF) > 0;

    return [
      Tab(
        height: hTab,
        child: Column(
          children: [
            SizedBox(
              height: h,
              child: FittedBox(
                child: Text(
                  "Temp",
                  style: style2,
                ),
              ),
            ),
            Text((frame.temp.toStringAsFixed(1)), style: style2),
            const Text("°C"),
          ],
        ),
      ),
      Tab(
        height: hTab,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: h,
              child: FittedBox(
                child: Text(
                  "Goal",
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      "${(frame?.pump != "pressure" ? frame.setVal.toStringAsFixed(1) : "<" + frame.triggerVal.toStringAsFixed(1))}",
                      style: style2,
                    ),
                    const Text("ml/s"),
                  ],
                ),
                const SizedBox(
                  width: 10,
                ),
                Column(
                  children: [
                    Text(
                      "${(frame?.pump == "pressure" ? frame.setVal.toStringAsFixed(1) : "<" + frame.triggerVal.toStringAsFixed(1))}",
                      style: style2,
                    ),
                    const Text("bar"),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      Tab(
        height: hTab,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: h,
              child: FittedBox(
                child: Text(
                  "Maximum",
                  // style: style1,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "${(frame?.frameLen.toStringAsFixed(1) ?? 0)}",
                      style: style2,
                    ),
                    Text(
                      "s",
                    ),
                  ],
                ),
                SizedBox(
                  width: 10,
                ),
                if (frame.maxVol > 0)
                  Column(
                    children: [
                      Text(
                        "${(frame.maxVol.toStringAsFixed(1) ?? 0)}",
                        style: style2,
                      ),
                      Text(
                        "ml",
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
      Tab(
        height: hTab,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: h,
              child: FittedBox(
                child: Text(
                  "Move on if...",
                  // style: style1,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      isComparing
                          ? ((isFlow ? "f " : "p ") +
                              (isGt ? "> " : "< ") +
                              "${(frame?.triggerVal.toStringAsFixed(1) ?? 0)}")
                          : "goal reached",
                      style: style2,
                    ),
                    Text(
                      isComparing ? (isFlow ? "ml/s" : "bar") : "",
                    ),
                  ],
                ),
                SizedBox(
                  width: 10,
                ),
                if (frame.maxVol > 0)
                  Column(
                    children: [
                      Text(
                        "${(frame.maxVol.toStringAsFixed(1) ?? 0)}",
                        style: style2,
                      ),
                      Text(
                        "ml",
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Padding buildRiseAndHold(De1ShotFrameClass riseAndHold, De1ShotFrameClass? forcedRise) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text("Rise and hold (${riseAndHold.frameLen.round()} s)"),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 8,
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Text("Time (${riseAndHold.frameLen.round()} s)"),
                          SfSlider(
                            min: 0.0,
                            max: 100.0,
                            value: riseAndHold.frameLen,
                            interval: 20,
                            stepSize: 0.1,
                            showTicks: true,
                            showLabels: true,
                            enableTooltip: true,
                            minorTicksPerInterval: 1,
                            onChanged: (dynamic value) {
                              setState(() {
                                var v = (value * 10).round() / 10;
                                riseAndHold.frameLen = v;
                              });
                            },
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 28.0),
                        child: Column(
                          children: [
                            Text(
                                "Limit flow (${(riseAndHold.pump == "flow" ? riseAndHold.setVal : riseAndHold.triggerVal).round()} ml/s)"),
                            SfSlider(
                              min: 0.0,
                              max: 10.0,
                              value: riseAndHold.pump == "flow" ? riseAndHold.setVal : riseAndHold.triggerVal,
                              interval: 1,
                              showTicks: true,
                              showLabels: true,
                              stepSize: 0.1,
                              enableTooltip: true,
                              minorTicksPerInterval: 1,
                              onChanged: (dynamic value) {
                                riseAndHold.pump == "flow"
                                    ? riseAndHold.setVal = value
                                    : riseAndHold.triggerVal = value;
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text("Pressure (${riseAndHold.setVal.round()} bar)"),
                      SfSlider.vertical(
                        min: 0.0,
                        max: 10.0,
                        value: riseAndHold.pump == "pressure" ? riseAndHold.setVal : riseAndHold.triggerVal,
                        interval: 2,
                        stepSize: 0.1,
                        showTicks: true,
                        showLabels: true,
                        enableTooltip: true,
                        minorTicksPerInterval: 1,
                        onChanged: (dynamic value) {
                          setState(() {
                            riseAndHold.setVal = value;
                            if (forcedRise != null) {
                              forcedRise.setVal = value;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Padding buildDecline() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const Text("Decline"),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 8,
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Text("Time (${decline?.frameLen.round()} s)"),
                          SfSlider(
                            min: 0.0,
                            max: 100.0,
                            value: decline?.frameLen,
                            interval: 10,
                            stepSize: 0.1,
                            showTicks: true,
                            showLabels: true,
                            enableTooltip: true,
                            minorTicksPerInterval: 1,
                            onChanged: (dynamic value) {
                              setState(() {
                                decline!.frameLen = value;
                              });
                            },
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 28.0),
                        child: Column(
                          children: [
                            Text("Stop at weight (${_profile.shotHeader.targetWeight.round()} g)"),
                            SfSlider(
                              min: 0.0,
                              max: 100.0,
                              value: _profile.shotHeader.targetWeight,
                              interval: 20,
                              stepSize: 0.1,
                              showTicks: false,
                              showLabels: true,
                              enableTooltip: true,
                              minorTicksPerInterval: 1,
                              onChanged: (dynamic value) {
                                setState(() {
                                  _profile.shotHeader.targetWeight = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text("Pressure (${decline?.setVal.round()} bar)"),
                      SfSlider.vertical(
                        min: 0.0,
                        max: 15.0,
                        value: preInfusion!.pump == "pressure" ? preInfusion!.setVal : preInfusion!.triggerVal,
                        interval: 2,
                        stepSize: 0.1,
                        showTicks: true,
                        showLabels: true,
                        enableTooltip: true,
                        minorTicksPerInterval: 1,
                        onChanged: (dynamic value) {
                          setState(() {
                            var v = (value * 10).round() / 10;
                            if (decline!.pump == "pressure") {
                              decline!.setVal = v;
                            } else {
                              decline!.triggerVal = v;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Column createKeyValue(String key, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(key, style: theme.TextStyles.tabHeading),
        Text(value, style: theme.TextStyles.tabPrimary),
      ],
    );
  }

  createSteps() {
    return _profile.shotFrames
        .map((p) => createKeyValue(p.name, "Duration: ${p.frameLen} s    Pressure: ${p.setVal} bar"))
        .toList();
  }

  void profileListener() {
    log.info('Profile updated');
  }

  List<Widget> handleChanges(De1ShotFrameClass frame) {
    return [
      changeTemp(unit: "°C", title: "Temperature", min: 70, max: 100, interval: 5, frame, frame.temp, (temp, isMixer) {
        frame.temp = (temp * 10).round() / 10;
        // int mask = (De1ShotFrameClass.TMixTemp);
        var mask = frame.flag & (255 - De1ShotFrameClass.TMixTemp);

        log.info("Changed $frame");

        if (!isMixer) {
          frame.flag &= mask;
        } else {
          frame.flag |= De1ShotFrameClass.TMixTemp;
        }

        setState(() {});
        log.info("Changed $frame");
      }),
      changeGoal(
          unit: "bar",
          title: "Pressure",
          min: 0,
          max: 16,
          interval: 1,
          frame,
          frame.pump == "pressure" ? frame.setVal : frame.triggerVal, (value, isFast, isPressure) {
        frame.transition = isFast ? "fast" : "smooth";

        var mask = frame.flag & (255 - De1ShotFrameClass.CtrlF);
        if (isPressure) {
          frame.flag &= mask;
        } else {
          frame.flag |= De1ShotFrameClass.CtrlF;
        }
        frame.pump = (frame.flag & De1ShotFrameClass.CtrlF) == 0 ? "pressure" : "flow";

        mask = frame.flag & (255 - De1ShotFrameClass.Interpolate);
        if (isFast) {
          frame.flag &= mask;
        } else {
          frame.flag |= De1ShotFrameClass.Interpolate;
        }
        setState(() {});
        log.info("Changed");
      }),
      changeMax(unit: "sec", title: "Time", min: 0, max: 100, frame, frame.frameLen, (value, a, b) {
        setState(() => frame.frameLen = value);
        log.info("Changed");
      }),
      changeMoveOnIf(unit: "sec", title: "Time", min: 0, max: 100, frame, frame.frameLen, (value) {
        setState(() {});
        log.info("Changed");
      }),
      // changeFlow(
      //     unit: "ml/s",
      //     title: "Flow",
      //     min: 0,
      //     max: 16,
      //     interval: 1,
      //     frame,
      //     frame.pump == "flow" ? frame.setVal : frame.triggerVal, (value, isFast) {
      //   var v = (value * 10).round() / 10;
      //   if (frame.pump == "flow") {
      //     frame.setVal = v;
      //   } else {
      //     frame.triggerVal = v;
      //   }
      //   frame.transition = isFast ? "fast" : "smooth";
      //   var mask = frame.flag & (255 - De1ShotFrameClass.Interpolate);
      //   if (isFast) {
      //     frame.flag &= mask;
      //   } else {
      //     frame.flag |= De1ShotFrameClass.Interpolate;
      //   }
      //   setState(() {});
      //   log.info("Changed");
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
    ];
  }

  changePressure(De1ShotFrameClass frame, double value, Function(double value, bool isMixer) valueChanged,
      {required String unit, required double max, required double min, double? interval, String? title}) {
    bool isFast = (frame.flag & De1ShotFrameClass.Interpolate) == 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (title != null) Text(title, style: Theme.of(context).textTheme.headlineLarge),
                  SizedBox(
                    width: 240,
                    height: 50,
                    child: SpinBox(
                      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                      textInputAction: TextInputAction.done,
                      onChanged: (value) {
                        valueChanged(value, isFast);
                      },
                      min: min,
                      max: max,
                      value: value,
                      decimals: 1,
                      step: 0.1,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.only(left: 15, bottom: 24, top: 24, right: 15),
                        suffix: Text(unit),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: SfSlider(
                      min: min,
                      max: max,
                      value: value,
                      interval: interval ?? max / 10,
                      showTicks: false,
                      showLabels: true,
                      enableTooltip: true,
                      stepSize: 0.1,
                      minorTicksPerInterval: 1,
                      onChanged: (dynamic value) {
                        valueChanged(value, isFast);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Row(
              children: [
                Text("Transition:", style: Theme.of(context).textTheme.labelMedium),
                ToggleButtons(
                  children: [const Text("Fast"), const Text("Smooth")],
                  isSelected: [isFast, !isFast],
                  onPressed: (index) {
                    valueChanged(value, index == 0 ? true : false);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget changeGoal(
      De1ShotFrameClass frame, double value, Function(double value, bool isMixer, bool isPressure) valueChanged,
      {required String unit, required double max, required double min, double? interval, String? title}) {
    bool isPressure = (frame.pump == "pressure" ? true : false);
    bool isFast = (frame.flag & De1ShotFrameClass.Interpolate) == 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: 160,
                  child: changeValueRow(
                      unit: "bar",
                      title: frame.pump == "pressure" ? "Pressure" : "limit Press.",
                      min: 0,
                      max: 16,
                      interval: 1,
                      frame,
                      frame.pump == "pressure" ? frame.setVal : frame.triggerVal, (value) {
                    var v = (value * 10).round() / 10;
                    if (frame.pump == "pressure") {
                      frame.setVal = v;
                    } else {
                      frame.triggerVal = v;
                    }
                    // frame.transition = isFast ? "fast" : "smooth";
                    // var mask = frame.flag & (255 - De1ShotFrameClass.Interpolate);
                    // if (isFast) {
                    //   frame.flag &= mask;
                    // } else {
                    //   frame.flag |= De1ShotFrameClass.Interpolate;
                    // }
                    setState(() {});
                    log.info("Changed");
                  }),
                ),
                SizedBox(
                  height: 160,
                  child: changeValueRow(
                      unit: "ml/s",
                      title: frame.pump == "pressure" ? "limit Flow" : "Flow",
                      min: 0,
                      max: 16,
                      interval: 1,
                      frame,
                      frame.pump == "flow" ? frame.setVal : frame.triggerVal, (value) {
                    if (frame.pump == "flow")
                      frame.setVal = value;
                    else
                      frame.triggerVal = value;
                    setState(() {});
                    log.info("Changed");
                  }),
                ),
              ],
            ),
          ),
        ),
        IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(width: 80, child: Text("Limiting:", style: Theme.of(context).textTheme.labelMedium)),
                    ToggleButtons(
                      children: [const Text("Pressure"), const Text("Flow")],
                      isSelected: [isPressure, !isPressure],
                      onPressed: (index) {
                        valueChanged(value, isFast, index == 0 ? true : false);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(width: 80, child: Text("Transition:", style: Theme.of(context).textTheme.labelMedium)),
                    ToggleButtons(
                      children: [const Text("Fast"), const Text("Smooth")],
                      isSelected: [isFast, !isFast],
                      onPressed: (index) {
                        valueChanged(value, index == 0 ? true : false, isPressure);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget changeMax(
      De1ShotFrameClass frame, double value, Function(double value, bool isMixer, bool isPressure) valueChanged,
      {required String unit, required double max, required double min, double? interval, String? title}) {
    bool isPressure = (frame.pump == "pressure" ? true : false);
    bool isFast = (frame.flag & De1ShotFrameClass.Interpolate) == 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: 160,
                  child: changeValueRow(unit: "sec", title: "Time", min: 0, max: 100, frame, frame.frameLen, (value) {
                    setState(() => frame.frameLen = value);
                    log.info("Changed");
                  }),
                ),
                SizedBox(
                  height: 160,
                  child: changeValueRow(
                      unit: "ml", title: "Max. Volume", min: 0, max: 500, De1ShotFrameClass(), frame.maxVol, (value) {
                    var v = (value * 10).round() / 10;
                    setState(() => frame.maxVol = v);
                  }),
                ),
              ],
            ),
          ),
        ),
        if (false)
          IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(width: 80, child: Text("Limiting:", style: Theme.of(context).textTheme.labelMedium)),
                      ToggleButtons(
                        children: [const Text("Pressure"), const Text("Flow")],
                        isSelected: [isPressure, !isPressure],
                        onPressed: (index) {
                          valueChanged(value, isFast, index == 0 ? true : false);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(width: 80, child: Text("Transition:", style: Theme.of(context).textTheme.labelMedium)),
                      ToggleButtons(
                        children: [const Text("Fast"), const Text("Smooth")],
                        isSelected: [isFast, !isFast],
                        onPressed: (index) {
                          valueChanged(value, index == 0 ? true : false, isPressure);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  changeFlow(De1ShotFrameClass frame, double value, Function(double value, bool isMixer) valueChanged,
      {required String unit, required double max, required double min, double? interval, String? title}) {
    bool isFast = (frame.flag & De1ShotFrameClass.Interpolate) == 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (title != null) Text(title, style: Theme.of(context).textTheme.headlineLarge),
                  SizedBox(
                    width: 240,
                    height: 50,
                    child: SpinBox(
                      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                      textInputAction: TextInputAction.done,
                      onChanged: (value) {
                        valueChanged(value, isFast);
                      },
                      min: min,
                      max: max,
                      value: value,
                      decimals: 1,
                      step: 0.1,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.only(left: 15, bottom: 24, top: 24, right: 15),
                        suffix: Text(unit),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: SfSlider(
                      min: min,
                      max: max,
                      value: value,
                      interval: interval ?? max / 10,
                      showTicks: false,
                      showLabels: true,
                      enableTooltip: true,
                      stepSize: 0.1,
                      minorTicksPerInterval: 1,
                      onChanged: (dynamic value) {
                        valueChanged(value, isFast);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text("Transition:", style: Theme.of(context).textTheme.labelMedium),
                  ToggleButtons(
                    children: [Text("Fast"), Text("Smooth")],
                    isSelected: [isFast, !isFast],
                    onPressed: (index) {
                      valueChanged(value, index == 0 ? true : false);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  changeTemp(De1ShotFrameClass frame, double value, Function(double value, bool isMixer) valueChanged,
      {required String unit, required double max, required double min, double? interval, String? title}) {
    bool isMix = ((frame.flag & De1ShotFrameClass.TMixTemp) > 0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (title != null) Text(title, style: Theme.of(context).textTheme.headlineLarge),
                  SizedBox(
                    width: 240,
                    height: 50,
                    child: SpinBox(
                      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                      textInputAction: TextInputAction.done,
                      onChanged: (value) {
                        valueChanged(value, isMix);
                      },
                      min: min,
                      max: max,
                      value: value,
                      decimals: 1,
                      step: 0.1,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.only(left: 15, bottom: 24, top: 24, right: 15),
                        suffix: Text(unit),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: SfSlider(
                      min: min,
                      max: max,
                      value: value,
                      interval: interval ?? max / 10,
                      showTicks: false,
                      showLabels: true,
                      enableTooltip: true,
                      stepSize: 0.1,
                      minorTicksPerInterval: 1,
                      onChanged: (dynamic value) {
                        valueChanged(value, isMix);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text("Sensor:", style: Theme.of(context).textTheme.labelMedium)),
                  ToggleButtons(
                    children: [Text("Coffee"), Text("Water")],
                    isSelected: [!isMix, isMix],
                    onPressed: (index) {
                      valueChanged(value, index == 0 ? false : true);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  changeMoveOnIf(De1ShotFrameClass frame, double value, Function(De1ShotFrameClass value) valueChanged,
      {required String unit, required double max, required double min, double? interval, String? title}) {
    bool isComparing = ((frame.flag & De1ShotFrameClass.DoCompare) > 0);
    bool isGt = (frame.flag & De1ShotFrameClass.DC_GT) > 0;
    bool isFlow = (frame.flag & De1ShotFrameClass.DC_CompF) > 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(width: 55, child: Text("Do\ncompare:", style: Theme.of(context).textTheme.labelMedium)),
                      Switch(
                        value: isComparing,
                        onChanged: (value) {
                          var mask = frame.flag & (255 - De1ShotFrameClass.DoCompare);
                          if (!value) {
                            frame.flag &= mask;
                          } else {
                            frame.flag |= De1ShotFrameClass.DoCompare;
                          }

                          valueChanged(frame);
                        },
                      ),
                    ],
                  ),
                  if (isComparing)
                    Row(
                      children: [
                        SizedBox(width: 55, child: Text("If:", style: Theme.of(context).textTheme.labelMedium)),
                        ToggleButtons(
                          children: [Text("Pressure"), Text("Flow")],
                          isSelected: [!isFlow, isFlow],
                          onPressed: (index) {
                            var mask = frame.flag & (255 - De1ShotFrameClass.DC_CompF);
                            if (index == 0) {
                              frame.flag &= mask;
                            } else {
                              frame.flag |= De1ShotFrameClass.DC_CompF;
                            }

                            valueChanged(frame);
                          },
                        ),
                      ],
                    ),
                  if (isComparing)
                    Row(
                      children: [
                        SizedBox(width: 55, child: Text("is:", style: Theme.of(context).textTheme.labelMedium)),
                        ToggleButtons(
                          children: [Text(" over "), Text(" below ")],
                          isSelected: [isGt, !isGt],
                          onPressed: (index) {
                            // DC_GT
                            var mask = frame.flag & (255 - De1ShotFrameClass.DC_GT);
                            if (index == 1) {
                              frame.flag &= mask;
                            } else {
                              frame.flag |= De1ShotFrameClass.DC_GT;
                            }

                            valueChanged(frame);
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: SizedBox(
              height: 160,
              child: !isComparing
                  ? null
                  : changeValueRow(
                      unit: isFlow ? "ml/s" : "bar",
                      title: isFlow ? "${isGt ? ">" : "<"} Flow" : "${isGt ? ">" : "<"} Pressure",
                      min: 0,
                      max: 16,
                      interval: 1,
                      frame,
                      frame.triggerVal, (value) {
                      frame.triggerVal = value;

                      setState(() {});
                      log.info("Changed");
                    }),
            ),
          ),
        ),
      ],
    );
  }

  Widget changeValue(De1ShotFrameClass frame, double value, Function(double value) valueChanged,
      {required String unit, required double max, required double min, double? interval, String? title}) {
    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (title != null) Text(title, style: Theme.of(context).textTheme.headlineMedium),
            SizedBox(
              width: 240,
              height: 80,
              child: SpinBox(
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  valueChanged(value);
                },
                min: min,
                max: max,
                value: value,
                decimals: 1,
                step: 0.1,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.only(left: 15, bottom: 24, top: 24, right: 15),
                  suffix: Text(unit),
                ),
              ),
            ),
            SfSlider(
              min: min,
              max: max,
              value: value,
              interval: interval ?? max / 10,
              showTicks: false,
              showLabels: true,
              enableTooltip: true,
              stepSize: 0.1,
              minorTicksPerInterval: 10,
              onChanged: (dynamic value) {
                valueChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget changeValueRow(De1ShotFrameClass frame, double value, Function(double value) valueChanged,
      {required String unit, required double max, required double min, double? interval, String? title}) {
    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Expanded(
          child: Column(
            children: [
              SizedBox(
                width: 350,
                height: 30,
                child: Expanded(
                  child: Row(
                    children: [
                      if (title != null)
                        SizedBox(width: 150, child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          width: 350,
                          child: SpinBox(
                            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                            textInputAction: TextInputAction.done,
                            onChanged: (value) {
                              valueChanged(value);
                            },
                            min: min,
                            max: max,
                            value: value,
                            decimals: 1,
                            step: 0.1,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.only(left: 15, bottom: 24, top: 24, right: 15),
                              suffix: Text(unit),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SfSlider(
                min: min,
                max: max,
                value: value,
                interval: interval ?? max / 10,
                showTicks: false,
                showLabels: true,
                enableTooltip: true,
                stepSize: 0.1,
                minorTicksPerInterval: 10,
                onChanged: (dynamic value) {
                  valueChanged(value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
