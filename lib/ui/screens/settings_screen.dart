import 'dart:developer';

import 'package:despresso/model/services/ble/ble_service.dart';
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
        SettingsGroup(
          title: 'Shot Settings',
          children: <Widget>[
            SwitchSettingsTile(
              settingKey: 'ShotStopOnWeight',
              title: 'Stop on Weight if scale detected',
              subtitle: 'If the scale is connected it is used to stop the shot if the profile has a limit given.',
              enabledLabel: 'Enabled',
              disabledLabel: 'Disabled',
              onChange: (value) {
                debugPrint('ShotStopOnWeight: $value');
              },
            ),
            SwitchSettingsTile(
              settingKey: 'ShotAutoTare',
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
        SettingsGroup(
          title: "Cloud Services",
          children: [
            ExpandableSettingsTile(
                title: 'Vizualizer',
                subtitle: 'Cloud shot upload',
                expanded: false,
                children: <Widget>[
                  SwitchSettingsTile(
                    leading: const Icon(Icons.usb),
                    settingKey: 'VizualizerUpload',
                    title: 'Upload Shots to Vizualizer',
                    onChange: (value) {
                      debugPrint('USB Debugging: $value');
                    },
                  ),
                  TextInputSettingsTile(
                    title: 'User Name/email',
                    settingKey: 'VizualizerUser',
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
                    settingKey: 'VizualizerPwd',
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
          ],
        ),
        SettingsGroup(
          title: 'Settings',
          children: <Widget>[
            CheckboxSettingsTile(
              settingKey: 'key-blue-tooth',
              title: 'Bluetooth',
              subtitle: 'Bluetooth allows interacting with the '
                  'near by bluetooth enabled devices',
              enabledLabel: 'Enabled',
              disabledLabel: 'Disabled',
              leading: const Icon(Icons.bluetooth),
              onChange: (value) {
                debugPrint('key-blue-tooth: $value');
              },
            ),
            SwitchSettingsTile(
              leading: const Icon(Icons.developer_mode),
              settingKey: 'key-switch-dev-mode',
              title: 'Developer Settings',
              onChange: (value) {
                debugPrint('key-switch-dev-mod: $value');
              },
              childrenIfEnabled: <Widget>[
                CheckboxSettingsTile(
                  leading: const Icon(Icons.adb),
                  settingKey: 'key-is-developer',
                  title: 'Developer Mode',
                  defaultValue: true,
                  onChange: (value) {
                    debugPrint('key-is-developer: $value');
                  },
                ),
                SwitchSettingsTile(
                  leading: const Icon(Icons.usb),
                  settingKey: 'key-is-usb-debugging',
                  title: 'USB Debugging',
                  onChange: (value) {
                    debugPrint('key-is-usb-debugging: $value');
                  },
                ),
                SimpleSettingsTile(
                  title: 'Root Settings',
                  subtitle: 'These setting is not accessible',
                  enabled: false,
                ),
                SimpleSettingsTile(
                  title: 'Custom Settings',
                  subtitle: 'Tap to execute custom callback',
                  onTap: () => debugPrint('Custom action'),
                ),
              ],
            ),
            SimpleSettingsTile(
              title: 'More Settings',
              subtitle: 'General App Settings',
              child: SettingsScreen(
                title: 'App Settings',
                children: <Widget>[
                  CheckboxSettingsTile(
                    leading: const Icon(Icons.adb),
                    settingKey: 'key-is-developer',
                    title: 'Developer Mode',
                    onChange: (bool value) {
                      debugPrint('Developer Mode ${value ? 'on' : 'off'}');
                    },
                  ),
                  SwitchSettingsTile(
                    leading: const Icon(Icons.usb),
                    settingKey: 'key-is-usb-debugging',
                    title: 'USB Debugging',
                    onChange: (value) {
                      debugPrint('USB Debugging: $value');
                    },
                  ),
                ],
              ),
            ),
            ModalSettingsTile(
              title: 'Quick setting dialog',
              subtitle: 'Settings on a dialog',
              children: <Widget>[
                CheckboxSettingsTile(
                  settingKey: 'key-day-light-savings',
                  title: 'Daylight Time Saving',
                  enabledLabel: 'Enabled',
                  disabledLabel: 'Disabled',
                  leading: const Icon(Icons.timelapse),
                  onChange: (value) {
                    debugPrint('key-day-light-saving: $value');
                  },
                ),
                SwitchSettingsTile(
                  settingKey: 'key-dark-mode',
                  title: 'Dark Mode',
                  enabledLabel: 'Enabled',
                  disabledLabel: 'Disabled',
                  leading: const Icon(Icons.palette),
                  onChange: (value) {
                    debugPrint('jey-dark-mode: $value');
                  },
                ),
              ],
            ),
            ExpandableSettingsTile(
              title: 'Quick setting 2',
              subtitle: 'Expandable Settings',
              expanded: true,
              children: <Widget>[
                CheckboxSettingsTile(
                  settingKey: 'key-day-light-savings-2',
                  title: 'Daylight Time Saving',
                  enabledLabel: 'Enabled',
                  disabledLabel: 'Disabled',
                  leading: const Icon(Icons.timelapse),
                  onChange: (value) {
                    debugPrint('key-day-light-savings-2: $value');
                  },
                ),
                SwitchSettingsTile(
                  settingKey: 'key-dark-mode-2',
                  title: 'Dark Mode',
                  enabledLabel: 'Enabled',
                  disabledLabel: 'Disabled',
                  leading: const Icon(Icons.palette),
                  onChange: (value) {
                    debugPrint('key-dark-mode-2: $value');
                  },
                ),
              ],
            ),
          ],
        ),
        SettingsGroup(
          title: 'Multiple choice settings',
          children: <Widget>[
            RadioSettingsTile<int>(
              title: 'Preferred Sync Period',
              settingKey: 'key-radio-sync-period',
              values: const <int, String>{
                0: 'Never',
                1: 'Daily',
                7: 'Weekly',
                15: 'Fortnight',
                30: 'Monthly',
              },
              selected: 0,
              onChange: (value) {
                debugPrint('key-radio-sync-period: $value');
              },
            ),
            DropDownSettingsTile<int>(
              title: 'E-Mail View',
              settingKey: 'key-dropdown-email-view',
              values: const <int, String>{
                2: 'Simple',
                3: 'Adjusted',
                4: 'Normal',
                5: 'Compact',
                6: 'Squizzed',
              },
              selected: 2,
              onChange: (value) {
                debugPrint('key-dropdown-email-view: $value');
              },
            ),
          ],
        ),
        ModalSettingsTile(
          title: 'Group Settings',
          subtitle: 'Same group settings but in a dialog',
          children: <Widget>[
            SimpleRadioSettingsTile(
              title: 'Sync Settings',
              settingKey: 'key-radio-sync-settings',
              values: const <String>[
                'Never',
                'Daily',
                'Weekly',
                'Fortnight',
                'Monthly',
              ],
              selected: 'Daily',
              onChange: (value) {
                debugPrint('key-radio-sync-settings: $value');
              },
            ),
            SimpleDropDownSettingsTile(
              title: 'Beauty Filter',
              settingKey: 'key-dropdown-beauty-filter',
              values: const <String>[
                'Simple',
                'Normal',
                'Little Special',
                'Special',
                'Extra Special',
                'Bizarre',
                'Horrific',
              ],
              selected: 'Special',
              onChange: (value) {
                debugPrint('key-dropdown-beauty-filter: $value');
              },
            )
          ],
        ),
        ExpandableSettingsTile(
          title: 'Expandable Group Settings',
          subtitle: 'Group of settings (expandable)',
          children: <Widget>[
            RadioSettingsTile<double>(
              title: 'Beauty Filter',
              settingKey: 'key-radio-beauty-filter-expandable',
              values: <double, String>{
                1.0: 'Simple',
                1.5: 'Normal',
                2.0: 'Little Special',
                2.5: 'Special',
                3.0: 'Extra Special',
                3.5: 'Bizarre',
                4.0: 'Horrific',
              },
              selected: 2.5,
              onChange: (value) {
                debugPrint('key-radio-beauty-filter-expandable: $value');
              },
            ),
            DropDownSettingsTile<int>(
              title: 'Preferred Sync Period',
              settingKey: 'key-dropdown-sync-period-2',
              values: const <int, String>{
                0: 'Never',
                1: 'Daily',
                7: 'Weekly',
                15: 'Fortnight',
                30: 'Monthly',
              },
              selected: 0,
              onChange: (value) {
                debugPrint('key-dropdown-sync-period-2: $value');
              },
            )
          ],
        ),
        SettingsGroup(
          title: 'Other settings',
          children: <Widget>[
            SliderSettingsTile(
              title: 'Volume [Auto-Adjusting to 20]',
              settingKey: 'key-slider-volume',
              defaultValue: 20,
              min: 0,
              max: 100,
              step: 1,
              leading: const Icon(Icons.volume_up),
              decimalPrecision: 0,
              onChange: (value) {
                debugPrint('\n===== on change end =====\n'
                    'key-slider-volume: $value'
                    '\n==========\n');
                Future.delayed(const Duration(seconds: 1), () {
                  // Reset value only if the current value is not 20
                  if (Settings.getValue('key-slider-volume') != 20) {
                    debugPrint('\n===== on change end =====\n'
                        'Resetting value to 20'
                        '\n==========\n');
                    Settings.setValue('key-slider-volume', 20.0, notify: true);
                  }
                });
              },
            ),
            ColorPickerSettingsTile(
              settingKey: 'key-color-picker',
              title: 'Accent Color',
              defaultValue: Colors.blue,
              onChange: (value) {
                debugPrint('key-color-picker: $value');
              },
            )
          ],
        ),
        ModalSettingsTile(
          title: 'Other settings',
          subtitle: 'Other Settings in a Dialog',
          children: <Widget>[
            SliderSettingsTile(
              title: 'Custom Ratio',
              settingKey: 'key-custom-ratio-slider-2',
              defaultValue: 2.5,
              min: 1,
              max: 5,
              step: 0.1,
              decimalPrecision: 1,
              leading: const Icon(Icons.aspect_ratio),
              onChange: (value) {
                debugPrint('\n===== on change =====\n'
                    'key-custom-ratio-slider-2: $value'
                    '\n==========\n');
              },
              onChangeStart: (value) {
                debugPrint('\n===== on change start =====\n'
                    'key-custom-ratio-slider-2: $value'
                    '\n==========\n');
              },
              onChangeEnd: (value) {
                debugPrint('\n===== on change end =====\n'
                    'key-custom-ratio-slider-2: $value'
                    '\n==========\n');
              },
            ),
            ColorPickerSettingsTile(
              settingKey: 'key-color-picker-2',
              title: 'Accent Picker',
              defaultValue: Colors.blue,
              onChange: (value) {
                debugPrint('key-color-picker-2: $value');
              },
            )
          ],
        )
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
