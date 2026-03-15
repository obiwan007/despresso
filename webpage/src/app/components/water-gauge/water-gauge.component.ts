import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-water-gauge',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="wg-root"
         role="progressbar"
         [attr.aria-valuemin]="0"
         [attr.aria-valuemax]="max()"
         [attr.aria-valuenow]="level()"
         aria-label="Water level"
         [style.height.px]="height()">
      <div class="wg-track">
        <div class="wg-fill" [style.height.%]="percent()"></div>
        @if (limit() !== undefined) {
          <div class="wg-limit" [style.bottom.%]="limitPercent()"></div>
        }
      </div>
      <span class="sr-only">{{ level() }} of {{ max() }}. Limit {{ limit() ?? 'n/a' }}.</span>
    </div>
  `,
  styles: [
    `
    :host { display: inline-block; }
    .wg-root { width: 10px; display: inline-flex; align-items: stretch; }
    .wg-track { position: relative; width: 100%; height: 100%; border-radius: 6px; background: rgba(0,0,0,0.1); overflow: hidden; }
    .wg-fill { position: absolute; left: 0; bottom: 0; width: 100%; background: var(--md-sys-color-primary, #1976d2); }
    .wg-limit { position: absolute; left: 0; width: 100%; height: 2px; background: var(--md-sys-color-error, #d32f2f); opacity: 0.9; }
    .sr-only { position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0, 0, 1px, 1px); white-space: nowrap; border: 0; }
    `
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WaterGaugeComponent {
  level = input<number>(0);
  limit = input<number | undefined>(undefined);
  max = input<number>(100);
  height = input<number>(120);

  percent = computed(() => {
    const v = Math.max(0, Math.min(this.level(), this.max()));
    return (v / (this.max() || 1)) * 100;
  });

  limitPercent = computed(() => {
    const lim = this.limit();
    if (lim === undefined || lim === null) return 0;
    const v = Math.max(0, Math.min(lim, this.max()));
    return (v / (this.max() || 1)) * 100;
  });
}
