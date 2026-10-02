# App web (`Fontes\web\`)

> Nota criada em 2026-09-24 (lacuna L3/L9 do diagnóstico). Referência de componentes PO UI genéricos: [poui/INDEX.md](../poui/INDEX.md). Camadas: [arquitetura.md](../arquitetura.md).

**Stack:** Angular `^21.2.0`, PO UI (`@po-ui/ng-components` / `ng-templates`) `^21.30.1`, TypeScript `~5.9.2`. Gerado com Angular CLI 21.2.

**Finalidade:** monitores web da THL (mensageria, e-mail, auditoria e métricas) e telas de cadastro (thl0001 Ambiente, thl0002 Parâmetro), consumindo o endpoint REST da própria biblioteca.

**Dois apps no mesmo workspace (2026-09-25)** — consulta e cadastro separados, como as seções do menu Datasul (consulta / cadastro / tarefa / relatório):

| Projeto (`angular.json`) | Entrada | Root / rotas | Pacote Datasul | Dev |
|---|---|---|---|---|
| `web` (consulta) | `src\main.ts` | `app.ts` · `app.routes.ts` | `build-deploy.ps1` → `dist\thl-html-consulta` (`html.mensageria`, `html.menu`) | `mensageria-dev`, porta 4200 |
| `cadastro` | `src\main-cadastro.ts` | `app-cadastro.ts` · `cadastro.routes.ts` (reusa `app.html`/`app.css`) | `build-deploy-cadastro.ps1` → `dist\thl-html-cadastro` (`html.cadastro`, `html.menu`) | `cadastro-dev`, porta 4201 |

Com dois projetos, `ng serve`/`ng build` **exigem o nome do projeto** (`package.json`: `start`/`build` = `web`, `start:cadastro`/`build:cadastro`).

> Decisões estruturais (dois apps, motor, standalone, mock) e o porquê de cada uma: [adr/arquitetura-front-end-web.md](../adr/arquitetura-front-end-web.md).

## 1. Integração com o backend

Os serviços de consulta chamam `${window.location.origin}/api/thl/integration/v1/resourcen/<rota>` (endpoint `Fontes\thl\integration\api\v1\resourcen.p`), sempre por **GET**:

| Rota | Mensagem inbound | Service ERP |
|---|---|---|
| `…/resourcen/mensageria` | `MensageriaMessage` | `MensageriaService:get(...)` |
| `…/resourcen/mensageria/conteudo` | `MensageriaMessage` (operação `conteudo`) | `MensageriaConteudoService:get( id, tipo )` — resposta lida como texto |
| `…/resourcen/email` | `EmailMessage` | `EmailService:get(...)` |
| `…/resourcen/auditoria` | `AuditoriaMessage` | `AuditoriaService:get(...)` |

Os filtros vão como query params (os mesmos nomes de `messaging-inbound.md`, por exemplo `codigoIni/Fin`, `dtCriacaoIni/Fin`, `pageSize`, `page`).

**App cadastro** — CRUD na API dos cadastros ([extensions/thl.md](../extensions/thl.md)):

| Rota API | Definição (`cadastros.defs.ts`) | Operações usadas | Filtro do GET |
|---|---|---|---|
| `…/resourcen/ambiente` | `ambienteDef` | GET, POST, PATCH, DELETE | — |
| `…/resourcen/parametro-ambiente` | `parametroDef` | GET, POST, PATCH, DELETE | — |
| `…/resourcen/parametro-variavel` | filho de `parametroDef` | GET, POST, PATCH, DELETE | `parametroIni/Fin` |
| `…/resourcen/parametro-programa` | filho de `parametroDef` (`noUpdate`) | GET, POST, DELETE (sem PATCH na API) | `parametroIni/Fin` |

Todas as chamadas passam pelo `CrudService` do motor genérico (não há mais service por recurso). DELETE leva a chave no **corpo JSON** (`http.delete(url, { body })`), não em query string. Variável sensível volta `********` no GET; o modal reenvia `********` e o backend mantém o valor.

⚠️ **Rotas vigentes (confirmado pelo responsável em 2026-10-01):** `parametro-ambiente`, `parametro-variavel` e `parametro-programa`, como na coleção **Nitro** do Postman (nuvem; as cópias em `Utils\postman` foram removidas em 2026-10-01). Alinhados no mesmo dia: `Utils\scripts\carga-thl-api-cadastros.p`, [extensions/thl.md](../extensions/thl.md), a ADR [api-rest-cadastros-thl.md](../adr/api-rest-cadastros-thl.md) (decisão nº 1 revista), [thl/camada-datasul.md](../thl/camada-datasul.md) e o comentário de cabeçalho das classes `Parametro*Message.cls` — não resta menção aos nomes antigos (`parametro`, `parametroVariavel`, `parametroPrograma`) fora do histórico. Ambiente onde a carga já rodou com os nomes antigos: a carga não renomeia — ajustar `thl-inbound-rota.rota-publica` das rotas `THL-PARAMETRO*`.

**Desenvolvimento local:** `proxy.conf.json` encaminha `/api` para um servidor PASOE/Tomcat do cliente (HTTPS, `secure: false`); `.claude\launch.json` sobe `ng serve web` (4200) e `ng serve cadastro` (4201). O cadastro em `development` usa backend **mock em memória** (`src\app\mock\cadastro-mock.interceptor.ts`, via `fileReplacements` de `mock-interceptors.ts` → `mock-interceptors.dev.ts`); o build de produção não inclui o mock.
**Deploy:** `build-deploy.ps1` faz `ng build web --configuration production` e monta a pasta `dist\thl-html-consulta`; `build-deploy-cadastro.ps1` faz o mesmo para `cadastro` (`dist\thl-html-cadastro`). Ambos no formato de menu HTML TOTVS para o webapps do Tomcat do Datasul. O `dist` fica só com essas duas pastas: não há zip e a saída bruta do build (`dist\web`, `dist\cadastro`) é apagada ao final. `-DeployPath` copia a pasta para o webapps (substitui as subpastas `html.*` existentes).

