import { Routes } from '@angular/router';

export const mensageriaRoutes: Routes = [
  {
    path: 'metricas',
    loadComponent: () =>
      import('./pages/mensageria-metricas/mensageria-metricas.component').then(m => m.MensageriaMetricasComponent)
  },
  {
    path: '',
    loadComponent: () =>
      import('./pages/mensagem-list/mensagem-list.component').then(
        m => m.MensagemListComponent
      )
  }
];
