import 'dart:async';
import 'dart:io';

import 'package:despresso/logger_util.dart';
import 'package:despresso/model/services/ble/ble_service.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/state/mqtt_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/model/services/state/visualizer_service.dart';
import 'package:despresso/objectbox.dart';
import 'package:despresso/ui/widgets/screen_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:logging/logging.dart';
import 'package:document_file_save_plus/document_file_save_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';
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
  late EspressoMachineService machineService;

  String? ownIpAdress = "<IP-ADRESS-OF-TABLET>";

  Timer? _resetBrightness;

  late StreamController<int> _controllerRefresh;
  late Stream<int> _streamRefresh;

  @override
  initState() {
    super.initState();
    settingsService = getIt<SettingsService>();
    machineService = getIt<EspressoMachineService>();
    bleService = getIt<BLEService>();
    visualizerService = getIt<VisualizerService>();
    settingsService.addListener(settingsServiceListener);
    bleService.addListener(settingsServiceListener);
    getIpAdress();

    _controllerRefresh = StreamController<int>();
    _streamRefresh = _controllerRefresh.stream.asBroadcastStream();
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
          title: "Hardware and connections",
          children: [
            SimpleSettingsTile(
              title: 'Bluetooth',
              leading: const Icon(Icons.bluetooth),
              child: SettingsScreen(
                title: 'Bluetooth',
                children: [
                  StreamBuilder<Object>(
                      stream: _streamRefresh,
                      builder: (context, snapshot) {
                        return SettingsContainer(
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
                                          setState(() {
                                            _controllerRefresh.add(0);
                                          });
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
                        );
                      }),
                  SettingsGroup(
                    title: "Special Bluetooth devices",
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
            ),
          ],
        ),
        SettingsGroup(
          title: "Coffee",
          children: [
            SimpleSettingsTile(
              title: "Coffee pouring",
              leading: const Icon(Icons.coffee),
              child: SettingsScreen(
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
                  SliderSettingsTile(
                    title: 'Stop before weight was reached [s]',
                    // subtitle:
                    //     "Delays in scale could be adjusted accordingly. The weight is calculated based on the current flow during an espresso shot",
                    settingKey: SettingKeys.targetEspressoWeightTimeAdjust.name,
                    defaultValue: settingsService.targetEspressoWeightTimeAdjust,
                    min: 0.05,
                    max: 0.95,
                    step: 0.05,
                    leading: const Icon(Icons.timer),
                    onChange: (value) {
                      debugPrint('targetEspressoWeightTimeAdjust: $value');
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
                  SwitchSettingsTile(
                    settingKey: SettingKeys.steamHeaterOff.name,
                    defaultValue: settingsService.steamHeaterOff,
                    title: 'Switch off steam heating',
                    subtitle: 'To save energy the steam heater will be turned off and the steam tab will be hidden.',
                    enabledLabel: 'Enabled',
                    disabledLabel: 'Disabled',
                    onChange: (value) {
                      log.info('steamHeaterOff: $value');
                      machineService.updateSettings();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: "Tablet",
          children: [
            SimpleSettingsTile(
              title: "Theme selection",
              leading: const Icon(Icons.palette),
              child: StreamBuilder<int>(
                  stream: _streamRefresh,
                  builder: (context, snapshot) {
                    return SettingsScreen(children: [
                      SwitchSettingsTile(
                        title: settingsService.screenDarkTheme ? 'Dark theme' : "Light theme",
                        settingKey: SettingKeys.screenDarkTheme.name,
                        defaultValue: settingsService.screenDarkTheme,
                        leading: const Icon(Icons.smart_screen),
                        onChange: (value) {
                          settingsService.notifyDelayed();
                          updateView();
                        },
                      ),
                      DropDownSettingsTile(
                          title: "Theme selection",
                          settingKey: SettingKeys.screenThemeIndex.name,
                          selected: settingsService.screenThemeIndex,
                          values: const {
                            "0": "Red",
                            "1": "Orange",
                            "2": "Blue",
                            "3": "Green",
                          },
                          onChange: (value) {
                            settingsService.notifyDelayed();
                          }),
                    ]);
                  }),
            ),
            SimpleSettingsTile(
              title: "Screen and Brightness",
              leading: const Icon(Icons.brightness_2),
              subtitle:
                  "Change how the app is changing screen brightness if not in use, switch the de1 on and shut it off if not used after a while.",
              child: SettingsScreen(title: "Brightness, sleep and screensaver", children: [
                SliderSettingsTile(
                  title: 'Reduce screen brightness after (0=off) [min]',
                  settingKey: SettingKeys.screenBrightnessTimer.name,
                  defaultValue: settingsService.screenBrightnessTimer,
                  min: 0,
                  max: 60,
                  step: 1,
                  leading: const Icon(Icons.timer),
                  onChange: (value) {
                    debugPrint('key-slider-volume: $value');
                  },
                ),
                SliderSettingsTile(
                  title: 'Reduce brightness to level',
                  settingKey: SettingKeys.screenBrightnessValue.name,
                  defaultValue: settingsService.screenBrightnessValue,
                  min: 0,
                  max: 1,
                  step: 0.01,
                  leading: const Icon(Icons.brightness_3),
                  onChange: (value) async {
                    try {
                      await ScreenBrightness().setScreenBrightness(value);
                      if (_resetBrightness != null) {
                        _resetBrightness!.cancel();
                        _resetBrightness = null;
                      }
                      _resetBrightness = Timer(
                        const Duration(seconds: 2),
                        () async {
                          log.info("Release");
                          await ScreenBrightness().resetScreenBrightness();
                        },
                      );
                    } catch (e) {
                      log.severe('Failed to set brightness');
                    }
                  },
                ),
                SettingsContainer(
                  leftPadding: 16,
                  children: [
                    const Text("Load Screensaver files"),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                              onPressed: () {
                                pickScreensaver();
                              },
                              child: const Text("Select files")),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                              onPressed: () {
                                ScreenSaver.deleteAllFiles();
                              },
                              child: const Text("Delete all screensaver files")),
                        ),
                      ],
                    ),
                  ],
                ),
                SliderSettingsTile(
                  title: 'Do not let tablet go to lock screen (0=do not lock screen, 240=keep always locked) [min]',
                  // subtitle: settingsService.screenLockTimer > 239 ? "Switched off" : "bla",
                  settingKey: SettingKeys.screenLockTimer.name,
                  defaultValue: settingsService.screenLockTimer,
                  min: 0,
                  max: 240,
                  step: 5,
                  leading: const Icon(Icons.lock),
                  onChange: (value) {
                    debugPrint('key-slider-volume: $value');
                    setState(() {});
                  },
                )
              ]),
            ),
            SimpleSettingsTile(
              title: "Bahaviour",
              leading: const Icon(Icons.switch_access_shortcut),
              subtitle: "Change how the app is handling the de1 in case of wake up and sleep.",
              child: SettingsScreen(title: "Behaviour", children: [
                SliderSettingsTile(
                  title: 'Switch de1 to sleep mode if it is idle for some time [min]',
                  settingKey: SettingKeys.sleepTimer.name,
                  defaultValue: settingsService.sleepTimer,
                  min: 0,
                  max: 240,
                  step: 5,
                  leading: const Icon(Icons.timer),
                  onChange: (value) {
                    debugPrint('key-slider-volume: $value');
                  },
                ),
                SwitchSettingsTile(
                  title: 'Wake up de1 if screen tapped (if screen was off)',
                  settingKey: SettingKeys.screenTapWake.name,
                  defaultValue: settingsService.screenTapWake,
                  leading: const Icon(Icons.back_hand),
                  onChange: (value) async {},
                ),
                SwitchSettingsTile(
                  title: 'Go back to Recipe screen if timeout occured',
                  settingKey: SettingKeys.screenTimoutGoToRecipe.name,
                  defaultValue: settingsService.screenTimoutGoToRecipe,
                  leading: const Icon(Icons.coffee),
                  onChange: (value) async {},
                ),
              ]),
            ),
            SimpleSettingsTile(
              title: "Smart charging",
              leading: const Icon(Icons.power),
              child: SettingsScreen(title: "Smart charging", children: [
                SwitchSettingsTile(
                  leading: const Icon(Icons.power),
                  defaultValue: settingsService.smartCharging,
                  settingKey: SettingKeys.smartCharging.name,
                  title: 'Keep Tablet charged between 60-90%',
                  onChange: (value) {
                    debugPrint('smartCharging: $value');
                  },
                ),
              ]),
            ),
          ],
        ),
        SettingsGroup(
          title: "Cloud and Network",
          children: [
            SimpleSettingsTile(
              title: "Cloud and Network",
              subtitle: "Handling of connections to other external systems like MQTT and Visualizer.",
              leading: const Icon(Icons.cloud),
              child: SettingsScreen(
                title: "Cloud and Network",
                children: [
                  ExpandableSettingsTile(
                    title: "Message Queue Broadcast (MQTT) client",
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
                          title: 'MQTT Port',
                          settingKey: SettingKeys.mqttPort.name,
                          initialValue: settingsService.mqttPort),
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
            ),
          ],
        ),
        SettingsGroup(
          title: "Backup and maintenance",
          children: [
            SimpleSettingsTile(
              title: "Backup Settings",
              leading: const Icon(Icons.backup_table),
              child: SettingsScreen(
                title: 'Backup/Restore',
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
            ),
          ],
        ),
        SettingsGroup(
          title: "Privacy Settings",
          children: [
            SimpleSettingsTile(
              title: "Privacy Settings",
              leading: const Icon(Icons.privacy_tip),
              child: SettingsScreen(
                title: 'Feedback and Crash reporting',
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

  void settingsServiceListener() {
    setState(() {});
    updateView();
  }

  Future<void> backupDatabase() async {
    try {
      var objectBox = getIt<ObjectBox>();
      List<Uint8List> data = [];
      data.add(objectBox.getBackupData());
      data.add(await getLoggerBackupData());

      var dateStr = DateTime.now().toLocal();

      await DocumentFileSavePlus.saveMultipleFiles(data, [
        "despresso_backup_$dateStr.bak",
        "logs_$dateStr.zip"
      ], [
        "application/octet-stream",
        "application/zip",
      ]);
      log.info("Backupdata saved ${data[0].length + data[1].length}");

      var snackBar = SnackBar(
          backgroundColor: Colors.greenAccent,
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
          backgroundColor: const Color.fromARGB(255, 250, 141, 141),
          content: Text('Saving backup failed $e'),
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

  Future<void> pickScreensaver() async {
    var filePickerResult =
        await FilePicker.platform.pickFiles(allowMultiple: true, lockParentWindow: true, type: FileType.image);

    final Directory saver = await ScreenSaver.getDirectory();

    if (filePickerResult != null) {
      try {
        for (var file in filePickerResult.files) {
          log.info("Screensaver: ${file.path}");
          String fileDestination = "${saver.path}${file.name}";
          var f = File(file.path!);
          await f.copy(fileDestination);
        }
      } catch (e) {
        log.severe("Error copy screensaver image $e");
      }
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

  void updateView() {
    _controllerRefresh.add(0);
  }
}
