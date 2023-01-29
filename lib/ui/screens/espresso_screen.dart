import 'dart:developer';
import 'dart:math' as math;

import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;

import 'package:despresso/ui/widgets/key_value.dart';
import 'package:despresso/ui/widgets/legend_list.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;

import 'package:fl_chart/fl_chart.dart';

import '../../devices/decent_de1.dart';
import '../../model/shotstate.dart';
import '../widgets/start_stop_button.dart';

class EspressoScreen extends StatefulWidget {
  const EspressoScreen({super.key});

  @override
  EspressoScreenState createState() => EspressoScreenState();
}

class EspressoScreenState extends State<EspressoScreen> {
  late CoffeeService coffeeSelectionService;
  late EspressoMachineService machineService;
  late ProfileService profileService;
  late ScaleService scaleService;
  late SettingsService settingsService;

  double baseTime = 0;

  String lastSubstate = '';

  String subState = "";

  bool refillAnounced = false;

  bool stopTriggered = false;

  double maxTime = 30;

  EspressoScreenState();

  @override
  void dispose() {
    super.dispose();
    machineService.removeListener(updateMachine);
    profileService.removeListener(updateProfile);
    coffeeSelectionService.removeListener(updateCoffeeSelection);
    log('Disposed espresso');
  }

  updateMachine() {
    setState(() {
      updateCoffee();
    });
  }

  updateProfile() {
    setState(() {});
  }

  updateCoffeeSelection() {
    setState(() {});
  }

  @override
  initState() {
    super.initState();
    settingsService = getIt<SettingsService>();
    machineService = getIt<EspressoMachineService>();
    machineService.addListener(updateMachine);

    profileService = getIt<ProfileService>();
    profileService.addListener(updateProfile);

    coffeeSelectionService = getIt<CoffeeService>();
    coffeeSelectionService.addListener(updateCoffeeSelection);
    // Scale services is consumed as stream
    scaleService = getIt<ScaleService>();
  }

  // loadShotData() async {
  //   await shotList.load("testshot.json");
  //   setState(() {});
  // }

  void updateCoffee() => setState(() {
        checkForRefill();
      });
  void triggerEndOfShot() {
    log("Idle mode initiated because of weight", error: {DateTime.now()});

    machineService.de1?.requestState(De1StateEnum.idle);
  }

  void checkForRefill() {
    if (refillAnounced == false && machineService.state.coffeeState == EspressoMachineState.refill) {
      var snackBar = SnackBar(
          content: const Text('Refill the water tank'),
          action: SnackBarAction(
            label: 'ok',
            onPressed: () {
              // Some code to undo the change.
            },
          ));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      refillAnounced = true;
    }
  }

  Iterable<VerticalRangeAnnotation> _createPhasesFl() {
    if (machineService.shotList.entries.isEmpty) {
      return [];
    }

    var stateChanges = machineService.shotList.entries.where((element) => element.subState.isNotEmpty).toList();

    int i = 0;
    var maxSampleTime = machineService.shotList.entries.last.sampleTimeCorrected;
    return stateChanges.map((from) {
      var toSampleTime = maxSampleTime;

      if (i < stateChanges.length - 1) {
        i++;
        toSampleTime = stateChanges[i].sampleTimeCorrected;
      }

      var col = theme.ThemeColors.statesColors[from.subState];
      var col2 = col ?? theme.ThemeColors.goodColor;
      // col == null ? col! : charts.Color(r: 0xff, g: 50, b: i * 19, a: 100);
      return VerticalRangeAnnotation(
        x1: from.sampleTimeCorrected,
        x2: toSampleTime,
        color: col2,
      );

      // return charts.RangeAnnotationSegment(
      //     from.sampleTimeCorrected, toSampleTime, charts.RangeAnnotationAxisType.domain,
      //     labelAnchor: charts.AnnotationLabelAnchor.end,
      //     color: col2,
      //     startLabel: from.subState,
      //     labelStyleSpec: charts.TextStyleSpec(
      //         fontSize: 10, color: charts.ColorUtil.fromDartColor(Theme.of(context).colorScheme.primary)),
      //     labelDirection: charts.AnnotationLabelDirection.vertical);
      // log("Phase ${element.subState}");
    });
  }

