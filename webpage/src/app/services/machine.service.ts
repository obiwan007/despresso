import {computed, effect, inject, Injectable, signal} from '@angular/core';
import {firstValueFrom, Subscription} from 'rxjs';

import {ShotService} from './shot.service';
import {
  BleStatus,
  Device,
  EspressoMachineFullState,
  EspressoMachineState,
  ScaleState,
  ShotState,
  WeightMeasurement,
} from '../models/state';
import {ApiService} from './api.service';

export enum EspressoMachineSubState {
  HeatWaterTank = 'heat_water_tank',
  Pouring = 'pouring',
  Preinfusion = 'preinfusion',
  NoState = 'no_state',
}

@Injectable({ providedIn: 'root' })
export class MachineService {
  private readonly shotService = inject(ShotService);
  private readonly apiService = inject(ApiService);
  // Signals holding latest data from subscriptions

  private readonly _machineState = computed(() => {
    const snapshot = this.apiService.snapshot();

    const s: EspressoMachineFullState = {
      state: (snapshot?.state.state ?? 'idle') as EspressoMachineState,
      subState: snapshot?.state.substate ?? '',
    };

    return s;
  });

  private readonly _shotState = computed(() => {
    const snapshot = this.apiService.snapshot();
    const d = snapshot?.timestamp ?? new Date();
    const s: ShotState = {
      id: -1,
      __typename: 'ShotState',
      pourTime: d.getTime() / 1000,
      sampleTimeCorrected: d.getTime() / 1000,
      frameName: '',

      sampleTime: d.getTime() / 1000,
      // weight: snapshot?..weight ?? 0,
      weight: 0,
      flowWeight: 0,
      groupFlow: snapshot?.flow ?? 0,
      groupPressure: snapshot?.pressure ?? 0,
      mixTemp: snapshot?.mixTemperature ?? 0,
      steamTemp: snapshot?.steamTemperature ?? 0,
      headTemp: snapshot?.groupTemperature ?? 0,
      setGroupFlow: snapshot?.targetFlow ?? 0,
      setGroupPressure: snapshot?.targetPressure ?? 0,
      setMixTemp: snapshot?.targetMixTemperature ?? 0,
      setHeadTemp: snapshot?.targetGroupTemperature ?? 0,
      subState: snapshot?.state.substate ?? '',
      frameNumber: snapshot?.profileFrame ?? 0,
    };

    return s;
  });

  private readonly _shotState2 = signal<ShotState | null>(null);
  private readonly _weightUpdate = computed(() => this.apiService.scaleSnapshot());
  readonly waterLevel = computed(() => this.apiService.waterLevelSnapshot());

  readonly bleStatus = signal<BleStatus | null>(null);

  readonly scales = signal<Device[]>([]);

  readonly scaleState2 = signal<ScaleState[]>([ScaleState.Disconnected, ScaleState.Disconnected]);

  readonly scaleState = computed(() => {
    return this.apiService.scaleConnected()
      ? [ScaleState.Connected, ScaleState.Disconnected]
      : [ScaleState.Disconnected, ScaleState.Disconnected];
  });

  readonly isSleeping = computed(() => {
    const s = this._machineState();
    if (!s) return false;
    const state = s.state === EspressoMachineState.Sleep;
    return state;
  });

  readonly isInShot = computed(() => {
    const s = this._machineState();
    if (!s) return false;
    const state =
      s.state === EspressoMachineState.Espresso ||
      s.state === EspressoMachineState.Water ||
      s.state === EspressoMachineState.Steam;
    // console.log('isInShot:', state);
    return state;
  });

  readonly shotTimer = computed(() => {
    this._shotState();
    const s = this._machineState();
    if (s?.state === EspressoMachineState.Espresso && this.timeRunning === false) {
      this.timeRunning = true;
      this.startTime = new Date().getTime() / 1000;
    }
    if (s?.state === EspressoMachineState.Espresso) {
      return new Date().getTime() / 1000 - this.startTime;
    } else {
      this.timeRunning = false;
    }
    return 0;
  });

  timer = signal(0);

  // Public readonly accessors
  readonly machineState = this._machineState;
  readonly shotState = this._shotState;
  readonly shotSamples = signal<ShotState[]>([]);
  readonly weightUpdate = this._weightUpdate;

