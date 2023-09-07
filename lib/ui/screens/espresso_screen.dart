import 'dart:math';

import 'package:despresso/model/services/state/notification_service.dart';
import 'package:despresso/model/services/state/screen_saver.dart';
import 'package:despresso/ui/screens/shot_edit.dart';
import 'package:logging/logging.dart';
import 'dart:math' as math;

import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/service_locator.dart';

import 'package:despresso/ui/widgets/key_value.dart';
import 'package:despresso/ui/widgets/legend_list.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:url_launcher/url_launcher.dart';
import 'package:despresso/generated/l10n.dart';

import '../../devices/decent_de1.dart';
import '../widgets/start_stop_button.dart';

class EspressoScreen extends StatefulWidget {
  const EspressoScreen({super.key});

  @override
  EspressoScreenState createState() => EspressoScreenState();
}

class EspressoScreenState extends State<EspressoScreen> {
  final log = Logger('EspressoScreenState');

  late CoffeeService coffeeSelectionService;
  late EspressoMachineService machineService;
  late ProfileService profileService;
  late ScaleService scaleService;
  late SettingsService settingsService;
  late ScreensaverService _screensaver;

  double baseTime = 0;

  String lastSubstate = '';

  String subState = "";

  bool refillAnounced = false;

  bool stopTriggered = false;

  double maxTime = 30;

  final GlobalKey<State<StatefulWidget>> _mywidgetkey = GlobalKey();

  Iterable<VerticalRangeAnnotation> ranges = [];

  Map<String, List<FlSpot>> data = {};

  Widget? single;

  int _lastLength = 0;

  String bleError = "";

  int _count = 0;
  DateTime _lastCount = DateTime.now();

  EspressoScreenState();

  @override
  void dispose() {
    super.dispose();
    machineService.removeListener(updateMachine);
    profileService.removeListener(updateProfile);
    coffeeSelectionService.removeListener(updateCoffeeSelection);
    log.info('Disposed espresso');
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
    _screensaver = getIt<ScreensaverService>();

    Future.delayed(const Duration(seconds: 4), () => checkPermissions());
  }

  // loadShotData() async {
  //   await shotList.load("testshot.json");
  //   setState(() {});
  // }

  void updateCoffee() => setState(() {
        checkForRefill();
      });
  void triggerEndOfShot() {
    log.info("Idle mode initiated because of weight");

    machineService.de1?.requestState(De1StateEnum.idle);
  }

  void checkForRefill() {
    if (refillAnounced == false && machineService.state.coffeeState == EspressoMachineState.refill) {
      getIt<SnackbarService>().notify(S.of(context).screenEspressoRefillTheWaterTank, SnackbarNotificationType.warn);
      refillAnounced = true;
    }
  }

