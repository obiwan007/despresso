import 'package:dashboard/dashboard.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/widgets/dashboard/add_dialog.dart';
import 'package:despresso/ui/widgets/dashboard/colored_dashboard_item.dart';
import 'package:flutter/material.dart';

import 'data_widget.dart';

class KPI extends StatefulWidget {
  final ColoredDashboardItem data;
  final DashboardItemController<ColoredDashboardItem> controller;
  const KPI({Key? key, required this.data, required this.controller}) : super(key: key);

  @override
  State<KPI> createState() => _KPIState();
}

class _KPIState extends State<KPI> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.controller.addListener(() {
      print("LISTEN");
    });
    switch (widget.data.widgetDataSource) {
      case WidgetDataSource.beansSum:
        widget.data.value = getIt<CoffeeService>().coffeeBox.count().toString();
        break;
      case WidgetDataSource.shotsSum:
        widget.data.value = getIt<CoffeeService>().shotBox.count().toString();
        break;
      case WidgetDataSource.recipeSum:
        widget.data.value = getIt<CoffeeService>().recipeBox.count().toString();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Theme.of(context).focusColor,
        // color: yellow,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.data.dataHeader != null)
                    Text(
                      widget.data.dataHeader!,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  if (widget.data.value != null)
                    FittedBox(
                      child: Text(
                        widget.data.value!,
                        style: widget.data.color != null
                            ? Theme.of(context).textTheme.titleLarge!.copyWith(color: widget.data.color)
                            : Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  if (widget.data.dataFooter != null)
                    Text(
                      widget.data.dataFooter!,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.data.footer != null)
                    Text(
                      widget.data.footer!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  if (widget.data.subFooter != null)
                    Text(
                      widget.data.subFooter!,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                ],
              ),
            ),
          ],
        ));
  }
}
