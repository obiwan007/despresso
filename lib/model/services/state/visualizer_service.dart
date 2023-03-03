import 'dart:async';
import 'dart:convert';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/model/shot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import '../../../service_locator.dart';

import 'package:http/http.dart' as http;

import '../../shotstate.dart';
import '../ble/machine_service.dart';

class VisualizerService extends ChangeNotifier {
  late SettingsService settingsService;
  late ProfileService profileService;

  late StreamSubscription<EspressoMachineFullState> streamStateSubscription;

  final log = Logger('VisualizerAuthService');

  VisualizerService() {
    log.info('VisualizerAuth:start');
    settingsService = getIt<SettingsService>();
    profileService = getIt<ProfileService>();
  }
  Future sendShotToVisualizer(Shot shot) async {
    if (settingsService.visualizerUser.isNotEmpty && settingsService.visualizerPwd.isNotEmpty) {
      String username = settingsService.visualizerUser;
      String password = settingsService.visualizerPwd;
      String basicAuth = 'Basic ${base64.encode(utf8.encode('$username:$password'))}';

      var headers = <String, String>{
        'authorization': basicAuth,
        'Content-Type': 'text/plain',
      };

      var body = createShotJson(shot);

      var request = http.MultipartRequest("POST", Uri.parse('https://visualizer.coffee/api/shots/upload'));
      request.files.add(http.MultipartFile.fromString("file", body, filename: "shot.tcl"));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode != 200) {
        var resBody = await response.stream.bytesToString();
        if (resBody.isNotEmpty && response.statusCode != 404) {
          var err = jsonDecode(resBody);
          throw ("Error in uploading: ${err['error']}");
        } else {
          throw ("Error in uploading: ${response.statusCode}");
        }
      }
      return response;
    } else {
      throw ("No username and/or password configured in settings");
    }
  }

  String createShotJson(Shot shot) {
    var prof = profileService.getProfile(shot.profileId);

    // var data = <String, dynamic>{
    //   'profile_title': prof!.title,
    //   "drink_tds": shot.totalDissolvedSolids,
    //   "drink_ey": shot.extractionYield,
    //   "espresso_enjoyment": shot.enjoyment,
    //   "bean_weight": shot.doseWeight,
    //   "drink_weight": shot.drinkWeight,
    //   "grinder_model": shot.grinderName,
    //   "grinder_setting": shot.grinderSettings,
    //   "bean_brand": shot.coffee.target?.roaster.target?.name ?? "unknown",
    //   "bean_type": shot.coffee.target?.name ?? "unknonw",
    //   "roast_date": null,
    //   "espresso_notes": shot.description,
    //   "roast_level": shot.coffee.target?.roastLevel ?? 0,
    //   "bean_notes": shot.coffee.target?.description ?? "",
    //   "start_time": shot.date.toIso8601String(),
    //   "duration": shot.shotstates.last.sampleTimeCorrected,
    // };
    var times = shot.shotstates.map((e) => e.sampleTimeCorrected.toStringAsFixed(4)).join(" ");
    // var espressoFlow = shot.shotstates.map(
    //   (element) => element.groupFlow,
    // );

    // data["timeframe"] = times;

    // data["data"] = <String, dynamic>{
    //   "espresso_flow": shot.shotstates.map((element) => element.groupFlow).toList(),
    //   "espresso_flow_weight": shot.shotstates.map((element) => element.flowWeight).toList(),
    //   "espresso_pressure": shot.shotstates.map((element) => element.groupPressure).toList(),
    //   "espresso_pressure_goal": shot.shotstates.map((element) => element.setGroupPressure).toList(),
    //   "espresso_flow_goal": shot.shotstates.map((element) => element.setGroupFlow).toList(),
    //   "espresso_weight": shot.shotstates.map((element) => element.weight).toList(),
    //   "espresso_temperature_mix": shot.shotstates.map((element) => element.mixTemp).toList(),
    //   "espresso_temperature_goal": shot.shotstates.map((element) => element.setMixTemp).toList(),
    //   "espresso_temperature_basket": shot.shotstates.map((element) => element.headTemp).toList(),
    // };

    var buffer = new StringBuffer();
    // buffer.writeln("local_time {${shot.date.toIso8601String()}}");

    buffer.writeln("clock ${(shot.date.millisecondsSinceEpoch / 1000).toInt()}");
    // buffer.writeln("app_version {1.39.0}");
    // buffer.writeln("local_time {Thu Jun 23 16:57:46 CST 2022}");
    buffer.writeln("espresso_elapsed {${times}}");
    buffer.writeln("espresso_pressure {${shot.shotstates.map((e) => e.groupPressure.toStringAsFixed(4)).join(" ")}}");
    buffer.writeln(
        "espresso_pressure_goal {${shot.shotstates.map((e) => e.setGroupPressure.toStringAsFixed(4)).join(" ")}}");
    buffer.writeln("espresso_weight {${shot.shotstates.map((e) => e.weight.toStringAsFixed(4)).join(" ")}}");
    buffer.writeln("espresso_flow {${shot.shotstates.map((e) => e.groupFlow.toStringAsFixed(4)).join(" ")}}");
    buffer.writeln("espresso_flow_goal {${shot.shotstates.map((e) => e.setGroupFlow.toStringAsFixed(4)).join(" ")}}");
    buffer.writeln("espresso_flow_weight {${shot.shotstates.map((e) => e.flowWeight.toStringAsFixed(4)).join(" ")}}");
    buffer.writeln(
        "espresso_temperature_basket {${shot.shotstates.map((e) => e.headTemp.toStringAsFixed(4)).join(" ")}}");
    buffer.writeln("espresso_temperature_mix {${shot.shotstates.map((e) => e.mixTemp.toStringAsFixed(4)).join(" ")}}");
    buffer.writeln(
        "espresso_temperature_basket {${shot.shotstates.map((e) => e.headTemp.toStringAsFixed(4)).join(" ")}}");
    buffer.writeln(
        "espresso_temperature_basket {${shot.shotstates.map((e) => e.headTemp.toStringAsFixed(4)).join(" ")}}");
    buffer.writeln(
        "espresso_temperature_basket {${shot.shotstates.map((e) => e.headTemp.toStringAsFixed(4)).join(" ")}}");
    buffer.writeln(
        "espresso_temperature_goal {${shot.shotstates.map((e) => e.setHeadTemp.toStringAsFixed(4)).join(" ")}}");

    // buffer.writeln("timers(espresso_stop) 1655974708631");
    // buffer.writeln("timers(espresso_start) 1655974677760");
    // buffer.writeln("timers(espresso_pour_stop) 1655974708631");
    // buffer.writeln("timers(espresso_pour_start) 1655974689010");
    // buffer.writeln("timers(espresso_preinfusion_stop) 1655974689010");
    // buffer.writeln("timers(espresso_preinfusion_start) 1655974677760");

    buffer.writeln("settings {");
    buffer.writeln("drink_ey ${shot.extractionYield}");
    buffer.writeln("drink_tds ${shot.totalDissolvedSolids}");
    buffer.writeln("drink_weight ${shot.pourWeight}");

    buffer.writeln("drinker_name ${shot.drinker}");
    buffer.writeln("my_name ${shot.barrista}");

    buffer.writeln("bean_brand {${shot.coffee.target?.roaster.target?.name ?? "unknown"}}");
    buffer.writeln("bean_notes {${shot.coffee.target?.description ?? ""}}");
    buffer.writeln("bean_type {${shot.coffee.target?.name ?? "unknown"}}");

    buffer.writeln("grinder_model {${shot.grinderName}}");
    buffer.writeln("grinder_settings {${shot.grinderSettings}}");
    buffer.writeln("grinder_dose_weight {${shot.doseWeight}}");

    buffer.writeln("profile_title ${prof!.title}");
    buffer.writeln("profile_notes  {${prof!.shotHeader.notes}}");

    buffer.writeln("roast_level {${shot.coffee.target?.roastLevel ?? 0}}");
    buffer.writeln("running_weight {${shot.pourWeight}}");

    buffer.writeln("espresso_notes {${shot.description}}");
    buffer.writeln("espresso_enjoyment ${shot.enjoyment * 20}");

    // buffer.writeln("beverage_type espresso");

    buffer.writeln("}");

    var ret = buffer.toString();
    return ret;
  }
}
