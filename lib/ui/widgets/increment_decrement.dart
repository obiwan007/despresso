import 'package:flutter/material.dart';

class IncrementDecrement extends StatefulWidget {
  const IncrementDecrement({
    super.key,
    required this.initialValue,
    this.onChanged,
  });
  final double initialValue;
  final ValueChanged<double>? onChanged;

  @override
  IncrementDecrementState createState() => IncrementDecrementState();
}

class IncrementDecrementState extends State<IncrementDecrement> {
  late double initialValue;
  late ValueChanged<double>? onChanged;

  IncrementDecrementState();

  @override
  void initState() {
    super.initState();
    initialValue = widget.initialValue;
    onChanged = widget.onChanged;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _decrementButton(),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
              initialValue: widget.initialValue.toString(),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (value) {
                setState(() {
                  if (widget.onChanged != null) widget.onChanged!(widget.initialValue);
                });
              }),
        )),
        _incrementButton(),
      ],
    );
  }

  Widget _decrementButton() {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          initialValue--;
          if (widget.onChanged != null) widget.onChanged!(widget.initialValue);
        });
      },
      child: const Icon(Icons.remove),
    );
  }

  Widget _incrementButton() {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          initialValue++;
          if (widget.onChanged != null) widget.onChanged!(widget.initialValue);
        });
      },
      child: const Icon(Icons.add),
    );
  }
}
