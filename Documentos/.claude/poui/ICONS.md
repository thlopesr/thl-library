## SEÇÃO 12 — ICONS.md

### 12.1 Ícones do PO-UI (Animalia)
- **Status atual (v21.x):** a biblioteca POIcon (`po-icon-*`) foi **depreciada e removida na v21.x.x**. O guia oficial de *deprecations* do po-angular registra: "A partir da v21, a biblioteca de ícones POIcon foi removida. O conjunto padrão de ícones passa a ser a lib Animalia Icons". A recomendação oficial é a **Animalia Icons**, prefixo `an an-<nome>`.
- **Uso em componente PO:** `p-icon="an an-user"`. Ex. verbatim da doc: `<po-input p-icon="an an-user" p-label="PO input"></po-input>`. Também: `<po-button p-icon="an an-floppy-disk" p-label="Salvar"></po-button>`.
- **Uso via classe CSS** (elemento `<i>`): `<i class="an an-user"></i>`. Variante preenchida (fill): `<i class="an-fill an-user"></i>`.
- **Migração POIcon → Animalia** (exemplo verbatim do `deprecations.md`): `<i class="po-icon po-icon-user"></i>` → `<i class="an an-user"></i>`.
- **Uso via TemplateRef** (ícone customizado):
  ```html
  <po-input [p-icon]="template" p-label="input template"></po-input>
  <ng-template #template><i class="an an-arrow-fat-line-down"></i></ng-template>
  ```
- **Instalação:** `npm i @animaliads/animalia-icon`.
- **Prefixos legados:**
  - `po-icon-*` → **removido na v21.x**; não funciona.
  - `ph ph-*` (Phosphor) → prefixo intermediário; a Animalia herda a convenção de nomes do Phosphor (kebab-case), mas o prefixo atual é `an`. Em projetos v21, usar `an an-*`.
- **Categorias** (navegador de ícones em po-ui.io/icons — SPA): ação (plus, pencil-simple, trash, floppy-disk), navegação (arrow-left, caret-*, list), status/feedback (check, warning, x-circle, info), arquivo (file-*, folder-*, download, upload), comunicação (envelope, chat, phone), usuário (user, user-circle), dados/ERP (table, warehouse, credit-card, calendar-*).

### 12.2 Ícones externos (Font Awesome / Phosphor)
- **Sim, o PO-UI suporta ícones externos.** Fonte oficial (comentários de `po-modal`/`po-input`/`po-button`): "Também é possível utilizar outras fontes de ícones, por exemplo a biblioteca Font Awesome".
- **Font Awesome:** incluir o CSS no `index.html` e usar o prefixo `fa`:
  ```html
  <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.3.1/css/all.css" crossorigin="anonymous" />
  ```
  ```html
  <po-button p-icon="fa fa-check-circle" p-label="Confirm"></po-button>
  ```
- **Phosphor:** pode ser incluído do mesmo modo (webfont, prefixo `ph ph-*`) ou via `@fortawesome/angular-fontawesome` como componente Angular. **Recomendação:** como o PO-UI 21 já embarca a Animalia (que usa a convenção Phosphor), prefira `an an-*` e reserve fontes externas para ícones inexistentes na Animalia.

### 12.3 Mapeamento ação → ícone (ERP)
Nomes base confirmados no catálogo Phosphor (do qual a Animalia deriva a convenção; prefixar com `an `). Onde havia equivalente aproximado na antiga POIcon, indicado como referência de migração.

| Ação | Animalia (atual) | Legado POIcon (removido v21) |
|------|------------------|------------------------------|
| Novo/Criar | `an an-plus` (ou `an an-plus-circle`) | `po-icon-plus` |
| Editar | `an an-pencil-simple` | `po-icon-edit` |
| Excluir | `an an-trash` | `po-icon-delete` |
| Visualizar/Detalhe | `an an-eye` | `po-icon-eye` |
| Buscar/Pesquisar | `an an-magnifying-glass` | `po-icon-search` |
| Filtrar | `an an-funnel` | `po-icon-filter` |
| Salvar | `an an-floppy-disk` | *(sem ícone dedicado 1:1)* |
| Cancelar/Fechar | `an an-x` (ou `an an-x-circle`) | `po-icon-close` |
| Voltar | `an an-arrow-left` (ou `an an-caret-left`) | `po-icon-arrow-left` |
| Atualizar/Refresh | `an an-arrows-clockwise` (ou `an an-arrow-clockwise`) | `po-icon-refresh` |
| Exportar | `an an-export` | `po-icon-export` |
| Imprimir | `an an-printer` | `po-icon-print` |
| Configurações | `an an-gear` (ou `an an-gear-six`) | `po-icon-settings` |
| Duplicar/Copiar | `an an-copy` (ou `an an-copy-simple`) | `po-icon-copy` |
| Download | `an an-download` (ou `an an-download-simple`) | `po-icon-download` |
| Upload | `an an-upload` (ou `an an-upload-simple`) | `po-icon-upload` |
| Expandir/Colapsar | `an an-caret-down` / `an an-caret-up` / `an an-caret-right` | `po-icon-arrow-down`/`-up` |
| Usuário/Perfil | `an an-user` (ou `an an-user-circle`) | `po-icon-user` |

