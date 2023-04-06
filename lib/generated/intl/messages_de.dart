// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a de locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'de';

  static String m0(sec) => "Bezug: ${sec} s";

  static String m1(sec) => "Total: ${sec} s";

  static String m2(sec) => "TTW: ${sec} s";

  static String m3(flow) => "Dampf Flussgeschwindigkeit ${flow} ml/s";

  static String m4(temp) => "Stop bei Temperatur ${temp} °C";

  static String m5(temp) => "Dampf Temperatur ${temp} °C";

  static String m6(t) => "Timer ${t} s";

  static String m7(w) => "Gewicht ${w} g";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "beans": MessageLookupByLibrary.simpleMessage("Bohnen"),
        "blue": MessageLookupByLibrary.simpleMessage("Blau"),
        "disabled": MessageLookupByLibrary.simpleMessage("Deaktiviert"),
        "disconnected": MessageLookupByLibrary.simpleMessage("disconnected"),
        "edit": MessageLookupByLibrary.simpleMessage("Ändern"),
        "enabled": MessageLookupByLibrary.simpleMessage("Aktiviert"),
        "error": MessageLookupByLibrary.simpleMessage("Fehler"),
        "exit": MessageLookupByLibrary.simpleMessage("Exit"),
        "flow": MessageLookupByLibrary.simpleMessage("Fluss"),
        "green": MessageLookupByLibrary.simpleMessage("Grün"),
        "hide": MessageLookupByLibrary.simpleMessage("Verstecken"),
        "mainMenuDespressoFeedback":
            MessageLookupByLibrary.simpleMessage("Despresso Feedback"),
        "mainMenuEspressoDiary":
            MessageLookupByLibrary.simpleMessage("Espresso Logbuch"),
        "mainMenuFeedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "no": MessageLookupByLibrary.simpleMessage("Nein"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "orange": MessageLookupByLibrary.simpleMessage("Orange"),
        "pressure": MessageLookupByLibrary.simpleMessage("Druck"),
        "privacy": MessageLookupByLibrary.simpleMessage("Privatsphäre/DSGVO"),
        "profiles": MessageLookupByLibrary.simpleMessage("Profile"),
        "reconnect": MessageLookupByLibrary.simpleMessage("Verbinden"),
        "red": MessageLookupByLibrary.simpleMessage("Rot"),
        "screenBeanSelectAcidity":
            MessageLookupByLibrary.simpleMessage("Säure"),
        "screenBeanSelectAddressOfRoaster":
            MessageLookupByLibrary.simpleMessage("Addresse"),
        "screenBeanSelectDaysAgo":
            MessageLookupByLibrary.simpleMessage("Tage her"),
        "screenBeanSelectDescriptionOfBean":
            MessageLookupByLibrary.simpleMessage("Beschreibung"),
        "screenBeanSelectDescriptionOfRoaster":
            MessageLookupByLibrary.simpleMessage("Beschreibung"),
        "screenBeanSelectHomepageOfRoaster":
            MessageLookupByLibrary.simpleMessage("Homepage"),
        "screenBeanSelectIntensity":
            MessageLookupByLibrary.simpleMessage("Intensität"),
        "screenBeanSelectNameOfBean":
            MessageLookupByLibrary.simpleMessage("Name"),
        "screenBeanSelectNameOfRoaster":
            MessageLookupByLibrary.simpleMessage("Name"),
        "screenBeanSelectRoastLevel":
            MessageLookupByLibrary.simpleMessage("Röstgrad"),
        "screenBeanSelectRoastingDate":
            MessageLookupByLibrary.simpleMessage("Röst-Datum"),
        "screenBeanSelectSelectBeans":
            MessageLookupByLibrary.simpleMessage("Wähle Bohne"),
        "screenBeanSelectSelectRoaster":
            MessageLookupByLibrary.simpleMessage("Wähle Röster"),
        "screenBeanSelectTasting":
            MessageLookupByLibrary.simpleMessage("Aromen"),
        "screenBeanSelectTitle":
            MessageLookupByLibrary.simpleMessage("Bohnen and Röster"),
        "screenBeanSelectTypeOfBeans":
            MessageLookupByLibrary.simpleMessage("Typ der Bohne"),
        "screenDiaryErrorUploadingShots":
            MessageLookupByLibrary.simpleMessage("Fehler beim Hochladen "),
        "screenDiaryNoShotsToUploadSelected":
            MessageLookupByLibrary.simpleMessage(
                "Keine Shots zum hochladen ausgewählt"),
        "screenDiaryNothingSelected":
            MessageLookupByLibrary.simpleMessage("Kein Shot ausgewählt"),
        "screenDiaryOverlaymode":
            MessageLookupByLibrary.simpleMessage("Overlaymodus:"),
        "screenDiarySuccessUploadingYourShots":
            MessageLookupByLibrary.simpleMessage("Hochladen war erfolgreich"),
        "screenEspressoBean": MessageLookupByLibrary.simpleMessage("Bohnen"),
        "screenEspressoDiary":
            MessageLookupByLibrary.simpleMessage("Logbucheintrag"),
        "screenEspressoFlow": MessageLookupByLibrary.simpleMessage("Fluss"),
        "screenEspressoFlowMlsPressureBar":
            MessageLookupByLibrary.simpleMessage("Fluss [ml/s] / Druck [bar]"),
        "screenEspressoPour": m0,
        "screenEspressoPressure":
            MessageLookupByLibrary.simpleMessage("Pressure"),
        "screenEspressoProfile": MessageLookupByLibrary.simpleMessage("Profil"),
        "screenEspressoRecipe": MessageLookupByLibrary.simpleMessage("Rezept"),
        "screenEspressoRefillTheWaterTank":
            MessageLookupByLibrary.simpleMessage("Bitte Wassertank füllen"),
        "screenEspressoTarget": MessageLookupByLibrary.simpleMessage("Ziel"),
        "screenEspressoTemp": MessageLookupByLibrary.simpleMessage("Temp"),
        "screenEspressoTimer": MessageLookupByLibrary.simpleMessage("Timer"),
        "screenEspressoTimes": MessageLookupByLibrary.simpleMessage("Zeit/s"),
        "screenEspressoTotal": m1,
        "screenEspressoTtw": m2,
        "screenEspressoWeight": MessageLookupByLibrary.simpleMessage("Gewicht"),
        "screenEspressoWeightG":
            MessageLookupByLibrary.simpleMessage("Gewicht [g]"),
        "screenRecipeAddRecipe":
            MessageLookupByLibrary.simpleMessage("Rezept hinzufügen"),
        "screenRecipeAdjustTempC":
            MessageLookupByLibrary.simpleMessage("Temp Anpassen [°C]"),
        "screenRecipeCoffeeNotes":
            MessageLookupByLibrary.simpleMessage("Bohnen Infos"),
        "screenRecipeGrindSettings":
            MessageLookupByLibrary.simpleMessage("Mühlen Einst.:"),
        "screenRecipeInitialTemp":
            MessageLookupByLibrary.simpleMessage("Anfangs Temperatur:"),
        "screenRecipeProfileDetails":
            MessageLookupByLibrary.simpleMessage("Profil Infos"),
        "screenRecipeRatio":
            MessageLookupByLibrary.simpleMessage("Verhältniss:"),
        "screenRecipeRecipeDetails":
            MessageLookupByLibrary.simpleMessage("Rezept Infos"),
        "screenRecipeSelectedBean":
            MessageLookupByLibrary.simpleMessage("Gewählte Bohnen"),
        "screenRecipeSelectedProfile":
            MessageLookupByLibrary.simpleMessage("Gewähltes Profil"),
        "screenRecipeSetRatio":
            MessageLookupByLibrary.simpleMessage("Verhältniss einstellen"),
        "screenRecipeStopOnWeightG":
            MessageLookupByLibrary.simpleMessage("Stop bei Gewicht [g]"),
        "screenRecipeWeightinBeansG":
            MessageLookupByLibrary.simpleMessage("Einwaage Bohnen [g]"),
        "screenRecipehotWater":
            MessageLookupByLibrary.simpleMessage("Heißwasser:"),
        "screenRecipesteamMilk":
            MessageLookupByLibrary.simpleMessage("Milch schäumen:"),
        "screenSettingsApplicationSettings":
            MessageLookupByLibrary.simpleMessage("Einstellungen"),
        "screenSettingsApplicationSettingsHardwareAndConnections":
            MessageLookupByLibrary.simpleMessage("Hardware and Verbindungen"),
        "screenSettingsApplicationSettingsScanForDevices":
            MessageLookupByLibrary.simpleMessage("Scanne nach Geräten"),
        "screenSettingsApplicationSettingsScanStart":
            MessageLookupByLibrary.simpleMessage(
                "Scanne nach DE1 und Waagen (Lunar, Skale2, Eureka, Decent)"),
        "screenSettingsAutoTare":
            MessageLookupByLibrary.simpleMessage("Auto Tara"),
        "screenSettingsBackup": MessageLookupByLibrary.simpleMessage("Backup"),
        "screenSettingsBackupAndMaintenance":
            MessageLookupByLibrary.simpleMessage("Backup und Wartung"),
        "screenSettingsBackupSettings":
            MessageLookupByLibrary.simpleMessage("Backup Einstellungen"),
        "screenSettingsBackuprestore":
            MessageLookupByLibrary.simpleMessage("Backup/Restore"),
        "screenSettingsBackuprestoreDatabase":
            MessageLookupByLibrary.simpleMessage("Backup/Restore Datenbank"),
        "screenSettingsBahaviour":
            MessageLookupByLibrary.simpleMessage("Verhalten"),
        "screenSettingsBehaviour":
            MessageLookupByLibrary.simpleMessage("Verhalten"),
        "screenSettingsBrightnessSleepAndScreensaver":
            MessageLookupByLibrary.simpleMessage(
                "Helligkeit, Ausschalten und Bildschirmschoner"),
        "screenSettingsChangeHowTheAppIsChangingScreenBrightnessIfNot":
            MessageLookupByLibrary.simpleMessage(
                "Einstellen wie die App die Bildhelligkeit regelt wenn nich benutzt. Wie wird die de1 in den Standby geschaltet."),
        "screenSettingsChangeHowTheAppIsHandlingTheDe1InCase":
            MessageLookupByLibrary.simpleMessage(
                "Ändern wie sich die App mit der de1 nach dem Standby und Start verhält."),
        "screenSettingsCheckYourRouterForIpAdressOfYourTabletOpen":
            MessageLookupByLibrary.simpleMessage(
                "Den Router für die IP Adresse des Tablets prüfen. Einen Browser öffnen unter "),
        "screenSettingsCloudAndNetwork":
            MessageLookupByLibrary.simpleMessage("Cloud und Netzwerk"),
        "screenSettingsCloudShotUpload":
            MessageLookupByLibrary.simpleMessage("Cloud Shot Upload"),
        "screenSettingsCoffeePouring":
            MessageLookupByLibrary.simpleMessage("Espresso Bezug"),
        "screenSettingsCoffeeSection":
            MessageLookupByLibrary.simpleMessage("Kaffee"),
        "screenSettingsDarkTheme":
            MessageLookupByLibrary.simpleMessage("Dunkles Theme"),
        "screenSettingsDeleteAllScreensaverFiles":
            MessageLookupByLibrary.simpleMessage(
                "Alle Bildschirmhintergründe entfernen"),
        "screenSettingsDoNotLetTabletGoToLockScreen0doNot":
            MessageLookupByLibrary.simpleMessage(
                "Tablet nicht in den Sperrbildschirm gehen lassen (0=Sperrbildschirm erlauben, 240=Niemals Sperrbildschirm) [min]"),
        "screenSettingsEnableMiniWebsiteWithPort8888":
            MessageLookupByLibrary.simpleMessage(
                "Mini Website aktivieren auf Port 8888"),
        "screenSettingsEnableMqtt":
            MessageLookupByLibrary.simpleMessage("Aktiviere MQTT"),
        "screenSettingsExitApp":
            MessageLookupByLibrary.simpleMessage("App Beenden"),
        "screenSettingsFailedRestoringBackup":
            MessageLookupByLibrary.simpleMessage(
                "Wiederherstellung ist fehlgeschlagen."),
        "screenSettingsFeedbackAndCrashReporting":
            MessageLookupByLibrary.simpleMessage("Feedback und Crash Berichte"),
        "screenSettingsFlushTimerS":
            MessageLookupByLibrary.simpleMessage("Spülen Timer [s]"),
        "screenSettingsGoBackToRecipeScreenIfTimeoutOccured":
            MessageLookupByLibrary.simpleMessage(
                "Nach einem Timeout automatisch zum Rezept Bildschirm zurückwechseln"),
        "screenSettingsHandlingOfConnectionsToOtherExternalSystemsLikeMqttAnd":
            MessageLookupByLibrary.simpleMessage(
                "Einstellungen für Verbindungen zu anderen Systemen wie MQTT und Visualizer."),
        "screenSettingsIfAShotIsStartingAutotareTheScale":
            MessageLookupByLibrary.simpleMessage(
                "Wenn ein Shot gestartet wird, wirt die Waage genullt."),
        "screenSettingsIfTheScaleIsConnectedItIsUsedToStop":
            MessageLookupByLibrary.simpleMessage(
                "Wenn eine Waage erkannt wurde und im Rezept ein Zielgewicht angegeben wurde, wird der Shot angehalten - falls das Zielgewicht erreicht wurde"),
        "screenSettingsIfYouHaveNoGhcInstalledYouWouldNeedThe":
            MessageLookupByLibrary.simpleMessage(
                "Wenn kein GHC installiert ist wird der \'Spülen\' Tab benötigt."),
        "screenSettingsKeepTabletChargedBetween6090":
            MessageLookupByLibrary.simpleMessage(
                "Das Tablet immer geladen halten zwischen 60-90% (de1 USB Port)"),
        "screenSettingsLightTheme":
            MessageLookupByLibrary.simpleMessage("Helles Theme"),
        "screenSettingsLoadScreensaverFiles":
            MessageLookupByLibrary.simpleMessage(
                "Bildschirmhintergründe laden"),
        "screenSettingsMessageQueueBroadcastMqttClient":
            MessageLookupByLibrary.simpleMessage(
                "Message Queue Broadcast (MQTT) Client"),
        "screenSettingsMilkSteamingThermometerSupport":
            MessageLookupByLibrary.simpleMessage(
                "Thermometer für Milch Aufschäumen"),
        "screenSettingsMiniWebsite":
            MessageLookupByLibrary.simpleMessage("Mini Website"),
        "screenSettingsMqttPassword":
            MessageLookupByLibrary.simpleMessage("MQTT Password"),
        "screenSettingsMqttPort":
            MessageLookupByLibrary.simpleMessage("MQTT Port"),
        "screenSettingsMqttRootTopic":
            MessageLookupByLibrary.simpleMessage("MQTT Root Topic"),
        "screenSettingsMqttServer":
            MessageLookupByLibrary.simpleMessage("MQTT Server"),
        "screenSettingsMqttUser":
            MessageLookupByLibrary.simpleMessage("MQTT User"),
        "screenSettingsPassword":
            MessageLookupByLibrary.simpleMessage("Passwort"),
        "screenSettingsPasswordCantBeSmallerThan7Letters":
            MessageLookupByLibrary.simpleMessage(
                "Passwort muss mindestens 7 Zeichen lang sein"),
        "screenSettingsPrivacySettings":
            MessageLookupByLibrary.simpleMessage("Privatsphäre und DSGVO"),
        "screenSettingsReduceBrightnessToLevel":
            MessageLookupByLibrary.simpleMessage("Helligkeit reduzieren"),
        "screenSettingsReduceScreenBrightnessAfter0offMin":
            MessageLookupByLibrary.simpleMessage(
                "Bildschirmhelligkeit reduzieren nach (0=aus) [min]"),
        "screenSettingsRestore":
            MessageLookupByLibrary.simpleMessage("Restore"),
        "screenSettingsRestoredBackup": MessageLookupByLibrary.simpleMessage(
            "Backup wurde wiederhergestellt"),
        "screenSettingsSavedBackup": MessageLookupByLibrary.simpleMessage(
            "Die Sicherung wurde angelegt"),
        "screenSettingsScaleSupport":
            MessageLookupByLibrary.simpleMessage("Waagen Unterstützung"),
        "screenSettingsScreenAndBrightness":
            MessageLookupByLibrary.simpleMessage("Bildschirm und Helligkeit"),
        "screenSettingsSecondFlushTimerS":
            MessageLookupByLibrary.simpleMessage("Zweiter Spülen Timer [s]"),
        "screenSettingsSelectFiles":
            MessageLookupByLibrary.simpleMessage("Dateiauswahl"),
        "screenSettingsSendDe1ShotUpdates":
            MessageLookupByLibrary.simpleMessage("Senden von de1 shot Updates"),
        "screenSettingsSendDe1StateUpdates":
            MessageLookupByLibrary.simpleMessage(
                "Senden von de1 Status Updates"),
        "screenSettingsSendDe1WaterLevelUpdates":
            MessageLookupByLibrary.simpleMessage(
                "Senden des de1 Wasser Levels"),
        "screenSettingsSendInformationsToSentryioIfTheAppCrashesOrYou":
            MessageLookupByLibrary.simpleMessage(
                "Sende Infos zu sentry.io im Falle das die App abstürzt oder die Feedback Funktion benutzt wird. Siehe https://sentry.io/privacy/ für eine genaue Beschreibung der geltenen Privatsphären Einstellungen von Sentry.io."),
        "screenSettingsSendTabletBatteryLevelUpdates":
            MessageLookupByLibrary.simpleMessage(
                "Senden von Tablet Batterie Updates"),
        "screenSettingsSendingTheStatusOfTheDe1":
            MessageLookupByLibrary.simpleMessage("Senden des Status der de1"),
        "screenSettingsSettingsAreRestoredPleaseCloseAppAndRestart":
            MessageLookupByLibrary.simpleMessage(
                "Einstellungen wurden wiederhergestellt. Bitte die App komplett beenden und neu Starten (Task Manager)."),
        "screenSettingsShotSettings":
            MessageLookupByLibrary.simpleMessage("Shot Einstellungen"),
        "screenSettingsShowFlush":
            MessageLookupByLibrary.simpleMessage("Spülen Anzeigen"),
        "screenSettingsSmartCharging":
            MessageLookupByLibrary.simpleMessage("Smart charging"),
        "screenSettingsSpecialBluetoothDevices":
            MessageLookupByLibrary.simpleMessage("Spezielle Bluetooth Geräte"),
        "screenSettingsStopBeforeWeightWasReachedS":
            MessageLookupByLibrary.simpleMessage(
                "Anhalten bevor das Zielgewicht erreicht wurde [s]"),
        "screenSettingsStopOnWeightIfScaleDetected":
            MessageLookupByLibrary.simpleMessage(
                "Bei erreichtem Gewicht stoppen wenn Waage verbunden ist"),
        "screenSettingsSwitchDe1ToSleepModeIfItIsIdleFor":
            MessageLookupByLibrary.simpleMessage(
                "Wenn im Idle Modus die de1 nach Zeit in den Standby schicken [min]"),
        "screenSettingsSwitchOffSteamHeating":
            MessageLookupByLibrary.simpleMessage("Dampfheizung ausschalten"),
        "screenSettingsSwitchOnScreensaverIfDe1ManuallySwitchedToSleep":
            MessageLookupByLibrary.simpleMessage(
                "Wenn die de1 per App in den Standby geschaltet wird, automatisch Bildschirmschoner aktivieren"),
        "screenSettingsTabletGroup":
            MessageLookupByLibrary.simpleMessage("Tablet"),
        "screenSettingsThemeSelection":
            MessageLookupByLibrary.simpleMessage("Theme Auswahl"),
        "screenSettingsThisCanLeadToAHigherLoadOnYourMqtt":
            MessageLookupByLibrary.simpleMessage(
                "Das könnte zu einer höheren Last im MQTT Server führen. Die Updatefrequenz ist etwa 10Hz."),
        "screenSettingsToSaveEnergyTheSteamHeaterWillBeTurnedOff":
            MessageLookupByLibrary.simpleMessage(
                "Um Energie zu sparen, kann der Dampferhitzer ausgeschaltet werden und das \'Dampf\' tab wird nicht angezeigt."),
        "screenSettingsUploadShotsToVisualizer":
            MessageLookupByLibrary.simpleMessage(
                "Upload Shots zu Visualizer.coffee"),
        "screenSettingsUserNameCantBeSmallerThan4Letters":
            MessageLookupByLibrary.simpleMessage(
                "User Name muss mindestens 4 Zeichen haben"),
        "screenSettingsUserNameemail":
            MessageLookupByLibrary.simpleMessage("User Name/email"),
        "screenSettingsWakeUpDe1IfAppIsLaunched":
            MessageLookupByLibrary.simpleMessage(
                "Wenn die App gestartet wird, de1 automatisch aufwecken"),
        "screenSettingsWakeUpDe1IfScreenTappedIfScreenWasOff":
            MessageLookupByLibrary.simpleMessage(
                "Wenn Bildschirmschoner deaktiviert wird, de1 aus dem Standby aufwecken"),
        "screenSettingsYouChangedCriticalSettingsYouNeedToRestartTheApp":
            MessageLookupByLibrary.simpleMessage(
                "Es wurden kritische Einstellungen geändert. Es wird ein Neustart der App benötigt."),
        "screenSteamAmbient": MessageLookupByLibrary.simpleMessage("Umgebung"),
        "screenSteamFlowrate": m3,
        "screenSteamOffNormalPurgeAfterStop":
            MessageLookupByLibrary.simpleMessage(
                "Aus (normaler purge nach Stop)"),
        "screenSteamOnSlowPurgeOn1stStop": MessageLookupByLibrary.simpleMessage(
            "An (langsamer purge nach erstem Stop)"),
        "screenSteamReset": MessageLookupByLibrary.simpleMessage("Reset"),
        "screenSteamStopAtTemperatur": m4,
        "screenSteamTempTip": MessageLookupByLibrary.simpleMessage("Temp Tip"),
        "screenSteamTemperaturs": m5,
        "screenSteamTimeS": MessageLookupByLibrary.simpleMessage("Zeit/s"),
        "screenSteamTimerS": m6,
        "screenSteamTwotapMode":
            MessageLookupByLibrary.simpleMessage("Dampf two-tap mode:"),
        "screenWaterWeightG": m7,
        "settings": MessageLookupByLibrary.simpleMessage("Einstellungen"),
        "show": MessageLookupByLibrary.simpleMessage("Anzeigen"),
        "start": MessageLookupByLibrary.simpleMessage("Start"),
        "stateDisconnected": MessageLookupByLibrary.simpleMessage("GETRENNT"),
        "stateIdleHeated": MessageLookupByLibrary.simpleMessage("aufgeheizt"),
        "statePour": MessageLookupByLibrary.simpleMessage("Bezug"),
        "steamScreenTempC": MessageLookupByLibrary.simpleMessage("Temp [°C]"),
        "stop": MessageLookupByLibrary.simpleMessage("Stop"),
        "subStateHeatWaterHeater":
            MessageLookupByLibrary.simpleMessage("Heize Wasser"),
        "subStateHeatWaterTank":
            MessageLookupByLibrary.simpleMessage("Heize Tank"),
        "switchOn": MessageLookupByLibrary.simpleMessage("Einschalten"),
        "tabHomeEspresso": MessageLookupByLibrary.simpleMessage("Espresso"),
        "tabHomeFlush": MessageLookupByLibrary.simpleMessage("Spülen"),
        "tabHomeRecipe": MessageLookupByLibrary.simpleMessage("Rezept"),
        "tabHomeSteam": MessageLookupByLibrary.simpleMessage("Dampf"),
        "tabHomeWater": MessageLookupByLibrary.simpleMessage("Wasser"),
        "temp": MessageLookupByLibrary.simpleMessage("Temp"),
        "wait": MessageLookupByLibrary.simpleMessage("Warten"),
        "weight": MessageLookupByLibrary.simpleMessage("Gewicht")
      };
}
