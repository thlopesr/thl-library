import { ChangeDetectionStrategy, Component, Input } from '@angular/core';
import { PoModule, PoPopupAction } from '@po-ui/ng-components';

// Menu "⋯" para usar em coluna `type: 'cellTemplate'` do po-table (a coluna de ações nativa não aceita título).
//
// `p-position="right-bottom"` não é enfeite: no padrão (`bottom-left`) o menu abre em cima da
// própria coluna Ação e cobre o "⋯" das linhas seguintes — medido em 15/10/2026, com o menu da
// linha 1 aberto o `elementFromPoint` sobre o "⋯" da linha 2 devolvia um item do menu da linha 1.
// O clique na outra linha ou disparava a ação errada ou só fechava o menu (o "preciso clicar duas
// vezes"). Abrindo para o lado, o menu cobre células de dados e nunca outro "⋯"; o PO UI rotaciona
// sozinho quando não cabe na tela.
@Component({
  selector: 'thl-row-actions',
  standalone: true,
  imports: [PoModule],
  templateUrl: './thl-row-actions.component.html',
  styles: [`
    :host {
      display: flex;
      align-items: center;
    }
    .po-clickable {
      display: flex;
    }
    .po-clickable po-icon.po-field-icon {
      color: var(--color-action-default);
    }
  `],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ThlRowActionsComponent {
  @Input({ required: true }) actions: PoPopupAction[] = [];
  @Input({ required: true }) row: unknown;
}
