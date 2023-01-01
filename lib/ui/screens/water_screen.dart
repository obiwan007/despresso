import 'package:despresso/devices/decent_de1.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;

import '../../model/shotstate.dart';
import '../widgets/start_stop_button.dart';

class WaterScreen extends StatefulWidget {
  @override
  _WaterScreenState createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  late EspressoMachineService machineService;
  late ScaleService scaleService;

  double _currentTemperature = 60;
  double _currentAmount = 100;
  double _currentSteamAutoOff = 45;
  double _currentFlushAutoOff = 15;
  List<ShotState> dataPoints = [];
  EspressoMachineState currentState = EspressoMachineState.disconnected;

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    machineService.addListener(machineStateListener);

    // Scale services is consumed as stream
    scaleService = getIt<ScaleService>();
  }

  @override
  void dispose() {
    super.dispose();
    machineService.removeListener(machineStateListener);
  }

  machineStateListener() {
    setState(() => {currentState = machineService.state.coffeeState});
    // machineService.de1?.setIdleState();
  }

  List<charts.Series<ShotState, double>> _createData() {
    return [
      charts.Series<ShotState, double>(
        id: 'Pressure',
        domainFn: (ShotState point, _) => point.sampleTime,
        measureFn: (ShotState point, _) => point.groupPressure,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.Colors.backgroundColor),
        strokeWidthPxFn: (_, __) => 3,
        data: dataPoints,
      ),
      charts.Series<ShotState, double>(
        id: 'Flow',
        domainFn: (ShotState point, _) => point.sampleTime,
        measureFn: (ShotState point, _) => point.groupFlow,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.Colors.secondaryColor),
        strokeWidthPxFn: (_, __) => 3,
        data: dataPoints,
      ),
    ];
  }

  Widget _buildWaterControl() {
    return ButtonBar(
      children: [
        Text(
          'Water:',
          style: theme.TextStyles.tabPrimary,
        ),
        ElevatedButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(theme.Colors.primaryColor),
            backgroundColor: MaterialStateProperty.all<Color>(theme.Colors.goodColor),
          ),
          child: Text(
            '-5',
            style: theme.TextStyles.tabSecondary,
          ),
          onPressed: () {
            setState(() {
              _currentAmount = _currentAmount - 5;
            });
          },
        ),
        Slider(
          value: _currentAmount,
          min: 0,
          max: 250,
          divisions: ((250 - 0) / 5).round(),
          label: _currentAmount.round().toString(),
          onChanged: (double value) {
            setState(() {
              _currentAmount = value;
            });
          },
        ),
        ElevatedButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(theme.Colors.primaryColor),
            backgroundColor: MaterialStateProperty.all<Color>(theme.Colors.goodColor),
          ),
          child: Text(
            '+5',
            style: theme.TextStyles.tabSecondary,
          ),
          onPressed: () {
            setState(() {
              _currentAmount = _currentAmount + 5;
            });
          },
        ),
      ],
      alignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
    );
  }

  Widget _buildSteamConrol() {
    return ButtonBar(
      children: [
        Text(
          'Steam Timeout: ',
          style: theme.TextStyles.tabPrimary,
        ),
        ElevatedButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(theme.Colors.primaryColor),
            backgroundColor: MaterialStateProperty.all<Color>(theme.Colors.goodColor),
          ),
          child: Text(
            '-1',
            style: theme.TextStyles.tabSecondary,
          ),
          onPressed: () {
            setState(() {
              _currentSteamAutoOff = _currentSteamAutoOff - 1;
            });
          },
        ),
        Slider(
          value: _currentSteamAutoOff,
          min: 0,
          max: 100,
          divisions: ((100 - 0) / 1).round(),
          label: _currentSteamAutoOff.round().toString(),
          onChanged: (double value) {
            setState(() {
              _currentSteamAutoOff = value;
            });
          },
        ),
        ElevatedButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(theme.Colors.primaryColor),
            backgroundColor: MaterialStateProperty.all<Color>(theme.Colors.goodColor),
          ),
          child: Text(
            '+1',
            style: theme.TextStyles.tabSecondary,
          ),
          onPressed: () {
            setState(() {
              _currentSteamAutoOff = _currentSteamAutoOff + 1;
            });
          },
        ),
      ],
      alignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
    );
  }

  Widget _buildTemperaturControl() {
    return ButtonBar(
      children: [
        Text(
          'Water Temperature: ',
          style: theme.TextStyles.tabPrimary,
        ),
        ElevatedButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(theme.Colors.primaryColor),
            backgroundColor: MaterialStateProperty.all<Color>(theme.Colors.goodColor),
          ),
          child: Text(
            '-1',
            style: theme.TextStyles.tabSecondary,
          ),
          onPressed: () {
            setState(() {
              _currentTemperature = _currentTemperature - 1;
            });
          },
        ),
        Slider(
          value: _currentTemperature,
          min: 20,
          max: 100,
          divisions: 80,
          label: _currentTemperature.round().toString(),
          onChanged: (double value) {
            setState(() {
              _currentTemperature = value;
            });
          },
        ),
        ElevatedButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(theme.Colors.primaryColor),
            backgroundColor: MaterialStateProperty.all<Color>(theme.Colors.goodColor),
          ),
          child: Text(
            '+1',
            style: theme.TextStyles.tabSecondary,
          ),
          onPressed: () {
            setState(() {
              _currentTemperature = _currentTemperature + 1;
            });
          },
        ),
      ],
      alignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
    );
  }

  Widget _buildFlushControl() {
    return ButtonBar(
      children: [
        Text(
          'Flush Timeout: ',
          style: theme.TextStyles.tabPrimary,
        ),
        ElevatedButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(theme.Colors.primaryColor),
            backgroundColor: MaterialStateProperty.all<Color>(theme.Colors.goodColor),
          ),
          child: Text(
            '-1',
            style: theme.TextStyles.tabSecondary,
          ),
          onPressed: () {
            setState(() {
              _currentFlushAutoOff = _currentFlushAutoOff - 1;
            });
          },
        ),
        Slider(
          value: _currentFlushAutoOff,
          min: 0,
          max: 180,
          divisions: ((180 - 0)).round(),
          label: _currentFlushAutoOff.round().toString(),
          onChanged: (double value) {
            setState(() {
              _currentFlushAutoOff = value;
            });
          },
        ),
        ElevatedButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(theme.Colors.primaryColor),
            backgroundColor: MaterialStateProperty.all<Color>(theme.Colors.goodColor),
          ),
          child: Text(
            '+1',
            style: theme.TextStyles.tabSecondary,
          ),
          onPressed: () {
            setState(() {
              _currentFlushAutoOff = _currentFlushAutoOff + 1;
            });
          },
        ),
      ],
      alignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
    );
  }

  Widget _buildGraph() {
    return Container(
      height: 150,
      margin: const EdgeInsets.only(left: 10.0),
      width: MediaQuery.of(context).size.width * 0.75,
      decoration: BoxDecoration(
        color: theme.Colors.tabColor,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: charts.LineChart(
        _createData(),
        animate: true,
        behaviors: [],
        primaryMeasureAxis: charts.NumericAxisSpec(
          renderSpec: charts.GridlineRendererSpec(
            labelStyle: charts.TextStyleSpec(fontSize: 10, color: charts.MaterialPalette.white),
            lineStyle: charts.LineStyleSpec(thickness: 0, color: charts.MaterialPalette.gray.shadeDefault),
          ),
        ),
        domainAxis: charts.NumericAxisSpec(
          renderSpec: charts.GridlineRendererSpec(
            labelStyle: charts.TextStyleSpec(fontSize: 10, color: charts.MaterialPalette.white),
            lineStyle: charts.LineStyleSpec(thickness: 0, color: charts.MaterialPalette.gray.shadeDefault),
          ),
        ),
      ),
    );
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
                  child: Column(
                    children: [
                      Text("Temperatur ${settings.targetHotWaterTemp}°C", style: theme.TextStyles.tabHeading),
                      Slider(
                        value: settings.targetHotWaterTemp.toDouble(),
                        max: 100,
                        min: 30,
                        divisions: 100,
                        label: "${settings.targetHotWaterTemp} °C",
                        onChanged: (double value) {
                          setState(() {
                            settings.targetHotWaterTemp = value.toInt();
                          });
                        },
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
                            Text("Timer ${settings.targetHotWaterLength} s", style: theme.TextStyles.tabHeading),
                            Slider(
                              value: settings.targetHotWaterLength.toDouble(),
                              max: 100,
                              min: 5,
                              divisions: 200,
                              label: "${settings.targetHotWaterLength} s",
                              onChanged: (double value) {
                                setState(() {
                                  settings.targetHotWaterLength = value.toInt();
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
                            Center(
                              child: Container(
                                width: 200,
                                height: 200,
                                child: CircularProgressIndicator(
                                  strokeWidth: 15,
                                  value: machineService.timer.inSeconds / settings.targetHotWaterLength,
                                ),
                              ),
                            ),
                            Center(child: Text("${machineService.timer.inSeconds.toStringAsFixed(0)} g")),
                          ],
                        ),
                        // CircularProgressIndicator(
                        //   value: machineService.scaleService.weight / settings.targetHotWaterWeight,
                        //   semanticsLabel: 'Current Weight',
                        // ),
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
                            Text("Weight ${settings.targetHotWaterWeight} g", style: theme.TextStyles.tabHeading),
                            Slider(
                              value: settings.targetHotWaterWeight.toDouble(),
                              max: 200,
                              min: 10,
                              divisions: 200,
                              label: "${settings.targetHotWaterWeight} g",
                              onChanged: (double value) {
                                setState(() {
                                  settings.targetHotWaterWeight = value.toInt();
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
                            Center(
                              child: Container(
                                width: 200,
                                height: 200,
                                child: CircularProgressIndicator(
                                  strokeWidth: 15,
                                  value: machineService.scaleService.weight / settings.targetHotWaterWeight,
                                ),
                              ),
                            ),
                            Center(child: Text("${machineService.scaleService.weight.toStringAsFixed(0)} g")),
                          ],
                        ),
                        // CircularProgressIndicator(
                        //   value: machineService.scaleService.weight / settings.targetHotWaterWeight,
                        //   semanticsLabel: 'Current Weight',
                        // ),
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const StartStopButton(),
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
}
