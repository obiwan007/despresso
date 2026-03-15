import { Component, Inject, inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { CommonModule } from '@angular/common';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatSelectModule } from '@angular/material/select';
import {FormsModule} from '@angular/forms';
import { ProfilesService } from '../../../../services/profiles.service';
import { MatCheckboxModule } from '@angular/material/checkbox';
import {Coffee} from '../../../../models/state';

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
  ],
  templateUrl: './coffee-edit.component.html',
})
export class CoffeeEditComponent {
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
}
