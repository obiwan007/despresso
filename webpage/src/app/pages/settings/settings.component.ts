import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
  OnDestroy,
  effect,
  inject,
  signal,
} from '@angular/core';
import { Router } from '@angular/router';
import { ReactiveFormsModule, FormBuilder, FormGroup } from '@angular/forms';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatButtonToggleModule } from '@angular/material/button-toggle';
import { MatButtonModule } from '@angular/material/button';
import { MatExpansionModule } from '@angular/material/expansion';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatCardModule } from '@angular/material/card';
import {SettingsService} from '../../services/settings.service';
import { MatIconModule } from '@angular/material/icon';
import { MachineService } from '../../services/machine.service';
import { ToolbarService } from '../../services/toolbar.service';
import {Settings} from '../../models/state';
import {ThemeMode, ThemeService} from '../../services/theme.service';

@Component({
  selector: 'app-settings',
  imports: [
    MatCardModule,
    MatButtonToggleModule,
    MatButtonModule,
    MatSnackBarModule,
    MatExpansionModule,
    ReactiveFormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatSlideToggleModule,
    MatIconModule,
  ],
  templateUrl: './settings.component.html',
  styleUrls: ['./settings.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SettingsComponent implements OnInit, OnDestroy {
  protected readonly mode = signal<ThemeMode>('system');
  protected readonly saving = signal<boolean>(false);
  protected form!: FormGroup;

  machineService = inject(MachineService);
  toolbar = inject(ToolbarService);

  constructor(
    private readonly theme: ThemeService,
    private readonly settingsService: SettingsService,
    private readonly snack: MatSnackBar,
    private readonly fb: FormBuilder,
    private readonly router: Router,
  ) {
    this.form = this.fb.group({
      // MQTT & Cloud
      mqttEnabled: [false],
      mqttServer: [''],
      mqttPort: [''],
      mqttUser: [''],
      mqttPassword: [''],
      mqttRootTopic: [''],
      mqttSendState: [false],
      mqttSendShot: [false],
      mqttSendBattery: [false],
      mqttSendWater: [false],

      // Shot & Scale
      shotStopOnWeight: [false],
      shotAutoTare: [false],
      scaleStartTimer: [false],
      tareOnWakeUp: [false],
      tareOnDetectedWeight: [false],
      scaleDisplayOffOnSleep: [false],
      targetEspressoWeightTimeAdjust: [0],
      stepLimitWeightTimeAdjust: [0],
      alwaysAllowSkipping: [false],

      // Flush & Water
      showFlushScreen: [false],
      targetFlushTime: [0],
      targetFlushTime2: [0],
      targetWaterlevel: [0],

      // Device flags
      hasScale: [false],
      hasSteamThermometer: [false],
      hasRefractometer: [false],
      steamHeaterOff: [false],

      // Tablet brightness & sleep
      screenBrightnessTimer: [0],
      screenBrightnessValue: [0],
      screensaverShowClock: [false],
      tabletSleepDuringScreensaver: [false],
      tabletSleepDuringScreensaverTimeout: [0],
      tabletSleepWhenMachineOff: [false],
      launchWake: [false],
      screenTimoutGoToRecipe: [false],

      // Smart charging & mini website
      smartCharging: [false],
      webServer: [false],

      // Experimental CafeHub
      useCafeHub: [false],
      chUrl: [''],
      useLongUUID: [false],

      // Visualizer
      visualizerUpload: [false],
      visualizerExtendedUpload: [false],
      visualizerExtendedUrl: [''],
      visualizerExtendedUser: [''],
      visualizerExtendedPwd: [''],
      visualizerClientId: [''],
      visualizerClientSecret: [''],

      // Misc
      sleepTimer: [0 as number | null],
    });
    this.form.get('mqttEnabled')?.valueChanges.subscribe(() => this.updateMqttFieldsEnabled());
    this.form
      .get('visualizerExtendedUpload')
      ?.valueChanges.subscribe(() => this.updateVisualizerFieldsEnabled());

    effect(() => {
      const s = this.settingsService.settings();
      if (!s) return;
      this.patchFromSettings(s);
      this.updateMqttFieldsEnabled();
      this.updateVisualizerFieldsEnabled();
    });
  }

  ngOnInit(): void {
    this.mode.set(this.theme.getMode());
    void this.settingsService.ensureLoaded();
    // If settings are already present, patch immediately
    const initial = this.settingsService.settings();
    if (initial) {
      this.patchFromSettings(initial);
      this.updateMqttFieldsEnabled();
      this.updateVisualizerFieldsEnabled();
    }
    // Listen for global save intent from toolbar
    window.addEventListener('app-save', this._onAppSave, { passive: true });
    // Show Save button while on settings page
    this.toolbar.setSaveVisible(true);
  }

  ngOnDestroy(): void {
    window.removeEventListener('app-save', this._onAppSave);
    // Hide Save button when leaving settings page
    this.toolbar.setSaveVisible(false);
  }

  private _onAppSave = (_e: Event) => {
    // Trigger local save when global app-save is dispatched
    void this.save();
  };

  private patchFromSettings(s: Settings): void {
    this.form.patchValue({
      mqttEnabled: !!s.mqttEnabled,
      mqttServer: s.mqttServer ?? '',
      mqttPort: s.mqttPort ?? '',
      mqttUser: s.mqttUser ?? '',
      mqttPassword: s.mqttPassword ?? '',
      mqttRootTopic: s.mqttRootTopic ?? '',
      mqttSendState: !!s.mqttSendState,
      mqttSendShot: !!s.mqttSendShot,
      mqttSendBattery: !!s.mqttSendBattery,
      mqttSendWater: !!s.mqttSendWater,

      shotStopOnWeight: !!s.shotStopOnWeight,
      shotAutoTare: !!s.shotAutoTare,
      scaleStartTimer: !!s.scaleStartTimer,
      tareOnWakeUp: !!s.tareOnWakeUp,
      tareOnDetectedWeight: !!s.tareOnDetectedWeight,
      scaleDisplayOffOnSleep: !!s.scaleDisplayOffOnSleep,
      targetEspressoWeightTimeAdjust: s.targetEspressoWeightTimeAdjust ?? 0,
      stepLimitWeightTimeAdjust: s.stepLimitWeightTimeAdjust ?? 0,
      alwaysAllowSkipping: !!s.alwaysAllowSkipping,

      showFlushScreen: !!s.showFlushScreen,
      targetFlushTime: s.targetFlushTime ?? 0,
      targetFlushTime2: s.targetFlushTime2 ?? 0,
      targetWaterlevel: s.targetWaterlevel ?? 0,

      hasScale: !!s.hasScale,
      hasSteamThermometer: !!s.hasSteamThermometer,
      hasRefractometer: !!s.hasRefractometer,
      steamHeaterOff: !!s.steamHeaterOff,

      screenBrightnessTimer: s.screenBrightnessTimer ?? 0,
      screenBrightnessValue: s.screenBrightnessValue ?? 0,
      screensaverShowClock: !!s.screensaverShowClock,
      tabletSleepDuringScreensaver: !!s.tabletSleepDuringScreensaver,
      tabletSleepDuringScreensaverTimeout: s.tabletSleepDuringScreensaverTimeout ?? 0,
      tabletSleepWhenMachineOff: !!s.tabletSleepWhenMachineOff,
      launchWake: !!s.launchWake,
      screenTimoutGoToRecipe: !!s.screenTimoutGoToRecipe,

      smartCharging: !!s.smartCharging,
      webServer: !!s.webServer,

      useCafeHub: !!s.useCafeHub,
      chUrl: s.chUrl ?? '',
      useLongUUID: !!s.useLongUUID,

      visualizerUpload: !!s.visualizerUpload,
      visualizerExtendedUpload: !!s.visualizerExtendedUpload,
      visualizerExtendedUrl: s.visualizerExtendedUrl ?? '',
      visualizerExtendedUser: s.visualizerExtendedUser ?? '',
      visualizerExtendedPwd: s.visualizerExtendedPwd ?? '',
      visualizerClientId: s.visualizerClientId ?? '',
      visualizerClientSecret: s.visualizerClientSecret ?? '',

      sleepTimer: s.sleepTimer ?? 0,
    });
  }

  onModeChange(value: ThemeMode): void {
    this.mode.set(value);
    this.theme.setMode(value);
  }

  async save(): Promise<void> {
    if (this.saving()) return;
    this.saving.set(true);
    try {
      const mode = this.mode();
      const input: Record<string, any> = {};
      if (mode === 'light') input['screenDarkTheme'] = false;
      else if (mode === 'dark') input['screenDarkTheme'] = true;
      // system -> omit to keep backend unchanged

      const v = this.form.value as any;
      input['mqttEnabled'] = !!v.mqttEnabled;
      if (v.mqttServer !== undefined) input['mqttServer'] = v.mqttServer || null;
      if (v.mqttPort !== undefined) input['mqttPort'] = v.mqttPort || null;
      if (v.mqttUser !== undefined) input['mqttUser'] = v.mqttUser || null;
      if (v.mqttPassword !== undefined) input['mqttPassword'] = v.mqttPassword || null;
      if (v.mqttRootTopic !== undefined) input['mqttRootTopic'] = v.mqttRootTopic || null;
      input['mqttSendState'] = !!v.mqttSendState;
      input['mqttSendShot'] = !!v.mqttSendShot;
      input['mqttSendBattery'] = !!v.mqttSendBattery;
      input['mqttSendWater'] = !!v.mqttSendWater;

      input['shotStopOnWeight'] = !!v.shotStopOnWeight;
      input['shotAutoTare'] = !!v.shotAutoTare;
      input['scaleStartTimer'] = !!v.scaleStartTimer;
      input['tareOnWakeUp'] = !!v.tareOnWakeUp;
      input['tareOnDetectedWeight'] = !!v.tareOnDetectedWeight;
      input['scaleDisplayOffOnSleep'] = !!v.scaleDisplayOffOnSleep;
      if (
        v.targetEspressoWeightTimeAdjust !== undefined &&
        v.targetEspressoWeightTimeAdjust !== null
      )
        input['targetEspressoWeightTimeAdjust'] = Number(v.targetEspressoWeightTimeAdjust);
      if (v.stepLimitWeightTimeAdjust !== undefined && v.stepLimitWeightTimeAdjust !== null)
        input['stepLimitWeightTimeAdjust'] = Number(v.stepLimitWeightTimeAdjust);
      input['alwaysAllowSkipping'] = !!v.alwaysAllowSkipping;

      input['showFlushScreen'] = !!v.showFlushScreen;
      if (v.targetFlushTime !== undefined && v.targetFlushTime !== null)
        input['targetFlushTime'] = Number(v.targetFlushTime);
      if (v.targetFlushTime2 !== undefined && v.targetFlushTime2 !== null)
        input['targetFlushTime2'] = Number(v.targetFlushTime2);
      if (v.targetWaterlevel !== undefined && v.targetWaterlevel !== null)
        input['targetWaterlevel'] = Number(v.targetWaterlevel);

      input['hasScale'] = !!v.hasScale;
      input['hasSteamThermometer'] = !!v.hasSteamThermometer;
      input['hasRefractometer'] = !!v.hasRefractometer;
      input['steamHeaterOff'] = !!v.steamHeaterOff;

      if (v.screenBrightnessTimer !== undefined && v.screenBrightnessTimer !== null)
        input['screenBrightnessTimer'] = Number(v.screenBrightnessTimer);
      if (v.screenBrightnessValue !== undefined && v.screenBrightnessValue !== null)
        input['screenBrightnessValue'] = Number(v.screenBrightnessValue);
      input['screensaverShowClock'] = !!v.screensaverShowClock;
      input['tabletSleepDuringScreensaver'] = !!v.tabletSleepDuringScreensaver;
      if (
        v.tabletSleepDuringScreensaverTimeout !== undefined &&
        v.tabletSleepDuringScreensaverTimeout !== null
      )
        input['tabletSleepDuringScreensaverTimeout'] = Number(
          v.tabletSleepDuringScreensaverTimeout,
        );
      input['tabletSleepWhenMachineOff'] = !!v.tabletSleepWhenMachineOff;
      input['launchWake'] = !!v.launchWake;
      input['screenTimoutGoToRecipe'] = !!v.screenTimoutGoToRecipe;

      input['smartCharging'] = !!v.smartCharging;
      input['webServer'] = !!v.webServer;

      input['useCafeHub'] = !!v.useCafeHub;
      if (v.chUrl !== undefined) input['chUrl'] = v.chUrl || null;
      input['useLongUUID'] = !!v.useLongUUID;

      input['visualizerUpload'] = !!v.visualizerUpload;
      input['visualizerExtendedUpload'] = !!v.visualizerExtendedUpload;
      if (v.visualizerExtendedUrl !== undefined)
        input['visualizerExtendedUrl'] = v.visualizerExtendedUrl || null;
      if (v.visualizerExtendedUser !== undefined)
        input['visualizerExtendedUser'] = v.visualizerExtendedUser || null;
      if (v.visualizerExtendedPwd !== undefined)
        input['visualizerExtendedPwd'] = v.visualizerExtendedPwd || null;
      if (v.visualizerClientId !== undefined)
        input['visualizerClientId'] = v.visualizerClientId || null;
      if (v.visualizerClientSecret !== undefined)
        input['visualizerClientSecret'] = v.visualizerClientSecret || null;

      if (v.sleepTimer !== undefined && v.sleepTimer !== null)
        input['sleepTimer'] = Number(v.sleepTimer);

      await this.settingsService.updateSettings(input);
      this.snack.open('Settings saved', 'OK', { duration: 2500 });
      this.router.navigateByUrl('/');
    } catch (e: any) {
      this.snack.open(e?.message || 'Failed to save settings', 'Dismiss', { duration: 3500 });
    } finally {
      this.saving.set(false);
    }
  }

  private updateMqttFieldsEnabled(): void {
    const enabled = !!this.form.get('mqttEnabled')?.value;
    const names = ['mqttServer', 'mqttPort', 'mqttUser', 'mqttPassword', 'mqttRootTopic'];
    for (const n of names) {
      const c = this.form.get(n);
      if (!c) continue;
      if (enabled) c.enable({ emitEvent: false });
      else c.disable({ emitEvent: false });
    }
  }

  private updateVisualizerFieldsEnabled(): void {
    const enabled = !!this.form.get('visualizerExtendedUpload')?.value;
    const names = ['visualizerExtendedUrl', 'visualizerExtendedUser', 'visualizerExtendedPwd'];
    for (const n of names) {
      const c = this.form.get(n);
      if (!c) continue;
      if (enabled) c.enable({ emitEvent: false });
      else c.disable({ emitEvent: false });
    }
  }

  back(): void {
    this.router.navigateByUrl('/');
  }

  async loginVisualizer(): Promise<void> {
    // await this.auth.startLogin();
  }
}
