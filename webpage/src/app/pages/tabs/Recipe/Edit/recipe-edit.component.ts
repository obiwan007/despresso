import { Component, Inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { CommonModule } from '@angular/common';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import {FormsModule} from '@angular/forms';
import {MatCheckboxModule} from '@angular/material/checkbox';
import {RecipeEntity} from '../../../../models/state';

@Component({
  selector: 'app-recipe-edit',
  standalone: true,
  imports: [CommonModule, MatFormFieldModule, MatInputModule, MatButtonModule, MatDialogModule, FormsModule,
    MatCheckboxModule,
  ],
  templateUrl: './recipe-edit.component.html',
})
export class RecipeEditComponent {
  recipe: RecipeEntity;

  constructor(
    public dialogRef: MatDialogRef<RecipeEditComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { recipe: RecipeEntity }
  ) {
    // Make a shallow copy to avoid mutating the original until save
    this.recipe = { ...data.recipe };
  }

  onCancel() {
    this.dialogRef.close();
  }

  onSave() {
    this.dialogRef.close(this.recipe);
  }
}
