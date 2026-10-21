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
import { Email } from '../../models/email.model';
import { realcarJson } from '../../../shared/domain';

@Component({
  selector: 'app-email-detail-modal',
  standalone: true,
  imports: [CommonModule, PoModule],
  templateUrl: './email-detail-modal.component.html',
  styleUrls: ['./email-detail-modal.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class EmailDetailModalComponent {
  @ViewChild('modal') modal!: PoModalComponent;

  @Input() email: Email | null = null;
  @Input() initialTab = 0;

  @Output() closed = new EventEmitter<void>();
  @Output() reenviar = new EventEmitter<string>();

  isResending = false;
  activeTab = 0;

  private cdr = inject(ChangeDetectorRef);
  private sanitizer = inject(DomSanitizer);
  private notification = inject(PoNotificationService);

  primaryAction: PoModalAction = {
    label: 'Fechar',
    action: () => this.onClose()
  };

  get secondaryAction(): PoModalAction | undefined {
    if (!this.email || this.email.logEnvio !== 'Erro') {
      return undefined;
    }
    return {
      label: 'Reenviar',
      loading: this.isResending,
      danger: true,
      action: () => this.onReenviar()
    };
  }

  get modalTitle(): string {
    if (!this.email) return 'Detalhes E-mail';
    return `Detalhes E-mail - ${this.email.assunto || ''}`;
  }

  get statusTagType(): PoTagType {
    if (!this.email) return PoTagType.Info;
    switch (this.email.logEnvio) {
      case 'Sucesso': return PoTagType.Success;
      case 'Erro': return PoTagType.Danger;
      default: return PoTagType.Warning;
    }
  }

  get statusDescricao(): string {
    if (!this.email) return '';
    switch (this.email.logEnvio) {
      case 'Sucesso': return 'E-mail entregue com sucesso';
      case 'Erro': return 'Falha no envio do e-mail';
      default: return this.email.logEnvio || '';
    }
  }

  get mensagemHtml(): SafeHtml {
    if (!this.email?.mensagem) return '';
    try {
      const parsed = JSON.parse(this.email.mensagem);
      if (parsed['tt-mensagem'] && Array.isArray(parsed['tt-mensagem'])) {
        const html = parsed['tt-mensagem']
          .map((m: any) => m.mensagem || '')
          .join('');
        return this.sanitizer.bypassSecurityTrustHtml(html);
      }
      return this.sanitizer.bypassSecurityTrustHtml(this.email.mensagem);
    } catch {
      return this.sanitizer.bypassSecurityTrustHtml(this.email.mensagem);
    }
  }

  get hasMensagem(): boolean {
    return !!this.email?.mensagem;
  }

  /** Realce por tipo; o `bypassSecurityTrustHtml` é seguro porque `realcarJson`
   *  escapa `&`, `<` e `>` antes de montar os `<span>`. */
  get retornoHtml(): SafeHtml {
    return this.sanitizer.bypassSecurityTrustHtml(realcarJson(this.email?.retorno));
  }

  get hasRetorno(): boolean {
    return !!this.email?.retorno && this.email.retorno !== '(vazio)';
  }

  get retornoBadgeLabel(): string {
    return 'Retorno';
  }

  get parametrosHtml(): SafeHtml {
    return this.sanitizer.bypassSecurityTrustHtml(realcarJson(this.email?.informacao));
  }

  get hasParametros(): boolean {
    return !!this.email?.informacao;
  }

  open(email: Email, tab = 0): void {
    this.email = email;
    this.activeTab = tab;
    this.cdr.markForCheck();
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
  }

  copyId(): void {
    if (!this.email) return;
    navigator.clipboard.writeText(this.email.id).then(() => {
      this.notification.success('Código copiado!');
    });
  }

  onClose(): void {
    this.activeTab = 0;
    this.closed.emit();
  }

  onReenviar(): void {
    if (!this.email) return;
    this.isResending = true;
    this.cdr.markForCheck();
    this.reenviar.emit(this.email.id);
  }

  resetResending(): void {
    this.isResending = false;
    this.cdr.markForCheck();
  }

}
