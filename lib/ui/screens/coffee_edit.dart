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

class CoffeeEdit extends StatefulWidget {
  const CoffeeEdit(this.selectedCoffeeId, {super.key});
  final int selectedCoffeeId;

  @override
  CoffeeEditState createState() => CoffeeEditState();
}

enum EditModes { show, add, edit }

class CoffeeEditState extends State<CoffeeEdit> {
  final log = Logger('CoffeeEditState');

  late CoffeeService coffeeService;
  late EspressoMachineService machineService;

  Coffee _editedCoffee = Coffee();
  int selectedCoffeeId = 0;

  FormGroup? currentForm;
  List<DropdownMenuItem<int>> roasters = [];

  int _selectedRoasterId = 0;

  FormGroup get theForm2 => fb.group(<String, Object>{
        'name': ['test', Validators.required],
        'description': [''],
        'type': [''],
        'price': [''],
        'taste': [''],
        'origin': [''],
        'intensityRating': [0.1],
        'acidRating': [0.1],
        'roastLevel': [0.1],
      });

  late FormGroup theForm;

  CoffeeEditState();

  @override
  void initState() {
    super.initState();
    selectedCoffeeId = widget.selectedCoffeeId;
    coffeeService = getIt<CoffeeService>();
    machineService = getIt<EspressoMachineService>();
    coffeeService.addListener(updateCoffee);
    roasters = loadRoasters();

    if (selectedCoffeeId > 0) {
      _editedCoffee = coffeeService.coffeeBox.get(selectedCoffeeId)!;
    } else {
      _editedCoffee = Coffee();
    }
    if (_editedCoffee.roaster.targetId == 0) {
      _selectedRoasterId = coffeeService.selectedRoasterId;
    } else {
      _selectedRoasterId = _editedCoffee.roaster.targetId;
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
      'roastLevel': [_editedCoffee.roastLevel],
      'roastDate': [_editedCoffee.roastDate],
      "region": [_editedCoffee.region],
      "farm": [_editedCoffee.farm],
      "cropyear": [_editedCoffee.cropyear],
      "process": [_editedCoffee.process],
      "elevation": [_editedCoffee.elevation, Validators.number],
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
        title: selectedCoffeeId == 0 ? const Text('Add new coffee beans') : const Text('Edit coffee beans'),
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
    return Focus(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KeyValueWidget(label: "Roaster", value: ""),
          DropdownButton(
            isExpanded: true,
            alignment: Alignment.centerLeft,
            value: _selectedRoasterId,
            items: roasters,
            onChanged: (value) async {
              _selectedRoasterId = value!;
              coffeeService.setSelectedRoaster(_selectedRoasterId);
            },
          ),

          ReactiveTextField<String>(
            formControlName: 'name',
            autofocus: true,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'Name of bean',
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
          SizedBox(
            width: 300,
            child: Row(
              children: [
                Expanded(
                  child: ReactiveTextField<DateTime>(
                    formControlName: 'roastDate',
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Roasting date',
                    ),
                  ),
                ),
                ReactiveDatePicker(
                  formControlName: 'roastDate',
                  lastDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  builder: (context, picker, child) {
                    return IconButton(
                      onPressed: picker.showPicker,
                      icon: const Icon(Icons.date_range),
                    );
                  },
                ),
              ],
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
            formControlName: 'region',
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'Region',
            ),
          ),
          ReactiveTextField<String>(
            formControlName: 'farm',
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'Farm',
            ),
          ),
          ReactiveTextField<int>(
            formControlName: 'elevation',
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'Elevation (m or ft)',
            ),
          ),
          SizedBox(
            width: 300,
            child: Row(
              children: [
                Expanded(
                  child: ReactiveTextField<DateTime>(
                    formControlName: 'cropyear',
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Crop date',
                    ),
                  ),
                ),
                ReactiveDatePicker(
                  formControlName: 'cropyear',
                  initialDatePickerMode: DatePickerMode.year,
                  lastDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 20 * 365)),
                  builder: (context, picker, child) {
                    return IconButton(
                      onPressed: picker.showPicker,
                      icon: const Icon(Icons.date_range),
                    );
                  },
                ),
              ],
            ),
          ),
          ReactiveTextField<String>(
            formControlName: 'process',
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'Process',
            ),
          ),
          SizedBox(
            width: 250,
            child: ReactiveTextField<String>(
              formControlName: 'price',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price/package',
              ),
            ),
          ),

          const HeightWidget(height: 20),
          const KeyValueWidget(label: "Acidity", value: ""),
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
          const HeightWidget(height: 20),

          const KeyValueWidget(label: "Intensity", value: ""),
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
          const HeightWidget(height: 20),
          const KeyValueWidget(label: "Roast Level", value: ""),

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
      ),
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
    _editedCoffee.region = form.value["region"] as String;
    _editedCoffee.farm = form.value["farm"] as String;
    _editedCoffee.cropyear = form.value["cropyear"] as DateTime? ?? DateTime.now();
    _editedCoffee.process = form.value["process"] as String;
    _editedCoffee.roastDate = form.value["roastDate"] as DateTime? ?? DateTime.now();
    _editedCoffee.description = form.value["description"] as String;
    _editedCoffee.intensityRating = form.value["intensityRating"] as double;
    _editedCoffee.acidRating = form.value["acidRating"] as double;
    _editedCoffee.roastLevel = form.value["roastLevel"] as double;
    _editedCoffee.elevation = form.value["elevation"] as int? ?? 0;
    _editedCoffee.roaster.targetId = _selectedRoasterId;
    coffeeService.addCoffee(_editedCoffee);
    selectedCoffeeId = _editedCoffee.id;
    coffeeService.setSelectedCoffee(selectedCoffeeId);
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
