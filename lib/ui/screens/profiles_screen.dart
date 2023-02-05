import 'package:despresso/logger_util.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:despresso/ui/widgets/key_value.dart';
import 'package:despresso/ui/widgets/profile_graph.dart';
import 'package:flutter/material.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:despresso/ui/theme.dart' as theme;
import 'package:logging/logging.dart';
import '../../model/services/ble/machine_service.dart';
import '../../service_locator.dart';
import './profiles_edit_screen.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({Key? key}) : super(key: key);

  @override
  ProfilesScreenState createState() => ProfilesScreenState();
}

class ProfilesScreenState extends State<ProfilesScreen> {
  final log = Logger('ProfilesScreenState');

  late ProfileService profileService;

  late EspressoMachineService machineService;

  De1ShotProfile? _selectedProfile;

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    profileService = getIt<ProfileService>();

    profileService.addListener(profileListener);
    log.info(profileService.currentProfile.toString());
    _selectedProfile = profileService.currentProfile;
  }

  @override
  void dispose() {
    super.dispose();

    machineService.removeListener(profileListener);
    log.info('Disposed profile');
  }

  @override
  Widget build(BuildContext context) {
    var items = profileService.profiles
        .map((p) => DropdownMenuItem(
              value: p,
              child: Text("${p.shotHeader.title} ${p.isDefault ? '' : ' *'}"),
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
        actions: <Widget>[
          ElevatedButton(
            child: const Text(
              'Edit',
            ),
            onPressed: () {
              setState(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilesEditScreen(_selectedProfile!.clone())),
                );
              });
            },
          ),
        ],
      ),
      body: Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 4, // takes 30% of available width
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButton(
                          isExpanded: true,
                          alignment: Alignment.centerLeft,
                          value: _selectedProfile,
                          items: items,
                          onChanged: (value) {
                            setState(() {
                              _selectedProfile = value!;
                              profileService.setProfile(_selectedProfile!);
                              // calcProfileGraph();
                              // phases = _createPhases();
                            });
                          },
                          hint: const Text("Select item")),
                      KeyValueWidget(label: "Notes", value: _selectedProfile!.shotHeader.notes),
                      KeyValueWidget(label: "Beverage", value: _selectedProfile!.shotHeader.beverageType),
                      KeyValueWidget(label: "Type", value: _selectedProfile!.shotHeader.type),
                      KeyValueWidget(label: "Max Flow", value: _selectedProfile!.shotHeader.maximumFlow.toString()),
                      KeyValueWidget(
                          label: "Max Pressure", value: _selectedProfile!.shotHeader.minimumPressure.toString()),
                      KeyValueWidget(
                          label: "Target Volume", value: _selectedProfile!.shotHeader.targetVolume.toString()),
                      KeyValueWidget(
                          label: "Target Weight", value: _selectedProfile!.shotHeader.targetWeight.toString()),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 6, // takes 30% of available width
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: ProfileGraphWidget(key: UniqueKey(), selectedProfile: _selectedProfile!),
                  ),
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...createSteps(),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add),
                                  onPressed: () async {
                                    var messenger = ScaffoldMessenger.of(context);
                                    var result = await machineService.uploadProfile(_selectedProfile!);

                                    var snackBar = SnackBar(
                                        content: Text('Profile is selected: $result'),
                                        action: SnackBarAction(
                                          label: 'Ok',
                                          onPressed: () {
                                            // Some code to undo the change.
                                          },
                                        ));

                                    messenger.showSnackBar(snackBar);
                                  },
                                  label: const Text(
                                    "Save to Decent",
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  createSteps() {
    return _selectedProfile!.shotFrames
        .map((p) => KeyValueWidget(label: p.name, value: "Duration: ${p.frameLen} s    Pressure: ${p.setVal} bar"))
        .toList();
  }

  void profileListener() {
    log.info('Profile updated');
    _selectedProfile = profileService.currentProfile;
  }
}
