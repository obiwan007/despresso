import 'dart:async';

import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:wakelock/wakelock.dart';

import '../../../service_locator.dart';

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

  @override
  void dispose() {
    super.dispose();
  }

  void _notifyDelayed() {
    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        notifyListeners();
      },
    );
  }

  notify(String text, SnackbarNotificationType type) {
    _controllerNotification.add(SnackbarNotification(text, type));
  }
}
