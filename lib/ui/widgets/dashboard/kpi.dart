import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/widgets/dashboard/colored_dashboard_item.dart';
import 'package:flutter/material.dart';

class KPI extends StatefulWidget {
  final ColoredDashboardItem data;
  const KPI({Key? key, required this.data}) : super(key: key);

  @override
  State<KPI> createState() => _KPIState();
}

class _KPIState extends State<KPI> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

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
                  if (widget.data.title != null)
                    Row(
                      children: [
                        Text(
                          widget.data.title!,
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.titleSmall,
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
