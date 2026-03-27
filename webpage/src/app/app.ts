import {Component, OnInit, signal, effect, inject, computed} from '@angular/core';
import {ScreensaverComponent} from './components/screen-saver/screensaver.component';
import {Router, NavigationEnd, RouterOutlet, RouterLink} from '@angular/router';
import {MatToolbarModule} from '@angular/material/toolbar';
import {MatButtonModule} from '@angular/material/button';
import {MatIconModule} from '@angular/material/icon';
import {MatButtonToggleModule} from '@angular/material/button-toggle';
import {MatMenuModule} from '@angular/material/menu';
import {ThemeService, ThemeMode} from './services/theme.service';
import {SettingsService} from './services/settings.service';
import {MachineService} from './services/machine.service';
import {ToolbarService} from './services/toolbar.service';
import {EspressoMachineState} from './models/state';

@Component({
  selector: 'app-root',
  imports: [
    RouterOutlet,
    RouterLink,
    MatToolbarModule,
    MatButtonModule,
    MatIconModule,
    MatButtonToggleModule,
    MatMenuModule,
    ScreensaverComponent,
  ],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App implements OnInit {
  settings = inject(SettingsService);
  machine = inject(MachineService);

  protected readonly title = signal('frontend');
  protected readonly mode = signal<ThemeMode>('system');
  protected readonly isHome = signal<boolean>(false);
  protected screensaverTimeout = 60_000; // default 60s
  private screensaverTimer: any = null;
  private wakeupTriggered = false;
  sleepTimestamp: number = 0;
  constructor(
    private readonly theme: ThemeService,
    private readonly router: Router,
  ) { }
  toolbar = inject(ToolbarService);

  showScreensaver = computed(() => {
    console.log('Screensaver', this.settings.settings());
    const sleeping = this.machine.isSleeping();
    if (this.settings.settings()?.tabletSleepWhenMachineOff) {
      this.wakeupTriggered = sleeping === false;
      if (sleeping) this.sleepTimestamp = Date.now();
      return sleeping;
    }
    return false;
  });

  ngOnInit(): void {
    this.settings.ensureLoaded();

    const initial = this.theme.getMode();
    this.mode.set(initial);
    this.theme.applyThemeForMode(initial);

    // Track current route to hide toolbar on home
    this.router.events.subscribe((evt) => {
      if (evt instanceof NavigationEnd) {
        const url = evt.urlAfterRedirects || evt.url;
        this.isHome.set(url === '/' || url === '' || (url.startsWith('/#') && url.length <= 2));
      }
    });

    // Screensaver timer setup
    window.addEventListener('mousemove', this.resetScreensaverTimer.bind(this), true);
    window.addEventListener('mousedown', this.resetScreensaverTimer.bind(this), true);
    window.addEventListener('touchstart', this.resetScreensaverTimer.bind(this), true);
    window.addEventListener('keydown', this.resetScreensaverTimer.bind(this), true);
    window.addEventListener('scroll', this.resetScreensaverTimer.bind(this), true);
  }

  private resetScreensaverTimer() {
    if (
      this.machine.machineState()?.state === EspressoMachineState.Sleep &&
      this.wakeupTriggered === false
    ) {
      const now = Date.now();
      const diff = now - this.sleepTimestamp;
      if (diff < 2000) {
        // Prevent immediate wakeup right after sleep
        return;
      }
      this.machine.switchOn();
      this.wakeupTriggered = true;
    }
  }

  onScreensaverClick() {
    this.resetScreensaverTimer();
  }

  setMode(mode: ThemeMode): void {
    this.mode.set(mode);
    this.theme.setMode(mode);
  }

  onBack(): void {
    // Navigate back in history for predictable UX
    window.history.back();
  }

  onSave(): void {
    // Delegate save intent via service
    this.toolbar.triggerSave();
  }
}
