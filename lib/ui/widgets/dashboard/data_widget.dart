import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/shot.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/coffee_selection.dart';
import 'package:despresso/ui/widgets/legend_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:dashboard/dashboard.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher_string.dart';

const Color blue = Color(0xFF4285F4);
const Color red = Color(0xFFEA4335);
const Color yellow = Color(0xFFFBBC05);
const Color green = Color(0xFF34A853);

const List<Color> colorList = [
  blue,
  red,
  yellow,
  green,
  Color.fromARGB(255, 244, 66, 155),
  Color.fromARGB(255, 244, 66, 119),
  Color.fromARGB(255, 66, 244, 110),
  Color.fromARGB(255, 244, 66, 173),
  Color.fromARGB(255, 232, 244, 66),
  Color.fromARGB(255, 244, 66, 78),
  Color.fromARGB(255, 158, 66, 244),
  Color.fromARGB(255, 244, 122, 66),
  Color.fromARGB(255, 66, 188, 244),
  Color.fromARGB(255, 66, 244, 99),
  Color.fromARGB(255, 66, 244, 93),
  Color.fromARGB(255, 244, 167, 66),
];

class ColoredDashboardItem extends DashboardItem {
  ColoredDashboardItem(
      {this.color,
      required int width,
      required int height,
      required String identifier,
      this.data,
      int minWidth = 1,
      int minHeight = 1,
      int? maxHeight,
      int? maxWidth,
      int? startX,
      int? startY})
      : super(
            startX: startX,
            startY: startY,
            width: width,
            height: height,
            identifier: identifier,
            maxHeight: maxHeight,
            maxWidth: maxWidth,
            minWidth: minWidth,
            minHeight: minHeight);

  ColoredDashboardItem.fromMap(Map<String, dynamic> map)
      : color = map["color"] != null ? Color(map["color"]) : null,
        data = map["data"],
        super.withLayout(map["item_id"], ItemLayout.fromMap(map["layout"]));

  Color? color;

  String? data;

  @override
  Map<String, dynamic> toMap() {
    var sup = super.toMap();
    if (color != null) {
      sup["color"] = color?.value;
    }
    if (data != null) {
      sup["data"] = data;
    }
    return sup;
  }
}

class DataWidget extends StatelessWidget {
  DataWidget({Key? key, required this.item}) : super(key: key);

  final ColoredDashboardItem item;

  final Map<String, Widget Function(ColoredDashboardItem i)> _map = {
    "welcome": (l) => const WelcomeWidget(),
    "shotsperrecipe": (l) => ShotsPerRecipe(),
    "basic": (l) => const BasicInformation(),
    "transform": (l) => const TransformAdvice(),
    "add": (l) => const AddAdvice(),
    "buy_mee": (l) => const BuyMee(),
    "delete": (l) => const ClearAdvice(),
    "refresh": (l) => const DefaultAdvice(),
    "info": (l) => InfoAdvice(layout: l.layoutData),
    "github": (l) => const Github(),
    "twitter": (l) => const Twitter(),
    "linkedin": (l) => const LinkedIn(),
    "pub": (l) => const Pub(),
  };

  @override
  Widget build(BuildContext context) {
    return _map[item.data]!(item);
  }
}

class Pub extends StatelessWidget {
  const Pub({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        launchUrlString("https://pub.dev/packages/dashboard");
      },
      child: Container(
        color: Colors.white,
        child: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                image: DecorationImage(fit: BoxFit.contain, image: AssetImage("assets/pub_dev.png")))),
      ),
    );
  }
}

class LinkedIn extends StatelessWidget {
  const LinkedIn({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        launchUrlString("https://www.linkedin.com/in/mehmetyaz/");
      },
      child: Container(
        color: const Color(0xFF0A66C2),
        child: Row(
          children: [
            const Expanded(
                child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Connect Me!", style: TextStyle(color: Colors.white)),
            )),
            Expanded(
              child: Container(
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      image: DecorationImage(fit: BoxFit.contain, image: AssetImage("assets/linkedin.png")))),
            ),
          ],
        ),
      ),
    );
  }
}

class Twitter extends StatelessWidget {
  const Twitter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        launchUrlString("https://twitter.com/smehmetyaz");
      },
      child: Container(
        color: const Color(0xFF1DA0F1),
        child: Row(
          children: [
            const Expanded(
                child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Follow Me!", style: TextStyle(color: Colors.white)),
            )),
            Expanded(
              child: Container(
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      image: DecorationImage(fit: BoxFit.contain, image: AssetImage("assets/twitter.png")))),
            ),
          ],
        ),
      ),
    );
  }
}

class Github extends StatelessWidget {
  const Github({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        launchUrlString("https://github.com/Mehmetyaz/dashboard");
      },
      child: Container(
        color: Colors.white,
        child: Row(
          children: [
            const Expanded(
                child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Create Issue!",
                style: TextStyle(color: Colors.black),
              ),
            )),
            Expanded(
              child: Container(
                  margin: const EdgeInsets.all(5),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      image: DecorationImage(fit: BoxFit.contain, image: AssetImage("assets/github.png")))),
            ),
          ],
        ),
      ),
    );
  }
}

