import {effect, Injectable, signal} from "@angular/core";
import {ApiShot, EspressoMachineState, SnapShot, Shot, shotFromApi, ScaleSnapShot, WaterLevelSnapShot, LogSnapShot} from "../models/state";

const GATEWAY_URL = 'http://localhost:4200';
const WS_URL = 'ws://localhost:4200';

export { GATEWAY_URL, WS_URL };

type ApiDevice = {
    name: string;
    id: string;
    state: string;
    type: string;
};

@Injectable({ providedIn: 'root' })
export class ApiService {

    readonly snapshot = signal<SnapShot | null>(null);
    readonly scaleSnapshot = signal<ScaleSnapShot | null>(null);
    readonly waterLevelSnapshot = signal<WaterLevelSnapShot | null>(null);
    readonly logSnapshot = signal<LogSnapShot | null>(null);  
    readonly devices = signal<ApiDevice[]>([]);
    readonly shotIds = signal<string[]>([]);

    /**
     *
     */
    constructor() {
        this.initShots();

        effect(() => {
            const logSnapshot = this.logSnapshot();
            console.log(`${logSnapshot?.timestamp} = ${logSnapshot?.level}: ${logSnapshot?.message}`);
        });

    }

    private initShots() {
        this.getAllShotIds().then(ids => {
            console.log('Initial shot IDs:', ids);
            if (ids.length > 0) {
                this.getShots([ids[ids.length - 1]]).then(shots => {
                    console.log('Initial shots:', shots);
                });
            }
        });
    }

    test() {
    // Test connection
        fetch(`${GATEWAY_URL}/api/v1/machine/state`)
        .then(res => res.json())
        .then(data => console.log('Machine state:', data))
        .catch(err => console.error('Connection failed:', err));
    }

    async initWebserviceMachine() {
        const ws = new WebSocket(`${WS_URL}/ws/v1/machine/snapshot`);

        ws.onopen = () => {
        console.log('Connected to machine snapshot stream');
        };

        ws.onmessage = (event) => {
        const snapshot = JSON.parse(event.data);
        this.snapshot.set(new SnapShot(snapshot));
        // console.log('Received snapshot:', this.snapshot());

        };

        ws.onerror = (error) => {
        console.error('WebSocket error:', error);
        };

        ws.onclose = () => {
            console.log('WebSocket Machine closed, attempting reconnect...');
            setTimeout(() => this.initWebserviceMachine(), 1000);
        };
    }

    async initWebserviceScale() {
        const ws = new WebSocket(`${WS_URL}/ws/v1/scale/snapshot`);

        ws.onopen = () => {
            console.log('Connected to scale snapshot stream');
        };

        ws.onmessage = (event) => {
            const snapshot = JSON.parse(event.data);
            this.scaleSnapshot.set(new ScaleSnapShot(snapshot));
            // console.log('Received snapshot:', this.snapshot());

        };

        ws.onerror = (error) => {
            console.error('WebSocket error:', error);
        };

        ws.onclose = () => {
            console.log('WebSocket Scale closed, attempting reconnect...');
            setTimeout(() => this.initWebserviceScale(), 1000);
        };
    }

    async initWebserviceWaterlevel() {
        const ws = new WebSocket(`${WS_URL}/ws/v1/machine/waterLevels`);

        ws.onopen = () => {
            console.log('Connected to water level snapshot stream');
        };

        ws.onmessage = (event) => {
            const snapshot = JSON.parse(event.data);
            this.waterLevelSnapshot.set(new WaterLevelSnapShot(snapshot));
            // console.log('Received snapshot:', this.snapshot());

        };

        ws.onerror = (error) => {
            console.error('WebSocket error:', error);
        };

        ws.onclose = () => {
            console.log('WebSocket closed, attempting reconnect...');
            setTimeout(() => this.initWebserviceScale(), 1000);
        };
    }

    async initWebserviceLogs() {
        const ws = new WebSocket(`${WS_URL}/ws/v1/logs`);

        ws.onopen = () => {
            console.log('Connected to logs snapshot stream');
        };

        ws.onmessage = (event) => {
            const snapshot = JSON.parse(event.data);
            this.logSnapshot.set(new LogSnapShot(snapshot));
            // console.log('Received snapshot:', this.snapshot());

        };

        ws.onerror = (error) => {
            console.error('WebSocket error:', error);
        };

        ws.onclose = () => {
            console.log('WebSocket Logs closed, attempting reconnect...');
            setTimeout(() => this.initWebserviceLogs(), 1000);
        };
    }

