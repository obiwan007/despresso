
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