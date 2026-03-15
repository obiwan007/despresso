import {ChangeDetectionStrategy, Component, signal, computed, effect, input, inject, OnInit} from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatListModule } from '@angular/material/list';
import { MatTableModule } from '@angular/material/table';
import { MatSnackBarModule } from '@angular/material/snack-bar';
import { ShotService } from '../../services/shot.service';
import { SettingsService } from '../../services/settings.service';
import {MatSlideToggleModule} from '@angular/material/slide-toggle';
import {FormsModule, ReactiveFormsModule} from '@angular/forms';
import {ProfilesService} from '../../services/profiles.service';
import {ShotGraphComponent} from '../../components/shot-graph/Tab/shot-graph.component';
import { DescribeShotComponent } from '../../components/describe-shot/describe-shot.component';
import { MatDialog } from '@angular/material/dialog';
import {ShotEntity} from '../../models/state';
// import { VisualizerService } from '../../services/visualizer.service';

@Component({
  selector: 'app-shot-selection',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatCheckboxModule,
    MatListModule,
    MatTableModule,
    MatSnackBarModule,
    MatSlideToggleModule,
    ReactiveFormsModule,
    FormsModule,
    ShotGraphComponent,
  ],
  templateUrl: './shot-selection.component.html',
  styleUrls: ['./shot-selection.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ShotSelectionComponent implements OnInit {
  private readonly shotService = inject(ShotService);
  readonly settingsService = inject(SettingsService);
  readonly profileService = inject(ProfilesService);
  private readonly dialog = inject(MatDialog);

  readonly shots = computed(() => {
    return this.shotService.shots()?.sort((a, b) => b.id.localeCompare(a.id));
  });
  readonly selectedShots = signal<ShotEntity[]>([]);
  readonly overlay = signal(false);
  readonly busy = signal(false);
  readonly busyProgress = signal(0);

  constructor() {}

  ngOnInit() {
    setTimeout(
      () => this.selectedShots.set((this.shots() ?? [])?.length > 0 ? [this.shots()![0]] : []),
      1000,
    );
  }

  setSelection(id: string) {
    const selected = this.selectedShots();
    if (selected.findIndex((s) => s.id === id) !== -1) {
      this.selectedShots.set(selected.filter((s) => s.id !== id));
    } else {
      this.selectedShots.set([...selected, this.shots()!.find((s) => s.id === id)!]);
    }
  }

  async shareCSV() {
    if (this.selectedShots().length === 0) return;
    // await this.shotService.shareShotsAsCSV(this.selectedShots());
  }

  async uploadToVisualizer() {
    if (this.selectedShots().length === 0) {
      // this.shotService.notify('No shots selected for upload');
      return;
    }
    this.busy.set(true);
    this.busyProgress.set(0);
    for (let i = 0; i < this.selectedShots().length; i++) {
      this.busyProgress.set((i + 1) / this.selectedShots().length);
      await this.shotService.sendShotToVisualizer(this.selectedShots()[i].id);
    }
    this.busy.set(false);
    this.busyProgress.set(0);
    // this.shotService.notify('Shots uploaded to visualizer');
  }

  openDescribeShot(shot: ShotEntity): void {
    if (!shot) return;
    this.dialog.open(DescribeShotComponent, {
      width: '640px',
      autoFocus: true,
      restoreFocus: true,
      panelClass: 'describe-shot-dialog',
      data: { shot },
    });
  }

  async uploadToVisualizerById(id: string) {
    this.busy.set(true);
    const visId = await this.shotService.sendShotToVisualizer(id);
    this.busy.set(false);
    const shot = this.shots()?.find((s) => s.id === id);
    if (shot) {
      shot.visualizerId = visId;
      this.shotService.shots.update((current) => {
        const updated = [...(current ?? [])];
        const index = updated.findIndex((s) => s.id === id);
        if (index !== -1) {
          updated[index] = shot;
        }
        return updated;
      });
    }
    // this.shotService.notify('Shots uploaded to visualizer');
  }
}
