import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class LegendWidget extends StatelessWidget {
  const LegendWidget({
    super.key,
    required this.name,
    required this.color,
    required this.value,
    required this.touched,
    required this.touchIndex,
  });
  final String name;
  final Color color;
  final String value;
  final bool touched;
  final int touchIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Container(
        //   width: 10,
        //   height: 10,
        //   decoration: BoxDecoration(
        //     shape: BoxShape.circle,
        //     color: color,
        //   ),
        // ),
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
  const LegendsListWidget({
    super.key,
    required this.legends,
    required this.touchIndex,
  });
  final List<Legend> legends;
  final int touchIndex;

  @override
  Widget build(BuildContext context) {
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

class Legend {
  Legend(this.name, this.color, this.value);
  final String name;
  final Color color;
  final String value;
}
