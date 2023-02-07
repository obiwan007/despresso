import 'package:despresso/logger_util.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:despresso/ui/widgets/profile_graph.dart';
import 'package:flutter/material.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:community_charts_flutter/community_charts_flutter.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import '../../model/services/ble/machine_service.dart';
import '../../service_locator.dart';

class ProfilesEditScreen extends StatefulWidget {
  De1ShotProfile profile;

  ProfilesEditScreen(this.profile, {Key? key}) : super(key: key);

  @override
  ProfilesEditScreenState createState() {
    return ProfilesEditScreenState(profile);
  }
}

class ProfilesEditScreenState extends State<ProfilesEditScreen> {
  final log = Logger('ProfilesEditScreenState');

  late ProfileService profileService;
  ShotList shotList = ShotList([]);
  late EspressoMachineService machineService;

  Iterable<RangeAnnotationSegment<double>> phases = [];

  final De1ShotProfile _profile;

  De1ShotFrameClass? preInfusion;
  De1ShotFrameClass? forcedRise;
  De1ShotFrameClass? riseAndHold;
  De1ShotFrameClass? decline;

  ProfilesEditScreenState(this._profile);

  @override
  void initState() {
    super.initState();
    log.info('Init State ${_profile.shotHeader.title}');
    machineService = getIt<EspressoMachineService>();
    profileService = getIt<ProfileService>();

    profileService.addListener(profileListener);

    for (var element in _profile.shotFrames) {
      log.info("Profile: $element");
    }

    phases = _createPhases();

    var declineObject = De1ShotFrameClass();
    declineObject.frameToWrite = _profile.shotFrames.length;
    declineObject.temp = _profile.shotFrames.first.temp;

    preInfusion = _profile.shotFrames.where((element) => (element.name == "preinfusion")).toList().first;

    riseAndHold = _profile.shotFrames.where((element) => (element.name == "rise and hold")).toList().first;
    forcedRise = _profile.shotFrames.where((element) => (element.name == "forced rise without limit")).toList().first;
    var declineArray = _profile.shotFrames.where((element) => (element.name == "decline")).toList();
    if (declineArray.isNotEmpty) {
      decline = declineArray.first;
    } else {
      _profile.shotFrames.add(declineObject);
      decline = declineObject;
    }
    log.info("Decline: $decline");
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
        title: Text('Profile Edit: ${_profile.shotHeader.title}'),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () {
              setState(() {
                profileService.save(_profile);
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
            Container(
              color: Colors.white10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Card(
                          child: buildPreinfusion(),
                        ),
                      ),
                      Expanded(
                        flex: 5, // takes 30% of available width
                        child: Card(
                          child: buildRiseAndHold(),
                        ),
                      ),
                      Expanded(
                        flex: 5, // takes 30% of available width
                        child: Card(
                          child: buildDecline(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPreinfusion() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const Text("Preinfuse"),
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
                          Text("Infusion Time (${preInfusion?.frameLen.round()} s)"),
                          SfSlider(
                            min: 0.0,
                            max: 100.0,
                            value: preInfusion!.frameLen,
                            interval: 20,
                            showTicks: true,
                            showLabels: true,
                            enableTooltip: true,
                            minorTicksPerInterval: 1,
                            onChanged: (dynamic value) {
                              setState(() {
                                preInfusion!.frameLen = value;
                                phases = _createPhases();
                              });
                            },
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 28.0),
                        child: Column(
                          children: [
                            const Text("Max. Flow"),
                            SfSlider(
                              min: 0.0,
                              max: 10.0,
                              value: preInfusion!.pump == "flow" ? preInfusion!.setVal : preInfusion!.triggerVal,
                              interval: 1,
                              showTicks: true,
                              showLabels: true,
                              enableTooltip: true,
                              minorTicksPerInterval: 1,
                              onChanged: (dynamic value) {
                                var v = (value * 10).round() / 10;
                                if (preInfusion!.pump == "flow")
                                  preInfusion!.setVal = v;
                                else
                                  preInfusion!.triggerVal = v;
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
                      Text("Pressure < ${preInfusion?.setVal} bar"),
                      SfSlider.vertical(
                        min: 0.0,
                        max: 10.0,
                        value: preInfusion!.pump == "pressure" ? preInfusion!.setVal : preInfusion!.triggerVal,
                        interval: 5,
                        showTicks: true,
                        showLabels: true,
                        enableTooltip: true,
                        minorTicksPerInterval: 5,
                        onChanged: (dynamic value) {
                          setState(() {
                            var v = (value * 10).round() / 10;
                            if (preInfusion!.pump == "pressure")
                              preInfusion!.setVal = v;
                            else
                              preInfusion!.triggerVal = v;
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

  Padding buildRiseAndHold() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text("Rise and hold (${riseAndHold?.frameLen.round()} s)"),
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
                          Text("Time (${riseAndHold?.frameLen.round()} s)"),
                          SfSlider(
                            min: 0.0,
                            max: 100.0,
                            value: riseAndHold!.frameLen,
                            interval: 20,
                            showTicks: true,
                            showLabels: true,
                            enableTooltip: true,
                            minorTicksPerInterval: 1,
                            onChanged: (dynamic value) {
                              setState(() {
                                riseAndHold!.frameLen = value;
                                phases = _createPhases();
                              });
                            },
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 28.0),
                        child: Column(
                          children: [
                            Text("Limit flow (${riseAndHold?.frameLen.round()} ml/s)"),
                            SfSlider(
                              min: 0.0,
                              max: 10.0,
                              value: riseAndHold!.frameLen,
                              interval: 1,
                              showTicks: true,
                              showLabels: true,
                              enableTooltip: true,
                              minorTicksPerInterval: 1,
                              onChanged: (dynamic value) {
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
                      Text("Pressure (${riseAndHold?.setVal.round()} bar)"),
                      SfSlider.vertical(
                        min: 0.0,
                        max: 10.0,
                        value: riseAndHold?.setVal,
                        interval: 2,
                        showTicks: true,
                        showLabels: true,
                        enableTooltip: true,
                        minorTicksPerInterval: 1,
                        onChanged: (dynamic value) {
                          setState(() {
                            riseAndHold!.setVal = value;
                            if (forcedRise != null) {
                              forcedRise!.setVal = value;
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
                            interval: 20,
                            showTicks: true,
                            showLabels: true,
                            enableTooltip: true,
                            minorTicksPerInterval: 1,
                            onChanged: (dynamic value) {
                              setState(() {
                                decline!.frameLen = value;
                                phases = _createPhases();
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
                        value: decline?.setVal,
                        interval: 2,
                        showTicks: true,
                        showLabels: true,
                        enableTooltip: true,
                        minorTicksPerInterval: 1,
                        onChanged: (dynamic value) {
                          setState(() {
                            decline!.setVal = value;
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

  Iterable<RangeAnnotationSegment<double>> _createPhases() {
    if (shotList.entries.isEmpty) {
      return [];
    }

    var stateChanges = shotList.entries.where((element) => element.subState.isNotEmpty).toList();
    // log.info("Phases= ${stateChanges.length}");

    int i = 0;
    var maxSampleTime = shotList.entries.last.sampleTimeCorrected;
    return stateChanges.map((from) {
      var toSampleTime = maxSampleTime;
      // og(from.subState);
      if (i < stateChanges.length - 1) {
        i++;
        toSampleTime = stateChanges[i].sampleTimeCorrected;
      }

      var col = theme.ThemeColors.statesColors[from.subState];
      var col2 = charts.ColorUtil.fromDartColor(col ?? theme.ThemeColors.backgroundColor);
      // col == null ? col! : charts.Color(r: 0xff, g: 50, b: i * 19, a: 100);
      return charts.RangeAnnotationSegment(
          from.sampleTimeCorrected, toSampleTime, charts.RangeAnnotationAxisType.domain,
          labelAnchor: charts.AnnotationLabelAnchor.end,
          color: col2,
          startLabel: from.subState,
          labelStyleSpec: charts.TextStyleSpec(
              fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.secondaryColor)),
          labelDirection: charts.AnnotationLabelDirection.vertical);
      // log.info("Phase ${element.subState}");
    });
  }
}
