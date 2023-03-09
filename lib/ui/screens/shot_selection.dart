import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/model/services/state/visualizer_service.dart';
import 'package:despresso/model/shot.dart';
import 'package:despresso/objectbox.dart';
import 'package:despresso/objectbox.g.dart';
import 'package:despresso/ui/widgets/legend_list.dart';
import 'package:despresso/ui/widgets/progress_overlay.dart';
import 'package:despresso/ui/widgets/shot_graph.dart';
import 'package:logging/logging.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:intl/intl.dart';
import 'package:reactive_flutter_rating_bar/reactive_flutter_rating_bar.dart';
import 'package:share_plus/share_plus.dart';

class ShotSelectionTab extends StatefulWidget {
  const ShotSelectionTab({super.key});

  @override
  ShotSelectionTabState createState() => ShotSelectionTabState();
}

enum EditModes { show, add, edit }

class ShotSelectionTabState extends State<ShotSelectionTab> {
  final log = Logger('ShotSelectionTabState');

  late Box<Shot> shotBox;

  List<int> selectedShots = [];

  bool _overlay = false;

  bool showPressure = true;
  bool showFlow = true;
  bool showWeight = true;
  bool showTemp = true;

  late VisualizerService visualizerService;
  late SettingsService settingsService;

  bool _busy = false;

  double _busyProgress = 0;

  CoffeeSelectionTabState() {}

  @override
  void initState() {
    super.initState();
    shotBox = getIt<ObjectBox>().store.box<Shot>();
    visualizerService = getIt<VisualizerService>();
    settingsService = getIt<SettingsService>();
  }

