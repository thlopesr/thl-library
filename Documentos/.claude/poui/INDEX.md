---
tipo: guia
camada: ambos
status: referencia
tags: [po-ui, referencia, web]
updated: 2026-10-13
---

# PO-UI Knowledge Base — Índice Geral

Knowledge base de referência para geração de telas front-end PO-UI (Angular/TypeScript) para o módulo THL no TOTVS Datasul 12.

**Stack:** PO-UI 21.x · Angular 21 · TypeScript 5.9 · Node.js 20.11+
**Tema:** `@totvs/po-theme` (AnimaliaDS)
**Referência externa:** `dts-backoffice-util` é descrito no catálogo, mas não está instalado no projeto; sua adoção exige avaliação de compatibilidade.

> Uso no projeto: [web/app-web.md](../web/app-web.md) (apps de consulta e de cadastro) · motor dos cadastros em [web/motor-cadastro.md](../web/motor-cadastro.md) · camadas em [arquitetura.md](../arquitetura.md) · índice geral em [INDEX.md](../INDEX.md).
>
> ⚠️ **Antes de usar este catálogo, leia [web/poui-licoes.md](../web/poui-licoes.md)**: o que o PO UI **não** faz, confirmado rodando no projeto. As notas aqui descrevem a API documentada; a nota de lições corrige o que a documentação não diz.

---

## Arquivos de referência

| Arquivo | Conteúdo | Quando consultar |
|---------|----------|-----------------|
| [SETUP.md](SETUP.md) | Versões, criação de projeto, pacotes NPM, tema, módulos Angular, proxy local | Iniciar projeto novo, verificar compatibilidade, configurar ambiente |
| [LAYOUT.md](LAYOUT.md) | Grid 12 colunas, classes po-lg/md/sm/xl, containers, exemplos de layout para ERP | Definir layout de formulários e telas |
| [FORM-COMPONENTS.md](FORM-COMPONENTS.md) | Todos os componentes de formulário: input, number, decimal, combo, lookup, datepicker, switch, etc. Propriedades, eventos, exemplos | Criar formulários de cadastro/edição |
| [TABLE-COMPONENTS.md](TABLE-COMPONENTS.md) | po-table (colunas, ações, paginação, ordenação, seleção), po-list-view, po-tree-view | Criar telas de listagem/consulta |
| [PAGE-TEMPLATES.md](PAGE-TEMPLATES.md) | Templates estáticos (po-page-list, po-page-detail, po-page-edit) e dinâmicos (po-page-dynamic-*) | Estruturar páginas CRUD |
| [DYNAMIC-COMPONENTS.md](DYNAMIC-COMPONENTS.md) | po-dynamic-form, po-dynamic-view, PoDynamicFormField, contrato JSON de metadata | Criar telas metadata-driven / dinâmicas |
| [ROUTING.md](ROUTING.md) | Padrão de rotas CRUD, po-menu, po-toolbar, po-breadcrumb, po-tabs, po-stepper, po-accordion | Configurar navegação e organizar conteúdo em abas/seções |
| [MODALS.md](MODALS.md) | po-modal, PoDialogService, po-disclaimer-group, po-page-slide, po-popup | Criar modais, confirmações, filtros com disclaimers |
| [FEEDBACK-UX.md](FEEDBACK-UX.md) | Notificações, loading, progress, tooltip, popover, botões, dropdown, padrões UX para ERP | Implementar feedback visual e UX |
| [SERVICES.md](SERVICES.md) | Serviços PO-UI nativos, dts-backoffice-util (MenuDatasulService, ReportService, RPW, ProfileService, etc.), padrão de Service CRUD | Integrar com Datasul, criar services HTTP |
| [SCREEN-PATTERNS.md](SCREEN-PATTERNS.md) | **7 padrões completos de tela**: Listagem, Cadastro/Edição, Detalhe, Master-Detail, CRUD Dinâmico, Consulta com Filtros, Cadastro com Abas. Código completo de cada arquivo. | **Principal referência para gerar telas THL** |
| [ICONS.md](ICONS.md) | Ícones Animalia (an-icon), mapeamento ação→ícone para ERP | Escolher ícones para ações e menus |
| [I18N.md](I18N.md) | Internacionalização PO-UI, PoI18nService, traduções customizadas, integração idioma Datasul | Configurar i18n |
| [OVERVIEW.md](OVERVIEW.md) | Visão geral da arquitetura PO-UI↔Datasul (front+back). Referência rápida de todas as 13 áreas. | Consulta rápida, entender a arquitetura completa |

