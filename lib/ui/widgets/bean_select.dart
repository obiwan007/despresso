import 'package:collection/collection.dart';
import 'package:despresso/model/coffee.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/objectbox.g.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';

class BeanSelect extends StatefulWidget {
  const BeanSelect({Key? key, this.onChanged}) : super(key: key);
  final void Function(int)? onChanged;
  @override
  _BeanSelectState createState() => _BeanSelectState();
}

class _BeanSelectState extends State<BeanSelect> {
  int _selectedCoffeeId = 0;

  List<DropdownMenuItem<int>> coffees = [];
  Coffee newCoffee = Coffee();

  late CoffeeService _coffeeService;

  @override
  void initState() {
    super.initState();
    _coffeeService = getIt<CoffeeService>();

    newCoffee.name = "<new Beans>";
    newCoffee.id = 0;

    updateCoffee();
    _coffeeService.addListener(updateCoffee);
  }

  @override
  void dispose() {
    super.dispose();
    _coffeeService.removeListener(updateCoffee);
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      isExpanded: true,
      alignment: Alignment.centerLeft,
      value: _selectedCoffeeId,
      items: coffees,
      onChanged: (value) {
        setState(() {
          if (value != 0) {
            _selectedCoffeeId = value!;
            _coffeeService.setSelectedCoffee(_selectedCoffeeId);
          }
          if (widget.onChanged != null) widget.onChanged!(value!);
        });
      },
    );
  }

  List<DropdownMenuItem<int>> loadCoffees() {
    // Build and watch the query,
    // set triggerImmediately to emit the query immediately on listen.
    final builder = _coffeeService.coffeeBox.query().order(Coffee_.name).build();
    var found = builder.find();

    var coffees = found
        .map(
          (p) => DropdownMenuItem(
              value: p.id,
              child: Text(
                p.name,
              )),
        )
        .toList();
    coffees.insert(0, DropdownMenuItem(value: 0, child: Text(newCoffee.name)));
    return coffees;
  }

  void updateCoffee() {
    setState(
      () {
        _selectedCoffeeId = _coffeeService.selectedCoffeeId;

        coffees = loadCoffees();

        if (coffees.firstWhereOrNull((element) => element.value == _selectedCoffeeId) == null) {
          _selectedCoffeeId = 0;
        }
      },
    );
  }
}
