import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'settings_service.dart';

final mqttServer = SettingsService().mqttServer;
final mqttPort = SettingsService().mqttPort;
final mqttEnabled = SettingsService().mqttEnabled;

final client = MqttServerClient(mqttServer, mqttPort.toString());

class MqttService {
  MqttService() {
    startService();
  }

  Future<int> startService() async {
    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;
    client.pongCallback = pong;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('dart_client')
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    print('Client connecting....');
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      print('Client exception: $e');
      client.disconnect();
    } on SocketException catch (e) {
      print('Socket exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Client connected');
    } else {
      print(
          'Client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
      exit(-1);
    }

    const subTopic = 'despresso/switch';
    print('Subscribing to the $subTopic topic');
    client.subscribe(subTopic, MqttQos.atMostOnce);
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print('Received message: topic is ${c[0].topic}, payload is $pt');
    });

    client.published!.listen((MqttPublishMessage message) {
      print(
          'Published topic: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
    });

    const pubTopic = 'despresso/status';
    final builder = MqttClientPayloadBuilder();
    builder.addString('Hello from mqtt_client');

    print('Subscribing to the $pubTopic topic');
    client.subscribe(pubTopic, MqttQos.exactlyOnce);

    print('Publishing our topic');
    client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);

    print('Sleeping....');
    await MqttUtilities.asyncSleep(80);

    print('Unsubscribing');
    client.unsubscribe(subTopic);
    client.unsubscribe(pubTopic);

    await MqttUtilities.asyncSleep(2);
    print('Disconnecting');
    client.disconnect();

    return 0;
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    print('Subscription confirmed for topic $topic');
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    print('OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus!.disconnectionOrigin ==
        MqttDisconnectionOrigin.solicited) {
      print('OnDisconnected callback is solicited, this is correct');
    }
    exit(-1);
  }

  /// The successful connect callback
  void onConnected() {
    print('OnConnected client callback - Client connection was sucessful');
  }

  /// Pong callback
  void pong() {
    print('Ping response client callback invoked');
  }
}
