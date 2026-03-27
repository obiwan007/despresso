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
      console.error('Failed to load profiles.', error);
      this._profiles.set([]);
      return [];
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
      console.error('Failed to load recipes.', error);
      this._recipes.set([]);
      return [];
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
      console.error('Failed to load roasters.', error);
      this._roasters.set([]);
      return [];
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
      console.error('Failed to load coffees.', error);
      this._coffees.set([]);
      return [];
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
    try {
      const updated = await this.apiService.updateRecipe({...recipe, id, __typename: 'RecipeEntity'});
      if (updated) {
        const current = this._recipes() ?? [];
        const exists = current.some((r) => r.id === updated.id);
        const next = exists
          ? current.map((r) => (r.id === updated.id ? updated : r))
          : [...current, updated];
        this._recipes.set(next);
        return updated;
      }
    } catch (error) {
      console.error('Failed to update recipe via API.', error);
    }
    return null;
  }

  async createRecipe(recipe: RecipeEntity): Promise<RecipeEntity | null> {
    try {
      const created = await this.apiService.createRecipe({...recipe, __typename: 'RecipeEntity'});
      if (created) {
        const current = this._recipes() ?? [];
        this._recipes.set([...current, created]);
        return created;
      }
    } catch (error) {
      console.error('Failed to create recipe via API.', error);
    }
    return null;
  }

  async deleteRecipe(recipe: RecipeEntity): Promise<void> {
    try {
      await this.apiService.deleteRecipes([recipe.id]);
    } catch (error) {
      console.error('Failed to delete recipe via API.', error);
    }
    const current = this._recipes() ?? [];
    this._recipes.set(current.filter((r) => r.id !== recipe.id));
  }

  async updateCoffee(id: string, coffee: Coffee): Promise<Coffee | null> {
    try {
      const updated = await this.apiService.updateCoffee({...coffee, id, __typename: 'Coffee'});
      if (updated) {
        const current = this._coffees() ?? [];
        const exists = current.some((c) => c.id === updated.id);
        const next = exists
          ? current.map((c) => (c.id === updated.id ? updated : c))
          : [...current, updated];
        this._coffees.set(next);
        return updated;
      }
    } catch (error) {
      console.error('Failed to update coffee via API.', error);
    }
    return null;
  }

  async createCoffee(coffee: Coffee): Promise<Coffee | null> {
    try {
      const created = await this.apiService.createCoffee({...coffee, __typename: 'Coffee'});
      if (created) {
        const current = this._coffees() ?? [];
        this._coffees.set([...current, created]);
        return created;
      }
    } catch (error) {
      console.error('Failed to create coffee via API.', error);
    }
    return null;
  }

  async deleteCoffee(coffee: Coffee): Promise<void> {
    try {
      await this.apiService.deleteCoffees([coffee.id]);
    } catch (error) {
      console.error('Failed to delete coffee via API.', error);
    }
    const current = this._coffees() ?? [];
    this._coffees.set(current.filter((c) => c.id !== coffee.id));
  }

  async updateRoaster(id: string, roaster: Roaster): Promise<Roaster | null> {
    try {
      const updated = await this.apiService.updateRoaster({...roaster, id, __typename: 'Roaster'});
      if (updated) {
        const current = this._roasters() ?? [];
        const exists = current.some((r) => r.id === updated.id);
        const next = exists
          ? current.map((r) => (r.id === updated.id ? updated : r))
          : [...current, updated];
        this._roasters.set(next);
        return updated;
      }
    } catch (error) {
      console.error('Failed to update roaster via API.', error);
    }
    return null;
  }

  async createRoaster(roaster: Roaster): Promise<Roaster | null> {
    try {
      const created = await this.apiService.createRoaster({...roaster, __typename: 'Roaster'});
      if (created) {
        const current = this._roasters() ?? [];
        this._roasters.set([...current, created]);
        return created;
      }
    } catch (error) {
      console.error('Failed to create roaster via API.', error);
    }
    return null;
  }

  async deleteRoaster(roaster: Roaster): Promise<void> {
    try {
      await this.apiService.deleteRoasters([roaster.id]);
    } catch (error) {
      console.error('Failed to delete roaster via API.', error);
    }
    const current = this._roasters() ?? [];
    this._roasters.set(current.filter((r) => r.id !== roaster.id));
  }
}
