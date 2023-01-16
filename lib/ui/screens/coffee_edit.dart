import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:despresso/model/coffee.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:reactive_flutter_rating_bar/reactive_flutter_rating_bar.dart';

import 'package:reactive_forms/reactive_forms.dart';

import '../../model/coffee.dart';
import '../../model/services/ble/machine_service.dart';

class CoffeeEdit extends StatefulWidget {
  CoffeeEdit(int this.selectedCoffeeId);
  int selectedCoffeeId;

  @override
  _CoffeeEditState createState() => _CoffeeEditState(selectedCoffeeId);
}

enum EditModes { show, add, edit }

class _CoffeeEditState extends State<CoffeeEdit> {
  late CoffeeService coffeeService;
  late EspressoMachineService machineService;

  Coffee _editedCoffee = Coffee();
  int selectedCoffeeId = 0;

  FormGroup get theForm2 => fb.group(<String, Object>{
        'name': ['test', Validators.required],
        'description': [''],
        'type': [''],
        'price': [''],
        'taste': [''],
        'origin': [''],
        'intensityRating': [0.1],
        'acidRating': [0.1],
        'grinderSettings': [0.1],
        'roastLevel': [0.1],
      });

  late FormGroup theForm;

  _CoffeeEditState(this.selectedCoffeeId);

  @override
  void initState() {
    super.initState();
    coffeeService = getIt<CoffeeService>();
    machineService = getIt<EspressoMachineService>();
    coffeeService.addListener(updateCoffee);

    if (selectedCoffeeId > 0) {
      _editedCoffee = coffeeService.coffeeBox.get(selectedCoffeeId)!;
    } else {
      _editedCoffee = Coffee();
    }

    theForm = fb.group(<String, Object>{
      'name': [_editedCoffee.name, Validators.required],
      'description': [_editedCoffee.description],
      'type': [_editedCoffee.type],
      'price': [_editedCoffee.price],
      'taste': [_editedCoffee.taste],
      'origin': [_editedCoffee.origin],
      'intensityRating': [_editedCoffee.intensityRating],
      'acidRating': [_editedCoffee.acidRating],
      'grinderSettings': [_editedCoffee.grinderSettings],
      'roastLevel': [_editedCoffee.roastLevel],
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
        title: const Text('Edit Coffee Beans'),
        actions: <Widget>[
          ElevatedButton(
            child: Text(
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
                coffeeForm(form),
              ],
            ),
          ),
        ),
      ),
    );
  }

  coffeeForm(FormGroup form) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReactiveTextField<String>(
          formControlName: 'name',
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: 'Name',
          ),
          validationMessages: {
            ValidationMessage.required: (_) => 'Name must not be empty',
          },
        ),
        ReactiveTextField<String>(
          keyboardType: TextInputType.text,
          formControlName: 'description',
          decoration: const InputDecoration(
            labelText: 'Description',
          ),
        ),
        ReactiveTextField<String>(
          formControlName: 'taste',
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: 'Taste of Beans',
          ),
        ),
        ReactiveTextField<String>(
          formControlName: 'type',
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: 'Type of Beans',
          ),
        ),
        ReactiveTextField<String>(
          formControlName: 'origin',
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: 'Origin',
          ),
        ),
        ReactiveTextField<String>(
          formControlName: 'price',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Price/package',
          ),
        ),
        ReactiveTextField<double>(
          formControlName: 'grinderSettings',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Grinder',
          ),
        ),
        createKeyValue("Acidity", null),
        ReactiveRatingBarBuilder<double>(
          formControlName: 'acidRating',
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
          itemBuilder: (context, _) => const Icon(
            Icons.star,
            color: Colors.amber,
          ),
        ),
        createKeyValue("Intensity", null),
        ReactiveRatingBarBuilder<double>(
          formControlName: 'intensityRating',
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
          itemBuilder: (context, _) => const Icon(
            Icons.star,
            color: Colors.amber,
          ),
        ),
        createKeyValue("Roast Level", null),
        ReactiveRatingBarBuilder<double>(
          formControlName: 'roastLevel',
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
          itemBuilder: (context, _) => const Icon(
            Icons.star,
            color: Colors.amber,
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
            setState(() {
              Navigator.pop(context);
            });
          },
          child: const Text('CANCEL'),
        ),
      ],
    );
  }

  Widget createKeyValue(String key, String? value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(key, style: theme.TextStyles.tabHeading),
          if (value != null) Text(value, style: theme.TextStyles.tabPrimary),
        ],
      ),
    );
  }

  void saveFormData(FormGroup form) {
    _editedCoffee.name = form.value["name"] as String;
    _editedCoffee.type = form.value["type"] as String;
    _editedCoffee.price = form.value["price"] as String;
    _editedCoffee.taste = form.value["taste"] as String;
    _editedCoffee.origin = form.value["origin"] as String;

    _editedCoffee.intensityRating = form.value["intensityRating"] as double;
    _editedCoffee.acidRating = form.value["acidRating"] as double;
    _editedCoffee.grinderSettings = form.value["grinderSettings"] as double;
    _editedCoffee.roastLevel = form.value["roastLevel"] as double;
    coffeeService.addCoffee(_editedCoffee);
    selectedCoffeeId = _editedCoffee.id;
    coffeeService.setSelectedCoffee(selectedCoffeeId);
  }

  void updateCoffee() {
    setState(
      () {},
    );
  }
}