  Iterable<charts.RangeAnnotationSegment<double>> _createPhases() {
    if (machineService.shotList.entries.isEmpty) {
      return [];
    }

    var stateChanges = machineService.shotList.entries.where((element) => element.subState.isNotEmpty).toList();

    int i = 0;
    var maxSampleTime = machineService.shotList.entries.last.sampleTimeCorrected;
    return stateChanges.map((from) {
      var toSampleTime = maxSampleTime;

      if (i < stateChanges.length - 1) {
        i++;
        toSampleTime = stateChanges[i].sampleTimeCorrected;
      }

      var col = theme.ThemeColors.statesColors[from.subState];
      var col2 = charts.ColorUtil.fromDartColor(col ?? theme.ThemeColors.goodColor);
      // col == null ? col! : charts.Color(r: 0xff, g: 50, b: i * 19, a: 100);
      return charts.RangeAnnotationSegment(
          from.sampleTimeCorrected, toSampleTime, charts.RangeAnnotationAxisType.domain,
          labelAnchor: charts.AnnotationLabelAnchor.end,
          color: col2,
          startLabel: from.subState,
          labelStyleSpec: charts.TextStyleSpec(
              fontSize: 10, color: charts.ColorUtil.fromDartColor(Theme.of(context).colorScheme.primary)),
          labelDirection: charts.AnnotationLabelDirection.vertical);
      // log("Phase ${element.subState}");
    });
  }

