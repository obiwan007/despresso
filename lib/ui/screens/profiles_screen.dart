import 'dart:developer';

import 'package:despresso/model/services/state/profile_service.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    profileService = getIt<ProfileService>();

    profileService.addListener(profileListener);
    log(profileService.currentProfile.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate back to first route when tapped.
          },
          child: const Text('Go back!'),
        ),
      ),
    );
  }

  void profileListener() {
    log('Profile updated');
  }
}
