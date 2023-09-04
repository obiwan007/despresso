import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dashboard/dashboard.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/shot.dart';
import 'package:despresso/objectbox.g.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/widgets/dashboard/add_dialog.dart';
import 'package:despresso/ui/widgets/dashboard/colored_dashboard_item.dart';
import 'package:despresso/ui/widgets/dashboard/colorlist.dart';
import 'package:despresso/ui/widgets/dashboard/data_widget.dart';
import 'package:despresso/ui/widgets/legend_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShotsPerTime extends StatefulWidget {
  const ShotsPerTime({Key? key, required this.data, required this.controller}) : super(key: key);
  final ColoredDashboardItem data;
  final DashboardItemController<ColoredDashboardItem> controller;
  @override
  State<ShotsPerTime> createState() => _ShotsPerTimeState();
}

class _ShotsPerTimeState extends State<ShotsPerTime> {
  late CoffeeService _coffeeService;
  late List<Shot> allShots;

  late LinkedHashMap<String, LinkedHashMap<String, int>> sortedMap = LinkedHashMap();
  late LinkedHashMap<String, int> colormap = LinkedHashMap();
  int touchedIndex = -1;
  TimeRanges _selectedTimeRange = TimeRanges.allData;
  DateTime time = DateTime.now();
  var timeRanges = [
    const DropdownMenuItem(
      value: 1,
      child: Text("Day"),
    ),
    const DropdownMenuItem(
      value: 7,
      child: Text("Week"),
    ),
    const DropdownMenuItem(
      value: 30,
      child: Text("Month"),
    )
  ];

  @override
  void initState() {
    super.initState();
    _coffeeService = getIt<CoffeeService>();
    _selectedTimeRange = widget.data.range!.range;
    //allShots = _coffeeService.shotBox.getAll();
    // time = allShots.last.date;
    calcData();
    // var sortedKeys = counts.keys.toList(growable: false)..sort((k1, k2) => counts[k2]!.compareTo(counts[k1]!));
    // sortedMap = counts; // LinkedHashMap.fromIterable(sortedKeys, key: (k) => k, value: (k) => counts[k]!);
    // print(sortedMap);
  }

  void calcData() {
    _selectedTimeRange = widget.data.range!.range;
    time = widget.data.range!.from;
    var fromTo = widget.data.range!.getFrame();

    sortedMap.clear();
    if (_selectedTimeRange != TimeRanges.today) {
      var f = fromTo.start;
      while (f.isBefore(fromTo.end)) {
        var key = "${f.day}_${f.month}_${f.year}";
        f = f.add(Duration(days: 1));

        sortedMap[key] = LinkedHashMap();
      }
      // for (var i = 1; i < _selectedTimeRange; i++) {
      //   var d = time.subtract(Duration(days: i));
      //   var key = "${d.day}_${d.month}_${d.year}";
      //   sortedMap[key] = LinkedHashMap();
      // }
    }
    if (_selectedTimeRange == TimeRanges.today) {
      for (var i = 0; i < 24; i++) {
        var d = time.subtract(Duration(hours: i));
        var key = "${d.hour}";
        sortedMap[key] = LinkedHashMap();
      }
    }

    final builder = getIt<CoffeeService>()
        .shotBox
        .query(Shot_.date.between(fromTo.start.millisecondsSinceEpoch, fromTo.end.millisecondsSinceEpoch))
        .build();
    allShots = builder.find();
    for (var element in allShots) {
      try {
        var d = element.date;
        if (true || d.isBefore(fromTo.end) && d.isAfter(fromTo.start)) {
          var key = _selectedTimeRange == TimeRanges.today ? "${d.hour}" : "${d.day}_${d.month}_${d.year}";
          print(key);
          var key2 = element.recipe.target?.name;
          if (key2 != null) {
            if (sortedMap[key] == null) {
              sortedMap[key] = LinkedHashMap();
            }
            if (sortedMap[key]![key2] == null) {
              sortedMap[key]![key2] = 0;
            }
            sortedMap[key]![key2] = sortedMap[key]![key2]! + 1;
          }

          // sortedMap[key] = sortedMap[key]! + 1;
        }
      } catch (e) {
        debugPrint("Error");
      }
    }
    colormap.clear();
    var index = 0;
    sortedMap.entries.forEach((element) {
      element.value.forEach(
        (key, value) {
          if (colormap[key] == null) {
            colormap[key] = index % colorList.length;
            index++;
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    var legends = colormap.entries
        .mapIndexed((i, e) => Legend(
              e.key,
              colorList[colormap[e.key]!],
              e.value.toString(),
            ))
        .toList();
    final DateFormat formatter = DateFormat('yMMMd');
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
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          widget.data.title!,
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        // IconButton(
                        //     onPressed: () {
                        //       time = time.subtract(Duration(days: _selectedTimeRange));
                        //       widget.data.range!.to = time;
                        //       widget.controller.delete(widget.data.identifier);
                        //       widget.controller.add(widget.data, mountToTop: false);
                        //       calcData();
                        //       setState(() {});
                        //     },
                        //     icon: const Icon(Icons.chevron_left)),
                        // DropdownButton(
                        //   isExpanded: false,
                        //   alignment: Alignment.centerLeft,
                        //   value: _selectedTimeRange,
                        //   items: timeRanges,
                        //   onChanged: (value) {
                        //     if (value != 0) {
                        //       _selectedTimeRange = value!;
                        //       widget.data.range!.range = _selectedTimeRange;
                        //       widget.controller.delete(widget.data.identifier);
                        //       widget.controller.add(widget.data, mountToTop: false);

                        //       calcData();
                        //     }
                        //     setState(() {});
                        //   },
                        // ),
                        // IconButton(
                        //     onPressed: () {
                        //       time = time.subtract(Duration(days: -_selectedTimeRange));
                        //       widget.data.range!.to = time;
                        //       widget.controller.delete(widget.data.identifier);
                        //       widget.controller.add(widget.data, mountToTop: false);
                        //       calcData();
                        //       setState(() {});
                        //     },
                        //     icon: const Icon(Icons.chevron_right)),
                        const SizedBox(width: 10),
                        Text(TimeRange.getLabels()[widget.data.range!.range]!),
                        const SizedBox(width: 10),
                        Text("until ${formatter.format(time)}"),
                      ],
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
                                  return AddDialog(
                                    data: widget.data,
                                    controller: widget.controller,
                                  );
                                });
                            if (res != null) {
                              widget.controller.delete(widget.data.identifier);
                              widget.controller.add(res, mountToTop: false);
                              calcData();
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
          const SizedBox(
            height: 10,
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: LayoutBuilder(builder: (context, constrains) {
                    var r = min(constrains.maxWidth, constrains.maxHeight) / 2;
                    return BarChart(
                      BarChartData(
                        // pieTouchData: PieTouchData(
                        //   touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        //     setState(() {
                        //       if (!event.isInterestedForInteractions ||
                        //           pieTouchResponse == null ||
                        //           pieTouchResponse.touchedSection == null) {
                        //         touchedIndex = -1;
                        //         return;
                        //       }
                        //       touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        //       print(touchedIndex);
                        //     });
                        //   },
                        // ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        barGroups: showingSections(10),
                        // maxY: 10,

                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(sideTitles: _bottomTitles),
                          leftTitles:
                              const AxisTitles(sideTitles: SideTitles(reservedSize: 30, showTitles: true, interval: 1)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(
                  width: 10,
                ),
              ],
            ),
          ),
          LegendsListWidget(legends: legends, touchIndex: touchedIndex, noValues: true, horizontal: true)
        ],
      ),
    );
  }

  List<BarChartGroupData> showingSections(double radius) {
    // const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
    return sortedMap.entries.mapIndexed((i, e) {
      print("Section $i");
      final isTouched = i == touchedIndex;
      var color = colorList[i % colorList.length];

      double sum = 0;
      e.value.entries.forEach((element) {
        sum = sum + element.value;
      });
      double currentY = 0;

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: sum, // isTouched ? e.value + 1 : e.value.toDouble() * 2,
            // color: isTouched ? widget.touchedBarColor : barColor,
            // width: 10,
            color: Colors.white,
            // borderSide: isTouched
            //     ? BorderSide(color: widget.touchedBarColor.darken(80))
            //     : const BorderSide(color: Colors.white, width: 0),
            // backDrawRodData: BackgroundBarChartRodData(
            //   show: true,
            //   toY: 10,
            //   // color: widget.barBackgroundColor,
            // ),
            rodStackItems: e.value.entries.mapIndexed((index, element) {
              var bar = BarChartRodStackItem(
                currentY,
                currentY + element.value.toDouble(),
                colorList[colormap[element.key]!],
                // BorderSide(
                //   color: Colors.white,
                //   width: isTouched ? 2 : 0,
                // ),
              );
              currentY += element.value.toDouble();
              return bar;
            }).toList(),
          ),
        ],
      );
    }).toList();
  }

