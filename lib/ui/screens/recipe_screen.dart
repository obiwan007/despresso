import 'package:despresso/model/recipe.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/coffee_selection.dart';
import 'package:despresso/ui/screens/profiles_screen.dart';
import 'package:flutter/material.dart';

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
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
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
            child: RecipeDetails(profileService: profileService, coffeeService: coffeeService),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Details",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            flex: 6,
                            child: Text(
                              "Graph",
                              style: Theme.of(context).textTheme.titleMedium,
                            )),
                        Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Description",
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(profileService.currentProfile?.shotHeader.notes ?? ""),
                                if (coffeeService.currentCoffee?.description.isNotEmpty == true)
                                  Text(
                                    "Coffee notes",
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                Text(coffeeService.currentCoffee?.description ?? ""),
                                StreamBuilder<int>(
                                    stream: machineService.streamBatteryState,
                                    builder: (context, snapshot) {
                                      return Column(
                                        children: [
                                          if (snapshot.hasData) Text("Battery: ${snapshot.data}"),
                                          if (machineService.de1 != null)
                                            Text("Mode: ${machineService.de1!.usbChargerMode}"),
                                          if (machineService.de1 != null)
                                            ElevatedButton(
                                                onPressed: () {
                                                  machineService.de1!.setUsbChargerMode(
                                                      machineService.de1!.usbChargerMode == 0 ? 1 : 0);
                                                },
                                                child: Text("Toggle USB Charger"))
                                        ],
                                      );
                                    })
                              ],
                            )),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _buildControls(context),
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
        data.name ?? "noname",
      ),
      subtitle: Text(
        data.profileId + " " + data.coffee.target!.name,
      ),
      selected: coffeeService.selectedRecipe == data.id,
      onTap: () {
        coffeeService.setSelectedRecipe(data.id);
      },
      trailing: ElevatedButton(
          onPressed: () {
            coffeeService.removeRecipe(data.id);
          },
          child: Icon(Icons.delete_forever)),
    );
  }
}

class RecipeDetails extends StatelessWidget {
  const RecipeDetails({
    Key? key,
    required this.profileService,
    required this.coffeeService,
  }) : super(key: key);

  final ProfileService profileService;
  final CoffeeService coffeeService;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Current Shot Recipe",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Container(
                color: Colors.black38,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(child: Text("Selected Base Profile")),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const ProfilesScreen()),
                                      );
                                    },
                                    child: Text(profileService.currentProfile?.title ?? "No Profile selected"),
                                  ),
                                  Text(
                                      "Stop weight: ${profileService.currentProfile?.shotHeader.targetWeight.toStringAsFixed(1)} g")
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Row(
                        //   children: [
                        //     Expanded(child: Text("Dial In Layer")),
                        //     Expanded(
                        //       child: ElevatedButton(
                        //         onPressed: () {},
                        //         child: Text("Reduced Flow"),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        const Divider(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(child: Text("Selected Bean")),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const CoffeeSelectionTab()),
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
                        ElevatedButton(
                          onPressed: () {},
                          child: Text("Add as Favorite"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            coffeeService.addRecipe(
                                name: profileService.currentProfile!.title + "/" + coffeeService.currentCoffee!.name,
                                coffeeId: coffeeService.selectedCoffee,
                                profileId: profileService.currentProfile!.id);
                          },
                          child: Text("Save Recipe"),
                        ),
                      ]),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
