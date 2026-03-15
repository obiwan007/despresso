import {Component, effect, inject, signal} from '@angular/core';
// NgIf no longer used in template
import {RouterLink} from '@angular/router';
import {MatTabsModule} from '@angular/material/tabs';
import {MatSidenavModule} from '@angular/material/sidenav';
import { MatButtonModule } from '@angular/material/button';
import {MatMenuModule} from '@angular/material/menu';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import {MatIconModule} from '@angular/material/icon';
import {RecipeTabComponent} from '../tabs/Recipe/Tab/recipe-tab.component';
import {BrewingTabComponent} from '../tabs/brewing/brewing-tab.component';
import {SteamTabComponent} from '../tabs/steam/steam-tab.component';
import {WaterTabComponent} from '../tabs/water/water-tab.component';
import {FlushTabComponent} from '../tabs/flush/flush-tab.component';
import {MachineComponent} from '../machine/machine.component';
import { MachineService } from '../../services/machine.service';
import { BuildInfoService } from '../../services/build-info.service';
import {EspressoMachineState} from '../../models/state';
import {GATEWAY_URL} from '../../services/api.service';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [
    RouterLink,
    MatTabsModule,
    MatSidenavModule,
    MatButtonModule,
    MatMenuModule,
    MatIconModule,
    MatDialogModule,
    RecipeTabComponent,
    BrewingTabComponent,
    SteamTabComponent,
    WaterTabComponent,
    FlushTabComponent,
    MachineComponent,
  ],
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss'],
})
export class HomeComponent {

  selectedTab = signal(0);
  machineService = inject(MachineService);
  buildInfoService = inject(BuildInfoService);
  private readonly dialog = inject(MatDialog);
  lastState: EspressoMachineState | undefined;
  /**
   *
   */
  constructor() {
    effect(() => {
      // Just to trigger change detection when needed

      const state = this.machineService.machineState()?.state;

      if (state != this.lastState) {
        this.lastState = state;
        switch (state) {
          case EspressoMachineState.Espresso:
            this.onTabChange(1);
            break;
          case EspressoMachineState.Steam:
            this.onTabChange(2);
            break;
          case EspressoMachineState.Water:
            this.onTabChange(3);
            break;
          case EspressoMachineState.Flush:
            this.onTabChange(4);
            break;
        }
      }
    });
  }

  onTabChange($event: number) {
    this.selectedTab.set($event);
  }

  onSettingsClick() {
    window.open(`${GATEWAY_URL}/api/v1/plugins/settings.reaplugin/ui`);
  }
}
