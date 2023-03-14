import 'package:despresso/helper/linear_regress.ion.dart';
import 'package:despresso/model/shot.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:despresso/objectbox.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/shot_edit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:despresso/ui/theme.dart' as theme;
import 'package:intl/intl.dart';

class ShotGraph extends StatefulWidget {
  int id;
  List<int>? overlayIds;

  bool showFlow;
  bool showPressure;
  bool showWeight;
  bool showTemp;

  ShotGraph(
      {Key? key,
      required this.id,
      this.overlayIds,
      required this.showFlow,
      required this.showPressure,
      required this.showWeight,
      required this.showTemp})
      : super(key: key);

  @override
  _ShotGraphState createState() => _ShotGraphState();
}

class _ShotGraphState extends State<ShotGraph> {
  int id = 0;

  List<int>? overlayIds;

  bool _overlayMode = false;

  List<Shot?> shotOverlay = [];

  _ShotGraphState();

  @override
  Widget build(BuildContext context) {
    id = widget.id;
    overlayIds = widget.overlayIds;
    var shotBox = getIt<ObjectBox>().store.box<Shot>();
    if (overlayIds != null) {
      _overlayMode = true;
      for (var element in overlayIds!) {
        shotOverlay.add(shotBox.get(element));
      }
    } else {
      var shot = shotBox.get(id);
      overlayIds = [id];
      shotOverlay.add(shot);
    }
    return Container(
      child: Column(
        children: [
          ...shotOverlay.map(
            (e) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                  '${DateFormat.Hm().format(e!.date)} ${DateFormat.yMd().format(e.date)} ${e.pourWeight.toStringAsFixed(1)}g in ${e.pourTime.toStringAsFixed(1)}s'),
              TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ShotEdit(
                                e.id,
                              )),
                    );
                  },
                  icon: const Icon(Icons.note_add),
                  label: const Text("Diary"))
            ]),
          ),
          _buildGraphs()['single'],
        ],
      ),
    );
  }

  _buildGraphs() {
    Iterable<VerticalRangeAnnotation> ranges = [];
    Map<String, List<FlSpot>> datamap = {};

    for (var shot in shotOverlay) {
      if (!_overlayMode) ranges = _createPhasesFl(shot!.shotstates.toList());
      var data = _createDataFlCharts(shot!.id, shot.shotstates);
      datamap.addAll(data);
    }
    // var data = _createDataFlCharts();
    // double maxTime = 0;
    // var id = overlayIds!.first;
    // try {
    //   var t = shotOverlay.first!.shotstates.last.sampleTimeCorrected;
    //   //var maxData = datamap["pressure$id"]!.last;
    //   // var t = maxData.x;
    //   maxTime = t;
    // } catch (ex) {
    //   maxTime = 0;
    // }

    var single = _buildGraphSingleFlCharts(datamap, ranges);
    return {"single": single};
  }

  Iterable<VerticalRangeAnnotation> _createPhasesFl(List<ShotState> states) {
    var stateChanges = states.where((element) => element.subState.isNotEmpty).toList();

    int i = 0;
    var maxSampleTime = states.last.sampleTimeCorrected;
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
    });
  }

  Map<String, List<FlSpot>> _createDataFlCharts(int id, List<ShotState> shotstates) {
    return {
      "pressure$id": shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.groupPressure)).toList(),
      "pressureSet$id": shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.setGroupPressure)).toList(),
      "flow$id": shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.groupFlow)).toList(),
      "flowSet$id": shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.setGroupFlow)).toList(),
      "temp$id": shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.headTemp)).toList(),
      "tempSet$id": shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.setHeadTemp)).toList(),
      "weight$id": shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.weight)).toList(),
      "flowG$id": shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.flowWeight)).toList(),
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

  Widget _buildGraphSingleFlCharts(Map<String, List<FlSpot>> data, Iterable<VerticalRangeAnnotation> ranges) {
    List<LineChartBarData> lineBarsDataFlows = [];
    List<LineChartBarData> lineBarsDataTempWeight = [];
    double i = 0;
    for (var id in overlayIds!) {
      if (widget.showPressure) {
        lineBarsDataFlows
            .add(createChartLineDatapoints(data["pressure$id"]!, 4, calcColor(theme.ThemeColors.pressureColor, i)));
        lineBarsDataFlows
            .add(createChartLineDatapoints(data["pressureSet$id"]!, 2, calcColor(theme.ThemeColors.pressureColor, i)));
      }
      if (widget.showFlow) {
        lineBarsDataFlows
            .add(createChartLineDatapoints(data["flow$id"]!, 4, calcColor(theme.ThemeColors.flowColor, i)));
        lineBarsDataFlows
            .add(createChartLineDatapoints(data["flowSet$id"]!, 2, calcColor(theme.ThemeColors.flowColor, i)));
        lineBarsDataFlows
            .add(createChartLineDatapoints(data["flowG$id"]!, 2, calcColor(theme.ThemeColors.weightColor, i)));
      }
      if (widget.showWeight) {
        lineBarsDataTempWeight
            .add(createChartLineDatapoints(data["weight$id"]!, 2, calcColor(theme.ThemeColors.weightColor, i)));
      }
      if (widget.showTemp) {
        lineBarsDataTempWeight
            .add(createChartLineDatapoints(data["temp$id"]!, 4, calcColor(theme.ThemeColors.tempColor, i)));
        lineBarsDataTempWeight
            .add(createChartLineDatapoints(data["tempSet$id"]!, 2, calcColor(theme.ThemeColors.tempColor, i)));
      }
      i += 0.25;
    }

    var flowChart1 = LineChart(
      LineChartData(
        minY: 0,
        // maxY: 15,
        // minX: data["pressure${overlayIds!.first}"]!.first.x,
        // maxX: maxTime,
        lineTouchData: LineTouchData(enabled: false),
        clipData: FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
        ),
        lineBarsData: lineBarsDataFlows,
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
        // minX: data["pressure${overlayIds!.first}"]!.first.x,
        // maxX: maxTime,
        lineTouchData: LineTouchData(enabled: false),
        clipData: FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
        ),
        lineBarsData: lineBarsDataTempWeight,
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
          // SizedBox(
          //   height: 30,
          //   child: LegendsListWidget(
          //     legends: [
          //       Legend('Pressure', theme.ThemeColors.pressureColor),
          //       Legend('Flow', theme.ThemeColors.flowColor),
          //       Legend('Weight', theme.ThemeColors.weightColor),
          //       Legend('Temp', theme.ThemeColors.tempColor),
          //     ],
          //   ),
          // ),
          SizedBox(height: 400, child: flowChart1),
          const SizedBox(height: 20),
          SizedBox(height: 100, child: flowChart2),
        ],
      ),
    );
  }

  Color calcColor(Color col, double i) {
    return col.withOpacity(1 - i);
    // return Color.fromRGBO(col.red, col.green, col.blue, col.alpha / 255 - i);
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
}
