// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Hello World!`
  String get helloWorld {
    return Intl.message(
      'Hello World!',
      name: 'helloWorld',
      desc: 'The conventional newborn programmer greeting',
      args: [],
    );
  }

  /// `Recipe`
  String get tabHomeRecipe {
    return Intl.message(
      'Recipe',
      name: 'tabHomeRecipe',
      desc: '',
      args: [],
    );
  }

  /// `Espresso`
  String get tabHomeEspresso {
    return Intl.message(
      'Espresso',
      name: 'tabHomeEspresso',
      desc: '',
      args: [],
    );
  }

  /// `Steam`
  String get tabHomeSteam {
    return Intl.message(
      'Steam',
      name: 'tabHomeSteam',
      desc: '',
      args: [],
    );
  }

  /// `Water`
  String get tabHomeWater {
    return Intl.message(
      'Water',
      name: 'tabHomeWater',
      desc: '',
      args: [],
    );
  }

  /// `Flush`
  String get tabHomeFlush {
    return Intl.message(
      'Flush',
      name: 'tabHomeFlush',
      desc: '',
      args: [],
    );
  }

  /// `Recipe Details`
  String get screenRecipeRecipeDetails {
    return Intl.message(
      'Recipe Details',
      name: 'screenRecipeRecipeDetails',
      desc: '',
      args: [],
    );
  }

  /// `Hot water:`
  String get screenRecipehotWater {
    return Intl.message(
      'Hot water:',
      name: 'screenRecipehotWater',
      desc: '',
      args: [],
    );
  }

  /// `Steam milk:`
  String get screenRecipesteamMilk {
    return Intl.message(
      'Steam milk:',
      name: 'screenRecipesteamMilk',
      desc: '',
      args: [],
    );
  }

  /// `Profile Details`
  String get screenRecipeProfileDetails {
    return Intl.message(
      'Profile Details',
      name: 'screenRecipeProfileDetails',
      desc: '',
      args: [],
    );
  }

  /// `Coffee notes`
  String get screenRecipeCoffeeNotes {
    return Intl.message(
      'Coffee notes',
      name: 'screenRecipeCoffeeNotes',
      desc: '',
      args: [],
    );
  }

  /// `Selected profile`
  String get screenRecipeSelectedProfile {
    return Intl.message(
      'Selected profile',
      name: 'screenRecipeSelectedProfile',
      desc: '',
      args: [],
    );
  }

  /// `Initial temperature:`
  String get screenRecipeInitialTemp {
    return Intl.message(
      'Initial temperature:',
      name: 'screenRecipeInitialTemp',
      desc: '',
      args: [],
    );
  }

  /// `Selected Bean`
  String get screenRecipeSelectedBean {
    return Intl.message(
      'Selected Bean',
      name: 'screenRecipeSelectedBean',
      desc: '',
      args: [],
    );
  }

  /// `Grind Settings:`
  String get screenRecipeGrindSettings {
    return Intl.message(
      'Grind Settings:',
      name: 'screenRecipeGrindSettings',
      desc: '',
      args: [],
    );
  }

  /// `Ratio:`
  String get screenRecipeRatio {
    return Intl.message(
      'Ratio:',
      name: 'screenRecipeRatio',
      desc: '',
      args: [],
    );
  }

  /// `Weight-in beans [g]`
  String get screenRecipeWeightinBeansG {
    return Intl.message(
      'Weight-in beans [g]',
      name: 'screenRecipeWeightinBeansG',
      desc: '',
      args: [],
    );
  }

  /// `Stop on Weight [g]`
  String get screenRecipeStopOnWeightG {
    return Intl.message(
      'Stop on Weight [g]',
      name: 'screenRecipeStopOnWeightG',
      desc: '',
      args: [],
    );
  }

  /// `Adjust temp [°C]`
  String get screenRecipeAdjustTempC {
    return Intl.message(
      'Adjust temp [°C]',
      name: 'screenRecipeAdjustTempC',
      desc: '',
      args: [],
    );
  }

  /// `Add recipe`
  String get screenRecipeAddRecipe {
    return Intl.message(
      'Add recipe',
      name: 'screenRecipeAddRecipe',
      desc: '',
      args: [],
    );
  }

  /// `No`
  String get no {
    return Intl.message(
      'No',
      name: 'no',
      desc: '',
      args: [],
    );
  }

  /// `Set Ratio`
  String get screenRecipeSetRatio {
    return Intl.message(
      'Set Ratio',
      name: 'screenRecipeSetRatio',
      desc: '',
      args: [],
    );
  }

  /// `Ok`
  String get ok {
    return Intl.message(
      'Ok',
      name: 'ok',
      desc: '',
      args: [],
    );
  }

  /// `Refill the water tank`
  String get screenEspressoRefillTheWaterTank {
    return Intl.message(
      'Refill the water tank',
      name: 'screenEspressoRefillTheWaterTank',
      desc: '',
      args: [],
    );
  }

  /// `Recipe`
  String get screenEspressoRecipe {
    return Intl.message(
      'Recipe',
      name: 'screenEspressoRecipe',
      desc: '',
      args: [],
    );
  }

  /// `Profile`
  String get screenEspressoProfile {
    return Intl.message(
      'Profile',
      name: 'screenEspressoProfile',
      desc: '',
      args: [],
    );
  }

  /// `Coffee`
  String get screenEspressoBean {
    return Intl.message(
      'Coffee',
      name: 'screenEspressoBean',
      desc: '',
      args: [],
    );
  }

  /// `Target`
  String get screenEspressoTarget {
    return Intl.message(
      'Target',
      name: 'screenEspressoTarget',
      desc: '',
      args: [],
    );
  }

  /// `Timer`
  String get screenEspressoTimer {
    return Intl.message(
      'Timer',
      name: 'screenEspressoTimer',
      desc: '',
      args: [],
    );
  }

  /// `Pour: {sec} s`
  String screenEspressoPour(Object sec) {
    return Intl.message(
      'Pour: $sec s',
      name: 'screenEspressoPour',
      desc: '',
      args: [sec],
    );
  }

  /// `Total: {sec} s`
  String screenEspressoTotal(Object sec) {
    return Intl.message(
      'Total: $sec s',
      name: 'screenEspressoTotal',
      desc: '',
      args: [sec],
    );
  }

  /// `TTW: {sec} s`
  String screenEspressoTtw(Object sec) {
    return Intl.message(
      'TTW: $sec s',
      name: 'screenEspressoTtw',
      desc: '',
      args: [sec],
    );
  }

  /// `Espresso Diary`
  String get screenEspressoDiary {
    return Intl.message(
      'Espresso Diary',
      name: 'screenEspressoDiary',
      desc: '',
      args: [],
    );
  }

  /// `Flow [ml/s] / Pressure [bar]`
  String get screenEspressoFlowMlsPressureBar {
    return Intl.message(
      'Flow [ml/s] / Pressure [bar]',
      name: 'screenEspressoFlowMlsPressureBar',
      desc: '',
      args: [],
    );
  }

  /// `Time/s`
  String get screenEspressoTimes {
    return Intl.message(
      'Time/s',
      name: 'screenEspressoTimes',
      desc: '',
      args: [],
    );
  }

  /// `Pressure`
  String get screenEspressoPressure {
    return Intl.message(
      'Pressure',
      name: 'screenEspressoPressure',
      desc: '',
      args: [],
    );
  }

  /// `Flow`
  String get screenEspressoFlow {
    return Intl.message(
      'Flow',
      name: 'screenEspressoFlow',
      desc: '',
      args: [],
    );
  }

  /// `Weight`
  String get screenEspressoWeight {
    return Intl.message(
      'Weight',
      name: 'screenEspressoWeight',
      desc: '',
      args: [],
    );
  }

  /// `Temp`
  String get screenEspressoTemp {
    return Intl.message(
      'Temp',
      name: 'screenEspressoTemp',
      desc: '',
      args: [],
    );
  }

  /// `Weight [g]`
  String get screenEspressoWeightG {
    return Intl.message(
      'Weight [g]',
      name: 'screenEspressoWeightG',
      desc: '',
      args: [],
    );
  }

  /// `Steam two-tap mode:`
  String get screenSteamTwotapMode {
    return Intl.message(
      'Steam two-tap mode:',
      name: 'screenSteamTwotapMode',
      desc: '',
      args: [],
    );
  }

  /// `On (slow purge on 1st stop)`
  String get screenSteamOnSlowPurgeOn1stStop {
    return Intl.message(
      'On (slow purge on 1st stop)',
      name: 'screenSteamOnSlowPurgeOn1stStop',
      desc: '',
      args: [],
    );
  }

  /// `Off (normal purge after stop)`
  String get screenSteamOffNormalPurgeAfterStop {
    return Intl.message(
      'Off (normal purge after stop)',
      name: 'screenSteamOffNormalPurgeAfterStop',
      desc: '',
      args: [],
    );
  }

  /// `Steam Temperaturs {temp} °C`
  String screenSteamTemperaturs(Object temp) {
    return Intl.message(
      'Steam Temperaturs $temp °C',
      name: 'screenSteamTemperaturs',
      desc: '',
      args: [temp],
    );
  }

  /// `Timer {t} s`
  String screenSteamTimerS(Object t) {
    return Intl.message(
      'Timer $t s',
      name: 'screenSteamTimerS',
      desc: '',
      args: [t],
    );
  }

  /// `Stop at Temperature {temp} °C`
  String screenSteamStopAtTemperatur(Object temp) {
    return Intl.message(
      'Stop at Temperature $temp °C',
      name: 'screenSteamStopAtTemperatur',
      desc: '',
      args: [temp],
    );
  }

  /// `Steam Flowrate {flow} ml/s`
  String screenSteamFlowrate(Object flow) {
    return Intl.message(
      'Steam Flowrate $flow ml/s',
      name: 'screenSteamFlowrate',
      desc: '',
      args: [flow],
    );
  }

  /// `Time/s`
  String get screenSteamTimeS {
    return Intl.message(
      'Time/s',
      name: 'screenSteamTimeS',
      desc: '',
      args: [],
    );
  }

  /// `Temp [°C]`
  String get steamScreenTempC {
    return Intl.message(
      'Temp [°C]',
      name: 'steamScreenTempC',
      desc: '',
      args: [],
    );
  }

  /// `Temp Tip`
  String get screenSteamTempTip {
    return Intl.message(
      'Temp Tip',
      name: 'screenSteamTempTip',
      desc: '',
      args: [],
    );
  }

  /// `Ambient`
  String get screenSteamAmbient {
    return Intl.message(
      'Ambient',
      name: 'screenSteamAmbient',
      desc: '',
      args: [],
    );
  }

  /// `Reset`
  String get screenSteamReset {
    return Intl.message(
      'Reset',
      name: 'screenSteamReset',
      desc: '',
      args: [],
    );
  }

  /// `Weight {w} g`
  String screenWaterWeightG(Object w) {
    return Intl.message(
      'Weight $w g',
      name: 'screenWaterWeightG',
      desc: '',
      args: [w],
    );
  }

  /// `Espresso Diary`
  String get mainMenuEspressoDiary {
    return Intl.message(
      'Espresso Diary',
      name: 'mainMenuEspressoDiary',
      desc: '',
      args: [],
    );
  }

  /// `Profiles`
  String get profiles {
    return Intl.message(
      'Profiles',
      name: 'profiles',
      desc: '',
      args: [],
    );
  }

  /// `Beans`
  String get beans {
    return Intl.message(
      'Beans',
      name: 'beans',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Feedback`
  String get mainMenuFeedback {
    return Intl.message(
      'Feedback',
      name: 'mainMenuFeedback',
      desc: '',
      args: [],
    );
  }

  /// `Despresso Feedback`
  String get mainMenuDespressoFeedback {
    return Intl.message(
      'Despresso Feedback',
      name: 'mainMenuDespressoFeedback',
      desc: '',
      args: [],
    );
  }

  /// `Privacy`
  String get privacy {
    return Intl.message(
      'Privacy',
      name: 'privacy',
      desc: '',
      args: [],
    );
  }

  /// `Exit`
  String get exit {
    return Intl.message(
      'Exit',
      name: 'exit',
      desc: '',
      args: [],
    );
  }

  /// `No shots to upload selected`
  String get screenDiaryNoShotsToUploadSelected {
    return Intl.message(
      'No shots to upload selected',
      name: 'screenDiaryNoShotsToUploadSelected',
      desc: '',
      args: [],
    );
  }

  /// `Success uploading your shots`
  String get screenDiarySuccessUploadingYourShots {
    return Intl.message(
      'Success uploading your shots',
      name: 'screenDiarySuccessUploadingYourShots',
      desc: '',
      args: [],
    );
  }

  /// `Error uploading shots`
  String get screenDiaryErrorUploadingShots {
    return Intl.message(
      'Error uploading shots',
      name: 'screenDiaryErrorUploadingShots',
      desc: '',
      args: [],
    );
  }

  /// `Nothing selected`
  String get screenDiaryNothingSelected {
    return Intl.message(
      'Nothing selected',
      name: 'screenDiaryNothingSelected',
      desc: '',
      args: [],
    );
  }

  /// `Overlaymode:`
  String get screenDiaryOverlaymode {
    return Intl.message(
      'Overlaymode:',
      name: 'screenDiaryOverlaymode',
      desc: '',
      args: [],
    );
  }

  /// `Pressure`
  String get pressure {
    return Intl.message(
      'Pressure',
      name: 'pressure',
      desc: '',
      args: [],
    );
  }

  /// `Flow`
  String get flow {
    return Intl.message(
      'Flow',
      name: 'flow',
      desc: '',
      args: [],
    );
  }

  /// `Weight`
  String get weight {
    return Intl.message(
      'Weight',
      name: 'weight',
      desc: '',
      args: [],
    );
  }

  /// `Temp`
  String get temp {
    return Intl.message(
      'Temp',
      name: 'temp',
      desc: '',
      args: [],
    );
  }

  /// `Beans and Roasters`
  String get screenBeanSelectTitle {
    return Intl.message(
      'Beans and Roasters',
      name: 'screenBeanSelectTitle',
      desc: '',
      args: [],
    );
  }

  /// `Select Roaster`
  String get screenBeanSelectSelectRoaster {
    return Intl.message(
      'Select Roaster',
      name: 'screenBeanSelectSelectRoaster',
      desc: '',
      args: [],
    );
  }

  /// `EDIT`
  String get edit {
    return Intl.message(
      'EDIT',
      name: 'edit',
      desc: '',
      args: [],
    );
  }

  /// `Select Beans`
  String get screenBeanSelectSelectBeans {
    return Intl.message(
      'Select Beans',
      name: 'screenBeanSelectSelectBeans',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get screenBeanSelectNameOfRoaster {
    return Intl.message(
      'Name',
      name: 'screenBeanSelectNameOfRoaster',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get screenBeanSelectDescriptionOfRoaster {
    return Intl.message(
      'Description',
      name: 'screenBeanSelectDescriptionOfRoaster',
      desc: '',
      args: [],
    );
  }

  /// `Homepage`
  String get screenBeanSelectHomepageOfRoaster {
    return Intl.message(
      'Homepage',
      name: 'screenBeanSelectHomepageOfRoaster',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get screenBeanSelectAddressOfRoaster {
    return Intl.message(
      'Address',
      name: 'screenBeanSelectAddressOfRoaster',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get screenBeanSelectNameOfBean {
    return Intl.message(
      'Name',
      name: 'screenBeanSelectNameOfBean',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get screenBeanSelectDescriptionOfBean {
    return Intl.message(
      'Description',
      name: 'screenBeanSelectDescriptionOfBean',
      desc: '',
      args: [],
    );
  }

  /// `Tasting`
  String get screenBeanSelectTasting {
    return Intl.message(
      'Tasting',
      name: 'screenBeanSelectTasting',
      desc: '',
      args: [],
    );
  }

  /// `Type of Beans`
  String get screenBeanSelectTypeOfBeans {
    return Intl.message(
      'Type of Beans',
      name: 'screenBeanSelectTypeOfBeans',
      desc: '',
      args: [],
    );
  }

  /// `Roasting date`
  String get screenBeanSelectRoastingDate {
    return Intl.message(
      'Roasting date',
      name: 'screenBeanSelectRoastingDate',
      desc: '',
      args: [],
    );
  }

  /// `Acidity`
  String get screenBeanSelectAcidity {
    return Intl.message(
      'Acidity',
      name: 'screenBeanSelectAcidity',
      desc: '',
      args: [],
    );
  }

  /// `Intensity`
  String get screenBeanSelectIntensity {
    return Intl.message(
      'Intensity',
      name: 'screenBeanSelectIntensity',
      desc: '',
      args: [],
    );
  }

  /// `Roast Level`
  String get screenBeanSelectRoastLevel {
    return Intl.message(
      'Roast Level',
      name: 'screenBeanSelectRoastLevel',
      desc: '',
      args: [],
    );
  }

  /// `days ago`
  String get screenBeanSelectDaysAgo {
    return Intl.message(
      'days ago',
      name: 'screenBeanSelectDaysAgo',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'de'),
      Locale.fromSubtags(languageCode: 'es'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
