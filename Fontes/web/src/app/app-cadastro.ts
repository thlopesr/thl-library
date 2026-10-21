import { Component, inject } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { PoModule, PoMenuItem } from '@po-ui/ng-components';
import { ThlScrollRestoreService } from './shared/domain';
import { ThlMenuTooltipFixDirective } from './shared/directives';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, PoModule, ThlMenuTooltipFixDirective],
  templateUrl: './app.html',
  styleUrls: ['./app.css', './app-cadastro.css']
})
export class AppCadastro {
  /** Guarda e devolve a rolagem do `.po-page-content` ao trocar de rota. */
  constructor() {
    inject(ThlScrollRestoreService).iniciar();
  }

  // Lista plana; os títulos de seção e a linha separadora vêm do app-cadastro.css (pelo link do 1º item de cada grupo).
  menus: PoMenuItem[] = [
    { label: 'Início', link: '/', icon: 'an an-house', shortLabel: 'Início' },
    { label: 'Ambiente', link: '/ambiente', icon: 'an an-globe-simple', shortLabel: 'Ambiente' },
    { label: 'Parâmetro', link: '/parametro', icon: 'an an-gear-six', shortLabel: 'Parâmetro' },
    { label: 'Grupo de e-mail', link: '/grupo-email', icon: 'an an-users-three', shortLabel: 'Grupo' },
    { label: 'E-mail', link: '/email', icon: 'an an-envelope-simple', shortLabel: 'E-mail' },
    { label: 'Aplicação', link: '/aplicacao', icon: 'an an-squares-four', shortLabel: 'Aplicação' },
    { label: 'Objeto', link: '/objeto', icon: 'an an-cube', shortLabel: 'Objeto' },
    { label: 'Conexão', link: '/conexao', icon: 'an an-plugs', shortLabel: 'Conexão' },
    { label: 'Path', link: '/path', icon: 'an an-path', shortLabel: 'Path' },
    { label: 'Auditoria', link: '/auditoria', icon: 'an an-clipboard-text', shortLabel: 'Auditoria' }
  ];
}