  // Active subscriptions
  private subMachine?: Subscription;
  private subShot?: Subscription;
  private subWeight?: Subscription;
  private subBleStatus?: Subscription;
  private weightInterval?: ReturnType<typeof setInterval>;
  private weightSimValue = 0;
  private shotInterval?: ReturnType<typeof setInterval>;
  private shotSimIndex = 0;
  private machineInterval?: ReturnType<typeof setInterval>;
  private bleInterval?: ReturnType<typeof setInterval>;
  private scaleInterval?: ReturnType<typeof setInterval>;
  private waterInterval?: ReturnType<typeof setInterval>;

  // Current scale index for weight updates
  private scaleIndex = 0;

  private readonly simRunning = signal<boolean>(false);

  subState = computed(() => {
    switch (this.machineState()?.subState) {
      case EspressoMachineSubState.HeatWaterTank:
        return 'heating water tank';
      case EspressoMachineSubState.Pouring:
        return 'Pouring';
      case EspressoMachineSubState.Preinfusion:
        return 'Preinfusion';
      case EspressoMachineSubState.NoState:
        return '';
      default:
        return this.machineState()?.subState;
    }
  });
  startTime: number = 0;
  timeRunning: boolean = false;

  sampleWeightCounter = 0;
  startSampleWeightTime = Date.now();
  sampleCounter: number = 0;
  startSampleTime = Date.now();
  simRunningCounter: any;
  simInterval: number = 0;
  interpolateInterval?: number = undefined;
  interpolCounter = 0;

  intHz = 16;

  constructor() {
    this.start();

    // effect(() => {
    //   console.log('Water level:', this.waterLevel());
    // });
  }

  /** Start all subscriptions */
  start(): void {
    this.apiService.test();
    this.apiService.getDevices();
    // this.apiService.initWebserviceLogs();
    this.apiService.initWebserviceMachine();
    this.apiService.initWebserviceScale();
    this.apiService.initWebserviceWaterlevel();

    // this.startMachineState();
    // this.startShotState();
    // this.startWeightUpdates(this.scaleIndex);
    // this.startBleStatusUpdates();
    // this.startScaleStatusUpdates(0);
    // this.startWaterLevelUpdates();
    // this.interpolateInterval = setInterval(() => {
    //   this.doInterpolate();
    // }, 1 / this.intHz * 1000);
  }
  doInterpolate() {
    if (this.isInShot()) {
      const samples = this.shotSamples();
      const current = samples.length > 0 ? structuredClone(samples[samples.length - 1]) : null;
      // const before = samples.length > 1 ? (structuredClone(samples[samples.length - 2])) : null;

      if (current) {
        this.interpolCounter++;
        current.pourTime += 4 / this.intHz / 10;
        current.id = -1;
        this.shotSamples.update((s) => [...s.filter((ss) => ss.id !== -1), current]);
      }
    } else {
      this.interpolCounter = 0;
    }
  }

  /** Stop all subscriptions */
  stop(): void {
    this.subMachine?.unsubscribe();
    this.subShot?.unsubscribe();
    this.subWeight?.unsubscribe();
    this.subMachine = undefined;
    this.subShot = undefined;
    this.subWeight = undefined;
    if (this.weightInterval) {
      clearInterval(this.weightInterval);
      this.weightInterval = undefined;
    }
    if (this.shotInterval) {
      clearInterval(this.shotInterval);
      this.shotInterval = undefined;
    }
    if (this.machineInterval) {
      clearInterval(this.machineInterval);
      this.machineInterval = undefined;
    }
    if (this.bleInterval) {
      clearInterval(this.bleInterval);
      this.bleInterval = undefined;
    }
    if (this.scaleInterval) {
      clearInterval(this.scaleInterval);
      this.scaleInterval = undefined;
    }
    if (this.waterInterval) {
      clearInterval(this.waterInterval);
      this.waterInterval = undefined;
    }
  }

  /** Set scale index and restart weight updates subscription */
  setScaleIndex(index: number): void {
    this.scaleIndex = index;
    if (this.subWeight) {
      this.subWeight.unsubscribe();
      this.subWeight = undefined;
    }
    this.startWeightUpdates(index);
  }