  @override
  void dispose() {
    super.dispose();

    log.info('Disposed coffeeselection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shot Database'),
        actions: [
          Builder(
            builder: (BuildContext context) {
              return TextButton.icon(
                onPressed: () => _onShare(context),
                icon: const Icon(Icons.ios_share),
                label: const Text("CSV"),
              );
            },
          ),
          if (settingsService.visualizerUpload)
            TextButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text("Visualizer"),
              onPressed: () async {
                if (selectedShots.isEmpty) {
                  var snackBar = SnackBar(
                      content: const Text("No shots to upload selected"),
                      action: SnackBarAction(
                        label: 'Ok',
                        onPressed: () {
                          // Some code to undo the change.
                        },
                      ));
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  return;
                }
                try {
                  setState(() {
                    _busy = true;
                  });
                  for (var element in selectedShots) {
                    setState(() {
                      _busyProgress += 1 / selectedShots.length;
                    });
                    var shot = shotBox.get(element);
                    var id = await visualizerService.sendShotToVisualizer(shot!);
                    shot.visualizerId = id;
                    shotBox.put(shot);
                  }
                  var snackBar = SnackBar(
                      backgroundColor: Colors.greenAccent,
                      content: const Text("Success uploading your shots"),
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
                      content: Text("Error uploading shots: $e"),
                      action: SnackBarAction(
                        label: 'Ok',
                        onPressed: () {
                          // Some code to undo the change.
                        },
                      ));
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  log.severe("Error uploading shots $e");
                }
                setState(() {
                  _busy = false;
                  _busyProgress = 0;
                });
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 445,
              child: StreamBuilder<List<Shot>>(
                  stream: getShots(),
                  builder: (context, snapshot) => ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: snapshot.hasData ? snapshot.data!.length : 0,
                      itemBuilder: _shotListBuilder(snapshot.data ?? []))),
            ),
            Expanded(
              child: selectedShots.isEmpty
                  ? const Text("Nothing selected")
                  : Column(
                      children: [
                        Row(
                          children: [
                            const Text("Overlaymode:"),
                            Switch(
                              value: _overlay,
                              onChanged: (value) {
                                setState(() {
                                  _overlay = value;
                                });
                              },
                            ),
                          ],
                        ),
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _overlay ? min(selectedShots.length, 1) : selectedShots.length,
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(32),
                                  bottomLeft: Radius.circular(32),
                                ),
                                child: ListTile(
                                  title: ShotGraph(
                                      key: UniqueKey(),
                                      id: selectedShots[index],
                                      overlayIds: _overlay ? selectedShots : null,
                                      showFlow: showFlow,
                                      showPressure: showPressure,
                                      showWeight: showWeight,
                                      showTemp: showTemp),
                                ),
                              );
                            },
                          ),
                        ),
                        LegendsListWidget(
                          legends: [
                            Legend(
                              'Pressure',
                              theme.ThemeColors.pressureColor,
                              value: showPressure,
                              onChanged: (p0) {
                                setState(() {
                                  showPressure = p0;
                                });
                              },
                            ),
                            Legend(
                              'Flow',
                              theme.ThemeColors.flowColor,
                              value: showFlow,
                              onChanged: (p0) {
                                setState(() {
                                  showFlow = p0;
                                });
                              },
                            ),
                            Legend(
                              'Weight',
                              theme.ThemeColors.weightColor,
                              value: showWeight,
                              onChanged: (p0) {
                                setState(() {
                                  showWeight = p0;
                                });
                              },
                            ),
                            Legend(
                              'Temp',
                              theme.ThemeColors.tempColor,
                              value: showTemp,
                              onChanged: (p0) {
                                setState(() {
                                  showTemp = p0;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<Shot>> getShots() {
    // Query for all notes, sorted by their date.
    // https://docs.objectbox.io/queries
    final builder = shotBox.query().order(Shot_.date, flags: Order.descending);
    // Build and watch the query,
    // set triggerImmediately to emit the query immediately on listen.
    return builder
        .watch(triggerImmediately: true)
        // Map it to a list of notes to be used by a StreamBuilder.
        .map((query) => query.find());
  }

  Dismissible Function(BuildContext, int) _shotListBuilder(List<Shot> shots) =>
      (BuildContext context, int index) => Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.startToEnd,
            onDismissed: (_) {
              setState(() {
                var id = shots[index].id;
                selectedShots.removeWhere((element) => element == id);
                shotBox.remove(id);
              });
            },
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
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: ListTile(
                key: Key('list_item_${shots[index].id}'),
                title: Text(
                  shots[index].profileId,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat().format(shots[index].date)),
                    Text(
                      '${shots[index].coffee.target?.name ?? 'no coffee'} (${shots[index].coffee.target?.roaster.target?.name ?? 'no roaster'})',
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${shots[index].pourWeight.toStringAsFixed(1)}g in ${shots[index].pourTime.toStringAsFixed(1)}s ',
                        ),
                        if (shots[index].enjoyment > 0)
                          RatingBarIndicator(
                            rating: shots[index].enjoyment,
                            itemBuilder: (context, index) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            itemCount: 5,
                            itemSize: 20.0,
                            direction: Axis.horizontal,
                          ),
                      ],
                    ),
                  ],
                ),
                // trailing: OutlinedButton(
                //   onPressed: () {},
                //   child: Icon(Icons.delete_forever),
                // ),
                onTap: () {
                  setSelection(shots[index].id);
                },
                selected: selectedShots.contains(shots[index].id),
              ),
            ),
          );

  setSelection(int id) {
    var found = selectedShots.firstWhereOrNull((element) => element == id);
    if (found == null) {
      selectedShots.add(id);
    } else {
      selectedShots.removeWhere((element) => element == id);
    }
    setState(() {});
  }

  _onShare(BuildContext context) async {
    // _onShare method:
    if (selectedShots.isEmpty) return;
    final box = context.findRenderObject() as RenderBox?;
    var shot = shotBox.get(selectedShots.first);
    var list = shot!.shotstates.toList().map((entry) {
      return [
        shot.date,
        shot.coffee.target!.name,
        shot.pourWeight,
        shot.pourTime,
        shot.profileId,
        entry.sampleTimeCorrected,
        entry.frameNumber,
        entry.weight,
        entry.flowWeight,
        entry.headTemp,
        entry.mixTemp,
        entry.groupFlow,
        entry.groupPressure,
        entry.setGroupFlow,
        entry.setGroupPressure,
        entry.setHeadTemp,
        entry.setMixTemp,
      ];
    }).toList();
    var header = [
      "date",
      "name",
      "pourWeight",
      "pourTime",
      "profileId",
      "sampleTimeCorrected",
      "frameNumber",
      "weight",
      "flowWeight",
      "headTemp",
      "mixTemp",
      "groupFlow",
      "groupPressure",
      "setGroupFlow",
      "setGroupPressure",
      "setHeadTemp",
      "setMixTemp",
    ];
    list.insert(0, header);
    String csv = const ListToCsvConverter().convert(list, fieldDelimiter: ";");

    final List<int> codeUnits = csv.codeUnits;
    final Uint8List unit8List = Uint8List.fromList(codeUnits);
    var xfile = XFile.fromData(unit8List, mimeType: "text/csv");

    await Share.shareXFiles(
      [xfile],
      subject: "text/comma_separated_values/csv",
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }
}
