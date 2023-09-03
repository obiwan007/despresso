import 'dart:async';
import 'dart:math';

import 'package:dashboard/dashboard.dart';
import 'package:despresso/devices/decent_de1.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/ui/widgets/dashboard/add_dialog.dart';
import 'package:despresso/ui/widgets/dashboard/colored_dashboard_item.dart';
import 'package:despresso/ui/widgets/dashboard/storage.dart';
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

  late DashboardItemController<ColoredDashboardItem>
      itemController; //  = DashboardItemController<ColoredDashboardItem>(items: items);

  bool refreshing = false;

  // var storage = MyItemStorage();

  int? slot;

  late CoffeeService coffeeService;

  MyItemStorage _storage = MyItemStorage();

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
    coffeeService = getIt<CoffeeService>();
    initItems();
    itemController.addListener(() {});
  }

  @override
  void dispose() {
    super.dispose();

    log.info('Disposed DashboardScreen');
  }

  initItems() {
    // List<ColoredDashboardItem> items = [
    //   ColoredDashboardItem(
    //     startX: 0,
    //     height: 1,
    //     width: 1,
    //     identifier: "1",
    //     color: Colors.yellow,
    //     data: "kpi",
    //     dataHeader: "#",
    //     dataFooter: "Shots",
    //     title: "Shots",
    //     subTitle: "Shots done over time",
    //     // footer: "Shots",
    //     // subFooter: "Shots",
    //     value: coffeeService.shotBox.count().toString(),
    //   ),
    //   ColoredDashboardItem(
    //     startX: 1,
    //     height: 1,
    //     width: 1,
    //     identifier: "2",
    //     color: Colors.green,
    //     data: "kpi",
    //     //dataHeader: "#",
    //     //dataFooter: "Recipes",
    //     title: "Recipes",
    //     // subTitle: "Shots done over time",
    //     // footer: "Shots",
    //     // subFooter: "Shots",
    //     value: coffeeService.recipeBox.count().toString(),
    //   ),
    //   ColoredDashboardItem(
    //     startX: 2,
    //     startY: 0,
    //     height: 1,
    //     width: 1,
    //     identifier: "3",
    //     color: Colors.red,
    //     data: "kpi",
    //     //dataHeader: "#",
    //     // dataFooter: "Beans",
    //     title: "Beans",
    //     // subTitle: "Shots done over time",
    //     // footer: "Shots",
    //     // subFooter: "Shots",
    //     value: coffeeService.coffeeBox.count().toString(),
    //   ),
    //   ColoredDashboardItem(
    //       title: "Recipe Distribution",
    //       subTitle: "Show shots per recipe",
    //       startX: 0,
    //       startY: 1,
    //       height: 2,
    //       width: 4,
    //       identifier: "4",
    //       data: "shotsperrecipe"),
    //   ColoredDashboardItem(
    //       title: "Shots Distribution",
    //       subTitle: "Show shots over time",
    //       startX: 4,
    //       startY: 1,
    //       height: 2,
    //       width: 4,
    //       identifier: "5",
    //       data: "shotspertime"),
    //   // ColoredDashboardItem(
    //   //     startX: 3, startY: 1, height: 2, width: 2, identifier: "11", color: Colors.orange, data: "info")
    // ];

    //itemController = DashboardItemController<ColoredDashboardItem>(items: items);
    itemController = DashboardItemController.withDelegate(itemStorageDelegate: _storage);
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
          IconButton(
              onPressed: () async {
                await _storage.clear();
                setState(() {
                  refreshing = true;
                });
                _storage = MyItemStorage();
                itemController = DashboardItemController.withDelegate(itemStorageDelegate: _storage);
                Future.delayed(const Duration(milliseconds: 150)).then((value) {
                  setState(() {
                    refreshing = false;
                  });
                });
              },
              icon: const Icon(Icons.refresh)),
          IconButton(
              onPressed: () {
                itemController.clear();
              },
              icon: const Icon(Icons.delete)),
          IconButton(
              onPressed: () {
                add(context);
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
          body: refreshing
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Dashboard(
                  shrinkToPlace: false,
                  slideToTop: false,
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

  Future<void> add(BuildContext context) async {
    var res = await showDialog(
        context: context,
        builder: (c) {
          var sample = ColoredDashboardItem(
              widgetDataSource: WidgetDataSource.beansSum,
              color: Colors.red,
              width: 1,
              height: 1,
              title: "My Beans",
              subTitle: "",
              dataHeader: "#",
              dataFooter: "beans",
              footer: "test",
              subFooter: "foot",
              startX: 1,
              startY: 3,
              data: "kpi",
              identifier: (Random().nextInt(100000) + 4).toString(),
              minWidth: 1,
              minHeight: 1,
              maxWidth: null,
              maxHeight: null);

          return AddDialog(data: sample);
        });

    if (res != null) {
      print(res);
      itemController.add(res,
          // ColoredDashboardItem(
          //     widgetDataSource: res[9],
          //     color: Colors.red,
          //     width: res[0],
          //     height: res[1],
          //     title: res[6],
          //     subTitle: res[7],
          //     dataHeader: res[10],
          //     dataFooter: res[11],
          //     footer: res[12],
          //     subFooter: res[13],
          //     startX: 1,
          //     startY: 3,
          //     data: res[8],
          //     identifier: (Random().nextInt(100000) + 4).toString(),
          //     minWidth: res[2],
          //     minHeight: res[3],
          //     maxWidth: res[4] == 0 ? null : res[4],
          //     maxHeight: res[5] == 0 ? null : res[5]),
          mountToTop: false);
    }
  }
}
