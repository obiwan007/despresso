import {Component, Output, EventEmitter, OnInit, OnDestroy, signal} from '@angular/core';
import {AsyncPipe, NgOptimizedImage} from '@angular/common';
import {AnalogClockComponent} from './analog-clock.component';

@Component({
  selector: 'app-screensaver',
  standalone: true,
  imports: [AnalogClockComponent, NgOptimizedImage],
  template: `
    <div class="screensaver" (click)="onClick()" tabindex="0" aria-label="Exit screensaver">
      <img
        class="screensaver-bg"
        [ngSrc]="currentImage() ?? ''"
        [style.opacity]="bgOpacity()"
        [style.transition]="bgTransition()"
        fill
        alt=""
        aria-hidden="true"
      />
      <analog-clock
        [size]="220"
        [style.position]="'absolute'"
        [style.left.px]="x()"
        [style.top.px]="y()"
      ></analog-clock>
    </div>
  `,
  styleUrls: ['./screensaver.component.scss'],
})
export class ScreensaverComponent implements OnInit, OnDestroy {
  @Output() screensaverClick = new EventEmitter<void>();

  x = signal(0);
  y = signal(0);
  private vx = 0.2 + Math.random() * 0.2;
  private vy = 0.1 + Math.random() * 0.2;
  private moveTimer: any;
  private imageTimer: any;
  private readonly size = 220;
  readonly currentImage = signal<string | null>(null);
  readonly bgOpacity = signal<number>(0);
  readonly bgTransition = signal<string>('opacity 0s');
  private images: string[] = [];

  ngOnInit() {
    this.x.set(Math.random() * (window.innerWidth - this.size));
    this.y.set(Math.random() * (window.innerHeight - this.size));
    this.moveTimer = setInterval(() => this.move(), 100);
    void this.loadImages();
  }
  ngOnDestroy() {
    clearInterval(this.moveTimer);
    clearInterval(this.imageTimer);
  }

  move() {
    this.x.set(this.x() + this.vx);
    this.y.set(this.y() + this.vy);
    if (this.x() < 0 || this.x() > window.innerWidth - this.size) this.vx *= -1;
    if (this.y() < 0 || this.y() > window.innerHeight - this.size) this.vy *= -1;
    this.x.set(Math.max(0, Math.min(this.x(), window.innerWidth - this.size)));
    this.y.set(Math.max(0, Math.min(this.y(), window.innerHeight - this.size)));
  }

  onClick() {
    this.screensaverClick.emit();
  }

  private async loadImages(): Promise<void> {
    try {
      const res = await fetch('screensaver/manifest.json', { cache: 'no-cache' });
      if (!res.ok) return;
      const list = (await res.json()) as string[];
      if (Array.isArray(list) && list.length > 0) {
        this.images = list;
        this.pickRandomImage();
        this.imageTimer = setInterval(() => this.pickRandomImage(), 5 * 60 * 1000);
      }
    } catch {
      // ignore errors; background image optional
    }
  }

  private pickRandomImage(): void {
    if (!this.images.length) return;
    const idx = Math.floor(Math.random() * this.images.length);
    this.currentImage.set(this.images[idx]);
    // Fade in over ~3s, then slowly fade out over 5 minutes
    this.bgTransition.set('opacity 0s');
    this.bgOpacity.set(0);
    // next microtask to start fade-in
    setTimeout(() => {
      this.bgTransition.set('opacity 3s ease-in');
      this.bgOpacity.set(1);
      // after fade-in completes, start long fade-out (~300s)
      setTimeout(() => {
        this.bgTransition.set('opacity 300s linear');
        this.bgOpacity.set(0);
      }, 3000);
    }, 0);
  }
}
