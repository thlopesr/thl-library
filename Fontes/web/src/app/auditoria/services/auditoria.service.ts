import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { Auditoria, AuditoriaFiltro } from '../models/auditoria.model';

interface ApiResponse {
  total: number;
  hasNext: boolean;
  items: Auditoria[];
}

@Injectable({ providedIn: 'root' })
export class AuditoriaService {
  private http = inject(HttpClient);
  private readonly api = `${window.location.origin}/api/thl/integration/v1/resourcen/auditoria`;

  getAll(filters: AuditoriaFiltro = {}): Observable<Auditoria[]> {
    let params = new HttpParams();

    if (filters.bancoIni) params = params.set('bancoIni', filters.bancoIni.trim());
    if (filters.bancoFin) params = params.set('bancoFin', filters.bancoFin.trim());
    if (filters.tabelaIni) params = params.set('tabelaIni', filters.tabelaIni.trim());
    if (filters.tabelaFin) params = params.set('tabelaFin', filters.tabelaFin.trim());
    if (filters.dtCriacaoInicial) params = params.set('dtCriacaoIni', filters.dtCriacaoInicial);
    if (filters.dtCriacaoFinal) params = params.set('dtCriacaoFin', filters.dtCriacaoFinal);
    if (filters.usuarioIni) params = params.set('usuarioIni', filters.usuarioIni.trim());
    if (filters.usuarioFin) params = params.set('usuarioFin', filters.usuarioFin.trim());

    return this.http.get<ApiResponse>(this.api, { params }).pipe(
      map(resp => {
        if (resp && Array.isArray(resp.items)) return resp.items;
        if (Array.isArray(resp)) return resp as unknown as Auditoria[];
        return [];
      })
    );
  }
}
