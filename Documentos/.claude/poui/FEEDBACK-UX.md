---
tipo: guia
camada: ambos
status: referencia
tags: [po-ui, referencia, web]
updated: 2026-10-13
---

# SEÇÃO 9 — FEEDBACK E UX (FEEDBACK-UX.md)

## 9.1 po-notification (PoNotificationService)

**Métodos:** `success()`, `error()`, `warning()`, `information()`.

**Interface PoNotification:** `message`, `duration`, `action`, `actionLabel`, `orientation`, `type`.

**Comportamento (do `po-notification.service.ts`):** notificações do tipo **Error** e aquelas com `action`+`actionLabel` **não** somem automaticamente; as demais são destruídas após `duration`. Orientação via enum `PoToasterOrientation` (`Top`/`Bottom`); tipo via `PoToasterType` (`Success`, `Error`, `Warning`, `Information`).

```typescript
private poNotification = inject(PoNotificationService);

this.poNotification.success('Registro salvo com sucesso!');
this.poNotification.warning('Verifique os campos obrigatórios.');
this.poNotification.error('Erro ao salvar o registro.');
this.poNotification.information('Processamento em andamento.');

// Com ação e orientação:
this.poNotification.success({
  message: 'Registro salvo.',
  duration: 5000,
  orientation: PoToasterOrientation.Bottom,
  actionLabel: 'Desfazer',
  action: () => this.desfazer()
});
```

📚 https://po-ui.io/documentation/po-notification

## 9.2 po-loading-overlay

**Propriedades:** `p-screen-lock`, `p-text`.

```html
<po-loading-overlay *ngIf="carregando" [p-screen-lock]="true" p-text="Carregando..."></po-loading-overlay>
```

**Loading automático via interceptor.** O `po-http-request-interceptor` cria um `PoLoadingOverlayComponent` com `screenLock = true` quando a requisição envia o header `X-PO-Screen-Lock: true`. Requer `provideHttpClient(withInterceptorsFromDi())` e importação do `PoModule`/`PoHttpInterceptorModule`.

📚 https://po-ui.io/documentation/po-loading-overlay

## 9.3 po-loading

Loading inline dentro de componentes. Propriedade `p-text`.

```html
<po-loading p-text="Aguarde"></po-loading>
```

## 9.4 po-progress

**Propriedades:** `p-value` (0–100), `p-info`, `p-status`, `p-text`, `p-size`, `p-indeterminate`.

```html
<po-progress [p-value]="percentual" [p-info]="percentual + '%'" p-status="success"></po-progress>
```

**Exemplo (upload com progresso):** atualize `p-value` conforme o evento `HttpEventType.UploadProgress` do HttpClient.

## 9.5 po-tooltip

Diretiva `p-tooltip` com `p-tooltip-position` (`top`, `right`, `bottom`, `left`). Aplicável a qualquer elemento.

```html
<po-button p-icon="an an-trash" p-tooltip="Excluir" p-tooltip-position="bottom"></po-button>
<span p-tooltip="Informação adicional">ⓘ</span>
```

## 9.6 po-popover

**Diferença tooltip × popover:** o tooltip exibe apenas um texto curto no hover; o popover exibe conteúdo rico e título, com trigger configurável (hover/click).

**Propriedades:** `p-title`, `p-trigger`, `p-position`, `p-target` (ElementRef | HTMLElement), `p-hide-arrow`, `p-append-in-body`, `p-custom-classes`, `(p-open)`, `(p-close)`.

```html
<po-button p-label="Abrir Popover" #btn></po-button>
<po-popover [p-target]="btn" p-title="Informação" p-trigger="click">
  Conteúdo rico do popover
</po-popover>
```

```typescript
@ViewChild(PoButtonComponent, { read: ElementRef, static: true }) btn: PoButtonComponent;
```

📚 https://po-ui.io/documentation/po-popover

## 9.7 po-button / po-button-group

**Propriedades po-button:** `p-label`, `p-icon` (string | TemplateRef), `p-disabled`, `p-loading`, `p-kind`, `p-type` (PoButtonType — comportamento em formulário HTML), `p-danger`, `p-size`, `p-aria-label`, `(p-click)`.

`p-kind` define o estilo (`primary`, `secondary`, `tertiary`); o estilo *danger* é obtido com `p-danger="true"`.

**Exemplo (toolbar de ações Salvar/Cancelar/Excluir):**

```html
<po-button p-label="Salvar" p-kind="primary" p-icon="an an-check" (p-click)="salvar()"></po-button>
<po-button p-label="Cancelar" p-kind="secondary" (p-click)="cancelar()"></po-button>
<po-button p-label="Excluir" p-kind="tertiary" [p-danger]="true" p-icon="an an-trash" (p-click)="excluir()"></po-button>
```

`po-button-group` agrupa botões via `[p-buttons]`.

📚 https://po-ui.io/documentation/po-button

## 9.8 po-dropdown

Menu dropdown de ações. **Interface PoDropdownAction:** `label`, `action?`, `icon?`, `visible?`, `disabled?`, `selected?`, `type?`.

```html
<po-dropdown [p-actions]="acoes" p-label="Mais ações"></po-dropdown>
```

```typescript
acoes = [
  { label: 'Exportar CSV', action: this.exportar.bind(this) },
  { label: 'Imprimir', action: this.imprimir.bind(this) }
];
```

📚 https://po-ui.io/documentation/po-dropdown

## 9.9 Padrões de UX para ERP

- **notification vs dialog** — notification para feedback **não-bloqueante** (salvou, erro pós-operação); dialog para decisões **bloqueantes** que exigem resposta do usuário (confirmar exclusão).
- **loading-overlay vs loading inline** — overlay com `p-screen-lock` para operações que bloqueiam a tela inteira; inline para carregamento de um componente/área específica.
- **Após salvar** → `PoNotificationService.success()`.
- **Erro de validação (regra de negócio/campos)** → `warning()`.
- **Erro de servidor (5xx/indisponível)** → `error()` (ou automático via interceptor).
- **Ação destrutiva** → `PoDialogService.confirm()` antes de executar.
- **Sair de formulário com alterações não salvas** → guard `CanDeactivate` + `confirm()`:

```typescript
canDeactivate(): boolean | Observable<boolean> {
  if (!this.form.dirty) return true;
  return new Observable(observer => {
    this.poDialog.confirm({
      title: 'Alterações não salvas',
      message: 'Deseja sair sem salvar?',
      confirm: () => { observer.next(true); observer.complete(); },
      cancel: () => { observer.next(false); observer.complete(); }
    });
  });
}
```

---