  SideTitles get _bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 55, //+ _selectedTimeRange == 7 ? 25 : 25,
        getTitlesWidget: (value, meta) {
          print("Bottom: $value");
          String text = '';
          String text2 = '';
          switch (_selectedTimeRange) {
            case TimeRanges.thisWeek:
            case TimeRanges.lastWeek:
              final DateFormat formatter = DateFormat('EEE');
              final DateFormat formatter2 = DateFormat('dd MMM');

              var d = time.subtract(Duration(days: 7 - value.toInt()));
              text = formatter.format(d);
              text2 = formatter2.format(d);

              break;
            case TimeRanges.lastMonth:
            case TimeRanges.last3Month:
            case TimeRanges.thisMonth:
              final DateFormat formatter = DateFormat('dd');
              final DateFormat formatter2 = DateFormat('MMM');

              if (value.toInt() % 2 == 0) {
                var d = time.subtract(Duration(days: 30 - value.toInt()));
                text = formatter.format(d);
                if (value.toInt() % 10 == 0) text2 = formatter2.format(d);
                // text = d.day.toString();
              }

              break;
            case TimeRanges.today:
              if (value.toInt() % 2 == 0) {
                var d = time.subtract(Duration(hours: 23 - value.toInt()));
                text = d.hour.toString();
              }

              break;
            case TimeRanges.dateRange:
              // TODO: Handle this case.
              break;
            case TimeRanges.thisYear:
              // TODO: Handle this case.
              break;
            case TimeRanges.lastYear:
              // TODO: Handle this case.
              break;
            case TimeRanges.allData:
              // TODO: Handle this case.
              break;
          }

          return Column(
            children: [
              Text(text),
              Text(text2, style: Theme.of(context).textTheme.labelSmall),
            ],
          );
        },
      );
}

class AdviceResize extends StatelessWidget {
  const AdviceResize({Key? key, required this.size}) : super(key: key);

  final int size;

  @override
  Widget build(BuildContext context) {
    return Container(
        color: green,
        alignment: Alignment.center,
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 5),
              height: double.infinity,
              width: 1,
              color: Colors.white,
            ),
            const Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("Users can resize widgets.",
                    maxLines: 2, style: TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.center),
                Text(
                    "To try resizing, hold (or long press) the line on the left"
                    " and drag it to the left.",
                    maxLines: 5,
                    style: TextStyle(color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center),
                Text("Don't forget switch to edit mode.",
                    maxLines: 3, style: TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.center),
              ],
            ))
          ],
        ));
  }
}
