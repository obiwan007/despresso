import { Component, computed, effect, inject, signal } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { RecipeEditComponent } from '../Edit/recipe-edit.component';

import { MatCardModule } from '@angular/material/card';
import { ProfilesService } from '../../../../services/profiles.service';
import { CommonModule } from '@angular/common';
import { SettingsService } from '../../../../services/settings.service';
import { MatListModule } from '@angular/material/list';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatSidenavModule } from '@angular/material/sidenav';
import {MatButtonModule} from '@angular/material/button';
import { firstValueFrom } from 'rxjs';
import { MatMenuModule } from '@angular/material/menu';
import { CoffeeEditComponent } from '../../Coffee/Edit/coffee-edit.component';
import {Coffee, RecipeEntity} from '../../../../models/state';

@Component({
  selector: 'app-recipe-tab',
  standalone: true,
  imports: [
    MatCardModule,
    CommonModule,
    MatListModule,
    MatCardModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatCheckboxModule,
    MatSidenavModule,
    MatButtonModule,
    MatMenuModule,
  ],
  templateUrl: './recipe-tab.component.html',
  styleUrls: ['./recipe-tab.component.scss'],
})
export class RecipeTabComponent {
  private readonly profilesService = inject(ProfilesService);
  private readonly settingsService = inject(SettingsService);

  recipes = computed(() => this.profilesService.recipes()?.filter(r => r.isShot === false));
  roasters = this.profilesService.roasters;
  profiles = computed(
    () =>
      this.profilesService
        .profiles()
        ?.filter((p) => p.shotHeader.beverageType !== 'cleaning')
        .sort((a, b) => a.title.localeCompare(b.title)) ?? null,
  );
  coffees = computed(() => this.profilesService.coffees()?.filter(c => c.isShot === false));

  settings = this.settingsService.settings;

  readonly selectedId = signal<string | null>(null);

  readonly selectedRecipe = computed<RecipeEntity | null>(() => {
    const list = this.recipes();
    const id = this.selectedId();
    if (!list || !id) return null;
    return list.find((p) => p.id === id) ?? null;
  });

  private readonly dialog = inject(MatDialog);

  constructor() {
    // Ensure settings are loaded so preselectEffect can run
    this.settingsService.ensureLoaded();
  }

  async selectRecipe(id: string) {
    this.selectedId.set(id);
    const recipe = this.selectedRecipe();
    if (!recipe) return;
    try {
      await this.updateSettings(recipe, recipe.profileId);
    } catch (e) {
      console.error('Failed to persist selectedRecipe to settings', e);
    }
  }

  readonly selectedCoffee = computed<Coffee | null>(() => {
    const list = this.coffees();
    const recipe = this.selectedRecipe();
    const id = recipe?.coffeeId ?? null;
    if (!list || !id) return null;
    return list.find((c) => c.id === id) ?? null;
  });

  async onProfileChange(profileId: string): Promise<void> {
    const recipe = this.selectedRecipe();
    if (!recipe) return;
    try {
      await this.profilesService.updateRecipe(recipe?.id ?? 0, { ...recipe, profileId });
      await this.updateSettings(recipe, profileId);
    } catch (e) {
      // noop: consider surfacing a toast/snackbar in future
      console.error('Failed to update recipe profileId', e);
    }
  }

  private async updateSettings(recipe: RecipeEntity, profileId: string) {
    await this.settingsService.updateSettings({
      selectedRecipe: recipe?.id ?? null,
      currentProfile: profileId,
      targetEspressoWeight: recipe.adjustedWeight,
      targetTempCorrection: recipe.adjustedTemp,
      targetHotWaterWeight: recipe.weightWater,
      targetHotWaterVol: recipe.weightWater,
      // useWater: recipe.useWater,
      shotStopOnWeight: !recipe.disableStopOnWeight,
      steamHeaterOff: !recipe.useSteam,
    });
  }

  async onCoffeeChange(coffeeId: string): Promise<void> {
    if (coffeeId === '') {
      this.onAddCoffee();
      return;
    }
    const recipe = this.selectedRecipe();
    if (!recipe) return;
    try {
      await this.profilesService.updateRecipe(recipe?.id ?? '', {...recipe, coffeeId});
    } catch (e) {
      console.error('Failed to update recipe coffeeId', e);
    }
  }

  async onAdjustedWeightChange(raw: string): Promise<void> {
    const recipe = this.selectedRecipe();
    if (!recipe) return;
    const weight = Number(raw);
    if (!Number.isFinite(weight) || weight < 0) return;
    recipe.grinderDoseWeight = (weight * recipe.ratio1) / recipe.ratio2;
    const updated = {
      ...recipe,
      grinderDoseWeight: recipe.grinderDoseWeight,
      adjustedWeight: weight,
    };
    try {
      await this.profilesService.updateRecipe(recipe.id, updated);
      await this.updateSettings(updated, updated.profileId);
    } catch (e) {
      console.error('Failed to update adjustedWeight', e);
    }
  }

