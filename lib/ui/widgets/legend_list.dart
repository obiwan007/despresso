import 'package:flutter/material.dart';

class LegendWidget extends StatelessWidget {
  LegendWidget({
    super.key,
    required this.name,
    required this.color,
    required this.onChanged,
    this.value,
  });
  final String name;
  final Color color;
  final void Function(bool)? onChanged;
  bool? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(name, style: Theme.of(context).textTheme.labelMedium),
        if (onChanged != null)
          Checkbox(
            value: value,
            onChanged: (value) {
              if (onChanged != null) onChanged!(value!);
            },
          )
      ],
    );
  }
}

class LegendsListWidget extends StatelessWidget {
  const LegendsListWidget({
    super.key,
    required this.legends,
  });
  final List<Legend> legends;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      children: legends
          .map(
            (e) => LegendWidget(
              name: e.name,
              color: e.color,
              value: e.value,
              onChanged: e.onChanged,
            ),
          )
          .toList(),
    );
  }
}

class Legend {
  Legend(this.name, this.color, {this.onChanged, this.value});
  final String name;
  final Color color;
  final void Function(bool)? onChanged;
  final bool? value;
}
