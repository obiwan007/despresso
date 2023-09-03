import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dashboard/src/dashboard_base.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/shot.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/widgets/dashboard/colored_dashboard_item.dart';
import 'package:despresso/ui/widgets/legend_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'add_dialog.dart';
import 'colorlist.dart';
import 'data_widget.dart';

class ShotsPerRecipe extends StatefulWidget {
  const ShotsPerRecipe({Key? key, required this.data, required this.controller}) : super(key: key);
  final ColoredDashboardItem data;
  final DashboardItemController<ColoredDashboardItem> controller;
  @override
  State<ShotsPerRecipe> createState() => _ShotsPerRecipeState();
}

class _ShotsPerRecipeState extends State<ShotsPerRecipe> {
  late CoffeeService _coffeeService;
  late List<Shot> allShots;

  Map<String, int> counts = HashMap();
  late LinkedHashMap<String, int> sortedMap;

  int touchedIndex = -1;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _coffeeService = getIt<CoffeeService>();
    allShots = _coffeeService.shotBox.getAll();

    for (var element in allShots) {
      try {
        if (element.recipe.target != null) {
          var key = element.recipe.target?.name;
          if (key == null) continue;
          if (counts[key] == null) {
            counts[key] = 0;
          }
          counts[key] = counts[key]! + 1;
        }
      } catch (e) {
        debugPrint("Error");
      }
    }
    var sortedKeys = counts.keys.toList(growable: false)..sort((k1, k2) => counts[k2]!.compareTo(counts[k1]!));
    sortedMap = LinkedHashMap.fromIterable(sortedKeys, key: (k) => k, value: (k) => counts[k]!);
    print(sortedMap);
  }

  @override
  Widget build(BuildContext context) {
    var legends = sortedMap.entries
        .mapIndexed((i, e) => Legend(
              e.key,
              colorList[i % colorList.length],
              e.value.toString(),
            ))
        .toList();

    return Container(
      color: Theme.of(context).focusColor,
      // color: yellow,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.data.title != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.data.title!,
                        textAlign: TextAlign.left,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (widget.controller.isEditing)
                      PopupMenuButton<SelectedWidgetMenu>(
                        initialValue: null,
                        // Callback that sets the selected popup menu item.
                        onSelected: (SelectedWidgetMenu item) async {
                          switch (item) {
                            case SelectedWidgetMenu.edit:
                              var res = await showDialog(
                                  context: context,
                                  builder: (c) {
                                    return AddDialog(data: widget.data);
                                  });
                              if (res != null) {
                                widget.controller.delete(widget.data.identifier);
                                widget.controller.add(res, mountToTop: false);
                              }
                              break;
                            case SelectedWidgetMenu.delete:
                              widget.controller.delete(widget.data.identifier);
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<SelectedWidgetMenu>>[
                          const PopupMenuItem<SelectedWidgetMenu>(
                            value: SelectedWidgetMenu.edit,
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem<SelectedWidgetMenu>(
                            value: SelectedWidgetMenu.delete,
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                  ],
                ),
              if (widget.data.subTitle != null)
                Row(
                  children: [
                    Text(
                      widget.data.subTitle!,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
            ],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: LayoutBuilder(builder: (context, constrains) {
                    var r = min(constrains.maxWidth, constrains.maxHeight) / 2;
                    return PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              print(touchedIndex);
                            });
                          },
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        sectionsSpace: 1,
                        centerSpaceRadius: r - 30,
                        sections: showingSections(20),
                      ),
                    );
                  }),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: SingleChildScrollView(child: LegendsListWidget(legends: legends, touchIndex: touchedIndex)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections(double radius) {
    // const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
    return sortedMap.entries.mapIndexed((i, e) {
      final isTouched = i == touchedIndex;
      var color = colorList[i % colorList.length];
      // var actCol = Color.fromRGBO(color.red, color.green, color.blue, isTouched || touchedIndex == -1 ? 1 : 0.5);
      var actCol = color.withOpacity(isTouched || touchedIndex == -1 ? 1 : 0.5);
      return PieChartSectionData(
        borderSide: isTouched ? BorderSide(color: color, width: 8) : BorderSide(color: color.withOpacity(0)),
        value: e.value.toDouble(),
        showTitle: false,
        // title: "${e.value} = ${(e.value / allShots.length * 100).toInt()}%",
        radius: radius + 10 * (isTouched == true ? 1 : 0),
        color: actCol,
        // titleStyle: TextStyle(
        //   fontSize: 11,
        //   fontWeight: FontWeight.bold,
        //   shadows: shadows,
        // ),
      );
    }).toList();
  }
}
