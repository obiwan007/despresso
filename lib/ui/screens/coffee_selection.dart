import 'package:collection/collection.dart';
import 'package:despresso/generated/l10n.dart';
import 'package:despresso/objectbox.g.dart';
import 'package:despresso/ui/widgets/key_value.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import 'package:despresso/model/coffee.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/coffee_edit.dart';
import 'package:despresso/ui/screens/roaster_edit.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:reactive_flutter_rating_bar/reactive_flutter_rating_bar.dart';

import '../../model/services/ble/machine_service.dart';

class CoffeeSelectionTab extends StatefulWidget {
  final bool saveToRecipe;
  const CoffeeSelectionTab({super.key, required this.saveToRecipe});

  @override
  CoffeeSelectionTabState createState() => CoffeeSelectionTabState();
}

enum EditModes { show, add, edit }

class CoffeeSelectionTabState extends State<CoffeeSelectionTab> {
  final log = Logger('CoffeeSelectionTabState');

  Roaster newRoaster = Roaster();
  Coffee newCoffee = Coffee();
  int _selectedRoasterId = 0;
  int _selectedCoffeeId = 0;
  //String _selectedCoffee;

  late CoffeeService coffeeService;
  late EspressoMachineService machineService;

  final EditModes _editRosterMode = EditModes.show;
  final EditModes _editCoffeeMode = EditModes.show;

  List<DropdownMenuItem<int>> roasters = [];
  List<DropdownMenuItem<int>> coffees = [];

