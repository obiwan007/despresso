// ignore_for_file: unnecessary_string_interpolations

import 'package:despresso/model/recipe.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/services/state/screen_saver.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/coffee_selection.dart';
import 'package:despresso/ui/screens/profiles_screen.dart';
import 'package:despresso/ui/screens/recipe_edit.dart';
import 'package:despresso/ui/widgets/profile_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:despresso/generated/l10n.dart';

import '../../model/shotstate.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  RecipeScreenState createState() => RecipeScreenState();
}

class RecipeScreenState extends State<RecipeScreen> {
  final log = Logger('RecipeScreenState');
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
    setState(() => currentState = machineService.state.coffeeState);
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
                      padding: const EdgeInsets.all(10.0),
                      itemBuilder: (context, index) =>
                          snapshot.hasData ? buildItem(context, snapshot.data![index]) : const Text("empty"),
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
            // ignore: avoid_unnecessary_containers
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
              child: RecipeDescription(profileService: profileService, coffeeService: coffeeService),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     coffeeService.addRecipe(
      //         name:
      //             "${profileService.currentProfile?.title ?? "no profile selected"}/${coffeeService.currentCoffee?.name ?? "No bean selected"}",
      //         coffeeId: coffeeService.selectedCoffeeId,
      //         profileId: profileService.currentProfile?.id ?? "Default");
      //   },
      //   // backgroundColor: Colors.green,
      //   label: Text(S.of(context).screenRecipeAddRecipe),
      //   icon: const Icon(Icons.add),
      // ),
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
    return Dismissible(
      key: UniqueKey(),
      background: Container(
        color: Colors.red,
        margin: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.centerLeft,
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      onDismissed: (_) {
        coffeeService.removeRecipe(data.id);
        setState(() {});
      },
      child: ListTile(
        trailing: IconButton(
          icon: data.isFavorite ? const Icon(color: Colors.orange, Icons.star) : const Icon(Icons.star_border_outlined),
          tooltip: 'Favorite',
          onPressed: () {
            coffeeService.recipeFavoriteToggle(data);
          },
        ),
        title: Text(
          data.name,
        ),
        subtitle: Text(
          "${data.profileId} ${data.coffee.target?.name ?? "no bean"}",
        ),
        selected: coffeeService.selectedRecipeId == data.id,
        onTap: () {
          coffeeService.setSelectedRecipe(data.id);
        },
      ),
    );
  }
}

class RecipeDescription extends StatelessWidget {
  const RecipeDescription({
    super.key,
    required this.profileService,
    required this.coffeeService,
  });

  final ProfileService profileService;
  final CoffeeService coffeeService;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          S.of(context).screenRecipeRecipeDetails,
          style: Theme.of(context).textTheme.titleMedium,
        ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(coffeeService.currentRecipe?.description ?? ""),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
          child: Row(
            children: [
              Text(S.of(context).screenRecipehotWater),
              Text("${(coffeeService.currentRecipe?.useWater ?? false) ? "" : S.of(context).no}"),
              Text((coffeeService.currentRecipe?.useWater ?? false)
                  ? " ${coffeeService.currentRecipe?.weightWater} g"
                  : ""),
            ],
          ),
        ),
        if (coffeeService.currentRecipe?.disableStopOnWeight == true)
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
            child: Row(
              children: [
                Text(S.of(context).screenRecipeStopOnWeight),
                Text("${(coffeeService.currentRecipe?.disableStopOnWeight ?? false) ? S.of(context).no : ""}"),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
          child: Row(
            children: [
              Text(S.of(context).screenRecipesteamMilk),
              Text((coffeeService.currentRecipe?.useSteam ?? false) ? "" : S.of(context).no),
              Text((coffeeService.currentRecipe?.useSteam ?? false)
                  ? " ${coffeeService.currentRecipe?.weightMilk} g"
                  : ""),
            ],
          ),
        ),
        const Divider(),

        Text(
          S.of(context).screenRecipeProfileDetails,
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
              S.of(context).screenRecipeCoffeeNotes,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        Text(coffeeService.currentCoffee?.description ?? ""),

        /// To make it possible to read because of Add recipe overlay button
        const SizedBox(height: 80),
      ],
    );
  }
}

enum SelectedMenu { edit, copy, add }

class RecipeDetails extends StatefulWidget {
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
  State<RecipeDetails> createState() => _RecipeDetailsState();
}

class _RecipeDetailsState extends State<RecipeDetails> {
  final log = Logger('RecipeDetails');

  late ScreensaverService _screensaver;

  @override
  void initState() {
    super.initState();
    _screensaver = getIt<ScreensaverService>();
  }

