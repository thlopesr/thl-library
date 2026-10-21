import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    loadChildren: () =>
      import('./metricas/metricas-routing').then(m => m.metricasRoutes)
  },
  // O Dashboard Msg foi removido em 2026-10-09: link antigo cai na tela de metricas do assunto,
  // como o redirect de 'rota' para 'objeto' no app de cadastro.
  { path: 'dashboard-mensageria', pathMatch: 'full', redirectTo: 'mensageria/metricas' },
  {
    path: 'mensageria',
    loadChildren: () =>
      import('./mensageria/mensageria-routing').then(m => m.mensageriaRoutes)
  },
  {
    path: 'email',
    loadChildren: () =>
      import('./email/email-routing').then(m => m.emailRoutes)
  },
  {
    path: 'auditoria',
    loadChildren: () =>
      import('./auditoria/auditoria-routing').then(m => m.auditoriaRoutes)
  }
];
