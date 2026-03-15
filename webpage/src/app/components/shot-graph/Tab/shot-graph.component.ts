import {Component, computed, effect, inject, input, makeEnvironmentProviders, signal} from '@angular/core';

import { MatCardModule } from '@angular/material/card';
import {MachineService} from '../../../services/machine.service';
import {CommonModule} from '@angular/common';
import {ShotService} from '../../../services/shot.service';
import * as Plotly from 'plotly.js-dist-min';
import {PlotlyModule} from 'angular-plotly.js';
import {ProfilesService} from '../../../services/profiles.service';

PlotlyModule.forRoot(Plotly);
console.log((Plotly as any).Templates?.plotly_dark);

@Component({
  selector: 'app-shot-graph',
  standalone: true,
  imports: [MatCardModule, CommonModule, PlotlyModule],
  templateUrl: './shot-graph.component.html',
  styleUrls: ['./shot-graph.component.scss'],
})
export class ShotGraphComponent {
  machineService = inject(MachineService);
  shotService = inject(ShotService);
  profilesService = inject(ProfilesService);

  shotId = input<string>();
  height=input<string>('');


  darkLayout = {
    paper_bgcolor: '#121212',
    plot_bgcolor: '#121212',
    font: {
      color: '#e0e0e0'
    },
    xaxis: {
      gridcolor: '#333',
      zerolinecolor: '#444',       
    },
    yaxis: {
      gridcolor: '#333',
      zerolinecolor: '#444',
      showline: true,
      linecolor: 'white',
      title: {
        text: 'Pressure [bar]',
        standoff: 20
      }     
    },
    yaxis2: {
      gridcolor: '#333',
      zerolinecolor: '#444',
      showline: true,
      linecolor: 'white',
      title: {
        text: 'Weight [g]',
        standoff: 20
      }     
    },
    yaxis3: {
      gridcolor: '#333',
      zerolinecolor: '#444',
      showline: true,
      linecolor: 'white',
      title: {
        text: 'Temperature [°C]',
        standoff: 20
      }     
    },
    legend: {
      bgcolor: '#121212'
    }
  };


  public graph = {    
    config: {
      // responsive: true,
      displayModeBar: false,
      // displaylogo: false,
    },
    layout: {
      template: "plotly_dark",
      ...this.darkLayout,
      grid: {
        rows: 3,
        columns: 1,
        pattern: 'coupled'
      },
      autosize: true,      
      xaxis3: {
        visible: true,
        anchor: 'y3',
        gridcolor: '#333',
        color: 'white',
        showline: true,
        linecolor: 'white',
        title: {
          text: 'Time [s]',
        }       
      },

      // MITTE
      xaxis2: {
        visible: false,
        anchor: 'y3',
        gridcolor: '#333',
        color: 'white'
      },

      xaxis: {
        visible: false,
        anchor: 'y3',
        gridcolor: '#333',
        color: 'white'
      },
    }
  };

