import { HttpInterceptorFn } from '@angular/common/http';

// Produção: sem mock. Em development o angular.json troca por mock-interceptors.dev.ts.
export const mockInterceptors: HttpInterceptorFn[] = [];
