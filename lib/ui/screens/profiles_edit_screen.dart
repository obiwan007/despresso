import 'package:despresso/generated/l10n.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/ui/widgets/editable_text.dart';
import 'package:despresso/ui/widgets/profile_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinbox/material.dart';
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import '../../model/services/ble/machine_service.dart';
import '../../service_locator.dart';

class ProfilesEditScreen extends StatefulWidget {
  final De1ShotProfile profile;

  const ProfilesEditScreen(this.profile, {Key? key}) : super(key: key);

  @override
  ProfilesEditScreenState createState() {
    return ProfilesEditScreenState();
  }
}

class ProfilesEditScreenState extends State<ProfilesEditScreen> with SingleTickerProviderStateMixin {
  final log = Logger('ProfilesEditScreenState');

  late ProfileService profileService;

  late EspressoMachineService machineService;

  late De1ShotProfile _profile;

  De1ShotFrameClass? preInfusion;
  // De1ShotFrameClass? forcedRise;
  De1ShotFrameClass? riseAndHold;
  De1ShotFrameClass? decline;

  De1ShotFrameClass? forcedRise;

  late TabController _tabController;

  List<MaterialColor> phaseColors = [Colors.blue, Colors.purple, Colors.green, Colors.brown];

  ProfilesEditScreenState();

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    log.info('Init State ${_profile.shotHeader.title}');
    machineService = getIt<EspressoMachineService>();
    profileService = getIt<ProfileService>();

    profileService.addListener(profileListener);
    // _tabController = TabController(length: 5, vsync: this, initialIndex: 1);
    for (var element in _profile.shotFrames) {
      log.info("Profile: $element");
    }