---

## Ordem de consulta recomendada por tarefa

### Criar uma tela de cadastro nova

No THL, priorize uma definição no [motor genérico](../web/motor-cadastro.md). Os padrões abaixo são referência genérica; componente próprio só quando o motor não atender ao requisito.
1. [SCREEN-PATTERNS.md](SCREEN-PATTERNS.md) → Padrão 2 (CRUD-CE) como blueprint
2. [FORM-COMPONENTS.md](FORM-COMPONENTS.md) → Componentes específicos dos campos
3. [LAYOUT.md](LAYOUT.md) → Grid e disposição dos campos
4. [ROUTING.md](ROUTING.md) → Rotas e breadcrumb
5. [FEEDBACK-UX.md](FEEDBACK-UX.md) → Notificações e loading

### Criar uma tela de consulta/listagem nova
1. [SCREEN-PATTERNS.md](SCREEN-PATTERNS.md) → Padrão 1 (CRUD-L) como blueprint
2. [TABLE-COMPONENTS.md](TABLE-COMPONENTS.md) → Configuração do po-table
3. [MODALS.md](MODALS.md) → Filtros com disclaimers
4. [PAGE-TEMPLATES.md](PAGE-TEMPLATES.md) → po-page-list
5. [FEEDBACK-UX.md](FEEDBACK-UX.md) → Loading e notificações

### Criar tela master-detail
1. [SCREEN-PATTERNS.md](SCREEN-PATTERNS.md) → Padrão 4 (Master-Detail)
2. [TABLE-COMPONENTS.md](TABLE-COMPONENTS.md) → Tabela de itens
3. [MODALS.md](MODALS.md) → Modal de inclusão/edição de item
4. [FORM-COMPONENTS.md](FORM-COMPONENTS.md) → Campos do formulário mestre e do item

### Criar tela dinâmica (metadata-driven)
1. [SCREEN-PATTERNS.md](SCREEN-PATTERNS.md) → Padrão 5 (CRUD Dinâmico)
2. [DYNAMIC-COMPONENTS.md](DYNAMIC-COMPONENTS.md) → PoDynamicFormField e contrato JSON
3. [PAGE-TEMPLATES.md](PAGE-TEMPLATES.md) → Templates dinâmicos (po-page-dynamic-*)

### Integrar com serviços Datasul
1. [SERVICES.md](SERVICES.md) → MenuDatasulService, ReportService, RPW, ProfileService
2. [OVERVIEW.md](OVERVIEW.md) → Arquitetura geral front↔back

---

## Notas

- **Back-end não está coberto aqui.** APIs REST Progress, PASOE e deploy são tratados separadamente.
- **Versões podem mudar.** O PO-UI segue o major do Angular. Ao atualizar, verificar breaking changes no CHANGELOG do repositório.
- **SCREEN-PATTERNS.md é o arquivo mais importante** — contém blueprints completos prontos para replicar.
- Dados coletados em **setembro/2026**, PO-UI 21.3.0, Angular 21. **Projeto (`Fontes\web\package.json`, 2026-09-24):** `@po-ui/ng-components` `^21.30.1`, `@angular/core` `^21.2.0`, TypeScript `~5.9.2`. Componentes próprios do app: ver [web/app-web.md](../web/app-web.md).
