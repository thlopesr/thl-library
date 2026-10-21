import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { FaixaPeriodo } from './periodo';

// Rotas `<assunto>/metricas`: resposta `{ items, hasNext }` — `total` não existe no backend.
// Sem paginação e sem limite (ao contrário das listagens), então a soma no cliente é completa.
@Injectable({ providedIn: 'root' })
export class MetricasService {
  private http = inject(HttpClient);
  private readonly base = `${window.location.origin}/api/thl/integration/v1/resourcen`;

  /** `campoData` é o prefixo do filtro da rota: `dtCriacao` ou `dtEnvio`. */
  buscar<T>(rota: string, campoData: string, faixa: FaixaPeriodo): Observable<T[]> {
    const params = new HttpParams()
      .set(`${campoData}Ini`, faixa.ini)
      .set(`${campoData}Fin`, faixa.fin);

    return this.http.get<{ items?: T[] } | T[]>(`${this.base}/${rota}/metricas`, { params }).pipe(
      map(resp => (Array.isArray(resp) ? resp : resp?.items ?? []))
    );
  }
}