  layout = computed(() => {
    const baseLayout = {
      ...this.graph.layout,

      shapes: this.markers().map(m => ({
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
          dash: 'dot'
        }
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
          color: '#aaa'
    }
      }))
    };
    return baseLayout;

  });

  shotFrames = computed(() => {
    return this.profilesService.getProfileById(this.shot()?.profileId ?? '')?.shotFrames ?? [];
  });

  markers = computed(() => {
    const frames = this.shotFrames() ?? [];
    const s = this.shot()?.shotstates;
    return s
      ?.filter((ss, i, arr) =>
        ss.frameNumber > 0 &&
        (i === 0 || ss.frameNumber !== arr[i - 1].frameNumber && frames[ss.frameNumber]?.name!== undefined)
      )
      .map(ss => ({
        x: ss.pourTime*100,
        label: frames[ss.frameNumber]?.name ?? ''
      })) ?? [];
  });

  shot=computed(() => {
    return this.shotService.shots()?.find(s => s.id === this.shotId());  
  });

  d1 = computed(() => {
    const s = this.shot()?.shotstates ?? [];    
    const weightY = s?.map(sh => sh.weight ?? 0) ?? [];
    const groupPressureY = s?.map(sh => sh.groupPressure ?? 0) ?? [];
    const groupPressureGoal = s?.map(sh => sh.setGroupPressure ?? 0) ?? [];
    const startTime = s?.length ? s[0].sampleTimeCorrected : 0;
    const x = s?.map((sh) => sh.pourTime) ?? [];
    const subsStates = s
      ?.filter(ss => ss.frameNumber > 0)
      .map((ss, i, arr) =>
        i === 0 || ss.frameNumber !== arr[i - 1].frameNumber  
          ? frames[ss.frameNumber]?.name
          : null
      );
    return [      
      {
        x, y: groupPressureY, type: 'scatter', mode: 'lines+points', name: 'Group Pressure', marker: {color: 'green'}, xaxis: 'x', yaxis: 'y',
        hovertemplate: '%{y} bar, %{x} s',
        fill: 'tozeroy',
        fillcolor: 'rgba(0,128,0,0.2)',
      },
      {
        x, y: groupPressureGoal, type: 'scatter', mode: 'lines+points', name: 'Group Pressure Goal', line: {
          dash: 'dash'
        }, marker: {color: 'darkgreen'}, xaxis: 'x', yaxis: 'y',
        hovertemplate: '%{y} bar, %{x} s',
      },

      {
        x, y: s?.map(sh => sh.groupFlow ?? 0) ?? [], type: 'scatter', mode: 'lines+points', name: 'Group Flow', marker: {color: 'blue'}, xaxis: 'x', yaxis: 'y',
        hovertemplate: '%{y} ml/s, %{x} s',
        fill: 'tozeroy',
        fillcolor: 'rgba(0,0,128,0.2)',
      },
      {
        x, y: s?.map(sh => sh.setGroupFlow ?? 0) ?? [], type: 'scatter', mode: 'lines+points', name: 'Group Flow Goal', line: {
          dash: 'dash'
        }, marker: {color: 'darkgrey'}, xaxis: 'x', yaxis: 'y',
        hovertemplate: '%{y} ml/s, %{x} s',
      },

      {
        x, y: s?.map(sh => sh.setHeadTemp) ?? [], type: 'scatter', mode: 'lines+points', name: 'Head Temp Goal', marker: {color: 'red'}, xaxis: 'x3', yaxis: 'y3',
        line: {
          dash: 'dash'
        },
        hovertemplate: '%{y} °C, %{x} s',
      },
      {
        x, y: s?.map(sh => sh.headTemp) ?? [], type: 'scatter', mode: 'lines+points', name: 'Head Temp', marker: {color: 'red'}, xaxis: 'x3', yaxis: 'y3',
        hovertemplate: '%{y} °C, %{x} s',
        fill: 'tonexty',
        fillcolor: 'rgba(128,00,0,0.25)',
      },
      {
        x, y: s?.map(sh => sh.mixTemp) ?? [], type: 'scatter', mode: 'lines+points', name: 'Mix Temp', marker: {color: 'orange'}, xaxis: 'x3', yaxis: 'y3',
        hovertemplate: '%{y} °C, %{x} s',
      },


      {
        x, y: s?.map(sh => sh.flowWeight ?? 0) ?? [], type: 'scatter', mode: 'lines+points', name: 'Weight Flow',
        hovertemplate: '%{y} g/s, %{x} s',
        marker: {color: 'brown'}, xaxis: 'x', yaxis: 'y'
      },
      {
        x, y: weightY, type: 'scatter', mode: 'lines+points+text',
        name: 'Weight', marker: {color: 'gray'}, xaxis: 'x2', yaxis: 'y2',
        hovertemplate: '%{y} g, %{x} s',
        fill: 'tozeroy',
        fillcolor: 'rgba(128,128,128,0.25)',
      },

    ];

  });



  /**
   *
   */
  constructor() {
  }
}
