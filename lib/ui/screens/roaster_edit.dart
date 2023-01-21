import 'dart:developer';

import 'package:despresso/model/coffee.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';

import 'package:reactive_forms/reactive_forms.dart';

import '../../model/services/ble/machine_service.dart';

class RoasterEdit extends StatefulWidget {
  RoasterEdit(this.selectedRoasterId, {super.key});
  int selectedRoasterId;

  @override
  RoasterEditState createState() => RoasterEditState(selectedRoasterId);
}

enum EditModes { show, add, edit }

class RoasterEditState extends State<RoasterEdit> {
  int _selectedRoasterId = 0;

  late CoffeeService coffeeService;
  late EspressoMachineService machineService;

  Roaster _editedRoaster = Roaster();
  int selectedRoasterId;

  FormGroup get theForm2 => fb.group(<String, Object>{
        'name': ['test', Validators.required],
        'description': [''],
        'address': [''],
        'homepage': [''],
        'id': [0],
      });

  late FormGroup theForm;

  RoasterEditState(this.selectedRoasterId);

  @override
  void initState() {
    super.initState();
    coffeeService = getIt<CoffeeService>();
    machineService = getIt<EspressoMachineService>();
    coffeeService.addListener(updateCoffee);

    if (selectedRoasterId > 0) {
      _editedRoaster = coffeeService.roasterBox.get(selectedRoasterId)!;
    } else {
      _editedRoaster = Roaster();
    }

    theForm = fb.group(<String, Object>{
      'name': [_editedRoaster.name, Validators.required],
      'description': [_editedRoaster.description],
      'address': [_editedRoaster.address],
      'homepage': [_editedRoaster.homepage],
      'id': [_editedRoaster.id],
    });
  }

  @override
  void dispose() {
    super.dispose();
    coffeeService.removeListener(updateCoffee);
    log('Disposed coffeeselection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Roaster'),
        actions: <Widget>[
          ElevatedButton(
            child: const Text(
              'Save',
            ),
            onPressed: () {
              setState(() {
                Navigator.pop(context);
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ReactiveFormBuilder(
          form: () => theForm,
          builder: (context, form, child) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                roasterForm(form),
              ],
            ),
          ),
        ),
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
                      saveFormData(form);
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text('SAVE'),
            );
          },
        ),
        ElevatedButton(
          onPressed: () {
            form.reset();
            Navigator.pop(context);
          },
          child: const Text('CANCEL'),
        ),
      ],
    );
  }

  void saveFormData(FormGroup form) {
    _editedRoaster.name = form.value["name"] as String;
    _editedRoaster.address = form.value["address"] as String;
    _editedRoaster.description = form.value["description"] as String;
    _editedRoaster.homepage = form.value["homepage"] as String;
    coffeeService.addRoaster(_editedRoaster);
    _selectedRoasterId = _editedRoaster.id;
    coffeeService.setSelectedRoaster(_selectedRoasterId);
  }

  void updateCoffee() {
    setState(
      () {},
    );
  }
}
