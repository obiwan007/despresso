import 'dart:math';

import 'package:despresso/devices/decent_de1.dart';
import 'package:despresso/helper/message.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/ble/temperature_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/widgets/legend_list.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:despresso/generated/l10n.dart';
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

  late SettingsService settings;

  int _parseIntInRange(String value, int min, int max, int fallback) {
    final parsed = int.tryParse(value);
    if (parsed == null) return fallback;
    if (parsed < min) return min;
    if (parsed > max) return max;
    return parsed;
  }

  double _parseDoubleInRange(String value, double min, double max, double fallback) {
    final parsed = double.tryParse(value);
    if (parsed == null) return fallback;
    if (parsed < min) return min;
    if (parsed > max) return max;
    return parsed;
  }

  Widget _buildIntInput({required int value, required int min, required int max, required String suffix, required void Function(int value) onValue}) {
    final controller = TextEditingController(text: value.toString());
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          final parsed = _parseIntInRange(controller.text, min, max, value);
          onValue(parsed);
        }
      },
      child: TextField(
        key: ValueKey(value),
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), suffixText: suffix),
        onSubmitted: (text) {
          final parsed = _parseIntInRange(text, min, max, value);
          onValue(parsed);
        },
      ),
    );
  }

  Widget _buildDoubleInput({
    required double value,
    required double min,
    required double max,
    required String suffix,
    required int decimals,
    required RegExp formatterPattern,
    required void Function(double value) onValue,
  }) {
    final controller = TextEditingController(text: value.toStringAsFixed(decimals));
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          final parsed = _parseDoubleInRange(controller.text, min, max, value);
          onValue(parsed);
        }
      },
      child: TextField(
        key: ValueKey(value),
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(formatterPattern)],
        decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), suffixText: suffix),
        onSubmitted: (text) {
          final parsed = _parseDoubleInRange(text, min, max, value);
          onValue(parsed);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    settings = getIt<SettingsService>();
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
    setState(() => currentState = machineService.state.coffeeState);
    // machineService.de1?.setIdleState();
  }

  tempStateListener() {
    setState(() => {});
    // machineService.de1?.setIdleState();
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(S.of(context).screenSteamTwotapMode,
                                  style: Theme.of(context).textTheme.labelLarge),
                            ),
                            Switch(
                              value: machineService.de1?.steamPurgeMode == 1,
                              onChanged: (value) {
                                if (machineService.state.coffeeState != EspressoMachineState.steam) {
                                  machineService.de1?.setSteamPurgeMode(value == true ? 1 : 0);
                                  setState(() {});
                                  machineService.notify();
                                }
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                machineService.de1?.steamPurgeMode == 1
                                    ? S.of(context).screenSteamOnSlowPurgeOn1stStop
                                    : S.of(context).screenSteamOffNormalPurgeAfterStop,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(S.of(context).screenSteamTemperaturs(settings.targetSteamTemp), style: Theme.of(context).textTheme.labelLarge),
                              Row(
                                children: [
                                  Expanded(
                                    child: Slider(
                                      value: settings.targetSteamTemp.toDouble(),
                                      max: 180,
                                      min: 100,
                                      divisions: 80,
                                      label: "${settings.targetSteamTemp} °C",
                                      onChanged: (double value) {
                                        setState(() {
                                          settings.targetSteamTemp = value.toInt();
                                          machineService.updateSettings();
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 90,
                                    child: _buildIntInput(
                                      value: settings.targetSteamTemp,
                                      min: 100,
                                      max: 180,
                                      suffix: "°C",
                                      onValue: (value) {
                                        setState(() {
                                          settings.targetSteamTemp = value;
                                          machineService.updateSettings();
                                        });
                                      },
                                    ),
                                  ),
                                ],
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
                              Text(S.of(context).screenSteamTimerS(settings.targetSteamLength.toInt()),
                                  style: Theme.of(context).textTheme.labelLarge),
                              Row(
                                children: [
                                  Expanded(
                                    child: Slider(
                                      value: settings.targetSteamLength.toDouble(),
                                      max: 200,
                                      min: 1,
                                      divisions: 200,
                                      label: "${settings.targetSteamLength} s",
                                      onChanged: (double value) {
                                        setState(() {
                                          settings.targetSteamLength = value.toInt();
                                          machineService.updateSettings();
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 90,
                                    child: _buildIntInput(
                                      value: settings.targetSteamLength.toInt(),
                                      min: 1,
                                      max: 200,
                                      suffix: "s",
                                      onValue: (value) {
                                        setState(() {
                                          settings.targetSteamLength = value;
                                          machineService.updateSettings();
                                        });
                                      },
                                    ),
                                  ),
                                ],
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
                    Column(
                      children: [
                        Text(S.of(context).screenSteamStopAtTemperatur(settings.targetMilkTemperature),
                            style: Theme.of(context).textTheme.labelLarge),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: settings.targetMilkTemperature.toDouble(),
                                max: 80,
                                min: 20,
                                divisions: 60,
                                label: "${settings.targetMilkTemperature} °C",
                                onChanged: (double value) {
                                  setState(() {
                                    settings.targetMilkTemperature = value.toInt();
                                    machineService.updateSettings();
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: _buildIntInput(
                                value: settings.targetMilkTemperature,
                                min: 20,
                                max: 80,
                                suffix: "°C",
                                onValue: (value) {
                                  setState(() {
                                    settings.targetMilkTemperature = value;
                                    machineService.updateSettings();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
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
                              Text(S.of(context).screenSteamFlowrate(settings.targetSteamFlow.toStringAsFixed(1)),
                                  style: Theme.of(context).textTheme.labelLarge),
                              Row(
                                children: [
                                  Expanded(
                                    child: Slider(
                                      value: settings.targetSteamFlow,
                                      max: 4.5,
                                      min: 0.5,
                                      divisions: 40,
                                      label: "${settings.targetSteamFlow.toStringAsFixed(1)} ml/s",
                                      onChanged: (double value) {
                                        setState(() {
                                          settings.targetSteamFlow = value;
                                          machineService.de1?.setSteamFlow(value);
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 90,
                                    child: _buildDoubleInput(
                                      value: settings.targetSteamFlow,
                                      min: 0.5,
                                      max: 4.5,
                                      decimals: 1,
                                      suffix: "ml/s",
                                      formatterPattern: RegExp(r'^\d*\.?\d{0,1}'),
                                      onValue: (value) {
                                        setState(() {
                                          settings.targetSteamFlow = value;
                                          machineService.de1?.setSteamFlow(value);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                    child: (tempService.state != TempState.connected)
                        ? Container()
                        : Wrap(
                            direction: Axis.vertical,
                            spacing: 10,
                            children: [
                              OutlinedButton(
                                  onLongPress: () {
                                    settings.targetMilkTempPreset1 = settings.targetMilkTemperature;
                                    showOk(context, "Saved");
                                  },
                                  onPressed: () {
                                    settings.targetMilkTemperature = settings.targetMilkTempPreset1;
                                    machineService.updateSettings();
                                  },
                                  child: Column(
                                    children: [
                                      const Text("Stop 1"),
                                      Text(
                                        "${settings.targetMilkTempPreset1}°C",
                                        style: Theme.of(context).textTheme.labelSmall,
                                      ),
                                    ],
                                  )),
                              OutlinedButton(
                                  onLongPress: () {
                                    settings.targetMilkTempPreset2 = settings.targetMilkTemperature;
                                    showOk(context, "Saved");
                                  },
                                  onPressed: () {
                                    settings.targetMilkTemperature = settings.targetMilkTempPreset2;
                                    machineService.updateSettings();
                                  },
                                  child: Column(
                                    children: [
                                      const Text("Stop 2"),
                                      Text(
                                        "${settings.targetMilkTempPreset2}°C",
                                        style: Theme.of(context).textTheme.labelSmall,
                                      ),
                                    ],
                                  )),
                              OutlinedButton(
                                  onLongPress: () {
                                    settings.targetMilkTempPreset3 = settings.targetMilkTemperature;
                                    showOk(context, "Saved");
                                  },
                                  onPressed: () {
                                    settings.targetMilkTemperature = settings.targetMilkTempPreset3;
                                    machineService.updateSettings();
                                  },
                                  child: Column(
                                    children: [
                                      const Text("Stop 3"),
                                      Text(
                                        "${settings.targetMilkTempPreset3}°C",
                                        style: Theme.of(context).textTheme.labelSmall,
                                      ),
                                    ],
                                  )),
                            ],
                          ),
                  ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: StartStopButton(requestedState: De1StateEnum.steam),
                  ),
                ],
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
      // ignore: empty_catches
    } catch (ex) {}

    var flowChart2 = LineChart(
      LineChartData(
        minY: 0,
        maxY: settings.targetMilkTemperature.toDouble() + 15,
        minX: data["temp1"]!.first.x,
        maxX: maxTime,
        lineTouchData: const LineTouchData(enabled: false),
        clipData: const FlClipData.all(),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: true,
        ),
        lineBarsData: [
          createChartLineDatapoints(data["temp1"]!, 4, theme.ThemeColors.tempColor),
          createChartLineDatapoints(data["temp2"]!, 2, theme.ThemeColors.flowColor),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            axisNameSize: 25,
            axisNameWidget: Text(
              S.of(context).screenSteamTimeS,
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
              S.of(context).steamScreenTempC,
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
                      Legend(S.of(context).screenSteamTempTip, theme.ThemeColors.tempColor),
                      Legend(S.of(context).screenSteamAmbient, theme.ThemeColors.flowColor),
                    ],
                  ),
                ),
              ),
              OutlinedButton(
                  onPressed: () {
                    tempService.resetHistory();
                  },
                  child: Text(S.of(context).screenSteamReset)),
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
      dotData: const FlDotData(
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
      meta: meta,
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
      meta: meta,
      space: 16,
      child: Text(meta.formattedValue, style: style),
    );
  }
}
