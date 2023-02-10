import 'dart:convert';
import 'dart:io';

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
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../model/services/ble/machine_service.dart';
import 'package:share_plus/share_plus.dart';
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
  FilePickerResult? filePickerResult;
  File? pickedFile;

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
          // Use Builder to get the widget context
          Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () => _onShare(context),
                child: Icon(Icons.ios_share),
              );
            },
          ),

          ElevatedButton(
            child: const Icon(Icons.file_download),
            onPressed: () {
              getProfileFromFolder(context);
            },
          ),
          ElevatedButton(
            child: const Icon(Icons.edit),
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
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
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
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                KeyValueWidget(label: "Notes", value: _selectedProfile!.shotHeader.notes),
                                KeyValueWidget(label: "Beverage", value: _selectedProfile!.shotHeader.beverageType),
                                KeyValueWidget(label: "Type", value: _selectedProfile!.shotHeader.type),
                                KeyValueWidget(
                                    label: "Max Flow", value: _selectedProfile!.shotHeader.maximumFlow.toString()),
                                KeyValueWidget(
                                    label: "Max Pressure",
                                    value: _selectedProfile!.shotHeader.minimumPressure.toString()),
                                KeyValueWidget(
                                    label: "Target Volume",
                                    value: _selectedProfile!.shotHeader.targetVolume.toString()),
                                KeyValueWidget(
                                    label: "Target Weight",
                                    value: _selectedProfile!.shotHeader.targetWeight.toString()),
                              ],
                            )),
                      ),
                    ),
                  ],
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

  getProfileFromFolder(context) async {
    filePickerResult = await FilePicker.platform
        .pickFiles(lockParentWindow: true, type: FileType.custom, allowedExtensions: ["json", "tcl"]);

    if (filePickerResult != null) {
      pickedFile = File(filePickerResult!.files.single.path.toString());
      loadJsonProfile(file: pickedFile!);
    } else {
      // can perform some actions like notification etc
    }
  }

  createSteps() {
    return _selectedProfile!.shotFrames
        .map((p) => KeyValueWidget(
            label: p.name,
            value:
                "Duration: ${p.frameLen} s    ${p.pump == "pressure" ? "Pressure [bar]" : "Flow [ml/s]"}: ${p.setVal}"))
        .toList();
  }

  void profileListener() {
    log.info('Profile updated');
    _selectedProfile = profileService.currentProfile;
    setState(() {});
  }

  loadJsonProfile({required File file}) async {
    try {
      var lines = await file.readAsString();
      var profile = profileService.parseDefaultProfile(lines, false);
      profile.isDefault = false;
      profile.id = const Uuid().v1().toString();
      log.info("Loaded Profile: ${profile.id} ${profile.title}");
      setState(() {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilesEditScreen(profile)),
        );
      });
    } catch (e) {
      log.severe("Error loading profile $e");
    }
  }

  _onShare(BuildContext context) async {
    // _onShare method:
    final box = context.findRenderObject() as RenderBox?;
    // var profileAsString = jsonEncode(_selectedProfile!.toJson());
    var encoder = const JsonEncoder.withIndent("  ");
    var profileAsString = encoder.convert(_selectedProfile!.toJson());
    await Share.share(
      profileAsString,
      subject: _selectedProfile!.title,
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }
}
