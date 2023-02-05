import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:flutter/material.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:despresso/ui/theme.dart' as theme;

class ProfileGraphWidget extends StatefulWidget {
  final De1ShotProfile selectedProfile;
  const ProfileGraphWidget({
    Key? key,
    required this.selectedProfile,
  }) : super(key: key);

  @override
  State<ProfileGraphWidget> createState() => ProfileGraphWidgetState(selectedProfile);
}

class ProfileGraphWidgetState extends State<ProfileGraphWidget> {
  ProfileGraphWidgetState(this._selectedProfile);

  ShotList shotList = ShotList([]);
  final De1ShotProfile? _selectedProfile;

  @override
  Widget build(BuildContext context) {
    return _buildGraphPressure();
  }

  Widget _buildGraphPressure() {
    Iterable<charts.RangeAnnotationSegment<double>> phases = [];
    calcProfileGraph();
    phases = _createPhases();
    const secondaryMeasureAxisId = 'secondaryMeasureAxisId';
    var data = _createSeriesData();

    var flowChart = charts.LineChart(
      [data[0], data[2]..setAttribute(charts.measureAxisIdKey, secondaryMeasureAxisId)],
      animate: false,
      behaviors: [
        charts.SeriesLegend(),
        // Define one domain and two measure annotations configured to render
        // labels in the chart margins.
        charts.RangeAnnotation([...phases], defaultLabelPosition: charts.AnnotationLabelPosition.margin),
      ],
      primaryMeasureAxis: charts.NumericAxisSpec(
        renderSpec: charts.GridlineRendererSpec(
          labelStyle: charts.TextStyleSpec(
              fontSize: 10, color: charts.ColorUtil.fromDartColor(Theme.of(context).colorScheme.primary)),
          lineStyle: charts.LineStyleSpec(
              thickness: 0, color: charts.ColorUtil.fromDartColor(Theme.of(context).colorScheme.secondary)),
        ),
      ),
      secondaryMeasureAxis: charts.NumericAxisSpec(
        renderSpec: charts.GridlineRendererSpec(
          labelStyle: charts.TextStyleSpec(
              fontSize: 10, color: charts.ColorUtil.fromDartColor(Theme.of(context).colorScheme.primary)),
          lineStyle: charts.LineStyleSpec(
              thickness: 0, color: charts.ColorUtil.fromDartColor(Theme.of(context).colorScheme.secondary)),
        ),
      ),
      domainAxis: charts.NumericAxisSpec(
        renderSpec: charts.GridlineRendererSpec(
          labelStyle: charts.TextStyleSpec(
              fontSize: 10, color: charts.ColorUtil.fromDartColor(Theme.of(context).colorScheme.primary)),
          lineStyle: charts.LineStyleSpec(
              thickness: 0, color: charts.ColorUtil.fromDartColor(Theme.of(context).colorScheme.secondary)),
        ),
      ),
    );

    return Container(
      // height: 100,
      margin: const EdgeInsets.only(left: 10.0),
      //width: MediaQuery.of(context).size.width - 105,
      decoration: BoxDecoration(
        color: Colors.black12,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: flowChart,
    );
  }

  List<charts.Series<ShotState, double>> _createSeriesData() {
    return [
      charts.Series<ShotState, double>(
        id: 'Pressure',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.groupPressure,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.pressureColor),
        strokeWidthPxFn: (_, __) => 3,
        data: shotList.entries,
      ),
      charts.Series<ShotState, double>(
        id: 'Flow',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.groupFlow,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.flowColor),
        strokeWidthPxFn: (_, __) => 3,
        data: shotList.entries,
      ),
      charts.Series<ShotState, double>(
        id: 'Temp',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.headTemp,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.tempColor),
        strokeWidthPxFn: (_, __) => 3,
        data: shotList.entries,
      ),
      charts.Series<ShotState, double>(
        id: 'Weight',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.weight,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.tempColor),
        strokeWidthPxFn: (_, __) => 3,
        data: shotList.entries,
      ),
    ];
  }

  calcProfileGraph() {
    shotList.clear();
    var time = 0.0;
    var frame = _selectedProfile!.shotFrames.first;

    ShotState shotState = ShotState(
        time, time, 0, 0, frame.temp, frame.temp, frame.temp, frame.temp, 0, 0, frame.frameToWrite, 0, 0, frame.name);

    shotList.entries.add(shotState);
    for (var frame in _selectedProfile!.shotFrames) {
      time += frame.frameLen;
      ShotState shotState = ShotState(time, time, frame.setVal, frame.setVal, frame.temp, frame.temp, frame.temp,
          frame.temp, 0, 0, 0, 0, 0, frame.name);
      shotList.entries.add(shotState);
    }
  }

  Iterable<charts.RangeAnnotationSegment<double>> _createPhases() {
    if (shotList.entries.isEmpty) {
      return [];
    }
    // shotList.entries.forEach((element) {
    //   if (element.subState.isNotEmpty) {
    //     log.info(element.subState + " " + element.sampleTimeCorrected.toString());
    //   }
    // });
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
              fontSize: 10,
              // color: charts.ColorUtil.fromDartColor(theme.ThemeColors.secondaryColor)),
              color: charts.ColorUtil.fromDartColor(Color(0xFFD0BCFF))),
          labelDirection: charts.AnnotationLabelDirection.vertical);
      // log.info("Phase ${element.subState}");
    });
  }
}
