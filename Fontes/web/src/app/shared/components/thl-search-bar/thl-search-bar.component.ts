import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'thl-search-bar',
  standalone: true,
  templateUrl: './thl-search-bar.component.html',
  styleUrls: ['./thl-search-bar.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ThlSearchBarComponent {
  @Input() placeholder = 'Buscar...';
  @Input() value = '';
  @Input() showAdvanced = true;
  @Output() search = new EventEmitter<string>();
  @Output() advanced = new EventEmitter<void>();

  emitSearch(term: string): void {
    this.search.emit(term.trim());
  }

  // Campo limpo manualmente: reaplica a busca sem termo
  onInput(term: string): void {
    if (term === '') {
      this.search.emit('');
    }
  }
}
