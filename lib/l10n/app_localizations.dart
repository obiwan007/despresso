import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('ko')
  ];

  /// No description provided for @beans.
  ///
  /// In en, this message translates to:
  /// **'Beans'**
  String get beans;

  /// No description provided for @blue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get blue;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'disconnected'**
  String get disconnected;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'EDIT'**
  String get edit;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'error'**
  String get error;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @flow.
  ///
  /// In en, this message translates to:
  /// **'Flow'**
  String get flow;

  /// No description provided for @footerBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get footerBattery;

  /// No description provided for @footerConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get footerConnect;

  /// No description provided for @footerGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get footerGroup;

  /// No description provided for @footerProbe.
  ///
  /// In en, this message translates to:
  /// **'Probe'**
  String get footerProbe;

  /// No description provided for @footerRefillWater.
  ///
  /// In en, this message translates to:
  /// **'Refill water'**
  String get footerRefillWater;

  /// No description provided for @footerScale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get footerScale;

  /// No description provided for @footerTare.
  ///
  /// In en, this message translates to:
  /// **'  Tare  '**
  String get footerTare;

  /// No description provided for @footerWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get footerWater;

  /// No description provided for @graphFlowMlsPressureBar.
  ///
  /// In en, this message translates to:
  /// **'Flow [ml/s] / Pressure [bar]'**
  String get graphFlowMlsPressureBar;

  /// No description provided for @graphTime.
  ///
  /// In en, this message translates to:
  /// **'Time/s'**
  String get graphTime;

  /// No description provided for @green.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get green;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @mainMenuDespressoFeedback.
  ///
  /// In en, this message translates to:
  /// **'Despresso Feedback'**
  String get mainMenuDespressoFeedback;

  /// No description provided for @mainMenuEspressoDiary.
  ///
  /// In en, this message translates to:
  /// **'Espresso Diary'**
  String get mainMenuEspressoDiary;

  /// No description provided for @mainMenuFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get mainMenuFeedback;

  /// No description provided for @mainMenuMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get mainMenuMaintenance;

  /// No description provided for @mainMenuStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get mainMenuStatistics;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @orange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get orange;

  /// No description provided for @pressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get pressure;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @profiles.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profiles;

  /// No description provided for @recipe.
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get recipe;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get red;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @screenBeanSelectAcidity.
  ///
  /// In en, this message translates to:
  /// **'Acidity'**
  String get screenBeanSelectAcidity;

  /// No description provided for @screenBeanSelectAddressOfRoaster.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get screenBeanSelectAddressOfRoaster;

  /// No description provided for @screenBeanSelectDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get screenBeanSelectDaysAgo;

  /// No description provided for @screenBeanSelectDescriptionOfBean.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get screenBeanSelectDescriptionOfBean;

  /// No description provided for @screenBeanSelectDescriptionOfRoaster.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get screenBeanSelectDescriptionOfRoaster;

  /// No description provided for @screenBeanSelectHomepageOfRoaster.
  ///
  /// In en, this message translates to:
  /// **'Homepage'**
  String get screenBeanSelectHomepageOfRoaster;

  /// No description provided for @screenBeanSelectIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get screenBeanSelectIntensity;

  /// No description provided for @screenBeanSelectNameOfBean.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get screenBeanSelectNameOfBean;

  /// No description provided for @screenBeanSelectNameOfRoaster.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get screenBeanSelectNameOfRoaster;

  /// No description provided for @screenBeanSelectRoastingDate.
  ///
  /// In en, this message translates to:
  /// **'Roasting date'**
  String get screenBeanSelectRoastingDate;

  /// No description provided for @screenBeanSelectRoastLevel.
  ///
  /// In en, this message translates to:
  /// **'Roast Level'**
  String get screenBeanSelectRoastLevel;

  /// No description provided for @screenBeanSelectSelectBeans.
  ///
  /// In en, this message translates to:
  /// **'Select Beans'**
  String get screenBeanSelectSelectBeans;

  /// No description provided for @screenBeanSelectSelectRoaster.
  ///
  /// In en, this message translates to:
  /// **'Select Roaster'**
  String get screenBeanSelectSelectRoaster;

  /// No description provided for @screenBeanSelectTasting.
  ///
  /// In en, this message translates to:
  /// **'Tasting'**
  String get screenBeanSelectTasting;

  /// No description provided for @screenBeanSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Beans and Roasters'**
  String get screenBeanSelectTitle;

  /// No description provided for @screenBeanSelectTypeOfBeans.
  ///
  /// In en, this message translates to:
  /// **'Type of Beans'**
  String get screenBeanSelectTypeOfBeans;

  /// No description provided for @screenDiaryErrorUploadingShots.
  ///
  /// In en, this message translates to:
  /// **'Error uploading shots'**
  String get screenDiaryErrorUploadingShots;

  /// No description provided for @screenDiaryNoShotsToUploadSelected.
  ///
  /// In en, this message translates to:
  /// **'No shots to upload selected'**
  String get screenDiaryNoShotsToUploadSelected;

  /// No description provided for @screenDiaryNothingSelected.
  ///
  /// In en, this message translates to:
  /// **'Nothing selected'**
  String get screenDiaryNothingSelected;

  /// No description provided for @screenDiaryOverlaymode.
  ///
  /// In en, this message translates to:
  /// **'Overlaymode:'**
  String get screenDiaryOverlaymode;

  /// No description provided for @screenDiarySuccessUploadingYourShots.
  ///
  /// In en, this message translates to:
  /// **'Success uploading your shots'**
  String get screenDiarySuccessUploadingYourShots;

  /// No description provided for @screenEspressoBean.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get screenEspressoBean;

  /// No description provided for @screenEspressoDiary.
  ///
  /// In en, this message translates to:
  /// **'Espresso Diary'**
  String get screenEspressoDiary;

  /// No description provided for @screenEspressoFlow.
  ///
  /// In en, this message translates to:
  /// **'Flow'**
  String get screenEspressoFlow;

  /// No description provided for @screenEspressoFlowMlsPressureBar.
  ///
  /// In en, this message translates to:
  /// **'Flow [ml/s] / Pressure [bar]'**
  String get screenEspressoFlowMlsPressureBar;

  /// No description provided for @screenEspressoPour.
  ///
  /// In en, this message translates to:
  /// **'Pour: {sec} s'**
  String screenEspressoPour(Object sec);

  /// No description provided for @screenEspressoPressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get screenEspressoPressure;

  /// No description provided for @screenEspressoProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get screenEspressoProfile;

  /// No description provided for @screenEspressoRecipe.
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get screenEspressoRecipe;

  /// No description provided for @screenEspressoRefillTheWaterTank.
  ///
  /// In en, this message translates to:
  /// **'Refill the water tank'**
  String get screenEspressoRefillTheWaterTank;

  /// No description provided for @screenEspressoTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get screenEspressoTarget;

  /// No description provided for @screenEspressoTemp.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get screenEspressoTemp;

  /// No description provided for @screenEspressoTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get screenEspressoTimer;

  /// No description provided for @screenEspressoTimes.
  ///
  /// In en, this message translates to:
  /// **'Time/s'**
  String get screenEspressoTimes;

  /// No description provided for @screenEspressoTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {sec} s'**
  String screenEspressoTotal(Object sec);

  /// No description provided for @screenEspressoTtw.
  ///
  /// In en, this message translates to:
  /// **'TTW: {sec} s'**
  String screenEspressoTtw(Object sec);

  /// No description provided for @screenEspressoWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get screenEspressoWeight;

  /// No description provided for @screenEspressoWeightG.
  ///
  /// In en, this message translates to:
  /// **'Weight [g]'**
  String get screenEspressoWeightG;

  /// No description provided for @screenRecipeAddRecipe.
  ///
  /// In en, this message translates to:
  /// **'Add recipe'**
  String get screenRecipeAddRecipe;

  /// No description provided for @screenRecipeAdjustTempC.
  ///
  /// In en, this message translates to:
  /// **'Adjust Temp [°C]'**
  String get screenRecipeAdjustTempC;

  /// No description provided for @screenRecipeCoffeeNotes.
  ///
  /// In en, this message translates to:
  /// **'Coffee notes'**
  String get screenRecipeCoffeeNotes;

  /// No description provided for @screenRecipeEditAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Adjustments'**
  String get screenRecipeEditAdjustments;

  /// No description provided for @screenRecipeEditDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get screenRecipeEditDescription;

  /// No description provided for @screenRecipeEditDisableStoponweightSelectThisForPourOverWhereYouDo.
  ///
  /// In en, this message translates to:
  /// **'Disable Stop-on-Weight (Select this for pour over where you do not want to stop on weight): '**
  String get screenRecipeEditDisableStoponweightSelectThisForPourOverWhereYouDo;

  /// No description provided for @screenRecipeEditDoseWeightin.
  ///
  /// In en, this message translates to:
  /// **'Dose Weight-in'**
  String get screenRecipeEditDoseWeightin;

  /// No description provided for @screenRecipeEditDosingAndWeights.
  ///
  /// In en, this message translates to:
  /// **'Dosing and weights'**
  String get screenRecipeEditDosingAndWeights;

  /// No description provided for @screenRecipeEditGrinderModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get screenRecipeEditGrinderModel;

  /// No description provided for @screenRecipeEditGrinderSettings.
  ///
  /// In en, this message translates to:
  /// **'Grinder Settings'**
  String get screenRecipeEditGrinderSettings;

  /// No description provided for @screenRecipeEditMilkAndWater.
  ///
  /// In en, this message translates to:
  /// **'Milk and water'**
  String get screenRecipeEditMilkAndWater;

  /// No description provided for @screenRecipeEditMilkWeight.
  ///
  /// In en, this message translates to:
  /// **'Milk weight'**
  String get screenRecipeEditMilkWeight;

  /// No description provided for @screenRecipeEditNameOfRecipe.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get screenRecipeEditNameOfRecipe;

  /// No description provided for @screenRecipeEditRatio.
  ///
  /// In en, this message translates to:
  /// **'Ratio'**
  String get screenRecipeEditRatio;

  /// No description provided for @screenRecipeEditRatioTo.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get screenRecipeEditRatioTo;

  /// No description provided for @screenRecipeEditTemperatureCorrection.
  ///
  /// In en, this message translates to:
  /// **'Temperature correction'**
  String get screenRecipeEditTemperatureCorrection;

  /// No description provided for @screenRecipeEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Recipe'**
  String get screenRecipeEditTitle;

  /// No description provided for @screenRecipeEditUseSteam.
  ///
  /// In en, this message translates to:
  /// **'Use steam? '**
  String get screenRecipeEditUseSteam;

  /// No description provided for @screenRecipeEditUseWater.
  ///
  /// In en, this message translates to:
  /// **'Use water? '**
  String get screenRecipeEditUseWater;

  /// No description provided for @screenRecipeEditWeightOut.
  ///
  /// In en, this message translates to:
  /// **'Weight out'**
  String get screenRecipeEditWeightOut;

  /// No description provided for @screenRecipeGrindSettings.
  ///
  /// In en, this message translates to:
  /// **'Grind Setting:'**
  String get screenRecipeGrindSettings;

  /// No description provided for @screenRecipehotWater.
  ///
  /// In en, this message translates to:
  /// **'Hot water: '**
  String get screenRecipehotWater;

  /// No description provided for @screenRecipeInitialTemp.
  ///
  /// In en, this message translates to:
  /// **'Initial temperature:'**
  String get screenRecipeInitialTemp;

  /// No description provided for @screenRecipeProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Profile Details'**
  String get screenRecipeProfileDetails;

  /// No description provided for @screenRecipeRatio.
  ///
  /// In en, this message translates to:
  /// **'Ratio:'**
  String get screenRecipeRatio;

  /// No description provided for @screenRecipeRecipeDetails.
  ///
  /// In en, this message translates to:
  /// **'Recipe Details'**
  String get screenRecipeRecipeDetails;

  /// No description provided for @screenRecipeSelectedBean.
  ///
  /// In en, this message translates to:
  /// **'Selected Bean'**
  String get screenRecipeSelectedBean;

  /// No description provided for @screenRecipeSelectedProfile.
  ///
  /// In en, this message translates to:
  /// **'Selected profile'**
  String get screenRecipeSelectedProfile;

  /// No description provided for @screenRecipeSetRatio.
  ///
  /// In en, this message translates to:
  /// **'Set Ratio'**
  String get screenRecipeSetRatio;

  /// No description provided for @screenRecipesteamMilk.
  ///
  /// In en, this message translates to:
  /// **'Steam milk:'**
  String get screenRecipesteamMilk;

  /// No description provided for @screenRecipeStopOnWeight.
  ///
  /// In en, this message translates to:
  /// **'Stop on weight: '**
  String get screenRecipeStopOnWeight;

  /// No description provided for @screenRecipeStopOnWeightG.
  ///
  /// In en, this message translates to:
  /// **'Stop on Weight [g]'**
  String get screenRecipeStopOnWeightG;

  /// No description provided for @screenRecipeWeightinBeansG.
  ///
  /// In en, this message translates to:
  /// **'Weight-in beans [g]'**
  String get screenRecipeWeightinBeansG;

  /// No description provided for @screenRoasterEditAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get screenRoasterEditAddress;

  /// No description provided for @screenRoasterEditDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get screenRoasterEditDescription;

  /// No description provided for @screenRoasterEditHomepage.
  ///
  /// In en, this message translates to:
  /// **'Homepage'**
  String get screenRoasterEditHomepage;

  /// No description provided for @screenRoasterEditNameOfRoaster.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get screenRoasterEditNameOfRoaster;

  /// No description provided for @screenRoasterEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Roaster'**
  String get screenRoasterEditTitle;

  /// No description provided for @screenSettingsApplicationSettings.
  ///
  /// In en, this message translates to:
  /// **'Application Settings'**
  String get screenSettingsApplicationSettings;

  /// No description provided for @screenSettingsApplicationSettingsHardwareAndConnections.
  ///
  /// In en, this message translates to:
  /// **'Hardware and connections'**
  String get screenSettingsApplicationSettingsHardwareAndConnections;

  /// No description provided for @screenSettingsApplicationSettingsScanForDevices.
  ///
  /// In en, this message translates to:
  /// **'Scan for Devices'**
  String get screenSettingsApplicationSettingsScanForDevices;

  /// No description provided for @screenSettingsApplicationSettingsScanStart.
  ///
  /// In en, this message translates to:
  /// **'Scan for DE1 and scales (Lunar, Skale2, Eureka, Decent)'**
  String get screenSettingsApplicationSettingsScanStart;

  /// No description provided for @screenSettingsArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get screenSettingsArabic;

  /// No description provided for @screenSettingsAutoTare.
  ///
  /// In en, this message translates to:
  /// **'Auto Tare'**
  String get screenSettingsAutoTare;

  /// No description provided for @screenSettingsBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get screenSettingsBackup;

  /// No description provided for @screenSettingsBackupAndMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Backup and maintenance'**
  String get screenSettingsBackupAndMaintenance;

  /// No description provided for @screenSettingsBackuprestore.
  ///
  /// In en, this message translates to:
  /// **'Backup/Restore'**
  String get screenSettingsBackuprestore;

  /// No description provided for @screenSettingsBackuprestoreDatabase.
  ///
  /// In en, this message translates to:
  /// **'Backup/Restore database'**
  String get screenSettingsBackuprestoreDatabase;

  /// No description provided for @screenSettingsBackupSettings.
  ///
  /// In en, this message translates to:
  /// **'Backup Settings'**
  String get screenSettingsBackupSettings;

  /// No description provided for @screenSettingsBahaviour.
  ///
  /// In en, this message translates to:
  /// **'Behaviour'**
  String get screenSettingsBahaviour;

  /// No description provided for @screenSettingsBehaviour.
  ///
  /// In en, this message translates to:
  /// **'Behaviour'**
  String get screenSettingsBehaviour;

  /// No description provided for @screenSettingsBrightnessSleepAndScreensaver.
  ///
  /// In en, this message translates to:
  /// **'Brightness, sleep and screensaver'**
  String get screenSettingsBrightnessSleepAndScreensaver;

  /// No description provided for @screenSettingsChangeHowTheAppIsChangingScreenBrightnessIfNot.
  ///
  /// In en, this message translates to:
  /// **'Change how the app is changing screen brightness if not in use, switch the de1 on and shut it off if not used after a while.'**
  String get screenSettingsChangeHowTheAppIsChangingScreenBrightnessIfNot;

  /// No description provided for @screenSettingsChangeHowTheAppIsHandlingTheDe1InCase.
  ///
  /// In en, this message translates to:
  /// **'Change how the app is handling the de1 in case of wake up and sleep.'**
  String get screenSettingsChangeHowTheAppIsHandlingTheDe1InCase;

  /// No description provided for @screenSettingsCheckYourRouterForIpAdressOfYourTabletOpen.
  ///
  /// In en, this message translates to:
  /// **'Check your router for IP adress of your tablet. Open browser under'**
  String get screenSettingsCheckYourRouterForIpAdressOfYourTabletOpen;

  /// No description provided for @screenSettingsCloudAndNetwork.
  ///
  /// In en, this message translates to:
  /// **'Cloud and Network'**
  String get screenSettingsCloudAndNetwork;

  /// No description provided for @screenSettingsCloudShotUpload.
  ///
  /// In en, this message translates to:
  /// **'Cloud shot upload'**
  String get screenSettingsCloudShotUpload;

  /// No description provided for @screenSettingsCoffeePouring.
  ///
  /// In en, this message translates to:
  /// **'Coffee pouring'**
  String get screenSettingsCoffeePouring;

  /// No description provided for @screenSettingsCoffeeSection.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get screenSettingsCoffeeSection;

  /// No description provided for @screenSettingsDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get screenSettingsDarkTheme;

  /// No description provided for @screenSettingsDeleteAllScreensaverFiles.
  ///
  /// In en, this message translates to:
  /// **'Delete all screensaver files'**
  String get screenSettingsDeleteAllScreensaverFiles;

  /// No description provided for @screenSettingsDoNotLetTabletGoToLockScreen0doNot.
  ///
  /// In en, this message translates to:
  /// **'Do not let tablet go to lock screen (0=do not lock screen, 240=keep always locked) [min]'**
  String get screenSettingsDoNotLetTabletGoToLockScreen0doNot;

  /// No description provided for @screenSettingsEnableMiniWebsiteWithPort8888.
  ///
  /// In en, this message translates to:
  /// **'Enable Mini Website with port 8888'**
  String get screenSettingsEnableMiniWebsiteWithPort8888;

  /// No description provided for @screenSettingsEnableMqtt.
  ///
  /// In en, this message translates to:
  /// **'Enable MQTT'**
  String get screenSettingsEnableMqtt;

  /// No description provided for @screenSettingsEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get screenSettingsEnglish;

  /// No description provided for @screenSettingsExitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit app'**
  String get screenSettingsExitApp;

  /// No description provided for @screenSettingsFailedRestoringBackup.
  ///
  /// In en, this message translates to:
  /// **'Failed restoring backup'**
  String get screenSettingsFailedRestoringBackup;

  /// No description provided for @screenSettingsFeedbackAndCrashReporting.
  ///
  /// In en, this message translates to:
  /// **'Feedback and Crash reporting'**
  String get screenSettingsFeedbackAndCrashReporting;

  /// No description provided for @screenSettingsFlushTimerS.
  ///
  /// In en, this message translates to:
  /// **'Flush timer [s]'**
  String get screenSettingsFlushTimerS;

  /// No description provided for @screenSettingsGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get screenSettingsGerman;

  /// No description provided for @screenSettingsGoBackToRecipeScreenIfTimeoutOccured.
  ///
  /// In en, this message translates to:
  /// **'Go back to Recipe screen if timeout occured'**
  String get screenSettingsGoBackToRecipeScreenIfTimeoutOccured;

  /// No description provided for @screenSettingsGraphDataDuringHeatingAndPreinfusionAreSavedIntoShot.
  ///
  /// In en, this message translates to:
  /// **'Graph data during heating and preinfusion are saved into shot history.'**
  String get screenSettingsGraphDataDuringHeatingAndPreinfusionAreSavedIntoShot;

  /// No description provided for @screenSettingsHandlingOfConnectionsToOtherExternalSystemsLikeMqttAnd.
  ///
  /// In en, this message translates to:
  /// **'Handling of connections to other external systems like MQTT and Visualizer.'**
  String
      get screenSettingsHandlingOfConnectionsToOtherExternalSystemsLikeMqttAnd;

  /// No description provided for @screenSettingsIfAShotIsStartingAutotareTheScale.
  ///
  /// In en, this message translates to:
  /// **'If a shot is starting, auto-tare the scale'**
  String get screenSettingsIfAShotIsStartingAutotareTheScale;

  /// No description provided for @screenSettingsifSwitchedOffYouDoNotSeeHeatingAndPreinfusion.
  ///
  /// In en, this message translates to:
  /// **'If switched off you do not see heating and preinfusion in shot graph.'**
  String get screenSettingsifSwitchedOffYouDoNotSeeHeatingAndPreinfusion;

  /// No description provided for @screenSettingsIfTheScaleIsConnectedItIsUsedToStop.
  ///
  /// In en, this message translates to:
  /// **'If the scale is connected it is used to stop the shot if the profile has a limit given.'**
  String get screenSettingsIfTheScaleIsConnectedItIsUsedToStop;

  /// No description provided for @screenSettingsIfYouHaveNoGhcInstalledYouWouldNeedThe.
  ///
  /// In en, this message translates to:
  /// **'If you have no GHC installed, you would need the flush screen'**
  String get screenSettingsIfYouHaveNoGhcInstalledYouWouldNeedThe;

  /// No description provided for @screenSettingsKeepTabletChargedBetween6090.
  ///
  /// In en, this message translates to:
  /// **'Keep Tablet charged between 60-90%'**
  String get screenSettingsKeepTabletChargedBetween6090;

  /// No description provided for @screenSettingsKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get screenSettingsKorean;

  /// No description provided for @screenSettingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get screenSettingsLanguage;

  /// No description provided for @screenSettingsLightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get screenSettingsLightTheme;

  /// No description provided for @screenSettingsLoadScreensaverFiles.
  ///
  /// In en, this message translates to:
  /// **'Load Screensaver files'**
  String get screenSettingsLoadScreensaverFiles;

  /// No description provided for @screenSettingsMessageQueueBroadcastMqttClient.
  ///
  /// In en, this message translates to:
  /// **'Message Queue Broadcast (MQTT) client'**
  String get screenSettingsMessageQueueBroadcastMqttClient;

  /// No description provided for @screenSettingsMilkSteamingThermometerSupport.
  ///
  /// In en, this message translates to:
  /// **'Milk steaming thermometer support'**
  String get screenSettingsMilkSteamingThermometerSupport;

  /// No description provided for @screenSettingsMiniWebsite.
  ///
  /// In en, this message translates to:
  /// **'Mini Website'**
  String get screenSettingsMiniWebsite;

  /// No description provided for @screenSettingsMqttPassword.
  ///
  /// In en, this message translates to:
  /// **'MQTT Password'**
  String get screenSettingsMqttPassword;

  /// No description provided for @screenSettingsMqttPort.
  ///
  /// In en, this message translates to:
  /// **'MQTT Port'**
  String get screenSettingsMqttPort;

  /// No description provided for @screenSettingsMqttRootTopic.
  ///
  /// In en, this message translates to:
  /// **'MQTT root topic'**
  String get screenSettingsMqttRootTopic;

  /// No description provided for @screenSettingsMqttServer.
  ///
  /// In en, this message translates to:
  /// **'MQTT Server'**
  String get screenSettingsMqttServer;

  /// No description provided for @screenSettingsMqttUser.
  ///
  /// In en, this message translates to:
  /// **'MQTT User'**
  String get screenSettingsMqttUser;

  /// No description provided for @screenSettingsPassword.
  ///
  /// In en, this message translates to:
  /// **'password'**
  String get screenSettingsPassword;

  /// No description provided for @screenSettingsPasswordCantBeSmallerThan7Letters.
  ///
  /// In en, this message translates to:
  /// **'Password can\'t be smaller than 7 letters'**
  String get screenSettingsPasswordCantBeSmallerThan7Letters;

  /// No description provided for @screenSettingsPowermode.
  ///
  /// In en, this message translates to:
  /// **'Powermode'**
  String get screenSettingsPowermode;

  /// No description provided for @screenSettingsPrivacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get screenSettingsPrivacySettings;

  /// No description provided for @screenSettingsReduceBrightnessToLevel.
  ///
  /// In en, this message translates to:
  /// **'Reduce brightness to level'**
  String get screenSettingsReduceBrightnessToLevel;

  /// No description provided for @screenSettingsReduceScreenBrightnessAfter0offMin.
  ///
  /// In en, this message translates to:
  /// **'Reduce screen brightness after (0=off) [min]'**
  String get screenSettingsReduceScreenBrightnessAfter0offMin;

  /// No description provided for @screenSettingsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get screenSettingsRestore;

  /// No description provided for @screenSettingsRestoredBackup.
  ///
  /// In en, this message translates to:
  /// **'Restored backup'**
  String get screenSettingsRestoredBackup;

  /// No description provided for @screenSettingsSavedBackup.
  ///
  /// In en, this message translates to:
  /// **'Saved backup'**
  String get screenSettingsSavedBackup;

  /// No description provided for @screenSettingsSaveShotGraphDataEvenForPrePouringStates.
  ///
  /// In en, this message translates to:
  /// **'Include heating phase in saved shot graph data'**
  String get screenSettingsSaveShotGraphDataEvenForPrePouringStates;

  /// No description provided for @screenSettingsScalesFound.
  ///
  /// In en, this message translates to:
  /// **'Scales'**
  String get screenSettingsScalesFound;

  /// No description provided for @screenSettingsScaleSupport.
  ///
  /// In en, this message translates to:
  /// **'Scale support'**
  String get screenSettingsScaleSupport;

  /// No description provided for @screenSettingsScreenAndBrightness.
  ///
  /// In en, this message translates to:
  /// **'Screen and Brightness'**
  String get screenSettingsScreenAndBrightness;

  /// No description provided for @screenSettingsSecondFlushTimerS.
  ///
  /// In en, this message translates to:
  /// **'Second Flush timer [s]'**
  String get screenSettingsSecondFlushTimerS;

  /// No description provided for @screenSettingsSelectFiles.
  ///
  /// In en, this message translates to:
  /// **'Select files'**
  String get screenSettingsSelectFiles;

  /// No description provided for @screenSettingsSendDe1ShotUpdates.
  ///
  /// In en, this message translates to:
  /// **'Send de1 shot updates'**
  String get screenSettingsSendDe1ShotUpdates;

  /// No description provided for @screenSettingsSendDe1StateUpdates.
  ///
  /// In en, this message translates to:
  /// **'Send de1 state updates'**
  String get screenSettingsSendDe1StateUpdates;

  /// No description provided for @screenSettingsSendDe1WaterLevelUpdates.
  ///
  /// In en, this message translates to:
  /// **'Send de1 water level updates'**
  String get screenSettingsSendDe1WaterLevelUpdates;

  /// No description provided for @screenSettingsSendInformationsToSentryioIfTheAppCrashesOrYou.
  ///
  /// In en, this message translates to:
  /// **'Send informations to sentry.io if the app crashes or you use the feedback option. Check https://sentry.io/privacy/ for detailed data privacy description.'**
  String get screenSettingsSendInformationsToSentryioIfTheAppCrashesOrYou;

  /// No description provided for @screenSettingsSendingTheStatusOfTheDe1.
  ///
  /// In en, this message translates to:
  /// **'Sending the status of the de1'**
  String get screenSettingsSendingTheStatusOfTheDe1;

  /// No description provided for @screenSettingsSendTabletBatteryLevelUpdates.
  ///
  /// In en, this message translates to:
  /// **'Send tablet battery level updates'**
  String get screenSettingsSendTabletBatteryLevelUpdates;

  /// No description provided for @screenSettingsSettingsAreRestoredPleaseCloseAppAndRestart.
  ///
  /// In en, this message translates to:
  /// **'Settings are restored. Please close app and restart.'**
  String get screenSettingsSettingsAreRestoredPleaseCloseAppAndRestart;

  /// No description provided for @screenSettingsShotSettings.
  ///
  /// In en, this message translates to:
  /// **'Shot Settings'**
  String get screenSettingsShotSettings;

  /// No description provided for @screenSettingsShowClockDuringScreensaver.
  ///
  /// In en, this message translates to:
  /// **'Show clock during screensaver'**
  String get screenSettingsShowClockDuringScreensaver;

  /// No description provided for @screenSettingsShowFlush.
  ///
  /// In en, this message translates to:
  /// **'Show Flush'**
  String get screenSettingsShowFlush;

  /// No description provided for @screenSettingsSmartCharging.
  ///
  /// In en, this message translates to:
  /// **'Smart charging'**
  String get screenSettingsSmartCharging;

  /// No description provided for @screenSettingsSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get screenSettingsSpanish;

  /// No description provided for @screenSettingsSpecialBluetoothDevices.
  ///
  /// In en, this message translates to:
  /// **'Special Bluetooth devices'**
  String get screenSettingsSpecialBluetoothDevices;

  /// No description provided for @screenSettingsStopBeforeWeightWasReachedS.
  ///
  /// In en, this message translates to:
  /// **'Stop before weight was reached [s]'**
  String get screenSettingsStopBeforeWeightWasReachedS;

  /// No description provided for @screenSettingsStopOnWeightIfScaleDetected.
  ///
  /// In en, this message translates to:
  /// **'Stop on Weight if scale detected'**
  String get screenSettingsStopOnWeightIfScaleDetected;

  /// No description provided for @screenSettingsSwitchDe1ToSleepModeIfItIsIdleFor.
  ///
  /// In en, this message translates to:
  /// **'Switch de1 to sleep mode if it is idle for some time [min]'**
  String get screenSettingsSwitchDe1ToSleepModeIfItIsIdleFor;

  /// No description provided for @screenSettingsSwitchOffSteamHeating.
  ///
  /// In en, this message translates to:
  /// **'Switch off steam heating'**
  String get screenSettingsSwitchOffSteamHeating;

  /// No description provided for @screenSettingsSwitchOnScreensaverIfDe1ManuallySwitchedToSleep.
  ///
  /// In en, this message translates to:
  /// **'Switch on screensaver if de1 manually switched to sleep'**
  String get screenSettingsSwitchOnScreensaverIfDe1ManuallySwitchedToSleep;

  /// No description provided for @screenSettingsTabletDefault.
  ///
  /// In en, this message translates to:
  /// **'Tablet default'**
  String get screenSettingsTabletDefault;

  /// No description provided for @screenSettingsTabletGroup.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get screenSettingsTabletGroup;

  /// No description provided for @screenSettingsTare.
  ///
  /// In en, this message translates to:
  /// **'Tare'**
  String get screenSettingsTare;

  /// No description provided for @screenSettingsTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing'**
  String get screenSettingsTesting;

  /// No description provided for @screenSettingsTestingScales.
  ///
  /// In en, this message translates to:
  /// **'Testing features of scales'**
  String get screenSettingsTestingScales;

  /// No description provided for @screenSettingsThemeSelection.
  ///
  /// In en, this message translates to:
  /// **'Language and Theme selection'**
  String get screenSettingsThemeSelection;

  /// No description provided for @screenSettingsThisCanLeadToAHigherLoadOnYourMqtt.
  ///
  /// In en, this message translates to:
  /// **'This can lead to a higher load on your MQTT server as the message frequency is about 10Hz.'**
  String get screenSettingsThisCanLeadToAHigherLoadOnYourMqtt;

  /// No description provided for @screenSettingsToSaveEnergyTheSteamHeaterWillBeTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'To save energy the steam heater will be turned off and the steam tab will be hidden.'**
  String get screenSettingsToSaveEnergyTheSteamHeaterWillBeTurnedOff;

  /// No description provided for @screenSettingsUploadShotsToVisualizer.
  ///
  /// In en, this message translates to:
  /// **'Upload Shots to Visualizer'**
  String get screenSettingsUploadShotsToVisualizer;

  /// No description provided for @screenSettingsUserNameCantBeSmallerThan4Letters.
  ///
  /// In en, this message translates to:
  /// **'User Name can\'t be smaller than 4 letters'**
  String get screenSettingsUserNameCantBeSmallerThan4Letters;

  /// No description provided for @screenSettingsUserNameemail.
  ///
  /// In en, this message translates to:
  /// **'User Name/email'**
  String get screenSettingsUserNameemail;

  /// No description provided for @screenSettingsWakeUpDe1IfAppIsLaunched.
  ///
  /// In en, this message translates to:
  /// **'Wake up de1 if app is launched'**
  String get screenSettingsWakeUpDe1IfAppIsLaunched;

  /// No description provided for @screenSettingsWakeUpDe1IfScreenTappedIfScreenWasOff.
  ///
  /// In en, this message translates to:
  /// **'Wake up de1 if screen tapped (if screen was off)'**
  String get screenSettingsWakeUpDe1IfScreenTappedIfScreenWasOff;

  /// No description provided for @screenSettingsWeightedContainer.
  ///
  /// In en, this message translates to:
  /// **'Weighted container'**
  String get screenSettingsWeightedContainer;

  /// No description provided for @screenSettingsWeightOfOneContainers.
  ///
  /// In en, this message translates to:
  /// **'Weight of containers'**
  String get screenSettingsWeightOfOneContainers;

  /// No description provided for @screenSettingsYouChangedCriticalSettingsYouNeedToRestartTheApp.
  ///
  /// In en, this message translates to:
  /// **'You changed critical settings. You need to restart the app to make the settings active.'**
  String get screenSettingsYouChangedCriticalSettingsYouNeedToRestartTheApp;

  /// No description provided for @screenShotEditBarrista.
  ///
  /// In en, this message translates to:
  /// **'Barrista'**
  String get screenShotEditBarrista;

  /// No description provided for @screenShotEditDescribeYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Describe your experience'**
  String get screenShotEditDescribeYourExperience;

  /// No description provided for @screenShotEditDoseWeightG.
  ///
  /// In en, this message translates to:
  /// **'Dose weight [g]'**
  String get screenShotEditDoseWeightG;

  /// No description provided for @screenShotEditDrinker.
  ///
  /// In en, this message translates to:
  /// **'Drinker'**
  String get screenShotEditDrinker;

  /// No description provided for @screenShotEditDrinkWeightG.
  ///
  /// In en, this message translates to:
  /// **'Drink weight [g]'**
  String get screenShotEditDrinkWeightG;

  /// No description provided for @screenShotEditEnjoyment.
  ///
  /// In en, this message translates to:
  /// **'Enjoyment'**
  String get screenShotEditEnjoyment;

  /// No description provided for @screenShotEditExtractionYield.
  ///
  /// In en, this message translates to:
  /// **'Extraction yield'**
  String get screenShotEditExtractionYield;

  /// No description provided for @screenShotEditGrinder.
  ///
  /// In en, this message translates to:
  /// **'Grinder'**
  String get screenShotEditGrinder;

  /// No description provided for @screenShotEditGrinderSettings.
  ///
  /// In en, this message translates to:
  /// **'Grinder settings'**
  String get screenShotEditGrinderSettings;

  /// No description provided for @screenShotEditOpenInVisualizercoffee.
  ///
  /// In en, this message translates to:
  /// **'Open in Visualizer.coffee'**
  String get screenShotEditOpenInVisualizercoffee;

  /// No description provided for @screenShotEditPouringTimeS.
  ///
  /// In en, this message translates to:
  /// **'Pouring time [s]'**
  String get screenShotEditPouringTimeS;

  /// No description provided for @screenShotEditPouringWeightG.
  ///
  /// In en, this message translates to:
  /// **'Pouring weight [g]'**
  String get screenShotEditPouringWeightG;

  /// No description provided for @screenShotEditSuccessUploadingYourShot.
  ///
  /// In en, this message translates to:
  /// **'Success uploading your shot'**
  String get screenShotEditSuccessUploadingYourShot;

  /// No description provided for @screenShotEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Describe your experience with shot from {desc}'**
  String screenShotEditTitle(Object desc);

  /// No description provided for @screenShotEditTotalDissolvedSolidssTds.
  ///
  /// In en, this message translates to:
  /// **'Total Dissolved Solidss (TDS)'**
  String get screenShotEditTotalDissolvedSolidssTds;

  /// No description provided for @screenShowGraphDataBeforePouringPhaseStarts.
  ///
  /// In en, this message translates to:
  /// **'Show graph data before pouring phase starts.'**
  String get screenShowGraphDataBeforePouringPhaseStarts;

  /// No description provided for @screenSteamAmbient.
  ///
  /// In en, this message translates to:
  /// **'Ambient'**
  String get screenSteamAmbient;

  /// No description provided for @screenSteamFlowrate.
  ///
  /// In en, this message translates to:
  /// **'Steam Flowrate {flow} ml/s'**
  String screenSteamFlowrate(Object flow);

  /// No description provided for @screenSteamOffNormalPurgeAfterStop.
  ///
  /// In en, this message translates to:
  /// **'Off (normal purge after stop)'**
  String get screenSteamOffNormalPurgeAfterStop;

  /// No description provided for @screenSteamOnSlowPurgeOn1stStop.
  ///
  /// In en, this message translates to:
  /// **'On (slow purge on 1st stop)'**
  String get screenSteamOnSlowPurgeOn1stStop;

  /// No description provided for @screenSteamReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get screenSteamReset;

  /// No description provided for @screenSteamStopAtTemperatur.
  ///
  /// In en, this message translates to:
  /// **'Stop at Temperature {temp} °C'**
  String screenSteamStopAtTemperatur(Object temp);

  /// No description provided for @screenSteamTemperaturs.
  ///
  /// In en, this message translates to:
  /// **'Steam Temperature {temp} °C'**
  String screenSteamTemperaturs(Object temp);

  /// No description provided for @screenSteamTempTip.
  ///
  /// In en, this message translates to:
  /// **'Temp Tip'**
  String get screenSteamTempTip;

  /// No description provided for @screenSteamTimerS.
  ///
  /// In en, this message translates to:
  /// **'Timer {t} s'**
  String screenSteamTimerS(Object t);

  /// No description provided for @screenSteamTimeS.
  ///
  /// In en, this message translates to:
  /// **'Time/s'**
  String get screenSteamTimeS;

  /// No description provided for @screenSteamTwotapMode.
  ///
  /// In en, this message translates to:
  /// **'Steam two-tap mode:'**
  String get screenSteamTwotapMode;

  /// No description provided for @screenWaterTemp.
  ///
  /// In en, this message translates to:
  /// **'Water Temperature'**
  String get screenWaterTemp;

  /// No description provided for @screenWaterTemperatureWatertemp.
  ///
  /// In en, this message translates to:
  /// **'Water Temperature {watertemp} °C'**
  String screenWaterTemperatureWatertemp(Object watertemp);

  /// No description provided for @screenWaterWeightG.
  ///
  /// In en, this message translates to:
  /// **'Weight {w} g'**
  String screenWaterWeightG(Object w);

  /// No description provided for @screenWaterWeightVolume.
  ///
  /// In en, this message translates to:
  /// **'Water Weight/Volume {volume} g or ml'**
  String screenWaterWeightVolume(Object volume, Object volumen);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsAutostartTimerOnScaleDuringPuring.
  ///
  /// In en, this message translates to:
  /// **'Autostart timer on scale during puring'**
  String get settingsAutostartTimerOnScaleDuringPuring;

  /// No description provided for @settingsContainerAutotare.
  ///
  /// In en, this message translates to:
  /// **'Tare if weight was detected'**
  String get settingsContainerAutotare;

  /// No description provided for @settingsContainerCurrentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current Weight'**
  String get settingsContainerCurrentWeight;

  /// No description provided for @settingsMoveonatweightThresholdS.
  ///
  /// In en, this message translates to:
  /// **'Move-on-at-weight threshold [s]'**
  String get settingsMoveonatweightThresholdS;

  /// No description provided for @settingsNextStepWillBeTriggeredAtThisDurationFromReaching.
  ///
  /// In en, this message translates to:
  /// **'Next step will be triggered at this duration from reaching target weight'**
  String get settingsNextStepWillBeTriggeredAtThisDurationFromReaching;

  /// No description provided for @settingsRefillWatertankAtLimit.
  ///
  /// In en, this message translates to:
  /// **'Refill watertank at limit'**
  String get settingsRefillWatertankAtLimit;

  /// No description provided for @settingsSleepAllowTabletSleepDuringScreensaver.
  ///
  /// In en, this message translates to:
  /// **'Allow tablet sleep during screensaver'**
  String get settingsSleepAllowTabletSleepDuringScreensaver;

  /// No description provided for @settingsSleepAllowTabletSleepWhenMachineIsSleepingOrDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Allow tablet sleep when machine is sleeping or disconnected'**
  String get settingsSleepAllowTabletSleepWhenMachineIsSleepingOrDisconnected;

  /// No description provided for @settingsSleepMinutesToSpendInScreensaverBeforeAllowingSleep.
  ///
  /// In en, this message translates to:
  /// **'Minutes to spend in screensaver before allowing sleep'**
  String get settingsSleepMinutesToSpendInScreensaverBeforeAllowingSleep;

  /// No description provided for @settingsSleepWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: depending on your tablet and operating system settings, letting your tablet go to sleep might cause interruptions to the Bluetooth connection to your machine or accessories.'**
  String get settingsSleepWarning;

  /// No description provided for @settingsSleepWhenMachineIsInSleepSwitchOffScaleDisplayIf.
  ///
  /// In en, this message translates to:
  /// **'When machine is in sleep, switch off scale display if possible'**
  String get settingsSleepWhenMachineIsInSleepSwitchOffScaleDisplayIf;

  /// No description provided for @settingsTabletSleep.
  ///
  /// In en, this message translates to:
  /// **'Tablet sleep'**
  String get settingsTabletSleep;

  /// No description provided for @settingsTareifTheScaleIsAlreadyConnectedTareIsCalledIf.
  ///
  /// In en, this message translates to:
  /// **'If the scale is already connected, tare is called if machine woke up from sleep.'**
  String get settingsTareifTheScaleIsAlreadyConnectedTareIsCalledIf;

  /// No description provided for @settingsTareOnWakeupOfDe1.
  ///
  /// In en, this message translates to:
  /// **'Tare on wakeup of de1'**
  String get settingsTareOnWakeupOfDe1;

  /// No description provided for @settingsWeightcontainer1IeWeightCup.
  ///
  /// In en, this message translates to:
  /// **'Container 1 (i.E. weight cup):'**
  String get settingsWeightcontainer1IeWeightCup;

  /// No description provided for @settingsWeightcontainer2IeEspressoCup.
  ///
  /// In en, this message translates to:
  /// **'Container 2 (i.E. Espresso Cup):'**
  String get settingsWeightcontainer2IeEspressoCup;

  /// No description provided for @settingsWeightcontainer3IeSteamMug.
  ///
  /// In en, this message translates to:
  /// **'Container 3 (i.E. Steam Mug):'**
  String get settingsWeightcontainer3IeSteamMug;

  /// No description provided for @settingsWeightcontainer4IeSteamMug.
  ///
  /// In en, this message translates to:
  /// **'Container 4 (i.E. Steam Mug):'**
  String get settingsWeightcontainer4IeSteamMug;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stateDisconnected.
  ///
  /// In en, this message translates to:
  /// **'disconnected'**
  String get stateDisconnected;

  /// No description provided for @state_Disconnected.
  ///
  /// In en, this message translates to:
  /// **'disconnected'**
  String get state_Disconnected;

  /// No description provided for @stateIdleHeated.
  ///
  /// In en, this message translates to:
  /// **'heated up'**
  String get stateIdleHeated;

  /// No description provided for @statePour.
  ///
  /// In en, this message translates to:
  /// **'pour'**
  String get statePour;

  /// No description provided for @steamScreenTempC.
  ///
  /// In en, this message translates to:
  /// **'Temp [°C]'**
  String get steamScreenTempC;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @subStateHeatWaterHeater.
  ///
  /// In en, this message translates to:
  /// **'Heating Water'**
  String get subStateHeatWaterHeater;

  /// No description provided for @subStateHeatWaterTank.
  ///
  /// In en, this message translates to:
  /// **'Heating Tank'**
  String get subStateHeatWaterTank;

  /// No description provided for @switchOn.
  ///
  /// In en, this message translates to:
  /// **'Switch on'**
  String get switchOn;

  /// No description provided for @tabHomeEspresso.
  ///
  /// In en, this message translates to:
  /// **'Espresso'**
  String get tabHomeEspresso;

  /// No description provided for @tabHomeFlush.
  ///
  /// In en, this message translates to:
  /// **'Flush'**
  String get tabHomeFlush;

  /// No description provided for @tabHomeRecipe.
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get tabHomeRecipe;

  /// No description provided for @tabHomeSteam.
  ///
  /// In en, this message translates to:
  /// **'Steam'**
  String get tabHomeSteam;

  /// No description provided for @tabHomeWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get tabHomeWater;

  /// No description provided for @temp.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get temp;

  /// No description provided for @validatorNotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'must not be empty'**
  String get validatorNotBeEmpty;

  /// No description provided for @wait.
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get wait;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'de', 'en', 'es', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
