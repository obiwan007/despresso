import {ChangeDetectionStrategy, Component, computed, effect, inject, signal} from '@angular/core';
import {CommonModule} from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import {MatSliderModule} from '@angular/material/slider';
import {MatButtonModule} from '@angular/material/button';
import {MatIconModule} from '@angular/material/icon';
import {MatProgressSpinnerModule} from '@angular/material/progress-spinner';
import {MachineService} from '../../../services/machine.service';
import {SettingsService} from '../../../services/settings.service';
import {EspressoMachineState} from '../../../models/state';

@Component({
  selector: 'app-steam-tab',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatSliderModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
  ],
  templateUrl: './steam-tab.component.html',
  styleUrls: ['./steam-tab.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SteamTabComponent {
  private readonly machine = inject(MachineService);
  private readonly settingsSvc = inject(SettingsService);

  readonly settings = this.settingsSvc.settings;

  readonly isSteaming = computed<boolean>(() => this.machine.machineState()?.state === EspressoMachineState.Steam);
  readonly currentSteamTemp = computed<number>(() => this.machine.shotState()?.steamTemp ?? 0);
  readonly steamTempProgressPct = computed<number>(() => {
    const target = this.settings()?.targetSteamTemp;
    const val = this.currentSteamTemp();
    if (!target || target <= 0) return 0;
    const pct = (val / target) * 100;
    return Math.max(0, Math.min(100, Math.round(pct)));
  });

  constructor() {
    this.settingsSvc.ensureLoaded();
  }

  async onSteamTempChanged(v: number): Promise<void> {
    //this.targetSteamTemp.set(Number(v));
    await this.settingsSvc.updateSettings({targetSteamTemp: Number(v)});
  }

  async onSteamLengthChanged(v: number): Promise<void> {
    // this.targetSteamLength.set(Number(v));
    await this.settingsSvc.updateSettings({targetSteamLength: Number(v)});
  }

  async onMilkTempChanged(v: number): Promise<void> {
    //    this.targetMilkTemperature.set(Number(v));
    await this.settingsSvc.updateSettings({targetMilkTemperature: Number(v)});
  }

  async onSteamFlowChanged(v: number): Promise<void> {
    //this.targetSteamFlow.set(v);
    await this.settingsSvc.updateSettings({targetSteamFlow: Number(v)});
  }

  async startSteam(): Promise<void> {
    await this.machine.requestState(EspressoMachineState.Steam);
  }

  async stopSteam(): Promise<void> {
    await this.machine.requestState(EspressoMachineState.Idle);
  }

  async loadPreset(n: 1 | 2 | 3): Promise<void> {
    const s = this.settings();
    if (!s) return;
    const val = n === 1 ? s.targetMilkTempPreset1 : n === 2 ? s.targetMilkTempPreset2 : s.targetMilkTempPreset3;
    if (typeof val === 'number') {
      await this.onMilkTempChanged(val);
    }
  }

  async savePreset(n: 1 | 2 | 3): Promise<void> {
    const v = Number(this.settings()?.targetMilkTemperature);
    console.log("Save milk temp preset", n, v);
    const input =
      n === 1 ? {targetMilkTempPreset1: v} : n === 2 ? {targetMilkTempPreset2: v} : {targetMilkTempPreset3: v};
    await this.settingsSvc.updateSettings(input);
  }
}
