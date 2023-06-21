import 'package:despresso/generated/l10n.dart';
import 'package:despresso/model/recipe.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/coffee_edit.dart';
import 'package:despresso/ui/widgets/bean_select.dart';
import 'package:despresso/ui/widgets/profile_select.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'package:reactive_forms/reactive_forms.dart';

import '../../model/services/ble/machine_service.dart';

class RecipeEdit extends StatefulWidget {
  const RecipeEdit(this.selectedRecipeId, {super.key, this.title});
  final int selectedRecipeId;
  final String? title;

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

  RecipeEditState();

  @override
  void initState() {
    super.initState();
    _selectedRecipeId = widget.selectedRecipeId;
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
      'adjustedTemp': [
        _editedRecipe.adjustedTemp,
        Validators.min(-10.0),
        Validators.max(10.0),
      ],
      'adjustedWeight': [
        _editedRecipe.adjustedWeight,
        Validators.min(0.0),
        Validators.max(5000.0),
      ],
      'grinderDoseWeight': [
        _editedRecipe.grinderDoseWeight,
        Validators.min(0.0),
        Validators.max(5000.0),
      ],
      'grinderSettings': [_editedRecipe.grinderSettings],
      'grinderModel': [_editedRecipe.grinderModel],
      'ratio1': [
        _editedRecipe.ratio1,
        Validators.min(0.0),
        Validators.max(100.0),
      ],
      'ratio2': [
        _editedRecipe.ratio2,
        Validators.min(0.0),
        Validators.max(100.0),
      ],
      'tempSteam': [_editedRecipe.tempSteam],
      'tempWater': [_editedRecipe.tempWater],
      'timeSteam': [_editedRecipe.timeSteam],
      'timeWater': [_editedRecipe.timeWater],
      'useSteam': [_editedRecipe.useSteam],
      'useWater': [_editedRecipe.useWater],
      'weightMilk': [
        _editedRecipe.weightMilk,
        Validators.min(0.0),
        Validators.max(5000.0),
      ],
      'weightWater': [
        _editedRecipe.weightWater,
        Validators.min(0.0),
        Validators.max(1000.0),
      ],
      'id': [_editedRecipe.id],
      'disableStopOnWeight': [_editedRecipe.disableStopOnWeight],
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
        title: widget.title == null ? Text(S.of(context).screenRecipeEditTitle) : Text(widget.title!),
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
                  recipeForm(form),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  recipeForm(FormGroup form) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ReactiveTextField<String>(
                  formControlName: 'name',
                  decoration: InputDecoration(
                    labelText: S.of(context).screenRecipeEditNameOfRecipe,
                  ),
                  validationMessages: {
                    ValidationMessage.required: (_) => 'Name must not be empty',
                  },
                ),
                ReactiveTextField<String>(
                  formControlName: 'description',
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: S.of(context).screenRecipeEditDescription,
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Profile", style: Theme.of(context).textTheme.labelMedium),
                    ProfileSelect(
                      onChanged: (p0) {
                        _editedRecipe.profileId = p0.id;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Beans", style: Theme.of(context).textTheme.labelMedium),
                    BeanSelect(
                      onChanged: (coffeeId) {
                        _editedRecipe.coffee.targetId = coffeeId;
                        setState(() {
                          if (coffeeId == 0) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CoffeeEdit(0)),
                            );
                          } else {
                            coffeeService.setSelectedCoffee(coffeeId);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 20),
        Card(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Grinder", style: Theme.of(context).textTheme.labelMedium),
              Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: ReactiveTextField<double>(
                      formControlName: 'grinderSettings',
                      decoration: InputDecoration(
                        labelText: S.of(context).screenRecipeEditGrinderSettings,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  SizedBox(
                    width: 200,
                    child: ReactiveTextField<String>(
                      formControlName: 'grinderModel',
                      decoration: InputDecoration(
                        labelText: S.of(context).screenRecipeEditGrinderModel,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )),
        const SizedBox(height: 20),
        Card(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.of(context).screenRecipeEditDosingAndWeights, style: Theme.of(context).textTheme.labelMedium),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: ReactiveTextField<double>(
                      formControlName: 'ratio1',
                      keyboardType: const TextInputType.numberWithOptions(),
                      decoration: InputDecoration(
                        labelText: S.of(context).screenRecipeEditRatio,
                      ),
                      onSubmitted: (control) {
                        recalcWeight(form);
                        setState(() {});
                      },
                      showErrors: (control) => control.invalid,
                      validationMessages: {
                        ValidationMessage.max: (error) =>
                            'A value greater than ${(error as Map)['max']} is not accepted',
                        ValidationMessage.min: (error) => 'A value lower than ${(error as Map)['min']} is not accepted',
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                    width: 100,
                    child: ReactiveTextField<double>(
                      formControlName: 'ratio2',
                      keyboardType: const TextInputType.numberWithOptions(),
                      decoration: InputDecoration(
                        labelText: S.of(context).screenRecipeEditRatioTo,
                      ),
                      onSubmitted: (control) {
                        recalcWeight(form);
                        setState(() {});
                      },
                      showErrors: (control) => control.invalid,
                      validationMessages: {
                        ValidationMessage.max: (error) =>
                            'A value greater than ${(error as Map)['max']} is not accepted',
                        ValidationMessage.min: (error) => 'A value lower than ${(error as Map)['min']} is not accepted',
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  SizedBox(
                    width: 200,
                    child: ReactiveTextField<double>(
                      formControlName: 'grinderDoseWeight',
                      keyboardType: const TextInputType.numberWithOptions(),
                      decoration: InputDecoration(
                        labelText: S.of(context).screenRecipeEditDoseWeightin,
                      ),
                      onSubmitted: (control) {
                        recalcWeight(form);
                        setState(() {});
                      },
                      showErrors: (control) => control.invalid,
                      validationMessages: {
                        ValidationMessage.max: (error) =>
                            'A value greater than ${(error as Map)['max']} is not accepted',
                        ValidationMessage.min: (error) => 'A value lower than ${(error as Map)['min']} is not accepted',
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                    width: 200,
                    child: ReactiveTextField<double>(
                      formControlName: 'adjustedWeight',
                      keyboardType: const TextInputType.numberWithOptions(),
                      decoration: InputDecoration(
                        labelText: S.of(context).screenRecipeEditWeightOut,
                      ),
                      showErrors: (control) => control.invalid,
                      validationMessages: {
                        ValidationMessage.max: (error) =>
                            'A value greater than ${(error as Map)['max']} is not accepted',
                        ValidationMessage.min: (error) => 'A value lower than ${(error as Map)['min']} is not accepted',
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        )),
        const SizedBox(height: 20),
        Card(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.of(context).screenRecipeEditAdjustments, style: Theme.of(context).textTheme.labelMedium),
              Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: ReactiveTextField<double>(
                      formControlName: 'adjustedTemp',
                      decoration: InputDecoration(
                        labelText: S.of(context).screenRecipeEditTemperatureCorrection,
                      ),
                      showErrors: (control) => control.invalid,
                      validationMessages: {
                        ValidationMessage.max: (error) =>
                            'A value greater than ${(error as Map)['max']} is not accepted',
                        ValidationMessage.min: (error) => 'A value lower than ${(error as Map)['min']} is not accepted',
                      },
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                      child: Text(S.of(context).screenRecipeEditDisableStoponweightSelectThisForPourOverWhereYouDo)),
                  SizedBox(
                    width: 120,
                    child: ReactiveSwitch(
                      formControlName: 'disableStopOnWeight',
                      onChanged: (control) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )),
        const SizedBox(height: 20),
        Card(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.of(context).screenRecipeEditMilkAndWater, style: Theme.of(context).textTheme.labelMedium),
              Row(
                children: [
                  SizedBox(width: 150, child: Text(S.of(context).screenRecipeEditUseSteam)),
                  ReactiveSwitch(
                    formControlName: 'useSteam',
                    onChanged: (control) => setState(() {}),
                  ),
                ],
              ),
              if (form.value["useSteam"] as bool)
                SizedBox(
                  width: 200,
                  child: ReactiveTextField<double>(
                    formControlName: 'weightMilk',
                    keyboardType: const TextInputType.numberWithOptions(),
                    decoration: InputDecoration(
                      labelText: S.of(context).screenRecipeEditMilkWeight,
                    ),
                  ),
                ),
              const Divider(),
              Row(
                children: [
                  SizedBox(width: 150, child: Text(S.of(context).screenRecipeEditUseWater)),
                  ReactiveSwitch(
                    formControlName: 'useWater',
                    onChanged: (control) => setState(() {}),
                  ),
                ],
              ),
              if (form.value["useWater"] as bool)
                SizedBox(
                  width: 200,
                  child: ReactiveTextField<double>(
                    formControlName: 'weightWater',
                    keyboardType: const TextInputType.numberWithOptions(),
                    showErrors: (control) => control.invalid,
                    validationMessages: {
                      ValidationMessage.max: (error) => 'A value greater than ${(error as Map)['max']} is not accepted',
                      ValidationMessage.min: (error) => 'A value lower than ${(error as Map)['min']} is not accepted',
                    },
                    decoration: const InputDecoration(
                      labelText: 'Water weight',
                    ),
                  ),
                ),
            ],
          ),
        )),
      ],
    );
  }

  void recalcWeight(FormGroup form) {
    var ratio1 = form.value["ratio1"] as double? ?? 0;
    if (ratio1 > 0) {
      var ratio2 = form.value["ratio2"] as double? ?? 0;
      var grinderDoseWeight = form.value["grinderDoseWeight"] as double? ?? 0;

      var adjustedWeight = grinderDoseWeight * (ratio2 / ratio1);
      var ctrl = form.controls["adjustedWeight"]!;
      ctrl.value = adjustedWeight;
    }
  }

  void saveFormData(FormGroup form) {
    _editedRecipe.name = form.value["name"] as String;
    _editedRecipe.description = form.value["description"] as String;
    _editedRecipe.adjustedPressure = form.value["adjustedPressure"] as double? ?? 0;
    _editedRecipe.adjustedTemp = form.value["adjustedTemp"] as double? ?? 0;
    _editedRecipe.adjustedWeight = form.value["adjustedWeight"] as double? ?? 0;
    _editedRecipe.grinderDoseWeight = form.value["grinderDoseWeight"] as double? ?? 0;
    _editedRecipe.grinderSettings = form.value["grinderSettings"] as double? ?? 0;
    _editedRecipe.grinderModel = form.value["grinderModel"] as String? ?? "";
    _editedRecipe.ratio1 = form.value["ratio1"] as double? ?? 0;
    _editedRecipe.ratio2 = form.value["ratio2"] as double? ?? 0;
    _editedRecipe.tempSteam = form.value["tempSteam"] as double? ?? 0;
    _editedRecipe.tempWater = form.value["tempWater"] as double? ?? 0;
    _editedRecipe.timeSteam = form.value["timeSteam"] as double? ?? 0;
    _editedRecipe.timeWater = form.value["timeWater"] as double? ?? 0;
    _editedRecipe.useSteam = form.value["useSteam"] as bool;
    _editedRecipe.useWater = form.value["useWater"] as bool;
    _editedRecipe.disableStopOnWeight = form.value["disableStopOnWeight"] as bool;
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
