// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/ui/widgets/key_value.dart';
import 'package:despresso/ui/widgets/labeled_checkbox.dart';
import 'package:despresso/ui/widgets/profile_graph.dart';
import 'package:despresso/ui/widgets/selectable_steps.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:logging/logging.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../../model/services/ble/machine_service.dart';
import 'package:share_plus/share_plus.dart';
import '../../service_locator.dart';
import './profiles_edit_screen.dart';
import './profiles_d-flow_edit_screen.dart';
import './profiles_advanced_edit_screen.dart';

enum FilterModes {
  Mine,
  Default,
  Hidden,
  Favorites,
  Flow,
  Pressure,
  Advanced,
}

class ProfilesScreen extends StatefulWidget {
  bool saveToRecipe = false;
  ProfilesScreen({Key? key, required this.saveToRecipe}) : super(key: key);

  @override
  ProfilesScreenState createState() => ProfilesScreenState();
}

class ProfilesScreenState extends State<ProfilesScreen> {
  final log = Logger('ProfilesScreenState');

  late ProfileService profileService;
  late EspressoMachineService machineService;
  late TextEditingController shortCodeController;
  late CoffeeService coffeeService;
  late SettingsService settingsService;

  De1ShotProfile? _selectedProfile;
  FilePickerResult? filePickerResult;
  File? pickedFile;

  List<String> filterOptions = [
    FilterModes.Mine.name,
    FilterModes.Default.name,
    FilterModes.Hidden.name,
    FilterModes.Flow.name,
    FilterModes.Pressure.name,
    FilterModes.Advanced.name,
  ];

  List<String> selectedFilter = [
    FilterModes.Mine.name,
    FilterModes.Default.name,
  ];

  int _selectedPhase = -1;

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    profileService = getIt<ProfileService>();
    coffeeService = getIt<CoffeeService>();
    settingsService = getIt<SettingsService>();
    shortCodeController = TextEditingController();

    selectedFilter = settingsService.profileFilterList;

