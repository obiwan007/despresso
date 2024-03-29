import 'package:dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';

import 'colored_dashboard_item.dart';

class AddDialog extends StatefulWidget {
  ColoredDashboardItem data;
  final DashboardItemController<ColoredDashboardItem> controller;

  AddDialog({
    Key? key,
    required this.data,
    required this.controller,
  }) : super(key: key);

  @override
  State<AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<AddDialog> {
  int minW = 1, minH = 1, w = 1, h = 1;

  int? maxW, maxH;
  final DateFormat formatter = DateFormat('yMMMd');
  List<DropdownMenuItem<TimeRanges>> timeRanges = [];
  //    [
  //   const DropdownMenuItem(
  //     value: TimeRanges.today,
  //     child: Text("Today"),
  //   ),
  //   const DropdownMenuItem(
  //     value: TimeRanges.thisWeek,
  //     child: Text("This Week"),
  //   ),
  //   const DropdownMenuItem(
  //     value: TimeRanges.thisMonth,
  //     child: Text("This Month"),
  //   ),
  //   const DropdownMenuItem(
  //     value: TimeRanges.lastWeek,
  //     child: Text("Last week"),
  //   ),
  //   const DropdownMenuItem(
  //     value: TimeRanges.lastMonth,
  //     child: Text("last Month"),
  //   ),
  //   const DropdownMenuItem(
  //     value: TimeRanges.thisYear,
  //     child: Text("This year"),
  //   ),
  //   const DropdownMenuItem(
  //     value: TimeRanges.allData,
  //     child: Text("All recorded data"),
  //   ),
  // ];
  Color color = Colors.red;
  var types = [
    const DropdownMenuItem(
      value: "kpi",
      child: Text("KPI"),
    ),
    const DropdownMenuItem(
      value: "shotsperrecipe",
      child: Text("Shots per Recipe"),
    ),
    const DropdownMenuItem(
      value: "shotspertime",
      child: Text("Shots per Time"),
    )
  ];

  var datasources = [
    const DropdownMenuItem(
      value: WidgetDataSource.beansSum,
      child: Text("Sum Beans"),
    ),
    const DropdownMenuItem(
      value: WidgetDataSource.recipeSum,
      child: Text("Sum Recipes"),
    ),
    const DropdownMenuItem(
      value: WidgetDataSource.shotsSum,
      child: Text("Sum Shots"),
    ),
  ];
  DateTime time = DateTime.now();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    TimeRange.getLabels().forEach((k, v) {
      timeRanges.add(DropdownMenuItem(
        value: k,
        child: Text(v),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const Text("Add item with:"),
                Row(
                  children: [
                    DropdownButton(
                      isExpanded: false,
                      alignment: Alignment.centerLeft,
                      value: widget.data.data,
                      items: types,
                      onChanged: (value) {
                        widget.data.data = value;
                        setState(() {});
                      },
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    if (widget.data.data == "kpi")
                      DropdownButton(
                        isExpanded: false,
                        alignment: Alignment.centerLeft,
                        value: widget.data.widgetDataSource,
                        items: datasources,
                        onChanged: (value) {
                          widget.data.widgetDataSource = value!;
                          setState(() {});
                        },
                      ),
                  ],
                ),
                Row(
                  children: [
                    // IconButton(
                    //     onPressed: () {
                    //       // time = time.subtract(Duration(days: widget.data.range!.range));
                    //       widget.data.range!.to = time;
                    //       setState(() {});
                    //     },
                    //     icon: const Icon(Icons.chevron_left)),
                    DropdownButton(
                      isExpanded: false,
                      alignment: Alignment.centerLeft,
                      value: widget.data.range!.range,
                      items: timeRanges,
                      onChanged: (value) {
                        if (value != 0) {
                          widget.data.range!.range = value!;
                        }
                        setState(() {});
                      },
                    ),
                    // IconButton(
                    //     onPressed: () {
                    //       time = time.subtract(Duration(days: -widget.data.range!.range));
                    //       widget.data.range!.to = time;
                    //       setState(() {});
                    //     },
                    //     icon: const Icon(Icons.chevron_right)),
                    Text(formatter.format(time)),
                  ],
                ),

                TextFormField(
                  autofocus: true,
                  controller: null,
                  inputFormatters: const [],
                  initialValue: widget.data.title,
                  onChanged: (v) {
                    widget.data.title = v;
                  },
                  decoration: const InputDecoration(hintText: 'Title of widget'),
                  // maxLength: 100,
                ),
                TextFormField(
                  autofocus: true,
                  controller: null,
                  inputFormatters: const [],
                  initialValue: widget.data.subTitle,
                  onChanged: (v) {
                    widget.data.subTitle = v;
                  },
                  decoration: const InputDecoration(hintText: 'Subtitle'),
                  // maxLength: 100,
                ),
                TextFormField(
                  autofocus: true,
                  controller: null,
                  inputFormatters: const [],
                  initialValue: widget.data.dataHeader,
                  onChanged: (v) {
                    widget.data.dataHeader = v;
                  },
                  decoration: const InputDecoration(hintText: 'Value Header'),
                  // maxLength: 100,
                ),
                TextFormField(
                  autofocus: true,
                  controller: null,
                  inputFormatters: const [],
                  initialValue: widget.data.dataFooter,
                  onChanged: (v) {
                    widget.data.dataFooter = v;
                  },
                  decoration: const InputDecoration(hintText: 'Value Footer'),
                  // maxLength: 100,
                ),
                TextFormField(
                  autofocus: true,
                  controller: null,
                  inputFormatters: const [],
                  initialValue: widget.data.footer,
                  onChanged: (v) {
                    widget.data.footer = v;
                  },
                  decoration: const InputDecoration(hintText: 'Footer'),
                  // maxLength: 100,
                ),
                TextFormField(
                  autofocus: true,
                  controller: null,
                  inputFormatters: const [],
                  initialValue: widget.data.subFooter,
                  onChanged: (v) {
                    widget.data.subFooter = v;
                  },
                  decoration: const InputDecoration(hintText: 'Subfooter'),
                  // maxLength: 100,
                ),
                // drop("Width", false, 0, false),
                // drop("Height", false, 1, false),
                // drop("Minimum Width", false, 2, true),
                // drop("Minimum Height", false, 3, true),
                // drop("Maximum Width", true, 4, false),
                // drop("Maximum Height", true, 5, false),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("Color: "),
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        height: 200,
                        width: double.infinity,
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: BlockPicker(
                            pickerColor: widget.data.color == null ? Colors.white : widget.data.color!,
                            onColorChanged: (c) {
                              setState(() {
                                widget.data.color = c;
                              });
                            }),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                    onPressed: () {
                      // if (values[0] < values[2]) {
                      //   ScaffoldMessenger.of(context)
                      //       .showSnackBar(const SnackBar(content: Text("width >= minWidth is not true.")));
                      //   return;
                      // }
                      // if (values[1] < values[3]) {
                      //   ScaffoldMessenger.of(context)
                      //       .showSnackBar(const SnackBar(content: Text("height >= minHeight is not true.")));
                      //   return;
                      // }
                      // if (values[4] != 0 && values[0] > values[4]) {
                      //   ScaffoldMessenger.of(context)
                      //       .showSnackBar(const SnackBar(content: Text("width <= maxWidth is not true.")));
                      //   return;
                      // }
                      // if (values[5] != 0 && values[1] > values[5]) {
                      //   ScaffoldMessenger.of(context)
                      //       .showSnackBar(const SnackBar(content: Text("height <= maxHeight is not true.")));
                      //   return;
                      // }

                      Navigator.pop(context, widget.data);
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 30),
                      child: Text("Save"),
                    )),
                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget drop(String name, bool nullable, int index, bool bounded) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Text("$name: "),
  //       SizedBox(
  //         width: 100,
  //         child: DropdownButton<int>(
  //             underline: const SizedBox(),
  //             alignment: Alignment.centerRight,
  //             items: [
  //               if (nullable) 0,
  //               1,
  //               2,
  //               3,
  //               4,
  //               if (!bounded) ...[5, 6, 7, 8, 9]
  //             ]
  //                 .map((e) => DropdownMenuItem<int>(
  //                     alignment: Alignment.centerRight,
  //                     value: e,
  //                     child: Text(
  //                       (e == 0 ? "null" : e).toString(),
  //                       textAlign: TextAlign.right,
  //                     )))
  //                 .toList(),
  //             value: values[index],
  //             onChanged: (v) {
  //               setState(() {
  //                 values[index] = v ?? 1;
  //               });
  //             }),
  //       ),
  //     ],
  //   );
  // }
}
