import 'dart:convert';
import 'dart:developer';

import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/shotdecoder.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:flutter/material.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart'
    as charts;
import 'package:community_charts_flutter/community_charts_flutter.dart';
import 'package:despresso/ui/theme.dart' as theme;
import '../../model/services/ble/machine_service.dart';
import '../../service_locator.dart';

class ProfilesEditScreen extends StatefulWidget {
  De1ShotProfile profile;

  ProfilesEditScreen(De1ShotProfile this.profile, {Key? key}) : super(key: key);

  @override
  _ProfilesEditScreenState createState() {
    return _ProfilesEditScreenState(profile);
  }
}

class _ProfilesEditScreenState extends State<ProfilesEditScreen> {
  late ProfileService profileService;
  ShotList shotList = ShotList([]);
  late EspressoMachineService machineService;

  De1ShotProfile? _selectedProfile;

  Iterable<RangeAnnotationSegment<double>> phases = [];

  De1ShotProfile _profile;

  _ProfilesEditScreenState(De1ShotProfile this._profile);

  @override
  void initState() {
    super.initState();
    log('Init State ${_profile.shot_header.title}');
    machineService = getIt<EspressoMachineService>();
    profileService = getIt<ProfileService>();

    profileService.addListener(profileListener);
    log(profileService.currentProfile.toString());
    _selectedProfile = profileService.currentProfile;
    calcProfileGraph();
    phases = _createPhases();
  }

  @override
  void dispose() {
    super.dispose();

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
        title: Text('Profile Edit: ${_profile.shot_header.title}'),
      ),
      body: Scaffold(
        body: Column(
          children: [
            Expanded(
              flex: 5, // takes 30% of available width
              child: _buildGraphPressure(),
            ),
            Expanded(
              flex: 5, // takes 30% of available width
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [],
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
      margin: const EdgeInsets.only(left: 0.0),
      width: MediaQuery.of(context).size.width - 0,
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
        .map((p) => createKeyValue(
            p.name, "Duration: ${p.frameLen} s    Pressure: ${p.setVal} bar"))
        .toList();
  }

  void profileListener() {
    log('Profile updated');
    _selectedProfile = profileService.currentProfile;
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
    for (var frame in _selectedProfile!.shot_frames) {
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
    }
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

      var col = theme.Colors.statesColors[from.subState];
      var col2 =
          charts.ColorUtil.fromDartColor(col ?? theme.Colors.backgroundColor);
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
