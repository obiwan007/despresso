import {Injectable, signal} from '@angular/core';
import {Subject} from 'rxjs';
import {debounceTime, tap} from 'rxjs/operators';
import {Settings} from '../models/state';


@Injectable({ providedIn: 'root' })
export class SettingsService {

  private readonly _settings = signal<Settings | null>(null);
  // Public readonly signal for consumers
  readonly settings = this._settings.asReadonly();

  // RxJS-based debounced mutation pipeline
  private readonly debounceMs = 1000;
  private readonly updateInput$ = new Subject<Partial<Settings>>();
  private readonly updateResult$;

  private readonly mockSettings: Settings = {
    __typename: 'Settings',
    alwaysAllowSkipping: true,
    currentProfile: 'default',
    currentVersion: '1.0.0-mock',
    hasScale: true,
    hasSteamThermometer: false,
    locale: 'en-US',
    mqttEnabled: false,
    mqttPort: '1883',
    mqttServer: 'localhost',
    recordPrePouring: true,
    screenBrightnessTimer: 120,
    screenBrightnessValue: 70,
    screenDarkTheme: false,
    screenThemeIndex: 'classic',
    screenThemeMode: 1,
    screensaverOnIfIdle: true,
    screensaverShowClock: true,
    selectedCoffee: '1',
    selectedRecipe: '1',
    selectedRoaster: '1',
    selectedShot: 0,
    shotAutoTare: true,
    shotStopOnWeight: true,
    sleepTimer: 900,
    smartCharging: true,
    startCounter: 128,
    steamHeaterOff: false,
    steamSettings: 2,
    targetEspressoVol: 36,
    targetEspressoWeight: 36,
    targetGroupTemp: 93,
    targetHotWaterTemp: 90,
    targetMilkTemperature: 60,
    targetSteamFlow: 3,
    targetSteamLength: 20,
    targetSteamTemp: 135,
    targetTempCorrection: 0,
    targetWaterlevel: 80,
    useCafeHub: false,
    useLongUUID: false,
    useSentry: false,
    webServer: true,
  };

  constructor() {
    setInterval(() => this.checkBattery(), 60000);
    this.requestWakelook();
    this.fetchSettings();

    this.updateResult$ = this.updateInput$
      .pipe(
        // Merge successive inputs; latest keys win
        // scan((acc, next) => ({...acc, ...next}), {} as SettingsInput),
        // tap((s) => this._settings.update(c => c ? {...c, ...s} : s as Settings)),
        debounceTime(this.debounceMs),
        tap((s) => console.log('Updating settings with debounce:', s)),
        //shareReplay(1)
      )
      .subscribe(async (input) => {
        const r = await this.mutateSettings(input);
        this._settings.set(r.data!.updateSettings);
      });
  }

  public mutateSettings(input: Partial<Settings>) {
    console.log('Mutating settings (mock):', input);
    const merged = {...this.mockSettings, ...this._settings(), ...input};
    this._settings.set(merged);
    return Promise.resolve({
      data: {
        updateSettings: merged,
      },
    });
  }

  async fetchSettings(): Promise<Settings> {
    const s = {...this.mockSettings};
    this._settings.set(s);
    return Promise.resolve(s);
  }

  async updateSettings(input: Partial<Settings>) {
    // Push into debounced pipeline and await next mutation result
    this.updateInput$.next(input);
  }

  async ensureLoaded(): Promise<Settings> {
    const existing = this._settings();
    if (existing) return existing;
    return this.fetchSettings();
  }

  checkBattery() {
    try {
      (navigator as any)?.getBattery().then((battery: any) => {
        console.log('Battery level:', battery, battery?.level); // 0.0 – 1.0
      });
    } catch (_e) {}
  }

  async requestWakelook() {
    console.log('Wake Lock request');
    try {
      const granted: WakeLockSentinel = await navigator.wakeLock.request('screen');
      console.log('Wake Lock granted:', granted);
    } catch (error) {
      console.log('Wake Lock request failed:', error);
    }
  }
}
