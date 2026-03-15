import { ChangeDetectionStrategy, Component, signal, Input, OnInit } from '@angular/core';
import { MatDialogModule, MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { inject } from '@angular/core';
import { ShotService } from '../../services/shot.service';
import { MatSliderModule } from '@angular/material/slider';
import { FormsModule } from '@angular/forms';
import {ShotEntity} from '../../models/state';

@Component({
  selector: 'app-describe-shot',
  // standalone defaults enabled in Angular v21
  imports: [
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatSliderModule,
    FormsModule,
  ],
  templateUrl: './describe-shot.component.html',
  styleUrls: ['./describe-shot.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DescribeShotComponent {
  readonly notes = signal<string>('');
  readonly barrista = signal<string>('');
  readonly drinker = signal<string>('');
  readonly enjoyment = signal<number>(5);
  readonly grinderSettings = signal<number>(0);
  readonly totalDissolvedSolids = signal<number>(0);
  readonly extractionYield = signal<number>(0);

  private readonly dialogRef = inject(MatDialogRef<DescribeShotComponent>);
  private readonly shotService = inject(ShotService);
  private readonly data = inject(MAT_DIALOG_DATA) as { shot: ShotEntity };
  private shot: ShotEntity;

  constructor() {
    this.shot = this.data.shot;
    if (this.shot) {
      if (this.shot.description) this.notes.set(this.shot.description);
      if (this.shot.barrista) this.barrista.set(this.shot.barrista);
      if (this.shot.drinker) this.drinker.set(this.shot.drinker);
      if (typeof this.shot.enjoyment === 'number') this.enjoyment.set(this.shot.enjoyment);
      if (typeof this.shot.grinderSettings === 'number')
        this.grinderSettings.set(this.shot.grinderSettings);
      if (typeof this.shot.totalDissolvedSolids === 'number')
        this.totalDissolvedSolids.set(this.shot.totalDissolvedSolids);
      if (typeof this.shot.extractionYield === 'number')
        this.extractionYield.set(this.shot.extractionYield);
    }
  }

  onInput(field: 'notes' | 'barrista' | 'drinker', event: Event): void {
    const target = event.target as HTMLInputElement | HTMLTextAreaElement | null;
    if (!target) return;
    if (field === 'notes') this.notes.set(target.value);
    if (field === 'barrista') this.barrista.set(target.value);
    if (field === 'drinker') this.drinker.set(target.value);
  }

  onSlider(
    field: 'enjoyment' | 'grinderSettings' | 'totalDissolvedSolids' | 'extractionYield',
    value: number,
  ): void {
    if (field === 'enjoyment') this.enjoyment.set(value);
    if (field === 'grinderSettings') this.grinderSettings.set(value);
    if (field === 'totalDissolvedSolids') this.totalDissolvedSolids.set(value);
    if (field === 'extractionYield') this.extractionYield.set(value);
  }

  onClose(): void {
    this.dialogRef.close();
  }

  async onSave(): Promise<void> {
    if (!this.shot?.id) {
      this.dialogRef.close();
      return;
    }
    await this.shotService.updateShot(this.shot.id, {
      id: this.shot.id,
      description: this.notes().trim(),
      barrista: this.barrista().trim(),
      drinker: this.drinker().trim(),
      enjoyment: this.enjoyment(),
      grinderSettings: this.grinderSettings(),
      totalDissolvedSolids: this.totalDissolvedSolids(),
      extractionYield: this.extractionYield(),
    });
    this.dialogRef.close({
      notes: this.notes(),
      barrista: this.barrista(),
      drinker: this.drinker(),
      enjoyment: this.enjoyment(),
      grinderSettings: this.grinderSettings(),
      totalDissolvedSolids: this.totalDissolvedSolids(),
      extractionYield: this.extractionYield(),
    });
  }
}
