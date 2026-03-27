import {ChangeDetectionStrategy, Component, computed, effect, inject, signal} from '@angular/core';
import {CommonModule} from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import {MatSliderModule} from '@angular/material/slider';
import {MatButtonModule} from '@angular/material/button';
import {MatIconModule} from '@angular/material/icon';
import {MatProgressSpinnerModule} from '@angular/material/progress-spinner';
import {MatFormFieldModule} from '@angular/material/form-field';
import {MatInputModule} from '@angular/material/input';
import {MachineService} from '../../../services/machine.service';
import {SettingsService} from '../../../services/settings.service';
import {EspressoMachineState} from '../../../models/state';

@Component({
  selector: 'app-flush-tab',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatSliderModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatFormFieldModule,
    MatInputModule,
  ],
  templateUrl: './flush-tab.component.html',
  styleUrls: ['./flush-tab.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FlushTabComponent {
  private readonly machine = inject(MachineService);
  private readonly settingsSvc = inject(SettingsService);

  readonly settings = this.settingsSvc.settings;

  // Local state mirrors settings
  readonly targetFlushTime = computed(() => (this.settings()?.targetFlushTime ?? 0));
  readonly targetFlushTime2 = computed(() => (this.settings()?.targetFlushTime2 ?? 0));

  readonly isFlushing = computed<boolean>(() => this.machine.machineState()?.state === EspressoMachineState.Flush);
  readonly progressValue = signal<number>(0);
  interval?: number;

  constructor() {
    effect(() => {
      const s = this.isFlushing();
      if (s) {
        this.progressValue.set(0);
        const totalTimeMs = this.targetFlushTime() * 1000;
        const intervalMs = 20;
        const inc = 100 / (totalTimeMs / intervalMs);
        this.interval = setInterval(() => {
          this.progressValue.update((v) => {
            const next = v + inc;
            if (next >= 100) {
              clearInterval(this.interval);
              this.interval = undefined;
              return 100;
            }
            return next;
          });
        }, intervalMs);
      } else {
        if (this.interval) {
          clearInterval(this.interval);
          this.interval = undefined;
        }
        this.progressValue.set(0);
      }
    });
    this.settingsSvc.ensureLoaded();
  }

  async onFlushTimeChanged(v: number): Promise<void> {
    // this.targetFlushTime.set(v);
    await this.settingsSvc.updateSettings({targetFlushTime: v});
  }

  async onFlushTime2Changed(v: number): Promise<void> {
    // this.targetFlushTime2.set(v);
    await this.settingsSvc.updateSettings({targetFlushTime2: v});
  }

  async startFlush(): Promise<void> {
    await this.machine.requestState(EspressoMachineState.Flush);
  }

  async stopFlush(): Promise<void> {
    await this.machine.requestState(EspressoMachineState.Idle);
  }
}
