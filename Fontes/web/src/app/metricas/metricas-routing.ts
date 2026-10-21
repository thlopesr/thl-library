import { Routes } from '@angular/router';

export const metricasRoutes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/metricas/metricas.component').then(m => m.MetricasComponent)
  }
];
