import 'dart:developer';

import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'objectbox.dart';
import 'ui/landingpage.dart';
import 'package:wakelock/wakelock.dart';
import 'ui/theme.dart' as theme;

late ObjectBox objectbox;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectbox = await ObjectBox.create();

  try {
    Wakelock.enable();
  } on MissingPluginException catch (e) {
    log('Failed to set wakelock: $e');
  }
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
  // SystemChrome.setEnabledSystemUIOverlays([
  //   SystemUiOverlay.bottom, //This line is used for showing the bottom bar
  // ]);
  initSettings().then((_) {
    runApp(MyApp());
  });
}

Future<void> initSettings() async {
  await Settings.init(
    cacheProvider: SharePreferenceCache(),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key}) {
    getIt.registerSingleton<ObjectBox>(objectbox, signalsReady: false);
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
        scaffoldBackgroundColor: theme.Colors.backgroundColor,
        backgroundColor: theme.Colors.backgroundColor,
        colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
          primary: theme.Colors.secondaryColor,
          secondary: Colors.green,
          // brightness: Brightness.dark,
        ),
      ),
      home: const LandingPage(title: 'despresso'),
    );
  }
}
