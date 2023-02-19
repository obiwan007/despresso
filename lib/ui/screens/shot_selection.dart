import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:despresso/model/shot.dart';
import 'package:despresso/objectbox.dart';
import 'package:despresso/objectbox.g.dart';
import 'package:despresso/ui/widgets/legend_list.dart';
import 'package:despresso/ui/widgets/shot_graph.dart';
import 'package:logging/logging.dart';

import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:intl/intl.dart';
import 'package:objectbox/objectbox.dart';
import 'package:objectbox/src/native/box.dart';
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

  CoffeeSelectionTabState() {}

  @override
  void initState() {
    super.initState();
    shotBox = getIt<ObjectBox>().store.box<Shot>();
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
              return ElevatedButton(
                onPressed: () => _onShare(context),
                child: Icon(Icons.ios_share),
              );
            },
          ),
        ],
      ),
      body: Row(
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
            child: selectedShots.length == 0
                ? Text("Nothing selected")
                : Column(
                    children: [
                      Row(
                        children: [
                          Text("Overlaymode:"),
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
                              borderRadius: BorderRadius.only(
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
            key: Key('list_item_$index'),
            direction: DismissDirection.startToEnd,
            onDismissed: (_) {
              setState(() {});
            },
            background: Container(
              color: Colors.red,
              margin: const EdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
            ),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: ListTile(
                key: Key('list_item_$index'),
                title: Text(
                  shots[index].profileId,
                  // style: const TextStyle(
                  //   fontSize: 15.0,
                  // ),

                  // Provide a Key for the integration test
                  key: Key('list_item_$index'),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${DateFormat().format(shots[index].date)}'),
                    Text(
                      '${shots[index].coffee.target!.name} (${shots[index].coffee.target?.roaster.target?.name})',
                    ),
                    Text(
                      '${shots[index].pourWeight.toStringAsFixed(1)}g in ${shots[index].pourTime.toStringAsFixed(1)}s ',
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
    if (selectedShots.length == 0) return;
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
