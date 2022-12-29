import 'dart:convert';
import 'dart:developer';

import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/shotdecoder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:despresso/ui/theme.dart' as theme;
import '../../model/services/ble/machine_service.dart';
import '../../service_locator.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({Key? key}) : super(key: key);

  @override
  _ProfilesScreenState createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  late ProfileService profileService;

  late EspressoMachineService machineService;

  De1ShotProfile? _selectedProfile = null;
  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    profileService = getIt<ProfileService>();

    profileService.addListener(profileListener);
    log(profileService.currentProfile.toString());
    _selectedProfile = profileService.profiles.first;
  }

  @override
  void dispose() {
    super.dispose();
    // TODO: implement dispose
    machineService.removeListener(profileListener);
    log('Disposed profile');
  }

  @override
  Widget build(BuildContext context) {
    var items = profileService.profiles
        .map((p) => DropdownMenuItem(
              value: p,
              child: Text(p.shot_header.title),
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
      ),
      body: Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 4, // takes 30% of available width
              child: Column(
                children: [
                  DropdownButton(
                      isExpanded: true,
                      alignment: Alignment.centerLeft,
                      value: _selectedProfile,
                      items: items,
                      onChanged: (value) {
                        setState(() {
                          _selectedProfile = value!;
                        });
                      },
                      hint: Text("Select item")),
                  createKeyValue("Notes", _selectedProfile!.shot_header.notes),
                  createKeyValue(
                      "Beverage", _selectedProfile!.shot_header.beverage_type),
                  createKeyValue("Type", _selectedProfile!.shot_header.type),
                  createKeyValue("Max Flow",
                      _selectedProfile!.shot_header.maximumFlow.toString()),
                  createKeyValue("Max Pressure",
                      _selectedProfile!.shot_header.minimumPressure.toString()),
                  createKeyValue("Target Volume",
                      _selectedProfile!.shot_header.target_volume.toString()),
                  createKeyValue("Target Weight",
                      _selectedProfile!.shot_header.target_weight.toString()),
                  ...createSteps(),
                ],
              ),
            ),
            Expanded(
              flex: 6, // takes 30% of available width
              child: ElevatedButton(
                onPressed: () {
                  // Navigate back to first route when tapped.
                },
                child: const Text('Go back!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Row createKeyValue(String key, String value) {
    return Row(
      children: [
        Expanded(flex: 3, child: Text(key, style: theme.TextStyles.tabLabel)),
        Expanded(
          flex: 7,
          child: Text(value, style: theme.TextStyles.tabLabel),
        ),
      ],
    );
  }

  createSteps() {
    return _selectedProfile!.shot_frames
        .map((p) => createKeyValue(p.frameToWrite.toString(), p.name))
        .toList();
  }

  void profileListener() {
    log('Profile updated');
  }
}
