import 'package:despresso/generated/l10n.dart';
import 'package:despresso/model/coffee.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'package:reactive_forms/reactive_forms.dart';

import '../../model/services/ble/machine_service.dart';

class RoasterEdit extends StatefulWidget {
  const RoasterEdit(this.selectedRoasterId, {super.key});
  final int selectedRoasterId;

  @override
  RoasterEditState createState() => RoasterEditState();
}

enum EditModes { show, add, edit }

class RoasterEditState extends State<RoasterEdit> {
  final log = Logger('RoasterEditState');

  int _selectedRoasterId = 0;

  late CoffeeService coffeeService;
  late EspressoMachineService machineService;

  Roaster _editedRoaster = Roaster();
  late int selectedRoasterId;

  FormGroup? currentForm;

  FormGroup get theForm2 => fb.group(<String, Object>{
        'name': ['test', Validators.required],
        'description': [''],
        'address': [''],
        'homepage': [''],
        'id': [0],
      });

  late FormGroup theForm;

  RoasterEditState();

  @override
  void initState() {
    super.initState();
    selectedRoasterId = widget.selectedRoasterId;
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
    log.info('Disposed coffeeselection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).screenRoasterEditTitle),
        actions: <Widget>[
          ElevatedButton(
            child: Text(
              S.of(context).save,
            ),
            onPressed: () {
              if (currentForm != null && currentForm!.valid) {
                setState(() {
                  log.info("${currentForm!.value}");
                  saveFormData(currentForm!);
                  Navigator.pop(context);
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ReactiveFormBuilder(
          form: () => theForm,
          builder: (context, form, child) {
            currentForm = form;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  roasterForm(form),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  roasterForm(FormGroup form) {
    return Column(
      children: [
        ReactiveTextField<String>(
          formControlName: 'name',
          decoration: InputDecoration(
            labelText: S.of(context).screenRoasterEditNameOfRoaster,
          ),
          validationMessages: {
            ValidationMessage.required: (_) => S.of(context).validatorNotBeEmpty,
          },
        ),
        ReactiveTextField<String>(
          formControlName: 'description',
          decoration: InputDecoration(
            labelText: S.of(context).screenRoasterEditDescription,
          ),
        ),
        ReactiveTextField<String>(
          formControlName: 'address',
          decoration: InputDecoration(
            labelText: S.of(context).screenRoasterEditAddress,
          ),
        ),
        ReactiveTextField<String>(
          formControlName: 'homepage',
          decoration: InputDecoration(
            labelText: S.of(context).screenRoasterEditHomepage,
          ),
        ),
        // ReactiveFormConsumer(
        //   builder: (context, form, child) {
        //     return ElevatedButton(
        //       onPressed: form.valid
        //           ? () {
        //               log.info("${form.value}");
        //               saveFormData(form);
        //               Navigator.pop(context);
        //             }
        //           : null,
        //       child: const Text('SAVE'),
        //     );
        //   },
        // ),
        // ElevatedButton(
        //   onPressed: () {
        //     form.reset();
        //     Navigator.pop(context);
        //   },
        //   child: const Text('CANCEL'),
        // ),
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
