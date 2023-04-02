import 'package:despresso/model/coffee.dart';
import 'package:despresso/model/recipe.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'package:reactive_forms/reactive_forms.dart';

import '../../model/services/ble/machine_service.dart';

class RecipeEdit extends StatefulWidget {
  RecipeEdit(this.selectedRecipeId, {super.key});
  int selectedRecipeId;

  @override
  RecipeEditState createState() => RecipeEditState();
}

enum EditModes { show, add, edit }

class RecipeEditState extends State<RecipeEdit> {
  final log = Logger('RecipeEdit');

  int _selectedRecipeId = 0;

  late CoffeeService coffeeService;
  late EspressoMachineService machineService;

  Recipe _editedRecipe = Recipe();

  FormGroup? currentForm;

  FormGroup get theForm2 => fb.group(<String, Object>{
        'name': ['test', Validators.required],
        'description': [''],
        'address': [''],
        'homepage': [''],
        'id': [0],
      });

  late FormGroup theForm;

  RecipeEditState() {
    _selectedRecipeId = widget.selectedRecipeId;
  }

  @override
  void initState() {
    super.initState();
    coffeeService = getIt<CoffeeService>();
    machineService = getIt<EspressoMachineService>();
    coffeeService.addListener(updateCoffee);

    if (_selectedRecipeId > 0) {
      _editedRecipe = coffeeService.recipeBox.get(_selectedRecipeId)!;
    } else {
      _editedRecipe = Recipe();
    }

    theForm = fb.group(<String, Object>{
      'name': [_editedRecipe.name, Validators.required],
      'description': [_editedRecipe.description],
      'adjustedPressure': [_editedRecipe.adjustedPressure],
      'adjustedTemp': [_editedRecipe.adjustedTemp],
      'adjustedWeight': [_editedRecipe.adjustedWeight],
      'grinderDoseWeight': [_editedRecipe.grinderDoseWeight],
      'grinderSettings': [_editedRecipe.grinderSettings],
      'ratio1': [_editedRecipe.ratio1],
      'ratio2': [_editedRecipe.ratio2],
      'tempSteam': [_editedRecipe.tempSteam],
      'tempWater': [_editedRecipe.tempWater],
      'timeSteam': [_editedRecipe.timeSteam],
      'timeWater': [_editedRecipe.timeWater],
      'useSteam': [_editedRecipe.useSteam],
      'useWater': [_editedRecipe.useWater],
      'weightMilk': [_editedRecipe.weightMilk],
      'weightWater': [_editedRecipe.weightWater],
      'id': [_editedRecipe.id],
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
        title: const Text('Edit Roaster'),
        actions: <Widget>[
          ElevatedButton(
            child: const Text(
              'Save',
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
        ReactiveTextField<double>(
          formControlName: 'grinderDoseWeight',
          decoration: const InputDecoration(
            labelText: 'Dose Weight-in',
          ),
        ),
        ReactiveTextField<double>(
          formControlName: 'grinderSettings',
          decoration: const InputDecoration(
            labelText: 'Grinder Settings',
          ),
        ),

        ReactiveTextField<double>(
          formControlName: 'adjustedWeight',
          decoration: const InputDecoration(
            labelText: 'Weight correction',
          ),
        ),
        ReactiveTextField<double>(
          formControlName: 'adjustedTemp',
          decoration: const InputDecoration(
            labelText: 'Temperature correction',
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
    _editedRecipe.name = form.value["name"] as String;
    _editedRecipe.description = form.value["description"] as String;
    _editedRecipe.adjustedPressure = form.value["adjustedPressure"] as double? ?? 0;
    _editedRecipe.adjustedTemp = form.value["adjustedTemp"] as double? ?? 0;
    _editedRecipe.adjustedWeight = form.value["adjustedWeight"] as double? ?? 0;
    _editedRecipe.grinderDoseWeight = form.value["grinderDoseWeight"] as double? ?? 0;
    _editedRecipe.grinderSettings = form.value["grinderSettings"] as double? ?? 0;
    _editedRecipe.ratio1 = form.value["ratio1"] as double? ?? 0;
    _editedRecipe.ratio2 = form.value["ratio2"] as double? ?? 0;
    _editedRecipe.tempSteam = form.value["tempSteam"] as double? ?? 0;
    _editedRecipe.tempWater = form.value["tempWater"] as double? ?? 0;
    _editedRecipe.timeSteam = form.value["timeSteam"] as double? ?? 0;
    _editedRecipe.timeWater = form.value["timeWater"] as double? ?? 0;
    _editedRecipe.useSteam = form.value["useSteam"] as bool;
    _editedRecipe.useWater = form.value["useWater"] as bool;
    _editedRecipe.weightMilk = form.value["weightMilk"] as double? ?? 0;
    _editedRecipe.weightWater = form.value["weightWater"] as double? ?? 0;

    coffeeService.updateRecipe(_editedRecipe);
  }

  void updateCoffee() {
    setState(
      () {},
    );
  }
}
