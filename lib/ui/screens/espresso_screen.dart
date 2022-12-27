import 'dart:developer';

import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;

import '../../model/shotstate.dart';

class EspressoScreen extends StatefulWidget {
  @override
  _EspressoScreenState createState() => _EspressoScreenState();
}

class _EspressoScreenState extends State<EspressoScreen> {
  late CoffeeService coffeeSelectionService;
  late EspressoMachineService machineService;
  late ProfileService profileService;
  late ScaleService scaleService;

  ShotList shotList = ShotList([]);

  bool inShot = false;
  double baseTime = 0;

  String lastSubstate = '';

  String subState = "";
  _EspressoScreenState() {
    shotList.load("testshot.json");
  }
  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    machineService.addListener(() {
      setState(() {
        updateCoffee();
      });
    });
    profileService = getIt<ProfileService>();
    profileService.addListener(() {
      setState(() {});
    });

    coffeeSelectionService = getIt<CoffeeService>();
    coffeeSelectionService.addListener(() {
      setState(() {});
    });
    // Scale services is consumed as stream
    scaleService = getIt<ScaleService>();
  }

  void updateCoffee() => setState(() {
        if (machineService.state.coffeeState == EspressoMachineState.sleep ||
            machineService.state.coffeeState ==
                EspressoMachineState.disconnected) {
          return;
        }
        var shot = machineService.state.shot;
        // if (machineService.state.subState.isNotEmpty) {
        //   subState = machineService.state.subState;
        // }
        if (shot == null) {
          log('Shot null');
          return;
        }
        if (machineService.state.coffeeState == EspressoMachineState.idle) {
          inShot = false;
          if (shotList.entries.isNotEmpty &&
              shotList.saving == false &&
              shotList.saved == false) {
            shotFinished();
          }

          return;
        }
        if (!inShot) {
          log('Not Idle and not in Shot');
          inShot = true;
          shotList.clear();
          baseTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
          log("basetime $baseTime");
        }
        subState = machineService.state.subState;
        if (!(shot.sampleTimeCorrected > 0)) {
          if (lastSubstate != subState && subState.isNotEmpty) {
            log("SubState: $subState");
            lastSubstate = machineService.state.subState;
            shot.subState = lastSubstate;
          }

          shot.weight = scaleService.weight;
          shot.sampleTimeCorrected = shot.sampleTime - baseTime;
          // log("Sample ${shot!.sampleTimeCorrected} ${shot.weight}");
          shotList.add(shot);
        }
      });

  shotFinished() async {
    log("Save last shot");
    await shotList.saveData("testshot.json");
  }

  _createPhases() {
    if (shotList.entries.isEmpty) {
      return [];
    }
    shotList.entries.forEach((element) {
      if (element.subState.isNotEmpty) {
        log(element.subState + " " + element.sampleTimeCorrected.toString());
      }
    });
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
          col != null ? col! : theme.Colors.goodColor);
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

  List<charts.Series<ShotState, double>> _createData() {
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

  Widget _buildGraphTemp() {
    var ranges = _createPhases();
    var data = _createData();
    // data[2].setAttribute(charts.measureAxisIdKey, "secondaryMeasureAxisId");
    var flowChart = charts.LineChart(
      [data[2]],
      animate: true,
      behaviors: [
        // Define one domain and two measure annotations configured to render
        // labels in the chart margins.
        charts.RangeAnnotation([
          ...ranges,
          // charts.RangeAnnotationSegment(
          //     9.5, 12, charts.RangeAnnotationAxisType.domain,
          //     labelAnchor: charts.AnnotationLabelAnchor.end,
          //     color: const charts.Color(r: 0xff, g: 0, b: 0, a: 100),
          //     labelDirection: charts.AnnotationLabelDirection.vertical),
        ], defaultLabelPosition: charts.AnnotationLabelPosition.margin),
      ],
      secondaryMeasureAxis: charts.NumericAxisSpec(
        renderSpec: charts.GridlineRendererSpec(
          labelStyle: charts.TextStyleSpec(
              fontSize: 10,
              color:
                  charts.ColorUtil.fromDartColor(theme.Colors.secondaryColor)),
          lineStyle: charts.LineStyleSpec(
              thickness: 0,
              color:
                  charts.ColorUtil.fromDartColor(theme.Colors.secondaryColor)),
        ),
      ),
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
      height: 300,
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

  Widget _buildGraphPressure() {
    var flowChart = charts.LineChart(
      [_createData()[0]],
      animate: true,
      behaviors: [
        // Define one domain and two measure annotations configured to render
        // labels in the chart margins.
        charts.RangeAnnotation([
          charts.RangeAnnotationSegment(
              9.5, 12, charts.RangeAnnotationAxisType.measure,
              labelAnchor: charts.AnnotationLabelAnchor.end,
              color: const charts.Color(r: 0xff, g: 0, b: 0, a: 0x30),
              labelDirection: charts.AnnotationLabelDirection.vertical),
        ], defaultLabelPosition: charts.AnnotationLabelPosition.margin),
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
      height: 300,
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

  Widget _buildGraphFlow() {
    var data = _createData();
    var flowChart = charts.LineChart(
      [data[1], data[3]],
      animate: true,
      behaviors: [
        // Define one domain and two measure annotations configured to render
        // labels in the chart margins.
        charts.RangeAnnotation([
          charts.RangeAnnotationSegment(
              9.5, 12, charts.RangeAnnotationAxisType.measure,
              labelAnchor: charts.AnnotationLabelAnchor.end,
              color: const charts.Color(r: 0xff, g: 0, b: 0, a: 0x30),
              labelDirection: charts.AnnotationLabelDirection.vertical),
        ], defaultLabelPosition: charts.AnnotationLabelPosition.margin),
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
      height: 300,
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

  Widget _buildLiveInsights() {
    Widget insights;
    if (machineService.state.shot != null) {
      insights = Column(
        children: [
          Row(
            children: [
              const Text('State: ', style: theme.TextStyles.tabSecondary),
              Text(
                  machineService.state.coffeeState.name
                      .toString()
                      .toUpperCase(),
                  style: theme.TextStyles.tabPrimary),
            ],
          ),
          Row(
            children: [
              const Text('Op: ', style: theme.TextStyles.tabSecondary),
              Text(machineService.state.subState,
                  style: theme.TextStyles.tabPrimary),
            ],
          ),
          Row(
            children: [
              const Text('Pressure: ', style: theme.TextStyles.tabSecondary),
              Text(
                  '${machineService.state.shot!.groupPressure.toStringAsFixed(1)} bar',
                  style: theme.TextStyles.tabPrimary),
            ],
          ),
          Row(
            children: [
              const Text('Flow: ', style: theme.TextStyles.tabSecondary),
              Text(
                  '${machineService.state.shot!.groupFlow.toStringAsFixed(2)} ml/s',
                  style: theme.TextStyles.tabPrimary),
            ],
          ),
          Row(
            children: [
              const Text('Mix Temp: ', style: theme.TextStyles.tabSecondary),
              Text(
                  '${machineService.state.shot!.mixTemp.toStringAsFixed(2)} °C',
                  style: theme.TextStyles.tabPrimary),
            ],
          ),
          Row(
            children: [
              const Text('Head Temp: ', style: theme.TextStyles.tabSecondary),
              Text(
                  '${machineService.state.shot!.headTemp.toStringAsFixed(2)} °C',
                  style: theme.TextStyles.tabPrimary),
            ],
          ),
          Row(
            children: [
              const Text('Water: ', style: theme.TextStyles.tabSecondary),
              Text(
                  '${machineService.state.water?.getLevelPercent()}% / ${machineService.state.water?.waterLevel}',
                  style: theme.TextStyles.tabPrimary),
            ],
          ),
        ],
      );
    } else {
      insights = Text(
          "${machineService.state.coffeeState.name} ${machineService.state.subState}",
          style: theme.TextStyles.tabPrimary);
    }
    return insights;
  }

  Row _buildScaleInsight() {
    return Row(
      children: [
        const Spacer(),
        StreamBuilder<WeightMeassurement>(
          stream: scaleService.stream,
          initialData: WeightMeassurement(0, 0),
          builder: (BuildContext context,
              AsyncSnapshot<WeightMeassurement> snapshot) {
            return Column(
              children: <Widget>[
                Row(
                  children: [
                    const Text('Weight: ',
                        style: theme.TextStyles.tabSecondary),
                    Text('${snapshot.data!.weight.toStringAsFixed(2)}g',
                        style: theme.TextStyles.tabSecondary),
                  ],
                ),
                Row(
                  children: [
                    const Text('Flow: ', style: theme.TextStyles.tabSecondary),
                    Text('${snapshot.data!.flow.toStringAsFixed(2)}g/s',
                        style: theme.TextStyles.tabSecondary)
                  ],
                ),
              ],
            );
          },
        ),
        const Spacer(),
      ],
    );
  }

  var pressAttention = true;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.Colors.backgroundColor,
        ),
        body: Row(
          children: [
            Expanded(
              flex: 8, // takes 30% of available width
              child: Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildGraphPressure(),
                  ),
                  Expanded(
                    flex: 1,
                    child: _buildGraphFlow(),
                  ),
                  Expanded(
                    flex: 1,
                    child: _buildGraphTemp(),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2, // takes 30% of available width
              child: Column(
                  children: [_buildLiveInsights(), _buildScaleInsight()]),
            ),
          ],
        ),
      ),
    );
  }
}
