import { Component, Input, OnChanges } from '@angular/core';
import { PoModule, PoTableColumn } from '@po-ui/ng-components';
import { Auditoria, SnapshotRow } from '../../models/auditoria.model';

@Component({
  selector: 'app-auditoria-detail',
  standalone: true,
  imports: [PoModule],
  templateUrl: './auditoria-detail.component.html',
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
export class AuditoriaDetailComponent implements OnChanges {
  @Input() auditoria!: Auditoria;
  @Input() activeTab = 0;

  snapshotRows: SnapshotRow[] = [];
  isAtualizacao = false;

  snapshotColumns: PoTableColumn[] = [];

  ngOnChanges(): void {
    if (!this.auditoria) return;
    this.isAtualizacao = this.auditoria.operacao === 'Atualizacao';
    this.buildSnapshotRows();
    this.buildSnapshotColumns();
  }

  getOperacaoColor(): string {
    switch (this.auditoria.operacao) {
      case 'Criacao': return 'color-10';
      case 'Atualizacao': return 'color-08';
      case 'Delecao': return 'color-07';
      default: return 'color-12';
    }
  }

  getProgramaTexto(): string {
    if (!this.auditoria.programaExecutado) return '(vazio)';
    return this.auditoria.programaExecutado
      .split(' | ')
      .map(s => s.trim())
      .join('\n');
  }

  private buildSnapshotColumns(): void {
    if (this.isAtualizacao) {
      this.snapshotColumns = [
        { property: 'campo', label: 'Campo' },
        { property: 'valorAnterior', label: 'Valor Anterior' },
        { property: 'valorAtual', label: 'Valor Atual' }
      ];
    } else {
      this.snapshotColumns = [
        { property: 'campo', label: 'Campo' },
        { property: 'valorAtual', label: 'Valor' }
      ];
    }
  }

  private buildSnapshotRows(): void {
    const atual = this.extractFields(this.auditoria.snapshotAtual);
    const anterior = this.extractFields(this.auditoria.snapshotAnterior);

    const allKeys = new Set<string>([...Object.keys(atual), ...Object.keys(anterior)]);

    this.snapshotRows = Array.from(allKeys).map(campo => ({
      campo,
      valorAnterior: this.formatValue(anterior[campo]),
      valorAtual: this.formatValue(atual[campo])
    }));
  }

  private extractFields(snapshot: any): Record<string, any> {
    if (!snapshot || typeof snapshot !== 'object') return {};
    const keys = Object.keys(snapshot);
    if (keys.length === 0) return {};
    const arr = snapshot[keys[0]];
    if (Array.isArray(arr) && arr.length > 0 && typeof arr[0] === 'object') {
      return arr[0] ?? {};
    }
    return {};
  }

  private formatValue(value: any): string {
    if (value === undefined || value === null) return '';
    if (typeof value === 'object') return JSON.stringify(value);
    return String(value);
  }
}
