import 'dart:developer';
import 'dart:math' as math;

import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:community_charts_flutter/community_charts_flutter.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;

import '../../devices/decent_de1.dart';
import '../../model/shotstate.dart';
import '../widgets/start_stop_button.dart';

class EspressoScreen extends StatefulWidget {
  @override
  _EspressoScreenState createState() => _EspressoScreenState();
}

class _EspressoScreenState extends State<EspressoScreen> {
  late CoffeeService coffeeSelectionService;
  late EspressoMachineService machineService;
  late ProfileService profileService;
  late ScaleService scaleService;

  double baseTime = 0;

  String lastSubstate = '';

  String subState = "";

  bool refillAnounced = false;

  bool stopTriggered = false;

  double maxTime = 30;
  _EspressoScreenState() {}

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

        // if (machineService.state.coffeeState == EspressoMachineState.sleep ||
        //     machineService.state.coffeeState == EspressoMachineState.disconnected ||
        //     machineService.state.coffeeState == EspressoMachineState.refill) {
        //   return;
        // }
        // var shot = machineService.state.shot;
        // // if (machineService.state.subState.isNotEmpty) {
        // //   subState = machineService.state.subState;
        // // }
        // if (shot == null) {
        //   log('Shot null');
        //   return;
        // }
        // if (machineService.state.coffeeState == EspressoMachineState.idle) {
        //   refillAnounced = false;
        //   inShot = false;
        //   if (shotList.saved == false &&
        //       shotList.entries.isNotEmpty &&
        //       shotList.saving == false &&
        //       shotList.saved == false) {
        //     shotFinished();
        //   }

        //   return;
        // }
        // if (!inShot && machineService.state.coffeeState == EspressoMachineState.espresso) {
        //   log('Not Idle and not in Shot');
        //   inShot = true;
        //   shotList.clear();
        //   baseTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
        //   log("basetime $baseTime");
        // }

        // subState = machineService.state.subState;

        // if (!(shot.sampleTimeCorrected > 0 && inShot == true)) {
        //   if (lastSubstate != subState && subState.isNotEmpty) {
        //     log("SubState: $subState");
        //     lastSubstate = machineService.state.subState;
        //     shot.subState = lastSubstate;
        //   }

        //   shot.weight = scaleService.weight;
        //   shot.flowWeight = scaleService.flow;
        //   shot.sampleTimeCorrected = shot.sampleTime - baseTime;

        //   if (scaleService.state == ScaleState.connected &&
        //       profileService.currentProfile!.shot_header.target_weight > 1 &&
        //       shot.weight + 1 > profileService.currentProfile!.shot_header.target_weight) {
        //     log("Shot Weight reached ${shot.weight} > ${profileService.currentProfile!.shot_header.target_weight}");

