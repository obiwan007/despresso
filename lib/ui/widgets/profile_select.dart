// ignore_for_file: constant_identifier_names

import 'package:collection/collection.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/ui/widgets/labeled_checkbox.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../service_locator.dart';

enum FilterModes {
  Mine,
  Default,
  Hidden,
  Favorites,
  Flow,
  Pressure,
  Advanced,
}

class ProfileSelect extends StatefulWidget {
  const ProfileSelect({Key? key, this.onChanged}) : super(key: key);

  final void Function(De1ShotProfile)? onChanged;

  @override
  ProfileSelectState createState() => ProfileSelectState();
}

class ProfileSelectState extends State<ProfileSelect> {
  final log = Logger('ProfileSelect');

  late SettingsService settingsService;

  late TextEditingController shortCodeController;

  late CoffeeService coffeeService;

  late ProfileService profileService;

  late EspressoMachineService machineService;

  De1ShotProfile? _selectedProfile;

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

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();
    profileService = getIt<ProfileService>();
    coffeeService = getIt<CoffeeService>();
    settingsService = getIt<SettingsService>();
    shortCodeController = TextEditingController();

    selectedFilter = settingsService.profileFilterList;

    _selectedProfile = profileService.currentProfile;
    profileService.addListener(profileListener);
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

    return Row(
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
                    if (widget.onChanged != null) {
                      widget.onChanged!(_selectedProfile!);
                    }
                  },
                  hint: const Text("Select item"))
              : const Text("No profiles found for selection"),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: renderFilterDropdown(context, items),
        ),
      ],
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

  void profileListener() {
    log.info('Profile updated');
    _selectedProfile = profileService.currentProfile;
    setState(() {});
  }
}
