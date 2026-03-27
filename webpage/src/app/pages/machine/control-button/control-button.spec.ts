import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ControlButton } from './control-button';

describe('ControlButton', () => {
  let component: ControlButton;
  let fixture: ComponentFixture<ControlButton>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ControlButton]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ControlButton);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
