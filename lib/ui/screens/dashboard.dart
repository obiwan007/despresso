import 'dart:async';

import 'package:dashboard/dashboard.dart';
import 'package:despresso/devices/decent_de1.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/ui/widgets/start_stop_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:logging/logging.dart';
import 'package:despresso/ui/widgets/dashboard/data_widget.dart';
import '../../service_locator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final log = Logger('DashboardScreen');

  late SettingsService settingsService;
  late EspressoMachineService machineService;

  final ScrollController scrollController = ScrollController();
  List<ColoredDashboardItem> items = [
    ColoredDashboardItem(height: 2, width: 2, identifier: "1", color: Colors.red, data: "basic"),
    ColoredDashboardItem(height: 2, width: 3, identifier: "2", color: Colors.green, data: "shotsperrecipe"),
    ColoredDashboardItem(height: 2, width: 2, identifier: "3", color: Colors.orange, data: "info")
  ];

  ///
  late var itemController = DashboardItemController<ColoredDashboardItem>(items: items);

  bool refreshing = false;

  // var storage = MyItemStorage();

  int? slot;

  setSlot() {
    var w = MediaQuery.of(context).size.width;
    setState(() {
      slot = w > 600
          ? w > 900
              ? 8
              : 6
          : 4;
    });
  }

  List<String> d = [];

  @override
  initState() {
    super.initState();
    settingsService = getIt<SettingsService>();
    machineService = getIt<EspressoMachineService>();

    itemController.addListener(() {});
  }

  @override
  void dispose() {
    super.dispose();

    log.info('Disposed DashboardScreen');
  }

  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    slot = w > 600
        ? w > 900
            ? 8
            : 6
        : 4;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.pop(context, null),
        ),
        title: const Text('Statistics Dashboard'),
        actions: [
          IconButton(onPressed: () async {}, icon: const Icon(Icons.refresh)),
          IconButton(
              onPressed: () {
                itemController.clear();
              },
              icon: const Icon(Icons.delete)),
          IconButton(
              onPressed: () {
                // add(context);
              },
              icon: const Icon(Icons.add)),
          IconButton(
              onPressed: () {
                itemController.isEditing = !itemController.isEditing;
                setState(() {});
              },
              icon: const Icon(Icons.edit)),
        ],
      ),
      body: Scaffold(
          body: Dashboard(
        shrinkToPlace: false,
        slideToTop: true,
        absorbPointer: false,
        padding: const EdgeInsets.all(8),
        horizontalSpace: 8,
        verticalSpace: 8,
        slotAspectRatio: 1,
        animateEverytime: true,
        slotCount: slot!,
        errorPlaceholder: (e, s) {
          return Text("$e , $s");
        },
        itemStyle: ItemStyle(
            color: Colors.transparent,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        physics: const RangeMaintainingScrollPhysics(),
        editModeSettings: EditModeSettings(
            paintBackgroundLines: true,
            resizeCursorSide: 15,
            curve: Curves.easeOut,
            duration: const Duration(milliseconds: 300),
            backgroundStyle: const EditModeBackgroundStyle(
                lineColor: Colors.black38, lineWidth: 0.5, dualLineHorizontal: true, dualLineVertical: true)),
        dashboardItemController: itemController,
        itemBuilder: (item) {
          var layout = item.layoutData;
          if (item.data != null) {
            return DataWidget(
              item: item,
            );
          }
          return Text(item.identifier);
        },
      )),
    );
  }
}
