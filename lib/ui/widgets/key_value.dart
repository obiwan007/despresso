import 'package:flutter/material.dart';

class KeyValueWidget extends StatelessWidget {
  const KeyValueWidget({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
            flex: 1, // takes 30% of available width
            child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
        Expanded(
            flex: 1, // takes 30% of available width
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