  CoffeeSelectionTabState() {
    newRoaster.name = "<new roaster>";
    newRoaster.id = 0;
    _selectedRoasterId = 0;
    newCoffee.name = "<new Beans>";
    newCoffee.id = 0;
    _selectedCoffeeId = 0;
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
    if (widget.saveToRecipe) coffeeService.setSelectedRecipeCoffee(_selectedCoffeeId);
    coffeeService.removeListener(updateCoffee);
    log.info('Disposed coffeeselection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).screenBeanSelectTitle),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CoffeeEdit(0)),
          );
        },
        // backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                              width: 150,
                              child: Text(S.of(context).screenBeanSelectSelectRoaster, style: theme.TextStyles.h2)),
                          Expanded(
                            flex: 8,
                            child: DropdownButton(
                              isExpanded: true,
                              alignment: Alignment.centerLeft,
                              value: _selectedRoasterId,
                              items: roasters,
                              onChanged: (value) async {
                                _selectedRoasterId = value!;
                                if (value == 0) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RoasterEdit(0)),
                                  );
                                } else {
                                  coffeeService.setSelectedRoaster(_selectedRoasterId);
                                }
                                // setState(() {});
                              },
                            ),
                          ),
                          if (_editRosterMode == EditModes.show)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    // _editRosterMode = EditModes.edit;
                                    // _editCoffeeMode = EditModes.show;
                                    // _editedRoaster = roaster;
                                    // form.value = _editedRoaster.toJson();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => RoasterEdit(_selectedRoasterId)),
                                    );
                                  });
                                },
                                child: Text(S.of(context).edit),
                              ),
                            ),
                        ],
                      ),
                      if (_selectedRoasterId > 0) roasterData(),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                              width: 150,
                              child: Text(S.of(context).screenBeanSelectSelectBeans, style: theme.TextStyles.h2)),
                          Expanded(
                            flex: 8,
                            child: DropdownButton(
                              isExpanded: true,
                              alignment: Alignment.centerLeft,
                              value: _selectedCoffeeId,
                              items: coffees,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCoffeeId = value!;
                                  if (value == 0) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const CoffeeEdit(0)),
                                    );
                                  } else {
                                    coffeeService.setSelectedCoffee(_selectedCoffeeId);
                                  }
                                });
                              },
                            ),
                          ),
                          if (_editCoffeeMode == EditModes.show)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => CoffeeEdit(_selectedCoffeeId)),
                                    );
                                    // _editCoffeeMode = EditModes.edit;
                                    // _editRosterMode = EditModes.show;
                                    // _editedCoffee = coffee;
                                    // form.value = _editedCoffee.toJson();
                                  });
                                },
                                child: Text(S.of(context).edit),
                              ),
                            ),
                        ],
                      ),
                      if (_selectedCoffeeId > 0) coffeeData(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<int>> loadRoasters() {
    final builder = coffeeService.roasterBox.query().order(Roaster_.name).build();
    var found = builder.find();

    var roasters = found
        .map((p) => DropdownMenuItem(
              value: p.id,
              child: Text(
                p.name,
                style: (p.coffees.firstWhereOrNull((element) => element.id == _selectedCoffeeId) != null)
                    ? const TextStyle(color: Colors.amber)
                    : const TextStyle(color: Colors.white60),
              ),
            ))
        .toList();
    roasters.insert(0, DropdownMenuItem(value: 0, child: Text(newRoaster.name)));
    return roasters;
  }

  List<DropdownMenuItem<int>> loadCoffees() {
    // Build and watch the query,
    // set triggerImmediately to emit the query immediately on listen.
    final builder = coffeeService.coffeeBox.query().order(Coffee_.name).build();
    var found = builder.find();

    var coffees = found
        .map(
          (p) => DropdownMenuItem(
              value: p.id,
              child: Text(
                p.name,
                style: (p.roaster.targetId == _selectedRoasterId)
                    ? const TextStyle(color: Colors.amber)
                    : const TextStyle(color: Colors.white60),
              )),
        )
        .toList();
    coffees.insert(0, DropdownMenuItem(value: 0, child: Text(newCoffee.name)));
    return coffees;
  }

  roasterData() {
    if (_selectedRoasterId == 0) return;

    var roaster = coffeeService.roasterBox.get(_selectedRoasterId)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyValueWidget(label: S.of(context).screenBeanSelectNameOfRoaster, value: roaster.name),
        if (roaster.description.isNotEmpty)
          KeyValueWidget(label: S.of(context).screenBeanSelectDescriptionOfRoaster, value: roaster.description),
        if (roaster.homepage.isNotEmpty)
          KeyValueWidget(label: S.of(context).screenBeanSelectHomepageOfRoaster, value: roaster.homepage),
        if (roaster.address.isNotEmpty)
          KeyValueWidget(label: S.of(context).screenBeanSelectAddressOfRoaster, value: roaster.address),
      ],
    );
  }

  coffeeData() {
    if (_selectedCoffeeId == 0) return;

    var coffee = coffeeService.coffeeBox.get(_selectedCoffeeId)!;
    DateTime d1 = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyValueWidget(label: S.of(context).screenBeanSelectNameOfBean, value: coffee.name),
        if (coffee.description.isNotEmpty)
          KeyValueWidget(label: S.of(context).screenBeanSelectDescriptionOfBean, value: coffee.description),
        const SizedBox(height: 10),
        KeyValueWidget(label: S.of(context).screenBeanSelectTasting, value: coffee.taste),
        KeyValueWidget(label: S.of(context).screenBeanSelectTypeOfBeans, value: coffee.type),
        KeyValueWidget(
            label: S.of(context).screenBeanSelectRoastingDate,
            value:
                "${DateFormat.Md().format(coffee.roastDate)}, ${d1.difference(coffee.roastDate).inDays} ${S.of(context).screenBeanSelectDaysAgo}"),
        const SizedBox(height: 10),
        KeyValueWidget(
          label: S.of(context).screenBeanSelectAcidity,
          value: "",
          widget: RatingBarIndicator(
            rating: coffee.acidRating,
            itemBuilder: (context, index) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            itemCount: 5,
            itemSize: 20.0,
            direction: Axis.horizontal,
          ),
        ),
        const SizedBox(height: 10),
        KeyValueWidget(
          label: S.of(context).screenBeanSelectIntensity,
          value: "",
          widget: RatingBarIndicator(
            rating: coffee.intensityRating,
            itemBuilder: (context, index) => const Icon(
              Icons.star,
              color: Colors.red,
            ),
            itemCount: 5,
            itemSize: 20.0,
            direction: Axis.horizontal,
          ),
        ),
        const SizedBox(height: 10),
        KeyValueWidget(
          label: S.of(context).screenBeanSelectRoastLevel,
          value: "",
          widget: RatingBarIndicator(
            rating: coffee.roastLevel,
            itemBuilder: (context, index) => const Icon(
              Icons.star,
              color: Colors.lightBlue,
            ),
            itemCount: 5,
            itemSize: 20.0,
            direction: Axis.horizontal,
          ),
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
          Text(key, style: Theme.of(context).textTheme.labelLarge),
          if (value != null) Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  void updateCoffee() {
    setState(
      () {
        _selectedCoffeeId = coffeeService.selectedCoffeeId;
        _selectedRoasterId = coffeeService.selectedRoasterId;
        roasters = loadRoasters();
        coffees = loadCoffees();
        log.info("Loaded Roasters $roasters");
        if (coffees.firstWhereOrNull((element) => element.value == _selectedCoffeeId) == null) {
          _selectedCoffeeId = 0;
        }
        if (roasters.firstWhereOrNull((element) => element.value == _selectedRoasterId) == null) {
          _selectedRoasterId = 0;
        }
      },
    );
  }
}
