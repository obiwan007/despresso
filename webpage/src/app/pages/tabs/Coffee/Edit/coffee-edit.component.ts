import { Component, Inject, inject } from '@angular/core';
import {
  MatDialogRef,
  MAT_DIALOG_DATA,
  MatDialogModule,
  MatDialog,
} from '@angular/material/dialog';
import { CommonModule } from '@angular/common';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatSelectModule } from '@angular/material/select';
import {FormsModule} from '@angular/forms';
import { ProfilesService } from '../../../../services/profiles.service';
import { MatCheckboxModule } from '@angular/material/checkbox';
import {Coffee} from '../../../../models/state';
import {MatMenuModule} from '@angular/material/menu';
import {MatIconModule} from '@angular/material/icon';
import {RoasterEditComponent} from '../../roaster/Edit/roaster-edit.component';
import {firstValueFrom} from 'rxjs';

@Component({
  selector: 'app-coffee-edit',
  standalone: true,
  imports: [
    CommonModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatDialogModule,
    FormsModule,
    MatSelectModule,
    MatCheckboxModule,
    MatMenuModule,
    MatIconModule,
    MatDialogModule,
  ],
  templateUrl: './coffee-edit.component.html',
})
export class CoffeeEditComponent {
  private readonly dialog = inject(MatDialog);

  coffee: Coffee;
  readonly profiles = inject(ProfilesService);

  constructor(
    public dialogRef: MatDialogRef<CoffeeEditComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { coffee: Coffee },
  ) {
    this.coffee = { ...data.coffee } as Coffee;
  }

  onCancel() {
    this.dialogRef.close();
  }

  onSave() {
    this.dialogRef.close(this.coffee);
  }

  async onDeleteRoaster() {
    const id = this.coffee.roasterId;
    const r = this.profiles.getRoasterById(id);
    if (!r) return;
    await this.profiles.deleteRoaster(r);
    const list = this.profiles.roasters();
    if (list && list?.length > 0) {
      this.coffee.roasterId = list[0].id;
    }
  }

  async onEditRoaster() {
    const id = this.coffee.roasterId;
    const r = this.profiles.getRoasterById(id);
    const ref = this.dialog.open(RoasterEditComponent, {
      data: {roaster: r},
      width: 'calc(100% - 20px)',
      minHeight: 'calc(100vh - 120px)',
      autoFocus: true,
    });
    const result = await firstValueFrom(ref.afterClosed());
    if (result) {
      await this.profiles.updateRoaster(result.id, result);
    }
  }

  async onAddRoaster() {
    const id = this.coffee.roasterId;
    const r = this.profiles.getRoasterById(id);
    const roaster = structuredClone(r);
    if (!roaster) return;
    roaster.id = new Date().getTime().toString(); // Simple unique ID generation
    const ref = this.dialog.open(RoasterEditComponent, {
      data: {roaster},
      width: 'calc(100% - 20px)',
      minHeight: 'calc(100vh - 120px)',
      autoFocus: true,
    });
    const result = await firstValueFrom(ref.afterClosed());
    if (result) {
      const roaster = await this.profiles.createRoaster(result);
      this.coffee.roasterId = roaster!.id;
    }
  }
}
