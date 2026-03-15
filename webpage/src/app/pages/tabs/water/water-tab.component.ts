import {ChangeDetectionStrategy, Component, computed, effect, inject, signal} from '@angular/core';
import {CommonModule} from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import {MatFormFieldModule} from '@angular/material/form-field';
import {MatInputModule} from '@angular/material/input';
import {MatSliderModule} from '@angular/material/slider';
import {MatButtonModule} from '@angular/material/button';
import {MatIconModule} from '@angular/material/icon';
import {MatProgressBarModule} from '@angular/material/progress-bar';
import {MachineService} from '../../../services/machine.service';
import {SettingsService} from '../../../services/settings.service';
import {EspressoMachineState} from '../../../models/state';


@Component({
  selector: 'app-water-tab',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatSliderModule,
    MatButtonModule,
    MatIconModule,
    MatProgressBarModule,
  ],
  templateUrl: './water-tab.component.html',
  styleUrls: ['./water-tab.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WaterTabComponent {
  private readonly machine = inject(MachineService);
  private readonly settingsSvc = inject(SettingsService);

  readonly settings = this.settingsSvc.settings;

  // Local controls state
  readonly targetTemp = signal<number>(90);
  readonly targetWeight = signal<number>(200);

  // Derived live state
  readonly isPouring = computed<boolean>(() => {
    const st = this.machine.machineState();
    return st?.state === EspressoMachineState.Water;
  });

  readonly currentWeight = computed<number>(() => this.machine.weightUpdate()?.weight ?? 0);

  readonly progressPct = computed<number>(() => {
    const target = this.targetWeight();
    if (!target || target <= 0) return 0;
    const pct = (this.currentWeight() / target) * 100;
    return Math.max(0, Math.min(100, Math.round(pct)));
  });

  constructor() {
    // Initialize controls from settings when available
    effect(() => {
      const s = this.settings();
      if (!s) return;
      if (typeof s.targetHotWaterTemp === 'number') this.targetTemp.set(s.targetHotWaterTemp);
      if (typeof s.targetHotWaterWeight === 'number') this.targetWeight.set(s.targetHotWaterWeight);
    });
    // Ensure settings are loaded at least once
    this.settingsSvc.ensureLoaded();
  }

  async onTempChanged(value: number): Promise<void> {
    this.targetTemp.set(value);
    await this.settingsSvc.updateSettings({targetHotWaterTemp: value});
  }

  async onWeightChanged(raw: string | number): Promise<void> {
    const v = typeof raw === 'number' ? raw : Number(raw);
    if (!Number.isFinite(v) || v <= 0) return;
    this.targetWeight.set(v);
    await this.settingsSvc.updateSettings({targetHotWaterWeight: v, targetHotWaterVol: v});
  }

  async startWater(): Promise<void> {
    await this.machine.requestState(EspressoMachineState.Water);
  }

  async stopWater(): Promise<void> {
    await this.machine.requestState(EspressoMachineState.Idle);
  }

  async tareScale(): Promise<void> {
    await this.machine.scaleTare(0);
  }
}
