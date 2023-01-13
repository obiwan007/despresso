import 'dart:developer';

import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/landingpage.dart';
import 'package:wakelock/wakelock.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    Wakelock.enable();
  } on MissingPluginException catch (e) {
    log('Failed to set wakelock: ' + e.toString());
  }
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
  // SystemChrome.setEnabledSystemUIOverlays([
  //   SystemUiOverlay.bottom, //This line is used for showing the bottom bar
  // ]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp() {
    setupServices();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'despresso',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: LandingPage(title: 'despresso'),
    );
  }
}
