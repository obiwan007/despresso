import 'package:despresso/generated/l10n.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/model/shot.dart';
import 'package:despresso/ui/widgets/height_widget.dart';
import 'package:despresso/ui/widgets/key_value.dart';
import 'package:despresso/ui/widgets/progress_overlay.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:reactive_flutter_rating_bar/reactive_flutter_rating_bar.dart';

import 'package:reactive_forms/reactive_forms.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:despresso/model/services/state/visualizer_service.dart';

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
  late VisualizerService visualizerService;
  late SettingsService settingsService;

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
  bool _busy = false;
  double _busyProgress = 0;

  ShotEditState();

  @override
  void initState() {
    super.initState();
    coffeeService = getIt<CoffeeService>();
    machineService = getIt<EspressoMachineService>();
    visualizerService = getIt<VisualizerService>();
    settingsService = getIt<SettingsService>();

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
        title: Text(S.of(context).screenShotEditTitle(
            '${DateFormat.yMd().format(_editedShot.date)} ${DateFormat.Hm().format(_editedShot.date)}')),
        actions: <Widget>[
          // Builder(
          //   builder: (BuildContext context) {
          //     return TextButton.icon(
          //       onPressed: () => _onShare(context),
          //       icon: const Icon(Icons.ios_share),
          //       label: const Text("Share shot"),
          //     );
          //   },
          // ),
          if (settingsService.visualizerUpload)
            TextButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text("Visualizer"),
              onPressed: () async {
                try {
                  if (currentForm != null && currentForm!.valid) {
                    setState(() {
                      log.info("${currentForm!.value}");
                      saveFormData(currentForm!);
                    });
                  }
                  setState(() {
                    _busy = true;
                  });
                  var selectedShots = [_editedShot];
                  for (var _ in selectedShots) {
                    setState(() {
                      _busyProgress += 1 / selectedShots.length;
                    });
                    var id = await visualizerService.sendShotToVisualizer(_editedShot);
                    _editedShot.visualizerId = id;
                    coffeeService.updateShot(_editedShot);
                  }
                  var snackBar = SnackBar(
                      backgroundColor: Colors.greenAccent,
                      content: Text(S.of(context).screenShotEditSuccessUploadingYourShot),
                      action: SnackBarAction(
                        label: 'Ok',
                        onPressed: () {
                          // Some code to undo the change.
                        },
                      ));
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                } catch (e) {
                  var snackBar = SnackBar(
                      backgroundColor: const Color.fromARGB(255, 250, 141, 141),
                      content: Text("Error uploading shot: $e"),
                      action: SnackBarAction(
                        label: S.of(context).ok,
                        onPressed: () {
                          // Some code to undo the change.
                        },
                      ));
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  log.severe("Error uploading shot $e");
                }
                setState(() {
                  _busy = false;
                  _busyProgress = 0;
                });
              },
            ),

          TextButton.icon(
            icon: const Icon(Icons.save_alt),
            label: Text(
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
      body: ModalProgressOverlay(
        inAsyncCall: _busy,
        progressIndicator: CircularProgressIndicator(
          // strokeWidth: 15,
          value: _busyProgress,
        ),
        child: SingleChildScrollView(
          child: ReactiveFormBuilder(
            form: () => theForm,
            builder: (context, form, child) {
              currentForm = form;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    shotForm(form),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  shotForm(FormGroup form) {
    var width = 100.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                KeyValueWidget(
                    width: width, label: S.of(context).recipe, value: _editedShot.recipe.target?.name ?? "No Recipe"),
                KeyValueWidget(width: width, label: S.of(context).profile, value: _editedShot.profileId),
                KeyValueWidget(
                    width: width,
                    label: S.of(context).beans,
                    value: (_editedShot.recipe.target?.coffee.targetId ?? 0) > 0
                        ? _editedShot.recipe.target?.coffee.target?.name ?? ""
                        : "No Beans"),
                if (_editedShot.visualizerId.isNotEmpty)
                  KeyValueWidget(
                    width: width,
                    label: "Visualizer",
                    value: "",
                    widget: InkWell(
                      onTap: () => launchUrl(Uri.parse('https://visualizer.coffee/shots/${_editedShot.visualizerId}')),
                      child: Text(
                        S.of(context).screenShotEditOpenInVisualizercoffee,
                        style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                ReactiveTextField<String>(
                  formControlName: 'description',
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: S.of(context).screenShotEditDescribeYourExperience,
                  ),
                  validationMessages: {
                    ValidationMessage.required: (_) => S.of(context).validatorNotBeEmpty,
                  },
                ),
                HeightWidget(height: 20),
                KeyValueWidget(label: S.of(context).screenShotEditEnjoyment, value: ""),
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
              ]),
            ),
          ),
        ),

        HeightWidget(height: 20),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                ReactiveTextField<String>(
                  keyboardType: TextInputType.text,
                  formControlName: 'drinker',
                  decoration: InputDecoration(
                    labelText: S.of(context).screenShotEditDrinker,
                  ),
                ),
                ReactiveTextField<String>(
                  formControlName: 'barrista',
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: S.of(context).screenShotEditBarrista,
                  ),
                ),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ReactiveTextField<double>(
                  formControlName: 'totalDissolvedSolids',
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: S.of(context).screenShotEditTotalDissolvedSolidssTds,
                  ),
                ),
                ReactiveTextField<double>(
                  formControlName: 'extractionYield',
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: S.of(context).screenShotEditExtractionYield,
                  ),
                ),
              ],
            ),
          )),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                ReactiveTextField<String>(
                  formControlName: 'grinderName',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: S.of(context).screenShotEditGrinder,
                  ),
                ),
                ReactiveTextField<double>(
                  formControlName: 'grinderSettings',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: S.of(context).screenShotEditGrinderSettings,
                  ),
                ),
              ]),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                ReactiveTextField<double>(
                  formControlName: 'doseWeight',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: S.of(context).screenShotEditDoseWeightG,
                  ),
                ),
                ReactiveTextField<double>(
                  formControlName: 'drinkWeight',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: S.of(context).screenShotEditDrinkWeightG,
                  ),
                ),
                ReactiveTextField<double>(
                  formControlName: 'pourTime',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: S.of(context).screenShotEditPouringTimeS,
                  ),
                ),
                ReactiveTextField<double>(
                  formControlName: 'pourWeight',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: S.of(context).screenShotEditPouringWeightG,
                  ),
                ),
              ]),
            ),
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

  void saveFormData(FormGroup form) {
    _editedShot.description = form.value["description"] as String;
    _editedShot.barrista = form.value["barrista"] as String;
    _editedShot.doseWeight = form.value["doseWeight"] as double? ?? 0.0;
    _editedShot.drinkWeight = form.value["drinkWeight"] as double? ?? 0.0;
    _editedShot.drinker = form.value["drinker"] as String;
    _editedShot.enjoyment = form.value["enjoyment"] as double;

    _editedShot.extractionYield = form.value["extractionYield"] as double? ?? 0.0;
    _editedShot.grinderName = form.value["grinderName"] as String;
    _editedShot.grinderSettings = form.value["grinderSettings"] as double? ?? 0.0;
    _editedShot.pourTime = form.value["pourTime"] as double? ?? 0.0;
    _editedShot.pourWeight = form.value["pourWeight"] as double? ?? 0.0;
    _editedShot.targetEspressoWeight = form.value["targetEspressoWeight"] as double? ?? 0.0;
    _editedShot.totalDissolvedSolids = form.value["totalDissolvedSolids"] as double? ?? 0.0;

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
