import 'dart:async';

import 'package:despresso/model/services/state/settings_service.dart';
import 'package:feedback_sentry/feedback_sentry.dart';
import 'package:sentry_logging/sentry_logging.dart';
import 'package:logging/logging.dart';

import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'helper/objectbox_cache_provider.dart';
import 'logger_util.dart';
import 'objectbox.dart';
import 'ui/landingpage.dart';
import 'color_schemes.g.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n.dart';

// import 'package:logging_appenders/logging_appenders.dart';

late ObjectBox objectbox;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initLogger();

  final log = Logger("main");
  // final appender = PrintAppender.setupLogging(stderrLevel: Level.SEVERE);
  // final basePath = await getApplicationDocumentsDirectory();
  // RotatingFileAppender(baseFilePath: "${basePath.path}/logs", keepRotateCount: 3);

  WidgetsFlutterBinding.ensureInitialized();
  objectbox = await ObjectBox.create();
  getIt.registerSingleton<ObjectBox>(objectbox, signalsReady: false);
  log.info("Starting app");

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky, overlays: []);

  initSettings().then((_) async {
    // if (Platform.isWindows) {
    //   Timer(
    //     const Duration(seconds: 1),
    //     () => DE1Simulated(),
    //   );
    // }

    String dsn = Settings.getValue<bool>(SettingKeys.useSentry.name, defaultValue: true)! ? '<SENTRY_KEY>' : '';

    bool noSentry = dsn.isEmpty || dsn.length == 12;
    if (noSentry) {
      runApp(MyApp());
    } else {
      await SentryFlutter.init(
        (options) {
          options.dsn = dsn;
          // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
          // We recommend adjusting this value in production.
          options.tracesSampleRate = 1.0;
          options.enableUserInteractionTracing = true;
          options.attachScreenshot = true;
          options.addIntegration(LoggingIntegration());
        },
        appRunner: () => runApp(SentryUserInteractionWidget(child: MyApp())),
      );
    }
  });
}

Future<void> initSettings() async {
  await Settings.init(
    cacheProvider: ObjectBoxPreferenceCache(),
  );
}

class MyApp extends StatefulWidget {
  MyApp({super.key}) {
    setupServices();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late SettingsService _settings;

  @override
  void initState() {
    super.initState();
    _settings = getIt<SettingsService>();
    _settings.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    var schemaLight = lightColorSchemes[int.parse(_settings.screenThemeIndex)];
    var themeDark = darkColorSchemes[int.parse(_settings.screenThemeIndex)];
    return BetterFeedback(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'despresso',
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        locale: _settings.locale == "auto" ? null : Locale(_settings.locale),
        // localizationsDelegates: const [
        //   AppLocalizations.delegate,
        //   GlobalMaterialLocalizations.delegate,
        //   GlobalWidgetsLocalizations.delegate,
        //   GlobalCupertinoLocalizations.delegate,
        // ],
        // supportedLocales: const [
        //   Locale('en'), // English
        //   Locale('de'), // German
        //   Locale('es'), // German
        // ],
        theme: ThemeData.from(
          useMaterial3: true,
          colorScheme: schemaLight,
        ),
        darkTheme: ThemeData.from(
          useMaterial3: true,
          colorScheme: themeDark,
        ),

        // ThemeData(
        //   useMaterial3: true,

        //   colorScheme: lightColorScheme,
        //   // textTheme: const TextTheme(
        //   //   displayLarge: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
        //   //   titleLarge: TextStyle(fontSize: 36.0, fontStyle: FontStyle.normal),
        //   //   bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
        //   // ),
        // ),
        // darkTheme: ThemeData(
        //   useMaterial3: true,
        //   // colorScheme: ColorScheme.fromSeed(seedColor: Colors.red, brightness: Brightness.dark),
        //   colorScheme: darkColorScheme,
        //   // textTheme: const TextTheme(
        //   //     // displayLarge: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
        //   //     // titleLarge: TextStyle(fontSize: 36.0, fontStyle: FontStyle.normal),
        //   //     // bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
        //   //     ),
        // ),
        themeMode: _settings.screenDarkTheme ? ThemeMode.dark : ThemeMode.light,

        // theme: ThemeData(
        //   useMaterial3: true,
        //   brightness: Brightness.light,
        // ),
        // darkTheme: ThemeData(
        //   useMaterial3: true,
        //   brightness: Brightness.dark,
        //   scaffoldBackgroundColor: theme.Colors.backgroundColor,
        //   backgroundColor: theme.Colors.backgroundColor,
        //   colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
        //     primary: theme.Colors.secondaryColor,
        //     secondary: Colors.green,
        //     // brightness: Brightness.dark,
        //   ),

        home: const LandingPage(title: 'despresso'),
        navigatorObservers: [SentryNavigatorObserver()],
      ),
    );
  }
}
