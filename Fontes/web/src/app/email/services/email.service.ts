import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { Email, EmailFiltro } from '../models/email.model';

@Injectable({ providedIn: 'root' })
export class EmailService {
  private http = inject(HttpClient);
  private readonly api = `${window.location.origin}/api/thl/integration/v1/resourcen/email`;

  private extractItems(resp: any): Email[] {
    if (!resp) return [];
    if (Array.isArray(resp)) return resp;
    if (resp.items && Array.isArray(resp.items)) return resp.items;
    for (const val of Object.values(resp)) {
      if (Array.isArray(val)) return val as Email[];
      if (val && typeof val === 'object' && !Array.isArray(val)) {
        for (const inner of Object.values(val as Record<string, unknown>)) {
          if (Array.isArray(inner)) return inner as Email[];
        }
      }
    }
    return [];
  }

  getAll(filters: EmailFiltro = {}): Observable<Email[]> {
    let params = new HttpParams();

    if (filters.dtEnvioInicial) {
      params = params.set('dtEnvioIni', filters.dtEnvioInicial);
    }
    if (filters.dtEnvioFinal) {
      params = params.set('dtEnvioFin', filters.dtEnvioFinal);
    }
    if (filters.idIni) {
      params = params.set('idIni', filters.idIni.trim());
    }
    if (filters.idFin) {
      params = params.set('idFin', filters.idFin.trim());
    }
    if (filters.codProgDtsulIni) {
      params = params.set('codProgDtsulIni', filters.codProgDtsulIni.trim());
    }
    if (filters.codProgDtsulFin) {
      params = params.set('codProgDtsulFin', filters.codProgDtsulFin.trim());
    }

    return this.http.get<any>(this.api, { params }).pipe(
      map(resp => this.extractItems(resp))
    );
  }
}