    var declineObject = De1ShotFrameClass();
    declineObject.temp = _profile.shotFrames.first.temp;
    try {
      var pre = _profile.shotFrames.where((element) => (element.name.startsWith("preinfusion")));
      preInfusion = pre.isEmpty ? null : pre.toList().first;

      var riseW = _profile.shotFrames.where((element) => (element.name == "rise and hold" || element.name == "hold"));
      riseAndHold = riseW.isNotEmpty ? riseW.first : null;
      var forcedRiseWhere = _profile.shotFrames.where((element) => (element.name == "forced rise without limit"));
      forcedRise = forcedRiseWhere.isNotEmpty ? forcedRiseWhere.first : null;
      var declineArray = _profile.shotFrames.where((element) => (element.name == "decline")).toList();
      if (declineArray.isNotEmpty) {
        decline = declineArray.first;
      } else if (_profile.shotHeader.type != "advanced") {
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
        _tabController = TabController(length: 1, vsync: this, initialIndex: 0);
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
          initialValue: _profile.shotHeader.title,
          onChanged: (value) {
            setState(() {
              _profile.shotHeader.title = value;
            });
          },
        ),
        //Text('Profile Edit: ${_profile.shotHeader.title}'),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Save as new'),
            onPressed: () {
              setState(() {
                profileService.saveAsNew(_profile);
                Navigator.pop(context);
              });
            },
          ),
          ElevatedButton(
            child: Text(S.of(context).save),
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
            if (_profile.shotHeader.type != "advanced") SizedBox(height: 195, child: createTabBar()),
            if (_profile.shotHeader.type != "advanced")
              Expanded(
                child: IntrinsicHeight(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      if (preInfusion != null) ...handleChanges(preInfusion!),
                      ...handleChanges(riseAndHold!),
                      ...handleChanges(decline!),
                      changeValue(
                          unit: "ml",
                          title: "Max. Volume",
                          min: 0,
                          max: 100,
                          De1ShotFrameClass(),
                          _profile.shotHeader.targetVolume, (value) {
                        var v = (value * 10).round() / 10;
                        setState(() => _profile.shotHeader.targetVolume = v);
                      }),
                      changeValue(
                          unit: "g",
                          title: "Max. Weight",
                          min: 0,
                          max: 100,
                          De1ShotFrameClass(),
                          _profile.shotHeader.targetWeight, (value) {
                        var v = (value * 10).round() / 10;
                        setState(() => _profile.shotHeader.targetWeight = v);
                      }),
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
              flex: 4,
              child: ColoredBox(
                color: phaseColors[0],
                child: const SizedBox(
                  height: 20,
                  width: 100,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: ColoredBox(
                color: phaseColors[1],
                child: const SizedBox(
                  height: 20,
                  width: 100,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: ColoredBox(
                color: phaseColors[2],
                child: const SizedBox(
                  height: 20,
                  width: 100,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: ColoredBox(
                color: phaseColors[3],
                child: const SizedBox(
                  height: 20,
                  width: 100,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 50,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                  flex: 4, child: Center(child: Text("Preinfusion", style: Theme.of(context).textTheme.bodyLarge))),
              Expanded(
                  flex: 4, child: Center(child: Text("Rise and hold", style: Theme.of(context).textTheme.bodyLarge))),
              Expanded(flex: 4, child: Center(child: Text("Decline", style: Theme.of(context).textTheme.bodyLarge))),
              Expanded(flex: 2, child: Center(child: Text("Stop", style: Theme.of(context).textTheme.bodyLarge))),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,

          // indicator: BoxDecoration(color: _tabController.index < 4 ? Colors.red : Colors.green),
          // indicator:
          //     UnderlineTabIndicator(borderSide: BorderSide(width: 5.0), insets: EdgeInsets.symmetric(horizontal: 16.0)),
          tabs: <Widget>[
            if (preInfusion != null) ...createTabs(preInfusion, color: phaseColors[0]),
            ...createTabs(riseAndHold, color: phaseColors[1]),
            ...createTabs(decline, color: phaseColors[2]),
            Tab(
              height: 95,
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Text("Vol",
                        style: TextStyle(color: phaseColors[3], fontWeight: FontWeight.normal, fontSize: 20)),
                  ),
                  Text("${_profile.shotHeader.targetVolume}",
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
              (frame.frameLen.toStringAsFixed(1)),
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
                  style: (frame.pump == De1PumpMode.pressure) ? style1 : style2,
                ),
              ),
            ),
            Text("${(frame.pump == De1PumpMode.pressure ? frame.setVal : frame.triggerVal)}",
                style: (frame.pump == De1PumpMode.pressure) ? style1 : style2),
            Text("bar", style: (frame.pump == De1PumpMode.pressure) ? style3 : null),
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
                  style: (frame.pump == De1PumpMode.flow) ? style1 : style2,
                ),
              ),
            ),
            Text("${(frame.pump == De1PumpMode.flow ? frame.setVal : frame.triggerVal)}",
                style: (frame.pump == De1PumpMode.flow) ? style1 : style2),
            Text("ml/s", style: (frame.pump == De1PumpMode.flow) ? style3 : null),
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
                                "Limit flow (${(riseAndHold.pump == De1PumpMode.flow ? riseAndHold.setVal : riseAndHold.triggerVal).round()} ml/s)"),
                            SfSlider(
                              min: 0.0,
                              max: 10.0,
                              value: riseAndHold.pump == De1PumpMode.flow ? riseAndHold.setVal : riseAndHold.triggerVal,
                              interval: 1,
                              showTicks: true,
                              showLabels: true,
                              stepSize: 0.1,
                              enableTooltip: true,
                              minorTicksPerInterval: 1,
                              onChanged: (dynamic value) {
                                riseAndHold.pump == De1PumpMode.flow
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
                        value: riseAndHold.pump == De1PumpMode.pressure ? riseAndHold.setVal : riseAndHold.triggerVal,
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
                        value: preInfusion!.pump == De1PumpMode.pressure ? preInfusion!.setVal : preInfusion!.triggerVal,
                        interval: 2,
                        stepSize: 0.1,
                        showTicks: true,
                        showLabels: true,
                        enableTooltip: true,
                        minorTicksPerInterval: 1,
                        onChanged: (dynamic value) {
                          setState(() {
                            var v = (value * 10).round() / 10;
                            if (decline!.pump == De1PumpMode.pressure) {
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

  void profileListener() {
    log.info('Profile updated');
  }

  handleChanges(De1ShotFrameClass frame) {
    return [
      changeValue(unit: "sec", title: "Time", min: 0, max: 100, frame, frame.frameLen, (value) {
        setState(() => frame.frameLen = value);
        log.info("Changed");
      }),
      changeValue(
          unit: "bar",
          title: "Pressure",
          min: 0,
          max: 16,
          interval: 1,
          frame,
          frame.pump == De1PumpMode.pressure ? frame.setVal : frame.triggerVal, (value) {
        var v = (value * 10).round() / 10;
        if (frame.pump == De1PumpMode.pressure) {
          frame.setVal = v;
        } else {
          frame.triggerVal = v;
        }
        setState(() {});
        log.info("Changed");
      }),
      changeValue(
          unit: "ml/s",
          title: "Flow",
          min: 0,
          max: 16,
          interval: 1,
          frame,
          frame.pump == De1PumpMode.flow ? frame.setVal : frame.triggerVal, (value) {
        var v = (value * 10).round() / 10;
        if (frame.pump == De1PumpMode.flow) {
          frame.setVal = v;
        } else {
          frame.triggerVal = v;
        }
        setState(() {});
        log.info("Changed");
      }),
      changeValue(unit: "°C", title: "Temperature", min: 80, max: 100, interval: 1, frame, frame.temp, (value) {
        frame.temp = (value * 10).round() / 10;

        setState(() {});
        log.info("Changed");
      })
    ];
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