  startSim(): void {
    this.simRunningCounter = 0;
    this.simRunning.set(true);
    // this._machineState.set({
    //   state: EspressoMachineState.Espresso,
    //   subState: EspressoMachineSubState.Pouring,
    // } as EspressoMachineFullState);

    // this.simInterval = setInterval(() => {}, 100);
  }

  interpolationTimer(t: number): void {
    this.timer.set(t);
    const frequency = 16 / 4; // Hz

    const intervalMs = 250 / 4;

    const maxCount = frequency / intervalMs;
    // console.log('Timer', t, intervalMs);

    for (let i = 0; i <= 2; i++) {
      setTimeout(
        () => {
          //if (this.timer() < t) {
          const newTime = this.timer() + intervalMs / 1000;
          this.timer.set(newTime);
          // console.log('interpolated timer set to', newTime);
          // }
        },
        (i + 1) * intervalMs,
      );
      //  console.log('set timeout for', (i + 1) * intervalMs, t + (intervalMs * (i + 1)) / 1000);
    }
  }

  private startWeightUpdates(index: number): void {
    this.subWeight?.unsubscribe();
    if (this.weightInterval) {
      clearInterval(this.weightInterval);
      this.weightInterval = undefined;
    }

    this.weightSimValue = this._weightUpdate()?.weight ?? 0;
    this.weightInterval = setInterval(() => {
      if (this.simRunning()) {
        return;
      }

      this.sampleWeightCounter++;
      if (this.sampleWeightCounter % 50 === 0) {
        const now = Date.now();
        const elapsed = now - this.startSampleWeightTime;
        const rate = this.sampleWeightCounter / (elapsed / 1000);
        console.log(`Weight sample rate: ${rate.toFixed(2)} samples/sec`);
        this.startSampleWeightTime = now;
        this.sampleWeightCounter = 0;
      }

      const delta = Math.random() * 0.6 - 0.2;
      this.weightSimValue = Math.max(0, this.weightSimValue + delta);
      const flow = Math.max(0, 1 + Math.random() * 2);
    }, 100);
  }

  private startBleStatusUpdates(): void {
    this.subBleStatus?.unsubscribe();
    if (this.bleInterval) {
      clearInterval(this.bleInterval);
      this.bleInterval = undefined;
    }

    const devices: Device[] = [
      {__typename: 'Device', id: 'scale-1', localName: 'Scale A', rssi: -56},
      {__typename: 'Device', id: 'scale-2', localName: 'Scale B', rssi: -63},
    ];

    let scanning = true;
    this.bleInterval = setInterval(() => {
      scanning = !scanning;
      const connected = scanning ? [] : [devices[0]];
      this.bleStatus.set({
        __typename: 'BleStatus',
        connected,
        devices,
        scanning,
      });
    }, 2000);
  }

  // private startScaleStatusUpdates(index: number): void {
  //   if (this.scaleInterval) {
  //     clearInterval(this.scaleInterval);
  //     this.scaleInterval = undefined;
  //   }

  //   const states = [ScaleState.Connecting, ScaleState.Connected, ScaleState.Disconnected];
  //   let stateIndex = 0;
  //   this.scaleInterval = setInterval(() => {
  //     const next = states[stateIndex % states.length];
  //     stateIndex += 1;
  //     this.scaleState.update((s) => {
  //       return [...s.slice(0, index), next, ...s.slice(index + 1)];
  //     });
  //   }, 3000);
  // }

  async stopServer(): Promise<boolean | undefined> {
    return false;
  }

  async switchOn(): Promise<void> {
    return this.requestState(EspressoMachineState.Idle);
  }
  async switchOff(): Promise<void> {
    return this.requestState(EspressoMachineState.Sleep);
  }

  async requestState(state: EspressoMachineState): Promise<void> {
    return await this.apiService.setState(state);
  }

  async scaleTare(index: number): Promise<boolean | undefined> {
    //this._weightUpdate.set({weight: 0, flow: 0} as WeightMeasurement);
    this.apiService.tareScale();
    return true;
  }

  async startScan(): Promise<boolean | undefined> {
    this.apiService.scanDevices(true, false);
    return true;
  }

  async scanForScales(): Promise<Device[]> {
    return [];
  }

  async fetchScales(): Promise<Device[]> {
    return [];
  }
}
