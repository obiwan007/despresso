import {ChangeDetectionStrategy, Component, computed, effect, inject, input, output, signal} from '@angular/core';
import {CommonModule} from '@angular/common';
import {MatButtonModule} from '@angular/material/button';
import {MatIconModule} from '@angular/material/icon';
import {EspressoMachineSubState, MachineService} from '../../../services/machine.service';
import {EspressoMachineState} from '../../../models/state';

@Component({
  selector: 'app-control-button',
  imports: [CommonModule, MatButtonModule, MatIconModule],
  templateUrl: './control-button.html',
  styleUrl: './control-button.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ControlButton {

  private readonly machineService = inject(MachineService);


  labelTop = signal<string>('Start');
  labelBottom = signal<string>('Ready to brew');
  icon = signal<string>('play_arrow');
  disabled = signal<boolean>(false);
  color = signal<'red' | 'blue' | 'green' | 'orange'>('green');

  clicked = output<void>();

  /**
   *
   */
  constructor() {

    effect(() => {

      let labelTop = '';
      let color: 'red' | 'blue' | 'green' | 'orange' = 'red';
      const {state, subState} = this.machineService.machineState() ?? {};
      const subStateText = this.machineService.subState() ?? '';

      switch (state) {
        case EspressoMachineState.Idle:
          if (subState === EspressoMachineSubState.HeatWaterTank) {
            labelTop = 'Heating';
            this.labelBottom.set(subStateText);
            color = 'orange';
          } else {
            labelTop = 'Start';
            this.labelBottom.set('Ready to brew');
            color = 'green';
          }
          break;
        case EspressoMachineState.Espresso:
          labelTop = 'Stop Brewing';
          color = 'red';
          this.labelBottom.set(subStateText);
          break;
        case EspressoMachineState.Steam:
          labelTop = 'Stop Steaming';
          color = 'red';
          this.labelBottom.set(subStateText);
          break;
        case EspressoMachineState.Water:
          labelTop = 'Stop Water';
          color = 'red';
          this.labelBottom.set(subStateText);
          break;
        case EspressoMachineState.Flush:
          labelTop = 'Stop Flush';
          color = 'red';
          this.labelBottom.set(subStateText);
          break;
        default:
          labelTop = state ?? 'WAIT';
          color = 'red';
          this.labelBottom.set(subStateText);
      }

      this.labelTop.set(labelTop);
      this.color.set(color);

    });



  }

}
