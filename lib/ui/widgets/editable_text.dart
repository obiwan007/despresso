import 'package:flutter/material.dart';

class IconEditableText extends StatefulWidget {
  IconEditableText({
    super.key,
    this.initialValue,
    this.onChanged,
    this.style,
    this.textAlign,
  });
  String? initialValue;
  TextStyle? style;
  TextAlign? textAlign;
  ValueChanged<String>? onChanged;

  @override
  _IconEditableTextState createState() => _IconEditableTextState(initialValue: initialValue, onChanged: onChanged);
}

class _IconEditableTextState extends State<IconEditableText> {
  bool isEditable = false;
  String? initialValue = "";
  ValueChanged<String>? onChanged;

  _IconEditableTextState({
    this.initialValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: !isEditable
              ? Text(
                  initialValue!,
                  style: widget.style,
                  textAlign: widget.textAlign,
                )
              : TextFormField(
                  initialValue: initialValue,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (value) {
                    setState(() {
                      isEditable = false;
                      initialValue = value;
                      if (onChanged != null) onChanged!(value);
                    });
                  })),
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () {
          setState(() => isEditable = true,);
        },
      )
    ]);
  }
}