class BuyMee extends StatelessWidget {
  const BuyMee({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        launchUrlString("https://www.buymeacoffee.com/mehmetyaz");
      },
      child: Container(
          alignment: Alignment.center,
          decoration:
              const BoxDecoration(image: DecorationImage(fit: BoxFit.cover, image: AssetImage("assets/img.png")))),
    );
  }
}

class InfoAdvice extends StatelessWidget {
  const InfoAdvice({Key? key, required this.layout}) : super(key: key);

  final ItemLayout layout;

  @override
  Widget build(BuildContext context) {
    return Container(
        color: blue,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          children: [
            const Text("Example dimensions and locations. (showing this)", style: TextStyle(color: Colors.white)),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: DataTable(
                    dataRowHeight: 25,
                    headingRowHeight: 25,
                    border: const TableBorder(horizontalInside: BorderSide(color: Colors.white)),
                    headingTextStyle: const TextStyle(color: Colors.white),
                    dataTextStyle: const TextStyle(color: Colors.white),
                    columns: const [
                      DataColumn(label: Text("startX")),
                      DataColumn(label: Text("startY")),
                      DataColumn(label: Text("width")),
                      DataColumn(label: Text("height"))
                    ],
                    rows: [
                      DataRow(cells: [
                        DataCell(Text(layout.startX.toString())),
                        DataCell(Text(layout.startY.toString())),
                        DataCell(Text(layout.width.toString())),
                        DataCell(Text(layout.height.toString())),
                      ])
                    ]),
              ),
            ),
          ],
        ));
  }
}

class DefaultAdvice extends StatelessWidget {
  const DefaultAdvice({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        // color: yellow,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Icon(
              Icons.refresh,
              size: 30,
              color: Colors.white,
            ),
            Expanded(
              child: Text(
                "Your layout changes saved locally."
                " Set default with this button.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ));
  }
}

class ClearAdvice extends StatelessWidget {
  const ClearAdvice({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: green,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Icon(
              Icons.delete,
              size: 30,
              color: Colors.white,
            ),
            Text(
              "Delete all widgets.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            )
          ],
        ));
  }
}

class AddAdvice extends StatelessWidget {
  const AddAdvice({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: blue,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Icon(
              Icons.add,
              size: 30,
              color: Colors.white,
            ),
            Text(
              "Add own colored widget with custom sizes.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            )
          ],
        ));
  }
}

class TransformAdvice extends StatelessWidget {
  const TransformAdvice({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: red,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Users can move widgets.",
              style: TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const Text(
              "To try moving, hold (or long press) the widget and move.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            Row(
              children: const [
                Expanded(
                  child: Text(
                    "While moving, it shrinks if possible according to the "
                    "minimum width and height values.\n(This min w: 2 , h: 2)",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
/*
                Icon(
                  Icons.arrow_right_alt,
                  color: Colors.white,
                  size: 30,
                )
*/
              ],
            ),
          ],
        ));
  }
}

class WelcomeWidget extends StatelessWidget {
  const WelcomeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: red,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            RichText(
                text: TextSpan(style: const TextStyle(color: Colors.white, fontSize: 20), children: [
              const TextSpan(text: "Welcome to "),
              TextSpan(
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launchUrlString("https://pub.dev/packages/dashboard");
                    },
                  text: "dashboard",
                  style: const TextStyle(decoration: TextDecoration.underline)),
              const TextSpan(text: " online demo!"),
            ])),
          ],
        ));
  }
}

class BasicInformation extends StatefulWidget {
  const BasicInformation({Key? key}) : super(key: key);

  @override
  State<BasicInformation> createState() => _BasicInformationState();
}

class _BasicInformationState extends State<BasicInformation> {
  late CoffeeService _coffeeService;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _coffeeService = getIt<CoffeeService>();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Theme.of(context).focusColor,
        // color: yellow,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Shots",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Expanded(
                  child: Text(
                    "${_coffeeService.shotBox.count()}",
                    maxLines: 3,
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Recipes",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Expanded(
                  child: Text(
                    "${_coffeeService.recipeBox.count()}",
                    maxLines: 3,
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Beans",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Expanded(
                  child: Text(
                    "${_coffeeService.coffeeBox.count()}",
                    maxLines: 3,
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ));
  }
}

class ShotsPerRecipe extends StatefulWidget {
  const ShotsPerRecipe({Key? key}) : super(key: key);

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
            ))
        .toList();
    var w = 100;

    return Container(
      color: Theme.of(context).focusColor,
      // color: yellow,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
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
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: showingSections(w! / 2),
              ),
            ),
          ),
          Expanded(
            child: LegendsListWidget(legends: legends),
          )
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections(double radius) {
    const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
    return sortedMap.entries.mapIndexed((i, e) {
      final isTouched = i == touchedIndex;
      print(isTouched);
      return PieChartSectionData(
        borderSide: isTouched
            ? BorderSide(color: colorList[i % colorList.length], width: 8)
            : BorderSide(color: colorList[i % colorList.length].withOpacity(0)),
        value: e.value.toDouble(),
        title: "${e.value} = ${(e.value / allShots.length * 100).toInt()}%",
        radius: radius + 10 * (isTouched == true ? 1 : 0),
        color: colorList[i % colorList.length],
        titleStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: shadows,
        ),
      );
    }).toList();
  }
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
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
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
