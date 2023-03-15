// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/ui/widgets/key_value.dart';
import 'package:despresso/ui/widgets/labeled_checkbox.dart';
import 'package:despresso/ui/widgets/profile_graph.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:logging/logging.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../../model/services/ble/machine_service.dart';
import 'package:share_plus/share_plus.dart';
import '../../service_locator.dart';
import './profiles_edit_screen.dart';

enum FilterModes {
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

  De1ShotProfile? _selectedProfile;
  FilePickerResult? filePickerResult;
  File? pickedFile;

  List<String> filterOptions = [
    FilterModes.Default.name,
    FilterModes.Hidden.name,
    FilterModes.Flow.name,
    FilterModes.Pressure.name,
    FilterModes.Advanced.name,
  ];

  List<String> selectedFilter = [
    FilterModes.Default.name,
  ];

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    profileService = getIt<ProfileService>();
    coffeeService = getIt<CoffeeService>();
    shortCodeController = TextEditingController();

    profileService.addListener(profileListener);
    log.info(profileService.currentProfile.toString());
    _selectedProfile = profileService.currentProfile;
  }

  @override
  void dispose() {
    super.dispose();

    if (widget.saveToRecipe) coffeeService.setSelectedRecipeProfile(_selectedProfile!.id);

    machineService.removeListener(profileListener);
    log.info('Disposed profile');
  }

  @override
  Widget build(BuildContext context) {
    var showHidden = selectedFilter.contains(FilterModes.Hidden.name);
    var showDefault = selectedFilter.contains(FilterModes.Default.name);
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

            if (showDefault) res1 = element.shotHeader.hidden == 0;
            if (showHidden) res2 = element.shotHeader.hidden == 1;
            if (showFlow) res3 = element.shotHeader.type == 'flow';
            if (showPressure) res4 = element.shotHeader.type == 'pressure';
            if (showAdvanced) res5 = element.shotHeader.type == 'advanced';

            return res1 || res2 || (res3 || res4 || res5);
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
                return element.value!.id == _selectedProfile!.id;
              },
            )) {
      if (items.isNotEmpty) _selectedProfile = items[0].value;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
        actions: <Widget>[
          // Use Builder to get the widget context
          Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () => _onShare(context),
                child: const Icon(Icons.ios_share),
              );
            },
          ),
          ElevatedButton(
            child: const Icon(Icons.cloud_download),
            onPressed: () async {
              final shortCode = await _openShortCodeDiaglog();
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
                                ? ProfileGraphWidget(key: UniqueKey(), selectedProfile: _selectedProfile!)
                                : Text("nothing selected"),
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

  Future<String?> _openShortCodeDiaglog() async {
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