> Os nomes base (`plus`, `pencil-simple`, `trash`, `magnifying-glass`, `funnel`, `floppy-disk`, `x`, `arrow-left`, `arrows-clockwise`, `export`, `printer`, `gear`, `copy`, `download`, `upload`, `caret-*`, `user`) são todos ícones padrão do Phosphor. `an an-plus`, `an an-pencil-simple` e `an an-trash` estão **confirmados em código-fonte oficial** do po-angular. Os demais são altamente prováveis na Animalia (mesma convenção), mas devem ser confirmados no navegador de ícones antes do uso em produção. Os nomes `po-icon-*` servem apenas como mapa de migração — não funcionam na v21.

---

## REFERÊNCIA RÁPIDA — Componentes por categoria

| Categoria | Componente | Quando usar |
|-----------|-----------|-------------|
| Input texto | `po-input` | Texto livre; suporta `p-mask` (CPF/CNPJ/telefone) e `p-icon` |
| Input número inteiro | `po-number` | Quantidades, inteiros |
| Input decimal/moeda | `po-decimal` | Valores monetários/decimais (`p-decimals-length`) |
| Senha | `po-password` | Campos de senha |
| Área de texto | `po-textarea` | Observações, textos longos |
| Rich text | `po-rich-text` | Conteúdo formatado (HTML) |
| Seleção única (poucas) | `po-radio-group` | ≤3 opções, escolha única |
| Seleção múltipla (poucas) | `po-checkbox-group` | ≤3 opções, múltipla |
| Combo estático | `po-select` | Lista fixa, escolha única |
| Combo com busca/API | `po-combo` | Carga dinâmica via `p-filter-service`/muitas opções |
| Seleção múltipla | `po-multiselect` | Múltiplos valores (ex.: filtro de status) |
| Lookup/Zoom | `po-lookup` | Campo relacionado com modal (`p-filter-service`, `p-columns`, `p-advanced-filters`) |
| Liga/desliga | `po-switch` | Booleano com rótulo on/off |
| Checkbox único | `po-checkbox` | Aceite/flag isolado |
| Data | `po-datepicker` | Data única |
| Período | `po-datepicker-range` | Intervalo de datas (`[inicio, fim]`) |
| Arquivo | `po-upload` | Upload de arquivos |
| Exibição leitura | `po-info` | Par label/valor somente leitura; totalizadores |
| Exibição dinâmica | `po-dynamic-view` | Detalhe orientado a metadados (`p-fields`, `p-value`) |
| Formulário dinâmico | `po-dynamic-form` | Form gerado de `PoDynamicFormField[]` |
| Tabela | `po-table` | Colunas tipadas, ações, `p-show-more` (paginação), `type: 'label'` |
| Lista visual | `po-list-view` | Cards/itens com layout customizado |
| Página com filtro | `po-page-list` | Listagem com busca + disclaimers + ações |
| Página padrão | `po-page-default` | Formulário/detalhe com breadcrumb e ações |
| Página edição | `po-page-edit` | Formulário com ações Salvar/Cancelar padronizadas |
| Tabela dinâmica | `po-page-dynamic-table` | CRUD list metadata-driven (`p-service-api`) |
| Edição dinâmica | `po-page-dynamic-edit` | Create/edit metadata-driven |
| Detalhe dinâmico | `po-page-dynamic-detail` | Visualização metadata-driven |
| Busca dinâmica | `po-page-dynamic-search` | Filtros avançados metadata-driven |
| Navegação | `po-menu` | Menu lateral |
| Navegação | `po-breadcrumb` | Trilha de navegação |
| Navegação | `po-tabs`/`po-tab` | Cadastro/detalhe multi-seção |
| Navegação | `po-toolbar` | Barra superior |
| Navegação | `po-stepper` | Fluxo em etapas |
| Modal | `po-modal` | Diálogos, form de item (`p-primary-action`/`p-secondary-action`) |
| Modal | `po-page-slide` | Painel lateral deslizante |
| Feedback | `po-notification` (service) | Toasts de sucesso/erro/aviso/info |
| Feedback | `po-dialog` (service) | Confirmação/alerta (`.confirm()`, `.alert()`) |
| Feedback | `po-loading` / `po-loading-overlay` | Indicadores de carregamento |
| Feedback | `po-disclaimer` / `po-disclaimer-group` | Chips de filtros ativos |
| Layout | `po-widget` | Agrupador visual (card) de conteúdo |
| Status | `po-tag` | Etiquetas de status coloridas |

---
