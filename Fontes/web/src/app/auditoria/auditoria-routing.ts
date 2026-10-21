import { Routes } from '@angular/router';

export const auditoriaRoutes: Routes = [
  {
    path: 'metricas',
    loadComponent: () =>
      import('./pages/auditoria-metricas/auditoria-metricas.component').then(
        m => m.AuditoriaMetricasComponent
      )
  },
  {
    path: '',
    loadComponent: () =>
      import('./pages/auditoria-list/auditoria-list.component').then(
        m => m.AuditoriaListComponent
      )
  }
];
