import { Injectable, signal } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class ToolbarService {
  readonly showSave = signal(false);

  setSaveVisible(visible: boolean): void {
    this.showSave.set(!!visible);
  }

  triggerSave(): void {
    const evt = new CustomEvent('app-save');
    window.dispatchEvent(evt);
  }
}
