import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { Mensagem, MensagemFiltro } from '../models/mensagem.model';

@Injectable({ providedIn: 'root' })
export class MensagemService {
  private http = inject(HttpClient);
  private readonly api = `${window.location.origin}/api/thl/integration/v1/resourcen/mensageria`;

  private readonly conteudoApi = `${window.location.origin}/api/thl/integration/v1/resourcen/mensageria/conteudo`;

  getConteudo(id: string, tipo: number): Observable<string> {
    const params = new HttpParams().set('id', id).set('tipo', String(tipo));
    return this.http.get(this.conteudoApi, { params, responseType: 'text' });
  }

  private extractItems(resp: any): Mensagem[] {
    if (!resp) return [];
    if (Array.isArray(resp)) return resp;
    if (resp.items && Array.isArray(resp.items)) return resp.items;
    for (const val of Object.values(resp)) {
      if (Array.isArray(val)) return val as Mensagem[];
      if (val && typeof val === 'object' && !Array.isArray(val)) {
        for (const inner of Object.values(val as Record<string, unknown>)) {
          if (Array.isArray(inner)) return inner as Mensagem[];
        }
      }
    }
    return [];
  }

  getAll(filters: MensagemFiltro = {}): Observable<Mensagem[]> {
    let params = new HttpParams();

    if (filters.codMsgIni) params = params.set('codigoIni', filters.codMsgIni.trim());
    if (filters.codMsgFin) params = params.set('codigoFin', filters.codMsgFin.trim());
    if (filters.objetoIni) params = params.set('objetoIni', filters.objetoIni.trim());
    if (filters.objetoFin) params = params.set('objetoFin', filters.objetoFin.trim());
    if (filters.operacaoIni) params = params.set('operacaoIni', filters.operacaoIni.trim());
    if (filters.operacaoFin) params = params.set('operacaoFin', filters.operacaoFin.trim());
    if (filters.aplicacaoIni) params = params.set('aplicacaoIni', filters.aplicacaoIni.trim());
    if (filters.aplicacaoFin) params = params.set('aplicacaoFin', filters.aplicacaoFin.trim());
    if (filters.dtIntegracaoInicial) params = params.set('dtIntegracaoIni', filters.dtIntegracaoInicial);
    if (filters.dtIntegracaoFinal) params = params.set('dtIntegracaoFin', filters.dtIntegracaoFinal);
    if (filters.dtCriacaoInicial) params = params.set('dtCriacaoIni', filters.dtCriacaoInicial);
    if (filters.dtCriacaoFinal) params = params.set('dtCriacaoFin', filters.dtCriacaoFinal);

    return this.http.get<any>(this.api, { params }).pipe(
      map(resp => this.extractItems(resp))
    );
  }
}
