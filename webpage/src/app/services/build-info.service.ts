import { Injectable, signal } from '@angular/core';
// APP_VERSION is provided by Angular builder via define
declare const APP_VERSION: string;

@Injectable({ providedIn: 'root' })
export class BuildInfoService {
  readonly version = signal<string>(APP_VERSION);
  readonly full = signal<string>(APP_VERSION);
}
