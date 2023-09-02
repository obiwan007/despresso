import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class LegendWidget extends StatelessWidget {
  LegendWidget({
    super.key,
    required this.name,
    required this.color,
    required this.value,
    required this.touched,
    required this.touchIndex,
    this.circleColor = false,
  });
  final String name;
  final Color color;
  final String value;
  final bool touched;
  final int touchIndex;
  bool circleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (circleColor)
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        if (!circleColor)
          Container(
            width: touched ? 60 : 50,
            color: Color.fromRGBO(color.red, color.green, color.blue, touched || touchIndex == -1 ? 1 : 0.3),
            padding: const EdgeInsets.only(right: 4.0, bottom: 0),
            child: Text(
              textAlign: TextAlign.end,
              overflow: TextOverflow.clip,
              value,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        const SizedBox(width: 6),
        Text(
          overflow: TextOverflow.clip,
          name,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class LegendsListWidget extends StatelessWidget {
  LegendsListWidget({
    super.key,
    required this.legends,
    required this.touchIndex,
    this.noValues = false,
    this.horizontal = false,
  });
  final List<Legend> legends;
  final int touchIndex;
  bool noValues = false;
  bool horizontal = false;

  @override
  Widget build(BuildContext context) {
    if (horizontal == true) {
      return Wrap(
        runSpacing: 10,
        spacing: 10,
        children: legends
            .mapIndexed(
              (i, e) => Padding(
                padding: const EdgeInsets.all(1.0),
                child: LegendWidget(
                  name: e.name,
                  color: e.color,
                  value: noValues ? '' : e.value,
                  touched: i == touchIndex,
                  touchIndex: touchIndex,
                  circleColor: noValues,
                ),
              ),
            )
            .toList(),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: legends
            .mapIndexed(
              (i, e) => Padding(
                padding: const EdgeInsets.all(1.0),
                child: LegendWidget(
                  name: e.name,
                  color: e.color,
                  value: e.value,
                  touched: i == touchIndex,
                  touchIndex: touchIndex,
                ),
              ),
            )
            .toList(),
      );
    }
  }
}

class Legend {
  Legend(this.name, this.color, this.value);
  final String name;
  final Color color;
  final String value;
}
