import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

class IncrementDecrement extends StatefulWidget {
  IncrementDecrement({
    super.key,
    required this.initialValue,
    this.onChanged,
  });
  double initialValue;
  ValueChanged<double>? onChanged;

  @override
  _IncrementDecrementState createState() => _IncrementDecrementState();
}

class _IncrementDecrementState extends State<IncrementDecrement> {
  _IncrementDecrementState();

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
          widget.initialValue--;
          if (widget.onChanged != null) widget.onChanged!(widget.initialValue);
        });
      },
      child: new Icon(Icons.remove),
    );
  }

  Widget _incrementButton() {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          widget.initialValue++;
          if (widget.onChanged != null) widget.onChanged!(widget.initialValue);
        });
      },
      child: Icon(Icons.add),
    );
  }
}
