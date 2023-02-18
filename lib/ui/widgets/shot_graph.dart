import 'package:despresso/model/shot.dart';
import 'package:despresso/objectbox.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/widgets/legend_list.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:despresso/ui/theme.dart' as theme;

class ShotGraph extends StatefulWidget {
  int id;
  ShotGraph({Key? key, required this.id}) : super(key: key);

  @override
  _ShotGraphState createState() => _ShotGraphState(id);
}

class _ShotGraphState extends State<ShotGraph> {
  int id;

  Shot? shot;

  _ShotGraphState(this.id) {
    var shotBox = getIt<ObjectBox>().store.box<Shot>();
    shot = shotBox.get(id);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text(id.toString()),
          _buildGraphs()['single'],
        ],
      ),
    );
  }

  _buildGraphs() {
    var ranges = _createPhasesFl();
    var data = _createDataFlCharts();
    double maxTime = 0;
    try {
      var maxData = data["pressure"]!.last;
      var t = maxData.x;
      maxTime = t;
    } catch (ex) {
      maxTime = 0;
    }

    var single = _buildGraphSingleFlCharts(data, maxTime, ranges);
    return {"single": single};
  }

  Iterable<VerticalRangeAnnotation> _createPhasesFl() {
    var stateChanges = shot!.shotstates.where((element) => element.subState.isNotEmpty).toList();

    int i = 0;
    var maxSampleTime = shot!.shotstates.last.sampleTimeCorrected;
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
      "pressure": shot!.shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.groupPressure)).toList(),
      "pressureSet": shot!.shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.setGroupPressure)).toList(),
      "flow": shot!.shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.groupFlow)).toList(),
      "flowSet": shot!.shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.setGroupFlow)).toList(),
      "temp": shot!.shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.headTemp)).toList(),
      "tempSet": shot!.shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.setHeadTemp)).toList(),
      "weight": shot!.shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.weight)).toList(),
      "flowG": shot!.shotstates.map((e) => FlSpot(e.sampleTimeCorrected, e.flowWeight)).toList(),
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
          SizedBox(height: 200, child: flowChart1),
          const SizedBox(height: 20),
          SizedBox(height: 100, child: flowChart2),
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
}
