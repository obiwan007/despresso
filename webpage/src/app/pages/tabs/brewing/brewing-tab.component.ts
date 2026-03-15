import {Component, computed, effect, inject, makeEnvironmentProviders, signal} from '@angular/core';

import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { DescribeShotComponent } from '../../../components/describe-shot/describe-shot.component';
import {MachineService} from '../../../services/machine.service';
import {CommonModule} from '@angular/common';
import {ShotService} from '../../../services/shot.service';
import * as Plotly from 'plotly.js-dist-min';
import {PlotlyModule} from 'angular-plotly.js';
import {ProfilesService} from '../../../services/profiles.service';
import {range} from 'rxjs';
import {SettingsService} from '../../../services/settings.service';
import {RecipeEntity} from '../../../models/state';

const framesPerSecond = 20;

PlotlyModule.forRoot(Plotly);
console.log((Plotly as any).Templates?.plotly_dark);

@Component({
  selector: 'app-brewing-tab',
  standalone: true,
  imports: [MatCardModule, CommonModule, PlotlyModule, MatButtonModule, MatDialogModule],
  templateUrl: './brewing-tab.component.html',
  styleUrls: ['./brewing-tab.component.scss'],
})
export class BrewingTabComponent {
  machineService = inject(MachineService);
  profileService = inject(ProfilesService);
  private readonly dialog = inject(MatDialog);
  readonly shotService = inject(ShotService);

  private readonly settingsService = inject(SettingsService);
  settings = this.settingsService.settings;
  selectedId = signal<string | null>(null);

  profilesService = inject(ProfilesService);
  shot = this.machineService.shotState;
  wasInShot: boolean = false;

  shotSamples = this.machineService.shotSamples;
  lastShot = this.shotService.lastShot;

  recipes = this.profilesService.recipes;

  readonly selectedRecipe = computed<RecipeEntity | null>(() => {
    const list = this.recipes();
    const id = this.selectedId();
    if (!list || !id) return null;
    return list.find((p) => p.id === id) ?? null;
  });

  darkLayout = computed(() => ({
    paper_bgcolor: '#121212',
    plot_bgcolor: '#121212',
    font: {
      color: '#e0e0e0',
    },
    xaxis: {
      gridcolor: '#333',
      showline: true,
      linecolor: 'white',
    },
    yaxis: {
      showline: true,
      linecolor: 'white',
      gridcolor: '#333',
      zerolinecolor: '#444',
    },
    yaxis2: {
      showline: true,
      linecolor: 'white',
      gridcolor: '#333',
      zerolinecolor: '#444',
      color: 'white',
      range: [0, (this.selectedRecipe()?.adjustedWeight ?? 100) + 2],
    },
    yaxis3: {
      showline: true,
      linecolor: 'white',
      gridcolor: '#333',
      zerolinecolor: '#444',
      range: [85, 95],
    },
    legend: {
      bgcolor: '#121212',
    },
  }));

  public graph = computed(() => ({
    config: {
      // responsive: true,
      displayModeBar: false,
      // displaylogo: false,
    },
    layout: {
      template: 'plotly_dark',
      ...this.darkLayout(),
      grid: {
        rows: 3,
        columns: 1,
        pattern: 'coupled',
      },
      autosize: true,
      xaxis3: {
        visible: true,
        anchor: 'y3',
        gridcolor: '#333',
        color: 'white',
        showline: true,
        linecolor: 'white',
      },

      // MITTE
      xaxis2: {
        visible: false,
        anchor: 'y3',
        gridcolor: '#333',
        color: 'white',
      },

      xaxis: {
        visible: false,
        anchor: 'y3',
        gridcolor: '#333',
        color: 'white',
      },
    },
  }));

  // maxX = signal(0);

  maxX = computed(() => {
    if (this.machineService.isInShot() === false) {
      return this.calcMaxX();
    } else {
      return this.machineService.timer();
    }
    // const s = this.machineService.isInShot() ? this.shotSamples() : this.lastShot()?.shotstates;
    // let pt = s?.length ? s[s.length - 1].pourTime : 5;
    // pt -= 0.5;
    // // pt = Math.round(pt / 5) * 5
    // const max = this.machineService.isInShot() ? pt : s?.length ? s[s.length - 1].pourTime : 0;
    // return max;
  });

