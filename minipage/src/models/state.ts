
export enum EspressoMachineState {
    idle = "idle", espresso = "espresso",
    water = "water", steam = "steam", sleep = "sleep", disconnected = "disconnected", connecting = "connecting", refill = "refill", flush = "flush"
}


export class State {
    state: EspressoMachineState = EspressoMachineState.disconnected;
    subState: string = '';

    static fromRaw(data: any): State {
        return Object.assign(new State(), data);
    }
}

export class Shot {
    subState: string = "";
    weight: number = 0;
    sampleTime: number = 0;
    sampleTimeCorrected: number = 0;
    pourTime: number = 0;
    groupPressure: number = 0;
    groupFlow: number = 0;
    mixTemp: number = 0;
    headTemp: number = 0;
    setMixTemp: number = 0;
    setHeadTemp: number = 0;
    setGroupPressure: number = 0;
    setGroupFlow: number = 0;
    flowWeight: number = 0;
    frameNumber: number = 0;
    steamTemp: number = 0;

    static fromRaw(data: any): Shot {
        return Object.assign(new Shot(), data);
    }

}