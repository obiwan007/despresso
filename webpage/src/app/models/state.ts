export enum EspressoMachineState {
  AirPurge = 'airPurge',
  Clean = 'clean',
  Connecting = 'connecting',
  Descale = 'descale',
  Disconnected = 'disconnected',
  Espresso = 'espresso',
  Flush = 'flush',
  Idle = 'idle',
  Refill = 'refill',
    Sleep = 'sleeping',
  Steam = 'steam',
  Water = 'water'
}

export enum ScaleState {
  Connected = 'connected',
  Connecting = 'connecting',
  Disconnected = 'disconnected',
  Disconnecting = 'disconnecting'
}

export type ShotEntity = {
  __typename?: 'ShotEntity';
    barrista?: string;
  coffeeId?:string;
    date?: string;
    description?: string;
    doseWeight?: number;
    drinkWeight?: number;
    drinker?: string;
    enjoyment?: number;
    estimatedWeightReachedTime?: number;
    estimatedWeight_b?: number;
    estimatedWeight_m?: number;
    estimatedWeight_tEnd?: number;
    estimatedWeight_tStart?: number;
    extractionYield?: number;
    grinderName?: string;
    grinderSettings?: number;
    id: string;
    pourTime?: number;
    pourWeight?: number;
    profileId?: string;
    ratio1?: number;
    ratio2?: number;
    recipeId?: string;
    roastingDate?: string;
    shotstates?: Array<ShotState>;
    targetEspressoWeight?: number;
    targetTempCorrection?: number;
    totalDissolvedSolids?: number;
    visualizerId?: string;
};

export type ShotState = {
    __typename: 'ShotState';
  flowWeight: number;
  frameName: string;
  frameNumber: number;
  groupFlow: number;
  groupPressure: number;
  headTemp: number;
  id: number;
  mixTemp: number;
  pourTime: number;
  sampleTime: number;
  sampleTimeCorrected: number;
  setGroupFlow: number;
  setGroupPressure: number;
  setHeadTemp: number;
  setMixTemp: number;
  steamTemp: number;
  subState: string;
  weight: number;
};

export type Settings = {
  __typename?: 'Settings';
  alwaysAllowSkipping?: boolean;
  chUrl?: string;
  currentProfile?: string;
  currentVersion?: string;
  hasRefractometer?: boolean;
  hasScale?: boolean;
  hasSteamThermometer?: boolean;
  launchWake?: boolean;
  locale?: string;
  mqttEnabled?: boolean;
  mqttPassword?: string;
  mqttPort?: string;
  mqttRootTopic?: string;
  mqttSendBattery?: boolean;
  mqttSendShot?: boolean;
  mqttSendState?: boolean;
  mqttSendWater?: boolean;
  mqttServer?: string;
  mqttUser?: string;
  profileFilter?: string;
  recordPrePouring?: boolean;
  savePrePouring?: boolean;
  scaleDisplayOffOnSleep?: boolean;
  scalePrimary?: string;
  scaleSecondary?: string;
  scaleStartTimer?: boolean;
  screenBrightnessTimer?: number;
  screenBrightnessValue?: number;
  screenDarkTheme?: boolean;
  screenTapWake?: boolean;
  screenThemeIndex?: string;
  screenThemeMode?: number;
  screenTimoutGoToRecipe?: boolean;
  screensaverOnIfIdle?: boolean;
  screensaverShowClock?: boolean;
    selectedCoffee?: string;
    selectedRecipe?: string;
    selectedRoaster?: string;
    selectedShot?: number;
  shotAutoTare?: boolean;
  shotStopOnWeight?: boolean;
  showFlushScreen?: boolean;
  sleepTimer?: number;
  smartCharging?: boolean;
  startCounter?: number;
  steamHeaterOff?: boolean;
  steamSettings?: number;
  stepLimitWeightTimeAdjust?: number;
  tabletSleepDuringScreensaver?: boolean;
  tabletSleepDuringScreensaverTimeout?: number;
  tabletSleepWhenMachineOff?: boolean;
  tareOnDetectedWeight?: boolean;
  tareOnWakeUp?: boolean;
  tareOnWeight1?: number;
  tareOnWeight2?: number;
  tareOnWeight3?: number;
  tareOnWeight4?: number;
  targetEspressoVol?: number;
  targetEspressoWeight?: number;
  targetEspressoWeightTimeAdjust?: number;
  targetFlushTime?: number;
  targetFlushTime2?: number;
  targetGroupTemp?: number;
  targetHotWaterLength?: number;
  targetHotWaterTemp?: number;
  targetHotWaterVol?: number;
  targetHotWaterWeight?: number;
  targetMilkTempPreset1?: number;
  targetMilkTempPreset2?: number;
  targetMilkTempPreset3?: number;
  targetMilkTemperature?: number;
  targetSteamFlow?: number;
  targetSteamLength?: number;
  targetSteamTemp?: number;
  targetTempCorrection?: number;
  targetWaterlevel?: number;
  useCafeHub?: boolean;
  useLongUUID?: boolean;
  useSentry?: boolean;
  visualizerAccessToken?: string;
  visualizerClientId?: string;
  visualizerClientSecret?: string;
  visualizerExpiring?: string;
  visualizerExtendedPwd?: string;
  visualizerExtendedUpload?: boolean;
  visualizerExtendedUrl?: string;
  visualizerExtendedUser?: string;
  visualizerPwd?: string;
  visualizerRefreshToken?: string;
  visualizerUpload?: boolean;
  visualizerUser?: string;
  webServer?: boolean;
};

