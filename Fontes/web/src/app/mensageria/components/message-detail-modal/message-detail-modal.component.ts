import {
  Component,
  Input,
  Output,
  EventEmitter,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  ViewChild,
  inject
} from '@angular/core';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import { CommonModule } from '@angular/common';
import { PoModalComponent, PoModalAction, PoModule, PoNotificationService, PoTagType } from '@po-ui/ng-components';
import { Mensagem } from '../../models/mensagem.model';
import { MensagemService } from '../../services/mensagem.service';

@Component({
  selector: 'app-message-detail-modal',
  standalone: true,
  imports: [CommonModule, PoModule],
  templateUrl: './message-detail-modal.component.html',
  styleUrls: ['./message-detail-modal.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class MessageDetailModalComponent {
  @ViewChild('modal') modal!: PoModalComponent;

  @Input() message: Mensagem | null = null;
  @Input() initialTab = 0;

  @Output() closed = new EventEmitter<void>();
  @Output() reprocessar = new EventEmitter<string>();

  activeTab = 0;
  isResending = false;

  conteudoSaida = '';
  conteudoEntrada = '';
  loadingSaida = false;
  loadingEntrada = false;

  private cdr = inject(ChangeDetectorRef);
  private sanitizer = inject(DomSanitizer);
  private notification = inject(PoNotificationService);
  private service = inject(MensagemService);

  primaryAction: PoModalAction = {
    label: 'Fechar',
    action: () => this.onClose()
  };

  get secondaryAction(): PoModalAction | undefined {
    if (!this.hasError) return undefined;
    return {
      label: 'Reprocessar',
      loading: this.isResending,
      danger: true,
      action: () => this.onReprocessar()
    };
  }

  get modalTitle(): string {
    if (!this.message) return 'Detalhes Mensagem';
    return `Detalhes Mensagem ${this.message.codMsg?.substring(0, 8) ?? ''}`;
  }

  get hasError(): boolean {
    return this.message?.statusRequisicao === 'Erro'
      || this.message?.statusRetorno === 'Erro'
      || this.message?.statusProcessamento === 'Erro';
  }

  get retornoHeaderClass(): string {
    if (!this.message) return '';
    return this.message.statusRetorno === 'Sucesso' ? 'ok' : 'err';
  }

  get httpStatusLabel(): string {
    if (!this.message) return '';
    const code = this.message.codStatusRetorno;
    if (code >= 200 && code < 300) return 'OK';
    if (code === 400) return 'Bad Request';
    if (code === 401) return 'Unauthorized';
    if (code === 403) return 'Forbidden';
    if (code === 404) return 'Not Found';
    if (code === 422) return 'Unprocessable Entity';
    if (code === 500) return 'Internal Server Error';
    if (code === 502) return 'Bad Gateway';
    if (code === 503) return 'Service Unavailable';
    return '';
  }

  open(message: Mensagem, tab = 0): void {
    this.message = message;
    this.activeTab = tab;
    this.conteudoSaida = '';
    this.conteudoEntrada = '';
    this.isResending = false;
    this.cdr.markForCheck();

    if (tab === 2 && message.conteudo?.temRequisicao) {
      this.carregarConteudoSaida();
    }
    if (tab === 3 && message.conteudo?.temResposta) {
      this.carregarConteudoEntrada();
    }

    // O app roda **zoneless** (sem `zone.js` nos polyfills): o que acontece dentro de um
    // `setTimeout` não agenda detecção de mudanças sozinho. Sem o `markForCheck` aqui, o
    // `po-modal` abria por dentro (`isHidden: false`) e **não renderizava** — o `<po-modal>`
    // ficava vazio no DOM até o próximo evento do Angular. Era o "precisa clicar duas vezes"
    // da mensageria e do e-mail: o primeiro clique abria o modal invisível e o segundo
    // apenas disparava a detecção que faltava. Medido em 16/10/2026.
    setTimeout(() => {
      this.modal?.open();
      this.cdr.markForCheck();
    });
  }

  onTabChange(tab: number): void {
    this.activeTab = tab;
    if (tab === 2 && !this.conteudoSaida && this.message?.conteudo?.temRequisicao) {
      this.carregarConteudoSaida();
    }
    if (tab === 3 && !this.conteudoEntrada && this.message?.conteudo?.temResposta) {
      this.carregarConteudoEntrada();
    }
  }

  onClose(): void {
    this.activeTab = 0;
    this.closed.emit();
  }

  onReprocessar(): void {
    if (!this.message) return;
    this.isResending = true;
    this.cdr.markForCheck();
    this.reprocessar.emit(this.message.id);
  }

  resetResending(): void {
    this.isResending = false;
    this.cdr.markForCheck();
  }

  getTagType(status: string): PoTagType {
    switch (status) {
      case 'Sucesso': return PoTagType.Success;
      case 'Erro': return PoTagType.Danger;
      default: return PoTagType.Warning;
    }
  }

  get conteudoSaidaHighlighted(): SafeHtml {
    return this.highlightJson(this.conteudoSaida);
  }

  get conteudoEntradaHighlighted(): SafeHtml {
    return this.highlightJson(this.conteudoEntrada);
  }

  private highlightJson(raw: string): SafeHtml {
    if (!raw) return '';
    try {
      const parsed = JSON.parse(raw);
      const expanded = this.expandJsonStrings(parsed);
      const json = JSON.stringify(expanded, null, 2);
      const html = json.replace(
        /("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g,
        (match) => {
          let cls = 'jn';
          if (/^"/.test(match)) cls = /:$/.test(match) ? 'jk' : 'js';
          else if (/true|false|null/.test(match)) cls = 'jb';
          return `<span class="${cls}">${match}</span>`;
        }
      );
      return this.sanitizer.bypassSecurityTrustHtml(html);
    } catch {
      return raw;
    }
  }

  private expandJsonStrings(obj: any): any {
    if (typeof obj === 'string') {
      const trimmed = obj.trim();
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        try { return this.expandJsonStrings(JSON.parse(trimmed)); } catch { return obj; }
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
    if (!this.message) return;
    this.loadingSaida = true;
    this.cdr.markForCheck();
    this.service.getConteudo(this.message.id, 1).subscribe({
      next: (data) => {
        this.conteudoSaida = data;
        this.loadingSaida = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.conteudoSaida = '';
        this.loadingSaida = false;
        this.cdr.markForCheck();
      }
    });
  }

  private carregarConteudoEntrada(): void {
    if (!this.message) return;
    this.loadingEntrada = true;
    this.cdr.markForCheck();
    this.service.getConteudo(this.message.id, 2).subscribe({
      next: (data) => {
        this.conteudoEntrada = data;
        this.loadingEntrada = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.conteudoEntrada = '';
        this.loadingEntrada = false;
        this.cdr.markForCheck();
      }
    });
  }
}
