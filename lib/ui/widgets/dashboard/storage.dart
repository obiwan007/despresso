import 'dart:async';
import 'dart:convert';

import 'package:dashboard/dashboard.dart';
import 'package:despresso/ui/widgets/dashboard/colored_dashboard_item.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyItemStorage extends DashboardItemStorageDelegate<ColoredDashboardItem> {
  late SharedPreferences _preferences;

  final List<int> _slotCounts = [4, 6, 8];

  final Map<int, List<ColoredDashboardItem>> _default = {
    4: <ColoredDashboardItem>[
      ColoredDashboardItem(
        widgetDataSource: WidgetDataSource.shotsSum,
        startX: 0,
        height: 1,
        width: 1,
        identifier: "1",
        color: Colors.yellow,
        data: "kpi",
        dataHeader: "#",
        dataFooter: "Shots",
        title: "Shots",
        subTitle: "Shots done over time",
        // footer: "Shots",
        // subFooter: "Shots",
        value: "10", //coffeeService.shotBox.count().toString(),
      ),
      ColoredDashboardItem(
        widgetDataSource: WidgetDataSource.recipeSum,
        startX: 1,
        height: 1,
        width: 1,
        identifier: "2",
        color: Colors.green,
        data: "kpi",
        //dataHeader: "#",
        //dataFooter: "Recipes",
        title: "Recipes",
        // subTitle: "Shots done over time",
        // footer: "Shots",
        // subFooter: "Shots",
        value: "20", //coffeeService.recipeBox.count().toString(),
      ),
      ColoredDashboardItem(
        widgetDataSource: WidgetDataSource.beansSum,
        startX: 2,
        startY: 0,
        height: 1,
        width: 1,
        identifier: "3",
        color: Colors.red,
        data: "kpi",
        //dataHeader: "#",
        // dataFooter: "Beans",
        title: "Beans",
        // subTitle: "Shots done over time",
        // footer: "Shots",
        // subFooter: "Shots",
        value: "30", // coffeeService.coffeeBox.count().toString(),
      ),
      ColoredDashboardItem(
          widgetDataSource: WidgetDataSource.recipeDist,
          title: "Recipe Distribution",
          subTitle: "Show shots per recipe",
          startX: 0,
          startY: 1,
          height: 2,
          width: 4,
          minWidth: 4,
          identifier: "4",
          data: "shotsperrecipe"),
      ColoredDashboardItem(
          widgetDataSource: WidgetDataSource.shotsOverTime,
          title: "Shots Distribution",
          subTitle: "Show shots over time",
          startX: 4,
          startY: 1,
          height: 2,
          width: 4,
          minWidth: 4,
          identifier: "5",
          data: "shotspertime"),
      // ColoredDashboardItem(
      //     startX: 3, startY: 1, height: 2, width: 2, identifier: "11", color: Colors.orange, data: "info")
    ],
    6: <ColoredDashboardItem>[
      ColoredDashboardItem(
        widgetDataSource: WidgetDataSource.shotsSum,
        startX: 0,
        height: 1,
        width: 1,
        identifier: "1",
        color: Colors.yellow,
        data: "kpi",
        dataHeader: "#",
        dataFooter: "Shots",
        title: "Shots",
        subTitle: "Shots done over time",
        // footer: "Shots",
        // subFooter: "Shots",
        value: "10", //coffeeService.shotBox.count().toString(),
      ),
      ColoredDashboardItem(
        widgetDataSource: WidgetDataSource.recipeSum,
        startX: 1,
        height: 1,
        width: 1,
        identifier: "2",
        color: Colors.green,
        data: "kpi",
        //dataHeader: "#",
        //dataFooter: "Recipes",
        title: "Recipes",
        // subTitle: "Shots done over time",
        // footer: "Shots",
        // subFooter: "Shots",
        value: "20", //coffeeService.recipeBox.count().toString(),
      ),
      ColoredDashboardItem(
        widgetDataSource: WidgetDataSource.beansSum,
        startX: 2,
        startY: 0,
        height: 1,
        width: 1,
        identifier: "3",
        color: Colors.red,
        data: "kpi",
        //dataHeader: "#",
        // dataFooter: "Beans",
        title: "Beans",
        // subTitle: "Shots done over time",
        // footer: "Shots",
        // subFooter: "Shots",
        value: "30", // coffeeService.coffeeBox.count().toString(),
      ),
      ColoredDashboardItem(
          widgetDataSource: WidgetDataSource.recipeDist,
          title: "Recipe Distribution",
          subTitle: "Show shots per recipe",
          startX: 0,
          startY: 1,
          height: 2,
          width: 4,
          minWidth: 4,
          identifier: "4",
          data: "shotsperrecipe"),
      ColoredDashboardItem(
          widgetDataSource: WidgetDataSource.shotsOverTime,
          title: "Shots Distribution",
          subTitle: "Show shots over time",
          startX: 0,
          startY: 3,
          height: 2,
          width: 4,
          minWidth: 4,
          identifier: "5",
          data: "shotspertime"),
    ],
    8: <ColoredDashboardItem>[
      ColoredDashboardItem(
        widgetDataSource: WidgetDataSource.shotsSum,
        startX: 0,
        height: 1,
        width: 1,
        identifier: "1",
        color: Colors.yellow,
        data: "kpi",
        title: "Shots",
        // footer: "Shots",
        // subFooter: "Shots",
        value: "10", //coffeeService.shotBox.count().toString(),
      ),
      ColoredDashboardItem(
        widgetDataSource: WidgetDataSource.recipeSum,
        startX: 1,
        height: 1,
        width: 1,
        identifier: "2",
        color: Colors.green,
        data: "kpi",
        //dataHeader: "#",
        //dataFooter: "Recipes",
        title: "Recipes",
        // subTitle: "Shots done over time",
        // footer: "Shots",
        // subFooter: "Shots",
        value: "20", //coffeeService.recipeBox.count().toString(),
      ),
      ColoredDashboardItem(
        widgetDataSource: WidgetDataSource.beansSum,
        startX: 2,
        startY: 0,
        height: 1,
        width: 1,
        identifier: "3",
        color: Colors.red,
        data: "kpi",
        //dataHeader: "#",
        // dataFooter: "Beans",
        title: "Beans",
        // subTitle: "Shots done over time",
        // footer: "Shots",
        // subFooter: "Shots",
        value: "30", // coffeeService.coffeeBox.count().toString(),
      ),
      ColoredDashboardItem(
          widgetDataSource: WidgetDataSource.recipeDist,
          title: "Recipe Distribution",
          subTitle: "Show shots per recipe",
          startX: 0,
          startY: 1,
          height: 2,
          width: 4,
          minWidth: 4,
          identifier: "4",
          data: "shotsperrecipe"),
      ColoredDashboardItem(
          widgetDataSource: WidgetDataSource.shotsOverTime,
          title: "Shots Distribution",
          subTitle: "Show shots over time",
          startX: 4,
          startY: 1,
          height: 2,
          width: 4,
          minWidth: 4,
          identifier: "5",
          data: "shotspertime"),
    ]
  };

  Map<int, Map<String, ColoredDashboardItem>>? _localItems;

  @override
  FutureOr<List<ColoredDashboardItem>> getAllItems(int slotCount) {
    try {
      if (_localItems != null) {
        return _localItems![slotCount]!.values.toList();
      }

      return Future.microtask(() async {
        _preferences = await SharedPreferences.getInstance();

        var init = _preferences.getBool("init") ?? false;
        init = false;
        if (!init) {
          _localItems = {
            for (var s in _slotCounts) s: _default[s]!.asMap().map((key, value) => MapEntry(value.identifier, value))
          };

          for (var s in _slotCounts) {
            var data = json.encode(_default[s]!.asMap().map((key, value) => MapEntry(value.identifier, value.toMap())));
            await _preferences.setString("layout_data_$s", data);
          }

          await _preferences.setBool("init", true);
        }
        var s = _preferences.getString("layout_data_$slotCount");

        print(s);
        if (s == null) return [];

        var js = json.decode(s!);

        return js!.values.map<ColoredDashboardItem>((value) => ColoredDashboardItem.fromMap(value)).toList();
      });
    } on Exception {
      rethrow;
    }
  }

  @override
  FutureOr<void> onItemsUpdated(List<ColoredDashboardItem> items, int slotCount) async {
    _setLocal();

    for (var item in items) {
      _localItems?[slotCount]?[item.identifier] = item;
    }

    var js = json.encode(_localItems![slotCount]!.map((key, value) => MapEntry(key, value.toMap())));

    await _preferences.setString("layout_data_$slotCount", js);
  }

  @override
  FutureOr<void> onItemsAdded(List<ColoredDashboardItem> items, int slotCount) async {
    _setLocal();
    for (var s in _slotCounts) {
      for (var i in items) {
        _localItems![s]?[i.identifier] = i;
      }

      await _preferences.setString(
          "layout_data_$s", json.encode(_localItems![s]!.map((key, value) => MapEntry(key, value.toMap()))));
    }
  }

  @override
  FutureOr<void> onItemsDeleted(List<ColoredDashboardItem> items, int slotCount) async {
    _setLocal();
    for (var s in _slotCounts) {
      for (var i in items) {
        _localItems![s]?.remove(i.identifier);
      }

      await _preferences.setString(
          "layout_data_$s", json.encode(_localItems![s]!.map((key, value) => MapEntry(key, value.toMap()))));
    }
  }

  Future<void> clear() async {
    for (var s in _slotCounts) {
      _localItems?[s]?.clear();
      await _preferences.remove("layout_data_$s");
    }
    _localItems = null;
    await _preferences.setBool("init", false);
  }

  _setLocal() {
    _localItems ??= {
      for (var s in _slotCounts) s: _default[s]!.asMap().map((key, value) => MapEntry(value.identifier, value))
    };
  }

  @override
  bool get layoutsBySlotCount => true;

  @override
  bool get cacheItems => true;
}
