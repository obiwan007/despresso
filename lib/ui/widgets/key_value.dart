import 'package:flutter/material.dart';

class KeyValueWidget extends StatelessWidget {
  KeyValueWidget({
    super.key,
    required this.label,
    required this.value,
    this.width = 150,
    this.widget,
  });

  final String label;
  final String value;
  final double width;
  Widget? widget;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
            width: width, // takes 30% of available width
            child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
        Expanded(
            flex: 1, // takes 30% of available width
            child: widget != null ? widget! : Text(value, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
