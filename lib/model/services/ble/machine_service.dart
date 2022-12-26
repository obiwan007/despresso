import 'package:flutter/material.dart';

class ShotState {
  ShotState(
      this.sampleTime,
      this.groupPressure,
      this.groupFlow,
      this.mixTemp,
      this.headTemp,
      this.setMixTemp,
      this.setHeadTemp,
      this.setGroupPressure,
      this.setGroupFlow,
      this.frameNumber,
      this.steamTemp);

  double sampleTime;
  double groupPressure;
  double groupFlow;
  double mixTemp;
  double headTemp;
  double setMixTemp;
  double setHeadTemp;
  double setGroupPressure;
  double setGroupFlow;
  int frameNumber;
  int steamTemp;
}

class WaterLevel {
  WaterLevel(this.waterLevel, this.waterLimit);

  int waterLevel;
  int waterLimit;
}

class MachineState {
  MachineState(this.shot, this.coffeeState);
  ShotState? shot;
  WaterLevel? water;
  EspressoMachineState coffeeState;
}

enum EspressoMachineState { idle, espresso, water, steam }

class EspressoMachineService extends ChangeNotifier {
  final MachineState _state = MachineState(null, EspressoMachineState.idle);

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

  MachineState get state => _state;
}
