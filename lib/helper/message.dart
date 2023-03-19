import 'package:flutter/material.dart';

showError(BuildContext context, String message) {
  showMessage(
    context,
    message,
    const Color.fromARGB(255, 250, 141, 141),
  );
}

showOk(BuildContext context, String message) {
  showMessage(
    context,
    message,
    Colors.greenAccent,
  );
}

showMessage(BuildContext context, String message, Color color) {
  var snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      action: SnackBarAction(
        label: 'Ok',
        onPressed: () {
          // Some code to undo the change.
        },
      ));

  return Future.delayed(Duration.zero, () {
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  });
}
