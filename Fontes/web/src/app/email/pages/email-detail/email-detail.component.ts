import { Component, Input } from '@angular/core';
import { PoModule } from '@po-ui/ng-components';
import { Email } from '../../models/email.model';

@Component({
  selector: 'app-email-detail',
  standalone: true,
  imports: [PoModule],
  templateUrl: './email-detail.component.html',
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
export class EmailDetailComponent {
  @Input() email!: Email;
  @Input() activeTab = 0;

  getStatusColor(status: string): string {
    switch (status) {
      case 'Sucesso': return 'color-10';
      case 'Erro': return 'color-07';
      default: return 'color-12';
    }
  }

  getMensagemTexto(): string {
    if (!this.email.mensagem) return '(vazio)';
    try {
      const parsed = JSON.parse(this.email.mensagem);
      if (parsed['tt-mensagem'] && Array.isArray(parsed['tt-mensagem'])) {
        return parsed['tt-mensagem']
          .map((m: any) => m.mensagem || '')
          .join('\n');
      }
      return this.email.mensagem;
    } catch {
      return this.email.mensagem;
    }
  }

  getRetornoTexto(): string {
    if (!this.email.retorno) return '(vazio)';
    try {
      const parsed = JSON.parse(this.email.retorno);
      return JSON.stringify(parsed, null, 2);
    } catch {
      return this.email.retorno;
    }
  }

  getInformacaoTexto(): string {
    if (!this.email.informacao) return '(vazio)';
    try {
      const parsed = JSON.parse(this.email.informacao);
      return JSON.stringify(parsed, null, 2);
    } catch {
      return this.email.informacao;
    }
  }
}