  async onAdjustedBeanWeightChange(raw: string): Promise<void> {
    const recipe = this.selectedRecipe();
    if (!recipe) return;
    const weight = Number(raw);
    if (!Number.isFinite(weight) || weight < 0) return;
    recipe.grinderDoseWeight = weight;
    recipe.adjustedWeight = (recipe.grinderDoseWeight * recipe.ratio2) / recipe.ratio1;
    this.onAdjustedWeightChange(recipe.adjustedWeight.toString());
  }

  async onAdjustedWaterWeightChange(raw: string): Promise<void> {
    const recipe = this.selectedRecipe();
    if (!recipe) return;
    const weight = Number(raw);
    if (!Number.isFinite(weight) || weight < 0) return;
    const updated = { ...recipe, weightWater: weight };
    try {
      await this.profilesService.updateRecipe(recipe.id, updated);
      await this.updateSettings(updated, updated.profileId);
    } catch (e) {
      console.error('Failed to update adjustedWeight', e);
    }
  }

  async onAdjustedMilkWeightChange(raw: string): Promise<void> {
    const recipe = this.selectedRecipe();
    if (!recipe) return;
    const weight = Number(raw);
    if (!Number.isFinite(weight) || weight < 0) return;
    const updated = { ...recipe, weightMilk: weight };
    try {
      await this.profilesService.updateRecipe(recipe.id, updated);
      await this.updateSettings(updated, updated.profileId);
    } catch (e) {
      console.error('Failed to update adjustedWeight', e);
    }
  }

  // Preselect from settings once data is available
  private readonly preselectEffect = effect(() => {
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

  async onAddCoffee() {
    const coffee = structuredClone(this.selectedCoffee());
    if (!coffee) return;
    coffee.id = new Date().getTime().toString(); // Simple unique ID generation
    const ref = this.dialog.open(CoffeeEditComponent, {
      data: { coffee },
      width: 'calc(100% - 20px)',
      minHeight: 'calc(100vh - 120px)',
      autoFocus: true,
    });
    const result = await firstValueFrom(ref.afterClosed());
    if (result) {
      const coffee = await this.profilesService.createCoffee(result);
      this.onCoffeeChange(coffee!.id);
    }
  }

  async onEditCoffee() {
    const coffee = this.selectedCoffee();
    if (!coffee) return;
    const ref = this.dialog.open(CoffeeEditComponent, {
      data: { coffee },
      width: 'calc(100% - 20px)',
      minHeight: 'calc(100vh - 120px)',
      autoFocus: true,
    });
    const result = await firstValueFrom(ref.afterClosed());
    if (result) {
      await this.profilesService.updateCoffee(coffee.id, result);
      await this.updateSettings(result, result.profileId);
    }
  }

  async onDeleteCoffee() {    
    await this.profilesService.deleteCoffee(this.selectedCoffee() as Coffee);
    const list = this.coffees();
    if (list && list?.length > 0) {
      this.onCoffeeChange(list[0].id);
    }    
  }

  async onEditRecipe() {
    const recipe = this.selectedRecipe();
    if (!recipe) return;
    const ref = this.dialog.open(RecipeEditComponent, {
      data: { recipe },
      width: 'calc(100% - 20px)',
      minHeight: 'calc(100vh - 120px)',
      autoFocus: true,
    });
    const result = await firstValueFrom(ref.afterClosed());
    if (result) {
      await this.profilesService.updateRecipe(recipe.id, result);
      await this.updateSettings(result, result.profileId);
    }
  }
  async onAddRecipe() {
    const recipe = structuredClone(this.selectedRecipe());
    if (!recipe) return;
    recipe.id = Date.now().toString(); // Simple unique ID generation
    const ref = this.dialog.open(RecipeEditComponent, {
      data: { recipe },
      width: 'calc(100% - 20px)',
      minHeight: 'calc(100vh - 120px)',
      autoFocus: true,
    });
    const result = await firstValueFrom(ref.afterClosed());
    if (result) {
      const recipe = await this.profilesService.createRecipe(result);
      if (!recipe) return;
      this.selectRecipe(recipe.id);
    }
  }

  async onDeleteRecipe() {
    const id = this.selectedRecipe()?.id ?? 0;
    await this.profilesService.deleteRecipe(this.selectedRecipe() as RecipeEntity);
    const list = this.recipes()
    if (list && list?.length > 0) {
      this.selectRecipe(list[0].id);
    }    
  }
}
