import { Routes } from '@angular/router';

export const emailRoutes: Routes = [
  {
    path: 'metricas',
    loadComponent: () =>
      import('./pages/email-metricas/email-metricas.component').then(m => m.EmailMetricasComponent)
  },
  {
    path: '',
    loadComponent: () =>
      import('./pages/email-list/email-list.component').then(
        m => m.EmailListComponent
      )
  }
];
