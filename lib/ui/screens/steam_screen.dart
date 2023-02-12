import 'dart:math';

import 'package:despresso/model/machine.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/ble/temperature_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/widgets/legend_list.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;

import '../../model/shotstate.dart';
import '../widgets/start_stop_button.dart';

class SteamScreen extends StatefulWidget {
  const SteamScreen({super.key});

  @override
  SteamScreenState createState() => SteamScreenState();
}

class SteamScreenState extends State<SteamScreen> {
  late EspressoMachineService machineService;
  late ScaleService scaleService;
  late TempService tempService;

  List<ShotState> dataPoints = [];
  EspressoMachineState currentState = EspressoMachineState.disconnected;

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    machineService.addListener(machineStateListener);
    tempService = getIt<TempService>();
    tempService.addListener(tempStateListener);
    // Scale services is consumed as stream
    scaleService = getIt<ScaleService>();
  }

  @override
  void dispose() {
    super.dispose();
    machineService.removeListener(machineStateListener);
    tempService.removeListener(tempStateListener);
  }

  machineStateListener() {
    setState(() => {currentState = machineService.state.coffeeState});
    // machineService.de1?.setIdleState();
  }

  tempStateListener() {
    setState(() => {});
    // machineService.de1?.setIdleState();
  }

  Widget _buildControls() {
    var settings = machineService.settings;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Text("Steam Temperatur ${settings.targetSteamTemp}°C", style: theme.TextStyles.tabHeading),
                            Slider(
                              value: settings.targetSteamTemp.toDouble(),
                              max: 180,
                              min: 100,
                              divisions: 80,
                              label: "${settings.targetSteamTemp} °C",
                              onChanged: (double value) {
                                setState(() {
                                  settings.targetSteamTemp = value.toInt();
                                  machineService.updateSettings(settings);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: Stack(
                          children: <Widget>[
                            if (machineService.state.coffeeState == EspressoMachineState.steam) ...[
                              Center(
                                child: SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 15,
                                    value: machineService.state.coffeeState == EspressoMachineState.steam
                                        ? (machineService.state.shot?.steamTemp ?? 1) / settings.targetSteamTemp
                                        : 0,
                                  ),
                                ),
                              ),
                              Center(child: Text("${machineService.state.shot?.steamTemp}°C")),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 20,
                  thickness: 5,
                  indent: 20,
                  endIndent: 0,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Text("Timer ${settings.targetSteamLength} s", style: theme.TextStyles.tabHeading),
                            Slider(
                              value: settings.targetSteamLength.toDouble(),
                              max: 200,
                              min: 1,
                              divisions: 200,
                              label: "${settings.targetSteamLength} s",
                              onChanged: (double value) {
                                setState(() {
                                  settings.targetSteamLength = value.toInt();
                                  machineService.updateSettings(settings);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: Stack(
                          children: <Widget>[
                            if (machineService.state.coffeeState == EspressoMachineState.steam) ...[
                              Center(
                                child: SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 15,
                                    value: machineService.state.coffeeState == EspressoMachineState.steam
                                        ? machineService.timer.inSeconds / settings.targetSteamLength
                                        : 0,
                                  ),
                                ),
                              ),
                              Center(child: Text("${machineService.timer.inSeconds.toStringAsFixed(0)}s")),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (tempService.state == TempState.connected)
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Text("Stop at Temperatur ${settings.targetMilkTemperature}°C",
                            style: theme.TextStyles.tabHeading),
                        Slider(
                          value: settings.targetMilkTemperature.toDouble(),
                          max: 80,
                          min: 20,
                          divisions: 60,
                          label: "${settings.targetMilkTemperature} °C",
                          onChanged: (double value) {
                            setState(() {
                              settings.targetMilkTemperature = value.toInt();
                              machineService.updateSettings(settings);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (tempService.state == TempState.connected)
                StreamBuilder<TempMeassurement>(
                    stream: tempService.stream,
                    builder: (context, snapshot) {
                      return snapshot.hasData
                          ? Expanded(
                              child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _buildGraphSingleFlCharts(),
                            ))
                          : const Text("No data");
                    }),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: StartStopButton(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _buildControls(),
    );
  }

  Map<String, List<FlSpot>> _createDataFlCharts() {
    return {
      "temp1": tempService.history.map((e) => FlSpot(e.time, e.temp1)).toList(),
      "temp2": tempService.history.map((e) => FlSpot(e.time, e.temp2)).toList(),
    };
  }

  Widget _buildGraphSingleFlCharts() {
    Map<String, List<FlSpot>> data = _createDataFlCharts();

    double maxTime = 0;
    try {
      var maxData = data["temp1"]!.last;
      var t = maxData.x;

      var corrected = (t ~/ 5.0).toInt() * 5.0 + 5;
      maxTime = max(45, corrected);
    } catch (ex) {}

    var flowChart2 = LineChart(
      LineChartData(
        minY: 0,
        maxY: machineService.settings.targetMilkTemperature.toDouble() + 15,
        minX: data["temp1"]!.first.x,
        maxX: maxTime,
        lineTouchData: LineTouchData(enabled: false),
        clipData: FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
        ),
        lineBarsData: [
          createChartLineDatapoints(data["temp1"]!, 4, theme.ThemeColors.tempColor),
          createChartLineDatapoints(data["temp2"]!, 2, theme.ThemeColors.flowColor),
        ],
        titlesData: FlTitlesData(
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
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
          rightTitles: AxisTitles(
            axisNameSize: 25,
            axisNameWidget: Text(
              'Temp [°C]',
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
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 30,
                  child: LegendsListWidget(
                    legends: [
                      Legend('Temp Tip', theme.ThemeColors.tempColor),
                      Legend('Ambient', theme.ThemeColors.flowColor),
                    ],
                  ),
                ),
              ),
              OutlinedButton(
                  onPressed: () {
                    tempService.resetHistory();
                  },
                  child: const Text("Reset")),
            ],
          ),
          if (data["temp1"]!.length > 2)
            Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: flowChart2,
                )),
        ],
      ),
    );
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
