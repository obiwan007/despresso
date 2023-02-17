import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'settings_service.dart';
import 'package:despresso/logger_util.dart';

// final client = MqttServerClient(mqttServer, mqttPort.toString());

class MqttService extends ChangeNotifier {
  final log = Logger('MqttService');

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
    log.info('MQTT:init mqtt');
    settingsService = getIt<SettingsService>();
    machineService = getIt<EspressoMachineService>();
    if (settingsService.mqttRootTopic.isNotEmpty) {
      rootTopic = "despresso/${settingsService.mqttRootTopic}";
    }
    startService();
  }

  stopService() {
    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      client.disconnect();
    }
  }

  Future<int> startService() async {
    connected = false;
    if (settingsService.mqttEnabled) {
      try {
        client = MqttServerClient(settingsService.mqttServer, "");
        client.logging(on: false);
        client.port = int.parse(settingsService.mqttPort);
        log.info('MQTT:mqtt service started');
        client.keepAlivePeriod = 60;
        client.autoReconnect = true;
        client.resubscribeOnAutoReconnect = true;
        client.onDisconnected = onDisconnected;
        client.setProtocolV31();

        client.onConnected = onConnected;
        client.onAutoReconnected = () {
          log.info("Auto Reconnected");
        };

        client.onAutoReconnect = () {
          log.info("Auto Reconnect - connection lost");
        };

        client.onSubscribed = onSubscribed;
        client.pongCallback = pong;

        final connMess = MqttConnectMessage()
            .withClientIdentifier('despresso')
            // .withWillTopic('willtopic')
            // .withWillMessage('My Will message')
            .startClean()
            .withWillQos(MqttQos.atLeastOnce);
        log.info('MQTT: Client connecting....');
        client.connectionMessage = connMess;

        try {
          log.info('MQTT:trying to connect');
          await client.connect(settingsService.mqttUser, settingsService.mqttPassword);
        } on NoConnectionException catch (e) {
          log.severe('MQTT: Client exception: $e');
          client.disconnect();
        } on SocketException catch (e) {
          log.severe('MQTT: Socket exception: $e');
          client.disconnect();
        }
      } catch (ex) {
        log.severe("MQTT: Exception: $ex");
        return -1;
      }

      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        log.info('MQTT: Client connected');
      } else {
        log.severe('MQTT:Client connection failed - disconnecting, status is ${client.connectionStatus}');
        client.disconnect();
        return -1;
      }

      log.info('MQTT:Subscribing to the $rootTopic /de1/setstatus topic');
      var statusRequest = '$rootTopic/de1/setstatus';
      client.subscribe(statusRequest, MqttQos.atMostOnce);
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final recMess = c![0].payload as MqttPublishMessage;
        final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        log.info('MQTT:Received message: topic is ${c[0].topic}, payload is $pt');
        if (c[0].topic == statusRequest) {
          var validState = false;
          switch (pt) {
            case "idle":
              machineService.de1?.switchOn();
              validState = true;
              break;
            case "sleep":
              machineService.de1?.switchOff();
              validState = true;
              break;
          }
          if (validState) {
            final builder = MqttClientPayloadBuilder();
            builder.addString(DateTime.now().toIso8601String());
            client.publishMessage(statusRequest, MqttQos.exactlyOnce, builder.payload!);
          }
        }
      });

      // client.published!.listen((MqttPublishMessage message) {
      //   log.finer(
      //       'MQTT:Published topic: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
      // });

      log.info('MQTT:Publishing our topic');
      var pubTopic = '$rootTopic/status';
      final builder = MqttClientPayloadBuilder();
      builder.addString(DateTime.now().toIso8601String());
      client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);

      connected = true;

      // log.info('MQTT:Sleeping....');
      // await MqttUtilities.asyncSleep(80);

      // log.info('MQTT:Unsubscribing');
      // client.unsubscribe(subTopic);
      // client.unsubscribe(pubTopic);

      // await MqttUtilities.asyncSleep(2);
      // log.info('MQTT:Disconnecting');
      // client.disconnect();
    }
    return 0;
  }

  void disconnect() async {
    if (!connected) return;

    log.info('MQTT:Unsubscribing');
    client.unsubscribe(subTopic);
    // client.unsubscribe(pubTopic);

    await MqttUtilities.asyncSleep(2);
    log.info('MQTT:Disconnecting');
    client.disconnect();
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    log.info('MQTT:Subscription confirmed for topic $topic');
  }

  /// The unsolicited disconnect callback
  Future<void> onDisconnected() async {
    connected = false;
    try {
      await streamStateSubscription.cancel();
      await streamBatterySubscription.cancel();
      await streamShotSubscription.cancel();
      await streamWaterSubscription.cancel();
    } catch (e) {
      log.severe('MQTT:OnDisconnected listener could not be closed $e');
    }

    log.info('MQTT:OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus!.disconnectionOrigin == MqttDisconnectionOrigin.solicited) {
      log.info('MQTT:OnDisconnected callback is solicited, this is correct');
    }

    // Future.delayed(
    //   const Duration(seconds: 10),
    //   () {
    //     log.info('MQTT:Reconnecting');
    //     startService();
    //   },
    // );
  }

  /// The successful connect callback
  void onConnected() {
    connected = true;
    log.info('MQTT:OnConnected client callback - Client connection was sucessful');
    handleEvents();
  }

  /// Pong callback
  void pong() {
    log.info('MQTT:Ping response client callback invoked');
  }

  void handleEvents() {
    streamStateSubscription = machineService.streamState.listen((event) {
      try {
        if (client.connectionStatus?.state != MqttConnectionState.connected) return;
        if (!settingsService.mqttSendState) return;
        var pubTopic = '$rootTopic/de1';
        var builder = MqttClientPayloadBuilder();
        builder.addString(event.state.name);
        client.publishMessage("$pubTopic/status", MqttQos.exactlyOnce, builder.payload!);

        builder = MqttClientPayloadBuilder();
        builder.addString(event.subState);
        client.publishMessage("$pubTopic/substatus", MqttQos.exactlyOnce, builder.payload!);
      } catch (e) {
        log.severe("MQTT: $e");
      }
    });
    streamShotSubscription = machineService.streamShotState.listen((event) {
      try {
        if (client.connectionStatus?.state != MqttConnectionState.connected) return;
        if (!settingsService.mqttSendShot) return;
        var pubTopic = '$rootTopic/de1/shot';
        var builder = MqttClientPayloadBuilder();

        builder.addString(jsonEncode(event.toJson()));
        client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);
      } catch (e) {
        log.severe("MQTT: $e");
      }
    });
    streamWaterSubscription = machineService.streamWaterLevel.listen((event) {
      try {
        if (client.connectionStatus?.state != MqttConnectionState.connected) return;
        if (!settingsService.mqttSendWater) return;
        var pubTopic = '$rootTopic/de1/waterlevel';
        var builder = MqttClientPayloadBuilder();
        builder.addString(event.waterLevel.toString());
        client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);
        builder = MqttClientPayloadBuilder();
        builder.addString(event.waterLimit.toString());
        client.publishMessage("${pubTopic}limit", MqttQos.exactlyOnce, builder.payload!);
      } catch (e) {
        log.severe("MQTT: $e");
      }
    });

    streamBatterySubscription = machineService.streamBatteryState.listen((event) {
      try {
        if (client.connectionStatus?.state != MqttConnectionState.connected) return;
        if (!settingsService.mqttSendBattery) return;
        var pubTopic = '$rootTopic/tablet/batterylevel';
        var builder = MqttClientPayloadBuilder();
        builder.addString(event.toString());
        client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);
        if (machineService.de1 != null) {
          builder = MqttClientPayloadBuilder();
          builder.addString(machineService.de1?.usbChargerMode.toString() ?? "-1");
          client.publishMessage('$rootTopic/tablet/usbchargermode', MqttQos.exactlyOnce, builder.payload!);
        }
        log.fine("Batterydata pushed to MQTT");
      } catch (e) {
        log.severe("MQTT: $e");
      }
    });
  }
}
