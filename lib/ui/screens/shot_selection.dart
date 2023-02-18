import 'package:collection/collection.dart';
import 'package:despresso/model/shot.dart';
import 'package:despresso/objectbox.dart';
import 'package:despresso/objectbox.g.dart';
import 'package:despresso/ui/widgets/key_value.dart';
import 'package:logging/logging.dart';

import 'package:despresso/model/coffee.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/coffee_edit.dart';
import 'package:despresso/ui/screens/roaster_edit.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:intl/intl.dart';
import 'package:objectbox/objectbox.dart';
import 'package:objectbox/src/native/box.dart';
import 'package:reactive_flutter_rating_bar/reactive_flutter_rating_bar.dart';

import '../../model/services/ble/machine_service.dart';

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
      body: Column(
        children: [
          Row(
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
              Expanded(child: Text("Selected: $selectedShots")),
            ],
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
                  setSelection(index);
                },
                selected: selectedShots.contains(index),
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
}
