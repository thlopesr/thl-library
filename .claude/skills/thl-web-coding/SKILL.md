---
name: thl-web-coding
description: "Implementar, corrigir e refatorar Angular e PO UI em Fontes/web, incluindo motor de cadastro, monitores e integração REST. Use thl-poui-design para especificação de UX e thl-web-qa para auditoria e regressão."
---

# thl-web-coding — código Angular + PO UI da THL-Library

## Escopo e evidências

Siga o `AGENTS.md` da raiz. Análise, revisão e diagnóstico registram achados; não autorizam alterações em código, mock ou documentação. Ao implementar uma mudança autorizada, sincronize apenas as notas afetadas. Declare como cada conclusão foi verificada e o que permanece pendente.

Você é desenvolvedor front-end sênior em **Angular 21 + PO UI 21 + tema TOTVS** e implementa telas em `Fontes\web\`. Se não houver especificação da tela, faça as perguntas mínimas ou sugira passar antes pela `thl-poui-design`.

Antes de codar, leia `Documentos\.claude\web\app-web.md` (estado atual do app). Conforme a tarefa, leia também:

| Tarefa | Leia antes |
|---|---|
| Qualquer cadastro | [`web\motor-cadastro.md`](../../../Documentos/.claude/web/motor-cadastro.md) — contrato do motor |
| Qualquer tela PO UI | [`web\poui-licoes.md`](../../../Documentos/.claude/web/poui-licoes.md) — armadilhas já verificadas |
| Chamada de API | `integration\messaging-inbound.md` — query params de cada rota |

## Stack

- Angular `^21.2` (standalone, `bootstrapApplication` com `app.config.ts`: `provideRouter(routes, withHashLocation())`, `provideHttpClient(withInterceptorsFromDi())`, `provideAnimations()`, `PoHttpInterceptorModule`).
- `@po-ui/ng-components` / `@po-ui/ng-templates` `^21.30.1`; tema `@totvs/po-theme` (CSS em `angular.json`); TypeScript `~5.9`.
- Bibliotecas TOTVS não instaladas (`dts-backoffice-util`, `dts-backoffice-kendo-grid`): não importar sem o usuário aprovar a instalação e a compatibilidade com Angular 21.

## Padrões obrigatórios

### Estrutura (decisão do projeto: **standalone por feature**)
```text
src/app/<feature>/
├── <feature>-routing.ts         export const <feature>Routes: Routes = [{ path: '', loadComponent: () => import(...) }]
├── pages/<nome>/<nome>.component.{ts,html,scss,spec.ts}
├── components/<nome>/...        (filtro avançado, modais da feature)
├── models/<nome>.model.ts
└── services/<nome>.service.ts
src/app/shared/components/thl-<nome>/   componentes reutilizáveis (+ index.ts)
```
- Componentes **standalone** (`imports: [...]` no próprio componente); rota registrada em `app.routes.ts` com `loadChildren: () => import('./<feature>/<feature>-routing').then(m => m.<feature>Routes)`.
- **Não criar `NgModule`.** A pasta legada `modules\` foi migrada e removida em 2026-09-24; o último resíduo (`mensageria\mensageria.module.ts`, sem importadores) saiu em 2026-10-09. **Não há nenhum `@NgModule` no projeto** — encontrar um é sinal de código morto ou de desvio do padrão. Os componentes órfãos (`src/app/dashboard`, `mensageria/pages/dashboard-mensageria` e o service dela) foram removidos em 2026-10-08: toda pasta em `pages/` deve ter rota.

### Codificação e estilo
- **Fontes web (`.ts`, `.html`, `.scss`, `.json`) em UTF-8 sem BOM com LF** — padrão Angular/Node. (A regra ISO-8859-1 do projeto vale só para fontes ABL.)
- Nomes: arquivos kebab-case (`mensagem-list.component.ts`), classes PascalCase, propriedades/métodos camelCase em inglês; textos da UI em pt-BR.
- `inject()` para dependências; `readonly` para URLs; tipagem estrita (sem `any` em modelos de API).
- Seguir `.editorconfig`/`.prettierrc` do projeto.

### Acesso ao backend
- URL sempre relativa à origem: `` `${window.location.origin}/api/thl/integration/v1/resourcen/<rota>` `` — nunca host fixo. Em dev, `proxy.conf.json` encaminha `/api`.
- Filtros e paginação como `HttpParams` com os nomes exatos dos query params da mensagem inbound (`codigoIni`, `dtCriacaoIni`, `page`, `pageSize`…); datas em ISO.
- Resposta de listas: `interface ApiResponse<T> { total: number; hasNext: boolean; items: T[] }`; tratar também resposta sem `items`.
- Erros: a falha de carregamento mostra a **mensagem do backend com botão "Tentar novamente"** no lugar da tabela — nunca deixar erro parecer lista vazia. Use `thl-error-state` (erro) e `thl-empty-state` (vazio) de `shared\components`, nunca um bloco novo: as cópias inline que existiam até 2026-10-09 referenciavam classes (`.thl-erro`, `.empty-container`) que nunca tiveram estilo. Zerar a lista no ramo `error` é o defeito clássico — a falha passa a afirmar que não há dados. Exiba só `error.message` do corpo da resposta; a mensagem do `HttpErrorResponse` é técnica demais para o usuário. O `PoHttpInterceptor` ainda mostra a notificação dele, que é complementar.
- Nos monitores, services em `<feature>/services`; nos cadastros, reutilize o `CrudService` comum do motor; nunca chamar `HttpClient` direto no componente.

### Componentes e UI
- Reutilizar `thl-page-header`, `thl-search-bar`, `thl-filter-tabs`, `thl-stat-chips` e os templates PO UI (`po-page-list`, `po-table`, `po-modal`, `po-disclaimer-group`, `po-info`…) conforme a especificação.
- Reutilizar também o `thl-row-actions` na coluna "Ação" (`type: 'cellTemplate'`) — é o padrão nos dois apps, mesmo com uma única ação.
- **Rótulos de situação ficam em `shared\domain\status-labels.ts`** (`STATUS_LABELS`, `STATUS_EMAIL_LABELS`, `OPERACAO_LABELS`). A API devolve texto (`Sucesso`, `Erro`, `Pendente`, `N/A`), não o código numérico. No `PoTableColumnLabel`, **`value` casa com o dado e `label` é o texto exibido** — inverter os dois não quebra nada e faz a coluna mostrar o conteúdo errado (foi defeito real nos três monitores até 2026-10-02).
- Estados de carregando, vazio **e erro** implementados, os três distintos entre si.
- Templates novos usam `@if`/`@for`, não `*ngIf`/`*ngFor`.

### Testes, build e deploy
- Testes proporcionais ao risco e ao escopo. Hoje não há alvo `test` nem runner instalado: não crie specs apenas para cumprir quantidade, nem configure um runner fora do escopo. Quando houver specs pertinentes, use standalone em `imports` do `TestBed`; distinga teste escrito de teste executado. Valide alterações web com `npx ng build web` e `npx ng build cadastro`.
- Dois apps separados, como as seções do menu Datasul: **`web`** (consulta/monitor — `main.ts`, `app.ts`, `app.routes.ts`) e **`cadastro`** (`main-cadastro.ts`, `app-cadastro.ts`, `cadastro.routes.ts`). Tela de cadastro nunca entra no menu/rotas da consulta, e vice-versa. O app `cadastro` não tem pastas de feature: todos os cadastros são definições do motor genérico (`shared\crud\` + `cadastros\cadastros.defs.ts`); `shared\` é comum aos dois apps.
- Build de produção e pacote: `.\build-deploy.ps1` (consulta → pasta `dist\thl-html-consulta`) e `.\build-deploy-cadastro.ps1` (cadastro → pasta `dist\thl-html-cadastro`). Os scripts não geram zip e apagam a saída bruta do `ng build` (`dist\web`, `dist\cadastro`) ao final; `-DeployPath` copia a pasta para o webapps. Dev: configs `mensageria-dev` (4200) e `cadastro-dev` (4201) em `.claude\launch.json`.
- **Cadastro novo = definição, não componente** (a comparação medida — bundle, runtime e quando abrir exceção — está em [`web\motor-cadastro.md`](../../../Documentos/.claude/web/motor-cadastro.md))**:** acrescente um `CrudResource` em `src\app\cadastros\cadastros.defs.ts`, a rota em `cadastro.routes.ts` (`cadastro('<path>', <def>)`), o item em `app-cadastro.ts` e os dados em `mock\cadastro-mock.data.ts`. O motor (`shared\crud\`) cuida de browse, coluna "Ação", formulário, detalhe e abas de filhos — ver `Documentos\.claude\web\app-web.md`.
- Backend mock do cadastro: `src\app\mock\cadastro-mock.interceptor.ts` (em memória, CRUD completo). Só entra no build `development` via `fileReplacements` (`mock-interceptors.ts` → `mock-interceptors.dev.ts`); nunca importar o interceptor direto. Para usar o PASOE real no `ng serve cadastro`, rode com `--configuration production` sem remover o `fileReplacements` da configuração compartilhada apenas para testar.
- `node_modules\`, `dist\`, `.angular\` nunca versionados.

### Armadilhas do PO UI (verificadas no projeto)

Lista completa em [`web\poui-licoes.md`](../../../Documentos/.claude/web/poui-licoes.md). As que mais aparecem:

- `po-dynamic-form` **não** renderiza `po-email`, `po-url` nem `po-rich-text` — só os tipos do `PoDynamicFieldType`. Campo que precise deles sai do formulário dinâmico.
- `icon` só funciona em `po-input`/`po-combo`; `readonly` só em `po-input`/`po-combo`/`po-textarea`/`po-rich-text`. `placeholder` funciona em todos.
- `type: 'label'` do `po-table` esconde a célula quando o valor não está no domínio — sempre prever um rótulo de fallback com o valor cru.
- Em `PoTableColumnLabel`, `type` semântico **sobrepõe** cor e ícone; para manter ícone próprio use `color`.
- `po-table` dentro de `po-tab` oculto não desenha: renderizar só a aba ativa.
- `po-rich-text` propaga o modelo no `keyup`/blur/comando, não a cada tecla; com `p-readonly` a barra continua visível (esconder todas as ações para sumir com ela).
- `::ng-deep` é obrigatório para estilizar conteúdo vindo de `[innerHTML]`.

## Tarefas
1. Implementar tela a partir da especificação da `thl-poui-design`.
2. Criar service + model para uma rota `resourcen/<rota>`.
3. Criar/estender componente `shared/components/thl-*`.
4. Refatorar código para o padrão standalone por feature.
5. Code review: `[ISSUE] arquivo.ts:linha — descrição → correção`.
6. Diagnosticar erro de build/execução/proxy.

Ao terminar, informe se algo exige backend (query param/campo inexistente → `thl-coding`) e atualize a documentação: `web\app-web.md` (rotas, serviços, componentes compartilhados), `web\motor-cadastro.md` (contrato ou regras do motor) e `web\poui-licoes.md` (comportamento do PO UI descoberto na marra — essa nota só vale se registrar o que foi confirmado rodando).

## Saída
Código completo (TS + HTML + SCSS + spec quando aplicável); explicações em português do Brasil.
