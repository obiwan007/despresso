import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../model/coffee.dart';
import '../../model/services/ble/machine_service.dart';

class CoffeeSelection {
  Widget getTabContent() {
    return CoffeeSelectionTab();
  }

  Widget getImage() {
    return CoffeeSelectionImage();
  }
}

class CoffeeSelectionImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: CachedNetworkImage(
        imageUrl:
            'https://images.squarespace-cdn.com/content/5d318463e8d6c50001d160a6/1563541579731-9HESYR1NGT92L2CWRJ3X/elemenza_Logo_BoA.png?format=1500w&content-type=image%2Fpng',
        width: 65,
        height: 65,
        color: theme.Colors.primaryColor,
        fit: BoxFit.scaleDown,
      ),
    );
  }
}

class CoffeeSelectionTab extends StatefulWidget {
  @override
  _CoffeeSelectionTabState createState() => _CoffeeSelectionTabState();
}

class _CoffeeSelectionTabState extends State<CoffeeSelectionTab> {
  final TextEditingController _typeAheadRoasterController = TextEditingController();
  final TextEditingController _typeAheadCoffeeController = TextEditingController();

  late Roaster? _selectedRoaster = null;
  late Coffee? _selectedCoffee = null;
  //String _selectedCoffee;

  late CoffeeService coffeeService;
  late EspressoMachineService machineService;

  @override
  void initState() {
    super.initState();
    coffeeService = getIt<CoffeeService>();
    machineService = getIt<EspressoMachineService>();
    coffeeService.addListener(updateCoffee);
  }

  @override
  void dispose() {
    super.dispose();
    coffeeService.removeListener(updateCoffee);
    log('Disposed coffeeselection');
  }

  @override
  Widget build(BuildContext context) {
    var roasters = coffeeService.knownRoasters
        .map((p) => DropdownMenuItem(
              value: p,
              child: Text("${p.name}"),
            ))
        .toList();
    var coffees = coffeeService.knownCoffees
        .map((p) => DropdownMenuItem(
              value: p,
              child: Text("${p.name}"),
            ))
        .toList();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addCoffee();
        },
        // backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("Select Roaster"),
            DropdownButton(
              isExpanded: true,
              alignment: Alignment.centerLeft,
              value: _selectedRoaster,
              items: roasters,
              onChanged: (value) {
                setState(() {
                  _selectedRoaster = value!;
                });
              },
            ),
            Text("Select Coffee"),
            DropdownButton(
              isExpanded: true,
              alignment: Alignment.centerLeft,
              value: _selectedCoffee,
              items: coffees,
              onChanged: (value) {
                setState(() {
                  _selectedCoffee = value!;
                });
              },
            ),

            // // TypeAheadFormField(
            // //   textFieldConfiguration: TextFieldConfiguration(
            // //     decoration: const InputDecoration(
            // //       labelText: 'Roaster',
            // //       labelStyle: theme.TextStyles.tabLabel,
            // //       contentPadding: EdgeInsets.zero,
            // //       border: InputBorder.none,
            // //       focusedBorder: InputBorder.none,
            // //       enabledBorder: InputBorder.none,
            // //       errorBorder: InputBorder.none,
            // //       disabledBorder: InputBorder.none,
            // //     ),
            // //     style: theme.TextStyles.tabSecondary,
            // //     controller: _typeAheadRoasterController,
            // //   ),
            // //   suggestionsCallback: (pattern) async {
            // //     return coffeeService.getRoasterSuggestions(pattern);
            // //   },
            // //   itemBuilder: (context, suggestion) {
            // //     return ListTile(
            // //       title: Text(suggestion),
            // //     );
            // //   },
            // //   transitionBuilder: (context, suggestionsBox, controller) {
            // //     return suggestionsBox;
            // //   },
            // //   onSuggestionSelected: (suggestion) {
            // //     _typeAheadRoasterController.text = suggestion;
            // //   },
            // //   validator: (value) {
            // //     if (value!.isEmpty) {
            // //       return 'Please select a roaster';
            // //     }
            // //     return null;
            // //   },
            // //   onSaved: (value) => _selectedRoaster = value!,
            // // ),
            // // TypeAheadFormField(
            // //   textFieldConfiguration: TextFieldConfiguration(
            // //       decoration: const InputDecoration(
            // //         labelText: 'Coffee',
            // //         labelStyle: theme.TextStyles.tabLabel,
            // //         contentPadding: EdgeInsets.zero,
            // //         border: InputBorder.none,
            // //         focusedBorder: InputBorder.none,
            // //         enabledBorder: InputBorder.none,
            // //         errorBorder: InputBorder.none,
            // //         disabledBorder: InputBorder.none,
            // //       ),
            // //       controller: _typeAheadCoffeeController,
            // //       style: theme.TextStyles.tabSecondary),
            // //   suggestionsCallback: (pattern) async {
            // //     return coffeeService.getCoffeeSuggestions(pattern, _selectedRoaster);
            // //   },
            // //   itemBuilder: (context, suggestion) {
            // //     return ListTile(
            // //       title: Text(suggestion),
            // //     );
            // //   },
            // //   transitionBuilder: (context, suggestionsBox, controller) {
            // //     return suggestionsBox;
            // //   },
            // //   onSuggestionSelected: (suggestion) {
            // //     _typeAheadCoffeeController.text = suggestion;
            // //   },
            // //   validator: (value) {
            // //     if (value!.isEmpty) {
            // //       return 'Please select a coffee';
            // //     }
            // //     return null;
            // //   },
            //   //onSaved: (value) => this._selectedCoffee = value,
            // ),
            Container(
                color: theme.Colors.backgroundColor,
                width: 24.0,
                height: 1.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0)),
            Row(
              children: <Widget>[
                const Icon(Icons.location_on, size: 14.0, color: theme.Colors.goodColor),
                Text(
                  "${_selectedCoffee?.origin ?? 'unknown'}",
                  style: theme.TextStyles.tabTertiary,
                ),
                Container(width: 24.0),
                const Icon(Icons.flight_land, size: 14.0, color: theme.Colors.goodColor),
                Text("${_selectedCoffee?.price}", style: theme.TextStyles.tabTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addCoffee() async {
    var r = Roaster();
    r.name = "Bärista";
    r.description = "Small little company in the middle of Berlin";
    await coffeeService.addRoaster(r);
    var c = Coffee();
    c.roasterId = r.id;
    c.name = "Bärige Mischung";
    c.acidRating = 5;
    c.arabica = 50;
    c.robusta = 50;
    c.grinderSettings = 10;
    c.description = "Cheap supermarket coffee";
    c.intensityRating = 5;
    c.roastLevel = 5;
    c.price = "20€";
    c.origin = "Columbia";
    await coffeeService.addCoffee(c);
  }

  void updateCoffee() {
    setState(
      () {},
    );
  }
}
