import { Routes } from '@angular/router';

export const inicioRoutes: Routes = [
  {
    path: '',
    loadComponent: () => import('./pages/inicio/inicio.component').then(m => m.InicioComponent)
  }
];
