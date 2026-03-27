import {Component, input, computed} from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

@Component({
  selector: 'app-gauge',
  standalone: true,
  imports: [CommonModule, MatCardModule, MatProgressSpinnerModule],
  templateUrl: './gauge.component.html',
  styleUrls: ['./gauge.component.scss'],
})
export class GaugeComponent {
    pressure = input<number>(66);
    temp = input<number>(66);
    flow = input<number>(0);
    weight = input<number>(0);
    time = input<number>(0);
    status = input<string>('preinfusion');
    subStatus = input<string | undefined>(undefined);
    min = input<number>(0);
    max = input<number>(100);
    size = input<number>(180); // overall width; height is half
    stroke = input<number>(5);
    tickNumber = input<number>(12);
    tickLength = input<number>(8);
    minorTicksPerSegment = input<number>(4);
    minorTickLength = input<number>(4);
    startAngle = input<number>(90 + 20); // left-bottom (225°)
    endAngle = input<number>(360 + 90 - 20);   // 225° + 320° span => 185° (used if gapDegrees=0)
    gapDegrees = input<number>(0);  // adjustable gap size; when >0 overrides endAngle

    // Optional color overrides (CSS color strings)
    colorPrimary = input<string | undefined>(undefined);
    colorSurface = input<string | undefined>(undefined);
    colorOutline = input<string | undefined>(undefined);
    colorOutlineVariant = input<string | undefined>(undefined);
    colorNeedle = input<string | undefined>(undefined);

    get cx() {return this.size() / 2;}
    get cy() {return this.size() / 2;}
    get r() {return this.size() / 2 - this.stroke() / 2;}
    get plateR() {return this.size() / 2 - 3;}

    private clamp(val: number) {
        return Math.max(this.min(), Math.min(this.max(), val));
    }

    private spanDegrees() {
        const gap = Math.max(0, Math.min(359, this.gapDegrees()));
        if (gap > 0) {
            return 360 - gap;
        }
        let s = this.endAngle() - this.startAngle();
        if (s < 0) s += 360;
        return s;
    }

    private mapValueToAngle(val: number) {
        const v = this.clamp(val);
        const range = this.max() - this.min();
        const t = range === 0 ? 0 : (v - this.min()) / range; // 0..1
        // Map to partial circle arc from startAngle to endAngle
        return this.startAngle() + t * this.spanDegrees(); // degrees
    }

    private toRadians(deg: number) {
        return (deg * Math.PI) / 180;
    }

    private polarToCartesian(cx: number, cy: number, r: number, angleDeg: number) {
        const a = this.toRadians(angleDeg);
        return {
            x: cx + r * Math.cos(a),
            y: cy + r * Math.sin(a),
        };
    }

    private describeArc(cx: number, cy: number, r: number, startAngle: number, endAngle: number) {
        const start = this.polarToCartesian(cx, cy, r, startAngle);
        const end = this.polarToCartesian(cx, cy, r, endAngle);
        const delta = ((endAngle - startAngle) % 360 + 360) % 360; // normalize 0..359
        const largeArcFlag = delta >= 180 ? 1 : 0;
        const sweepFlag = 1; // 1 = clockwise (positive angle)
        return `M ${start.x} ${start.y} A ${r} ${r} 0 ${largeArcFlag} ${sweepFlag} ${end.x} ${end.y}`;
    }

    get backgroundPath() {
        return this.describeArc(this.cx, this.cy, this.r, this.startAngle(), this.startAngle() + this.spanDegrees());
    }

    get valuePath() {
        const end = this.mapValueToAngle(this.pressure());
        return this.describeArc(this.cx, this.cy, this.r, this.startAngle(), end);
    }

    get needle() {
        const angle = this.mapValueToAngle(this.pressure());
        const tip = this.polarToCartesian(this.cx, this.cy, this.r - this.stroke(), angle);
        return {x1: this.cx, y1: this.cy, x2: tip.x, y2: tip.y};
    }

    get progress() {
        const range = this.max() - this.min();
        return range === 0 ? 0 : (this.clamp(this.pressure()) - this.min()) / range;
    }

    get circumference() {
        return 2 * Math.PI * this.r;
    }

    // Total length of the arc span (for dasharray animation)
    arcLengthTotal = computed(() => {
        const spanRad = (this.spanDegrees() * Math.PI) / 180;
        return this.r * spanRad;
    });

    // Dasharray for the value arc to animate smoothly
    valueDashArray = computed(() => {
        const total = this.arcLengthTotal();
        const fraction = this.progress;
        const len = Math.max(0, Math.min(total, total * fraction));
        const rest = Math.max(0, total - len);
        return `${len} ${rest}`;
    });

    ticks = computed(() => {
        const majors = Math.max(2, Math.floor(this.tickNumber()));
        const span = this.spanDegrees();
        const majorLines: Array<{x1: number; y1: number; x2: number; y2: number}> = [];
        const minorLines: Array<{x1: number; y1: number; x2: number; y2: number}> = [];
        const rOuter = this.r - this.stroke() / 2;
        const rInnerMajor = rOuter - this.tickLength();
        const rInnerMinor = rOuter - this.minorTickLength();
        // Major ticks
        for (let i = 0; i < majors; i++) {
            const angle = this.startAngle() + (span * i) / (majors - 1);
            const p1 = this.polarToCartesian(this.cx, this.cy, rInnerMajor, angle);
            const p2 = this.polarToCartesian(this.cx, this.cy, rOuter, angle);
            majorLines.push({x1: p1.x, y1: p1.y, x2: p2.x, y2: p2.y});
        }
        // Minor ticks between majors
        const minorsPer = Math.max(0, Math.floor(this.minorTicksPerSegment()));
        if (minorsPer > 0) {
            for (let seg = 0; seg < majors - 1; seg++) {
                for (let m = 1; m <= minorsPer; m++) {
                    const t = m / (minorsPer + 1);
                    const angle = this.startAngle() + span * (seg + t) / (majors - 1);
                    const p1 = this.polarToCartesian(this.cx, this.cy, rInnerMinor, angle);
                    const p2 = this.polarToCartesian(this.cx, this.cy, rOuter, angle);
                    minorLines.push({x1: p1.x, y1: p1.y, x2: p2.x, y2: p2.y});
                }
            }
        }
        return {major: majorLines, minor: minorLines};
    });

    // Needle rotation angle in degrees (CSS-friendly)
    needleAngle = computed(() => {
        const min = this.min();
        const max = this.max();
        const v = Math.min(Math.max(this.pressure(), min), max);
        const t = (v - min) / (max - min || 1);
        return this.startAngle() + t * this.spanDegrees();
    });

    // Base needle coordinates (horizontal to the right), rotated via CSS
    needleBase = computed(() => {
        const x1 = this.cx;
        const y1 = this.cy;
        const length = this.r - this.stroke() / 2;
        const x2 = x1 + length;
        const y2 = y1;
        return { x1, y1, x2, y2 };
    });
}
