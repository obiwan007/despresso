import { Component, computed, effect, inject, signal } from '@angular/core';

import { MatListModule } from '@angular/material/list';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import {MatFormFieldModule} from '@angular/material/form-field';
import {MatSelectModule} from '@angular/material/select';
import {MatCheckboxModule} from '@angular/material/checkbox';
import {MatSidenavModule} from '@angular/material/sidenav';
import {MatButtonModule} from '@angular/material/button';
import { ProfilesService } from '../../services/profiles.service';
import {BreakpointObserver} from '@angular/cdk/layout';
import {Profile} from '../../models/state';

@Component({
  selector: 'app-profiles',
  standalone: true,
    imports: [
    MatListModule,
    MatCardModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatFormFieldModule,
    MatSelectModule,
    MatCheckboxModule,
    MatSidenavModule,
    MatButtonModule
],
  templateUrl: './profiles.component.html',
  styleUrls: ['./profiles.component.scss']
})
export class ProfilesComponent {
    private readonly profilesService = inject(ProfilesService);
    private readonly breakpoint = inject(BreakpointObserver);

  readonly profiles = this.profilesService.profiles;
    readonly selectedId = signal<string | null>(null);
    readonly filtersOpen = signal(false);
    readonly filt = signal({
        defaultOnly: false,
        hiddenMode: 'any' as 'any' | 'hidden' | 'visible',
        author: '',
        beverageType: '',
        type: '',
    });

    readonly filteredProfiles = computed<Profile[] | null>(() => {
        const list = this.profiles();
        if (!list) return null;
        const f = this.filt();
        return list.filter(p => {
            if (f.defaultOnly && !p.isDefault) return false;
            const hidden = !!p.shotHeader?.hidden;
            if (f.hiddenMode === 'hidden' && !hidden) return false;
            if (f.hiddenMode === 'visible' && hidden) return false;
            if (f.author && (p.shotHeader?.author || '') !== f.author) return false;
            if (f.type && (p.shotHeader?.type || '') !== f.type) return false;
            if (f.beverageType && (p.shotHeader?.beverageType || '') !== f.beverageType) return false;
            return true;
        });
    });

  readonly selectedProfile = computed<Profile | null>(() => {
      const list = this.filteredProfiles();
    const id = this.selectedId();
    if (!list || !id) return null;
    return list.find(p => p.id === id) ?? null;
  });

  constructor() {
    effect(() => {
        const list = this.filteredProfiles();
        const current = this.selectedId();
        if (!list || list.length === 0) {
            if (current) this.selectedId.set(null);
            return;
        }
        if (!current || !list.some(p => p.id === current)) {
        this.selectedId.set(list[0].id);
      }
    });

    // Trigger initial load
    void this.profilesService.ensureLoaded();

      // Observe wide screens to keep filters persistent
      this.breakpoint.observe(['(min-width: 900px)']).subscribe(res => {
          this.isWide.set(!!res.matches);
      });
  }

  selectProfile(id: string) {
    this.selectedId.set(id);
  }

    authors = computed(() => {
        const list = this.profiles() ?? [];
        const set = new Set<string>();
        for (const p of list) {
            const a = (p.shotHeader?.author || '').trim();
            if (a) set.add(a);
        }
        return Array.from(set).sort((a, b) => a.localeCompare(b));
    });

    types = computed(() => {
        const list = this.profiles() ?? [];
        const set = new Set<string>();
        for (const p of list) {
            const v = (p.shotHeader?.type || '').trim();
            if (v) set.add(v);
        }
        return Array.from(set).sort((a, b) => a.localeCompare(b));
    });

    beverageTypes = computed(() => {
        const list = this.profiles() ?? [];
        const set = new Set<string>();
        for (const p of list) {
            const v = (p.shotHeader?.beverageType || '').trim();
            if (v) set.add(v);
        }
        return Array.from(set).sort((a, b) => a.localeCompare(b));
    });

    readonly isWide = signal(false);

    setDefaultOnly(checked: boolean) {
        this.filt.update(v => ({...v, defaultOnly: !!checked}));
    }

    setHiddenMode(mode: 'any' | 'hidden' | 'visible') {
        this.filt.update(v => ({...v, hiddenMode: mode}));
    }

    setAuthor(value: string) {
        this.filt.update(v => ({...v, author: value}));
    }

    setType(value: string) {
        this.filt.update(v => ({...v, type: value}));
    }

    setBeverageType(value: string) {
        this.filt.update(v => ({...v, beverageType: value}));
    }

    toggleFilters() {
        if (this.isWide()) return;
        this.filtersOpen.update(v => !v);
    }

    closeFilters() {
        if (this.isWide()) return;
        this.filtersOpen.set(false);
    }
}