  _buildGraphs() {
    if (machineService.inShot || ranges.isEmpty || machineService.shotList.lastTouched != _lastLength) {
      ranges = _createPhasesFl();
      data = _createDataFlCharts();

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

      // List<ShotState> raw = machineService.shotList.entries;
      _lastLength = machineService.shotList.lastTouched; // raw.length;
      var tEnd = machineService.currentShot.estimatedWeight_tEnd;
      var tStart = machineService.currentShot.estimatedWeight_tStart;
      tStart = tEnd - 3;
      var m = machineService.currentShot.estimatedWeight_m;
      var b = machineService.currentShot.estimatedWeight_b;
      var timeGoal = machineService.currentShot.estimatedWeightReachedTime;
      var weightGoal = m * timeGoal + b;
      var arr = [
        FlSpot(tStart - 5, m * (tStart - 5) + b),
        FlSpot(tEnd, m * tEnd + b),
        FlSpot(machineService.currentShot.estimatedWeightReachedTime, weightGoal),
        FlSpot(machineService.currentShot.estimatedWeightReachedTime, 0),
        FlSpot(machineService.currentShot.estimatedWeightReachedTime, weightGoal),
        FlSpot(0, weightGoal),
      ];

// Show the new scaled maxtime only of 5g before end of shot.
      if (machineService.inShot == false ||
          machineService.currentShot.targetEspressoWeight - (machineService.state.shot?.weight ?? 30) < 5) {
        var corrected = (timeGoal ~/ 5.0).toInt() * 5.0 + 5;
        maxTime = max(maxTime, corrected);
      }
      data["weightApprox"] = timeGoal > 0 && timeGoal < 200 ? arr : [];
    } else {
      data["weightApprox"] = data["weightApprox"] ?? [];
    }
    single = _buildGraphSingleFlCharts(data, maxTime, ranges);

    return {"single": single};
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
      // log.info("Phase ${element.subState}");
    });
  }

  Map<String, List<FlSpot>> _createDataFlCharts() {
    return {
      "pressure": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.groupPressure)).toList(),
      "pressureSet":
          machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.setGroupPressure)).toList(),
      "flow": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.groupFlow)).toList(),
      "flowSet": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.setGroupFlow)).toList(),
      "temp": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.headTemp)).toList(),
      "mixTemp": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.mixTemp)).toList(),
      "mixTempSet": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.setMixTemp)).toList(),
      "tempSet": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.setHeadTemp)).toList(),
      "weight": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.weight)).toList(),
      "flowG": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.flowWeight)).toList(),
    };
  }

  LineChartBarData createChartLineDatapoints(List<FlSpot> points, double barWidth, Color col, List<int>? dash) {
    // var data = machineService.shotList.entries;
    // var last = data.lastIndexWhere((element) => !element.isInterpolated);
    return LineChartBarData(
      spots: points,
      dotData: const FlDotData(
        show: false,
        // getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
        //   radius: 1,
        //   strokeWidth: 2,
        //   color: (data[index].isInterpolated) ? Colors.orange : col,
        //   strokeColor: (data[index].isInterpolated)
        //       ? Colors.orange
        //       : (index == last)
        //           ? Colors.red
        //           : col,
        // ),
      ),
      barWidth: barWidth,
      isCurved: false,
      color: col,
      dashArray: dash,
    );
  }

  Widget _buildGraphSingleFlCharts(
      Map<String, List<FlSpot>> data, double maxTime, Iterable<VerticalRangeAnnotation> ranges) {
    var borderData = FlBorderData(
      show: true,
      border: Border.all(
        width: 2,
        color: Theme.of(context).secondaryHeaderColor,
      ),
    );

    _count++;
    const nr = 10;
    if (_count % nr == 0) {
      var t = DateTime.now();
      var ms = t.difference(_lastCount).inMilliseconds;
      var hz = nr / ms * 1000.0;
      if (_count & 10 == 0) log.info("Graph Hz: $ms $hz");
      _lastCount = t;
    }
    bool hasFlow = settingsService.showFlowGraph;
    bool hasPressure = settingsService.showPressureGraph;
    const double sep = 5;
    double minX = data["pressure"]!.first.x; // max(0, (data["pressureSet"]!.last.x) - 5); //data["pressure"]!.first.x;
    // maxTime = (data["pressureSet"]!.last.x) + 1;

    double maxY1 =
        (!hasPressure) ? 0 : data["pressureSet"]!.map((e) => e.y).reduce((value, element) => max(value, element)) + 0.5;
    double maxY3 =
        (!hasPressure) ? 0 : data["pressure"]!.map((e) => e.y).reduce((value, element) => max(value, element)) + 0.5;
    double maxY2 =
        (!hasFlow) ? 0 : data["flowSet"]!.map((e) => e.y).reduce((value, element) => max(value, element)) + 0.5;

    double maxY4 = (!hasFlow) ? 0 : data["flow"]!.map((e) => e.y).reduce((value, element) => max(value, element)) + 0.5;
    var flowChart1 = LineChart(
      LineChartData(
        minY: 0,
        maxY: max(max(maxY3, maxY4), max(maxY1, maxY2)),
        minX: minX,
        maxX: maxTime,
        borderData: borderData,
        lineTouchData: const LineTouchData(enabled: false),
        clipData: const FlClipData.all(),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: true,
        ),
        lineBarsData: [
          if (hasPressure) createChartLineDatapoints(data["pressure"]!, 4, theme.ThemeColors.pressureColor, null),
          if (hasPressure) createChartLineDatapoints(data["pressureSet"]!, 1, theme.ThemeColors.pressureColor, [5, 5]),
          if (hasFlow) createChartLineDatapoints(data["flow"]!, 4, theme.ThemeColors.flowColor, null),
          if (hasFlow) createChartLineDatapoints(data["flowSet"]!, 1, theme.ThemeColors.flowColor, [5, 5]),
          if (hasFlow) createChartLineDatapoints(data["flowG"]!, 2, theme.ThemeColors.weightColor, null),
        ],
        rangeAnnotations: const RangeAnnotations(
          verticalRangeAnnotations: [
            // ...ranges,
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
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          bottomTitles: (!settingsService.showTempGraph && !settingsService.showWeightGraph)
              ? AxisTitles(
                  axisNameSize: 25,
                  axisNameWidget: Text(
                    S.of(context).screenEspressoTimes,
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
                )
              : AxisTitles(
                  axisNameSize: 25,
                  sideTitles: SideTitles(
                    showTitles: false,
                    getTitlesWidget: bottomTitleWidgets,
                    reservedSize: 26,
                  ),
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
              S.of(context).screenEspressoFlowMlsPressureBar,
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

    maxY3 = (!settingsService.showWeightGraph)
        ? 0
        : data["weight"]!.map((e) => e.y).reduce((value, element) => max(value, element)) + 0.5;
    var flowChart2 = LineChart(
      LineChartData(
        minY: 0,
        maxY: max(maxY3, machineService.currentShot.targetEspressoWeight * 1.15),
        minX: minX,
        maxX: maxTime,
        borderData: borderData,
        lineTouchData: const LineTouchData(enabled: false),
        clipData: const FlClipData.all(),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: true,
        ),
        lineBarsData: [
          createChartLineDatapoints(data["weight"]!, 2, theme.ThemeColors.weightColor, null),
          // createChartLineDatapoints(data["temp"]!, 4, theme.ThemeColors.tempColor, null),
          // createChartLineDatapoints(data["tempSet"]!, 2, theme.ThemeColors.tempColor, null),
          createChartLineDatapoints(data["weightApprox"]!, 2, theme.ThemeColors.weightColor, [5, 5]),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: (!settingsService.showTempGraph)
              ? AxisTitles(
                  axisNameSize: 25,
                  axisNameWidget: Text(
                    S.of(context).screenEspressoTimes,
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
                )
              : AxisTitles(
                  axisNameSize: 25,
                  sideTitles: SideTitles(
                    showTitles: false,
                    getTitlesWidget: bottomTitleWidgets,
                    reservedSize: 26,
                  ),
                ),
          show: true,
          leftTitles: AxisTitles(
            axisNameSize: 25,
            axisNameWidget: Text(
              S.of(context).screenEspressoWeightG,
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
    maxY1 = 0;
    double minY1 = 100;
    for (var s in ["mixTempSet", "mixTemp", "temp", "tempSet"]) {
      maxY1 = max(maxY1, data[s]!.map((e) => e.y).reduce((value, element) => max(value, element))) + 0.5;
      minY1 = min(minY1, data[s]!.map((e) => e.y).reduce((value, element) => min(value, element))) - 1;
    }

    var flowChart3 = LineChart(
      LineChartData(
        // minY: 80,
        maxY: maxY1,
        minY: minY1,
        minX: minX,
        maxX: maxTime,
        borderData: borderData,
        lineTouchData: const LineTouchData(enabled: false),
        clipData: const FlClipData.all(),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: true,
        ),
        lineBarsData: [
          createChartLineDatapoints(data["temp"]!, 2, theme.ThemeColors.tempColor, null),
          createChartLineDatapoints(data["tempSet"]!, 1, theme.ThemeColors.tempColor, [5, 5]),
          createChartLineDatapoints(data["mixTemp"]!, 2, theme.ThemeColors.tempColor2, null),
          createChartLineDatapoints(data["mixTempSet"]!, 1, theme.ThemeColors.tempColor2, [5, 5]),

          // createChartLineDatapoints(data["temp"]!, 4, theme.ThemeColors.tempColor, null),
          // createChartLineDatapoints(data["tempSet"]!, 2, theme.ThemeColors.tempColor, null),
          // createChartLineDatapoints(data["weightApprox"]!, 2, theme.ThemeColors.weightColor, [5, 5]),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            axisNameSize: 25,
            axisNameWidget: Text(
              S.of(context).screenEspressoTimes,
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
              S.of(context).screenEspressoTemp,
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
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (settingsService.showPressureGraph || settingsService.showFlowGraph)
            Expanded(
                flex: 1,
                child: InkWell(
                    onTap: () {
                      if (settingsService.showPressureGraph == false && settingsService.showFlowGraph == true) {
                        settingsService.showPressureGraph = false;
                        settingsService.showFlowGraph = false;
                      } else if (settingsService.showPressureGraph == true && settingsService.showFlowGraph == false) {
                        settingsService.showPressureGraph = false;
                        settingsService.showFlowGraph = true;
                      } else if (settingsService.showPressureGraph == true && settingsService.showFlowGraph == true) {
                        settingsService.showPressureGraph = false;
                        settingsService.showFlowGraph = true;
                      }

                      setState(() {});
                    },
                    child: flowChart1)),
          if (settingsService.showWeightGraph || settingsService.showTempGraph) const SizedBox(height: sep),
          if (settingsService.showWeightGraph)
            Expanded(
                flex: 1,
                child: InkWell(
                    onTap: () {
                      settingsService.showWeightGraph = false;
                      setState(() {});
                    },
                    child: flowChart2)),
          if (settingsService.showTempGraph) const SizedBox(height: sep),
          if (settingsService.showTempGraph)
            Expanded(
                flex: 1,
                child: InkWell(
                    onTap: () {
                      settingsService.showTempGraph = false;
                      setState(() {});
                    },
                    child: flowChart3)),
          SizedBox(
            height: 30,
            child: LegendsListWidget(
              legends: [
                Legend(
                  S.of(context).screenEspressoPressure,
                  theme.ThemeColors.pressureColor,
                  value: settingsService.showPressureGraph,
                  onChanged: (p0) {
                    settingsService.showPressureGraph = p0;
                    setState(() {});
                  },
                ),
                Legend(
                  S.of(context).screenEspressoFlow,
                  theme.ThemeColors.flowColor,
                  value: settingsService.showFlowGraph,
                  onChanged: (p0) {
                    settingsService.showFlowGraph = p0;
                    setState(() {});
                  },
                ),
                Legend(
                  S.of(context).screenEspressoWeight,
                  theme.ThemeColors.weightColor,
                  value: settingsService.showWeightGraph,
                  onChanged: (p0) {
                    settingsService.showWeightGraph = p0;
                    setState(() {});
                  },
                ),
                Legend(
                  S.of(context).screenEspressoTemp,
                  theme.ThemeColors.tempColor,
                  value: settingsService.showTempGraph,
                  onChanged: (p0) {
                    settingsService.showTempGraph = p0;
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 6,
      child: Text(meta.formattedValue, style: Theme.of(context).textTheme.labelSmall),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 6,
      child: Text(meta.formattedValue, style: Theme.of(context).textTheme.labelSmall),
    );
  }

  Widget _buildLiveInsights() {
    Widget insights;
    const width = 70.0;
    insights = Column(
      key: _mywidgetkey,
      children: [
        if (machineService.state.coffeeState == EspressoMachineState.disconnected) const Icon(Icons.bluetooth_disabled),
        KeyValueWidget(
            width: width,
            label: S.of(context).screenEspressoRecipe,
            value: coffeeSelectionService.currentRecipe?.name ?? "no recipe"),
        KeyValueWidget(
            width: width,
            label: S.of(context).screenEspressoProfile,
            value: profileService.currentProfile?.title ?? "no profile"),
        KeyValueWidget(
            width: width,
            label: S.of(context).screenEspressoBean,
            value: coffeeSelectionService.selectedCoffeeId > 0
                ? coffeeSelectionService.coffeeBox.get(coffeeSelectionService.selectedCoffeeId)?.name ?? ""
                : "No Beans"),
        if ((coffeeSelectionService.currentRecipe?.disableStopOnWeight ?? false) == false)
          KeyValueWidget(
              width: width,
              label: S.of(context).screenEspressoTarget,
              value:
                  '${settingsService.targetEspressoWeight.toStringAsFixed(1)} g / ${machineService.currentShot.shotstates.last.weight.toStringAsFixed(1)} g'),
        if (machineService.lastPourTime > 0)
          const Divider(
            height: 20,
            thickness: 5,
            indent: 0,
            endIndent: 0,
          ),
        if (machineService.lastPourTime > 0)
          KeyValueWidget(
              width: width,
              label: S.of(context).screenEspressoTimer,
              value: S.of(context).screenEspressoPour(machineService.lastPourTime.toStringAsFixed(1))),
        if (machineService.getOverallTime() > 0)
          KeyValueWidget(
              width: width,
              label: "",
              value: S.of(context).screenEspressoTotal(machineService.getOverallTime().toStringAsFixed(1))),
        if (machineService.isPouring && (machineService.state.shot?.timeToWeight ?? 0) > 0)
          KeyValueWidget(
              width: width,
              label: "",
              value:
                  S.of(context).screenEspressoTtw(machineService.state.shot?.timeToWeight.toStringAsFixed(1) ?? "?")),
        StreamBuilder<String>(
            stream: machineService.streamFrameName,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != "") {
                return Text(
                  snapshot.data!,
                  style:
                      Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                );
              }
              return const SizedBox.shrink();
            }),
        const Divider(
          height: 20,
          thickness: 5,
          indent: 0,
          endIndent: 0,
        ),
        TextButton.icon(
          onPressed: () {
            _screensaver.pause();
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ShotEdit(
                        coffeeSelectionService.selectedShotId,
                      )),
            ).then((value) => _screensaver.resume());
          },
          icon: const Icon(Icons.note_add),
          label: Text(S.of(context).screenEspressoDiary),
        ),
        const Divider(
          height: 20,
          thickness: 5,
          indent: 0,
          endIndent: 0,
        ),
        if (machineService.state.coffeeState != EspressoMachineState.espresso &&
            machineService.currentShot.visualizerId.isNotEmpty)
          TextButton.icon(
            onPressed: () {
              launchUrl(Uri.parse('https://visualizer.coffee/shots/${machineService.currentShot.visualizerId}'));
            },
            icon: const Icon(Icons.cloud),
            label: const Text("Visualizer.coffee"),
          ),
      ],
    );

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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 8, // takes 30% of available width
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: isEmpty
                      ? [
                          const Icon(size: 100, Icons.multiline_chart),
                          bleError.isEmpty
                              ? const Text("No data yet")
                              : const Text(
                                  "you need to enable location services in the system settings to be able to connect to the de1 and scales")
                        ]
                      : [
                          Expanded(
                            flex: 1,
                            child: graphs["single"],
                          ),
                        ]),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildRightSidePanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildRightSidePanel() {
    double height = 0;
    double expand = 0;
    try {
      final size = MediaQuery.of(context);
      final apparentSize = size.size.height - size.padding.bottom - size.padding.top;

      RenderBox? renderbox = _mywidgetkey.currentContext?.findRenderObject() as RenderBox?;
      if (renderbox != null) {
        height = renderbox.size.height;
      } else {
        height = 400;
        Future.delayed(const Duration(milliseconds: 100), () => setState(() {}));
      }
      expand = apparentSize - height - 360;
    } catch (e) {
      log.severe("Error in mediaquery $e");
    }

    return SizedBox(
      width: 230,
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.start, children: [
        _buildLiveInsights(),
        // Expanded(
        //   flex: 1,
        //   child: _buildScaleInsight(),
        // ),
        if (expand > 0) SizedBox(height: expand),
        const Padding(
          padding: EdgeInsets.all(5.0),
          child: StartStopButton(requestedState: De1StateEnum.espresso),
        ),
        // _buildButtons()
      ]),
    );
  }

  Future<void> checkPermissions() async {
    // var ble = getIt<BLEService>();
    // if (ble.checkInProgress) {
    //   return;
    // }
    // try {
    //   await ble.checkPermissions();
    //   bleError = "";
    // } catch (e) {
    //   bleError = "$e";
    //   setState(() {});
    //   log.severe("Error in connection to BLE $e");
    // }
    // setState(() {});
  }
}
