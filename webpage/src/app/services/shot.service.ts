import {inject, Injectable, signal} from '@angular/core';
import {ShotEntity, shotEntityFromShot} from '../models/state';
import {ApiService} from './api.service';

@Injectable({ providedIn: 'root' })
export class ShotService {

  readonly apiService = inject(ApiService);

  readonly shots = signal<ShotEntity[] | null>(null);
  readonly lastShot = signal<ShotEntity | null>(null);

  private readonly mockShots: ShotEntity[] = [
    {
      __typename: 'ShotEntity',
      barrista: 'Alex',
      coffeeId: 'coffee-1',
      date: '2026-02-15T09:12:00.000Z',
      description: 'Bright and citrusy',
      doseWeight: 18.5,
      drinkWeight: 36.0,
      drinker: 'Jamie',
      enjoyment: 8,
      estimatedWeightReachedTime: 28,
      estimatedWeight_b: 0,
      estimatedWeight_m: 1.2,
      estimatedWeight_tEnd: 30,
      estimatedWeight_tStart: 4,
      extractionYield: 19.2,
      grinderName: 'Niche Zero',
      grinderSettings: 12.3,
      id: '101',
      pourTime: 28,
      pourWeight: 36,
      profileId: 'profile-default',
      ratio1: 1,
      ratio2: 2,
      recipeId: '1',
      roastingDate: '2026-02-01',
      shotstates: [
        {
          __typename: 'ShotState',
          flowWeight: 2.5,
          frameName: 'pour',
          frameNumber: 1,
          groupFlow: 2.1,
          groupPressure: 9.0,
          headTemp: 92.5,
          id: 1,
          mixTemp: 90.0,
          pourTime: 5,
          sampleTime: 1,
          sampleTimeCorrected: 1,
          setGroupFlow: 2.0,
          setGroupPressure: 9.0,
          setHeadTemp: 93.0,
          setMixTemp: 90.0,
          steamTemp: 0,
          subState: 'preinfusion',
          weight: 2.5,
        },
      ],
      targetEspressoWeight: 36,
      targetTempCorrection: 0,
      totalDissolvedSolids: 9.1,
      visualizerId: 'vis-101',
    },
    {
      __typename: 'ShotEntity',
      barrista: 'Morgan',
      coffeeId: 'coffee-2',
      date: '2026-02-15T10:05:00.000Z',
      description: 'Chocolate and caramel',
      doseWeight: 19.0,
      drinkWeight: 38.0,
      drinker: 'Riley',
      enjoyment: 9,
      estimatedWeightReachedTime: 30,
      estimatedWeight_b: 0,
      estimatedWeight_m: 1.1,
      estimatedWeight_tEnd: 32,
      estimatedWeight_tStart: 5,
      extractionYield: 20.0,
      grinderName: 'Eureka Mignon',
      grinderSettings: 8.7,
      id: '102',
      pourTime: 30,
      pourWeight: 38,
      profileId: 'profile-classic',
      ratio1: 1,
      ratio2: 2,
      recipeId: '2',
      roastingDate: '2026-02-03',
      shotstates: [
        {
          __typename: 'ShotState',
          flowWeight: 3.0,
          frameName: 'pour',
          frameNumber: 1,
          groupFlow: 2.2,
          groupPressure: 9.2,
          headTemp: 93.0,
          id: 2,
          mixTemp: 90.5,
          pourTime: 6,
          sampleTime: 1,
          sampleTimeCorrected: 1,
          setGroupFlow: 2.1,
          setGroupPressure: 9.2,
          setHeadTemp: 93.5,
          setMixTemp: 90.5,
          steamTemp: 0,
          subState: 'extraction',
          weight: 3.0,
        },
      ],
      targetEspressoWeight: 38,
      targetTempCorrection: 0,
      totalDissolvedSolids: 9.5,
      visualizerId: 'vis-102',
    },
  ];

  /**
   *
   */
  constructor() {
    this.fetchShots();
  }

  async sendShotToVisualizer(id: string): Promise<string> {
    return '';
  }

  async fetchShots(): Promise<ShotEntity[]> {
    const ids = await this.apiService.getAllShotIds();

    const recentIds = ids.slice(-10);
    const shots = await this.apiService.getShots(recentIds);
    // const s = [...this.mockShots].sort((a, b) => a.id.localeCompare(b.id));
    const s = shots.map(shot => shotEntityFromShot(shot));
    this.shots.set(s);
    this.lastShot.set(s.length > 0 ? s[s.length - 1] : null);    
    return s;
  }

  private startShotUpdates(): void {
    console.log('startShotUpdates (mock): updates disabled');
  }

  async updateShot(
    id: string,
    input: ShotEntity,
  ): Promise<ShotEntity | null> {
    const updated = {...input, id} as ShotEntity;

    this.shots.update((list) => {
      if (!list) return list;
      return list.map((s) => (s.id === id ? ({ ...s, ...updated } as ShotEntity) : s));
    });
    if (this.lastShot()?.id === id) {
      this.lastShot.set({ ...(this.lastShot() as ShotEntity), ...updated });
    }
    return updated;
  }
}
