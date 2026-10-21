import { ApplicationConfig, provideBrowserGlobalErrorListeners, importProvidersFrom } from '@angular/core';
import { provideRouter, withHashLocation } from '@angular/router';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';
import { provideAnimations } from '@angular/platform-browser/animations';
import { PoHttpInterceptorModule } from '@po-ui/ng-components';

import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    // Sem `withInMemoryScrolling`: ele rola a janela, e nestas telas quem rola é o
    // `.po-page-content` do PO UI. Quem devolve a posição é o `ThlScrollRestoreService`.
    provideRouter(routes, withHashLocation()),
    provideHttpClient(withInterceptorsFromDi()),
    provideAnimations(),
    importProvidersFrom([PoHttpInterceptorModule])
  ]
};
