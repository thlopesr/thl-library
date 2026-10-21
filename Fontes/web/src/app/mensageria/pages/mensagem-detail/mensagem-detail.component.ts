import { ChangeDetectorRef, Component, Input, OnChanges, inject } from '@angular/core';
import { PoModule } from '@po-ui/ng-components';
import { Mensagem } from '../../models/mensagem.model';
import { MensagemService } from '../../services/mensagem.service';

@Component({
  selector: 'app-mensagem-detail',
  standalone: true,
  imports: [PoModule],
  templateUrl: './mensagem-detail.component.html',
  styles: [`
    .status-item {
      display: flex;
      flex-direction: column;
      gap: 4px;
      margin-bottom: 8px;
    }
    .status-label {
      font-size: 12px;
      color: var(--color-neutral-dark-70, #666);
      text-transform: uppercase;
      font-weight: 600;
    }
    .content-box {
      background: #f7f7f7;
      border: 1px solid #dae0e5;
      border-radius: 4px;
      padding: 12px;
      max-height: 400px;
      overflow-y: auto;
      font-size: 13px;
      white-space: pre-wrap;
      word-break: break-word;
    }
  `]
})
export class MensagemDetailComponent implements OnChanges {
  @Input() mensagem!: Mensagem;
  @Input() activeTab = 0;

  private service = inject(MensagemService);
  private cdr = inject(ChangeDetectorRef);

  conteudoSaida = '';
  conteudoEntrada = '';
  loadingSaida = false;
  loadingEntrada = false;

  getStatusColor(status: string): string {
    switch (status) {
      case 'Sucesso': return 'color-10';
      case 'Erro': return 'color-07';
      case 'Pendente': return 'color-08';
      case 'N/A': return 'color-12';
      default: return 'color-12';
    }
  }

  ngOnChanges(): void {
    this.conteudoSaida = '';
    this.conteudoEntrada = '';

    if (this.activeTab === 2 && this.mensagem?.conteudo?.temRequisicao) {
      this.carregarConteudoSaida();
    }
    if (this.activeTab === 3 && this.mensagem?.conteudo?.temResposta) {
      this.carregarConteudoEntrada();
    }
  }

  onTabChange(tab: number): void {
    if (tab === 2 && !this.conteudoSaida && this.mensagem?.conteudo?.temRequisicao) {
      this.carregarConteudoSaida();
    }
    if (tab === 3 && !this.conteudoEntrada && this.mensagem?.conteudo?.temResposta) {
      this.carregarConteudoEntrada();
    }
  }

  formatJson(raw: string): string {
    if (!raw) return '(vazio)';
    try {
      const parsed = JSON.parse(raw);
      const expanded = this.expandJsonStrings(parsed);
      return JSON.stringify(expanded, null, 2);
    } catch {
      return raw;
    }
  }

  private expandJsonStrings(obj: any): any {
    if (typeof obj === 'string') {
      const trimmed = obj.trim();
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        try {
          return this.expandJsonStrings(JSON.parse(trimmed));
        } catch { return obj; }
      }
      return obj;
    }
    if (Array.isArray(obj)) {
      return obj.map(item => this.expandJsonStrings(item));
    }
    if (obj && typeof obj === 'object') {
      const result: any = {};
      for (const key of Object.keys(obj)) {
        result[key] = this.expandJsonStrings(obj[key]);
      }
      return result;
    }
    return obj;
  }

  private carregarConteudoSaida(): void {
    this.loadingSaida = true;
    this.service.getConteudo(this.mensagem.id, 1).subscribe({
      next: (data) => {
        this.conteudoSaida = data;
        this.loadingSaida = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.conteudoSaida = '(erro ao carregar conteúdo)';
        this.loadingSaida = false;
        this.cdr.detectChanges();
      }
    });
  }

  private carregarConteudoEntrada(): void {
    this.loadingEntrada = true;
    this.service.getConteudo(this.mensagem.id, 2).subscribe({
      next: (data) => {
        this.conteudoEntrada = data;
        this.loadingEntrada = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.conteudoEntrada = '(erro ao carregar conteúdo)';
        this.loadingEntrada = false;
        this.cdr.detectChanges();
      }
    });
  }
}
