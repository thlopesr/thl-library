---
tipo: guia
camada: ambos
status: referencia
tags: [po-ui, referencia, web]
updated: 2026-10-13
---

# SEÇÃO 8 — MODAIS E DIÁLOGOS (MODALS.md)

## 8.1 po-modal

**Propriedades:** `p-title`, `p-size` (`sm`, `md`, `lg`, `xl`, `auto`), `p-hide-close`, `p-click-out`, `p-primary-action`, `p-secondary-action`. Conforme o `po-modal-base.component.ts`: "Quando informado `auto` a modal calculará automaticamente seu tamanho baseado em seu conteúdo. Caso não seja informado um valor, a modal terá o tamanho definido como `md`." "É possível fechar a modal através da tecla ESC, quando a propriedade `p-hide-close` não estiver habilitada."

**Interface PoModalAction (verbatim do fonte):**

```typescript
export interface PoModalAction {
  action: Function;    // função executada ao clicar
  label: string;       // rótulo do botão
  danger?: boolean;    // aplica o tipo "danger" (se em ambos, só o primário recebe)
  disabled?: boolean;  // desabilita o botão
  loading?: boolean;   // exibe estado de carregamento e desabilita
}
```

**Abrir/fechar via @ViewChild:**

```typescript
import { Component, ViewChild } from '@angular/core';
import { PoModalComponent, PoModalAction } from '@po-ui/ng-components';

@Component({ /* ... */ })
export class CadastroRapidoComponent {
  @ViewChild(PoModalComponent, { static: true }) modal: PoModalComponent;

  primaryAction: PoModalAction = { label: 'Salvar', action: () => this.salvar() };
  secondaryAction: PoModalAction = { label: 'Cancelar', action: () => this.modal.close() };

  abrir() { this.modal.open(); }
  salvar() { /* ... */ this.modal.close(); }
}
```

```html
<po-modal #modal p-title="Cadastro Rápido" p-size="md"
  [p-primary-action]="primaryAction"
  [p-secondary-action]="secondaryAction">
  <form>
    <po-input name="nome" p-label="Nome" [(ngModel)]="cliente.nome"></po-input>
  </form>
</po-modal>
```

**Modal de busca avançada:** dentro do `<po-modal>`, combine `po-input`/`po-datepicker-range` (filtros) com uma `po-table` de resultados; use `PoModalAction` para "Pesquisar"/"Fechar". Passe dados setando propriedades do componente antes de `open()`.

**Pegadinha.** O fechamento por ESC/"X" não emite evento próprio (Issue #1217); se precisar reagir ao cancelamento, use `p-hide-close` e trate o cancelamento por botão.

📚 https://po-ui.io/documentation/po-modal

## 8.2 po-dialog (PoDialogService)

**Explicação técnica.** Serviço injetável (`inject(PoDialogService)` ou construtor). `alert()` = alerta simples; `confirm()` = confirmação Sim/Não.

```typescript
import { Component, inject } from '@angular/core';
import { PoDialogService } from '@po-ui/ng-components';

export class ClienteListComponent {
  private poDialog = inject(PoDialogService);

  confirmarExclusao(id: string) {
    this.poDialog.confirm({
      title: 'Confirmar exclusão',
      message: 'Deseja realmente excluir o registro?',
      confirm: () => this.excluir(id),
      cancel: () => { /* opcional */ }
    });
  }

  alertaConcluido() {
    this.poDialog.alert({
      title: 'Sucesso',
      message: 'Operação concluída.',
      ok: () => { /* opcional */ }
    });
  }
}
```

**Interfaces (campos principais):**
- `PoDialogAlertOptions`: `title`, `message`, `ok?` (callback).
- `PoDialogConfirmOptions`: `title`, `message`, `confirm` (callback), `cancel?` (callback).

📚 https://po-ui.io/documentation/po-dialog

## 8.3 po-disclaimer / po-disclaimer-group

**Interfaces:**
- `PoDisclaimer`: `value: string`, `label?: string`, `property?: string`, `hideClose?: boolean`.
- `PoDisclaimerGroup`: `disclaimers: Array<PoDisclaimer>`, `title?: string`, `hideRemoveAll?: boolean`.

**Eventos do `po-disclaimer-group`:** `(p-change)`, `(p-remove)`, `(p-remove-all)`.

**Padrão completo (filtro avançado → disclaimer → recarrega tabela):**

```html
<po-disclaimer-group
  [p-disclaimers]="disclaimers"
  [p-title]="'Filtros aplicados'"
  (p-change)="onFilterChange($event)"
  (p-remove)="onRemove($event)"
  (p-remove-all)="onRemoveAll()">
</po-disclaimer-group>

<po-table [p-items]="items" [p-columns]="columns"></po-table>
```

```typescript
onFilterChange(disclaimers: PoDisclaimer[]) {
  this.disclaimers = disclaimers;
  this.recarregarTabela(disclaimers);
}
```

Para sincronizar automaticamente filtros ↔ disclaimers, use o `DisclaimerUtil` do dts-backoffice-util (Seção 10.2).

📚 https://po-ui.io/documentation/po-disclaimer-group

## 8.4 po-page-slide — painel lateral

**Propriedades:** `p-title`, `p-subtitle`, `p-size`, `p-hide-close`, `p-click-out`, `p-hide-secondary-actions`.

**Abrir/fechar via @ViewChild (`open()`/`close()`):**

```typescript
import { ViewChild } from '@angular/core';
import { PoPageSlideComponent } from '@po-ui/ng-components';

@ViewChild(PoPageSlideComponent, { static: true }) pageSlide: PoPageSlideComponent;

verDetalhe(item: ICliente) {
  this.itemSelecionado = item;
  this.pageSlide.open();
}
```

```html
<po-page-slide #slide p-title="Detalhe do Registro" p-size="md">
  <po-info p-label="Nome" [p-value]="itemSelecionado?.nome"></po-info>
</po-page-slide>
```

**Uso típico:** exibir o detalhe de um registro sem sair da listagem (mantém contexto da tabela).

📚 https://po-ui.io/documentation/po-page-slide

## 8.5 po-popup — menu contextual

**Interface PoPopupAction:** `label`, `action?`, `icon?`, `visible?`, `disabled?`, `separator?`, `selected?`, `type?`, `url?`.

```html
<po-button p-label="Ações" (p-click)="popup.toggle($event)"></po-button>
<po-popup #popup [p-actions]="acoes"></po-popup>
```

```typescript
acoes = [
  { label: 'Editar', icon: 'an an-pencil-simple', action: this.editar.bind(this) },
  { label: 'Excluir', icon: 'an an-trash', action: this.excluir.bind(this) }
];
```

📚 https://po-ui.io/documentation/po-popup

---
