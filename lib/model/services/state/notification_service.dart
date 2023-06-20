import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

enum SnackbarNotificationType {
  info,
  warn,
  severe,
  ok,
}

class SnackbarNotification {
  String text;
  SnackbarNotificationType type;

  SnackbarNotification(this.text, this.type);

  @override
  String toString() {
    return "$text $type";
  }
}

class SnackbarService extends ChangeNotifier {
  final log = Logger('SnackbarService');

  late StreamController<SnackbarNotification> _controllerNotification;
  late Stream<SnackbarNotification> _streamNotification;
  Stream<SnackbarNotification> get streamSnackbarNotification => _streamNotification;

  SnackbarService() {
    _controllerNotification = StreamController<SnackbarNotification>();
    _streamNotification = _controllerNotification.stream;
    init();
  }

  void init() async {
    notifyListeners();
  }

  // void _notifyDelayed() {
  //   Future.delayed(
  //     const Duration(milliseconds: 100),
  //     () {
  //       notifyListeners();
  //     },
  //   );
  // }

  notify(String text, SnackbarNotificationType type) {
    _controllerNotification.add(SnackbarNotification(text, type));
  }
}
