import { ApplicationConfig, provideBrowserGlobalErrorListeners, importProvidersFrom } from '@angular/core';
import { provideRouter, withHashLocation } from '@angular/router';
import { provideHttpClient, withInterceptors, withInterceptorsFromDi } from '@angular/common/http';
import { provideAnimations } from '@angular/platform-browser/animations';
import { PoHttpInterceptorModule } from '@po-ui/ng-components';

import { cadastroRoutes } from './cadastro.routes';
import { mockInterceptors } from './mock/mock-interceptors';

export const appCadastroConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    // Sem `withInMemoryScrolling`: ele rola a janela, e nestas telas quem rola é o
    // `.po-page-content` do PO UI. Quem devolve a posição é o `ThlScrollRestoreService`.
    provideRouter(cadastroRoutes, withHashLocation()),
    provideHttpClient(
      withInterceptorsFromDi(),
      withInterceptors(mockInterceptors)
    ),
    provideAnimations(),
    importProvidersFrom([PoHttpInterceptorModule])
  ]
};
