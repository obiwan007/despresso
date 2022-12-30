import 'dart:convert';
import 'dart:developer';

import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/shotdecoder.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart'
    as charts;
import 'package:community_charts_flutter/community_charts_flutter.dart';
import 'package:despresso/ui/theme.dart' as theme;
import '../../model/services/ble/machine_service.dart';
import '../../service_locator.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({Key? key}) : super(key: key);

  @override
  _ProfilesScreenState createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  late ProfileService profileService;
  ShotList shotList = ShotList([]);
  late EspressoMachineService machineService;

  De1ShotProfile? _selectedProfile = null;

  Iterable<RangeAnnotationSegment<double>> phases = [];
  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    profileService = getIt<ProfileService>();

    profileService.addListener(profileListener);
    log(profileService.currentProfile.toString());
    _selectedProfile = profileService.profiles.first;
  }

  @override
  void dispose() {
    super.dispose();
    // TODO: implement dispose
    machineService.removeListener(profileListener);
    log('Disposed profile');
  }

  @override
  Widget build(BuildContext context) {
    var items = profileService.profiles
        .map((p) => DropdownMenuItem(
              value: p,
              child: Text(p.shot_header.title),
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
      ),
      body: Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 4, // takes 30% of available width
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButton(
                          isExpanded: true,
                          alignment: Alignment.centerLeft,
                          value: _selectedProfile,
                          items: items,
                          onChanged: (value) {
                            setState(() {
                              _selectedProfile = value!;
                              calcProfileGraph();
                              phases = _createPhases();
                            });
                          },
                          hint: Text("Select item")),
                      createKeyValue(
                          "Notes", _selectedProfile!.shot_header.notes),
                      createKeyValue("Beverage",
                          _selectedProfile!.shot_header.beverage_type),
                      createKeyValue(
                          "Type", _selectedProfile!.shot_header.type),
                      createKeyValue("Max Flow",
                          _selectedProfile!.shot_header.maximumFlow.toString()),
                      createKeyValue(
                          "Max Pressure",
                          _selectedProfile!.shot_header.minimumPressure
                              .toString()),
                      createKeyValue(
                          "Target Volume",
                          _selectedProfile!.shot_header.target_volume
                              .toString()),
                      createKeyValue(
                          "Target Weight",
                          _selectedProfile!.shot_header.target_weight
                              .toString()),
                      // ...createSteps(),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 6, // takes 30% of available width
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildGraphPressure(),
                  ),
                  Expanded(
                    flex: 6,
                    child: const Text('!!!!!!!!!!!!!!!!! Go back!'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphPressure() {
    const secondaryMeasureAxisId = 'secondaryMeasureAxisId';
    var data = _createSeriesData();
    var flowChart = charts.LineChart(
      [
        data[0],
        data[2]..setAttribute(charts.measureAxisIdKey, secondaryMeasureAxisId)
      ],
      animate: false,
      behaviors: [
        charts.SeriesLegend(),
        // Define one domain and two measure annotations configured to render
        // labels in the chart margins.
        charts.RangeAnnotation([...phases],
            defaultLabelPosition: charts.AnnotationLabelPosition.margin),
      ],
      primaryMeasureAxis: charts.NumericAxisSpec(
        renderSpec: charts.GridlineRendererSpec(
          labelStyle: charts.TextStyleSpec(
              fontSize: 10,
              color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
          lineStyle: charts.LineStyleSpec(
              thickness: 0,
              color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
        ),
      ),
      secondaryMeasureAxis: charts.NumericAxisSpec(
        renderSpec: charts.GridlineRendererSpec(
          labelStyle: charts.TextStyleSpec(
              fontSize: 10,
              color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
          lineStyle: charts.LineStyleSpec(
              thickness: 0,
              color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
        ),
      ),
      domainAxis: charts.NumericAxisSpec(
        renderSpec: charts.GridlineRendererSpec(
          labelStyle: charts.TextStyleSpec(
              fontSize: 10,
              color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
          lineStyle: charts.LineStyleSpec(
              thickness: 0,
              color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
        ),
      ),
    );

    return Container(
      // height: 100,
      margin: const EdgeInsets.only(left: 10.0),
      width: MediaQuery.of(context).size.width - 105,
      decoration: BoxDecoration(
        color: theme.Colors.tabColor,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: flowChart,
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
    return _selectedProfile!.shot_frames
        .map((p) => createKeyValue(p.frameToWrite.toString(),
            "${p.name}\nT: ${p.temp}\nV: ${p.setVal}"))
        .toList();
  }

  void profileListener() {
    log('Profile updated');
  }

  List<charts.Series<ShotState, double>> _createSeriesData() {
    return [
      charts.Series<ShotState, double>(
        id: 'Pressure',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.groupPressure,
        colorFn: (_, __) =>
            charts.ColorUtil.fromDartColor(theme.Colors.pressureColor),
        strokeWidthPxFn: (_, __) => 3,
        data: shotList.entries,
      ),
      charts.Series<ShotState, double>(
        id: 'Flow',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.groupFlow,
        colorFn: (_, __) =>
            charts.ColorUtil.fromDartColor(theme.Colors.flowColor),
        strokeWidthPxFn: (_, __) => 3,
        data: shotList.entries,
      ),
      charts.Series<ShotState, double>(
        id: 'Temp',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.headTemp,
        colorFn: (_, __) =>
            charts.ColorUtil.fromDartColor(theme.Colors.tempColor),
        strokeWidthPxFn: (_, __) => 3,
        data: shotList.entries,
      ),
      charts.Series<ShotState, double>(
        id: 'Weight',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.weight,
        colorFn: (_, __) =>
            charts.ColorUtil.fromDartColor(theme.Colors.tempColor),
        strokeWidthPxFn: (_, __) => 3,
        data: shotList.entries,
      ),
    ];
  }

  void calcProfileGraph() {
    // this.sampleTime,
    //   this.sampleTimeCorrected,
    //   this.groupPressure,
    //   this.groupFlow,
    //   this.mixTemp,
    //   this.headTemp,
    //   this.setMixTemp,
    //   this.setHeadTemp,
    //   this.setGroupPressure,
    //   this.setGroupFlow,
    //   this.frameNumber,
    //   this.steamTemp,
    //   this.weight,
    //   this.subState

    // int frameToWrite = 0;
    // int flag = 0;
    // double setVal = 0; // {
    // double temp = 0; // {
    // double frameLen = 0.0; // convert_F8_1_7_to_float
    // double triggerVal = 0; // {
    // double maxVol = 0.0; // convert_bottom_10_of_U10P0
    // String name = "";
    // String pump = "";
    // String sensor = "";
    // String transition = "";
    shotList.clear();
    var time = 0.0;
    var frame = _selectedProfile!.shot_frames.first;

    ShotState shotState = ShotState(time, time, 0, 0, frame.temp, frame.temp,
        frame.temp, frame.temp, 0, 0, frame.frameToWrite, 0, 0, frame.name);

    shotList.entries.add(shotState);
    _selectedProfile!.shot_frames.forEach((frame) {
      time += frame.frameLen;
      ShotState shotState = ShotState(
          time,
          time,
          frame.setVal,
          frame.setVal,
          frame.temp,
          frame.temp,
          frame.temp,
          frame.temp,
          0,
          0,
          0,
          0,
          0,
          frame.name);
      shotList.entries.add(shotState);
    });
  }

  Iterable<RangeAnnotationSegment<double>> _createPhases() {
    if (shotList.entries.isEmpty) {
      return [];
    }
    // shotList.entries.forEach((element) {
    //   if (element.subState.isNotEmpty) {
    //     log(element.subState + " " + element.sampleTimeCorrected.toString());
    //   }
    // });
    var stateChanges = shotList.entries
        .where((element) => element.subState.isNotEmpty)
        .toList();
    // log("Phases= ${stateChanges.length}");

    int i = 0;
    var maxSampleTime = shotList.entries.last.sampleTimeCorrected;
    return stateChanges.map((from) {
      var toSampleTime = maxSampleTime;
      // og(from.subState);
      if (i < stateChanges.length - 1) {
        i++;
        toSampleTime = stateChanges[i].sampleTimeCorrected;
      }
      var to = stateChanges[i];

      var col = theme.Colors.statesColors[from.subState];
      var col2 = charts.ColorUtil.fromDartColor(
          col != null ? col! : theme.Colors.backgroundColor);
      // col == null ? col! : charts.Color(r: 0xff, g: 50, b: i * 19, a: 100);
      return charts.RangeAnnotationSegment(from.sampleTimeCorrected,
          toSampleTime, charts.RangeAnnotationAxisType.domain,
          labelAnchor: charts.AnnotationLabelAnchor.end,
          color: col2,
          startLabel: from.subState,
          labelStyleSpec: charts.TextStyleSpec(
              fontSize: 10,
              color:
                  charts.ColorUtil.fromDartColor(theme.Colors.secondaryColor)),
          labelDirection: charts.AnnotationLabelDirection.vertical);
      // log("Phase ${element.subState}");
    });
  }
}
