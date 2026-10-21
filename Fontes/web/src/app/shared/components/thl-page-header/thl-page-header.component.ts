import { ChangeDetectionStrategy, Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'thl-page-header',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './thl-page-header.component.html',
  styleUrls: ['./thl-page-header.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ThlPageHeaderComponent {
  @Input() title: string = '';
  @Input() subtitle: string = '';
  @Input() lastUpdate: string = '';
}
