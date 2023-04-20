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

  /// `Beans`
  String get beans {
    return Intl.message(
      'Beans',
      name: 'beans',
      desc: '',
      args: [],
    );
  }

  /// `Blue`
  String get blue {
    return Intl.message(
      'Blue',
      name: 'blue',
      desc: '',
      args: [],
    );
  }

  /// `Disabled`
  String get disabled {
    return Intl.message(
      'Disabled',
      name: 'disabled',
      desc: '',
      args: [],
    );
  }

  /// `disconnected`
  String get disconnected {
    return Intl.message(
      'disconnected',
      name: 'disconnected',
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

  /// `Enabled`
  String get enabled {
    return Intl.message(
      'Enabled',
      name: 'enabled',
      desc: '',
      args: [],
    );
  }

  /// `error`
  String get error {
    return Intl.message(
      'error',
      name: 'error',
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

  /// `Flow`
  String get flow {
    return Intl.message(
      'Flow',
      name: 'flow',
      desc: '',
      args: [],
    );
  }

  /// `Battery`
  String get footerBattery {
    return Intl.message(
      'Battery',
      name: 'footerBattery',
      desc: '',
      args: [],
    );
  }

  /// `Connect`
  String get footerConnect {
    return Intl.message(
      'Connect',
      name: 'footerConnect',
      desc: '',
      args: [],
    );
  }

  /// `Group`
  String get footerGroup {
    return Intl.message(
      'Group',
      name: 'footerGroup',
      desc: '',
      args: [],
    );
  }

  /// `Probe`
  String get footerProbe {
    return Intl.message(
      'Probe',
      name: 'footerProbe',
      desc: '',
      args: [],
    );
  }

  /// `Refill water`
  String get footerRefillWater {
    return Intl.message(
      'Refill water',
      name: 'footerRefillWater',
      desc: '',
      args: [],
    );
  }

  /// `Scale`
  String get footerScale {
    return Intl.message(
      'Scale',
      name: 'footerScale',
      desc: '',
      args: [],
    );
  }

  /// `  Tare  `
  String get footerTare {
    return Intl.message(
      '  Tare  ',
      name: 'footerTare',
      desc: '',
      args: [],
    );
  }

  /// `Water`
  String get footerWater {
    return Intl.message(
      'Water',
      name: 'footerWater',
      desc: '',
      args: [],
    );
  }

  /// `Flow [ml/s] / Pressure [bar]`
  String get graphFlowMlsPressureBar {
    return Intl.message(
      'Flow [ml/s] / Pressure [bar]',
      name: 'graphFlowMlsPressureBar',
      desc: '',
      args: [],
    );
  }

  /// `Time/s`
  String get graphTime {
    return Intl.message(
      'Time/s',
      name: 'graphTime',
      desc: '',
      args: [],
    );
  }

  /// `Green`
  String get green {
    return Intl.message(
      'Green',
      name: 'green',
      desc: '',
      args: [],
    );
  }

  /// `Hide`
  String get hide {
    return Intl.message(
      'Hide',
      name: 'hide',
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

  /// `Espresso Diary`
  String get mainMenuEspressoDiary {
    return Intl.message(
      'Espresso Diary',
      name: 'mainMenuEspressoDiary',
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

  /// `No`
  String get no {
    return Intl.message(
      'No',
      name: 'no',
      desc: '',
      args: [],
    );
  }

  /// `Off`
  String get off {
    return Intl.message(
      'Off',
      name: 'off',
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

  /// `On`
  String get on {
    return Intl.message(
      'On',
      name: 'on',
      desc: '',
      args: [],
    );
  }

  /// `Orange`
  String get orange {
    return Intl.message(
      'Orange',
      name: 'orange',
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

  /// `Privacy`
  String get privacy {
    return Intl.message(
      'Privacy',
      name: 'privacy',
      desc: '',
      args: [],
    );
  }

  /// `Profile`
  String get profile {
    return Intl.message(
      'Profile',
      name: 'profile',
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

  /// `Recipe`
  String get recipe {
    return Intl.message(
      'Recipe',
      name: 'recipe',
      desc: '',
      args: [],
    );
  }

  /// `Reconnect`
  String get reconnect {
    return Intl.message(
      'Reconnect',
      name: 'reconnect',
      desc: '',
      args: [],
    );
  }

  /// `Red`
  String get red {
    return Intl.message(
      'Red',
      name: 'red',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
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

  /// `Address`
  String get screenBeanSelectAddressOfRoaster {
    return Intl.message(
      'Address',
      name: 'screenBeanSelectAddressOfRoaster',
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

  /// `Description`
  String get screenBeanSelectDescriptionOfBean {
    return Intl.message(
      'Description',
      name: 'screenBeanSelectDescriptionOfBean',
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

  /// `Intensity`
  String get screenBeanSelectIntensity {
    return Intl.message(
      'Intensity',
      name: 'screenBeanSelectIntensity',
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

  /// `Name`
  String get screenBeanSelectNameOfRoaster {
    return Intl.message(
      'Name',
      name: 'screenBeanSelectNameOfRoaster',
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

  /// `Roast Level`
  String get screenBeanSelectRoastLevel {
    return Intl.message(
      'Roast Level',
      name: 'screenBeanSelectRoastLevel',
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

  /// `Select Roaster`
  String get screenBeanSelectSelectRoaster {
    return Intl.message(
      'Select Roaster',
      name: 'screenBeanSelectSelectRoaster',
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

  /// `Beans and Roasters`
  String get screenBeanSelectTitle {
    return Intl.message(
      'Beans and Roasters',
      name: 'screenBeanSelectTitle',
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

  /// `Error uploading shots`
  String get screenDiaryErrorUploadingShots {
    return Intl.message(
      'Error uploading shots',
      name: 'screenDiaryErrorUploadingShots',
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

  /// `Success uploading your shots`
  String get screenDiarySuccessUploadingYourShots {
    return Intl.message(
      'Success uploading your shots',
      name: 'screenDiarySuccessUploadingYourShots',
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

  /// `Espresso Diary`
  String get screenEspressoDiary {
    return Intl.message(
      'Espresso Diary',
      name: 'screenEspressoDiary',
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

  /// `Flow [ml/s] / Pressure [bar]`
  String get screenEspressoFlowMlsPressureBar {
    return Intl.message(
      'Flow [ml/s] / Pressure [bar]',
      name: 'screenEspressoFlowMlsPressureBar',
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

  /// `Pressure`
  String get screenEspressoPressure {
    return Intl.message(
      'Pressure',
      name: 'screenEspressoPressure',
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

  /// `Recipe`
  String get screenEspressoRecipe {
    return Intl.message(
      'Recipe',
      name: 'screenEspressoRecipe',
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

  /// `Target`
  String get screenEspressoTarget {
    return Intl.message(
      'Target',
      name: 'screenEspressoTarget',
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

  /// `Timer`
  String get screenEspressoTimer {
    return Intl.message(
      'Timer',
      name: 'screenEspressoTimer',
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

  /// `Weight`
  String get screenEspressoWeight {
    return Intl.message(
      'Weight',
      name: 'screenEspressoWeight',
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

  /// `Add recipe`
  String get screenRecipeAddRecipe {
    return Intl.message(
      'Add recipe',
      name: 'screenRecipeAddRecipe',
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

  /// `Coffee notes`
  String get screenRecipeCoffeeNotes {
    return Intl.message(
      'Coffee notes',
      name: 'screenRecipeCoffeeNotes',
      desc: '',
      args: [],
    );
  }

  /// `Adjustments`
  String get screenRecipeEditAdjustments {
    return Intl.message(
      'Adjustments',
      name: 'screenRecipeEditAdjustments',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get screenRecipeEditDescription {
    return Intl.message(
      'Description',
      name: 'screenRecipeEditDescription',
      desc: '',
      args: [],
    );
  }

  /// `Dose Weight-in`
  String get screenRecipeEditDoseWeightin {
    return Intl.message(
      'Dose Weight-in',
      name: 'screenRecipeEditDoseWeightin',
      desc: '',
      args: [],
    );
  }

  /// `Dosing and weights`
  String get screenRecipeEditDosingAndWeights {
    return Intl.message(
      'Dosing and weights',
      name: 'screenRecipeEditDosingAndWeights',
      desc: '',
      args: [],
    );
  }

  /// `Model`
  String get screenRecipeEditGrinderModel {
    return Intl.message(
      'Model',
      name: 'screenRecipeEditGrinderModel',
      desc: '',
      args: [],
    );
  }

  /// `Grinder Settings`
  String get screenRecipeEditGrinderSettings {
    return Intl.message(
      'Grinder Settings',
      name: 'screenRecipeEditGrinderSettings',
      desc: '',
      args: [],
    );
  }

  /// `Milk and water`
  String get screenRecipeEditMilkAndWater {
    return Intl.message(
      'Milk and water',
      name: 'screenRecipeEditMilkAndWater',
      desc: '',
      args: [],
    );
  }

  /// `Milk weight`
  String get screenRecipeEditMilkWeight {
    return Intl.message(
      'Milk weight',
      name: 'screenRecipeEditMilkWeight',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get screenRecipeEditNameOfRecipe {
    return Intl.message(
      'Name',
      name: 'screenRecipeEditNameOfRecipe',
      desc: '',
      args: [],
    );
  }

  /// `Ratio`
  String get screenRecipeEditRatio {
    return Intl.message(
      'Ratio',
      name: 'screenRecipeEditRatio',
      desc: '',
      args: [],
    );
  }

  /// `to`
  String get screenRecipeEditRatioTo {
    return Intl.message(
      'to',
      name: 'screenRecipeEditRatioTo',
      desc: '',
      args: [],
    );
  }

  /// `Temperature correction`
  String get screenRecipeEditTemperatureCorrection {
    return Intl.message(
      'Temperature correction',
      name: 'screenRecipeEditTemperatureCorrection',
      desc: '',
      args: [],
    );
  }

  /// `Edit Recipe`
  String get screenRecipeEditTitle {
    return Intl.message(
      'Edit Recipe',
      name: 'screenRecipeEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Use steam? `
  String get screenRecipeEditUseSteam {
    return Intl.message(
      'Use steam? ',
      name: 'screenRecipeEditUseSteam',
      desc: '',
      args: [],
    );
  }

  /// `Use water? `
  String get screenRecipeEditUseWater {
    return Intl.message(
      'Use water? ',
      name: 'screenRecipeEditUseWater',
      desc: '',
      args: [],
    );
  }

  /// `Weight out`
  String get screenRecipeEditWeightOut {
    return Intl.message(
      'Weight out',
      name: 'screenRecipeEditWeightOut',
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

  /// `Hot water:`
  String get screenRecipehotWater {
    return Intl.message(
      'Hot water:',
      name: 'screenRecipehotWater',
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

  /// `Profile Details`
  String get screenRecipeProfileDetails {
    return Intl.message(
      'Profile Details',
      name: 'screenRecipeProfileDetails',
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

  /// `Recipe Details`
  String get screenRecipeRecipeDetails {
    return Intl.message(
      'Recipe Details',
      name: 'screenRecipeRecipeDetails',
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

  /// `Selected profile`
  String get screenRecipeSelectedProfile {
    return Intl.message(
      'Selected profile',
      name: 'screenRecipeSelectedProfile',
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

  /// `Steam milk:`
  String get screenRecipesteamMilk {
    return Intl.message(
      'Steam milk:',
      name: 'screenRecipesteamMilk',
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

  /// `Weight-in beans [g]`
  String get screenRecipeWeightinBeansG {
    return Intl.message(
      'Weight-in beans [g]',
      name: 'screenRecipeWeightinBeansG',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get screenRoasterEditAddress {
    return Intl.message(
      'Address',
      name: 'screenRoasterEditAddress',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get screenRoasterEditDescription {
    return Intl.message(
      'Description',
      name: 'screenRoasterEditDescription',
      desc: '',
      args: [],
    );
  }

  /// `Homepage`
  String get screenRoasterEditHomepage {
    return Intl.message(
      'Homepage',
      name: 'screenRoasterEditHomepage',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get screenRoasterEditNameOfRoaster {
    return Intl.message(
      'Name',
      name: 'screenRoasterEditNameOfRoaster',
      desc: '',
      args: [],
    );
  }

  /// `Edit Roaster`
  String get screenRoasterEditTitle {
    return Intl.message(
      'Edit Roaster',
      name: 'screenRoasterEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Application Settings`
  String get screenSettingsApplicationSettings {
    return Intl.message(
      'Application Settings',
      name: 'screenSettingsApplicationSettings',
      desc: '',
      args: [],
    );
  }

  /// `Hardware and connections`
  String get screenSettingsApplicationSettingsHardwareAndConnections {
    return Intl.message(
      'Hardware and connections',
      name: 'screenSettingsApplicationSettingsHardwareAndConnections',
      desc: '',
      args: [],
    );
  }

  /// `Scan for Devices`
  String get screenSettingsApplicationSettingsScanForDevices {
    return Intl.message(
      'Scan for Devices',
      name: 'screenSettingsApplicationSettingsScanForDevices',
      desc: '',
      args: [],
    );
  }

  /// `Scan for DE1 and scales (Lunar, Skale2, Eureka, Decent)`
  String get screenSettingsApplicationSettingsScanStart {
    return Intl.message(
      'Scan for DE1 and scales (Lunar, Skale2, Eureka, Decent)',
      name: 'screenSettingsApplicationSettingsScanStart',
      desc: '',
      args: [],
    );
  }

  /// `Auto Tare`
  String get screenSettingsAutoTare {
    return Intl.message(
      'Auto Tare',
      name: 'screenSettingsAutoTare',
      desc: '',
      args: [],
    );
  }

  /// `Backup`
  String get screenSettingsBackup {
    return Intl.message(
      'Backup',
      name: 'screenSettingsBackup',
      desc: '',
      args: [],
    );
  }

  /// `Backup and maintenance`
  String get screenSettingsBackupAndMaintenance {
    return Intl.message(
      'Backup and maintenance',
      name: 'screenSettingsBackupAndMaintenance',
      desc: '',
      args: [],
    );
  }

  /// `Backup/Restore`
  String get screenSettingsBackuprestore {
    return Intl.message(
      'Backup/Restore',
      name: 'screenSettingsBackuprestore',
      desc: '',
      args: [],
    );
  }

  /// `Backup/Restore database`
  String get screenSettingsBackuprestoreDatabase {
    return Intl.message(
      'Backup/Restore database',
      name: 'screenSettingsBackuprestoreDatabase',
      desc: '',
      args: [],
    );
  }

  /// `Backup Settings`
  String get screenSettingsBackupSettings {
    return Intl.message(
      'Backup Settings',
      name: 'screenSettingsBackupSettings',
      desc: '',
      args: [],
    );
  }

  /// `Behaviour`
  String get screenSettingsBahaviour {
    return Intl.message(
      'Behaviour',
      name: 'screenSettingsBahaviour',
      desc: '',
      args: [],
    );
  }

  /// `Behaviour`
  String get screenSettingsBehaviour {
    return Intl.message(
      'Behaviour',
      name: 'screenSettingsBehaviour',
      desc: '',
      args: [],
    );
  }

  /// `Brightness, sleep and screensaver`
  String get screenSettingsBrightnessSleepAndScreensaver {
    return Intl.message(
      'Brightness, sleep and screensaver',
      name: 'screenSettingsBrightnessSleepAndScreensaver',
      desc: '',
      args: [],
    );
  }

  /// `Change how the app is changing screen brightness if not in use, switch the de1 on and shut it off if not used after a while.`
  String get screenSettingsChangeHowTheAppIsChangingScreenBrightnessIfNot {
    return Intl.message(
      'Change how the app is changing screen brightness if not in use, switch the de1 on and shut it off if not used after a while.',
      name: 'screenSettingsChangeHowTheAppIsChangingScreenBrightnessIfNot',
      desc: '',
      args: [],
    );
  }

  /// `Change how the app is handling the de1 in case of wake up and sleep.`
  String get screenSettingsChangeHowTheAppIsHandlingTheDe1InCase {
    return Intl.message(
      'Change how the app is handling the de1 in case of wake up and sleep.',
      name: 'screenSettingsChangeHowTheAppIsHandlingTheDe1InCase',
      desc: '',
      args: [],
    );
  }

  /// `Check your router for IP adress of your tablet. Open browser under`
  String get screenSettingsCheckYourRouterForIpAdressOfYourTabletOpen {
    return Intl.message(
      'Check your router for IP adress of your tablet. Open browser under',
      name: 'screenSettingsCheckYourRouterForIpAdressOfYourTabletOpen',
      desc: '',
      args: [],
    );
  }

  /// `Cloud and Network`
  String get screenSettingsCloudAndNetwork {
    return Intl.message(
      'Cloud and Network',
      name: 'screenSettingsCloudAndNetwork',
      desc: '',
      args: [],
    );
  }

  /// `Cloud shot upload`
  String get screenSettingsCloudShotUpload {
    return Intl.message(
      'Cloud shot upload',
      name: 'screenSettingsCloudShotUpload',
      desc: '',
      args: [],
    );
  }

  /// `Coffee pouring`
  String get screenSettingsCoffeePouring {
    return Intl.message(
      'Coffee pouring',
      name: 'screenSettingsCoffeePouring',
      desc: '',
      args: [],
    );
  }

  /// `Coffee`
  String get screenSettingsCoffeeSection {
    return Intl.message(
      'Coffee',
      name: 'screenSettingsCoffeeSection',
      desc: '',
      args: [],
    );
  }

  /// `Dark theme`
  String get screenSettingsDarkTheme {
    return Intl.message(
      'Dark theme',
      name: 'screenSettingsDarkTheme',
      desc: '',
      args: [],
    );
  }

  /// `Delete all screensaver files`
  String get screenSettingsDeleteAllScreensaverFiles {
    return Intl.message(
      'Delete all screensaver files',
      name: 'screenSettingsDeleteAllScreensaverFiles',
      desc: '',
      args: [],
    );
  }

  /// `Do not let tablet go to lock screen (0=do not lock screen, 240=keep always locked) [min]`
  String get screenSettingsDoNotLetTabletGoToLockScreen0doNot {
    return Intl.message(
      'Do not let tablet go to lock screen (0=do not lock screen, 240=keep always locked) [min]',
      name: 'screenSettingsDoNotLetTabletGoToLockScreen0doNot',
      desc: '',
      args: [],
    );
  }

  /// `Enable Mini Website with port 8888`
  String get screenSettingsEnableMiniWebsiteWithPort8888 {
    return Intl.message(
      'Enable Mini Website with port 8888',
      name: 'screenSettingsEnableMiniWebsiteWithPort8888',
      desc: '',
      args: [],
    );
  }

  /// `Enable MQTT`
  String get screenSettingsEnableMqtt {
    return Intl.message(
      'Enable MQTT',
      name: 'screenSettingsEnableMqtt',
      desc: '',
      args: [],
    );
  }

  /// `English`
  String get screenSettingsEnglish {
    return Intl.message(
      'English',
      name: 'screenSettingsEnglish',
      desc: '',
      args: [],
    );
  }

  /// `Exit app`
  String get screenSettingsExitApp {
    return Intl.message(
      'Exit app',
      name: 'screenSettingsExitApp',
      desc: '',
      args: [],
    );
  }

  /// `Failed restoring backup`
  String get screenSettingsFailedRestoringBackup {
    return Intl.message(
      'Failed restoring backup',
      name: 'screenSettingsFailedRestoringBackup',
      desc: '',
      args: [],
    );
  }

  /// `Feedback and Crash reporting`
  String get screenSettingsFeedbackAndCrashReporting {
    return Intl.message(
      'Feedback and Crash reporting',
      name: 'screenSettingsFeedbackAndCrashReporting',
      desc: '',
      args: [],
    );
  }

  /// `Flush timer [s]`
  String get screenSettingsFlushTimerS {
    return Intl.message(
      'Flush timer [s]',
      name: 'screenSettingsFlushTimerS',
      desc: '',
      args: [],
    );
  }

  /// `German`
  String get screenSettingsGerman {
    return Intl.message(
      'German',
      name: 'screenSettingsGerman',
      desc: '',
      args: [],
    );
  }

  /// `Go back to Recipe screen if timeout occured`
  String get screenSettingsGoBackToRecipeScreenIfTimeoutOccured {
    return Intl.message(
      'Go back to Recipe screen if timeout occured',
      name: 'screenSettingsGoBackToRecipeScreenIfTimeoutOccured',
      desc: '',
      args: [],
    );
  }

  /// `Handling of connections to other external systems like MQTT and Visualizer.`
  String
      get screenSettingsHandlingOfConnectionsToOtherExternalSystemsLikeMqttAnd {
    return Intl.message(
      'Handling of connections to other external systems like MQTT and Visualizer.',
      name:
          'screenSettingsHandlingOfConnectionsToOtherExternalSystemsLikeMqttAnd',
      desc: '',
      args: [],
    );
  }

  /// `If a shot is starting, auto-tare the scale`
  String get screenSettingsIfAShotIsStartingAutotareTheScale {
    return Intl.message(
      'If a shot is starting, auto-tare the scale',
      name: 'screenSettingsIfAShotIsStartingAutotareTheScale',
      desc: '',
      args: [],
    );
  }

  /// `If the scale is connected it is used to stop the shot if the profile has a limit given.`
  String get screenSettingsIfTheScaleIsConnectedItIsUsedToStop {
    return Intl.message(
      'If the scale is connected it is used to stop the shot if the profile has a limit given.',
      name: 'screenSettingsIfTheScaleIsConnectedItIsUsedToStop',
      desc: '',
      args: [],
    );
  }

  /// `If you have no GHC installed, you would need the flush screen`
  String get screenSettingsIfYouHaveNoGhcInstalledYouWouldNeedThe {
    return Intl.message(
      'If you have no GHC installed, you would need the flush screen',
      name: 'screenSettingsIfYouHaveNoGhcInstalledYouWouldNeedThe',
      desc: '',
      args: [],
    );
  }

  /// `Keep Tablet charged between 60-90%`
  String get screenSettingsKeepTabletChargedBetween6090 {
    return Intl.message(
      'Keep Tablet charged between 60-90%',
      name: 'screenSettingsKeepTabletChargedBetween6090',
      desc: '',
      args: [],
    );
  }

  /// `Korean`
  String get screenSettingsKorean {
    return Intl.message(
      'Korean',
      name: 'screenSettingsKorean',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get screenSettingsLanguage {
    return Intl.message(
      'Language',
      name: 'screenSettingsLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Light theme`
  String get screenSettingsLightTheme {
    return Intl.message(
      'Light theme',
      name: 'screenSettingsLightTheme',
      desc: '',
      args: [],
    );
  }

  /// `Load Screensaver files`
  String get screenSettingsLoadScreensaverFiles {
    return Intl.message(
      'Load Screensaver files',
      name: 'screenSettingsLoadScreensaverFiles',
      desc: '',
      args: [],
    );
  }

  /// `Message Queue Broadcast (MQTT) client`
  String get screenSettingsMessageQueueBroadcastMqttClient {
    return Intl.message(
      'Message Queue Broadcast (MQTT) client',
      name: 'screenSettingsMessageQueueBroadcastMqttClient',
      desc: '',
      args: [],
    );
  }

  /// `Milk steaming thermometer support`
  String get screenSettingsMilkSteamingThermometerSupport {
    return Intl.message(
      'Milk steaming thermometer support',
      name: 'screenSettingsMilkSteamingThermometerSupport',
      desc: '',
      args: [],
    );
  }

  /// `Mini Website`
  String get screenSettingsMiniWebsite {
    return Intl.message(
      'Mini Website',
      name: 'screenSettingsMiniWebsite',
      desc: '',
      args: [],
    );
  }

  /// `MQTT Password`
  String get screenSettingsMqttPassword {
    return Intl.message(
      'MQTT Password',
      name: 'screenSettingsMqttPassword',
      desc: '',
      args: [],
    );
  }

  /// `MQTT Port`
  String get screenSettingsMqttPort {
    return Intl.message(
      'MQTT Port',
      name: 'screenSettingsMqttPort',
      desc: '',
      args: [],
    );
  }

  /// `MQTT root topic`
  String get screenSettingsMqttRootTopic {
    return Intl.message(
      'MQTT root topic',
      name: 'screenSettingsMqttRootTopic',
      desc: '',
      args: [],
    );
  }

  /// `MQTT Server`
  String get screenSettingsMqttServer {
    return Intl.message(
      'MQTT Server',
      name: 'screenSettingsMqttServer',
      desc: '',
      args: [],
    );
  }

  /// `MQTT User`
  String get screenSettingsMqttUser {
    return Intl.message(
      'MQTT User',
      name: 'screenSettingsMqttUser',
      desc: '',
      args: [],
    );
  }

  /// `password`
  String get screenSettingsPassword {
    return Intl.message(
      'password',
      name: 'screenSettingsPassword',
      desc: '',
      args: [],
    );
  }

  /// `Password can't be smaller than 7 letters`
  String get screenSettingsPasswordCantBeSmallerThan7Letters {
    return Intl.message(
      'Password can\'t be smaller than 7 letters',
      name: 'screenSettingsPasswordCantBeSmallerThan7Letters',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Settings`
  String get screenSettingsPrivacySettings {
    return Intl.message(
      'Privacy Settings',
      name: 'screenSettingsPrivacySettings',
      desc: '',
      args: [],
    );
  }

  /// `Reduce brightness to level`
  String get screenSettingsReduceBrightnessToLevel {
    return Intl.message(
      'Reduce brightness to level',
      name: 'screenSettingsReduceBrightnessToLevel',
      desc: '',
      args: [],
    );
  }

  /// `Reduce screen brightness after (0=off) [min]`
  String get screenSettingsReduceScreenBrightnessAfter0offMin {
    return Intl.message(
      'Reduce screen brightness after (0=off) [min]',
      name: 'screenSettingsReduceScreenBrightnessAfter0offMin',
      desc: '',
      args: [],
    );
  }

  /// `Restore`
  String get screenSettingsRestore {
    return Intl.message(
      'Restore',
      name: 'screenSettingsRestore',
      desc: '',
      args: [],
    );
  }

  /// `Restored backup`
  String get screenSettingsRestoredBackup {
    return Intl.message(
      'Restored backup',
      name: 'screenSettingsRestoredBackup',
      desc: '',
      args: [],
    );
  }

  /// `Saved backup`
  String get screenSettingsSavedBackup {
    return Intl.message(
      'Saved backup',
      name: 'screenSettingsSavedBackup',
      desc: '',
      args: [],
    );
  }

  /// `Scale support`
  String get screenSettingsScaleSupport {
    return Intl.message(
      'Scale support',
      name: 'screenSettingsScaleSupport',
      desc: '',
      args: [],
    );
  }

  /// `Screen and Brightness`
  String get screenSettingsScreenAndBrightness {
    return Intl.message(
      'Screen and Brightness',
      name: 'screenSettingsScreenAndBrightness',
      desc: '',
      args: [],
    );
  }

  /// `Second Flush timer [s]`
  String get screenSettingsSecondFlushTimerS {
    return Intl.message(
      'Second Flush timer [s]',
      name: 'screenSettingsSecondFlushTimerS',
      desc: '',
      args: [],
    );
  }

  /// `Select files`
  String get screenSettingsSelectFiles {
    return Intl.message(
      'Select files',
      name: 'screenSettingsSelectFiles',
      desc: '',
      args: [],
    );
  }

  /// `Send de1 shot updates`
  String get screenSettingsSendDe1ShotUpdates {
    return Intl.message(
      'Send de1 shot updates',
      name: 'screenSettingsSendDe1ShotUpdates',
      desc: '',
      args: [],
    );
  }

  /// `Send de1 state updates`
  String get screenSettingsSendDe1StateUpdates {
    return Intl.message(
      'Send de1 state updates',
      name: 'screenSettingsSendDe1StateUpdates',
      desc: '',
      args: [],
    );
  }

  /// `Send de1 water level updates`
  String get screenSettingsSendDe1WaterLevelUpdates {
    return Intl.message(
      'Send de1 water level updates',
      name: 'screenSettingsSendDe1WaterLevelUpdates',
      desc: '',
      args: [],
    );
  }

  /// `Send informations to sentry.io if the app crashes or you use the feedback option. Check https://sentry.io/privacy/ for detailed data privacy description.`
  String get screenSettingsSendInformationsToSentryioIfTheAppCrashesOrYou {
    return Intl.message(
      'Send informations to sentry.io if the app crashes or you use the feedback option. Check https://sentry.io/privacy/ for detailed data privacy description.',
      name: 'screenSettingsSendInformationsToSentryioIfTheAppCrashesOrYou',
      desc: '',
      args: [],
    );
  }

  /// `Sending the status of the de1`
  String get screenSettingsSendingTheStatusOfTheDe1 {
    return Intl.message(
      'Sending the status of the de1',
      name: 'screenSettingsSendingTheStatusOfTheDe1',
      desc: '',
      args: [],
    );
  }

  /// `Send tablet battery level updates`
  String get screenSettingsSendTabletBatteryLevelUpdates {
    return Intl.message(
      'Send tablet battery level updates',
      name: 'screenSettingsSendTabletBatteryLevelUpdates',
      desc: '',
      args: [],
    );
  }

  /// `Settings are restored. Please close app and restart.`
  String get screenSettingsSettingsAreRestoredPleaseCloseAppAndRestart {
    return Intl.message(
      'Settings are restored. Please close app and restart.',
      name: 'screenSettingsSettingsAreRestoredPleaseCloseAppAndRestart',
      desc: '',
      args: [],
    );
  }

  /// `Shot Settings`
  String get screenSettingsShotSettings {
    return Intl.message(
      'Shot Settings',
      name: 'screenSettingsShotSettings',
      desc: '',
      args: [],
    );
  }

  /// `Show Flush`
  String get screenSettingsShowFlush {
    return Intl.message(
      'Show Flush',
      name: 'screenSettingsShowFlush',
      desc: '',
      args: [],
    );
  }

  /// `Smart charging`
  String get screenSettingsSmartCharging {
    return Intl.message(
      'Smart charging',
      name: 'screenSettingsSmartCharging',
      desc: '',
      args: [],
    );
  }

  /// `Spanish`
  String get screenSettingsSpanish {
    return Intl.message(
      'Spanish',
      name: 'screenSettingsSpanish',
      desc: '',
      args: [],
    );
  }

  /// `Special Bluetooth devices`
  String get screenSettingsSpecialBluetoothDevices {
    return Intl.message(
      'Special Bluetooth devices',
      name: 'screenSettingsSpecialBluetoothDevices',
      desc: '',
      args: [],
    );
  }

  /// `Stop before weight was reached [s]`
  String get screenSettingsStopBeforeWeightWasReachedS {
    return Intl.message(
      'Stop before weight was reached [s]',
      name: 'screenSettingsStopBeforeWeightWasReachedS',
      desc: '',
      args: [],
    );
  }

  /// `Stop on Weight if scale detected`
  String get screenSettingsStopOnWeightIfScaleDetected {
    return Intl.message(
      'Stop on Weight if scale detected',
      name: 'screenSettingsStopOnWeightIfScaleDetected',
      desc: '',
      args: [],
    );
  }

  /// `Switch de1 to sleep mode if it is idle for some time [min]`
  String get screenSettingsSwitchDe1ToSleepModeIfItIsIdleFor {
    return Intl.message(
      'Switch de1 to sleep mode if it is idle for some time [min]',
      name: 'screenSettingsSwitchDe1ToSleepModeIfItIsIdleFor',
      desc: '',
      args: [],
    );
  }

  /// `Switch off steam heating`
  String get screenSettingsSwitchOffSteamHeating {
    return Intl.message(
      'Switch off steam heating',
      name: 'screenSettingsSwitchOffSteamHeating',
      desc: '',
      args: [],
    );
  }

  /// `Switch on screensaver if de1 manually switched to sleep`
  String get screenSettingsSwitchOnScreensaverIfDe1ManuallySwitchedToSleep {
    return Intl.message(
      'Switch on screensaver if de1 manually switched to sleep',
      name: 'screenSettingsSwitchOnScreensaverIfDe1ManuallySwitchedToSleep',
      desc: '',
      args: [],
    );
  }

  /// `Tablet default`
  String get screenSettingsTabletDefault {
    return Intl.message(
      'Tablet default',
      name: 'screenSettingsTabletDefault',
      desc: '',
      args: [],
    );
  }

  /// `Tablet`
  String get screenSettingsTabletGroup {
    return Intl.message(
      'Tablet',
      name: 'screenSettingsTabletGroup',
      desc: '',
      args: [],
    );
  }

  /// `Language and Theme selection`
  String get screenSettingsThemeSelection {
    return Intl.message(
      'Language and Theme selection',
      name: 'screenSettingsThemeSelection',
      desc: '',
      args: [],
    );
  }

  /// `This can lead to a higher load on your MQTT server as the message frequency is about 10Hz.`
  String get screenSettingsThisCanLeadToAHigherLoadOnYourMqtt {
    return Intl.message(
      'This can lead to a higher load on your MQTT server as the message frequency is about 10Hz.',
      name: 'screenSettingsThisCanLeadToAHigherLoadOnYourMqtt',
      desc: '',
      args: [],
    );
  }

  /// `To save energy the steam heater will be turned off and the steam tab will be hidden.`
  String get screenSettingsToSaveEnergyTheSteamHeaterWillBeTurnedOff {
    return Intl.message(
      'To save energy the steam heater will be turned off and the steam tab will be hidden.',
      name: 'screenSettingsToSaveEnergyTheSteamHeaterWillBeTurnedOff',
      desc: '',
      args: [],
    );
  }

  /// `Upload Shots to Visualizer`
  String get screenSettingsUploadShotsToVisualizer {
    return Intl.message(
      'Upload Shots to Visualizer',
      name: 'screenSettingsUploadShotsToVisualizer',
      desc: '',
      args: [],
    );
  }

  /// `User Name can't be smaller than 4 letters`
  String get screenSettingsUserNameCantBeSmallerThan4Letters {
    return Intl.message(
      'User Name can\'t be smaller than 4 letters',
      name: 'screenSettingsUserNameCantBeSmallerThan4Letters',
      desc: '',
      args: [],
    );
  }

  /// `User Name/email`
  String get screenSettingsUserNameemail {
    return Intl.message(
      'User Name/email',
      name: 'screenSettingsUserNameemail',
      desc: '',
      args: [],
    );
  }

  /// `Wake up de1 if app is launched`
  String get screenSettingsWakeUpDe1IfAppIsLaunched {
    return Intl.message(
      'Wake up de1 if app is launched',
      name: 'screenSettingsWakeUpDe1IfAppIsLaunched',
      desc: '',
      args: [],
    );
  }

  /// `Wake up de1 if screen tapped (if screen was off)`
  String get screenSettingsWakeUpDe1IfScreenTappedIfScreenWasOff {
    return Intl.message(
      'Wake up de1 if screen tapped (if screen was off)',
      name: 'screenSettingsWakeUpDe1IfScreenTappedIfScreenWasOff',
      desc: '',
      args: [],
    );
  }

  /// `You changed critical settings. You need to restart the app to make the settings active.`
  String get screenSettingsYouChangedCriticalSettingsYouNeedToRestartTheApp {
    return Intl.message(
      'You changed critical settings. You need to restart the app to make the settings active.',
      name: 'screenSettingsYouChangedCriticalSettingsYouNeedToRestartTheApp',
      desc: '',
      args: [],
    );
  }

  /// `Barrista`
  String get screenShotEditBarrista {
    return Intl.message(
      'Barrista',
      name: 'screenShotEditBarrista',
      desc: '',
      args: [],
    );
  }

  /// `Describe your experience`
  String get screenShotEditDescribeYourExperience {
    return Intl.message(
      'Describe your experience',
      name: 'screenShotEditDescribeYourExperience',
      desc: '',
      args: [],
    );
  }

  /// `Dose weight [g]`
  String get screenShotEditDoseWeightG {
    return Intl.message(
      'Dose weight [g]',
      name: 'screenShotEditDoseWeightG',
      desc: '',
      args: [],
    );
  }

  /// `Drinker`
  String get screenShotEditDrinker {
    return Intl.message(
      'Drinker',
      name: 'screenShotEditDrinker',
      desc: '',
      args: [],
    );
  }

  /// `Drink weight [g]`
  String get screenShotEditDrinkWeightG {
    return Intl.message(
      'Drink weight [g]',
      name: 'screenShotEditDrinkWeightG',
      desc: '',
      args: [],
    );
  }

  /// `Enjoyment`
  String get screenShotEditEnjoyment {
    return Intl.message(
      'Enjoyment',
      name: 'screenShotEditEnjoyment',
      desc: '',
      args: [],
    );
  }

  /// `Extraction yield`
  String get screenShotEditExtractionYield {
    return Intl.message(
      'Extraction yield',
      name: 'screenShotEditExtractionYield',
      desc: '',
      args: [],
    );
  }

  /// `Grinder`
  String get screenShotEditGrinder {
    return Intl.message(
      'Grinder',
      name: 'screenShotEditGrinder',
      desc: '',
      args: [],
    );
  }

  /// `Grinder settings`
  String get screenShotEditGrinderSettings {
    return Intl.message(
      'Grinder settings',
      name: 'screenShotEditGrinderSettings',
      desc: '',
      args: [],
    );
  }

  /// `Open in Visualizer.coffee`
  String get screenShotEditOpenInVisualizercoffee {
    return Intl.message(
      'Open in Visualizer.coffee',
      name: 'screenShotEditOpenInVisualizercoffee',
      desc: '',
      args: [],
    );
  }

  /// `Pouring time [s]`
  String get screenShotEditPouringTimeS {
    return Intl.message(
      'Pouring time [s]',
      name: 'screenShotEditPouringTimeS',
      desc: '',
      args: [],
    );
  }

  /// `Pouring weight [g]`
  String get screenShotEditPouringWeightG {
    return Intl.message(
      'Pouring weight [g]',
      name: 'screenShotEditPouringWeightG',
      desc: '',
      args: [],
    );
  }

  /// `Success uploading your shot`
  String get screenShotEditSuccessUploadingYourShot {
    return Intl.message(
      'Success uploading your shot',
      name: 'screenShotEditSuccessUploadingYourShot',
      desc: '',
      args: [],
    );
  }

  /// `Describe your experience with shot from {desc}`
  String screenShotEditTitle(Object desc) {
    return Intl.message(
      'Describe your experience with shot from $desc',
      name: 'screenShotEditTitle',
      desc: '',
      args: [desc],
    );
  }

  /// `Total Dissolved Solidss (TDS)`
  String get screenShotEditTotalDissolvedSolidssTds {
    return Intl.message(
      'Total Dissolved Solidss (TDS)',
      name: 'screenShotEditTotalDissolvedSolidssTds',
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

  /// `Steam Flowrate {flow} ml/s`
  String screenSteamFlowrate(Object flow) {
    return Intl.message(
      'Steam Flowrate $flow ml/s',
      name: 'screenSteamFlowrate',
      desc: '',
      args: [flow],
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

  /// `On (slow purge on 1st stop)`
  String get screenSteamOnSlowPurgeOn1stStop {
    return Intl.message(
      'On (slow purge on 1st stop)',
      name: 'screenSteamOnSlowPurgeOn1stStop',
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

  /// `Stop at Temperature {temp} °C`
  String screenSteamStopAtTemperatur(Object temp) {
    return Intl.message(
      'Stop at Temperature $temp °C',
      name: 'screenSteamStopAtTemperatur',
      desc: '',
      args: [temp],
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

  /// `Temp Tip`
  String get screenSteamTempTip {
    return Intl.message(
      'Temp Tip',
      name: 'screenSteamTempTip',
      desc: '',
      args: [],
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

  /// `Time/s`
  String get screenSteamTimeS {
    return Intl.message(
      'Time/s',
      name: 'screenSteamTimeS',
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

  /// `Weight {w} g`
  String screenWaterWeightG(Object w) {
    return Intl.message(
      'Weight $w g',
      name: 'screenWaterWeightG',
      desc: '',
      args: [w],
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

  /// `Show`
  String get show {
    return Intl.message(
      'Show',
      name: 'show',
      desc: '',
      args: [],
    );
  }

  /// `Start`
  String get start {
    return Intl.message(
      'Start',
      name: 'start',
      desc: '',
      args: [],
    );
  }

  /// `disconnected`
  String get stateDisconnected {
    return Intl.message(
      'disconnected',
      name: 'stateDisconnected',
      desc: '',
      args: [],
    );
  }

  /// `disconnected`
  String get state_Disconnected {
    return Intl.message(
      'disconnected',
      name: 'state_Disconnected',
      desc: '',
      args: [],
    );
  }

  /// `heated up`
  String get stateIdleHeated {
    return Intl.message(
      'heated up',
      name: 'stateIdleHeated',
      desc: '',
      args: [],
    );
  }

  /// `pour`
  String get statePour {
    return Intl.message(
      'pour',
      name: 'statePour',
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

  /// `Stop`
  String get stop {
    return Intl.message(
      'Stop',
      name: 'stop',
      desc: '',
      args: [],
    );
  }

  /// `Heating Water`
  String get subStateHeatWaterHeater {
    return Intl.message(
      'Heating Water',
      name: 'subStateHeatWaterHeater',
      desc: '',
      args: [],
    );
  }

  /// `Heating Tank`
  String get subStateHeatWaterTank {
    return Intl.message(
      'Heating Tank',
      name: 'subStateHeatWaterTank',
      desc: '',
      args: [],
    );
  }

  /// `Switch on`
  String get switchOn {
    return Intl.message(
      'Switch on',
      name: 'switchOn',
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

  /// `Flush`
  String get tabHomeFlush {
    return Intl.message(
      'Flush',
      name: 'tabHomeFlush',
      desc: '',
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

  /// `Temp`
  String get temp {
    return Intl.message(
      'Temp',
      name: 'temp',
      desc: '',
      args: [],
    );
  }

  /// `must not be empty`
  String get validatorNotBeEmpty {
    return Intl.message(
      'must not be empty',
      name: 'validatorNotBeEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Wait`
  String get wait {
    return Intl.message(
      'Wait',
      name: 'wait',
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

  /// `Stop on weight: `
  String get screenRecipeStopOnWeight {
    return Intl.message(
      'Stop on weight: ',
      name: 'screenRecipeStopOnWeight',
      desc: '',
      args: [],
    );
  }

  /// `Disable Stop-on-Weight (Select this for pour over where you do not want to stop on weight): `
  String
      get screenRecipeEditDisableStoponweightSelectThisForPourOverWhereYouDo {
    return Intl.message(
      'Disable Stop-on-Weight (Select this for pour over where you do not want to stop on weight): ',
      name:
          'screenRecipeEditDisableStoponweightSelectThisForPourOverWhereYouDo',
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
      Locale.fromSubtags(languageCode: 'ko'),
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