  layout = computed(() => {
    const range = [0, this.maxX()];
    const baseLayout = {
      ...this.graph().layout,
      xaxis: {
        ...this.graph().layout.xaxis,
        range,
      },
      xaxis2: {
        ...this.graph().layout.xaxis2,
        range,
      },
      xaxis3: {
        ...this.graph().layout.xaxis3,
        range,
      },
      shapes: this.markers().map((m) => ({
        type: 'line',
        xref: 'x',
        yref: 'paper',
        x0: m.x,
        x1: m.x,
        y0: 0,
        y1: 1,
        line: {
          color: '#999',
          width: 1,
          dash: 'dot',
        },
      })),
      annotations: this.markers().map((m, i) => ({
        x: m.x,
        xref: 'x',
        y: 1,
        yref: 'paper',
        text: m.label,
        showarrow: false,
        yanchor: i % 2 === 0 ? 'top' : 'bottom',
        align: 'center',
        font: {
          size: 12,
          color: '#aaa',
        },
      })),
    };
    return baseLayout;
  });

  shotFrames = computed(() => {
    return this.profilesService.getProfileById(this.lastShot()?.profileId ?? '')?.shotFrames ?? [];
  });

  markers = computed(() => {
    const frames = this.shotFrames() ?? [];
    const s = this.machineService.isInShot() ? this.shotSamples() : this.lastShot()?.shotstates;
    const l =  (
      s
        ?.filter(
          (ss, i, arr) =>
            ss.frameNumber > 0 && (i === 0 || ss.frameNumber !== arr[i - 1].frameNumber && frames[ss.frameNumber]?.name!== undefined),
        )
        .map((ss) => ({
          x: ss.pourTime,
          label: frames[ss.frameNumber]?.name ?? '',
        })) ?? []
    );
    return l;
  });

  d1 = computed(() => {
    const frames = this.shotFrames() ?? [];
    const s = this.machineService.isInShot() ? this.shotSamples() : this.lastShot()?.shotstates;
    const weightY = s?.map((sh) => sh.weight ?? 0) ?? [];
    const groupPressureY = s?.map((sh) => sh.groupPressure ?? 0) ?? [];
    const groupPressureGoal = s?.map((sh) => sh.setGroupPressure ?? 0) ?? [];
    const startTime = s?.length ? s[0].sampleTimeCorrected : 0;
    const x = s?.map((sh) => sh.pourTime) ?? [];
    const subsStates = s
      ?.filter((ss) => ss.frameNumber > 0)
      .map((ss, i, arr) =>
        i === 0 || ss.frameNumber !== arr[i - 1].frameNumber ? frames[ss.frameNumber]?.name : null,
      );
    return [
      {
        x,
        y: groupPressureY,
        type: 'scattergl',
        mode: 'lines',
        name: 'Group Pressure',
        marker: { color: 'green' },
        xaxis: 'x',
        yaxis: 'y',
        hovertemplate: '%{y} bar, %{x} s',
        fill: 'tozeroy',
        line: {
          shape: 'spline',
          smoothing: 1.3,
        },
        fillcolor: 'rgba(0,128,0,0.2)',
      },
      {
        x,
        y: groupPressureGoal,
        type: 'scattergl',
        mode: 'lines',
        name: 'Group Pressure Goal',
        line: {
          dash: 'dash',
        },
        marker: { color: 'darkgreen' },
        xaxis: 'x',
        yaxis: 'y',
        hovertemplate: '%{y} bar, %{x} s',
      },

      {
        x,
        y: s?.map((sh) => sh.groupFlow ?? 0) ?? [],
        type: 'scattergl',
        mode: 'lines',
        name: 'Group Flow',
        marker: { color: 'blue' },
        xaxis: 'x',
        yaxis: 'y',
        hovertemplate: '%{y} ml/s, %{x} s',
        fill: 'tozeroy',
        line: {
          shape: 'spline',
          smoothing: 1.3,
        },
        fillcolor: 'rgba(0,0,128,0.2)',
      },
      {
        x,
        y: s?.map((sh) => sh.setGroupFlow ?? 0) ?? [],
        type: 'scattergl',
        mode: 'lines',
        name: 'Group Flow Goal',
        line: {
          dash: 'dash',
        },
        marker: { color: 'darkgrey' },
        xaxis: 'x',
        yaxis: 'y',

        hovertemplate: '%{y} ml/s, %{x} s',
      },

      {
        x,
        y: s?.map((sh) => sh.setHeadTemp) ?? [],
        type: 'scattergl',
        mode: 'lines',
        name: 'Head Temp Goal',
        marker: { color: 'red' },
        xaxis: 'x3',
        yaxis: 'y3',
        line: {
          dash: 'dash',
        },
        hovertemplate: '%{y} °C, %{x} s',
      },
      {
        x,
        y: s?.map((sh) => sh.headTemp) ?? [],
        type: 'scattergl',
        mode: 'lines',
        name: 'Head Temp',
        marker: { color: 'red' },
        xaxis: 'x3',
        yaxis: 'y3',
        hovertemplate: '%{y} °C, %{x} s',
        fill: 'tonexty',
        fillcolor: 'rgba(128,00,0,0.25)',
        line: {
          shape: 'spline',
          smoothing: 1.3,
        },
      },
      {
        x,
        y: s?.map((sh) => sh.mixTemp) ?? [],
        type: 'scattergl',
        mode: 'lines',
        name: 'Mix Temp',
        marker: { color: 'orange' },
        xaxis: 'x3',
        yaxis: 'y3',
        hovertemplate: '%{y} °C, %{x} s',
        line: {
          shape: 'spline',
          smoothing: 1.3,
        },
      },

      {
        x,
        y: s?.map((sh) => sh.flowWeight ?? 0) ?? [],
        type: 'scattergl',
        mode: 'lines',
        name: 'Weight Flow',
        hovertemplate: '%{y} g/s, %{x} s',
        marker: {
          color: 'brown',
          size: 3,
        },
        line: {
          shape: 'spline',
          smoothing: 1.3,
        },
        xaxis: 'x',
        yaxis: 'y',
      },
      {
        x,
        y: weightY,
        type: 'scattergl',
        mode: 'lines+text',
        marker: {
          color: 'white',
          size: 3,
        },
        line: {
          shape: 'spline',
          smoothing: 1.3,
          color: 'grey',
          width: 1,
        },
        name: 'Weight',
        xaxis: 'x2',
        yaxis: 'y2',
        hovertemplate: '%{y} g, %{x} s',
        fill: 'tozeroy',
        fillcolor: 'rgba(128,128,128,0.25)',
      },
    ];
  });