export type RecipeEntity = {
    __typename?: 'RecipeEntity';
    adjustedPressure: number;
    adjustedTemp: number;
    adjustedWeight: number;
    coffeeId?: string;
    description: string;
    disableStopOnWeight: boolean;
    flowSteam: number;
    grinderDoseWeight: number;
    grinderModel: string;
    grinderSettings: number;
    id: string;
    isDeleted: boolean;
    isFavorite: boolean;
    isShot: boolean;
    name: string;
    profileId: string;
    ratio1: number;
    ratio2: number;
    tempSteam: number;
    tempWater: number;
    timeSteam: number;
    timeWater: number;
    useSteam: boolean;
    useWater: boolean;
    weightMilk: number;
    weightWater: number;
};

export type Profile = {
    __typename?: 'Profile';
    id: string;
    isDefault: boolean;
    shotFrames: Array<De1ShotFrame>;
    shotHeader: De1ShotHeader;
    title: string;
};

export type De1ShotFrame = {
    __typename?: 'De1ShotFrame';
    flag: number;
    frameLen: number;
    limiter?: De1StepLimiterData | null;
    maxVol: number;
    maxWeight: number;
    name: string;
    pump: De1PumpMode;
    sensor: De1SensorType;
    setVal: number;
    temp: number;
    transition: De1Transition;
    triggerVal: number;
};

export type De1ShotHeader = {
    __typename?: 'De1ShotHeader';
    author: string;
    beverageType: string;
    headerV: number;
    hidden: number;
    lang: string;
    legacyProfileType: string;
    maximumFlow: number;
    minimumPressure: number;
    notes: string;
    numberOfFrames: number;
    numberOfPreinfuseFrames: number;
    tankTemperature: number;
    targetGroupTemp: number;
    targetVolume: number;
    targetVolumeCountStart: number;
    targetWeight: number;
    title: string;
    type: string;
    version: string;
};

export type De1StepLimiterData = {
    __typename?: 'De1StepLimiterData';
    range: number;
    value: number
};

export type De1StepLimiterDataInput = {
    range: number;
    value: number;
};

export enum De1Transition {
    Fast = 'fast',
    Smooth = 'smooth'
}

export enum De1PumpMode {
    Flow = 'flow',
    Pressure = 'pressure'
}

export enum De1SensorType {
    Coffee = 'coffee',
    Water = 'water'
}

export type Roaster = {
    __typename?: 'Roaster';
    address: string;
    description: string;
    homepage: string;
    id: string;
    imageURL: string;
    name: string;
};

export type Coffee = {
    __typename?: 'Coffee';
    acidRating: number;
    cropyear: string;
    description: string;
    elevation: number;
    farm: string;
    grinderDoseWeight: number;
    grinderSettings: number;
    id: string;
    imageURL: string;
    intensityRating: number;
    isShot: boolean;
    name: string;
    origin: string;
    price: string;
    process: string;
    region: string;
    roastDate: string;
    roastLevel: number;
    roasterId?: string;
    taste: string;
    type: string;
};

export class WaterLevelSnapShot {
    readonly currentLevel: number = 0;
    readonly refillLevel: number = 0;
    constructor(input: {currentLevel: number; refillLevel: number;}) {
        this.currentLevel = input.currentLevel;
        this.refillLevel = input.refillLevel;

    }
}
export class ScaleSnapShot {
    readonly weight: number = 0;
    readonly batteryLevel: number = 0;
    readonly timestamp: Date = new Date();
    constructor(input: {weight: number; batteryLevel: number; timestamp: Date}) {
        this.weight = input.weight;
        this.batteryLevel = input.batteryLevel;
        this.timestamp = input.timestamp;
    }
}

export class LogSnapShot {
    readonly message: string = '';
    readonly level: string = '';
    readonly timestamp: Date = new Date();
    constructor(input: {message: string; level: string; timestamp: Date}) {
        this.message = input.message;
        this.level = input.level;
        this.timestamp = input.timestamp;
    }
}

export class SnapShot {
    readonly timestamp: Date;
    readonly state: {state: string; substate: string};
    readonly flow: number;
    readonly pressure: number;
    readonly targetFlow: number;
    readonly targetPressure: number;
    readonly mixTemperature: number;
    readonly groupTemperature: number;
    readonly targetMixTemperature: number;
    readonly targetGroupTemperature: number;
    readonly profileFrame: number;
    readonly steamTemperature: number;

