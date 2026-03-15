import {Injectable, signal} from '@angular/core';
import {
  Coffee,
  De1PumpMode,
  De1SensorType,
  De1Transition,
  Profile,
  RecipeEntity,
  Roaster,
} from '../models/state';
import {ApiService} from './api.service';

@Injectable({ providedIn: 'root' })
export class ProfilesService {

  private readonly _recipes = signal<RecipeEntity[] | null>(null);
  private readonly _profiles = signal<Profile[] | null>(null);
  private readonly _roasters = signal<Roaster[] | null>(null);
  private readonly _coffees = signal<Coffee[] | null>(null);
  readonly profiles = this._profiles.asReadonly();
  readonly recipes = this._recipes.asReadonly();
  readonly roasters = this._roasters.asReadonly();
  readonly coffees = this._coffees.asReadonly();
  private readonly pendingRecipeIds = new Set<string>();

  private readonly mockProfiles: Profile[] = [
    {
      __typename: 'Profile',
      id: 'profile-default',
      isDefault: true,
      title: 'Default Espresso',
      shotHeader: {
        __typename: 'De1ShotHeader',
        author: 'Demo',
        beverageType: 'espresso',
        headerV: 1,
        hidden: 0,
        lang: 'en',
        legacyProfileType: 'standard',
        maximumFlow: 3.5,
        minimumPressure: 2.0,
        notes: 'Mock profile for local dev',
        numberOfFrames: 2,
        numberOfPreinfuseFrames: 1,
        tankTemperature: 25,
        targetGroupTemp: 93,
        targetVolume: 36,
        targetVolumeCountStart: 4,
        targetWeight: 36,
        title: 'Default Espresso',
        type: 'espresso',
        version: '1.0',
      },
      shotFrames: [
        {
          __typename: 'De1ShotFrame',
          flag: 0,
          frameLen: 6,
          maxVol: 6,
          maxWeight: 6,
          name: 'Preinfusion',
          pump: De1PumpMode.Flow,
          sensor: De1SensorType.Coffee,
          setVal: 2.0,
          temp: 93,
          transition: De1Transition.Smooth,
          triggerVal: 2,
        },
        {
          __typename: 'De1ShotFrame',
          flag: 0,
          frameLen: 24,
          maxVol: 36,
          maxWeight: 36,
          name: 'Extraction',
          pump: De1PumpMode.Pressure,
          sensor: De1SensorType.Coffee,
          setVal: 9.0,
          temp: 93,
          transition: De1Transition.Fast,
          triggerVal: 9,
        },
      ],
    },
    {
      __typename: 'Profile',
      id: 'profile-classic',
      isDefault: false,
      title: 'Classic 1:2',
      shotHeader: {
        __typename: 'De1ShotHeader',
        author: 'Demo',
        beverageType: 'espresso',
        headerV: 1,
        hidden: 0,
        lang: 'en',
        legacyProfileType: 'classic',
        maximumFlow: 3.2,
        minimumPressure: 2.0,
        notes: 'Classic profile mock',
        numberOfFrames: 2,
        numberOfPreinfuseFrames: 1,
        tankTemperature: 25,
        targetGroupTemp: 94,
        targetVolume: 38,
        targetVolumeCountStart: 5,
        targetWeight: 38,
        title: 'Classic 1:2',
        type: 'espresso',
        version: '1.0',
      },
      shotFrames: [
        {
          __typename: 'De1ShotFrame',
          flag: 0,
          frameLen: 7,
          maxVol: 7,
          maxWeight: 7,
          name: 'Preinfusion',
          pump: De1PumpMode.Flow,
          sensor: De1SensorType.Coffee,
          setVal: 2.2,
          temp: 94,
          transition: De1Transition.Smooth,
          triggerVal: 2,
        },
        {
          __typename: 'De1ShotFrame',
          flag: 0,
          frameLen: 25,
          maxVol: 38,
          maxWeight: 38,
          name: 'Extraction',
          pump: De1PumpMode.Pressure,
          sensor: De1SensorType.Coffee,
          setVal: 9.2,
          temp: 94,
          transition: De1Transition.Fast,
          triggerVal: 9,
        },
      ],
    },
  ];

  private readonly mockRoasters: Roaster[] = [
    {
      __typename: 'Roaster',
      address: '123 Roast St, Portland, OR',
      description: 'Light to medium roasts with high clarity.',
      homepage: 'https://example-roaster-a.com',
      id: '1',
      imageURL: '/assets/roasters/roaster-a.png',
      name: 'Aurora Roasters',
    },
    {
      __typename: 'Roaster',
      address: '456 Origin Ave, Seattle, WA',
      description: 'Chocolate-forward espresso blends.',
      homepage: 'https://example-roaster-b.com',
      id: '2',
      imageURL: '/assets/roasters/roaster-b.png',
      name: 'Beacon Coffee',
    },
  ];