  Map<String, charts.Series<ShotState, double>> _createData() {
    return {
      "pressure": charts.Series<ShotState, double>(
        id: 'Pressure [bar]',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.groupPressure,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.pressureColor),
        strokeWidthPxFn: (_, __) => 3,
        data: machineService.shotList.entries,
      ),
      "flow": charts.Series<ShotState, double>(
        id: 'Flow [ml/s]',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.groupFlow,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.flowColor),
        strokeWidthPxFn: (_, __) => 3,
        data: machineService.shotList.entries,
      ),
      "temp": charts.Series<ShotState, double>(
        id: 'Temp [°C]',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.headTemp,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.tempColor),
        strokeWidthPxFn: (_, __) => 3,
        data: machineService.shotList.entries,
      ),
      "weight": charts.Series<ShotState, double>(
        id: 'Weight [g]',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.weight,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.weightColor),
        strokeWidthPxFn: (_, __) => 3,
        data: machineService.shotList.entries,
      ),
      "flowG": charts.Series<ShotState, double>(
        id: 'Flow [g/s]',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.flowWeight,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.weightColor),
        strokeWidthPxFn: (_, __) => 3,
        data: machineService.shotList.entries,
      ),
      "flowSet": charts.Series<ShotState, double>(
        id: 'SetFlow [ml/s]',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.setGroupFlow,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.flowColor),
        dashPatternFn: (_, __) => [5, 5],
        strokeWidthPxFn: (_, __) => 3,
        data: machineService.shotList.entries,
      ),
      "pressureSet": charts.Series<ShotState, double>(
        id: 'SetPressure [bar]',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.setGroupPressure,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.pressureColor),
        dashPatternFn: (datum, index) => [5, 5],
        strokeWidthPxFn: (_, __) => 3,
        data: machineService.shotList.entries,
      ),
      "tempSet": charts.Series<ShotState, double>(
        id: 'SetTemp [°C]',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.setHeadTemp,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.tempColor),
        strokeWidthPxFn: (_, __) => 3,
        dashPatternFn: (datum, index) => [5, 5],
        data: machineService.shotList.entries,
      ),
    };
  }

  Map<String, List<FlSpot>> _createDataFlCharts() {
    return {
      "pressure": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.groupPressure)).toList(),
      "pressureSet":
          machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.setGroupPressure)).toList(),
      "flow": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.groupFlow)).toList(),
      "flowSet": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.setGroupFlow)).toList(),
      "temp": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.headTemp)).toList(),
      "tempSet": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.setHeadTemp)).toList(),
      "weight": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.weight)).toList(),
      "flowG": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.flowWeight)).toList(),
      // charts.Series<ShotState, double>(
      //   id: 'Pressure [bar]',
      //   domainFn: (ShotState point, _) => point.sampleTimeCorrected,
      //   measureFn: (ShotState point, _) => point.groupPressure,
      //   colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.pressureColor),
      //   strokeWidthPxFn: (_, __) => 3,
      //   data: machineService.shotList.entries,
      // ),
      // "flow": charts.Series<ShotState, double>(
      //   id: 'Flow [ml/s]',
      //   domainFn: (ShotState point, _) => point.sampleTimeCorrected,
      //   measureFn: (ShotState point, _) => point.groupFlow,
      //   colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.flowColor),
      //   strokeWidthPxFn: (_, __) => 3,
      //   data: machineService.shotList.entries,
      // ),
      // "temp": charts.Series<ShotState, double>(
      //   id: 'Temp [°C]',
      //   domainFn: (ShotState point, _) => point.sampleTimeCorrected,
      //   measureFn: (ShotState point, _) => point.headTemp,
      //   colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.tempColor),
      //   strokeWidthPxFn: (_, __) => 3,
      //   data: machineService.shotList.entries,
      // ),
      // "weight": charts.Series<ShotState, double>(
      //   id: 'Weight [g]',
      //   domainFn: (ShotState point, _) => point.sampleTimeCorrected,
      //   measureFn: (ShotState point, _) => point.weight,
      //   colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.weightColor),
      //   strokeWidthPxFn: (_, __) => 3,
      //   data: machineService.shotList.entries,
      // ),
      // "flowG": charts.Series<ShotState, double>(
      //   id: 'Flow [g/s]',
      //   domainFn: (ShotState point, _) => point.sampleTimeCorrected,
      //   measureFn: (ShotState point, _) => point.flowWeight,
      //   colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.weightColor),
      //   strokeWidthPxFn: (_, __) => 3,
      //   data: machineService.shotList.entries,
      // ),
      // "flowSet": charts.Series<ShotState, double>(
      //   id: 'SetFlow [ml/s]',
      //   domainFn: (ShotState point, _) => point.sampleTimeCorrected,
      //   measureFn: (ShotState point, _) => point.setGroupFlow,
      //   colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.flowColor),
      //   dashPatternFn: (_, __) => [5, 5],
      //   strokeWidthPxFn: (_, __) => 3,
      //   data: machineService.shotList.entries,
      // ),
      // "pressureSet": charts.Series<ShotState, double>(
      //   id: 'SetPressure [bar]',
      //   domainFn: (ShotState point, _) => point.sampleTimeCorrected,
      //   measureFn: (ShotState point, _) => point.setGroupPressure,
      //   colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.pressureColor),
      //   dashPatternFn: (datum, index) => [5, 5],
      //   strokeWidthPxFn: (_, __) => 3,
      //   data: machineService.shotList.entries,
      // ),
      // "tempSet": charts.Series<ShotState, double>(
      //   id: 'SetTemp [°C]',
      //   domainFn: (ShotState point, _) => point.sampleTimeCorrected,
      //   measureFn: (ShotState point, _) => point.setHeadTemp,
      //   colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.ThemeColors.tempColor),
      //   strokeWidthPxFn: (_, __) => 3,
      //   dashPatternFn: (datum, index) => [5, 5],
      //   data: machineService.shotList.entries,
      // ),
    };
  }

  _buildGraphs() {
    var ranges = _createPhasesFl();
    var data = _createDataFlCharts();

    try {
      var maxData = data["pressure"]!.last;
      var t = maxData.x;

      if (machineService.inShot == true) {
        var corrected = (t ~/ 5.0).toInt() * 5.0 + 5;
        maxTime = math.max(30, corrected);
      } else {
        maxTime = t;
      }
    } catch (ex) {
      maxTime = 0;
    }

//     log("Maxtime: $maxTime $corrected A ${(t).toInt()}  ${(t ~/ 5).toInt()}");
    if (settingsService.graphSingle == false) {
      // var temp = _buildGraphTemp(data, ranges);
      // var flow = _buildGraphFlow(data, ranges);
      // var pressure = _buildGraphPressure(data, ranges);

      // return {"temp": temp, "flow": flow, "pressure": pressure};
    } else {
      var single = _buildGraphSingleFlCharts(data, maxTime, ranges);
      return {"single": single};
    }
  }

  _buildGraphs2() {
    var ranges = _createPhases();
    var data = _createData();

    try {
      var maxData = data["flow"]!.data.last;
      var t = maxData.sampleTimeCorrected;

      if (machineService.inShot == true) {
        var corrected = (t ~/ 5.0).toInt() * 5.0 + 5;
        maxTime = math.max(30, corrected);
      } else {
        maxTime = t;
      }
    } catch (ex) {
      maxTime = 0;
    }

//     log("Maxtime: $maxTime $corrected A ${(t).toInt()}  ${(t ~/ 5).toInt()}");
    if (settingsService.graphSingle == false) {
      var temp = _buildGraphTemp(data, ranges);
      var flow = _buildGraphFlow(data, ranges);
      var pressure = _buildGraphPressure(data, ranges);

      return {"temp": temp, "flow": flow, "pressure": pressure};
    } else {
      var single = _buildGraphSingle(data, ranges);
      return {"single": single};
    }
  }

  Widget _buildGraphTemp(
      Map<String, charts.Series<ShotState, double>> data, Iterable<charts.RangeAnnotationSegment<double>> ranges) {
    var flowChart = charts.LineChart(
      [data["temp"]!, data["tempSet"]!],
      animate: false,
      behaviors: [
        // Define one domain and two measure annotations configured to render
        // labels in the chart margins.
        charts.SeriesLegend(),
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
              fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.secondaryColor)),
          lineStyle: charts.LineStyleSpec(
              thickness: 0, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.secondaryColor)),
        ),
      ),
      primaryMeasureAxis: charts.NumericAxisSpec(
        tickProviderSpec: const charts.BasicNumericTickProviderSpec(zeroBound: false),
        renderSpec: charts.GridlineRendererSpec(
          labelStyle:
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
          lineStyle:
              charts.LineStyleSpec(thickness: 0, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
        ),
      ),
      domainAxis: charts.NumericAxisSpec(
        viewport: charts.NumericExtents(0, maxTime),
        renderSpec: charts.GridlineRendererSpec(
          labelStyle:
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
          lineStyle:
              charts.LineStyleSpec(thickness: 0, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
        ),
      ),
    );

    return Container(
      height: 300,
      margin: const EdgeInsets.only(left: 10.0),
      width: MediaQuery.of(context).size.width - 105,
      decoration: BoxDecoration(
        color: theme.ThemeColors.graphBackground,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: flowChart,
    );
  }

  LineChartBarData sinLine(List<FlSpot> points, double barWidth, Color col) {
    return LineChartBarData(
      spots: points,
      dotData: FlDotData(
        show: false,
      ),
      barWidth: barWidth,
      isCurved: false,
      color: col,
    );
  }

  Widget _buildGraphSingleFlCharts(
      Map<String, List<FlSpot>> data, double maxTime, Iterable<VerticalRangeAnnotation> ranges) {
    var flowChart1 = LineChart(
      LineChartData(
        minY: 0,
        // maxY: 15,
        minX: data["pressure"]!.first.x,
        maxX: maxTime,
        lineTouchData: LineTouchData(enabled: false),
        clipData: FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
        ),
        lineBarsData: [
          sinLine(data["pressure"]!, 4, theme.ThemeColors.pressureColor),
          sinLine(data["pressureSet"]!, 2, theme.ThemeColors.pressureColor),
          sinLine(data["flow"]!, 4, theme.ThemeColors.flowColor),
          sinLine(data["flowSet"]!, 2, theme.ThemeColors.flowColor),
          sinLine(data["flowG"]!, 2, theme.ThemeColors.weightColor),
        ],
        rangeAnnotations: RangeAnnotations(
          verticalRangeAnnotations: [
            ...ranges,
          ],
          // horizontalRangeAnnotations: [
          //   HorizontalRangeAnnotation(
          //     y1: 2,
          //     y2: 3,
          //     color: const Color(0xffEEF3FE),
          //   ),
          // ],
        ),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          // bottomTitles: AxisTitles(
          //   axisNameWidget: const Text(
          //     'Time/s',
          //     textAlign: TextAlign.left,
          //     // style: TextStyle(
          //     //     // fontSize: 15,
          //     //     ),
          //   ),
          //   sideTitles: SideTitles(
          //     showTitles: true,
          //     getTitlesWidget: bottomTitleWidgets,
          //     reservedSize: 36,
          //   ),
          // ),
          show: true,
          leftTitles: AxisTitles(
            axisNameSize: 25,
            axisNameWidget: Text(
              'Flow [ml/s] / Pressure [bar]',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: leftTitleWidgets,
              reservedSize: 56,
            ),
          ),
        ),
      ),
    );

    var flowChart2 = LineChart(
      LineChartData(
        minY: 0,
        // maxY: 15,
        minX: data["pressure"]!.first.x,
        maxX: maxTime,
        lineTouchData: LineTouchData(enabled: false),
        clipData: FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
        ),
        lineBarsData: [
          sinLine(data["weight"]!, 2, theme.ThemeColors.weightColor),
          sinLine(data["temp"]!, 4, theme.ThemeColors.tempColor),
          sinLine(data["tempSet"]!, 2, theme.ThemeColors.tempColor),
        ],
        titlesData: FlTitlesData(
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            axisNameSize: 25,
            axisNameWidget: Text(
              'Time/s',
              style: Theme.of(context).textTheme.labelSmall,
              // style: TextStyle(
              //     // fontSize: 15,
              //     ),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: bottomTitleWidgets,
              reservedSize: 26,
            ),
          ),
          show: true,
          leftTitles: AxisTitles(
            axisNameSize: 25,
            axisNameWidget: Text(
              'Weight [g] / Temp [°C]',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: leftTitleWidgets,
              reservedSize: 56,
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 30,
            child: LegendsListWidget(
              legends: [
                Legend('Pressure', theme.ThemeColors.pressureColor),
                Legend('Flow', theme.ThemeColors.flowColor),
                Legend('Weight', theme.ThemeColors.weightColor),
                Legend('Temp', theme.ThemeColors.tempColor),
              ],
            ),
          ),
          Expanded(flex: 1, child: flowChart1),
          const SizedBox(height: 20),
          Expanded(flex: 1, child: flowChart2),
        ],
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 6,
      child: Text(meta.formattedValue, style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16,
      child: Text(meta.formattedValue, style: style),
    );
  }

  Widget _buildGraphSingle(
      Map<String, charts.Series<ShotState, double>> data, Iterable<charts.RangeAnnotationSegment<double>> ranges) {
    const secondaryMeasureAxisId = 'secondaryMeasureAxisId';
    var flowChart = charts.LineChart(
      [
        data["pressure"]!,
        data["pressureSet"]!,
        data["temp"]!..setAttribute(charts.measureAxisIdKey, secondaryMeasureAxisId), // temp axis,
        data["tempSet"]!..setAttribute(charts.measureAxisIdKey, secondaryMeasureAxisId), // temp axis
        data["flowSet"]!,
        data["flow"]!,
        data["flowG"]!,
        data["weight"]!..setAttribute(charts.measureAxisIdKey, secondaryMeasureAxisId), // temp axis,
      ],
      animate: false,
      behaviors: [
        // Define one domain and two measure annotations configured to render
        // labels in the chart margins.
        charts.SeriesLegend(
          position: charts.BehaviorPosition.end,
        ),
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
              fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.secondaryColor)),
          lineStyle: charts.LineStyleSpec(
              thickness: 0, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.secondaryColor)),
        ),
      ),
      primaryMeasureAxis: charts.NumericAxisSpec(
        tickProviderSpec: const charts.BasicNumericTickProviderSpec(zeroBound: false),
        renderSpec: charts.GridlineRendererSpec(
          labelStyle:
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
          lineStyle:
              charts.LineStyleSpec(thickness: 0, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
        ),
      ),
      domainAxis: charts.NumericAxisSpec(
        viewport: charts.NumericExtents(0, maxTime),
        renderSpec: charts.GridlineRendererSpec(
          labelStyle:
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
          lineStyle:
              charts.LineStyleSpec(thickness: 0, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
        ),
      ),
    );

    return Container(
      height: 300,
      margin: const EdgeInsets.only(left: 10.0),
      width: MediaQuery.of(context).size.width - 105,
      decoration: BoxDecoration(
        color: theme.ThemeColors.graphBackground,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: flowChart,
    );
  }

  Widget _buildGraphPressure(
      Map<String, charts.Series<ShotState, double>> data, Iterable<charts.RangeAnnotationSegment<double>> ranges) {
    var flowChart = charts.LineChart(
      [data["pressure"]!, data["pressureSet"]!],
      animate: false,
      behaviors: [
        charts.SeriesLegend(),
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
      primaryMeasureAxis: charts.NumericAxisSpec(
        renderSpec: charts.GridlineRendererSpec(
          labelStyle:
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
          lineStyle:
              charts.LineStyleSpec(thickness: 0, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
        ),
      ),
      domainAxis: charts.NumericAxisSpec(
        viewport: charts.NumericExtents(0, maxTime),
        renderSpec: charts.GridlineRendererSpec(
          labelStyle:
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
          lineStyle:
              charts.LineStyleSpec(thickness: 0, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
        ),
      ),
    );

    return Container(
      // height: 100,
      margin: const EdgeInsets.only(left: 10.0),
      width: MediaQuery.of(context).size.width - 105,
      decoration: BoxDecoration(
        color: theme.ThemeColors.graphBackground,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: flowChart,
    );
  }

  Widget _buildGraphFlow(
      Map<String, charts.Series<ShotState, double>> data, Iterable<charts.RangeAnnotationSegment<double>> ranges) {
    double maxWeight = (profileService.currentProfile?.shotHeader.targetWeight ?? 200.0) * 1.5;
    const secondaryMeasureAxisId = 'secondaryMeasureAxisId';

    var flowChart = charts.LineChart(
      [
        data["flow"]!,
        data["flowSet"]!,
        data["flowG"]!,
        data["weight"]!..setAttribute(charts.measureAxisIdKey, secondaryMeasureAxisId)
      ],
      animate: false,
      behaviors: [
        charts.SeriesLegend(),
        charts.RangeAnnotation([
          ...ranges,
        ], defaultLabelPosition: charts.AnnotationLabelPosition.margin),
      ],
      secondaryMeasureAxis: charts.NumericAxisSpec(
        tickProviderSpec: const charts.BasicNumericTickProviderSpec(zeroBound: false),
        viewport: charts.NumericExtents(0.0, maxWeight),
        renderSpec: charts.GridlineRendererSpec(
          labelStyle:
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
          lineStyle:
              charts.LineStyleSpec(thickness: 0, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
        ),
      ),
      primaryMeasureAxis: charts.NumericAxisSpec(
        tickProviderSpec: const charts.BasicNumericTickProviderSpec(zeroBound: false),
        renderSpec: charts.GridlineRendererSpec(
          labelStyle:
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
          lineStyle:
              charts.LineStyleSpec(thickness: 0, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
        ),
      ),
      domainAxis: charts.NumericAxisSpec(
        viewport: charts.NumericExtents(0, maxTime),
        renderSpec: charts.GridlineRendererSpec(
          labelStyle:
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
          lineStyle:
              charts.LineStyleSpec(thickness: 0, color: charts.ColorUtil.fromDartColor(theme.ThemeColors.primaryColor)),
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(left: 10.0),
      width: MediaQuery.of(context).size.width - 105,
      decoration: BoxDecoration(
        color: theme.ThemeColors.graphBackground,
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
          KeyValueWidget(label: "Profile", value: profileService.currentProfile!.title),
          KeyValueWidget(
              label: "Coffee",
              value: coffeeSelectionService.selectedCoffee > 0
                  ? coffeeSelectionService.coffeeBox.get(coffeeSelectionService.selectedCoffee)?.name ?? ""
                  : "No Beans"),
          KeyValueWidget(label: "Target", value: '${profileService.currentProfile?.shotHeader.targetWeight} g'),
          const Divider(
            height: 20,
            thickness: 5,
            indent: 0,
            endIndent: 0,
          ),
          KeyValueWidget(label: "Timer", value: '${machineService.lastPourTime.toStringAsFixed(1)} s'),
        ],
      );
    } else {
      insights = Text("${machineService.state.coffeeState.name} ${machineService.state.subState}",
          style: theme.TextStyles.tabPrimary);
    }
    return insights;
  }

  var pressAttention = true;

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> graphs = {};
    var isEmpty = machineService.shotList.entries.isEmpty;
    if (!isEmpty) {
      graphs = _buildGraphs();
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 8, // takes 30% of available width
              child: Column(
                children: isEmpty
                    ? [const Text("No data yet")]
                    : settingsService.graphSingle
                        ? [
                            Expanded(
                              flex: 1,
                              child: graphs["single"],
                            ),
                          ]
                        : [
                            Expanded(
                              flex: 1,
                              child: graphs["pressure"],
                            ),
                            Expanded(
                              flex: 1,
                              child: graphs["flow"],
                            ),
                            Expanded(
                              flex: 1,
                              child: graphs["temp"],
                            ),
                          ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 230, // takes 30% of available width
                child: Column(children: [
                  Expanded(
                    flex: 0,
                    child: _buildLiveInsights(),
                  ),
                  // Expanded(
                  //   flex: 1,
                  //   child: _buildScaleInsight(),
                  // ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.all(5.0),
                    child: StartStopButton(),
                  ),
                  // _buildButtons()
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
