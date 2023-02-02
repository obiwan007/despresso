import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'settings_service.dart';

// final client = MqttServerClient(mqttServer, mqttPort.toString());

class MqttService extends ChangeNotifier {
  late SettingsService settingsService;
  late EspressoMachineService machineService;
  late MqttClient client;
  final subTopic = 'despresso';

  bool connected = false;

  MqttService() {
    log('MQTT:init mqtt');
    settingsService = getIt<SettingsService>();
    machineService = getIt<EspressoMachineService>();
    startService();
  }

  Future<int> startService() async {
    connected = false;
    if (settingsService.mqttEnabled) {
      try {
        client = MqttServerClient(settingsService.mqttServer, "");
        client.port = int.parse(settingsService.mqttPort);
        log('MQTT:mqtt enabled starting service');
        client.logging(on: true);
        log('MQTT:mqtt service started');
        client.keepAlivePeriod = 60;
        client.onDisconnected = onDisconnected;
        client.setProtocolV31();

        // client.onConnected = onConnected;
        // client.onSubscribed = onSubscribed;
        // client.pongCallback = pong;

        final connMess = MqttConnectMessage()
            .withClientIdentifier('despresso')
            // .withWillTopic('willtopic')
            // .withWillMessage('My Will message')
            .startClean()
            .withWillQos(MqttQos.atLeastOnce);
        log('MQTT: Client connecting....');
        client.connectionMessage = connMess;

        try {
          log('MQTT:trying to connect');
          await client.connect(settingsService.mqttUser, settingsService.mqttPassword);
        } on NoConnectionException catch (e) {
          log('MQTT: Client exception: $e');
          client.disconnect();
        } on SocketException catch (e) {
          log('MQTT: Socket exception: $e');
          client.disconnect();
        }
      } catch (ex) {
        log("MQTT: Exception: $ex");
        return -1;
      }

      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        log('MQTT: Client connected');
      } else {
        log('MQTT:Client connection failed - disconnecting, status is ${client.connectionStatus}');
        client.disconnect();
        return -1;
      }

      log('MQTT:Subscribing to the $subTopic topic');
      client.subscribe(subTopic, MqttQos.atMostOnce);
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final recMess = c![0].payload as MqttPublishMessage;
        final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        log('MQTT:Received message: topic is ${c[0].topic}, payload is $pt');
      });

      client.published!.listen((MqttPublishMessage message) {
        log('MQTT:Published topic: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
      });

      const pubTopic = 'despresso/status';
      final builder = MqttClientPayloadBuilder();
      builder.addString('Hello from mqtt_client');

      log('Subscribing to the $pubTopic topic');
      // client.subscribe(pubTopic, MqttQos.exactlyOnce);

      log('MQTT:Publishing our topic');
      client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);

      connected = true;

      handleEvents();
      // log('MQTT:Sleeping....');
      // await MqttUtilities.asyncSleep(80);

      // log('MQTT:Unsubscribing');
      // client.unsubscribe(subTopic);
      // client.unsubscribe(pubTopic);

      // await MqttUtilities.asyncSleep(2);
      // log('MQTT:Disconnecting');
      // client.disconnect();
    }
    return 0;
  }

  void disconnect() async {
    if (!connected) return;

    log('MQTT:Unsubscribing');
    client.unsubscribe(subTopic);
    // client.unsubscribe(pubTopic);

    await MqttUtilities.asyncSleep(2);
    log('MQTT:Disconnecting');
    client.disconnect();
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    log('MQTT:Subscription confirmed for topic $topic');
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    log('MQTT:OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus!.disconnectionOrigin == MqttDisconnectionOrigin.solicited) {
      log('MQTT:OnDisconnected callback is solicited, this is correct');
    }
  }

  /// The successful connect callback
  void onConnected() {
    log('MQTT:OnConnected client callback - Client connection was sucessful');
  }

  /// Pong callback
  void pong() {
    log('MQTT:Ping response client callback invoked');
  }

  void handleEvents() {
    machineService.streamState.listen((event) {
      log("State CHange detected $event");
      const pubTopic = 'despresso/de1';
      var builder = MqttClientPayloadBuilder();
      builder.addString(event.state.name);
      client.publishMessage("$pubTopic/status", MqttQos.exactlyOnce, builder.payload!);

      builder = MqttClientPayloadBuilder();
      builder.addString(event.subState);
      client.publishMessage("$pubTopic/substatus", MqttQos.exactlyOnce, builder.payload!);
    });
    machineService.streamShotState.listen((event) {
      log("Shot State CHange detected $event");
      const pubTopic = 'despresso/de1/shot';
      var builder = MqttClientPayloadBuilder();

      builder.addString(jsonEncode(event.toJson()));
      client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);
    });
    machineService.streamWaterLevel.listen((event) {
      const pubTopic = 'despresso/de1/waterlevel';
      var builder = MqttClientPayloadBuilder();
      builder.addString(event.waterLevel.toString());
      client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);
      builder = MqttClientPayloadBuilder();
      builder.addString(event.waterLimit.toString());
      client.publishMessage("${pubTopic}limit", MqttQos.exactlyOnce, builder.payload!);
    });

    machineService.streamBatteryState.listen((event) {
      const pubTopic = 'despresso/tablet/batterylevel';
      var builder = MqttClientPayloadBuilder();
      builder.addString(event.toString());
      client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);
      builder = MqttClientPayloadBuilder();
      builder.addString(machineService.de1?.usbChargerMode.toString() ?? "-1");
      client.publishMessage('despresso/tablet/usbchargermode', MqttQos.exactlyOnce, builder.payload!);
    });
  }
}