  private readonly mockCoffees: Coffee[] = [
    {
      __typename: 'Coffee',
      acidRating: 7,
      cropyear: '2025',
      description: 'Citrus, stone fruit, floral finish.',
      elevation: 1800,
      farm: 'Finca El Sol',
      grinderDoseWeight: 18.5,
      grinderSettings: 12.2,
      id: '1',
      imageURL: '/assets/coffees/coffee-1.png',
      intensityRating: 6,
      isShot: true,
      name: 'Ethiopia Guji',
      origin: 'Ethiopia',
      price: '$18.00',
      process: 'Washed',
      region: 'Guji',
      roastDate: '2026-02-01',
      roastLevel: 3,
      roasterId: '1',
      taste: 'Citrus, peach, jasmine',
      type: 'Single Origin',
    },
    {
      __typename: 'Coffee',
      acidRating: 4,
      cropyear: '2025',
      description: 'Chocolate, caramel, low acidity.',
      elevation: 1400,
      farm: 'Santa Lucia',
      grinderDoseWeight: 19,
      grinderSettings: 9.5,
      id: '2',
      imageURL: '/assets/coffees/coffee-2.png',
      intensityRating: 8,
      isShot: true,
      name: 'Colombia Huila',
      origin: 'Colombia',
      price: '$16.50',
      process: 'Natural',
      region: 'Huila',
      roastDate: '2026-02-03',
      roastLevel: 4,
      roasterId: '2',
      taste: 'Cocoa, caramel, hazelnut',
      type: 'Single Origin',
    },
  ];

  private readonly mockRecipes: RecipeEntity[] = [
    {
      __typename: 'RecipeEntity',
      adjustedPressure: 9,
      adjustedTemp: 93,
      adjustedWeight: 36,
      coffeeId: '1',
      description: 'Balanced 1:2 espresso',
      disableStopOnWeight: false,
      flowSteam: 2.5,
      grinderDoseWeight: 18.5,
      grinderModel: 'Niche Zero',
      grinderSettings: 12.0,
      id: '1',
      isDeleted: false,
      isFavorite: true,
      isShot: true,
      name: 'Classic 1:2',
      profileId: 'profile-default',
      ratio1: 1,
      ratio2: 2,
      tempSteam: 135,
      tempWater: 90,
      timeSteam: 20,
      timeWater: 15,
      useSteam: true,
      useWater: false,
      weightMilk: 150,
      weightWater: 0,
    },
    {
      __typename: 'RecipeEntity',
      adjustedPressure: 8.5,
      adjustedTemp: 94,
      adjustedWeight: 38,
      coffeeId: '2',
      description: 'Longer ratio, sweeter finish',
      disableStopOnWeight: false,
      flowSteam: 2.8,
      grinderDoseWeight: 19.0,
      grinderModel: 'Eureka Mignon',
      grinderSettings: 9.0,
      id: '2',
      isDeleted: false,
      isFavorite: false,
      isShot: true,
      name: 'Sweet 1:2.2',
      profileId: 'profile-classic',
      ratio1: 1,
      ratio2: 2.2,
      tempSteam: 135,
      tempWater: 92,
      timeSteam: 18,
      timeWater: 14,
      useSteam: true,
      useWater: false,
      weightMilk: 120,
      weightWater: 0,
    },
  ];

  constructor(private readonly apiService: ApiService) {
    this.fetchProfiles();
    this.fetchRecipes();
    this.fetchRoasters();
    this.fetchCoffees();
  }

  async fetchProfiles(): Promise<Profile[]> {
    try {
      const ids = await this.apiService.getAllProfileIds();
      if (ids.length === 0) {
        this._profiles.set([]);
        return [];
      }
      const list = await this.apiService.getProfiles(ids);
      const sorted = [...list].sort((a, b) => a.title.localeCompare(b.title));
      this._profiles.set(sorted);
      return sorted;
    } catch (error) {
      console.error('Failed to load profiles, using mock data.', error);
      const list = [...this.mockProfiles].sort((a, b) => a.title.localeCompare(b.title));
      this._profiles.set(list);
      return list;
    }
  }

  async fetchRecipes(): Promise<RecipeEntity[]> {
    try {
      const ids = await this.apiService.getAllRecipeIds();
      if (ids.length === 0) {
        this._recipes.set([]);
        return [];
      }
      const list = await this.apiService.getRecipes(ids);
      const sorted = [...list].sort((a, b) => a.name.localeCompare(b.name));
      this._recipes.set(sorted);
      return sorted;
    } catch (error) {
      console.error('Failed to load recipes, using mock data.', error);
      const list = [...this.mockRecipes].sort((a, b) => a.name.localeCompare(b.name));
      this._recipes.set(list);
      return list;
    }
  }

