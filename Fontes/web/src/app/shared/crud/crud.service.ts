import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { CrudListResult, CrudRow } from './crud.model';

@Injectable({ providedIn: 'root' })
export class CrudService {
  private http = inject(HttpClient);
  private readonly base = `${window.location.origin}/api/thl/integration/v1/resourcen`;

  /** Lista o recurso; `faixa` vira `<campo>Ini` e `<campo>Fin` com o mesmo valor. */
  list(resource: string, faixa: CrudRow = {}): Observable<CrudListResult> {
    let params = new HttpParams();
    for (const [campo, valor] of Object.entries(faixa)) {
      params = params.set(`${campo}Ini`, String(valor)).set(`${campo}Fin`, String(valor));
    }
    return this.http.get<unknown>(`${this.base}/${resource}`, { params }).pipe(
      map(resp => this.extract(resp))
    );
  }

  create(resource: string, row: CrudRow): Observable<unknown> {
    return this.http.post(`${this.base}/${resource}`, row);
  }

  update(resource: string, row: CrudRow): Observable<unknown> {
    return this.http.patch(`${this.base}/${resource}`, row);
  }

  /** A API recebe a chave no corpo do DELETE. */
  delete(resource: string, key: CrudRow): Observable<unknown> {
    return this.http.delete(`${this.base}/${resource}`, { body: key });
  }

  private extract(resp: unknown): CrudListResult {
    if (Array.isArray(resp)) return { items: resp as CrudRow[] };
    const corpo = resp as { items?: unknown; total?: number; hasNext?: boolean } | null;
    const items = Array.isArray(corpo?.items) ? (corpo!.items as CrudRow[]) : [];
    return { items, total: corpo?.total, hasNext: corpo?.hasNext };
  }
}
