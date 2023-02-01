import 'dart:developer';

import 'package:despresso/model/services/ble/ble_service.dart';
import 'package:despresso/model/services/state/mqtt_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import '../../service_locator.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({Key? key}) : super(key: key);

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<AppSettingsScreen> {
  late SettingsService settingsService;
  late BLEService bleService;
  late MqttService mqttService;

  @override
  void initState() {
    super.initState();
    settingsService = getIt<SettingsService>();
    bleService = getIt<BLEService>();
    settingsService.addListener(settingsServiceListener);
    bleService.addListener(settingsServiceListener);
  }

  @override
  void dispose() {
    super.dispose();

    settingsService.removeListener(settingsServiceListener);
    bleService.removeListener(settingsServiceListener);
    log('Disposed settingspage');
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      title: 'Application Settings',
      children: [
        SettingsGroup(
          title: 'Machine Connection',
          children: <Widget>[
            SettingsContainer(
              leftPadding: 16,
              children: [
                const Text("Scan for DE1 and Lunar scale"),
                if (!bleService.isScanning)
                  ElevatedButton(
                      onPressed: () {
                        bleService.startScan();
                      },
                      child: const Text("Scan for Devices")),
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
          ],
        ),
        ExpandableSettingsTile(
          title: 'Shot Settings',
          children: <Widget>[
            SwitchSettingsTile(
              settingKey: SettingKeys.shotStopOnWeight.name,
              defaultValue: true,
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
              defaultValue: true,
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
        ExpandableSettingsTile(title: "Sleep Timer", children: [
          SliderSettingsTile(
            title: 'Switch Off After',
            settingKey: SettingKeys.sleepTimer.name,
            defaultValue: 120,
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
            defaultValue: 120,
            min: 0,
            max: 240,
            step: 5,
            leading: const Icon(Icons.lock),
            onChange: (value) {
              debugPrint('key-slider-volume: $value');
            },
          )
        ]),

        ExpandableSettingsTile(title: 'Vizualizer', subtitle: 'Cloud shot upload', expanded: false, children: <Widget>[
          SwitchSettingsTile(
            leading: const Icon(Icons.usb),
            settingKey: SettingKeys.vizualizerUpload.name,
            defaultValue: false,
            title: 'Upload Shots to Vizualizer',
            onChange: (value) {
              debugPrint('USB Debugging: $value');
            },
          ),
          TextInputSettingsTile(
            title: 'User Name/email',
            settingKey: SettingKeys.vizualizerUser.name,
            initialValue: 'admin',
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
            settingKey: SettingKeys.vizualizerPwd.name,
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
          title: 'App UI',
          children: <Widget>[
            SwitchSettingsTile(
              leading: const Icon(Icons.line_axis),
              defaultValue: settingsService.graphSingle,
              settingKey: SettingKeys.graphSingle.name,
              title: 'Single Graph',
              onChange: (value) {
                debugPrint('graphSingle: $value');
              },
            ),
          ],
        ),

        ExpandableSettingsTile(
          title: "Tablet settings",
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

        // SettingsGroup(
        //   title: 'Multiple choice settings',
        //   children: <Widget>[
        //     RadioSettingsTile<int>(
        //       title: 'Preferred Sync Period',
        //       settingKey: 'key-radio-sync-period',
        //       values: const <int, String>{
        //         0: 'Never',
        //         1: 'Daily',
        //         7: 'Weekly',
        //         15: 'Fortnight',
        //         30: 'Monthly',
        //       },
        //       selected: 0,
        //       onChange: (value) {
        //         debugPrint('key-radio-sync-period: $value');
        //       },
        //     ),
        //     DropDownSettingsTile<int>(
        //       title: 'E-Mail View',
        //       settingKey: 'key-dropdown-email-view',
        //       values: const <int, String>{
        //         2: 'Simple',
        //         3: 'Adjusted',
        //         4: 'Normal',
        //         5: 'Compact',
        //         6: 'Squizzed',
        //       },
        //       selected: 2,
        //       onChange: (value) {
        //         debugPrint('key-dropdown-email-view: $value');
        //       },
        //     ),
        //   ],
        // ),
        // ModalSettingsTile(
        //   title: 'Group Settings',
        //   subtitle: 'Same group settings but in a dialog',
        //   children: <Widget>[
        //     SimpleRadioSettingsTile(
        //       title: 'Sync Settings',
        //       settingKey: 'key-radio-sync-settings',
        //       values: const <String>[
        //         'Never',
        //         'Daily',
        //         'Weekly',
        //         'Fortnight',
        //         'Monthly',
        //       ],
        //       selected: 'Daily',
        //       onChange: (value) {
        //         debugPrint('key-radio-sync-settings: $value');
        //       },
        //     ),
        //     SimpleDropDownSettingsTile(
        //       title: 'Beauty Filter',
        //       settingKey: 'key-dropdown-beauty-filter',
        //       values: const <String>[
        //         'Simple',
        //         'Normal',
        //         'Little Special',
        //         'Special',
        //         'Extra Special',
        //         'Bizarre',
        //         'Horrific',
        //       ],
        //       selected: 'Special',
        //       onChange: (value) {
        //         debugPrint('key-dropdown-beauty-filter: $value');
        //       },
        //     )
        //   ],
        // ),
        // ExpandableSettingsTile(
        //   title: 'Expandable Group Settings',
        //   subtitle: 'Group of settings (expandable)',
        //   children: <Widget>[
        //     RadioSettingsTile<double>(
        //       title: 'Beauty Filter',
        //       settingKey: 'key-radio-beauty-filter-expandable',
        //       values: <double, String>{
        //         1.0: 'Simple',
        //         1.5: 'Normal',
        //         2.0: 'Little Special',
        //         2.5: 'Special',
        //         3.0: 'Extra Special',
        //         3.5: 'Bizarre',
        //         4.0: 'Horrific',
        //       },
        //       selected: 2.5,
        //       onChange: (value) {
        //         debugPrint('key-radio-beauty-filter-expandable: $value');
        //       },
        //     ),
        //     DropDownSettingsTile<int>(
        //       title: 'Preferred Sync Period',
        //       settingKey: 'key-dropdown-sync-period-2',
        //       values: const <int, String>{
        //         0: 'Never',
        //         1: 'Daily',
        //         7: 'Weekly',
        //         15: 'Fortnight',
        //         30: 'Monthly',
        //       },
        //       selected: 0,
        //       onChange: (value) {
        //         debugPrint('key-dropdown-sync-period-2: $value');
        //       },
        //     )
        //   ],
        // ),
        // SettingsGroup(
        //   title: 'Other settings',
        //   children: <Widget>[
        //     SliderSettingsTile(
        //       title: 'Volume [Auto-Adjusting to 20]',
        //       settingKey: 'key-slider-volume',
        //       defaultValue: 20,
        //       min: 0,
        //       max: 100,
        //       step: 1,
        //       leading: const Icon(Icons.volume_up),
        //       decimalPrecision: 0,
        //       onChange: (value) {
        //         debugPrint('\n===== on change end =====\n'
        //             'key-slider-volume: $value'
        //             '\n==========\n');
        //         Future.delayed(const Duration(seconds: 1), () {
        //           // Reset value only if the current value is not 20
        //           if (Settings.getValue('key-slider-volume') != 20) {
        //             debugPrint('\n===== on change end =====\n'
        //                 'Resetting value to 20'
        //                 '\n==========\n');
        //             Settings.setValue('key-slider-volume', 20.0, notify: true);
        //           }
        //         });
        //       },
        //     ),
        //     ColorPickerSettingsTile(
        //       settingKey: 'key-color-picker',
        //       title: 'Accent Color',
        //       defaultValue: Colors.blue,
        //       onChange: (value) {
        //         debugPrint('key-color-picker: $value');
        //       },
        //     )
        //   ],
        // ),
        // ModalSettingsTile(
        //   title: 'Other settings',
        //   subtitle: 'Other Settings in a Dialog',
        //   children: <Widget>[
        //     SliderSettingsTile(
        //       title: 'Custom Ratio',
        //       settingKey: 'key-custom-ratio-slider-2',
        //       defaultValue: 2.5,
        //       min: 1,
        //       max: 5,
        //       step: 0.1,
        //       decimalPrecision: 1,
        //       leading: const Icon(Icons.aspect_ratio),
        //       onChange: (value) {
        //         debugPrint('\n===== on change =====\n'
        //             'key-custom-ratio-slider-2: $value'
        //             '\n==========\n');
        //       },
        //       onChangeStart: (value) {
        //         debugPrint('\n===== on change start =====\n'
        //             'key-custom-ratio-slider-2: $value'
        //             '\n==========\n');
        //       },
        //       onChangeEnd: (value) {
        //         debugPrint('\n===== on change end =====\n'
        //             'key-custom-ratio-slider-2: $value'
        //             '\n==========\n');
        //       },
        //     ),
        //     ColorPickerSettingsTile(
        //       settingKey: 'key-color-picker-2',
        //       title: 'Accent Picker',
        //       defaultValue: Colors.blue,
        //       onChange: (value) {
        //         debugPrint('key-color-picker-2: $value');
        //       },
        //     )
        //   ],
        // ),

        ExpandableSettingsTile(
          title: "Message Queue Broadcast",
          children: [
            SwitchSettingsTile(
              leading: const Icon(Icons.settings_remote),
              settingKey: SettingKeys.mqttEnabled.name,
              title: 'Enable MQTT',
              onChange: (value) {
                debugPrint('mqtt enabled: $value');
                if (value) {
                  mqttService.startService();
                } else {
                  //stop mqtt service
                }
              },
            ),
            TextInputSettingsTile(
              title: 'MQTT Server',
              settingKey: SettingKeys.mqttServer.name,
              initialValue: 'mqtt://192.168.1.14',
            ),
            TextInputSettingsTile(
              title: 'MQTT Port',
              settingKey: SettingKeys.mqttPort.name,
              initialValue: '1883',
            ),
            TextInputSettingsTile(
              title: 'MQTT User',
              settingKey: SettingKeys.mqttUser.name,
              initialValue: 'user',
            ),
            TextInputSettingsTile(
              title: 'MQTT Password',
              settingKey: SettingKeys.mqttPassword.name,
              initialValue: '',
              obscureText: true,
            ),
          ],
        ),
      ],
    );
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
}
