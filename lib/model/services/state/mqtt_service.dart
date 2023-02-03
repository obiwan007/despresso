import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'settings_service.dart';
import 'package:despresso/logger_util.dart';

// final client = MqttServerClient(mqttServer, mqttPort.toString());

class MqttService extends ChangeNotifier {
  final log = getLogger();
  late SettingsService settingsService;
  late EspressoMachineService machineService;
  late MqttClient client;
  final subTopic = 'despresso';
  String rootTopic = "despresso";

  bool connected = false;

  late StreamSubscription<EspressoMachineFullState> streamStateSubscription;
  late StreamSubscription<int> streamBatterySubscription;
  late StreamSubscription<ShotState> streamShotSubscription;
  late StreamSubscription<WaterLevel> streamWaterSubscription;

  MqttService() {
    log.i('MQTT:init mqtt');
    settingsService = getIt<SettingsService>();
    machineService = getIt<EspressoMachineService>();
    if (settingsService.mqttRootTopic.isNotEmpty) {
      rootTopic = "despresso/${settingsService.mqttRootTopic}";
    }
    startService();
  }

  Future<int> startService() async {
    connected = false;
    if (settingsService.mqttEnabled) {
      try {
        client = MqttServerClient(settingsService.mqttServer, "");
        client.port = int.parse(settingsService.mqttPort);
        log.i('MQTT:mqtt enabled starting service');
        client.logging(on: true);
        log.i('MQTT:mqtt service started');
        client.keepAlivePeriod = 60;
        client.onDisconnected = onDisconnected;
        client.setProtocolV31();

        client.onConnected = onConnected;
        client.onSubscribed = onSubscribed;
        client.pongCallback = pong;

        final connMess = MqttConnectMessage()
            .withClientIdentifier('despresso')
            // .withWillTopic('willtopic')
            // .withWillMessage('My Will message')
            .startClean()
            .withWillQos(MqttQos.atLeastOnce);
        log.i('MQTT: Client connecting....');
        client.connectionMessage = connMess;

        try {
          log.i('MQTT:trying to connect');
          await client.connect(settingsService.mqttUser, settingsService.mqttPassword);
        } on NoConnectionException catch (e) {
          log.e('MQTT: Client exception: $e');
          client.disconnect();
        } on SocketException catch (e) {
          log.e('MQTT: Socket exception: $e');
          client.disconnect();
        }
      } catch (ex) {
        log.e("MQTT: Exception: $ex");
        return -1;
      }

      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        log.i('MQTT: Client connected');
      } else {
        log.e('MQTT:Client connection failed - disconnecting, status is ${client.connectionStatus}');
        client.disconnect();
        return -1;
      }

      log.i('MQTT:Subscribing to the $subTopic topic');
      client.subscribe(subTopic, MqttQos.atMostOnce);
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final recMess = c![0].payload as MqttPublishMessage;
        final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        log.i('MQTT:Received message: topic is ${c[0].topic}, payload is $pt');
      });

      client.published!.listen((MqttPublishMessage message) {
        log.v('MQTT:Published topic: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
      });

      log.i('MQTT:Publishing our topic');
      var pubTopic = '$rootTopic/status';
      final builder = MqttClientPayloadBuilder();
      builder.addString(DateTime.now().toIso8601String());
      client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);

      connected = true;

      // log.i('MQTT:Sleeping....');
      // await MqttUtilities.asyncSleep(80);

      // log.i('MQTT:Unsubscribing');
      // client.unsubscribe(subTopic);
      // client.unsubscribe(pubTopic);

      // await MqttUtilities.asyncSleep(2);
      // log.i('MQTT:Disconnecting');
      // client.disconnect();
    }
    return 0;
  }

  void disconnect() async {
    if (!connected) return;

    log.i('MQTT:Unsubscribing');
    client.unsubscribe(subTopic);
    // client.unsubscribe(pubTopic);

    await MqttUtilities.asyncSleep(2);
    log.i('MQTT:Disconnecting');
    client.disconnect();
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    log.i('MQTT:Subscription confirmed for topic $topic');
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    connected = false;

    streamStateSubscription.cancel();
    streamBatterySubscription.cancel();
    streamShotSubscription.cancel();
    streamWaterSubscription.cancel();

    log.i('MQTT:OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus!.disconnectionOrigin == MqttDisconnectionOrigin.solicited) {
      log.i('MQTT:OnDisconnected callback is solicited, this is correct');
    }

    Future.delayed(
      const Duration(seconds: 10),
      () {
        log.i('MQTT:Reconnecting');
        startService();
      },
    );
  }

  /// The successful connect callback
  void onConnected() {
    connected = true;
    log.i('MQTT:OnConnected client callback - Client connection was sucessful');
    handleEvents();
  }

  /// Pong callback
  void pong() {
    log.i('MQTT:Ping response client callback invoked');
  }

  void handleEvents() {
    streamStateSubscription = machineService.streamState.listen((event) {
      try {
        log.v("State Change detected $event");
        var pubTopic = '$rootTopic/de1';
        var builder = MqttClientPayloadBuilder();
        builder.addString(event.state.name);
        client.publishMessage("$pubTopic/status", MqttQos.exactlyOnce, builder.payload!);

        builder = MqttClientPayloadBuilder();
        builder.addString(event.subState);
        client.publishMessage("$pubTopic/substatus", MqttQos.exactlyOnce, builder.payload!);
      } catch (e) {
        log.e("MQTT: $e");
      }
    });
    streamShotSubscription = machineService.streamShotState.listen((event) {
      try {
        log.v("Shot State CHange detected $event");
        var pubTopic = '$rootTopic/de1/shot';
        var builder = MqttClientPayloadBuilder();

        builder.addString(jsonEncode(event.toJson()));
        client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);
      } catch (e) {
        log.e("MQTT: $e");
      }
    });
    streamWaterSubscription = machineService.streamWaterLevel.listen((event) {
      try {
        var pubTopic = '$rootTopic/de1/waterlevel';
        var builder = MqttClientPayloadBuilder();
        builder.addString(event.waterLevel.toString());
        client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);
        builder = MqttClientPayloadBuilder();
        builder.addString(event.waterLimit.toString());
        client.publishMessage("${pubTopic}limit", MqttQos.exactlyOnce, builder.payload!);
      } catch (e) {
        log.e("MQTT: $e");
      }
    });

    streamBatterySubscription = machineService.streamBatteryState.listen((event) {
      try {
        var pubTopic = '$rootTopic/tablet/batterylevel';
        var builder = MqttClientPayloadBuilder();
        builder.addString(event.toString());
        client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);
        builder = MqttClientPayloadBuilder();
        builder.addString(machineService.de1?.usbChargerMode.toString() ?? "-1");
        client.publishMessage('$rootTopic/tablet/usbchargermode', MqttQos.exactlyOnce, builder.payload!);
        log.v("Batterydata pushed to MQTT");
      } catch (e) {
        log.e("MQTT: $e");
      }
    });
  }
}
