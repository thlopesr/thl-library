import { Component, inject } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { PoModule, PoMenuItem } from '@po-ui/ng-components';
import { ThlScrollRestoreService } from './shared/domain';
import { ThlMenuTooltipFixDirective } from './shared/directives';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, PoModule, ThlMenuTooltipFixDirective],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  /** Guarda e devolve a rolagem do `.po-page-content` ao trocar de rota. */
  constructor() {
    inject(ThlScrollRestoreService).iniciar();
  }

  menus: PoMenuItem[] = [
    { label: 'Métricas gerais', link: '/', icon: 'an an-chart-bar', shortLabel: 'Gerais' },
    { label: 'Mensageria', link: '/mensageria', icon: 'an an-arrows-left-right', shortLabel: 'Mensageria' },
    { label: 'Métrica Mensageria', link: '/mensageria/metricas', icon: 'an an-chalkboard-simple', shortLabel: 'Mét. Msg' },
    { label: 'E-mail', link: '/email', icon: 'an an-envelope-simple', shortLabel: 'E-mail' },
    { label: 'Métrica E-mail', link: '/email/metricas', icon: 'an an-chalkboard-teacher', shortLabel: 'Mét. E-mail' },
    { label: 'Auditoria', link: '/auditoria', icon: 'an an-magnifying-glass', shortLabel: 'Auditoria' },
    { label: 'Métrica Auditoria', link: '/auditoria/metricas', icon: 'an an-chalkboard', shortLabel: 'Mét. Audit.' }
  ];
}
