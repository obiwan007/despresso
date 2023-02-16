import 'dart:async';

import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';

import 'package:angel3_framework/angel3_framework.dart';
import 'package:angel3_graphql/angel3_graphql.dart';
import 'package:graphql_schema2/graphql_schema2.dart';
import 'package:graphql_server2/graphql_server2.dart';

import 'settings_service.dart';

part 'graphql_service.g.dart';

// final client = MqttServerClient(mqttServer, mqttPort.toString());

class GraphQLService extends ChangeNotifier {
  final log = Logger('GrapQLService');

  late SettingsService settingsService;
  late EspressoMachineService machineService;

  late StreamSubscription<EspressoMachineFullState> streamStateSubscription;
  late StreamSubscription<int> streamBatterySubscription;
  late StreamSubscription<ShotState> streamShotSubscription;
  late StreamSubscription<WaterLevel> streamWaterSubscription;

  Angel? app;

  GraphQLService() {
    log.info('init');
  }

  stopService() {}

  Future<int> startService() async {
    settingsService = getIt<SettingsService>();
    machineService = getIt<EspressoMachineService>();
    app = Angel(
        logger: log
          ..onRecord.listen((rec) {
            log.info(rec);
            if (rec.error != null) print(rec.error);
            if (rec.stackTrace != null) print(rec.stackTrace);
          }));
    // var http = AngelHttp(app!);

    var todoService = app!.use('api/todos', MapService());
    var queryType = objectType(
      'Query',
      description: 'A simple API that manages your to-do list.',
      fields: [
        field(
          'todos',
          listOf(todoGraphQLType!.nonNullable()),
          resolve: resolveViaServiceIndex(todoService),
        ),
        field(
          'todo',
          todoGraphQLType!,
          resolve: resolveViaServiceRead(todoService),
          inputs: [
            GraphQLFieldInput('id', graphQLId.nonNullable()),
          ],
        ),
      ],
    );

    var schema = graphQLSchema(
      queryType: queryType,
    );

    app!.all('/graphql', graphQLHttp(GraphQL(schema)));
    app!.get('/graphiql', graphiQL());

    await todoService.create({
      'text': 'Clean your room!',
    });
    await todoService.create({'text': 'Take out the trash'});
    await todoService.create({'text': 'Become a billionaire at the age of 5'});

    //var server = await http.startServer('127.0.0.1', 3000);
    // var uri = Uri(scheme: 'http', host: server.address.address, port: server.port);
    // var graphiqlUri = uri.replace(path: 'graphiql');

    return 0;
  }

  void handleEvents() {}
}

@graphQLClass
class Todo {
  String text = "";

  @GraphQLDocumentation(description: 'Whether this item is complete.')
  bool isComplete = false;
}
