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

enum TimeRanges {
  today,
  dateRange,
  thisWeek,
  thisMonth,
  lastMonth,
  last3Month,
  thisYear,
  lastYear,
  allData,
  lastWeek,
}

class TimeRange {
  DateTime to;
  DateTime from;
  TimeRanges range;

  TimeRange({required this.from, required this.to, required this.range});

  Map<String, dynamic> toMap() {
    var sup = Map<String, dynamic>();

    sup["to"] = to.toIso8601String();
    sup["from"] = from.toIso8601String();
    sup["range"] = range.name;

    return sup;
  }

  TimeRange.fromMap(Map<String, dynamic> map)
      : to = DateTime.parse(map["to"]),
        from = DateTime.parse(map["from"]),
        range = TimeRanges.values.byName(map["range"]);

  static Map<TimeRanges, String> getLabels() {
    Map<TimeRanges, String> m = {
      TimeRanges.today: "Today",
      TimeRanges.dateRange: "Range",
      TimeRanges.thisWeek: "Week",
      TimeRanges.lastWeek: "last Week",
      TimeRanges.thisMonth: "Month",
      TimeRanges.lastMonth: "last Month",
      TimeRanges.last3Month: "last 3 Month",
      TimeRanges.thisYear: "Year",
      TimeRanges.lastYear: "last Year",
      TimeRanges.allData: "All recorded data",
    };
    return m;
  }

  DateTimeRange getFrame() {
    switch (range) {
      case TimeRanges.today:
        to = DateTime.now();
        from = to.subtract(Duration(days: 1));
        break;
      case TimeRanges.dateRange:
        // TODO: Handle this case.
        break;
      case TimeRanges.thisWeek:
        to = DateTime.now();
        from = to.subtract(Duration(days: 7));
        break;
      case TimeRanges.lastWeek:
        to = DateTime.now().subtract(Duration(days: 7));
        from = to.subtract(Duration(days: 7));
        break;
      case TimeRanges.lastMonth:
        to = DateTime.now().subtract(Duration(days: 30));
        from = to.subtract(Duration(days: 30));
        break;
      case TimeRanges.last3Month:
        to = DateTime.now();
        from = to.subtract(Duration(days: 30 * 3));
        break;
      case TimeRanges.lastYear:
        to = DateTime.now().subtract(Duration(days: 365));
        from = to.subtract(Duration(days: 365));

        break;
      case TimeRanges.allData:
        to = DateTime.now();
        from = to.subtract(Duration(days: 100 * 365));

        break;
      case TimeRanges.thisMonth:
        to = DateTime.now();
        from = to.subtract(Duration(days: 30));
        break;

      case TimeRanges.thisYear:
        to = DateTime.now();
        from = to.subtract(Duration(days: 365));
        break;
    }

    var fromTo = DateTimeRange(end: to.add(const Duration(seconds: 1)), start: from);
    return fromTo;
  }
}

class ColoredDashboardItem extends DashboardItem {
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
      this.range,
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
        range = map["range"] != null ? TimeRange.fromMap(map["range"]) : null,
        super.withLayout(map["item_id"], ItemLayout.fromMap(map["layout"]));

  TimeRange? range;
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
    if (range != null) {
      sup["range"] = range!.toMap();
    }
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
