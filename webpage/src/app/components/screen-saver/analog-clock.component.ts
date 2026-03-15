import { Component, Input, OnInit, OnDestroy, Signal, signal, effect } from '@angular/core';

@Component({
  selector: 'analog-clock',
  standalone: true,
  template: `
    <div class="analog-clock" [style.width.px]="size" [style.height.px]="size">
      <svg [attr.width]="size" [attr.height]="size" [attr.viewBox]="'0 0 ' + size + ' ' + size">
        <circle [attr.cx]="center" [attr.cy]="center" [attr.r]="radius" class="clock-face" />
        <line class="hand hour" [attr.x1]="center" [attr.y1]="center" [attr.x2]="hourX" [attr.y2]="hourY" />
        <line class="hand minute" [attr.x1]="center" [attr.y1]="center" [attr.x2]="minuteX" [attr.y2]="minuteY" />
        <line class="hand second" [attr.x1]="center" [attr.y1]="center" [attr.x2]="secondX" [attr.y2]="secondY" />
      </svg>
    </div>
  `,
  styleUrls: ['./analog-clock.component.scss']
})
export class AnalogClockComponent implements OnInit, OnDestroy {
  @Input() size = 220;
  private timer: any;
  now = signal(new Date());

  get center() { return this.size / 2; }
  get radius() { return this.size / 2 - 8; }

  get hourAngle() {
    const d = this.now();
    return ((d.getHours() % 12) + d.getMinutes() / 60) * 30;
  }
  get minuteAngle() {
    const d = this.now();
    return (d.getMinutes() + d.getSeconds() / 60) * 6;
  }
  get secondAngle() {
    const d = this.now();
    return d.getSeconds() * 6;
  }
  get hourX() { return this.center + Math.sin(this.hourAngle * Math.PI / 180) * (this.radius * 0.5); }
  get hourY() { return this.center - Math.cos(this.hourAngle * Math.PI / 180) * (this.radius * 0.5); }
  get minuteX() { return this.center + Math.sin(this.minuteAngle * Math.PI / 180) * (this.radius * 0.8); }
  get minuteY() { return this.center - Math.cos(this.minuteAngle * Math.PI / 180) * (this.radius * 0.8); }
  get secondX() { return this.center + Math.sin(this.secondAngle * Math.PI / 180) * (this.radius * 0.9); }
  get secondY() { return this.center - Math.cos(this.secondAngle * Math.PI / 180) * (this.radius * 0.9); }

  ngOnInit() {
    this.timer = setInterval(() => this.now.set(new Date()), 1000);
  }
  ngOnDestroy() {
    clearInterval(this.timer);
  }
}
