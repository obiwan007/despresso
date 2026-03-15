import {
  Component,
  ChangeDetectionStrategy,
  computed,
  effect,
  signal,
  inject,
} from '@angular/core';

import { MatCardModule } from '@angular/material/card';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { GaugeComponent } from './gauge/gauge.component';
import { WaterGaugeComponent } from '../../components/water-gauge/water-gauge.component';
import { MachineService } from '../../services/machine.service';
import { ControlButton } from './control-button/control-button';
import { ScaleButton } from './control-button/scale-button';
import { GrowingCircleComponent } from '../../components/growing-circle/growing-circle.component';
import { ProfilesService } from '../../services/profiles.service';
import { SettingsService } from '../../services/settings.service';
import {EspressoMachineState} from '../../models/state';

@Component({
  selector: 'app-machine',
  standalone: true,
  imports: [
    MatCardModule,
    MatSlideToggleModule,
    GaugeComponent,
    ControlButton,
    ScaleButton,
    WaterGaugeComponent,
    GrowingCircleComponent,
  ],
  templateUrl: './machine.component.html',
  styleUrls: ['./machine.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MachineComponent {
  readonly machineService = inject(MachineService);
  readonly profilesService = inject(ProfilesService);
  readonly settingsService = inject(SettingsService);

  pressure = signal(0);
  temp = signal(20);
  time = signal(0);
  weight = signal(0);
  flow = signal(0);

  // Display signals: map to live when enabled, else simulation
  displayPressure = computed(() => {
    return this.machineService.shotState()?.groupPressure ?? 0;
  });

  displayDestWeight = computed(() => {
    const r = this.settingsService.settings()?.selectedRecipe;
    if (r) {
      if (this.state()?.state === EspressoMachineState.Espresso) {
        return this.profilesService.getRecipeById(r)?.adjustedWeight ?? 35;
      } else {
        return this.profilesService.getRecipeById(r)?.weightWater ?? 80;
      }
    }
    return 35;
  });

  displayTemp = computed(() => {
    let temp = 0;
    switch (this.machineService.machineState()?.state) {
      case EspressoMachineState.Steam:
        temp = this.machineService.shotState()?.steamTemp ?? -1;
        break;
      case EspressoMachineState.Espresso:
        temp = this.machineService.shotState()?.mixTemp ?? -1;
        break;

      default:
        temp = this.machineService.shotState()?.mixTemp ?? -1;
    }
    return temp;
  });

  displayTime = computed(() => {
    return this.machineService.shotTimer() ?? 0;
  });

  displayWeight = computed(() => {
    return (
      this.machineService.weightUpdate()?.weight ?? this.machineService.shotState()?.weight ?? 0
    );
  });

  displayFlow = computed(() => {
    return (
      this.machineService.shotState()?.groupFlow 
    );
  });

  displayStatus = computed(() => {
    return this.machineService.machineState()?.state ?? 'unknown';
  });

  state = this.machineService.machineState;
  subState = this.machineService.subState;

  // Machine power state: on when not Sleep or Disconnected
  isOn = computed(() => {
    const s = this.machineService.machineState()?.state;
    return (
      s !== undefined && s !== EspressoMachineState.Sleep && s !== EspressoMachineState.Disconnected
    );
  });

  async togglePower() {
    if (this.isOn()) {
      await this.machineService.switchOff();
    } else {
      await this.machineService.switchOn();
    }
  }

  async onPowerToggle(checked: boolean) {
    if (checked) {
      await this.machineService.switchOn();
    } else {
      await this.machineService.switchOff();
    }
  }
}
