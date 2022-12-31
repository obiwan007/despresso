import 'package:despresso/devices/decent_de1.dart';
import 'package:despresso/model/settings.dart';
import 'package:despresso/model/shotdecoder.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shotstate.dart';

class WaterLevel {
  WaterLevel(this.waterLevel, this.waterLimit);

  int waterLevel = 0;
  int waterLimit = 0;

  int getLevelPercent() {
    var l = waterLevel - waterLimit;
    return l * 100 ~/ 8300;
  }
}

class MachineState {
  MachineState(this.shot, this.coffeeState);
  ShotState? shot;
  De1ShotHeaderClass? shotHeader;
  De1ShotFrameClass? shotFrame;

  WaterLevel? water;
  EspressoMachineState coffeeState;
  String subState = "";
}

enum EspressoMachineState { idle, espresso, water, steam, sleep, disconnected, connecting, refill, flush }

class EspressoMachineService extends ChangeNotifier {
  final MachineState _state = MachineState(null, EspressoMachineState.disconnected);

  DE1? de1;

  Settings de1Settings = Settings();

  late SharedPreferences prefs;

  EspressoMachineService();

  void init() async {
    prefs = await SharedPreferences.getInstance();
    log('Preferences loaded');

    var settingsString = prefs.getString("de1Setting");

    notifyListeners();
  }

  void setShot(ShotState shot) {
    _state.shot = shot;
    notifyListeners();
  }

  void setWaterLevel(WaterLevel water) {
    _state.water = water;
    notifyListeners();
  }

  void setState(EspressoMachineState state) {
    _state.coffeeState = state;
    notifyListeners();
  }

  void setSubState(String state) {
    _state.subState = state;
    notifyListeners();
  }

  MachineState get state => _state;

  void setDecentInstance(DE1 de1) {
    this.de1 = de1;
  }

  void setShotHeader(De1ShotHeaderClass sh) {
    _state.shotHeader = sh;
    log("Shotheader:$sh");
    notifyListeners();
  }

  void setShotFrame(De1ShotFrameClass sh) {
    _state.shotFrame = sh;
    log("ShotFrame:$sh");
    notifyListeners();
  }

  Future<String> uploadProfile(De1ShotProfile profile) async {
    var header = profile.shot_header;

    try {
      await de1!.writeWithResult(Endpoint.HeaderWrite, header.bytes);
    } catch (ex) {
      return "Error writing profile header $ex";
    }

    for (var fr in profile.shot_frames) {
      try {
        await de1!.writeWithResult(Endpoint.FrameWrite, fr.bytes);
      } catch (ex) {
        return "Error writing shot frame $fr";
      }
    }

    for (var exFrame in profile.shot_exframes) {
      try {
        await de1!.writeWithResult(Endpoint.FrameWrite, exFrame.bytes);
      } catch (ex) {
        return "Error writing ex shot frame $exFrame";
      }
    }

    // stop at volume in the profile tail
    if (profile.shot_header.target_volume > 0.0) {
      var tailBytes =
          De1ShotHeaderClass.encodeDe1ShotTail(profile.shot_frames.length, profile.shot_header.target_volume);

      try {
        await de1!.writeWithResult(Endpoint.FrameWrite, tailBytes);
      } catch (ex) {
        return "Error writing shot frame tail $tailBytes";
      }
    }

    // check if we need to send the new water temp
    if (de1Settings.targetGroupTemp != profile.shot_frames[0].temp) {
      profile.shot_header.targetGroupTemp = profile.shot_frames[0].temp;
      var bytes = Settings.encodeDe1OtherSetn(de1Settings);

      try {
        await de1!.writeWithResult(Endpoint.ShotSettings, bytes);
      } catch (ex) {
        return "Error writing shot settings $bytes";
      }
    }
    return Future.value("");
  }
}
