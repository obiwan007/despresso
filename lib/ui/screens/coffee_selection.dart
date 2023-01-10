import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'package:reactive_forms/reactive_forms.dart';

import '../../model/coffee.dart';
import '../../model/services/ble/machine_service.dart';

class CoffeeSelection {
  Widget getTabContent() {
    return CoffeeSelectionTab();
  }
}

class CoffeeSelectionTab extends StatefulWidget {
  @override
  _CoffeeSelectionTabState createState() => _CoffeeSelectionTabState();
}

enum EditModes { show, add, edit }

class _CoffeeSelectionTabState extends State<CoffeeSelectionTab> {
  final _formKeyRoaster = GlobalKey<FormState>();
  final TextEditingController _typeAheadRoasterController = TextEditingController();
  final TextEditingController _typeAheadCoffeeController = TextEditingController();

  Roaster newRoaster = Roaster();
  late Roaster _selectedRoaster;
  late Coffee? _selectedCoffee = null;
  //String _selectedCoffee;

  late CoffeeService coffeeService;
  late EspressoMachineService machineService;

  EditModes _editMode = EditModes.show;

  List<DropdownMenuItem<Roaster>> roasters = [];

  Roaster _editedRoaster = Roaster();

  FormGroup get form => fb.group(<String, Object>{
        'name': ['', Validators.required],
        'description': [''],
        'address': [''],
        'homepage': [''],
        'id': [''],
      });

  _CoffeeSelectionTabState() {
    newRoaster.name = "<new roaster>";
    newRoaster.id = "new";
    _selectedRoaster = newRoaster;
  }

  @override
  void initState() {
    super.initState();
    coffeeService = getIt<CoffeeService>();
    machineService = getIt<EspressoMachineService>();
    coffeeService.addListener(updateCoffee);
    updateCoffee();
  }

  @override
  void dispose() {
    super.dispose();
    coffeeService.removeListener(updateCoffee);
    log('Disposed coffeeselection');
  }

  @override
  Widget build(BuildContext context) {
    var coffees = coffeeService.knownCoffees
        .map((p) => DropdownMenuItem(
              value: p,
              child: Text("${p.name}"),
            ))
        .toList();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addCoffee();
        },
        // backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: ReactiveFormBuilder(
        form: () => form,
        builder: (context, form, child) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("Select Roaster"),
              DropdownButton(
                isExpanded: true,
                alignment: Alignment.centerLeft,
                value: _selectedRoaster,
                items: roasters,
                onChanged: (value) {
                  setState(() {
                    log("Form ${form.value}");
                    _selectedRoaster = value!;
                    if (value!.id == "new") {
                      _editedRoaster = Roaster();

                      form.value = _editedRoaster.toJson();
                      _editMode = EditModes.add;
                    } else {}
                    // form.value = {"name": _selectedRoaster.name};
                    // form.control('name').value = 'John';
                    log("Form ${form.value}");
                  });
                },
              ),
              _editMode != EditModes.show ? roasterForm(form) : roasterData(form),
              Spacer(),
              Text("Select Coffee"),
              DropdownButton(
                isExpanded: true,
                alignment: Alignment.centerLeft,
                value: _selectedCoffee,
                items: coffees,
                onChanged: (value) {
                  setState(() {
                    _selectedCoffee = value!;
                  });
                },
              ),
              Container(
                  color: theme.Colors.backgroundColor,
                  width: 24.0,
                  height: 1.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0)),
              Row(
                children: <Widget>[
                  const Icon(Icons.location_on, size: 14.0, color: theme.Colors.goodColor),
                  Text(
                    "${_selectedCoffee?.origin ?? 'unknown'}",
                    style: theme.TextStyles.tabTertiary,
                  ),
                  Container(width: 24.0),
                  const Icon(Icons.flight_land, size: 14.0, color: theme.Colors.goodColor),
                  Text("${_selectedCoffee?.price}", style: theme.TextStyles.tabTertiary),
                ],
              ),
            ],
          ),
        ),
      )!,
    );
  }

  List<DropdownMenuItem<Roaster>> loadRoasters() {
    var roasters = coffeeService.knownRoasters
        .map((p) => DropdownMenuItem(
              value: p,
              child: Text("${p.name}"),
            ))
        .toList();
    roasters.insert(0, DropdownMenuItem(value: newRoaster, child: Text("${newRoaster.name}")));
    return roasters;
  }

  Future<void> addCoffee() async {
    var r = Roaster();
    r.name = "Bärista";
    r.description = "Small little company in the middle of Berlin";
    r.address = "Franklinstr. 21, Berlin";
    r.homepage = "https://www.google.com";
    await coffeeService.addRoaster(r);
    var c = Coffee();
    c.roasterId = r.id;
    c.name = "Bärige Mischung";
    c.acidRating = 5;
    c.arabica = 50;
    c.robusta = 50;
    c.grinderSettings = 10;
    c.description = "Cheap supermarket coffee";
    c.intensityRating = 5;
    c.roastLevel = 5;
    c.price = "20€";
    c.origin = "Columbia";
    await coffeeService.addCoffee(c);
  }

  roasterData(FormGroup form) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        createKeyValue("Name", _selectedRoaster.name),
        if (_selectedRoaster.description.isNotEmpty) createKeyValue("Description", _selectedRoaster.description),
        if (_selectedRoaster.homepage.isNotEmpty) createKeyValue("Homepage", _selectedRoaster.homepage),
        if (_selectedRoaster.address.isNotEmpty) createKeyValue("Address", _selectedRoaster.address),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _editMode = EditModes.edit;
              _editedRoaster = _selectedRoaster;
              form.value = _editedRoaster.toJson();
            });
          },
          child: const Text('EDIT'),
        ),
      ],
    );
  }

  Widget createKeyValue(String key, String value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(key, style: theme.TextStyles.tabHeading),
          Text(value, style: theme.TextStyles.tabPrimary),
        ],
      ),
    );
  }

  roasterForm(FormGroup form) {
    return Column(
      children: [
        ReactiveTextField<String>(
          formControlName: 'name',
          decoration: const InputDecoration(
            labelText: 'Name',
          ),
          validationMessages: {
            ValidationMessage.required: (_) => 'Name must not be empty',
          },
        ),
        ReactiveTextField<String>(
          formControlName: 'description',
          decoration: const InputDecoration(
            labelText: 'Description',
          ),
        ),
        ReactiveTextField<String>(
          formControlName: 'address',
          decoration: const InputDecoration(
            labelText: 'Address',
          ),
        ),
        ReactiveTextField<String>(
          formControlName: 'homepage',
          decoration: const InputDecoration(
            labelText: 'Homepage',
          ),
        ),
        ReactiveFormConsumer(
          builder: (context, form, child) {
            return ElevatedButton(
              onPressed: form.valid
                  ? () {
                      log("${form.value}");
                      _editedRoaster = Roaster.fromJson(form.value);
                      if (_editMode == EditModes.add) {
                        coffeeService.addRoaster(_editedRoaster);
                      } else {
                        coffeeService.updateRoaster(_editedRoaster);
                      }
                      _selectedRoaster = _editedRoaster;
                      _editMode = EditModes.show;
                    }
                  : null,
              child: const Text('SAVE'),
            );
          },
        ),
        ElevatedButton(
          onPressed: () {
            form.reset();
            setState(() {
              _editMode = EditModes.show;
            });
          },
          child: const Text('CANCEL'),
        ),
      ],
    );
  }

  void updateCoffee() {
    setState(
      () {
        roasters = loadRoasters();
      },
    );
  }
}