  @override
  Widget build(BuildContext context) {
    var nameOfRecipe = widget.coffeeService.currentRecipe?.name ?? "no name";

    var firstFrame = widget.profileService.currentProfile?.firstFrame();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Text(
        //   "Current Shot Recipe",
        //   style: Theme.of(context).textTheme.titleMedium,
        // ),
        Row(
          children: [
            Expanded(
              child: Text(
                nameOfRecipe,
                key: Key(nameOfRecipe),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            PopupMenuButton<SelectedMenu>(
              initialValue: null,
              // Callback that sets the selected popup menu item.
              onSelected: (SelectedMenu item) async {
                switch (item) {
                  case SelectedMenu.add:
                    var id = widget.coffeeService.addRecipe(
                        name:
                            "${widget.profileService.currentProfile?.title ?? "no profile selected"}/${widget.coffeeService.currentCoffee?.name ?? "No bean selected"}",
                        coffeeId: widget.coffeeService.selectedCoffeeId,
                        profileId: widget.profileService.currentProfile?.id ?? "Default");
                    _screensaver.pause();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RecipeEdit(
                                id,
                                title: "Add Recipe",
                              )),
                    );
                    _screensaver.resume();
                    break;
                  case SelectedMenu.edit:
                    _screensaver.pause();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RecipeEdit(
                                widget.coffeeService.currentRecipe?.id ?? 0,
                              )),
                    );
                    _screensaver.resume();
                    widget.coffeeService.setSelectedRecipe(widget.coffeeService.currentRecipe!.id);

                    break;
                  case SelectedMenu.copy:
                    var id = await widget.coffeeService.copyRecipeFromId(widget.coffeeService.currentRecipe!.id);
                    if (id > 0) {
                      _screensaver.pause();
                      // ignore: use_build_context_synchronously
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RecipeEdit(
                                  id,
                                  title: "Copy Recipe",
                                )),
                      );
                      _screensaver.resume();
                      widget.coffeeService.setSelectedRecipe(id);
                    }
                    break;
                }
                // setState(() {
                //   selectedMenu = item;
                // });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<SelectedMenu>>[
                const PopupMenuItem<SelectedMenu>(
                  value: SelectedMenu.edit,
                  child: Text('Edit'),
                ),
                const PopupMenuItem<SelectedMenu>(
                  value: SelectedMenu.copy,
                  child: Text('Copy'),
                ),
                const PopupMenuItem<SelectedMenu>(
                  value: SelectedMenu.add,
                  child: Text('Add'),
                ),
              ],
            ),
            // IconButton(
            //   key: Key(nameOfRecipe),
            //   onPressed: () async {
            //     _screensaver.pause();
            //     var result = await Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //           builder: (context) => RecipeEdit(
            //                 widget.coffeeService.currentRecipe?.id ?? 0,
            //               )),
            //     );
            //     _screensaver.resume();
            //     widget.coffeeService.setSelectedRecipe(widget.coffeeService.currentRecipe!.id);
            //   },
            //   icon: const Icon(Icons.edit),
            // ),
          ],
        ),
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
                          Expanded(child: Text(S.of(context).screenRecipeSelectedProfile)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(40), // NEW
                                  ),
                                  onPressed: () async {
                                    var result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const ProfilesScreen(
                                                saveToRecipe: false,
                                              )),
                                    );
                                    log.info("New profile selected $result");
                                    if (result == null) {
                                      return;
                                    }
                                    widget.coffeeService.setSelectedRecipeProfile(result!.id);
                                    widget.coffeeService.setSelectedRecipe(widget.coffeeService.currentRecipe!.id);
                                  },
                                  child: Text(widget.profileService.currentProfile?.title ?? "No Profile selected"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Row(
                      //   crossAxisAlignment: CrossAxisAlignment.center,
                      //   children: [
                      //     const Expanded(child: Text("Suggested stop weight:")),
                      //     Expanded(
                      //       child: Column(
                      //         crossAxisAlignment: CrossAxisAlignment.center,
                      //         children: [
                      //           Text(
                      //               "${widget.profileService.currentProfile?.shotHeader.targetWeight.toStringAsFixed(1)} g"),
                      //         ],
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      if ((firstFrame?.temp ?? 0) > 0)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: Text(S.of(context).screenRecipeInitialTemp)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text("${firstFrame?.temp.toStringAsFixed(1)} °C"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      const Divider(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: Text(S.of(context).screenRecipeSelectedBean)),
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
                                          builder: (context) => const CoffeeSelectionTab(saveToRecipe: true)),
                                    );
                                  },
                                  child: Text(widget.coffeeService.currentCoffee?.name ?? "No Bean selected"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(),

                      // if ((widget.coffeeService.currentRecipe?.grinderSettings ?? 0) > 0)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: Text(S.of(context).screenRecipeGrindSettings)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SpinBox(
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                  textInputAction: TextInputAction.done,
                                  onChanged: (value) {
                                    var r = widget.coffeeService.currentRecipe;
                                    if (r != null) {
                                      r.grinderSettings = value;
                                      widget.coffeeService.updateRecipe(r);
                                    }
                                  },
                                  max: 120.0,
                                  value: widget.coffeeService.currentRecipe?.grinderSettings ?? 0.0,
                                  decimals: 1,
                                  step: 0.1,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.only(left: 5, bottom: 24, top: 24, right: 5),
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
                          Expanded(child: Text(S.of(context).screenRecipeRatio)),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    "${formatRatio(widget.coffeeService.currentRecipe?.ratio1 ?? 0.0)} : ${formatRatio(widget.coffeeService.currentRecipe?.ratio2 ?? 0.0)}"),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _openRatioDialog();
                                    setState(() => {});
                                  },
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: Text(S.of(context).screenRecipeWeightinBeansG)),
                          Expanded(
                            child: Column(
                              children: [
                                SpinBox(
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                  textInputAction: TextInputAction.done,
                                  onChanged: (value) {
                                    var r = widget.coffeeService.currentRecipe;
                                    if (r != null) {
                                      r.grinderDoseWeight = value;
                                      r.adjustedWeight = value * (r.ratio2 / r.ratio1);
                                      widget.coffeeService.updateRecipe(r);
                                      widget.settingsService.targetEspressoWeight = r.adjustedWeight;
                                    }
                                  },
                                  max: 120.0,
                                  value: widget.coffeeService.currentRecipe?.grinderDoseWeight ?? 0.0,
                                  decimals: 1,
                                  step: 0.1,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.only(left: 5, bottom: 24, top: 24, right: 5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (widget.coffeeService.currentRecipe?.disableStopOnWeight == false)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: Text(S.of(context).screenRecipeStopOnWeightG)),
                            Expanded(
                              child: Column(
                                children: [
                                  SpinBox(
                                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                    textInputAction: TextInputAction.done,
                                    onChanged: (value) {
                                      var r = widget.coffeeService.currentRecipe;
                                      if (r != null) {
                                        r.adjustedWeight = value;
                                        widget.coffeeService.updateRecipe(r);
                                        widget.settingsService.targetEspressoWeight = value;
                                      }
                                    },
                                    min: 0.0,
                                    max: 300.0,
                                    value: widget.settingsService.targetEspressoWeight,
                                    decimals: 1,
                                    step: 0.1,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.only(left: 5, bottom: 24, top: 24, right: 5),
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
                          Expanded(child: Text(S.of(context).screenRecipeAdjustTempC)),
                          Expanded(
                            child: Column(
                              children: [
                                SpinBox(
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                  textInputAction: TextInputAction.done,
                                  onChanged: (value) {
                                    var r = widget.coffeeService.currentRecipe;
                                    if (r != null) {
                                      r.adjustedTemp = value;
                                      widget.coffeeService.updateRecipe(r);
                                    }
                                  },
                                  min: -5.0,
                                  max: 5.0,
                                  value: widget.settingsService.targetTempCorrection.toDouble(),
                                  decimals: 1,
                                  step: 0.1,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.only(left: 5, bottom: 24, top: 24, right: 5),
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

  String formatRatio(double r) {
    var f = NumberFormat("#.#");
    return f.format(r);
  }

  Future<String?> _openRatioDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.current.screenRecipeSetRatio),
          content: SizedBox(
            height: 200,
            child: Column(
              children: [
                SpinBox(
                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  textInputAction: TextInputAction.done,
                  onChanged: (value) {
                    var r = widget.coffeeService.currentRecipe;
                    if (r != null) {
                      r.ratio1 = value;
                      widget.coffeeService.updateRecipe(r);
                    }
                  },
                  min: 1,
                  max: 10.0,
                  value: widget.coffeeService.currentRecipe!.ratio1,
                  decimals: 1,
                  step: 0.1,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 5, bottom: 24, top: 24, right: 5),
                  ),
                ),
                const Text(":"),
                SpinBox(
                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  textInputAction: TextInputAction.done,
                  onChanged: (value) {
                    var r = widget.coffeeService.currentRecipe;
                    if (r != null) {
                      r.ratio2 = value;
                      widget.coffeeService.updateRecipe(r);
                    }
                  },
                  min: 1,
                  max: 10.0,
                  value: widget.coffeeService.currentRecipe!.ratio2,
                  decimals: 1,
                  step: 0.1,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 5, bottom: 24, top: 24, right: 5),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(S.current.ok),
              onPressed: () {
                // widget.coffeeService.currentRecipe?.ratio1 = double.parse(_ratio1);
                var r = widget.coffeeService.currentRecipe!;
                var value = r.grinderDoseWeight;
                r.adjustedWeight = value * (r.ratio2 / r.ratio1);
                widget.coffeeService.updateRecipe(r);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String? numberValidator(String? value) {
    if (value == null) {
      return null;
    }
    final n = num.tryParse(value);
    if (n == null) {
      return '"$value" is not a valid number';
    }
    return null;
  }
}
