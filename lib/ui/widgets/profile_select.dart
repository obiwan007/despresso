// ignore_for_file: constant_identifier_names

import 'package:collection/collection.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/ui/widgets/labeled_checkbox.dart';
// import 'package:dropdown_button2/dropdown_button2.dart';
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
  late TextEditingController searchController;
  late FocusNode searchFocusNode;

  late CoffeeService coffeeService;

  late ProfileService profileService;

  late EspressoMachineService machineService;

  De1ShotProfile? _selectedProfile;
  String _searchQuery = '';
  bool _showSearchResults = false;

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
    searchController = TextEditingController();
    searchFocusNode = FocusNode();

    selectedFilter = settingsService.profileFilterList;
    final filtered = selectedFilter.where(filterOptions.contains).toList();
    if (filtered.length != selectedFilter.length) {
      selectedFilter = filtered;
      settingsService.profileFilterList = selectedFilter;
    }

    _selectedProfile = profileService.currentProfile;
    profileService.addListener(profileListener);
  }

  @override
  dispose() {
    super.dispose();
    profileService.removeListener(profileListener);
    searchController.dispose();
    searchFocusNode.dispose();
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

            bool passesFilterMode = res0 || res1 || res2 || (res3 || res4 || res5);
            
            // Apply search filter
            bool passesSearchFilter = true;
            if (_searchQuery.isNotEmpty) {
              passesSearchFilter = element.shotHeader.title.toLowerCase().contains(_searchQuery.toLowerCase());
            }

            return passesFilterMode && passesSearchFilter;
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search TextField
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search profiles...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          searchController.clear();
                          _searchQuery = '';
                          _showSearchResults = false;
                        });
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _showSearchResults = value.isNotEmpty;
              });
            },
          ),
        ),
        // Show filtered list when searching
        if (_showSearchResults && _searchQuery.isNotEmpty)
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
                color: Theme.of(context).cardColor,
              ),
              child: items.isNotEmpty
                  ? ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final profile = items[index].value!;
                        return ListTile(
                          title: Text("${profile.shotHeader.title}${profile.isDefault ? '' : ' *'}"),
                          selected: _selectedProfile?.id == profile.id,
                          onTap: () {
                            setState(() {
                              _selectedProfile = profile;
                              profileService.setProfile(_selectedProfile!);
                              searchController.clear();
                              _searchQuery = '';
                              _showSearchResults = false;
                              searchFocusNode.unfocus();
                            });
                            if (widget.onChanged != null) {
                              widget.onChanged!(_selectedProfile!);
                            }
                          },
                        );
                      },
                    )
                  : const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No profiles found"),
                    ),
            ),
          ),
        // Existing Row with Dropdown and Filter (only show when not searching)
        if (!_showSearchResults)
          Row(
            children: [
              Expanded(
                child: items.isNotEmpty
                    ? DropdownButton(
                        isExpanded: false,
                        alignment: Alignment.centerLeft,
                        value: _selectedProfile,
                        items: items,
                        // itemHeight: 40,
                        onChanged: (value) {
                          setState(() {
                            _selectedProfile = value!;
                            profileService.setProfile(_selectedProfile!);
                            // Clear search after selection
                            searchController.clear();
                            _searchQuery = '';
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
              SizedBox(width: 50, child: renderFilterDropdown(context, items)),
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: renderFilterDropdown(context, items),
              // ),
            ],
          ),
      ],
    );
  }

  DropdownButtonHideUnderline renderFilterDropdown(BuildContext context, List<DropdownMenuItem<De1ShotProfile>> items) {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
        isExpanded: true,
        iconSize: 15,
        elevation: 16,

        icon: const Icon(Icons.filter_alt),

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
                  width: 100,
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
        value: selectedFilter.isEmpty || !filterOptions.contains(selectedFilter.last) ? null : selectedFilter.last,
        onChanged: (value) {},
        // buttonHeight: 40,
        // buttonWidth: 140,
        // itemHeight: 40,
        // itemPadding: EdgeInsets.zero,
        selectedItemBuilder: (context) {
          return filterOptions.map((_) => const Icon(Icons.filter_alt)).toList();
          // items.map(
          //   (item) {
          //     return Container(
          //       alignment: AlignmentDirectional.center,
          //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
          //       child: Text(
          //         selectedFilter.join(', '),
          //         style: const TextStyle(
          //           fontSize: 14,
          //           overflow: TextOverflow.ellipsis,
          //         ),
          //         maxLines: 1,
          //       ),
          //     );
          //   },
          // ).toList();
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