  async fetchRoasters(): Promise<Roaster[]> {
    try {
      const ids = await this.apiService.getAllRoasterIds();
      if (ids.length === 0) {
        this._roasters.set([]);
        return [];
      }
      const list = await this.apiService.getRoasters(ids);
      const sorted = [...list].sort((a, b) => a.name.localeCompare(b.name));
      this._roasters.set(sorted);
      return sorted;
    } catch (error) {
      console.error('Failed to load roasters, using mock data.', error);
      const list = [...this.mockRoasters].sort((a, b) => a.name.localeCompare(b.name));
      this._roasters.set(list);
      return list;
    }
  }

  async fetchCoffees(): Promise<Coffee[]> {
    try {
      const ids = await this.apiService.getAllCoffeeIds();
      if (ids.length === 0) {
        this._coffees.set([]);
        return [];
      }
      const list = await this.apiService.getCoffees(ids);
      const sorted = [...list].sort((a, b) => a.name.localeCompare(b.name));
      this._coffees.set(sorted);
      return sorted;
    } catch (error) {
      console.error('Failed to load coffees, using mock data.', error);
      const list = [...this.mockCoffees].sort((a, b) => a.name.localeCompare(b.name));
      this._coffees.set(list);
      return list;
    }
  }

  async ensureLoaded(): Promise<Profile[]> {
    const existing = this._profiles();
    if (existing) return existing;
    return this.fetchProfiles();
  }

  getProfileById(id: string): Profile | undefined {
    return this.profiles()?.find((p) => p.id === id);
  }

  getCoffeeById(id: string | null | undefined): Coffee | undefined {
    if (!id) return undefined;
    return this.coffees()?.find((c) => c.id === id);
  }

  getRoasterById(id: string | null | undefined): Roaster | undefined {
    if (!id) return undefined;
    return this.roasters()?.find((r) => r.id === id);
  }
  getRecipeById(id: string | null | undefined): RecipeEntity | undefined {
    if (!id) return undefined;
    const existing = this.recipes()?.find((r) => r.id === id);
    if (existing) return existing;
    return undefined;
  }

  async updateRecipe(id: string, recipe: RecipeEntity): Promise<RecipeEntity | null> {
    const current = this._recipes() ?? [...this.mockRecipes];
    const updated: RecipeEntity = {...recipe, id, __typename: 'RecipeEntity'};
    const exists = current.some((r) => r.id === id);
    const next = exists
      ? current.map((r) => (r.id === id ? updated : r))
      : [...current, updated];
    this._recipes.set(next);
    return updated;
  }

  async createRecipe(recipe: RecipeEntity): Promise<RecipeEntity | null> {
    const current = this._recipes() ?? [...this.mockRecipes];
    const nextId = new Date().getTime().toString(); // Simple unique ID generation
    const created: RecipeEntity = {...recipe, id: nextId, __typename: 'RecipeEntity'};
    this._recipes.set([...current, created]);
    return created;
  }

  async deleteRecipe(recipe: RecipeEntity): Promise<void> {
    const current = this._recipes() ?? [...this.mockRecipes];
    this._recipes.set(current.filter((r) => r.id !== recipe.id));
  }

  async updateCoffee(id: string, coffee: Coffee): Promise<Coffee | null> {
    const current = this._coffees() ?? [...this.mockCoffees];
    const updated: Coffee = {...coffee, id, __typename: 'Coffee'};
    const exists = current.some((c) => c.id === id);
    const next = exists
      ? current.map((c) => (c.id === id ? updated : c))
      : [...current, updated];
    this._coffees.set(next);
    return updated;
  }

  async createCoffee(coffee: Coffee): Promise<Coffee | null> {
    const current = this._coffees() ?? [...this.mockCoffees];
    const nextId = new Date().getTime().toString(); // Simple unique ID generation
    const created: Coffee = {...coffee, id: nextId, __typename: 'Coffee'};
    this._coffees.set([...current, created]);
    return created;
  }

  async deleteCoffee(coffee: Coffee): Promise<void> {
    const current = this._coffees() ?? [...this.mockCoffees];
    this._coffees.set(current.filter((c) => c.id !== coffee.id));
  }

  async updateRoaster(id: string, roaster: Roaster): Promise<Roaster | null> {
    const current = this._roasters() ?? [...this.mockRoasters];
    const updated: Roaster = {...roaster, id, __typename: 'Roaster'};
    const exists = current.some((r) => r.id === id);
    const next = exists
      ? current.map((r) => (r.id === id ? updated : r))
      : [...current, updated];
    this._roasters.set(next);
    return updated;
  }

  async createRoaster(roaster: Roaster): Promise<Roaster | null> {
    const current = this._roasters() ?? [...this.mockRoasters];
    const nextId = new Date().getTime().toString(); // Simple unique ID generation
    const created: Roaster = {...roaster, id: nextId, __typename: 'Roaster'};
    this._roasters.set([...current, created]);
    return created;
  }

  async deleteRoaster(roaster: Roaster): Promise<void> {
    const current = this._roasters() ?? [...this.mockRoasters];
    this._roasters.set(current.filter((r) => r.id !== roaster.id));
  }
}
