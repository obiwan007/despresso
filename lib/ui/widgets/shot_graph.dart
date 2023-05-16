import 'package:despresso/model/shot.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:despresso/objectbox.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/shot_edit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:despresso/generated/l10n.dart';

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
                  label: Text(S.of(context).screenEspressoDiary))
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
      "tempMix$id": shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.mixTemp)).toList(),
      "tempMixSet$id": shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.setMixTemp)).toList(),
      "weight$id": shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.weight)).toList(),
      "flowG$id": shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.flowWeight)).toList(),
    };
  }

  LineChartBarData createChartLineDatapoints(List<FlSpot> points, double barWidth, Color col, List<int>? dash) {
    return LineChartBarData(
      spots: points,
      dotData: FlDotData(
        show: false,
      ),
      barWidth: barWidth,
      isCurved: false,
      color: col,
      dashArray: dash,
    );
  }

  Widget _buildGraphSingleFlCharts(Map<String, List<FlSpot>> data, Iterable<VerticalRangeAnnotation> ranges) {
    List<LineChartBarData> lineBarsDataFlows = [];
    List<LineChartBarData> lineBarsDataTempWeight = [];
    List<LineChartBarData> lineBarsDataTemp = [];
    double i = 0;
    for (var id in overlayIds!) {
      if (widget.showPressure) {
        lineBarsDataFlows.add(
            createChartLineDatapoints(data["pressure$id"]!, 4, calcColor(theme.ThemeColors.pressureColor, i), null));
        lineBarsDataFlows.add(createChartLineDatapoints(
            data["pressureSet$id"]!,
            2,
            calcColor(
              theme.ThemeColors.pressureColor,
              i,
            ),
            [5, 5]));
      }
      if (widget.showFlow) {
        lineBarsDataFlows
            .add(createChartLineDatapoints(data["flow$id"]!, 4, calcColor(theme.ThemeColors.flowColor, i), null));
        lineBarsDataFlows
            .add(createChartLineDatapoints(data["flowSet$id"]!, 2, calcColor(theme.ThemeColors.flowColor, i), [5, 5]));
        lineBarsDataFlows
            .add(createChartLineDatapoints(data["flowG$id"]!, 2, calcColor(theme.ThemeColors.weightColor, i), null));
      }
      if (widget.showWeight) {
        lineBarsDataTempWeight
            .add(createChartLineDatapoints(data["weight$id"]!, 2, calcColor(theme.ThemeColors.weightColor, i), null));
      }
      if (widget.showTemp) {
        lineBarsDataTemp
            .add(createChartLineDatapoints(data["temp$id"]!, 4, calcColor(theme.ThemeColors.tempColor, i), null));
        lineBarsDataTemp
            .add(createChartLineDatapoints(data["tempSet$id"]!, 2, calcColor(theme.ThemeColors.tempColor, i), [5, 5]));
        lineBarsDataTemp
            .add(createChartLineDatapoints(data["tempMix$id"]!, 4, calcColor(theme.ThemeColors.tempColor2, i), null));
        lineBarsDataTemp.add(
            createChartLineDatapoints(data["tempMixSet$id"]!, 2, calcColor(theme.ThemeColors.tempColor2, i), [5, 5]));
      }
      i += 0.25;
    }

    var flowChart1 = LineChart(
      LineChartData(
        // minY: 0,
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
          // bottomTitles: AxisTitles(
          //   sideTitles: SideTitles(showTitles: false),
          // ),
          bottomTitles: !widget.showTemp && !widget.showWeight
              ? AxisTitles(
                  axisNameSize: 25,
                  axisNameWidget: Text(
                    S.of(context).graphTime,
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
              S.of(context).graphFlowMlsPressureBar,
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
        // minY: 0,
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
          bottomTitles: !widget.showTemp
              ? AxisTitles(
                  axisNameSize: 25,
                  axisNameWidget: Text(
                    S.of(context).graphTime,
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

    var flowChart3 = LineChart(
      LineChartData(
        // minY: 0,
        // maxY: 15,
        // minX: data["pressure${overlayIds!.first}"]!.first.x,
        // maxX: maxTime,
        lineTouchData: LineTouchData(enabled: false),
        clipData: FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
        ),
        lineBarsData: lineBarsDataTemp,
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
              S.of(context).graphTime,
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
              "Temp",
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

    var height = 300 + 120 + 120;

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
          if (widget.showFlow || widget.showPressure)
            SizedBox(height: height - (widget.showTemp ? 120 : 0) - (widget.showWeight ? 120 : 0), child: flowChart1),
          if (widget.showWeight) const SizedBox(height: 20),
          if (widget.showWeight)
            SizedBox(
                height: height - (widget.showFlow || widget.showPressure ? 300 : 0) - (widget.showTemp ? 120 : 0),
                child: flowChart2),
          if (widget.showTemp) const SizedBox(height: 20),
          if (widget.showTemp)
            SizedBox(
                height: height - (widget.showFlow || widget.showPressure ? 300 : 0) - (widget.showWeight ? 120 : 0),
                child: flowChart3),
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
