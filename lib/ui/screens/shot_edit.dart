import 'package:despresso/model/shot.dart';
import 'package:despresso/ui/widgets/height_widget.dart';
import 'package:despresso/ui/widgets/key_value.dart';
import 'package:logging/logging.dart';

import 'package:despresso/model/coffee.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:reactive_flutter_rating_bar/reactive_flutter_rating_bar.dart';

import 'package:reactive_forms/reactive_forms.dart';

import '../../model/services/ble/machine_service.dart';

class ShotEdit extends StatefulWidget {
  const ShotEdit(this.selectedShotId, {super.key});
  final int selectedShotId;

  @override
  ShotEditState createState() => ShotEditState();
}

enum EditModes { show, add, edit }

class ShotEditState extends State<ShotEdit> {
  final log = Logger('ShotEditState');

  late CoffeeService coffeeService;
  late EspressoMachineService machineService;

  Shot _editedShot = Shot();

  FormGroup? currentForm;
  List<DropdownMenuItem<int>> roasters = [];

// double pourTime = 0;
//   double pourWeight = 0;
//   double targetEspressoWeight = 0;
//   double targetTempCorrection = 0;
//   double doseWeight = 0;
//   double drinkWeight = 0;

//   double grinderSettings = 0;

//   String description = "";
//   String grinderName = "";
//   DateTime roastingDate = DateTime.now();
//   double totalDissolvedSolidss = 0;
//   double extractionYield = 0;
//   double enjoyment = 0;
//   String barrista = "";
//   String drinker = "";
// }

  // FormGroup get theForm2 => fb.group(<String, Object>{
  //       'description': [''],
  //       'drinker': [''],
  //       'barrista': [''],
  //       'totalDissolvedSolidss': [0],
  //       'extractionYield': [0],
  //       'enjoyment': [0],
  //       'grinderSettings': [0.1],
  //       'grinderName': [''],
  //       'pourWeight': [0.1],
  //       'doseWeight': [0.1],
  //       'drinkWeight': [0.1],
  //       'pourTime': [0.1],
  //       'targetTempCorrection': [0.1],
  //       'targetEspressoWeight': [0.1],
  //     });

  late FormGroup theForm;

  ShotEditState();

  @override
  void initState() {
    super.initState();
    coffeeService = getIt<CoffeeService>();
    machineService = getIt<EspressoMachineService>();
    coffeeService.addListener(updateCoffee);
    roasters = loadRoasters();

    if (widget.selectedShotId > 0) {
      _editedShot = coffeeService.shotBox.get(widget.selectedShotId)!;
    } else {
      _editedShot = Shot();
    }
    if (_editedShot.coffee.targetId > 0) {}
    theForm = fb.group(<String, Object>{
      'description': [_editedShot.description],
      'drinker': [_editedShot.drinker],
      'barrista': [_editedShot.barrista],
      'totalDissolvedSolids': [_editedShot.totalDissolvedSolids],
      'extractionYield': [_editedShot.extractionYield],
      'enjoyment': [_editedShot.enjoyment],
      'grinderSettings': [_editedShot.grinderSettings],
      'grinderName': [_editedShot.grinderName],
      'doseWeight': [_editedShot.doseWeight],
      'drinkWeight': [_editedShot.drinkWeight],
      'pourWeight': [_editedShot.pourWeight],
      'pourTime': [_editedShot.pourTime],
      'targetTempCorrection': [_editedShot.targetTempCorrection],
      'targetEspressoWeight': [_editedShot.targetEspressoWeight],
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
        title: const Text('Describe your experience with Shot'),
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
                  coffeeForm(form),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  coffeeForm(FormGroup form) {
    var width = 70.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyValueWidget(width: width, label: "Recipe", value: _editedShot.recipe.target?.name ?? "No Recipe"),
        KeyValueWidget(width: width, label: "Profile", value: _editedShot.profileId),
        KeyValueWidget(
            width: width,
            label: "Coffee",
            value: (_editedShot.recipe.target?.coffee.targetId ?? 0) > 0
                ? _editedShot.recipe.target?.coffee.target?.name ?? ""
                : "No Beans"),

        ReactiveTextField<String>(
          formControlName: 'description',
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: 'Describe your experience',
          ),
          validationMessages: {
            ValidationMessage.required: (_) => 'Name must not be empty',
          },
        ),
        KeyValueWidget(label: "Enjoyment", value: ""),
        ReactiveRatingBarBuilder<double>(
          formControlName: 'enjoyment',
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
        HeightWidget(height: 20),
        ReactiveTextField<String>(
          keyboardType: TextInputType.text,
          formControlName: 'drinker',
          decoration: const InputDecoration(
            labelText: 'Drinker',
          ),
        ),
        ReactiveTextField<String>(
          formControlName: 'barrista',
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: 'Barrista',
          ),
        ),
        ReactiveTextField<double>(
          formControlName: 'totalDissolvedSolids',
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: 'Total Dissolved Solidss (TDS)',
          ),
        ),
        ReactiveTextField<double>(
          formControlName: 'extractionYield',
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: 'Extraction yield',
          ),
        ),
        ReactiveTextField<String>(
          formControlName: 'grinderName',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Grinder',
          ),
        ),
        ReactiveTextField<double>(
          formControlName: 'grinderSettings',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Grinder settings',
          ),
        ),
        ReactiveTextField<double>(
          formControlName: 'grinderSettings',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Grinder',
          ),
        ),
        ReactiveTextField<double>(
          formControlName: 'doseWeight',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Dose weight [g]',
          ),
        ),
        ReactiveTextField<double>(
          formControlName: 'drinkWeight',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Drink weight [g]',
          ),
        ),
        ReactiveTextField<double>(
          formControlName: 'pourTime',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Pouring time [s]',
          ),
        ),
        ReactiveTextField<double>(
          formControlName: 'pourWeight',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Pouring weight [g]',
          ),
        ),
        HeightWidget(height: 20),

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
    _editedShot.description = form.value["description"] as String;
    _editedShot.barrista = form.value["barrista"] as String;
    _editedShot.doseWeight = form.value["doseWeight"] as double;
    _editedShot.drinkWeight = form.value["drinkWeight"] as double;
    _editedShot.drinker = form.value["drinker"] as String;
    _editedShot.enjoyment = form.value["enjoyment"] as double;

    _editedShot.extractionYield = form.value["extractionYield"] as double;
    _editedShot.grinderName = form.value["grinderName"] as String;
    _editedShot.grinderSettings = form.value["grinderSettings"] as double;
    _editedShot.pourTime = form.value["pourTime"] as double;
    _editedShot.pourWeight = form.value["pourWeight"] as double;
    _editedShot.targetEspressoWeight = form.value["targetEspressoWeight"] as double;
    _editedShot.totalDissolvedSolids = form.value["totalDissolvedSolids"] as double;

    coffeeService.updateShot(_editedShot);
  }

  void updateCoffee() {
    setState(
      () {},
    );
  }

  List<DropdownMenuItem<int>> loadRoasters() {
    var roasters = coffeeService.roasterBox
        .getAll()
        .map((p) => DropdownMenuItem(
              value: p.id,
              child: Text(p.name),
            ))
        .toList();

    return roasters;
  }
}
