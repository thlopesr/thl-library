import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';

export interface StatChip {
  key: string;
  label: string;
  value: number;
  icon: string;
  color: string;
  active: boolean;
}

@Component({
  selector: 'thl-stat-chips',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './thl-stat-chips.component.html',
  styleUrls: ['./thl-stat-chips.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ThlStatChipsComponent {
  @Input() chips: StatChip[] = [];
  @Input() equalWidth = false;
  @Output() chipClick = new EventEmitter<StatChip>();

  onChipClick(chip: StatChip): void {
    this.chips.forEach(c => c.active = false);
    chip.active = true;
    this.chipClick.emit(chip);
  }
}
