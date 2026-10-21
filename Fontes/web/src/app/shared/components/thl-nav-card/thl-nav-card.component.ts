import { ChangeDetectionStrategy, Component, Input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { NavCard } from './thl-nav-card.model';

// Destino de navegação clicável. É uma âncora de verdade (`routerLink` em `<a>`), não um
// botão: abre em nova aba com Ctrl+clique, entra na lista de links do leitor de tela e
// recebe foco sem `tabindex` manual — nada disso acontece com `po-button (p-click)`.
@Component({
  selector: 'thl-nav-card',
  standalone: true,
  imports: [RouterLink],
  templateUrl: './thl-nav-card.component.html',
  styleUrls: ['./thl-nav-card.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ThlNavCardComponent {
  @Input({ required: true }) card!: NavCard;
}
