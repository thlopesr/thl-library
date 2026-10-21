import { Routes } from '@angular/router';
import {
  ambienteDef, aplicacaoDef, auditoriaDef, conexaoDef, emailDef, grupoEmailDef, objetoDef, parametroDef, pathDef
} from './cadastros/cadastros.defs';
import { CrudResource } from './shared/crud';

const cadastro = (path: string, def: CrudResource) => ({
  path,
  data: { def },
  loadComponent: () =>
    import('./shared/crud/thl-crud-page/thl-crud-page.component').then(m => m.ThlCrudPageComponent)
});

export const cadastroRoutes: Routes = [
  {
    path: '',
    pathMatch: 'full',
    loadChildren: () => import('./inicio/inicio-routing').then(m => m.inicioRoutes)
  },
  cadastro('ambiente', ambienteDef),
  cadastro('parametro', parametroDef),
  cadastro('grupo-email', grupoEmailDef),
  cadastro('email', emailDef),
  cadastro('aplicacao', aplicacaoDef),
  cadastro('objeto', objetoDef),
  cadastro('conexao', conexaoDef),
  cadastro('path', pathDef),
  cadastro('auditoria', auditoriaDef),
  // A rota virou operação do objeto (backend 2026-10-08): link antigo cai na tela certa.
  { path: 'rota', pathMatch: 'full', redirectTo: 'objeto' }
];