        //     triggerEndOfShot();
        //   }
        //   //if (profileService.currentProfile.shot_header.target_weight)
        //   // log("Sample ${shot!.sampleTimeCorrected} ${shot.weight}");
        //   shotList.add(shot);
        // }
      });
  void triggerEndOfShot() {
    log("Idle mode initiated because of weight", error: {DateTime.now()});

    machineService.de1?.requestState(De1StateEnum.idle);
    // Future.delayed(const Duration(milliseconds: 5000), () {
    //   log("Idle mode initiated finished", error: {DateTime.now()});
    //   stopTriggered = false;
    // });
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

  // shotFinished() async {
  //   log("Save last shot");
  //   await shotList.saveData("testshot.json");
  // }

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
      var to = stateChanges[i];

      var col = theme.Colors.statesColors[from.subState];
      var col2 = charts.ColorUtil.fromDartColor(col ?? theme.Colors.goodColor);
      // col == null ? col! : charts.Color(r: 0xff, g: 50, b: i * 19, a: 100);
      return charts.RangeAnnotationSegment(
          from.sampleTimeCorrected, toSampleTime, charts.RangeAnnotationAxisType.domain,
          labelAnchor: charts.AnnotationLabelAnchor.end,
          color: col2,
          startLabel: from.subState,
          labelStyleSpec:
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.Colors.secondaryColor)),
          labelDirection: charts.AnnotationLabelDirection.vertical);
      // log("Phase ${element.subState}");
    });
  }

  List<charts.Series<ShotState, double>> _createData() {
    return [
      charts.Series<ShotState, double>(
        id: 'Pressure [bar]',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.groupPressure,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.Colors.pressureColor),
        strokeWidthPxFn: (_, __) => 3,
        data: machineService.shotList.entries,
      ),
      charts.Series<ShotState, double>(
        id: 'Flow [ml/s]',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.groupFlow,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.Colors.flowColor),
        strokeWidthPxFn: (_, __) => 3,
        data: machineService.shotList.entries,
      ),
      charts.Series<ShotState, double>(
        id: 'Temp [°C]',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.headTemp,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.Colors.tempColor),
        strokeWidthPxFn: (_, __) => 3,
        data: machineService.shotList.entries,
      ),
      charts.Series<ShotState, double>(
        id: 'Weight [g]',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.weight,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.Colors.weightColor),
        strokeWidthPxFn: (_, __) => 3,
        data: machineService.shotList.entries,
      ),
      charts.Series<ShotState, double>(
        id: 'Flow [g/s]',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.flowWeight,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.Colors.weightColor),
        strokeWidthPxFn: (_, __) => 3,
        data: machineService.shotList.entries,
      ),
      charts.Series<ShotState, double>(
        id: 'SetFlow [ml/s]',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.setGroupFlow,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.Colors.flowColor),
        dashPatternFn: (_, __) => [5, 5],
        strokeWidthPxFn: (_, __) => 3,
        data: machineService.shotList.entries,
      ),
      charts.Series<ShotState, double>(
        id: 'SetPressure [bar]',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.setGroupPressure,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.Colors.pressureColor),
        dashPatternFn: (datum, index) => [5, 5],
        strokeWidthPxFn: (_, __) => 3,
        data: machineService.shotList.entries,
      ),
      charts.Series<ShotState, double>(
        id: 'SetTemp [°C]',
        domainFn: (ShotState point, _) => point.sampleTimeCorrected,
        measureFn: (ShotState point, _) => point.setHeadTemp,
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(theme.Colors.tempColor),
        strokeWidthPxFn: (_, __) => 3,
        dashPatternFn: (datum, index) => [5, 5],
        data: machineService.shotList.entries,
      ),
    ];
  }

  _buildGraphs() {
    var ranges = _createPhases();
    var data = _createData();

    try {
      var maxData = data[1].data.last;
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

    var temp = _buildGraphTemp(data, ranges);
    var flow = _buildGraphFlow(data, ranges);
    var pressure = _buildGraphPressure(data, ranges);

    return {"temp": temp, "flow": flow, "pressure": pressure};
  }

  Widget _buildGraphTemp(List<Series<ShotState, double>> data, Iterable<RangeAnnotationSegment<double>> ranges) {
    var flowChart = charts.LineChart(
      [data[2], data[7]],
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
          labelStyle:
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.Colors.secondaryColor)),
          lineStyle:
              charts.LineStyleSpec(thickness: 0, color: charts.ColorUtil.fromDartColor(theme.Colors.secondaryColor)),
        ),
      ),
      primaryMeasureAxis: charts.NumericAxisSpec(
        tickProviderSpec: const charts.BasicNumericTickProviderSpec(zeroBound: false),
        renderSpec: charts.GridlineRendererSpec(
          labelStyle:
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
          lineStyle:
              charts.LineStyleSpec(thickness: 0, color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
        ),
      ),
      domainAxis: charts.NumericAxisSpec(
        viewport: NumericExtents(0, maxTime),
        renderSpec: charts.GridlineRendererSpec(
          labelStyle:
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
          lineStyle:
              charts.LineStyleSpec(thickness: 0, color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
        ),
      ),
    );

    return Container(
      height: 300,
      margin: const EdgeInsets.only(left: 10.0),
      width: MediaQuery.of(context).size.width - 105,
      decoration: BoxDecoration(
        color: theme.Colors.graphBackground,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: flowChart,
    );
  }

  Widget _buildGraphPressure(List<Series<ShotState, double>> data, Iterable<RangeAnnotationSegment<double>> ranges) {
    var flowChart = charts.LineChart(
      [data[0], data[6]],
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
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
          lineStyle:
              charts.LineStyleSpec(thickness: 0, color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
        ),
      ),
      domainAxis: charts.NumericAxisSpec(
        viewport: NumericExtents(0, maxTime),
        renderSpec: charts.GridlineRendererSpec(
          labelStyle:
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
          lineStyle:
              charts.LineStyleSpec(thickness: 0, color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
        ),
      ),
    );

    return Container(
      // height: 100,
      margin: const EdgeInsets.only(left: 10.0),
      width: MediaQuery.of(context).size.width - 105,
      decoration: BoxDecoration(
        color: theme.Colors.graphBackground,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: flowChart,
    );
  }

  Widget _buildGraphFlow(List<Series<ShotState, double>> data, Iterable<RangeAnnotationSegment<double>> ranges) {
    double maxWeight = (profileService.currentProfile?.shotHeader.targetWeight ?? 200.0) * 1.5;
    const secondaryMeasureAxisId = 'secondaryMeasureAxisId';

    var flowChart = charts.LineChart(
      [data[1], data[5], data[4], data[3]..setAttribute(charts.measureAxisIdKey, secondaryMeasureAxisId)],
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
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
          lineStyle:
              charts.LineStyleSpec(thickness: 0, color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
        ),
      ),
      primaryMeasureAxis: charts.NumericAxisSpec(
        tickProviderSpec: const charts.BasicNumericTickProviderSpec(zeroBound: false),
        renderSpec: charts.GridlineRendererSpec(
          labelStyle:
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
          lineStyle:
              charts.LineStyleSpec(thickness: 0, color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
        ),
      ),
      domainAxis: charts.NumericAxisSpec(
        viewport: charts.NumericExtents(0, maxTime),
        renderSpec: charts.GridlineRendererSpec(
          labelStyle:
              charts.TextStyleSpec(fontSize: 10, color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
          lineStyle:
              charts.LineStyleSpec(thickness: 0, color: charts.ColorUtil.fromDartColor(theme.Colors.primaryColor)),
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(left: 10.0),
      width: MediaQuery.of(context).size.width - 105,
      decoration: BoxDecoration(
        color: theme.Colors.graphBackground,
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
          // Row(
          //   children: [
          //     // const Text('Profile: ', style: theme.TextStyles.tabSecondary),
          //     Text(profileService.currentProfile!.shotHeader.title, style: theme.TextStyles.tabHeading),
          //   ],
          // ),
          // const Divider(
          //   height: 20,
          //   thickness: 5,
          //   indent: 0,
          //   endIndent: 0,
          // ),
          createKeyValue("Profile", profileService.currentProfile!.title),
          createKeyValue(
              "Coffee",
              coffeeSelectionService.selectedCoffee > 0
                  ? coffeeSelectionService.coffeeBox.get(coffeeSelectionService.selectedCoffee)?.name ?? ""
                  : "No Beans"),
          createKeyValue("Target", '${profileService.currentProfile?.shotHeader.targetWeight} g'),
          const Divider(
            height: 20,
            thickness: 5,
            indent: 0,
            endIndent: 0,
          ),
          createKeyValue("Timer", '${machineService.lastPourTime.toStringAsFixed(1)} s'),
          createKeyValue("Pouring", '${machineService.isPouring} '),
          createKeyValue("LastSubstate", '${machineService.lastSubstate} '),

          // createKeyValue("State", machineService.state.coffeeState.name.toString().toUpperCase()),
          // createKeyValue("Sub", machineService.state.subState),
          // createKeyValue("Pressure", "${machineService.state.shot!.groupPressure.toStringAsFixed(1)} bar"),
          // createKeyValue("Flow", '${machineService.state.shot!.groupFlow.toStringAsFixed(2)} ml/s'),
          // createKeyValue("Mix Temp", '${machineService.state.shot!.mixTemp.toStringAsFixed(2)} °C'),
          // createKeyValue("Head Temp", '${machineService.state.shot!.headTemp.toStringAsFixed(2)} °C'),
          // createKeyValue("Water", '${machineService.state.water?.getLevelPercent()}%'),
        ],
      );
    } else {
      insights = Text("${machineService.state.coffeeState.name} ${machineService.state.subState}",
          style: theme.TextStyles.tabPrimary);
    }
    return insights;
  }

  Column _buildScaleInsight() {
    return Column(
      children: [
        StreamBuilder<WeightMeassurement>(
          stream: scaleService.stream,
          initialData: WeightMeassurement(0, 0, ScaleState.disconnected),
          builder: (BuildContext context, AsyncSnapshot<WeightMeassurement> snapshot) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                createKeyValue("State", snapshot.data!.state.name),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: snapshot.data!.state == ScaleState.disconnected
                      ? [
                          ElevatedButton(
                            onPressed: () {
                              scaleService.connect();
                            },
                            child: const Text(
                              "Connect",
                            ),
                          ),
                        ]
                      : [],
                ),
                createKeyValue("Weight",
                    profileService.currentProfile != null ? '${snapshot.data!.weight.toStringAsFixed(1)} g' : '_'),
                // ElevatedButton(
                //   onPressed: () {
                //     scaleService.tare();
                //   },
                //   child: const Text(
                //     "Tare",
                //   ),
                // ),
                createKeyValue(
                    "",
                    profileService.currentProfile != null
                        ? '${profileService.currentProfile!.shotHeader.targetWeight} g'
                        : '_'),
                createKeyValue("Flow", '${snapshot.data!.flow.toStringAsFixed(1)} g/s'),
              ],
            );
          },
        ),
        const Spacer(),
      ],
    );
  }

  Row _buildButtons() {
    return Row(
      children: [
        Spacer(flex: 1),
        Expanded(
          flex: 1,
          child: IconButton(
            iconSize: 50,
            isSelected: machineService.state.coffeeState == EspressoMachineState.sleep,
            icon: const Icon(Icons.power_settings_new, color: Colors.green),
            selectedIcon: const Icon(
              Icons.power_off,
              color: Colors.red,
            ),
            tooltip: 'Switch on/off decent de1',
            onPressed: () {
              if (machineService.state.coffeeState == EspressoMachineState.sleep) {
                machineService.de1?.switchOn();
              } else {
                machineService.de1?.switchOff();
              }
            },
          ),
        ),
        // Expanded(
        //   flex: 1,
        //   child: IconButton(
        //     iconSize: 50,
        //     isSelected: machineService.state.coffeeState == EspressoMachineState.sleep,
        //     icon: const Icon(Icons.power_off),
        //     selectedIcon: const Icon(Icons.power_settings_new),
        //     tooltip: 'Test',
        //     onPressed: () {
        //       _displayDialog(context);
        //     },
        //   ),
        // ),
      ],
    );
  }

  var pressAttention = true;

  _displayDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 500),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'Hai This Is Full Screen Dialog',
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "DISMISS",
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Row createKeyValue(String key, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
            flex: 1, // takes 30% of available width
            child: Text(key, style: theme.TextStyles.tabHeading)),
        Expanded(
            flex: 1, // takes 30% of available width
            child: Text(value, style: theme.TextStyles.tabPrimary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> graphs = {};
    var isEmpty = machineService.shotList.entries.isEmpty;
    if (!isEmpty) {
      graphs = _buildGraphs();
    }
    var isSelected = machineService.state.coffeeState == EspressoMachineState.espresso;

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
                  Spacer(),
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