  intervalTimer?: number;
  shotStarted: boolean = true;
  shotTime: number = 0;

  /**
   *
   */
  constructor() {
    effect(() => {
      const s = this.settings();
      const current = this.selectedId();
      const list = this.recipes();
      if (!s || !list || current) return;
      const id = s.selectedRecipe ?? null;
      if (!id) return;
      if (list.some((r) => r.id === id)) {
        this.selectedId.set(id);
      }
    });

    // this.intervalTimer = setInterval(() => {
    //   if (this.machineService.isInShot()) {
    //     if (this.shotStarted === false) {
    //       this.shotStarted = true;
    //       this.maxX.set(this.maxXShot());
    //     }
    //     const t = new Date().getTime() / 1000;
    //     let elapsed = 0.1;
    //     if (this.shotTime > 0) {
    //       elapsed = t - this.shotTime;
    //     }

    //     this.shotTime = t;
    //     this.maxX.update((x) => x + elapsed);
    //   } else {
    //     if (this.shotStarted) {
    //       this.maxX.set(this.calcMaxX());
    //       this.shotStarted = false;
    //     }
    //   }
    // }, 1000 / framesPerSecond);
  }

  calcMaxX() {
    const s = this.machineService.isInShot() ? this.shotSamples() : this.lastShot()?.shotstates;
    let pt = s?.length ? s[s.length - 1].pourTime : 5;
    pt += 5;
    // pt = Math.round(pt / 5) * 5
    const max = this.machineService.isInShot() ? pt : s?.length ? s[s.length - 1].pourTime : 0;
    return max;
  }

  openDescribeShot(): void {
    const lastShot = this.shotService.lastShot();
    if (!lastShot) return;
    this.dialog.open(DescribeShotComponent, {
      width: '640px',
      autoFocus: true,
      restoreFocus: true,
      panelClass: 'describe-shot-dialog',
      data: { shot: lastShot },
    });
  }

  async sendShotToVisualizer(id: string): Promise<void> {
  // await this.shotService.sendShotToVisualizer(id);
  }
}
