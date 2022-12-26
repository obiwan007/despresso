import 'package:despresso/model/services/state/machine_service.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:flutter_typeahead/flutter_typeahead.dart';

class MachineSelection {}

class MachineSelectionTab extends StatefulWidget {
  @override
  _MachineSelectionTabState createState() => _MachineSelectionTabState();
}

class _MachineSelectionTabState extends State<MachineSelectionTab> {
  final TextEditingController _typeAheadManufacturerController =
      TextEditingController();
  final TextEditingController _typeAheadModelController =
      TextEditingController();

  late String _selectedManufacturer;
  //String _selectedModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 95.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TypeAheadFormField(
            textFieldConfiguration: TextFieldConfiguration(
              decoration: InputDecoration(
                labelText: 'Manufacturer',
                labelStyle: theme.TextStyles.tabLabel,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
              style: theme.TextStyles.tabPrimary,
              controller: _typeAheadManufacturerController,
            ),
            suggestionsCallback: (pattern) async {
              return MachineService.getVendorSuggestions(pattern);
            },
            itemBuilder: (context, suggestion) {
              return ListTile(
                title: Text(suggestion),
              );
            },
            transitionBuilder: (context, suggestionsBox, controller) {
              return suggestionsBox;
            },
            onSuggestionSelected: (suggestion) {
              _typeAheadManufacturerController.text = suggestion;
              _selectedManufacturer = suggestion;
            },
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please select a manufacturer';
              }
              return null;
            },
            onSaved: (value) => _selectedManufacturer = value!,
          ),
          TypeAheadFormField(
            textFieldConfiguration: TextFieldConfiguration(
                decoration: InputDecoration(
                  labelText: 'Model',
                  labelStyle: theme.TextStyles.tabLabel,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
                controller: _typeAheadModelController,
                style: theme.TextStyles.tabSecondary),
            suggestionsCallback: (pattern) async {
              return MachineService.getModellSuggestions(
                  pattern, _selectedManufacturer);
            },
            itemBuilder: (context, suggestion) {
              return ListTile(
                title: Text(suggestion),
              );
            },
            transitionBuilder: (context, suggestionsBox, controller) {
              return suggestionsBox;
            },
            onSuggestionSelected: (suggestion) {
              _typeAheadModelController.text = suggestion;
              //this._selectedModel = suggestion;
            },
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please select a model';
              }
              return null;
            },
            //onSaved: (value) => this._selectedModel = value,
          ),
          Container(
              color: theme.Colors.backgroundColor,
              width: 24.0,
              height: 1.0,
              margin: const EdgeInsets.symmetric(vertical: 8.0)),
        ],
      ),
    );
  }
}
