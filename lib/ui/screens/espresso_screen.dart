import 'dart:math';

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

  double baseTime = 0;

  String lastSubstate = '';

  String subState = "";

  bool refillAnounced = false;

  bool stopTriggered = false;

  double maxTime = 30;

  GlobalKey<State<StatefulWidget>> _mywidgetkey = GlobalKey();

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

    var single = _buildGraphSingleFlCharts(data, maxTime, ranges);
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
      "tempSet": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.setHeadTemp)).toList(),
      "weight": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.weight)).toList(),
      "flowG": machineService.shotList.entries.map((e) => FlSpot(e.sampleTimeCorrected, e.flowWeight)).toList(),
    };
  }

  LineChartBarData createChartLineDatapoints(List<FlSpot> points, double barWidth, Color col) {
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
          createChartLineDatapoints(data["pressure"]!, 4, theme.ThemeColors.pressureColor),
          createChartLineDatapoints(data["pressureSet"]!, 2, theme.ThemeColors.pressureColor),
          createChartLineDatapoints(data["flow"]!, 4, theme.ThemeColors.flowColor),
          createChartLineDatapoints(data["flowSet"]!, 2, theme.ThemeColors.flowColor),
          createChartLineDatapoints(data["flowG"]!, 2, theme.ThemeColors.weightColor),
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
          createChartLineDatapoints(data["weight"]!, 2, theme.ThemeColors.weightColor),
          createChartLineDatapoints(data["temp"]!, 4, theme.ThemeColors.tempColor),
          createChartLineDatapoints(data["tempSet"]!, 2, theme.ThemeColors.tempColor),
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

  Widget _buildLiveInsights() {
    Widget insights;
    const width = 70.0;
    insights = Column(
      key: _mywidgetkey,
      children: [
        if (machineService.state.coffeeState == EspressoMachineState.disconnected) const Icon(Icons.bluetooth_disabled),
        KeyValueWidget(width: width, label: "Recipe", value: coffeeSelectionService.currentRecipe?.name ?? "no recipe"),
        KeyValueWidget(width: width, label: "Profile", value: profileService.currentProfile?.title ?? "no profile"),
        KeyValueWidget(
            width: width,
            label: "Coffee",
            value: coffeeSelectionService.selectedCoffeeId > 0
                ? coffeeSelectionService.coffeeBox.get(coffeeSelectionService.selectedCoffeeId)?.name ?? ""
                : "No Beans"),
        KeyValueWidget(width: width, label: "Target", value: '${settingsService.targetEspressoWeight} g'),
        if (machineService.lastPourTime > 0)
          const Divider(
            height: 20,
            thickness: 5,
            indent: 0,
            endIndent: 0,
          ),
        if (machineService.lastPourTime > 0)
          KeyValueWidget(
              width: width, label: "Timer", value: 'Pour: ${machineService.lastPourTime.toStringAsFixed(1)} s'),
        if (machineService.lastPourTime > 0)
          KeyValueWidget(
              width: width, label: "A", value: 'Total: ${machineService.getOverallTime().toStringAsFixed(1)} s'),
        const Divider(
          height: 20,
          thickness: 5,
          indent: 0,
          endIndent: 0,
        ),
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ShotEdit(
                        coffeeSelectionService.selectedShotId,
                      )),
            );
          },
          icon: const Icon(Icons.note_add),
          label: const Text("Espresso Diary"),
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
                      ? [const Text("No data yet")]
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
        Future.delayed(const Duration(milliseconds: 10), () => setState(() {}));
      }
      expand = apparentSize - height - 360;
      log.info("Height: ${apparentSize} $height $expand");
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
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: StartStopButton(requestedState: De1StateEnum.espresso),
        ),
        // _buildButtons()
      ]),
    );
  }
}