    constructor(input: {
        timestamp: string | Date;
        state: {state: string; substate: string};
        flow: number;
        pressure: number;
        targetFlow: number;
        targetPressure: number;
        mixTemperature: number;
        groupTemperature: number;
        targetMixTemperature: number;
        targetGroupTemperature: number;
        profileFrame: number;
        steamTemperature: number;
    }) {
        this.timestamp = input.timestamp instanceof Date ? input.timestamp : new Date(input.timestamp);
        this.state = input.state;
        this.flow = input.flow;
        this.pressure = input.pressure;
        this.targetFlow = input.targetFlow;
        this.targetPressure = input.targetPressure;
        this.mixTemperature = input.mixTemperature;
        this.groupTemperature = input.groupTemperature;
        this.targetMixTemperature = input.targetMixTemperature;
        this.targetGroupTemperature = input.targetGroupTemperature;
        this.profileFrame = input.profileFrame;
        this.steamTemperature = input.steamTemperature;
    }
}

export type ShotMeasurementMachine = {
    timestamp: Date;
    state: {state: string; substate: string};
    flow: number;
    pressure: number;
    mixTemperature: number;
};

export type ShotMeasurementScale = {
    timestamp: Date;
    weight: number;
    weightFlow: number;
    batteryLevel: number;
};

export type ShotMeasurement = {
    machine: ShotMeasurementMachine;
    scale?: ShotMeasurementScale;
    volume: number;
};

export type ShotWorkflow = {
    name: string;
    doseData: {
        doseIn: number;
        doseOut: number;
    };
};

export type Shot = {
    id: string;
    timestamp: Date;
    measurements: ShotMeasurement[];
    workflow: ShotWorkflow;
    recipeId?: string;
    profileId?: string;
    coffeeId?: string;
    roasterId?: string;
};

export type ApiShot = {
    id: string;
    timestamp: string;
    measurements: Array<{
        machine: {
            timestamp: string;
            state: {state: string; substate: string};
            flow: number;
            pressure: number;
            mixTemperature: number;
        };
        scale?: {
            timestamp: string;
            weight: number;
            weightFlow: number;
            batteryLevel: number;
        };
        volume: number;
    }>;
    workflow: ShotWorkflow;
    recipe?: RecipeEntity;
    coffee?: Coffee;

};

export const shotFromApi = (input: ApiShot): Shot => {
    return {
        id: input.id,
        timestamp: new Date(input.timestamp),
        measurements: input.measurements.map((m) => ({
            machine: {
                timestamp: new Date(m.machine.timestamp),
                state: m.machine.state,
                flow: m.machine.flow,
                pressure: m.machine.pressure,
                mixTemperature: m.machine.mixTemperature,
            },
            scale: m.scale ? {
                timestamp: new Date(m.scale.timestamp),
                weight: m.scale.weight,
                weightFlow: m.scale.weightFlow,
                batteryLevel: m.scale.batteryLevel,
            } : undefined,
            volume: m.volume,
        })),
        workflow: input.workflow,
        recipeId: input.recipe?.id,
        coffeeId: input.coffee?.id,
        roasterId: input.coffee?.roasterId,        
    };
};

export const shotEntityFromShot = (shot: Shot): ShotEntity => {
    const baseTime = shot.measurements[0]?.machine.timestamp.getTime() ?? shot.timestamp.getTime();
    const shotstates: ShotState[] = shot.measurements.map((measurement, index) => {
        const machine = measurement.machine;
        const scale = measurement.scale;
        const pourTime = (machine.timestamp.getTime() - baseTime) / 1000;
        return {
            __typename: 'ShotState',
            flowWeight: scale?.weightFlow ?? 0,
            frameName: machine.state.substate,
            frameNumber: index,
            groupFlow: machine.flow,
            groupPressure: machine.pressure,
            headTemp: machine.mixTemperature,
            id: index + 1,
            mixTemp: machine.mixTemperature,
            pourTime,
            sampleTime: pourTime,
            sampleTimeCorrected: pourTime,
            setGroupFlow: machine.flow,
            setGroupPressure: machine.pressure,
            setHeadTemp: machine.mixTemperature,
            setMixTemp: machine.mixTemperature,
            steamTemp: 0,
            subState: machine.state.substate,
            weight: scale?.weight ?? 0,            
        };
    });

    return {
        id: shot.id,
        date: shot.timestamp.toISOString(),
        description: shot.workflow.name,
        doseWeight: shot.workflow.doseData.doseIn,
        drinkWeight: shot.workflow.doseData.doseOut,
        shotstates,
        targetEspressoWeight: shot.workflow.doseData.doseOut,
        coffeeId: shot.coffeeId,
        profileId: shot.profileId,
        recipeId: shot.recipeId,

    };
};

export type WeightMeasurement = {
    __typename?: 'WeightMeasurement';
    flow: number;
    index: number;
    state: ScaleState;
    weight: number;
};

export type Device = {
    __typename?: 'Device';
    address?: string;
    id: string;
    localName?: string;
    rssi?: number;
};

export type EspressoMachineFullState = {
    __typename?: 'EspressoMachineFullState';
    state: EspressoMachineState;
    subState: string;
};

export type BleStatus = {
    __typename?: 'BleStatus';
    connected: Array<Device>;
    devices: Array<Device>;
    scanning: boolean;
};