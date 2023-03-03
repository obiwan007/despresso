import 'dart:io';

import 'package:despresso/model/services/ble/ble_service.dart';
import 'package:despresso/model/services/state/mqtt_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/model/services/state/visualizer_service.dart';
import 'package:despresso/objectbox.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:logging/logging.dart';
import 'package:document_file_save_plus/document_file_save_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../../service_locator.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({Key? key}) : super(key: key);

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<AppSettingsScreen> {
  final log = Logger('SettingsScreenState');

  late SettingsService settingsService;
  late BLEService bleService;
  late MqttService mqttService;
  late VisualizerService visualizerService;

  String? ownIpAdress = "<IP-ADRESS-OF-TABLET>";

  @override
  initState() {
    super.initState();
    settingsService = getIt<SettingsService>();
    bleService = getIt<BLEService>();
    visualizerService = getIt<VisualizerService>();
    settingsService.addListener(settingsServiceListener);
    bleService.addListener(settingsServiceListener);
    getIpAdress();
  }

  Future<void> getIpAdress() async {
    ownIpAdress = await NetworkInfo().getWifiIP();
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    settingsService.notifyDelayed();
    settingsService.removeListener(settingsServiceListener);
    bleService.removeListener(settingsServiceListener);

    log.info('Disposed settingspage');
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      title: 'Application Settings',
      children: [
        SettingsGroup(
          title: 'Bluetooth Connections',
          children: <Widget>[
            SettingsContainer(
              leftPadding: 16,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Text("Scan for DE1 and scales (Lunar, Skale2, Eureka, Decent)"),
                      if (!bleService.isScanning)
                        ElevatedButton(
                            onPressed: () {
                              bleService.startScan();
                            },
                            child: const Text("Scan for Devices")),
                    ],
                  ),
                ),
                if (bleService.isScanning)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    SizedBox(width: 100, child: Text("Found: ${bleService.devices.length} devices")),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: bleService.devices.map((e) => Text("${e.name} (${e.id})")).toList(),
                    ),
                  ],
                ),
              ],
            ),
            ExpandableSettingsTile(
              title: "Bluetooth devices",
              children: [
                SwitchSettingsTile(
                  leading: const Icon(Icons.settings_remote),
                  settingKey: SettingKeys.hasScale.name,
                  defaultValue: settingsService.hasScale,
                  title: 'Scale support',
                ),
                SwitchSettingsTile(
                  leading: const Icon(Icons.settings_remote),
                  settingKey: SettingKeys.hasSteamThermometer.name,
                  defaultValue: settingsService.hasSteamThermometer,
                  title: 'Milk steaming thermometer support',
                ),
              ],
            ),
          ],
        ),
        SettingsGroup(
          title: "Coffee pouring",
          children: [
            ExpandableSettingsTile(
              title: 'Shot Settings',
              children: <Widget>[
                SwitchSettingsTile(
                  settingKey: SettingKeys.shotStopOnWeight.name,
                  defaultValue: settingsService.shotStopOnWeight,
                  title: 'Stop on Weight if scale detected',
                  subtitle: 'If the scale is connected it is used to stop the shot if the profile has a limit given.',
                  enabledLabel: 'Enabled',
                  disabledLabel: 'Disabled',
                  onChange: (value) {
                    debugPrint('ShotStopOnWeight: $value');
                  },
                ),
                SwitchSettingsTile(
                  settingKey: SettingKeys.shotAutoTare.name,
                  defaultValue: settingsService.shotAutoTare,
                  title: 'Auto Tare',
                  subtitle: 'If a shot is starting, auto-tare the scale',
                  enabledLabel: 'Enabled',
                  disabledLabel: 'Disabled',
                  onChange: (value) {
                    debugPrint('ShotAutoTare: $value');
                  },
                ),
              ],
            ),
          ],
        ),
        SettingsGroup(
          title: "Tablet",
          children: [
            ExpandableSettingsTile(title: "Sleep Timer", children: [
              SliderSettingsTile(
                title: 'Switch Off After',
                settingKey: SettingKeys.sleepTimer.name,
                defaultValue: settingsService.sleepTimer,
                min: 0,
                max: 240,
                step: 5,
                leading: const Icon(Icons.switch_left),
                onChange: (value) {
                  debugPrint('key-slider-volume: $value');
                },
              ),
              SliderSettingsTile(
                title: 'Screen Lock',
                settingKey: SettingKeys.screenLockTimer.name,
                defaultValue: settingsService.screenLockTimer,
                min: 0,
                max: 240,
                step: 5,
                leading: const Icon(Icons.lock),
                onChange: (value) {
                  debugPrint('key-slider-volume: $value');
                },
              )
            ]),
            ExpandableSettingsTile(
              title: "Smart charging",
              children: [
                SwitchSettingsTile(
                  leading: const Icon(Icons.power),
                  defaultValue: settingsService.smartCharging,
                  settingKey: SettingKeys.smartCharging.name,
                  title: 'Keep Tablet charged between 60-90%',
                  onChange: (value) {
                    debugPrint('smartCharging: $value');
                  },
                ),
              ],
            ),
          ],
        ),
        SettingsGroup(
          title: "Cloud and Network",
          children: [
            ExpandableSettingsTile(
              title: "Message Queue Broadcast",
              children: [
                SwitchSettingsTile(
                  defaultValue: settingsService.mqttEnabled,
                  leading: const Icon(Icons.settings_remote),
                  settingKey: SettingKeys.mqttEnabled.name,
                  title: 'Enable MQTT',
                  onChange: (value) {
                    debugPrint('mqtt enabled: $value');
                    if (value) {
                      mqttService.startService();
                    } else {
                      mqttService.stopService();
                    }
                  },
                ),
                TextInputSettingsTile(
                  title: 'MQTT Server',
                  settingKey: SettingKeys.mqttServer.name,
                  initialValue: settingsService.mqttServer,
                ),
                TextInputSettingsTile(
                    title: 'MQTT Port', settingKey: SettingKeys.mqttPort.name, initialValue: settingsService.mqttPort),
                TextInputSettingsTile(
                  title: 'MQTT User',
                  settingKey: SettingKeys.mqttUser.name,
                  initialValue: settingsService.mqttUser,
                ),
                TextInputSettingsTile(
                  title: 'MQTT Password',
                  settingKey: SettingKeys.mqttPassword.name,
                  initialValue: settingsService.mqttPassword,
                  obscureText: true,
                ),
                TextInputSettingsTile(
                  title: 'MQTT root topic',
                  settingKey: SettingKeys.mqttRootTopic.name,
                  initialValue: settingsService.mqttRootTopic,
                  obscureText: false,
                ),
                SwitchSettingsTile(
                  leading: const Icon(Icons.settings_remote),
                  settingKey: SettingKeys.mqttSendState.name,
                  defaultValue: settingsService.mqttSendState,
                  title: 'Send de1 state updates',
                  subtitle: "Sending the status of the de1",
                  onChange: (value) {},
                ),
                SwitchSettingsTile(
                  leading: const Icon(Icons.settings_remote),
                  settingKey: SettingKeys.mqttSendShot.name,
                  defaultValue: settingsService.mqttSendShot,
                  title: 'Send de1 shot updates',
                  subtitle:
                      "This can lead to a higher load on your MQTT server as the message frequency is about 10Hz.",
                  onChange: (value) {},
                ),
                SwitchSettingsTile(
                  leading: const Icon(Icons.settings_remote),
                  settingKey: SettingKeys.mqttSendWater.name,
                  defaultValue: settingsService.mqttSendWater,
                  title: 'Send de1 water level updates',
                  subtitle: "This can lead to a higher load on your MQTT server.",
                  onChange: (value) {},
                ),
                SwitchSettingsTile(
                  leading: const Icon(Icons.settings_remote),
                  settingKey: SettingKeys.mqttSendBattery.name,
                  defaultValue: settingsService.mqttSendBattery,
                  title: 'Send tablet battery level updates',
                  onChange: (value) {},
                ),
              ],
            ),
            ExpandableSettingsTile(
                title: 'Visualizer',
                subtitle: 'Cloud shot upload',
                expanded: false,
                children: <Widget>[
                  SwitchSettingsTile(
                    leading: const Icon(Icons.cloud_upload),
                    settingKey: SettingKeys.visualizerUpload.name,
                    defaultValue: settingsService.visualizerUpload,
                    title: 'Upload Shots to Visualizer',
                    onChange: (value) {
                      debugPrint('USB Debugging: $value');
                    },
                  ),
                  TextInputSettingsTile(
                    title: 'User Name/email',
                    settingKey: SettingKeys.visualizerUser.name,
                    initialValue: settingsService.visualizerUser,
                    validator: (String? username) {
                      if (username != null && username.length > 3) {
                        return null;
                      }
                      return "User Name can't be smaller than 4 letters";
                    },
                    borderColor: Colors.blueAccent,
                    errorColor: Colors.deepOrangeAccent,
                  ),
                  TextInputSettingsTile(
                    title: 'password',
                    initialValue: settingsService.visualizerPwd,
                    settingKey: SettingKeys.visualizerPwd.name,
                    obscureText: true,
                    validator: (String? password) {
                      if (password != null && password.length > 6) {
                        return null;
                      }
                      return "Password can't be smaller than 7 letters";
                    },
                    borderColor: Colors.blueAccent,
                    errorColor: Colors.deepOrangeAccent,
                  ),
                ]),
            ExpandableSettingsTile(
              title: "Mini Website",
              children: [
                SwitchSettingsTile(
                  defaultValue: settingsService.webServer,
                  leading: const Icon(Icons.settings_remote),
                  settingKey: SettingKeys.webServer.name,
                  title: 'Enable Mini Website with port 8888',
                  subtitle:
                      "Check your router for IP adress of your tablet. Open browser under http://$ownIpAdress:8888",
                  onChange: (value) {
                    settingsService.notifyDelayed();
                  },
                ),
              ],
            ),
          ],
        ),
        SettingsGroup(
          title: "Backup Settings",
          children: [
            ExpandableSettingsTile(
              title: 'Backup/Restore Settings',
              expanded: false,
              children: <Widget>[
                SettingsContainer(
                  leftPadding: 16,
                  children: [
                    const Text("Backup/Restore database"),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                              onPressed: () {
                                backupDatabase();
                              },
                              child: const Text("Backup")),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                              onPressed: () {
                                restoreDatabase();
                              },
                              child: const Text("Restore")),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        SettingsGroup(
          title: "Privacy Settings",
          children: [
            ExpandableSettingsTile(
              title: 'Feedback and Crash reporting',
              expanded: false,
              children: <Widget>[
                SwitchSettingsTile(
                  leading: const Icon(Icons.settings_remote),
                  settingKey: SettingKeys.useSentry.name,
                  defaultValue: settingsService.useSentry,
                  title:
                      'Send informations to sentry.io if the app crashes or you use the feedback option. Check https://sentry.io/privacy/ for detailed data privacy description.',
                  onChange: (value) {
                    showSnackbar(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void showSnackbar(BuildContext context) {
    var snackBar = SnackBar(
        duration: const Duration(seconds: 5),
        content: const Text('You changed critical settings. You need to restart the app to make the settings active.'),
        action: SnackBarAction(
          label: 'ok',
          onPressed: () {
            // Some code to undo the change.
          },
        ));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Column createKeyValue(String key, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(key, style: theme.TextStyles.tabHeading),
        Text(value, style: theme.TextStyles.tabPrimary),
      ],
    );
  }

  void settingsServiceListener() {
    setState(() {});
  }

  Future<void> backupDatabase() async {
    try {
      var objectBox = getIt<ObjectBox>();
      var data = objectBox.getBackupData();
      await DocumentFileSavePlus.saveFile(data, "despresso_backup.bak", "application/octet-stream");
      log.info("Backupdata saved ${data.length}");

      var snackBar = SnackBar(
          content: const Text('Saved backup'),
          action: SnackBarAction(
            label: 'ok',
            onPressed: () {
              // Some code to undo the change.
            },
          ));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      log.severe("Save database failed $e");
      var snackBar = SnackBar(
          content: const Text('Saving backup failed'),
          action: SnackBarAction(
            label: 'ok',
            onPressed: () {
              // Some code to undo the change.
            },
          ));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> restoreDatabase() async {
    var filePickerResult = await FilePicker.platform.pickFiles(lockParentWindow: true, type: FileType.any);

    if (filePickerResult != null) {
      var objectBox = getIt<ObjectBox>();
      try {
        await objectBox.restoreBackupData(filePickerResult.files.single.path.toString());
        showRestartNowScreen();
        var snackBar = SnackBar(
            content: const Text('Restored backup'),
            action: SnackBarAction(
              label: 'ok',
              onPressed: () {
                // Some code to undo the change.
              },
            ));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } catch (e) {
        log.severe("Store restored $e");
        var snackBar = SnackBar(
            content: const Text('Failed restoring backup'),
            action: SnackBarAction(
              label: 'error',
              onPressed: () {
                // Some code to undo the change.
              },
            ));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } else {
      // can perform some actions like notification etc
    }
  }

  void showRestartNowScreen() {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black12.withOpacity(0.9), // Background color
      barrierDismissible: false,

      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) {
        return Column(
          children: <Widget>[
            Expanded(
              flex: 5,
              child: SizedBox.expand(
                child: Image.asset("assets/logo.png"),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text("Settings are restored. Please close app and restart.",
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  if (Platform.isAndroid) {
                    SystemNavigator.pop();
                  } else if (Platform.isIOS) {
                    exit(0);
                  }
                },
                child: const Text("Exit app"),
              ),
            ),
          ],
        );
      },
    );
  }
}
