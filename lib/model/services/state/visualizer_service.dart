import 'dart:async';
import 'dart:convert';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../../service_locator.dart';
import 'package:despresso/logger_util.dart';
import 'package:http/http.dart' as http;

import '../../shotstate.dart';
import '../ble/machine_service.dart';

class VisualizerService extends ChangeNotifier {
  late SettingsService settingsService;
  late EspressoMachineService machineService;
  late StreamSubscription<EspressoMachineFullState> streamStateSubscription;

  final log = Logger('VisualizerAuthService');
  VisualizerService() {
    log.info('VisualizerAuth:start');
    settingsService = getIt<SettingsService>();
    machineService = getIt<EspressoMachineService>();

    streamStateSubscription = machineService.streamState.listen((event) {
      if (settingsService.visualizerUpload == true) {
        log.info(event);
      }

      // sendShotToVisualizer(event);
    });

    Future sendShotToVisualizer() async {
      if (settingsService.visualizerUser.isNotEmpty && settingsService.visualizerPwd.isNotEmpty) {
        String username = settingsService.visualizerUser;
        String password = settingsService.visualizerPwd;
        String basicAuth = 'Basic ${base64.encode(utf8.encode('$username:$password'))}';
        var url = Uri.https('visualizer.coffee', '/api/shots/upload');
        var response = await http.post(url, headers: <String, String>{'authorization': basicAuth});
        // var  = jsonDecode(response.body)['profile_url'] + '.json';
      }
    }
  }
}