    profileService.addListener(profileListener);
    log.info(profileService.currentProfile.toString());
    _selectedProfile = profileService.currentProfile;
  }

  @override
  void dispose() {
    super.dispose();

    if (widget.saveToRecipe) coffeeService.setSelectedRecipeProfile(_selectedProfile?.id ?? "Default");

    profileService.removeListener(profileListener);
    log.info('Disposed profile');
  }

  @override
  Widget build(BuildContext context) {
    var showHidden = selectedFilter.contains(FilterModes.Hidden.name);
    var showDefault = selectedFilter.contains(FilterModes.Default.name);
    var showOnlyMine = selectedFilter.contains(FilterModes.Mine.name);
    var showFlow = selectedFilter.contains(FilterModes.Flow.name);
    var showPressure = selectedFilter.contains(FilterModes.Pressure.name);
    var showAdvanced = selectedFilter.contains(FilterModes.Advanced.name);

    var items = profileService.profiles
        .where(
          (element) {
            bool res1 = false;
            bool res2 = false;
            bool res3 = false;
            bool res4 = false;
            bool res5 = false;
            bool res0 = true;

            if (showDefault) res1 = element.shotHeader.hidden == 0;
            if (showHidden) res2 = element.shotHeader.hidden == 1;
            if (showFlow) res3 = element.shotHeader.type == 'flow';
            if (showPressure) res4 = element.shotHeader.type == 'pressure';
            if (showAdvanced) res5 = element.shotHeader.type == 'advanced';

            if (showOnlyMine) res0 = element.isDefault == false;

            return res0 || res1 || res2 || (res3 || res4 || res5);
          },
        )
        .map((p) => DropdownMenuItem(
              value: p,
              child: Text("${p.shotHeader.title} ${p.isDefault ? '' : ' *'}"),
            ))
        .toList()
        .sortedBy((element) => element.value?.title ?? "");
    // Check if we need to fallback
    if (_selectedProfile != null &&
        null ==
            items.firstWhereOrNull(
              (element) {
                return element.value!.id == (_selectedProfile?.id ?? "Default");
              },
            )) {
      if (items.isNotEmpty) _selectedProfile = items[0].value;
    }
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.pop(context, _selectedProfile),
        ),
        title: const Text('Profiles'),
        actions: <Widget>[
          if (_selectedProfile!.isDefault == false)
            TextButton.icon(
              icon: const Icon(Icons.delete),
              label: Text("Delete"),
              onPressed: () async {
                try {
                  await profileService.delete(_selectedProfile!);
                } catch (e) {
                  var snackBar = SnackBar(
                      content: Text("Error deleting profile: $e"),
                      action: SnackBarAction(
                        label: '',
                        onPressed: () {
                          // Some code to undo the change.
                        },
                      ));
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  log.severe("Error deleting profile $e");
                }
              },
            ),
          // Use Builder to get the widget context
          Builder(
            builder: (BuildContext context) {
              return TextButton.icon(
                label: Text("Share"),
                onPressed: () => _onShare(context),
                icon: const Icon(Icons.ios_share),
              );
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.cloud_download),
            label: Text("visualizer code"),
            onPressed: () async {
              final shortCode = await _openShortCodeDialog();
              if (shortCode == null || shortCode.isEmpty) return;

              try {
                var profile = await profileService.getJsonProfileFromVisualizerShortCode(shortCode);
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
                var snackBar = SnackBar(
                    content: Text("Error loading profile: $e"),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        // Some code to undo the change.
                      },
                    ));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                log.severe("Error loading profile $e");
              }
            },
          ),

          TextButton.icon(
            label: Text("Import json"),
            icon: const Icon(Icons.file_download),
            onPressed: () {
              getProfileFromFolder(context);
            },
          ),
          TextButton.icon(
            label: Text("Edit"),
            icon: const Icon(Icons.edit),
            onPressed: () {
              setState(() {
                if (_selectedProfile!.shotHeader.type == "advanced") {
                  if (_selectedProfile!.title.startsWith("D-Flow")) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DFlowEditScreen(_selectedProfile!.clone())),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdvancedProfilesEditScreen(_selectedProfile!.clone())),
                    );
                  }
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilesEditScreen(_selectedProfile!.clone())),
                  );
                }
              });
            },
          ),
        ],
      ),
      body: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                flex: 4, // takes 30% of available width
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: items.isNotEmpty
                                ? DropdownButton(
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
                                    hint: const Text("Select item"))
                                : const Text("No profiles found for selection"),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: renderFilterDropdown(context, items),
                          ),
                        ],
                      ),
                      if (items.isNotEmpty)
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: (_selectedProfile != null)
                                  ? Column(
                                      children: [
                                        KeyValueWidget(label: "Notes", value: _selectedProfile?.shotHeader.notes ?? ""),
                                        KeyValueWidget(
                                            label: "Beverage", value: _selectedProfile?.shotHeader.beverageType ?? ""),
                                        KeyValueWidget(label: "Type", value: _selectedProfile?.shotHeader.type ?? ""),
                                        KeyValueWidget(
                                            label: "Max Flow",
                                            value: _selectedProfile?.shotHeader.maximumFlow.toString() ?? ""),
                                        KeyValueWidget(
                                            label: "Max Pressure",
                                            value: _selectedProfile?.shotHeader.minimumPressure.toString() ?? ""),
                                        KeyValueWidget(
                                            label: "Target Volume",
                                            value: _selectedProfile?.shotHeader.targetVolume.toString() ?? ""),
                                        KeyValueWidget(
                                            label: "Target Weight",
                                            value: _selectedProfile?.shotHeader.targetWeight.toString() ?? ""),
                                      ],
                                    )
                                  : const Text("Nothing selected"),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 6, // takes 30% of available width
                child: !items.isNotEmpty
                    ? Container()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: _selectedProfile != null
                                ? ProfileGraphWidget(
                                    key: UniqueKey(),
                                    selectedProfile: _selectedProfile!,
                                    selectedPhase: _selectedPhase,
                                  )
                                : Text("nothing selected"),
                          ),
                          Expanded(
                            flex: 6,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 8,
                                    child: _selectedProfile != null
                                        ? SelectableSteps(
                                            profile: _selectedProfile!,
                                            selected: _selectedPhase,
                                            isEditable: false,
                                            onSelected: (p0) {
                                              _selectedPhase = p0;
                                              setState(() {});
                                            },
                                          )
                                        : Text(""),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.add),
                                          onPressed: () async {
                                            var messenger = ScaffoldMessenger.of(context);
                                            Text result;
                                            try {
                                              var r = await machineService.uploadProfile(_selectedProfile!);
                                              result = Text('Profile is selected: $r');
                                            } catch (e) {
                                              result = Text('Profile is not selected: $e');
                                            }

                                            var snackBar = SnackBar(
                                                content: result,
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
      ),
    );
  }

  DropdownButtonHideUnderline renderFilterDropdown(BuildContext context, List<DropdownMenuItem<De1ShotProfile>> items) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2(
        isExpanded: false, customButton: const Icon(Icons.filter_alt),
        dropdownWidth: 160,

        // hint: Align(
        //   alignment: AlignmentDirectional.center,
        //   child: Text(
        //     '',
        //     style: TextStyle(
        //       fontSize: 14,
        //       color: Theme.of(context).hintColor,
        //     ),
        //   ),
        // ),
        items: filterOptions.map((item) {
          return DropdownMenuItem<String>(
            value: item,

            //disable default onTap to avoid closing menu when selecting an item
            enabled: false,
            child: StatefulBuilder(
              builder: (context, menuSetState) {
                final isSelected = selectedFilter.contains(item);
                return Container(
                  height: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      LabeledCheckbox(
                        value: isSelected,
                        label: item,
                        onChanged: (value) {
                          !value! ? selectedFilter.remove(item) : selectedFilter.add(item);
                          settingsService.profileFilterList = selectedFilter;
                          setState(() {});
                          menuSetState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }).toList(),
        //Use last selected item as the current value so if we've limited menu height, it scroll to last item.
        value: selectedFilter.isEmpty ? null : selectedFilter.last,
        onChanged: (value) {},
        buttonHeight: 40,
        buttonWidth: 140,
        itemHeight: 40,
        itemPadding: EdgeInsets.zero,
        selectedItemBuilder: (context) {
          return items.map(
            (item) {
              return Container(
                alignment: AlignmentDirectional.center,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  selectedFilter.join(', '),
                  style: const TextStyle(
                    fontSize: 14,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              );
            },
          ).toList();
        },
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

  List<KeyValueWidget> createSteps() {
    return _selectedProfile == null
        ? []
        : _selectedProfile!.shotFrames
            .map((p) => KeyValueWidget(
                label: p.name,
                value:
                    "Duration: ${p.frameLen} s    ${p.pump == "pressure" ? "Pressure [bar]" : "Flow [ml/s]"}: ${p.setVal.toStringAsFixed(1)}"))
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
    log.info("Share profile $_selectedProfile");
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

  Future<String?> _openShortCodeDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Visualizer Profile Import'),
          content: TextField(
            autofocus: true,
            controller: shortCodeController,
            decoration: const InputDecoration(hintText: '4-digit visualizer short code'),
            maxLength: 4,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Import'),
              onPressed: () {
                Navigator.of(context).pop(shortCodeController.text);
                shortCodeController.clear();
              },
            ),
          ],
        );
      },
    );
  }
}
