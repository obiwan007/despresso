import 'dart:ffi';
import 'dart:typed_data';

import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/ui/widgets/editable_text.dart';
import 'package:despresso/ui/widgets/key_value.dart';
import 'package:despresso/ui/widgets/profile_graph.dart';
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

    switch (_profile.shotHeader.type) {
      case "pressure":
      case "flow":
        _tabController = TabController(length: 3 * 4 + 2, vsync: this, initialIndex: 0);
        break;
      default:
        _tabController = TabController(length: 6, vsync: this, initialIndex: 0);
    }
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
          initialValue: "${_profile.shotHeader.title} (Advanced Editor)",
          onChanged: (value) {
            setState(() {
              _profile.shotHeader.title = value;
            });
          },
        ),
        //Text('Profile Edit: ${_profile.shotHeader.title}'),
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
              flex: 1,
              child: IntrinsicHeight(
                child: ProfileGraphWidget(selectedProfile: _profile),
              ),
            ),
            Expanded(
                flex: 2,
                child: IntrinsicHeight(
                    child: Row(
                  children: [
                    Expanded(
                      flex: 1,
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
        // Row(
        //   children: [
        //     Expanded(
        //       flex: 4,
        //       child: ColoredBox(
        //         color: phaseColors[0],
        //         child: const SizedBox(
        //           height: 20,
        //           width: 100,
        //         ),
        //       ),
        //     ),
        //     Expanded(
        //       flex: 4,
        //       child: ColoredBox(
        //         color: phaseColors[1],
        //         child: const SizedBox(
        //           height: 20,
        //           width: 100,
        //         ),
        //       ),
        //     ),
        //     Expanded(
        //       flex: 4,
        //       child: ColoredBox(
        //         color: phaseColors[2],
        //         child: const SizedBox(
        //           height: 20,
        //           width: 100,
        //         ),
        //       ),
        //     ),
        //     Expanded(
        //       flex: 2,
        //       child: ColoredBox(
        //         color: phaseColors[3],
        //         child: const SizedBox(
        //           height: 20,
        //           width: 100,
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
        // SizedBox(
        //   height: 10,
        //   child: Row(
        //     crossAxisAlignment: CrossAxisAlignment.center,
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: [
        //       Expanded(
        //           flex: 4,
        //           child: Center(child: Text(_selectedStep.name, style: Theme.of(context).textTheme.bodyLarge))),
        //       // Expanded(
        //       //     flex: 4, child: Center(child: Text("Rise and hold", style: Theme.of(context).textTheme.bodyLarge))),
        //       // Expanded(flex: 4, child: Center(child: Text("Decline", style: Theme.of(context).textTheme.bodyLarge))),
        //       // Expanded(flex: 2, child: Center(child: Text("Stop", style: Theme.of(context).textTheme.bodyLarge))),
        //     ],
        //   ),
        // ),
        TabBar(
          controller: _tabController,

          // indicator: BoxDecoration(color: _tabController.index < 4 ? Colors.red : Colors.green),
          // indicator:
          //     UnderlineTabIndicator(borderSide: BorderSide(width: 5.0), insets: EdgeInsets.symmetric(horizontal: 16.0)),
          tabs: <Widget>[
            ...createTabs(_selectedStep, color: phaseColors[0]),
            Tab(
              height: 95,
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Text("max. Vol",
                        style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 20)),
                  ),
                  Text("${_selectedStep.maxVol}",
                      style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 20)),
                  Text(
                    "ml",
                    style: TextStyle(color: phaseColors[3]),
                  ),
                ],
              ),
            ),
            Tab(
              height: 95,
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Text("Weight",
                        style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 20)),
                  ),
                  Text("${_profile.shotHeader.targetWeight}",
                      style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 20)),
                  Text(
                    "g",
                    style: TextStyle(color: phaseColors[3]),
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

  createTabs(De1ShotFrameClass? frame, {required MaterialColor color}) {
    var h = 30.0;
    var hTab = 95.0;
    var fontsize = 20.0;
    var style1 = TextStyle(color: color, fontWeight: FontWeight.normal, fontSize: fontsize);
    var style2 = TextStyle(fontWeight: FontWeight.normal, fontSize: fontsize);
    var style3 = TextStyle(color: color);

    if (frame == null) {
      return [
        Tab(
          height: hTab,
          child: Column(
            children: [
              SizedBox(
                height: h,
                child: FittedBox(
                  child: Text(
                    "Error",
                    style: style1,
                  ),
                ),
              ),
              Text(
                "no frame",
                style: style1,
              ),
              Text(
                "",
                style: style3,
              ),
            ],
          ),
        ),
      ];
    }

    return [
      Tab(
        height: hTab,
        child: Column(
          children: [
            SizedBox(
              height: h,
              child: FittedBox(
                child: Text(
                  "Time",
                  style: style1,
                ),
              ),
            ),
            Text(
              "${(frame?.frameLen.toStringAsFixed(1) ?? 0)}",
              style: style1,
            ),
            Text(
              "sec",
              style: style3,
            ),
          ],
        ),
      ),
      Tab(
        height: hTab,
        child: Column(
          children: [
            SizedBox(
              height: h,
              child: FittedBox(
                child: Text(
                  "Pres.",
                  style: (frame?.pump == "pressure") ? style1 : style2,
                ),
              ),
            ),
            Text("${(frame?.pump == "pressure" ? frame.setVal : frame.triggerVal)}",
                style: (frame.pump == "pressure") ? style1 : style2),
            Text("bar", style: (frame.pump == "pressure") ? style3 : null),
          ],
        ),
      ),
      Tab(
        height: hTab,
        child: Column(
          children: [
            SizedBox(
              height: h,
              child: FittedBox(
                child: Text(
                  "Flow",
                  style: (frame.pump == "flow") ? style1 : style2,
                ),
              ),
            ),
            Text("${(frame.pump == "flow" ? frame.setVal : frame.triggerVal)}",
                style: (frame.pump == "flow") ? style1 : style2),
            Text("ml/s", style: (frame.pump == "flow") ? style3 : null),
          ],
        ),
      ),
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
      changeValue(unit: "sec", title: "Time", min: 0, max: 100, frame, frame.frameLen, (value) {
        setState(() => frame.frameLen = value);
        log.info("Changed");
      }),
      changePressure(
          unit: "bar",
          title: "Pressure",
          min: 0,
          max: 16,
          interval: 1,
          frame,
          frame.pump == "pressure" ? frame.setVal : frame.triggerVal, (value, isFast) {
        var v = (value * 10).round() / 10;
        if (frame.pump == "pressure") {
          frame.setVal = v;
        } else {
          frame.triggerVal = v;
        }
        frame.transition = isFast ? "fast" : "smooth";
        var mask = frame.flag & (255 - De1ShotFrameClass.Interpolate);
        if (isFast) {
          frame.flag &= mask;
        } else {
          frame.flag |= De1ShotFrameClass.Interpolate;
        }
        setState(() {});
        log.info("Changed");
      }),
      changeFlow(
          unit: "ml/s",
          title: "Flow",
          min: 0,
          max: 16,
          interval: 1,
          frame,
          frame.pump == "flow" ? frame.setVal : frame.triggerVal, (value, isFast) {
        var v = (value * 10).round() / 10;
        if (frame.pump == "flow") {
          frame.setVal = v;
        } else {
          frame.triggerVal = v;
        }
        frame.transition = isFast ? "fast" : "smooth";
        var mask = frame.flag & (255 - De1ShotFrameClass.Interpolate);
        if (isFast) {
          frame.flag &= mask;
        } else {
          frame.flag |= De1ShotFrameClass.Interpolate;
        }
        setState(() {});
        log.info("Changed");
      }),
      changeTemp(unit: "°C", title: "Temperature", min: 80, max: 100, interval: 1, frame, frame.temp, (temp, isMixer) {
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
      changeValue(unit: "ml", title: "Max. Volume", min: 0, max: 100, De1ShotFrameClass(), frame.maxVol, (value) {
        var v = (value * 10).round() / 10;
        setState(() => frame.maxVol = v);
      }),
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
                  Text("Sensor:", style: Theme.of(context).textTheme.labelMedium),
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

  changeValue(De1ShotFrameClass frame, double value, Function(double value) valueChanged,
      {required String unit, required double max, required double min, double? interval, String? title}) {
    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (title != null) Text(title, style: Theme.of(context).textTheme.headlineLarge),
            SizedBox(
              width: 240,
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
}

class SelectableSteps extends StatelessWidget {
  final log = Logger("SelectableStep");
  SelectableSteps({super.key, required De1ShotProfile profile, required this.selected, required this.onSelected})
      : _profile = profile;

  final De1ShotProfile _profile;
  final Function(int) onSelected;
  final int selected;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.vertical,
      shrinkWrap: false,
      itemCount: _profile.shotFrames.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            bottomLeft: Radius.circular(32),
          ),
          child: ListTile(
            title: Text(_profile.shotFrames[index].name),
            subtitle: getSubtitle(_profile.shotFrames[index]),
            selected: index == selected,
            onTap: () => onSelected(index),
          ),
        );
      },
    );
  }

  Widget getSubtitle(De1ShotFrameClass frame) {
    bool isMix = ((frame.flag & De1ShotFrameClass.TMixTemp) > 0);
    bool isGt = (frame.flag & De1ShotFrameClass.DC_GT) > 0;
    bool isFlow = (frame.flag & De1ShotFrameClass.DC_CompF) > 0;
    bool isCompared = (frame.flag & De1ShotFrameClass.DoCompare) > 0;
    String vol = "${frame.maxVol > 0 ? " or ${frame.maxVol} ml" : ""}";
    log.info("RenderFrame Test: $frame");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Set ${isMix ? "water" : "coffee"} temperature to ${frame.temp.toStringAsFixed(0)} °C"),
        if (frame.pump != "pressure")
          Text("pour ${frame.transition} at rate of ${frame.setVal.toStringAsFixed(1)} ml/s"),
        if (frame.pump == "pressure") Text("Pressurize ${frame.transition} to ${frame.setVal.toStringAsFixed(1)} bar"),
        Text("For a maximum of ${frame.frameLen.toStringAsFixed(0)} seconds $vol"),
        if (isCompared)
          Text(
              "Move on if ${isFlow ? "flow" : "pressure"} is ${isGt ? "over" : "below"} ${frame.triggerVal.toStringAsFixed(1)} bar"),
      ],
    );
  }
}