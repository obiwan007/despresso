import 'package:despresso/devices/decent_de1.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import '../../shotstate.dart';

class WaterLevel {
  WaterLevel(this.waterLevel, this.waterLimit);

  int waterLevel = 0;
  int waterLimit = 0;

  int getLevelPercent() {
    var l = waterLevel - waterLimit;
    return (l * 100 / 8300).toInt();
  }
}

class MachineState {
  MachineState(this.shot, this.coffeeState);
  ShotState? shot;
  WaterLevel? water;
  EspressoMachineState coffeeState;
  String subState = "";
}

enum EspressoMachineState {
  idle,
  espresso,
  water,
  steam,
  sleep,
  disconnected,
  refill,
  flush
}

class EspressoMachineService extends ChangeNotifier {
  final MachineState _state =
      MachineState(null, EspressoMachineState.disconnected);

  DE1? de1;

  EspressoMachineService();

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
}
