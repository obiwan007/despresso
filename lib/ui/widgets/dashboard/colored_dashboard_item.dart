import 'package:dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:objectbox/objectbox.dart';
// part "colored_dashboard_item.g.dart";

enum WidgetDataSource {
  shotsSum,
  recipeSum,
  beansSum,
  recipeDist,
  shotsOverTime,
}

class ColorConverter extends JsonConverter<Color, String> {
  const ColorConverter();

  @override
  fromJson(String json) {
    return Colors.red;
  }

  @override
  String toJson(Color c) {
    return c.toString();
  }
}

class ColoredDashboardItem extends DashboardItem {
  @Id()
  int id = 0;

  ColoredDashboardItem(
      {this.color,
      required this.width,
      required this.height,
      required String identifier,
      this.data,
      this.dataFooter,
      this.dataHeader,
      this.title,
      this.subTitle,
      this.footer,
      this.subFooter,
      this.value,
      required this.widgetDataSource,
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
        title = map["title"],
        width = 0,
        height = 0,
        dataHeader = map["dataHeader"],
        dataFooter = map["dataFooter"],
        subTitle = map["subTitle"],
        footer = map["footer"],
        subFooter = map["subFooter"],
        value = map["value"],
        widgetDataSource = WidgetDataSource.values.byName(map["widgetDataSource"]),
        super.withLayout(map["item_id"], ItemLayout.fromMap(map["layout"]));

  Color? color;
  int height;
  int width;
  String? dataHeader;
  String? dataFooter;
  String? data;
  String? title;
  String? subTitle;
  String? footer;
  String? subFooter;
  String? value;
  WidgetDataSource widgetDataSource;

  @override
  Map<String, dynamic> toMap() {
    var sup = super.toMap();
    if (color != null) {
      sup["color"] = color?.value;
    }
    if (data != null) {
      sup["data"] = data;
    }
    if (dataHeader != null) {
      sup["dataHeader"] = dataHeader;
    }
    if (dataFooter != null) {
      sup["dataFooter"] = dataFooter;
    }
    if (title != null) {
      sup["title"] = title;
    }
    if (subTitle != null) {
      sup["subTitle"] = subTitle;
    }
    if (footer != null) {
      sup["footer"] = footer;
    }
    if (subFooter != null) {
      sup["subFooter"] = subFooter;
    }
    sup["widgetDataSource"] = widgetDataSource.name;
    return sup;
  }
}