    getDevices() {
    // Test connection
        fetch(`${GATEWAY_URL}/api/v1/devices`)
        .then(res => res.json())
        .then((data: ApiDevice[]) => {
            const list = Array.isArray(data) ? data : [];
            this.devices.set(list);
            console.log('Devices:', list);
        })
        .catch(err => console.error('Connection failed:', err));
    }

    scanDevices(connect = false, quick = false) {
        const params = new URLSearchParams({
            connect: String(connect),
            quick: String(quick),
        });
        fetch(`${GATEWAY_URL}/api/v1/devices/scan?${params.toString()}`, {method: 'GET'})
        .then(res => res.json())
        .then((data: ApiDevice[]) => {
            const list = Array.isArray(data) ? data : [];
            this.devices.set(list);
            console.log('Scan devices:', list);
        })
        .catch(err => console.error('Connection failed:', err));
    }

    connectDevice(deviceId: string) {
        const params = new URLSearchParams({ deviceId });
        fetch(`${GATEWAY_URL}/api/v1/devices/connect?${params.toString()}`, { method: 'PUT' })
        .then(res => res.json())
        .then((data: ApiDevice[] | ApiDevice | null) => {
            if (Array.isArray(data)) {
                this.devices.set(data);
                console.log('Connected devices:', data);
                return;
            }
            if (data) {
                this.devices.update((list) => {
                    const next = list.slice();
                    const index = next.findIndex((d) => d.id === data.id);
                    if (index >= 0) {
                        next[index] = data;
                        return next;
                    }
                    next.push(data);
                    return next;
                });
                console.log('Connected device:', data);
                return;
            }
            console.log('Connected device: no data');
        })
        .catch(err => console.error('Connection failed:', err));
    }

    setState(newState: EspressoMachineState) {
        const stateMap: Record<EspressoMachineState, string> = {
            [EspressoMachineState.AirPurge]: 'airPurge',
            [EspressoMachineState.Clean]: 'clean',
            [EspressoMachineState.Connecting]: 'connecting',
            [EspressoMachineState.Descale]: 'descale',
            [EspressoMachineState.Disconnected]: 'disconnected',
            [EspressoMachineState.Espresso]: 'espresso',
            [EspressoMachineState.Flush]: 'flush',
            [EspressoMachineState.Idle]: 'idle',
            [EspressoMachineState.Refill]: 'refill',
            [EspressoMachineState.Sleep]: 'sleeping',
            [EspressoMachineState.Steam]: 'steam',
            [EspressoMachineState.Water]: 'hotWater',
        };
        const target = stateMap[newState] ?? newState;
        return fetch(`${GATEWAY_URL}/api/v1/machine/state/${target}`, { method: 'PUT' })
        .then(res => res.json())
        .then(data => console.log('State change:', data))
        .catch(err => console.error('Connection failed:', err));
    }

    tareScale() {
        return fetch(`${GATEWAY_URL}/api/v1/scale/tare`, { method: 'PUT' })
        .then(res => res.json())
        .then(data => console.log('Tare scale:', data))
        .catch(err => console.error('Connection failed:', err));
    }

    getAllShotIds(): Promise<string[]> {
        return fetch(`${GATEWAY_URL}/api/v1/shots/ids`)
        .then(res => res.json())
        .then(data => {
            console.log('Shot IDs:', data);
            this.shotIds.set(data);
            return data as string[];
        })
        .catch(err => {
            console.error('Connection failed:', err);
            return [] as string[];
        });
    }

    getShots(ids: string[]): Promise<Shot[]> {
        const params = new URLSearchParams({ ids: ids.join(',') });
        return fetch(`${GATEWAY_URL}/api/v1/shots?${params.toString()}`)
        .then(res => res.json())
        .then((data: ApiShot[]) => {
            const list =  data.map(shotFromApi);
            console.log('Shots:', list);
            return list;
        })
        .catch(err => {
            console.error('Connection failed:', err);
            return [] as Shot[];
        });
    }

    
    
}