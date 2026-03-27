import { Injectable } from '@angular/core';

export type Theme = 'light' | 'dark';
export type ThemeMode = Theme | 'system';

@Injectable({ providedIn: 'root' })
export class ThemeService {
  private readonly storageModeKey = 'app-theme-mode';
  private readonly legacyStorageKey = 'app-theme';
  private readonly themes: Record<Theme, string> = {
    light: 'themes/indigo-pink.css',
    dark: 'themes/pink-bluegrey.css',
  };
  private media: MediaQueryList | null = null;

  constructor() {
    if (typeof window !== 'undefined' && 'matchMedia' in window) {
      this.media = window.matchMedia('(prefers-color-scheme: dark)');
      // Auto-apply on system change when in system mode
      this.media.addEventListener?.('change', () => {
        if (this.getMode() === 'system') {
          this.applyThemeForMode('system');
        }
      });
    }
    // Initial apply from stored/system preference
    this.applyThemeForMode(this.getMode());
  }

  getMode(): ThemeMode {
    const stored = (localStorage.getItem(this.storageModeKey) as ThemeMode | null);
    if (stored === 'light' || stored === 'dark' || stored === 'system') return stored;
    // Migrate legacy storage if present
    const legacy = (localStorage.getItem(this.legacyStorageKey) as Theme | null);
    if (legacy === 'light' || legacy === 'dark') {
      localStorage.setItem(this.storageModeKey, legacy);
      return legacy;
    }
    return 'dark';
  }

  setMode(mode: ThemeMode): void {
    localStorage.setItem(this.storageModeKey, mode);
    this.applyThemeForMode(mode);
  }

  applyThemeForMode(mode: ThemeMode): void {
    const theme: Theme = mode === 'system' ? (this.prefersDark() ? 'dark' : 'light') : mode;
    this.apply(theme);
  }

  toggle(): ThemeMode {
    // Toggle only between light/dark; keep system if currently system -> dark
    const mode = this.getMode();
    const next: ThemeMode = mode === 'light' ? 'dark' : (mode === 'dark' ? 'light' : 'dark');
    this.setMode(next);
    return next;
  }

  current(): Theme {
    // Derive current applied theme by link href
    const link = document.getElementById('app-theme') as HTMLLinkElement | null;
    if (link?.href?.includes('pink-bluegrey')) return 'dark';
    return 'light';
  }

  private prefersDark(): boolean {
    return !!this.media?.matches;
  }

  private apply(theme: Theme): void {
      let link = document.getElementById('app-theme') as HTMLLinkElement | null;
      if (!link) {
          link = document.createElement('link');
          link.id = 'app-theme';
          link.rel = 'stylesheet';
          document.head.appendChild(link);
      }
      link.href = this.themes[theme];
    // dataset is an index signature in TS; use bracket access
    (document.documentElement.dataset as any)['theme'] = theme;
  }
}
