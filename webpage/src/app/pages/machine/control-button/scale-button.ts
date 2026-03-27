import {ChangeDetectionStrategy, Component, computed, effect, inject, input, output, signal} from '@angular/core';
import {CommonModule} from '@angular/common';
import {MatButtonModule} from '@angular/material/button';
import {MatIconModule} from '@angular/material/icon';
import {MachineService} from '../../../services/machine.service';
import {ScaleState} from '../../../models/state';

@Component({
  selector: 'app-scale-button',
  imports: [CommonModule, MatButtonModule, MatIconModule],
  templateUrl: './scale-button.html',
  styleUrl: './scale-button.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ScaleButton {
  private readonly machineService = inject(MachineService);

  weight = this.machineService.weightUpdate;
  connected = signal<boolean>(false);
  disabled = signal<boolean>(false);

  clicked = output<void>();

  constructor() {
    effect(() => {
      const state = this.machineService.scaleState()[0];
      this.connected.set(state === ScaleState.Connected);
      this.disabled.set(state !== ScaleState.Connected);
    });
    
  }

  onTare() {
    if (this.connected()) {
      this.machineService.scaleTare(0);
    }    else {
      this.machineService.startScan();
    }
  }
}
