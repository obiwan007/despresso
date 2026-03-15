import {APP_INITIALIZER, ApplicationConfig, importProvidersFrom, provideBrowserGlobalErrorListeners} from '@angular/core';
import { provideRouter } from '@angular/router';

import { routes } from './app.routes';
import {PlotlyModule} from 'angular-plotly.js';
import * as PlotlyJS from 'plotly.js-dist-min';
import {SettingsService} from './services/settings.service';
import {ThemeService} from './services/theme.service';

export const appConfig: ApplicationConfig = {
  providers: [
    importProvidersFrom(PlotlyModule.forRoot(PlotlyJS)),
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes),
    {
      provide: APP_INITIALIZER,
      useFactory: settingsInitializerFactory,
      deps: [SettingsService, ThemeService],
      multi: true,
    },
  ]
};

function settingsInitializerFactory(settings: SettingsService, theme: ThemeService) {
  return async () => {
    try {
      const s = await settings.ensureLoaded();
      if (s?.screenDarkTheme === true) {
        theme.setMode('dark');
      } else if (s?.screenDarkTheme === false) {
        theme.setMode('light');
      }
    } catch {
      // Ignore startup settings failures to avoid blocking app boot
    }
  };
}