import { Component, ChangeDetectionStrategy, input, signal, computed, effect } from '@angular/core';

@Component({
  selector: 'app-growing-circle',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './growing-circle.component.html',
  styleUrls: ['./growing-circle.component.css'],
  host: {
    class: 'growing-circle',
    role: 'progressbar',
    style: 'border-radius:50%; display:inline-grid; place-items:center;',
    '[attr.aria-label]': 'ariaLabel()',
    '[attr.aria-valuemin]': '0',
    '[attr.aria-valuemax]': 'destinationValue()',
    '[attr.aria-valuenow]': 'value()',
    '[style.width.px]': 'width()',
    '[style.height.px]': 'width()',
    '[class.warn]': 'isWarn()',
    '[class.growing]': 'isGoal()===false && isWarn()===false',
    '[class.goal]': 'isGoal() && !isWarn()',
  },
})
export class GrowingCircleComponent {
  // Inputs
  value = input<number>(0);
  destinationValue = input<number>(0);
  width = input<number>(64);

  // Local animated size state
  currentSize = signal<number>(0);

  // Percentage of completion based on value / destinationValue
  private readonly percentage = computed<number>(() => {
    const v = this.value();
    const d = this.destinationValue();
    if (!Number.isFinite(v) || !Number.isFinite(d) || d <= 0) return 0;
    const p = v / d;
    return Math.max(0, Math.min(1, p));
  });

  // Target size is the percentage of the provided width
  private readonly targetSize = computed<number>(() => {
    const w = this.width();
    const p = this.percentage();
    if (!Number.isFinite(w) || w <= 0) return 0;
    return Math.round(w * p);
  });

  // Warn when the current value exceeds the destination
  readonly isWarn = computed<boolean>(() => {
    const v = this.value();
    const d = this.destinationValue();
    return Number.isFinite(v) && Number.isFinite(d) ? v > d : false;
  });

  // Goal when value reaches at least 10% of destination
  readonly isGoal = computed<boolean>(() => {
    const v = this.value();
    const d = this.destinationValue();
    if (!Number.isFinite(v) || !Number.isFinite(d) || d <= 0) return false;
    return v / d >= 0.9;
  });

  // Trigger animation whenever destination changes
  private readonly animate = effect(() => {
    const next = this.targetSize();
    // Smoothly transition to the next size via CSS transition
    this.currentSize.set(next);
  });

  // Host bindings helpers
  ariaLabel(): string {
    const pct = Math.round(this.percentage() * 100);
    return `Value ${this.value()} of ${this.destinationValue()} (${pct}%)`;
  }

  fontSize(): number {
    const s = this.currentSize();
    // Keep text legible relative to size
    return Math.max(12, Math.round(s * 0.35));
  }
}
