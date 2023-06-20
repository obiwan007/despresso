import 'package:flutter/material.dart';

class IconEditableText extends StatefulWidget {
  const IconEditableText({
    super.key,
    this.initialValue,
    this.onChanged,
    this.style,
    this.textAlign,
  });
  final String? initialValue;
  final TextStyle? style;
  final TextAlign? textAlign;
  final ValueChanged<String>? onChanged;

  @override
  IconEditableTextState createState() => IconEditableTextState();
}

class IconEditableTextState extends State<IconEditableText> {
  bool isEditable = false;
  String? initialValue = "";
  ValueChanged<String>? onChanged;

  IconEditableTextState() {
    initialValue = widget.initialValue;
    onChanged = widget.onChanged;
  }

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
                  onChanged: (value) {
                    initialValue = value;
                    if (onChanged != null) onChanged!(value);
                  },
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
          setState(
            () => isEditable = true,
          );
        },
      )
    ]);
  }
}
