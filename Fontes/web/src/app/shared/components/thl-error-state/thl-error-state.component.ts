import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output } from '@angular/core';
import { PoModule } from '@po-ui/ng-components';

// Estado de erro de carregamento, igual em todas as telas: a falha nunca pode
// parecer lista vazia. `detalhe` recebe a mensagem do backend (`error.message`),
// não a do `HttpErrorResponse`, que é técnica demais para quem usa a tela.
// `role="alert"` faz o leitor de tela anunciar a falha sem o usuário ir procurar.
@Component({
  selector: 'thl-error-state',
  standalone: true,
  imports: [PoModule],
  templateUrl: './thl-error-state.component.html',
  styleUrls: ['./thl-error-state.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ThlErrorStateComponent {
  @Input() titulo = 'Não foi possível carregar.';
  @Input() detalhe = '';
  @Input() rotuloAcao = 'Tentar novamente';
  @Output() retry = new EventEmitter<void>();
}