## 2. Rotas (`app.routes.ts`)

| Caminho | Carrega | Pasta |
|---|---|---|
| `''` | `metricasRoutes` → `MetricasComponent` | `metricas\` |
| `dashboard-mensageria` | `DashboardComponent` (painel de integrações, `loadComponent`) | `mensageria\pages\dashboard\` |
| `mensageria` | `mensageriaRoutes` → `MensagemListComponent` | `mensageria\` |
| `email` | `emailRoutes` → `EmailListComponent` | `email\` |
| `auditoria` | `auditoriaRoutes` → `AuditoriaListComponent` | `auditoria\` |

Rotas do app **cadastro** (`cadastro.routes.ts`): `''` → redireciona para `ambiente`; depois uma rota por cadastro, todas carregando o `ThlCrudPageComponent` com a definição em `data: { def }`: `ambiente`, `parametro`, `grupo-email`, `email`, `objeto`, `conexao`, `path`, `rota`, `auditoria`. Não há rotas `new`/`edit`: incluir e editar são em modal, e os filhos aparecem na linha expandida do browse.

**Menu do app cadastro (`app-cadastro.ts` + `app-cadastro.css`, decisão de 2026-10-01):** `po-menu` recolhido, lista **plana** com ícone em todos os itens: Ambiente, Parâmetro, Grupo de e-mail, E-mail · Objeto, Conexão, Path, Rota · Auditoria. A separação dos grupos é só visual, por CSS (`::ng-deep` + `:has()` ancorado no `href` do 1º item de cada grupo): aberto mostra os títulos **Configuração / Integração / Auditoria**; recolhido (`app-root.po-collapsed-menu`) mostra uma linha fina entre os grupos. Item novo que inicia grupo → incluir o `href` no `app-cadastro.css`. O `po-menu` não tem divisor nativo; se a estrutura interna dele mudar, some só a separação.

**Motor genérico de cadastros (`shared\crud\`, 2026-10-01)** — **nenhum cadastro tem componente próprio**: cada um é uma definição `CrudResource` em `cadastros\cadastros.defs.ts`, e a rota passa a definição em `data: { def }` para o `ThlCrudPageComponent`. O motor cuida de browse, coluna "Ação", formulário, Detalhar, abas de filhos, estado de erro e contador.

> **O contrato completo — `CrudResource`, `CrudField`, regras, domínios, cadastros em uso e pendências da v2 — está em [motor-cadastro.md](motor-cadastro.md).**
> As armadilhas do PO UI que moldaram essas decisões estão em [poui-licoes.md](poui-licoes.md).

| Peça | Papel |
|---|---|
| `crud.model.ts` | `CrudResource`, `CrudField`, `CrudOption`, `CrudListResult` |
| `crud.service.ts` | `list` (devolve `{ items, total, hasNext }`), `create`, `update` (PATCH), `delete` com a chave no corpo |
| `thl-crud-list` | Browse, coluna "Ação", formulário e Detalhar em modal, estado de erro |
| `thl-crud-children` | Card da linha expandida, uma aba por filho com contador |
| `thl-crud-page` | Cabeçalho com contador + filtro local + "Adicionar" + lista |

**Modelo de browse pai + filhos (2026-09-30)** — desenho que o motor implementa (cabeçalho com busca e "Adicionar", linha expandida em card com `po-tabs` por filho, estado vazio por aba). Detalhado em [motor-cadastro.md](motor-cadastro.md#modelo-de-browse-pai--filhos).

## Padrão comum aos dois apps (2026-10-02)

- **Rótulos de situação** ficam em [`shared/domain/status-labels.ts`](../../../Fontes/web/src/app/shared/domain/status-labels.ts) (`STATUS_LABELS`, `STATUS_EMAIL_LABELS`, `OPERACAO_LABELS`), usados pelas colunas `type: 'label'` dos monitores. No `PoTableColumnLabel`, **`value` casa com o dado e `label` é o texto exibido** — estavam invertidos nos três monitores, que mostravam `1`/`2`/`3` no lugar de Sucesso/Erro/Pendente e de Criação/Atualização/Deleção.
- **Falha no carregamento** mostra a mensagem do backend e **Tentar novamente** no lugar da tabela, nos monitores e no motor de cadastro. Só a mensagem do corpo da resposta é exibida; a do `HttpErrorResponse` é técnica demais.
- **Ações da linha** em coluna "Ação" com `thl-row-actions` (`type: 'cellTemplate'`), não no `p-actions` do `po-table`.
- Templates novos usam o controle de fluxo do Angular (`@if`), não `*ngIf`.

## Observações

- `mensageria\services\` tem dois serviços para a mesma rota da API: `mensagem.service.ts` (lista/conteúdo) e `mensageria.service.ts` (`MensageriaDashboardService`, painel) — candidatos a unificar.
- ⚠️ **Testes não executáveis:** existem `.spec.ts` (Jasmine), mas não há alvo `test` no `angular.json` nem biblioteca de teste no `package.json`.
- `src\app\dashboard\` não está em nenhuma rota.
- `.claude\launch.json` na raiz e `Fontes\web\.claude\launch.json` duplicam a configuração do dev server.
- `node_modules\`, `dist\` e `.angular\` são ignorados pelo `Fontes\web\.gitignore`; nada de `Fontes\web\` está versionado hoje.
