import 'package:despresso/model/recipe.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/coffee_selection.dart';
import 'package:despresso/ui/screens/profiles_screen.dart';
import 'package:despresso/ui/widgets/editable_text.dart';
import 'package:despresso/ui/widgets/profile_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';

import '../../model/shotstate.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  RecipeScreenState createState() => RecipeScreenState();
}

class RecipeScreenState extends State<RecipeScreen> {
  late EspressoMachineService machineService;
  late ProfileService profileService;
  late CoffeeService coffeeService;
  late ScaleService scaleService;
  late SettingsService settingsService;

  List<ShotState> dataPoints = [];
  EspressoMachineState currentState = EspressoMachineState.disconnected;

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();

    // Scale services is consumed as stream
    scaleService = getIt<ScaleService>();
    profileService = getIt<ProfileService>();
    coffeeService = getIt<CoffeeService>();
    settingsService = getIt<SettingsService>();
    coffeeService.addListener(coffeeServiceListener);
    profileService.addListener(profileServiceListener);
  }

  @override
  void dispose() {
    super.dispose();
    coffeeService.removeListener(coffeeServiceListener);
    profileService.removeListener(profileServiceListener);
  }

  machineStateListener() {
    setState(() => {currentState = machineService.state.coffeeState});
    // machineService.de1?.setIdleState();
  }

  Widget _buildControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              color: Theme.of(context).listTileTheme.tileColor,
              child: StreamBuilder<List<Recipe>>(
                  stream: coffeeService.streamRecipe,
                  initialData: coffeeService.getRecipes(),
                  builder: (context, snapshot) {
                    return ListView.builder(
                      padding: EdgeInsets.all(10.0),
                      itemBuilder: (context, index) => buildItem(context, snapshot.data![index]),
                      itemCount: snapshot.data?.length ?? 0,
                    );
                  }),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
                child: SingleChildScrollView(
                    child: RecipeDetails(
              profileService: profileService,
              coffeeService: coffeeService,
              settingsService: settingsService,
            ))),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Details",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (profileService.currentProfile != null)
                    AspectRatio(
                      aspectRatio: 1.3,
                      child: ProfileGraphWidget(
                          key: Key(profileService.currentProfile?.id ?? UniqueKey().toString()),
                          selectedProfile: profileService.currentProfile!),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(profileService.currentProfile?.shotHeader.notes ?? ""),
                  ),
                  if (coffeeService.currentCoffee?.description.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Coffee notes",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  Text(coffeeService.currentCoffee?.description ?? ""),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          coffeeService.addRecipe(
              name: "${profileService.currentProfile!.title}/${coffeeService.currentCoffee!.name}",
              coffeeId: coffeeService.selectedCoffeeId,
              profileId: profileService.currentProfile!.id);
        },
        // backgroundColor: Colors.green,
        label: const Text('Add recipe'),
        icon: const Icon(Icons.add),
      ),
      body: Container(
        child: _buildControls(context),
      ),
    );
  }

  void coffeeServiceListener() {
    setState(() {});
  }

  void profileServiceListener() {
    setState(() {});
  }

  buildItem(BuildContext context, Recipe data) {
    return ListTile(
      title: Text(
        data.name,
      ),
      subtitle: Text(
        "${data.profileId} ${data.coffee.target!.name}",
      ),
      selected: coffeeService.selectedRecipeId == data.id,
      onTap: () {
        coffeeService.setSelectedRecipe(data.id);
      },
      trailing: ElevatedButton(
          onPressed: () {
            coffeeService.removeRecipe(data.id);
          },
          child: const Icon(Icons.delete_forever)),
    );
  }
}

class RecipeDetails extends StatelessWidget {
  const RecipeDetails({
    Key? key,
    required this.profileService,
    required this.coffeeService,
    required this.settingsService,
  }) : super(key: key);

  final ProfileService profileService;
  final CoffeeService coffeeService;
  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    var nameOfRecipe = coffeeService.getSelectedRecipe()?.name ?? "no name";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Text(
        //   "Current Shot Recipe",
        //   style: Theme.of(context).textTheme.titleMedium,
        // ),
        IconEditableText(
            key: Key(nameOfRecipe),
            initialValue: nameOfRecipe,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
            onChanged: (value) {
              var res = coffeeService.getSelectedRecipe();
              if (res != null) {
                res.name = value;
                coffeeService.updateRecipe(res);
              }
            }),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Card(
              // color: Colors.black38,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(child: Text("Selected Base Profile")),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(40), // NEW
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ProfilesScreen(
                                                saveToRecipe: true,
                                              )),
                                    );
                                  },
                                  child: Text(profileService.currentProfile?.title ?? "No Profile selected"),
                                ),
                                Text(
                                    "Suggested stop weight: ${profileService.currentProfile?.shotHeader.targetWeight.toStringAsFixed(1)} g"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(child: Text("Selected Bean")),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(40), // NEW
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => CoffeeSelectionTab(saveToRecipe: true)),
                                    );
                                  },
                                  child: Text(coffeeService.currentCoffee?.name ?? "No Coffee selected"),
                                ),
                                Text("Dose: ${coffeeService.currentCoffee?.grinderDoseWeight.toStringAsFixed(1)} g"),
                                Text("Grind Settings: ${coffeeService.currentCoffee?.grinderSettings ?? ''}"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(child: Text("Stop on Weight")),
                          Expanded(
                            child: Column(
                              children: [
                                SpinBox(
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                  textInputAction: TextInputAction.done,
                                  onChanged: (value) {
                                    var r = coffeeService.getSelectedRecipe();
                                    if (r != null) {
                                      r.adjustedWeight = value;
                                      coffeeService.updateRecipe(r);
                                      settingsService.targetEspressoWeight = value;
                                    }
                                  },
                                  max: 120.0,
                                  value: settingsService.targetEspressoWeight,
                                  decimals: 1,
                                  step: 0.5,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.only(left: 15, bottom: 24, top: 24, right: 15),
                                    suffix: Text('g'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(child: Text("Adjust temperature")),
                          Expanded(
                            child: Column(
                              children: [
                                SpinBox(
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                  textInputAction: TextInputAction.done,
                                  onChanged: (value) {
                                    var r = coffeeService.getSelectedRecipe();
                                    if (r != null) {
                                      r.adjustedTemp = value;
                                      coffeeService.updateRecipe(r);
                                    }
                                  },
                                  min: -5.0,
                                  max: 5.0,
                                  value: settingsService.targetTempCorrection.toDouble(),
                                  decimals: 1,
                                  step: 0.1,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.only(left: 15, bottom: 24, top: 24, right: 15),
                                    suffix: Text('°C'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ]),
              ),
            )
          ],
        ),
      ],
    );
  }
}
