import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output } from '@angular/core';
import { PoModule } from '@po-ui/ng-components';

// Estado vazio com orientação: "não encontrou" precisa dizer o que fazer em
// seguida. Diferente do erro (`thl-error-state`) — aqui a consulta respondeu.
// `acao` vazio esconde o botão, para a tela que não tem passo seguinte.
@Component({
  selector: 'thl-empty-state',
  standalone: true,
  imports: [PoModule],
  templateUrl: './thl-empty-state.component.html',
  styleUrls: ['./thl-empty-state.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ThlEmptyStateComponent {
  @Input({ required: true }) titulo!: string;
  @Input() descricao = '';
  @Input() acao = '';
  @Input() icone = 'an an-plus';
  @Output() acaoClick = new EventEmitter<void>();
}
