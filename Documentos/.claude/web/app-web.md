---
tipo: modulo
camada: ambos
status: vigente
tags: [web, po-ui, app-web]
updated: 2026-10-13
---

# App web (`Fontes\web\`)

> **2026-10-08 — URLs dos filhos alinhadas.** O app passou a usar `pai/filho` (`parametro-ambiente/variavel`, `parametro-ambiente/programa`, `objeto/parametro`, `objeto/usuario`, `conexao-rest/autenticacao`, `conexao-rest/header`, `auditoria-tabela/campo|acesso|notificacao|expurgo`, `grupo-email/usuario`), em `cadastros.defs.ts` e no mock. Só mudou o texto do `resource`: o `CrudService` monta a URL por interpolação e aceita a barra sem alteração. Verificado no mock (abas dos cinco agregados carregam, POST e DELETE respondem); **não testado contra o PASOE**.
>
> **2026-10-08 (lote 2) — Rota virou aba do Objeto.** `inbound-rota` deixou de existir no backend: a rota é operação do objeto (`objeto/rota`), uma por objeto, com chave `aplicacao` + `objeto`. No app ela saiu do menu e das rotas de topo e virou a terceira aba do Objeto (`single`), ao lado de Parâmetros e Usuários; `#/rota` redireciona para `#/objeto`, para o link antigo não cair em rota inexistente. Tabela em [extensions/thl.md](../extensions/thl.md).

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
| `…/resourcen/parametro-ambiente/variavel` | filho de `parametroDef` | GET, POST, PATCH, DELETE | `parametroIni/Fin` |
| `…/resourcen/parametro-ambiente/programa` | filho de `parametroDef` (`noUpdate`) | GET, POST, DELETE (sem PATCH na API) | `parametroIni/Fin` |

O filho é **operação na URL do pai** desde 2026-10-04; os filtros do GET não mudaram (`ParametroVariavelService.cls:105-109` segue lendo `ambienteIni/Fin` e `parametroIni/Fin`).

Todas as chamadas passam pelo `CrudService` do motor genérico (não há mais service por recurso). DELETE leva a chave no **corpo JSON** (`http.delete(url, { body })`), não em query string. Variável sensível volta `********` no GET; o modal reenvia `********` e o backend mantém o valor.

⚠️ **Rotas vigentes (confirmado pelo responsável em 2026-10-01):** `parametro-ambiente`, `parametro-variavel` e `parametro-programa`, como na coleção **Nitro** do Postman (nuvem; as cópias em `Utils\postman` foram removidas em 2026-10-01). Alinhados no mesmo dia: `Utils\scripts\carga-thl-api-cadastros.p`, [extensions/thl.md](../extensions/thl.md), a ADR [api-rest-cadastros-thl.md](../adr/api-rest-cadastros-thl.md) (decisão nº 1 revista), [thl/camada-datasul.md](../thl/camada-datasul.md) e o comentário de cabeçalho das classes `Parametro*Message.cls` — não resta menção aos nomes antigos (`parametro`, `parametroVariavel`, `parametroPrograma`) fora do histórico. Ambiente onde a carga já rodou com os nomes antigos: a carga não renomeia — ajustar `thl-inbound-rota.rota-publica` das rotas `THL-PARAMETRO*`.

**Desenvolvimento local:** `proxy.conf.json` encaminha `/api` para um servidor PASOE/Tomcat do cliente (HTTPS, `secure: false`); `.claude\launch.json` sobe `ng serve web` (4200) e `ng serve cadastro` (4201). O cadastro em `development` usa backend **mock em memória** (`src\app\mock\cadastro-mock.interceptor.ts`, via `fileReplacements` de `mock-interceptors.ts` → `mock-interceptors.dev.ts`); o build de produção não inclui o mock.
**Deploy:** `build-deploy.ps1` faz `ng build web --configuration production` e monta a pasta `dist\thl-html-consulta`; `build-deploy-cadastro.ps1` faz o mesmo para `cadastro` (`dist\thl-html-cadastro`). Ambos no formato de menu HTML TOTVS para o webapps do Tomcat do Datasul. O `dist` fica só com essas duas pastas: não há zip e a saída bruta do build (`dist\web`, `dist\cadastro`) é apagada ao final. Os pacotes contêm **apenas as subpastas `html.*`** — `META-INF` (com `MANIFEST.MF` e `war-tracker`) e `WEB-INF` (com um `web.xml` mínimo) foram gerados até 19/10/2026 e **removidos a pedido**; quem publica não os quer no pacote. Efeito colateral a lembrar: sem `WEB-INF/web.xml` não existe `WatchedResource` para o Tomcat vigiar, então publicar não recarrega o contexto sozinho — pasta nova pode continuar invisível até o contexto ser reiniciado à mão. `-DeployPath` publica no webapps em duas fases: copia cada subpasta `html.*` para `<pasta>.novo` ao lado da que está no ar, confere `index.html` e a contagem de arquivos, e só então troca por rename, desfazendo as trocas já feitas se alguma falhar. Nada é apagado antes de a cópia estar completa, e o script sai com erro em vez de declarar sucesso. O modo anterior apagava as subpastas antes de copiar: uma cópia interrompida (contexto no ar segurando os `.js`, antivírus, permissão) deixava o contexto **sem** `html.menu`. Rename bloqueado por arquivo em uso aborta pedindo para parar o contexto no Tomcat.

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

## Ajustes da rodada de 16/10 (tarde)

- **"Métricas" virou "Métricas gerais"** no menu (`shortLabel` "Gerais") e no título da tela raiz.
- **A tela raiz contava erro só do processamento.** O aviso do topo dizia "5 mensagens com erro em alguma fase" e o cartão logo abaixo dizia "Erro 0" — os erros estavam na requisição e no retorno. Agora os dois saem do **mesmo array** (`comErro`), contado pelo pior estado entre as três fases, que é o critério das telas de métricas e dos chips dos monitores. `sucesso` passou a ser "sem erro e sem pendência" (o `N/A` do retorno de mensagem de entrada não impede sucesso), então as três contagens somam o total.
- **O "duplo clique" era detecção de mudanças, não clique.** Diagnóstico e regra em [`poui-licoes.md`](poui-licoes.md): o app é **zoneless** e o `setTimeout` que abria o modal não agendava CD. Um clique já basta — verificado abrindo "Informação" pelo menu da linha.
- **Cartões da auditoria com cor da ação predominante** (`corDaPredominante`): criação verde, alteração âmbar, deleção vermelha, empate para a mais destrutiva. ⚠️ Ali a borda **não é severidade** como na mensageria e no e-mail — é a ação que domina a tabela. Verificado: tabela com 58 alterações → âmbar; com 9 criações → verde; com 4 deleções → vermelho.

## Duas escalas de cartão e dois significados de cor (2026-10-16)

O `thl-metric-card` passou a servir a dois papéis, e eles **não** usam a cor do mesmo jeito:

| | Telas de assunto | Métricas gerais |
|---|---|---|
| Cor da moldura | **estado** — erro / pendente / sucesso (auditoria: ação predominante) | **assunto** — azul `#2c6fb5`, roxo `#6b4fa8`, verde-azulado `#17807a` |
| Escala | padrão | `[grande]="true"`: título 20px, total 34px, linhas 17px, ícone do título 32px |

As três cores de assunto são deliberadamente **fora** da paleta de estado: verde, vermelho e âmbar já significam sucesso, erro e pendência dentro do próprio cartão, e um cartão de e-mail verde afirmaria "tudo certo" ao lado de uma linha "Erro 1". Quem manda na moldura é o `acento` quando existe; senão, o `estado`.

Também entraram na tela geral o **ícone do menu lateral ao lado de cada título** (mensageria, e-mail, auditoria) e um **ícone por linha** na cor da própria linha — os de auditoria são os mesmos dos chips da tela dela.

O cartão ganhou **sombra** (`box-shadow` neutro). Cuidado herdado: os modificadores de estado também usam `box-shadow` para a barra lateral `inset`, então a sombra vive numa variável SCSS e é repetida em cada um — declarar só no bloco base apagaria a barra.

## Seletor de sentido no monitor da mensageria (2026-10-16)

Entrada/Saída **não** virou chip: os chips são estados mutuamente exclusivos, e clicar em "Saída" apagaria o "Erro" — justamente a combinação mais útil. Virou um trio de botões (`↔`, `an-airplane-takeoff`, `an-airplane-landing`) **na faixa da engrenagem do `po-table`**, encostado nela, no mesmo molde medido no navegador: 44px de altura, ícone de 24px, cor `#045b8f`, sem borda nem fundo. O selecionado se marca por fundo azul suave; cada botão tem tooltip e `aria-label`.

Três coisas aprendidas aí:

- **Não há slot** naquela faixa (o `po-table` só expõe `cell`, `column` e `row`). O controle é posicionado **em relação à tabela** (contêiner `position: relative`), e não ao fluxo da página: duas tentativas com deslocamento fixo quebraram quando o disclaimer apareceu.
- O contêiner tem `min-height: 60px` para o controle não sumir quando o filtro esvazia a lista — senão o usuário fica sem como desfazer.
- A coluna **Dispositivo** ganhou o avião ao lado do texto por `p-table-column-template`. ⚠️ A diretiva **só funciona se a coluna declarar `type: 'columnTemplate'`** — sem isso é ignorada em silêncio. Não usei `type: 'label'` porque viraria tag colorida, reservada no projeto para estado e severidade.

⚠️ `dispositivo` **não vai para a API**: filtra o que já foi carregado. Quando a paginação real entrar, esse filtro precisa ir junto, senão passa a mentir.

## Cartão de métrica: tabela de fases (2026-10-16)

O cartão deixou de listar só erros. Cada fase virou uma **linha com quatro colunas** — sucesso · pendente · erro · não se aplica — sob um **cabeçalho de ícones** (`an-check-circle`, `an-clock`, `an-x-circle`, `an-minus-circle`), os mesmos dos chips que ficam logo acima na tela.

- **As quatro colunas somam o total do cartão**, então as três fases ficam na mesma régua e dá para comparar uma com a outra. É o que faz "onde quebra" saltar aos olhos.
- **A coluna N/A é obrigatória**: mensagem de entrada não tem retorno, e sem essa coluna a fase apareceria como um sucesso que nunca houve.
- **Os ícones dispensam legenda.** Era a parte frágil da alternativa com quatro números nus, que exigia uma linha explicando a ordem. Eles nasceram em 13px e **ficaram ilegíveis** — a 16/10 subiram para **18px** (colunas de 34px), que é onde o "x" se separa do relógio sem alargar o cartão.
- **Zeros em cinza claro** — é o que faz a coluna do erro saltar.
- **Saúde ficou**, agora com `an-heartbeat`. Ela responde outra pergunta ("este objeto vai bem?"); as fases respondem "onde quebra". A mesma barra serve de Entrega no e-mail.
- **A borda usa o pior estado presente** (erro > alerta > sucesso), com o tratamento do chip selecionado: borda colorida e fundo `#FAFBFF`. O fundo lavado anterior fazia uma tela de cartões saudáveis virar tapete verde.
- **Etiqueta de sentido com avião** (16/10): `an-airplane-takeoff` para Saída e `an-airplane-landing` para Entrada, no lugar das setas diagonais. **O texto continua** — a 11px os dois desenhos viram a mesma mancha, medido comparando as variantes no navegador; só o ícone funcionaria no seletor de período (onde o número carrega a informação), não aqui, onde a informação é a direção. O domínio `SENTIDOS` do `cadastros.defs.ts` foi alinhado na mesma rodada: o conceito Entrada/Saída tem **um desenho só nos dois apps**. Conferido no cadastro de Objeto com o mock (Entrada → `landing`, Saída → `takeoff`).
- **E-mail tem uma fase só** (Envio); **auditoria não tem fases** — são operações, sem noção de sucesso/erro —, então segue com as linhas numéricas e cartão neutro.

Defeito encontrado e corrigido no caminho: o modificador de estado nasceu como `.thl-metric--erro` e **colidiu com as classes de cor de texto** (`.thl-metric--erro` já existia), fazendo cada número da tabela herdar borda e fundo de cartão. Virou `.thl-metric--estado-*`. Fica a regra: modificador de bloco e classe utilitária de cor não podem compartilhar prefixo.

Verificado no navegador nas três telas, com dados injetados: mensageria com os três estados (erro/alerta/sucesso) e N/A no retorno de mensagens de entrada; e-mail com a fase única; auditoria **inalterada** (3 linhas, sem cabeçalho de ícones, sem borda de estado).

## Ajustes com o ambiente real (2026-10-16)

Primeira rodada com dados do PASOE à vista (capturas do usuário), o que mudou três coisas:

- **Auditoria: colunas maiores.** As larguras de 15/10 (110/175/110) foram medidas contra dados de teste e cortaram o conteúdo real — cabeçalho virava "Oper..."/"Usuár..." e a data perdia os segundos. Agora Operação 160, Dt. Criação 200 e Usuário 150; Campos segue elástica. Conferido com o conteúdo real (`Atualização`, `16/10/2026 15:12:33`, `ext.reginal`): nenhuma célula trunca.
- **Retorno e Parâmetro do e-mail com realce de JSON.** `realcarJson()` em [`shared/domain/json-view.ts`](../../../Fontes/web/src/app/shared/domain/json-view.ts): chave, texto, número, booleano e nulo em cores, `white-space: pre-wrap` (antes a linha longa corria para fora do modal) e altura máxima com rolagem. Também **desembrulha JSON gravado dentro de string** — o ABL às vezes grava escapado, e aí o `stringify` imprimia tudo numa linha. O `::ng-deep` é obrigatório porque o conteúdo vem de `[innerHTML]`.
- **Tooltip não engole mais clique** (`src/styles.css`, vale para os dois apps). A regra é `.po-tooltip:not(:has(a, button, input, select, textarea, [tabindex]))`: tooltip com conteúdo interativo — o `p-additional-help-tooltip` com header template, que hoje nenhuma tela usa — continua clicável. Medido: tooltip comum fica `pointer-events: none`, tooltip com link ou botão fica `auto`. Navegador sem `:has()` descarta a regra inteira e volta ao comportamento antigo, que é a degradação aceitável. É a defesa estrutural para o "precisa clicar duas vezes" no menu de ações: qualquer tooltip que fique sobre a tabela passava a consumir o primeiro clique. ⚠️ **Não reproduzido em dev** — com 60 linhas injetadas, mensageria e e-mail abrem o menu no primeiro clique. O usuário vê o problema em mensageria e e-mail, mas não em auditoria, num pacote anterior à correção completa do tooltip do menu (`thlMenuTooltipFix`, de 15/10 13:52). Confirmar depois de publicar o pacote novo.

## Estado preservado na navegação (2026-10-15)

Voltar para uma tela deixou de recomeçar do zero. O que já ia para a URL (filtros, busca, chip dos monitores, período e tráfego interno das métricas) ganhou companhia:

- **`pagina`** nos três monitores: quantas páginas do "Carregar mais" estavam abertas. **Não custa requisição** — a lista inteira já vem numa chamada e a paginação é fatiada no navegador, então restaurar é só cortar em outro ponto.
- **`chip` e `todos`** nas três telas de métricas: a situação selecionada e o "ver todos os cartões".
- **Rolagem** devolvida pelo `ThlScrollRestoreService` ([`shared/domain/scroll-restore.service.ts`](../../../Fontes/web/src/app/shared/domain/scroll-restore.service.ts)), ligado nos dois shells.

  ⚠️ A primeira versão usava `withInMemoryScrolling({ scrollPositionRestoration: 'enabled' })` e **não funcionava**: o `ViewportScroller` do Angular rola a **janela**, e nestas telas quem rola é o `.po-page-content` do PO UI — medido em 16/10 na mensageria com 80 linhas, o documento tinha a altura da janela enquanto o `.po-page-content` tinha 728px para 2358px de conteúdo. O `history.scrollRestoration === 'manual'` que serviu de "prova" só diz que a opção está ligada. A revisão de código pegou; a lição é que confirmar a ativação de um recurso não é confirmar o efeito dele.

  O serviço guarda o `scrollTop` por rota (sem query string, senão cada gravação de filtro perderia a posição), **nunca força o topo** — só mexe quando tem posição guardada, então navegação comum e o `replaceUrl` dos filtros não dão pulo — e **espera o conteúdo chegar** por até 10s, desistindo assim que o usuário roda, toca ou digita. Verificado de ponta a ponta: 400px guardados ao sair, 400px devolvidos ao voltar depois de a lista carregar.

Dois detalhes que só apareceram testando:

- **A restauração da página só é consumida quando há linhas** (`paginaRestaurar` + `filteredItems.length`). Sem isso, a carga que falha — lista vazia — gastava a restauração antes de existir lista, e a volta caía na página 1 mesmo com o parâmetro na URL. Em compensação ela **morre quando o usuário mexe no filtro** (busca, avançado, chip): a página só vale para o resultado que estava na tela quando o link foi gerado, e sem esse descarte uma entrada por `?pagina=5` com o backend fora acabava abrindo 100 linhas de um filtro diferente.
- **A URL diz a página desejada, não a atual** (`paginaDesejada`). Como `carregar()` grava a URL antes de os dados chegarem, com `this.page` ainda em 1, o parâmetro era apagado na própria entrada da tela.

Verificado no navegador com linhas injetadas: `pagina=3` apareceu na URL ao carregar mais duas vezes; entrando por `#/email?pagina=4`, o parâmetro sobreviveu à falha de carga e, quando os dados chegaram, a lista abriu com **80 linhas na página 4**; nas métricas, `chip=Erro&todos=1` foi e voltou. ⚠️ A restauração da **rolagem** não pôde ser exercitada de ponta a ponta (sem PASOE não há página longa o bastante); o que está confirmado é que a opção está ativa.

Fora de escopo por decisão: **cache dos dados** para não rechamar a API ao voltar. Em tela de monitoramento, dado velho sem aviso é pior que espera — se for feito, precisa de validade curta, mesmo filtro e "Última atualização" visível.

## Tooltip preso no menu lateral (2026-10-15)

Defeito do `po-menu` do PO UI: o tooltip do menu recolhido não some ao tirar o mouse e vai acumulando. Contornado por `thlMenuTooltipFix` em [`shared/directives/`](../../../Fontes/web/src/app/shared/directives), aplicado ao `<po-menu>` do `app.html` — que é o shell **dos dois apps** (`App` e `AppCadastro` compartilham o template), então a correção vale para consulta e cadastro.

O diagnóstico medido está em [`poui-licoes.md`](poui-licoes.md). Verificado com **ponteiro real** no navegador, nos três caminhos:

| Caminho | Antes | Depois |
|---|---|---|
| Sair **pelo lado** (sobre o próprio tooltip) | ficava preso | **nenhum** |
| Andar de um item para outro | sobravam dois | **só o do item atual** |
| Voltar ao menu depois | — | **o tooltip certo aparece** |

Os tooltips de outros componentes continuam funcionando: conferi o dos atalhos de período na mesma sessão ("Últimos 7 dias" aparece e some sozinho). A varredura só roda a partir de eventos do menu, então não alcança os demais.

## Seletor de período em ícones (2026-10-15)

Os atalhos das telas de métricas deixaram de ser texto: **cronômetro com 1** (1h), **calendário com 1** (24h), **com 7**, **com 21** e **`an-calendar-gear`** (Personalizado). Cronômetro conta horas, calendário conta dias — é o que separa "1h" de "24h", que no número sozinho seriam os dois um "1". A barra caiu de **398px para 320px**.

- **O desenho é SVG inline no `thl-filter-tabs`**, não ícone de fonte: o `an-calendar` da Animalia tem **"12" impresso no glifo** e número de fonte não se troca (conferido renderizando os candidatos). O SVG usa `currentColor`, então o ícone acompanha o branco do botão selecionado.
- **`ThlFilterTab` ganhou `glifo`, `icone` e `tooltip`.** O `label` continua curto porque também vira o subtítulo da página (`Erros por rota · 24h`); quem explica o desenho é o `tooltip`, que também vira o `aria-label`. O `<svg>` fica com `aria-hidden`.
- **Centralização medida, não estimada.** As linhas de base saíram do `getBBox()` do próprio texto, com as fontes já carregadas: o corpo do calendário vai de y=9,5 a y=21,5 (centro 15,5) e o desvio dos quatro dígitos ficou em **0,00**. Medir importou: estimativa colocava o dígito 0,76 acima do centro, e a primeira medição, feita antes de a fonte carregar, deu número diferente.
- **Rótulo `📅 Período |` à esquerda das opções** (`rotulo` e `rotuloIcone` do `thl-filter-tabs`, com `an-calendar-dots` e o separador que já existia para o botão de atualizar). É o que resolve o buraco do ícone sem texto: **tooltip não existe em toque**, e sem o rótulo a barra não dizia do que tratava num tablet. O rótulo não é foco nem clique, e vira o `aria-label` do grupo. Com o rótulo a barra foi de 320px para **412px** — **acima dos 398px da versão em texto**. Ou seja: o ganho de espaço acabou, e o que sobrou foi a troca de rótulos legíveis por ícones mais o título do grupo. Se o espaço voltar a apertar, é aqui que se mexe.

## Atalhos de período nos filtros avançados (2026-10-15)

`thl-date-shortcuts` (novo, em `shared/components`) põe **Hoje · 7 dias · Mês · Mês anterior** logo **abaixo** dos campos de data dos três filtros avançados. Helpers em [`shared/domain/periodo.ts`](../../../Fontes/web/src/app/shared/domain/periodo.ts): `ATALHOS_DATA`, `faixaDoAtalhoData()`, `diasAtras()`, `mesmaDataHora()`.

- **O atalho preenche os campos à vista**, não filtra escondido: o usuário vê a faixa, pode ajustar e só então aplica.
- **São links discretos, não pílulas.** O lugar que o usuário pediu era o rodapé do calendário, junto de "Limpar | Hoje" — mas o `po-calendar-footer` do PO UI é **componente interno, com entradas fixas e sem projeção de conteúdo**: chegar lá exigiria injetar DOM no overlay da biblioteca, que quebra na próxima atualização. Os links encostados no campo são o mais perto disso sem hack. Quatro opções de propósito: aqui eles dividem a tela com um formulário inteiro.
- **O estado ativo é negrito + sublinhado**, não só cor.
- **Dias inteiros, 00:00 a 23:59** — diferente dos `ATALHOS_PERIODO` das métricas, que são em horas. "Hoje" clicado às 9h precisa incluir o que entrar às 9h30.
- **Digitar data na mão volta a pílula para Personalizado**, comparando os campos com a faixa do atalho (`mesmaDataHora`, que ignora o fuso que o `po-datetimepicker` acrescenta ao modelo). Um sinalizador não serviria: preencher os dois campos dispara `ngModelChange` duas vezes e o atalho se apagava sozinho — aconteceu e está corrigido assim.
- **Limpar solta o atalho**, senão a pílula fica acesa com os campos vazios.
- **Aviso de expurgo só na mensageria**, acima de 21 dias, com a data-limite calculada: "Sucessos anteriores a 24/09/2026 podem já ter sido expurgados; erros ficam 42 dias." O texto diz **pode**, porque `retencao-dias-sucesso`/`-erro` são por objeto e configuráveis (0 = nunca expurga). E-mail e auditoria não têm aviso: a retenção do e-mail é decidida no agendamento do `thl0210rp.p` e a da auditoria é 365 dias por tabela.
- Verificado no navegador: os cinco atalhos geram a faixa certa, a pílula fica marcada, o aviso aparece só em "Mês anterior", o filtro emitido sai em `yyyy-MM-ddTHH:mm` (16 caracteres, como o `parseDateTime` exige) e vai para a URL. O contador da aba (`Principal (2)`) já conta as duas datas sozinho.

⚠️ **Trimestral ficou de fora de propósito.** Os três monitores **não enviam `page`/`pageSize`** — o `pageSize = 20` só fatia no navegador uma lista que já veio inteira, e o "Carregar mais" não busca nada novo. A API aceita os dois (`PaginationHelper`), então é trabalho de front. Com faixas longas numa auditoria movimentada, o navegador baixaria meses de uma vez: paginação de verdade vem antes de oferecer trimestre.

## Ajustes nos monitores e nas métricas (2026-10-15)

Seis ajustes pedidos pelo usuário, todos verificados no `ng serve web` com linhas injetadas por `ng.getComponent` (os monitores dependem de PASOE; **nada foi conferido contra o ambiente real**).

- **Menu de ações abre ao lado** (`thl-row-actions`, `p-position="right-bottom"`): corrige o "preciso clicar duas vezes". Diagnóstico e medição em [`poui-licoes.md`](poui-licoes.md) — o defeito era de sobreposição, não de clique, e valia para os três monitores **e** para os nove cadastros.
- **Mensageria:** `Código do status` e `Descrição do retorno` saíram do browse (`visible: false`). Seguem no ⚙️ e no detalhe. A busca rápida continua procurando dentro de `descrRetorno`, então uma linha pode casar sem mostrar por quê — mesmo comportamento que `codMsg` já tinha.
- **E-mail:** ordem passou a `Ação · Dt. Envio · Status · Assunto · Remetente · Destino`; `Programa` e `Ambiente` saíram do browse (seguem no detalhe). `Programa` continua sendo filtro do avançado, com o disclaimer como única pista na lista.
- **Auditoria:** larguras **em px** nas colunas de tamanho previsível (Tabela 160, Operação 110, Dt. Criação 175, Usuário 110, Referência 150) e **Campos sem `width`**, ficando com a sobra — 200px fixos viraram 701px elásticos a 1257px de janela. O `po-table` ignora porcentagem; está medido em `poui-licoes.md`.
- **Métricas (mensageria e e-mail):** cartão de unidade com falha ganha fundo avermelhado claro e barra lateral vermelha (`MetricCard.estado = 'erro'`, classe `.thl-metric--com-erro`). Tom suave de propósito: vermelho forte em vários cartões ao mesmo tempo apaga o destaque. O número de falhas continua escrito — **a cor é reforço, nunca o único sinal**. O critério é literal: *qualquer* falha ≥ 1 marca o cartão.

- **Mais recentes primeiro** nos três monitores: `maisRecentePrimeiro()` em [`shared/domain/ordenacao.ts`](../../../Fontes/web/src/app/shared/domain/ordenacao.ts), aplicado no fim do filtro local. A API devolve **agrupado** (por aplicação, por programa, por tabela) e sem `order`: o ABL monta a resposta com `for each` sem `by`. Como não há paginação no servidor, ordenar no cliente ordena tudo que está carregado. A comparação é de texto porque a data vem em ISO, onde ordem alfabética é ordem cronológica — se a API passar a mandar `dd/MM/yyyy`, quebra em silêncio (está escrito no cabeçalho da função). ⚠️ O `po-table` **não tem input de ordenação inicial**, então a setinha do cabeçalho não aparece; por isso o subtítulo das três telas diz "mais recentes primeiro". A ordenação por clique no cabeçalho continua funcionando nos dois sentidos (verificado).

Pedido na mesma rodada e **não aplicado**: JSON formatado no detalhe de e-mail.

## Telas de métricas (2026-10-08)

Três telas no app de consulta, uma por assunto, sobre as rotas `<assunto>/metricas` do backend:

| Rota da tela | Rota da API | Unidade do cartão | Barra |
|---|---|---|---|
| `#/mensageria/metricas` | `mensageria/metricas` (`dtCriacaoIni/Fin`) | aplicação + objeto | saúde (% sem erro) |
| `#/email/metricas` | `email/metricas` (`dtEnvioIni/Fin`) | programa + parâmetro de ambiente | entrega (% enviado) |
| `#/auditoria/metricas` | `auditoria/metricas` (`dtCriacaoIni/Fin`) | banco + tabela | proporção entre criação, alteração e deleção |

Acesso pelo **menu lateral** (2026-10-09): um grupo por assunto, com a listagem e a métrica lado a lado — Métricas · ⎯ · Mensageria, Métrica Mensageria · ⎯ · E-mail, Métrica E-mail · ⎯ · Auditoria, Métrica Auditoria. O botão *Métricas* saiu do `p-actions` dos três monitores, e com ele o `Router` que só ele usava. A linha divisória entre grupos é um `::before` no primeiro item de cada um (`app.css`), o mesmo recurso do app de cadastro — o `po-menu` não tem divisor nativo. O **Dashboard Msg** foi **removido** em 09/10/2026 (850 linhas): duplicava `#/mensageria/metricas` com outro recorte e os números divergiam. `#/dashboard-mensageria` virou redirect para `mensageria/metricas`, como `rota` → `objeto` no cadastro. Saíram junto, por ficarem sem referência: `MensageriaDashboardService`, `integration-card`, `integration-route.model.ts`, `health-score.pipe.ts`, `relative-time.pipe.ts` e o `dashboard-mensageria.model.ts`, que já estava órfão desde a limpeza de 08/10. **Ícones (14/10/2026):** as três telas de métrica usavam o mesmo `an-chart-line`, o que apagava a diferença entre elas no menu recolhido, onde só o ícone aparece. Agora cada uma tem o seu — `an-chalkboard-simple` (Mensageria), `an-chalkboard-teacher` (E-mail) e `an-chalkboard` (Auditoria) —, e os monitores de Mensageria e Auditoria passaram a `an-arrows-left-right` e `an-magnifying-glass`. Os cinco glifos foram conferidos no navegador: codepoints distintos, nenhum caindo em fallback. Peças compartilhadas: `shared\domain\periodo.ts` (faixa e atalhos), `shared\domain\metricas.service.ts` (uma chamada para as três), `shared/components/thl-period-filter` e `shared/components/thl-metric-card`.

- **Data e hora:** `yyyy-MM-ddTHH:mm`, hora local, sem segundos nem fuso — `toISOString()` deslocaria a faixa para UTC. Desde 2026-10-13 **todas as rotas** aceitam (e exigem) hora, listagens inclusive.
- **Atalhos:** 1h · 24h · 7 dias · 21 dias · Personalizado. O máximo é 21 dias porque é a retenção das mensagens com sucesso — em 30 dias o gráfico cairia sem o dado ter sumido.
- **Sem paginação e sem limite** nestas rotas, então a soma feita no cliente é completa (ao contrário das listagens, limitadas por página).
- **`total` não existe** na resposta (`{ items, hasNext }`).
- **E-mail: o cartão e a listagem contam universos diferentes — decidido manter assim (19/10/2026).** A unidade do cartão é `programa + paramAmbiente`, então `tkn4001e` aparece em **dois** cartões (`process.credito` e `garantia.email`); o cartão leva para o monitor passando **só** `codProgDtsul`, que traz os dois ambientes somados. Caso real: cartão 250, listagem 268, sendo 268 − 250 = 18 os envios de `garantia.email`. Nenhum dos dois números está errado. Levar o ambiente na navegação exigiria filtro local no monitor (o campo vem na listagem, mas **não existe query param** de parâmetro de ambiente no `EmailService.cls` — seria ⚠️ requer backend); agrupar só por programa faria os números baterem, mas apagaria a separação por ambiente, que é a razão da unidade ser programa + ambiente (o `thl-email` não guarda o parâmetro de e-mail). **Não tratar como defeito.**
- Auditoria **não tem falha**: a barra é proporção, não saúde. O chip de **Deleções** filtra o evento raro e irreversível.
- Mensageria esconde o **tráfego interno** (`interna`) por padrão. O botão virou **`thl-icon-toggle`** (14/10/2026), à esquerda dos atalhos de período e com o mesmo visual deles — ele reaproveita o stylesheet do `thl-filter-tabs` por `styleUrls`, em vez de copiar as regras. Sem rótulo visível e **sem estado de seleção** — fundo sempre branco, porque o escuro é dos atalhos de período e um botão aceso ao lado deles pareceria mais um atalho escolhido. **O ícone mostra o estado** (`an-eye` = mostrando, `an-eye-slash` = oculto), `aria-pressed` leva esse estado a quem não vê o ícone, e o **tooltip diz a ação** ("Mostrar/Ocultar tráfego interno"), que é também o `aria-label`. O estado continua indo para a URL (`internas=1`) e volta no recarregamento — verificado no navegador.
- E-mail agrupa por **programa**, não por parâmetro de e-mail: o `thl-email` não guarda o parâmetro nem o grupo.
- **Chip de situação filtra pelo que o rótulo promete:** o tipo do filtro cobre todas as chaves de chip (`todos`, `Sucesso`, `Erro`, `Pendente`). Com um tipo menor e `as`, os chips de sucesso e pendente caíam no ramo de erro e mostravam o oposto do rótulo.
- **Atalho do cartão para o monitor:** os três monitores leem o filtro da URL — mensageria `?aplicacao=&objeto=`, auditoria `?banco=&tabela=`, e-mail `?codProgDtsul=` (o nome do filtro na API, não `programa`). Sem isso o botão abriria a lista inteira fingindo ter filtrado.
- **Tráfego interno fora do resumo (19/10/2026):** a tela de **Métricas gerais** somava todas as linhas de `mensageria/metricas`, inclusive as de aplicação com `interna = true`, enquanto a tela de métricas da mensageria esconde as internas por padrão. No mesmo período os dois números divergiam — 124 na geral contra 4 na de mensageria. O agravante é que o tráfego interno é gerado pelo próprio monitor (cada atualização cria mensagens `THL/Mensageria`, `THL/Email` e `THL/Auditoria`), então o cartão media o uso da tela, não a integração. `MetricasService.getMetricas` ganhou o parâmetro `incluirInternas` (padrão `false`) e a tela recebeu o **mesmo `thl-icon-toggle` da tela de mensageria**, com os mesmos rótulos e o estado em `?internas=1`. Alternar refaz a consulta, como a troca de período — o resumo é montado a cada busca, não há dado bruto guardado na tela. A nota de rodapé diz que o tráfego interno não entra a menos que o botão esteja ligado. O e-mail e a auditoria não têm esse campo: `interna` existe só em `mensageria/metricas`, então o botão move apenas o bloco Mensageria.
- **Uma só fonte de número:** a tela de **Métricas** da raiz também consome as rotas `<assunto>/metricas` (2026-10-08). Antes somava as listagens, limitadas por página, e mostrava números menores que as telas novas no mesmo período. O Dashboard Msg, que tinha o mesmo problema, foi migrado junto e removido em 09/10.
- **Um seletor de período para todas as telas** (2026-10-09): `thl-period-filter`, com 1h · 24h · 7 dias · 21 dias · Personalizado (data **e** hora). Os tipos `PeriodFilter` e `PeriodoFiltro` foram removidos e os serviços recebem `FaixaPeriodo`, não o nome do atalho. Isso eliminou um defeito silencioso: o Dashboard Msg oferecia **30d**, que `faixaDoAtalho` não conhecia, então a opção caía no `default` e buscava **24 horas** — a tela prometia 30 dias e mostrava um dia.
- **A tela raiz é um resumo, não um painel** (2026-10-09): três `thl-metric-card`, um por assunto, com total, quebra por situação, barra e **Ver métricas** levando a `/<assunto>/metricas`. O KPI anterior (grade de cartões, cartões de fase, 261 linhas de SCSS próprio) saiu: respondia pior à mesma pergunta que as telas de métricas, e manter os dois significava duas respostas que já tinham divergido. O alerta do topo conta os erros **da faixa consultada** (`errosNoPeriodo`), não mais uma janela fixa de 24 horas anunciada como se fosse o período escolhido.
- **Data e hora em todas as rotas** (2026-10-13): as listagens passaram a ler com `getDateTime`, como as rotas de métricas. Os cartões levam a faixa **inteira** para o monitor (os `substring(0,10)` saíram) e os filtros avançados dos três monitores trocaram `po-datepicker` por **`po-datetimepicker`**: o usuário informa a hora. Normalização em `shared/domain/periodo.ts` — `paraFaixa` (modelo do componente, ISO com fuso) e `textoDigitadoParaFaixa` (o que está escrito no campo, quando o modelo não serve); data sem hora vale o dia inteiro (`T00:00`/`T23:59`) e `rotuloDeDataHora` monta o texto do filtro ativo. ⚠️ `parseDateTime` exige **exatamente 16 caracteres**: enquanto o front mandava só a data, toda consulta filtrada falhava. Armadilhas do componente em [poui-licoes.md](poui-licoes.md).
- **Troca rápida de período** cancela a busca anterior (`Subscription` guardada), senão a resposta mais lenta sobrescreve a mais recente.
- **Grade** mostra 12 cartões e um "Ver todos"; os cartões já vêm ordenados por volume.
- **O cartão leva o período junto** ao abrir o monitor (`dtCriacaoIni/Fin`, `dtEnvioIni/Fin`): sem isso a listagem aplicava o padrão dela e os números não batiam com o cartão.
- **Dado que a origem não informa fica ausente:** a rota de métricas não devolve o método da mensagem, então `IntegrationRoute.method` é opcional e o cartão do dashboard omite a etiqueta em vez de exibir um valor fixo.
- **Nível fora do domínio aparece cru** ("Nível 3"), como no motor de cadastro — rotular de "Normal" esconderia cadastro inválido.
- **Faixa personalizada acima de 21 dias** mostra aviso de que o início do período pode vir incompleto por expurgo (`excedeRetencao` em `periodo.ts`). A consulta continua valendo — o aviso explica a queda em vez de escondê-la.

## Estado do período na URL e consulta única (2026-10-14)

Duas correções a partir de defeitos reproduzidos no navegador:

- **Consulta duplicada.** Abrir um monitor com filtro na URL fazia **duas** chamadas idênticas: `ngOnInit` chamava `carregar()` e o `(p-change)` disparado pela montagem dos disclaimers chamava de novo. Os três monitores passaram a guardar a assinatura da lista que eles mesmos montam e ignoram o evento quando nada mudou — detalhe do comportamento do componente em [poui-licoes.md](poui-licoes.md). Remover um chip continua recarregando (verificado).
- **Período na URL.** As quatro telas de métricas guardam o período em `queryParams` (`atalho`, mais `ini`/`fin` no personalizado, mais `internas=1` na mensageria), com `replaceUrl: true` para não empilhar histórico a cada troca. Antes, sair da tela e voltar perdia o que estava escolhido — a rota é lazy e o componente nascia com o padrão de 24h. Agora o "voltar" do navegador restaura e o link é compartilhável (`#/auditoria/metricas?atalho=21d`).
  - Nos atalhos, a faixa é **recalculada** na abertura: o link mostra os últimos 7 dias de hoje, não os de quando foi copiado. Só o personalizado leva `ini`/`fin` fixos.
  - `atalho` desconhecido na URL cai no padrão da tela em vez de quebrar (verificado com `?atalho=999d`).
  - Helpers `periodoParaUrl` e `periodoDaUrl` em `shared/domain/periodo.ts`.
- **O filtro dos monitores também vai para a URL** (2026-10-14): filtro avançado, busca rápida e chip de situação, por
  `filtroParaUrl`/`filtroDaUrl` em `shared/domain/filtro-url.ts`, com `replaceUrl: true`. Sair e voltar restaura tudo,
  inclusive o chip marcado e o texto no campo de busca.
  - As chaves são os **nomes do modelo de filtro** (`aplicacaoIni`, `dtCriacaoInicial`…), não os query params da API —
    quem traduz para a API continua sendo o service.
  - Os **parâmetros curtos dos atalhos** (`aplicacao`, `objeto`, `banco`, `tabela`, `codProgDtsul`, `statusProcessamento`)
    continuam valendo e **prevalecem** sobre as chaves longas: são a intenção de quem clicou no cartão. Ao carregar, a tela
    reescreve a URL na forma longa — o link curto segue funcionando, mas a barra passa a mostrar o filtro real.
  - `codStatusRetorno` volta da URL como **número**; valor não numérico é descartado em vez de virar `NaN`.
  - A busca rápida grava a URL no próprio método: ela é local e não passa por `carregar()`.

## Filtro avançado da mensageria em abas (2026-10-14)

Eram 18 campos numa coluna só. Passaram a duas abas, com o critério vindo do **comportamento de cada campo**, não do assunto:

| Aba | Campos | O que fazem |
|---|---|---|
| **Principal** | Dt. Criação, Dt. Integração, Aplicação, Objeto, Operação (pares Ini/Fin) | Query param → consultam **toda a base** |
| **Avançado** | *Identificação*: Cód. Mensagem · *Refinar o resultado*: Dispositivo, Método, Status Requisição/Processamento/Retorno, Cód. Status Retorno | Cód. Mensagem vai ao servidor; os outros seis filtram **só o que já está carregado** |

- **Cód. Mensagem ficou na segunda aba** por decisão de uso (UUID que o usuário raramente tem em mãos), não por comportamento — por isso a aba tem duas seções e **o aviso fica sobre o grupo local**, não sobre a aba inteira.
- ⚠️ **Os seis filtros locais não existem na API**: o `MensageriaService.cls` declara 12 `queryParameters` (6 pares + 4 datas). Enquanto o ABL não aceitar `metodo`, `dispositivo`, as três situações e `codStatusRetorno`, o aviso é a forma honesta de apresentar o que o front consegue fazer. Tarefa para `thl-coding`.
- **Dt. Criação vem antes de Dt. Integração**: é a data que o usuário conhece e a que a navegação dos cartões preenche.
- Contador no rótulo (`Avançado (1)`) e **Limpar zera as duas abas** — ambos verificados no navegador.
- Estilos em `shared/styles/thl-filtro.scss` (título de seção e aviso).

## Painel de Cadastros — página inicial do app de cadastro (2026-10-14)

`#/` deixou de redirecionar para Ambiente: é o **Painel de Cadastros**, que agrupa os nove cadastros em três blocos (Base do ambiente · Integração · Notificação e auditoria), com item **Início** no topo do menu. Componente em `inicio/pages/inicio/`, rota em `inicio/inicio-routing.ts`.

A tela **orienta, não mede**. Cada grupo diz para que serve e leva ao cadastro certo; quem chega sem saber em qual dos nove itens do menu mexer resolve ali.

- **Nenhuma requisição.** A primeira versão contava os pré-requisitos; a contagem saiu a pedido do usuário em 14/10. Sem chamada não há carregando, vazio nem erro — e a tela deixou de depender do `total` que a API não devolve (a pendência continua valendo para os monitores).
- **Cada destino é uma âncora de verdade** (`thl-nav-card`, `<a [routerLink]>`): Ctrl+clique abre em nova aba, o leitor de tela lista os nove como links e o foco chega sem `tabindex`. Com `po-button (p-click)` nada disso acontece.
- **Títulos vêm das definições** (`ambienteDef.title`…), então renomear um cadastro atualiza o painel sozinho. As **descrições ficam no componente**: o `subtitle` da definição é cabeçalho do browse e carrega nome de programa (`thl0020`), que não serve de orientação.
- **Ordem de dependência** aparece como nota só no grupo Base ("comece por aqui"), não como etapas numeradas: a tela não é assistente e numerar prometia um passo a passo que não existe.
- **Ícones iguais aos do menu lateral** — quem clica aqui reencontra o item depois.
- Cards do grupo com a mesma altura na linha (`::ng-deep .po-widget { height: 100% }`); em largura `md` fecham 2+1 sem rolagem, que é a faixa típica dentro do shell Datasul.
- O menu recolhido ganhou linha divisória acima de Ambiente, que deixou de ser o primeiro item (`app-cadastro.css`).

Foi avaliada no navegador uma segunda visão (um card por cadastro, 9 em grade) e **descartada**: em `md` ela rola, e multiplicava por quatro o texto da tela sem mudar o destino.

## Padrão comum aos dois apps (2026-10-02)

- **Rótulos de situação** ficam em [`shared/domain/status-labels.ts`](../../../Fontes/web/src/app/shared/domain/status-labels.ts) (`STATUS_LABELS`, `STATUS_EMAIL_LABELS`, `OPERACAO_LABELS`), usados pelas colunas `type: 'label'` dos monitores. No `PoTableColumnLabel`, **`value` casa com o dado e `label` é o texto exibido** — estavam invertidos nos três monitores, que mostravam `1`/`2`/`3` no lugar de Sucesso/Erro/Pendente e de Criação/Atualização/Deleção. **Pendente no e-mail (19/10/2026):** `STATUS_EMAIL_LABELS` trazia só `Sucesso` e `Erro`, mas o `EmailService` devolve três estados (`log-envio` 1 = `Pendente`). Como `type: 'label'` esconde a célula para valor fora do domínio, o e-mail pendente saía **sem status** e não entrava em nenhum chip — os dois chips não somavam o total. O domínio passou a incluir `Pendente`, e o monitor ganhou o chip correspondente, alinhando-se à tela de métricas de e-mail, que já contava pendentes.
- **Falha no carregamento** mostra a mensagem do backend e **Tentar novamente** no lugar da tabela, em **todas** as telas dos dois apps. Só a mensagem do corpo da resposta é exibida; a do `HttpErrorResponse` é técnica demais.
- **Erro e vazio são dois componentes compartilhados** (2026-10-09): [`thl-error-state`](../../../Fontes/web/src/app/shared/components/thl-error-state) (`detalhe`, `retry`, com `role="alert"`) e [`thl-empty-state`](../../../Fontes/web/src/app/shared/components/thl-empty-state) (`titulo`, `descricao`, `acao` opcional). Antes o bloco estava copiado em sete telas e **as classes `.thl-erro`, `.thl-crud-erro` e `.empty-container` não tinham regra de estilo em lugar nenhum** — o erro aparecia como texto solto, sem moldura.
- **Vazio por filtro ≠ vazio por cadastro novo:** no motor, a lista sem registros diz "Nenhum registro corresponde ao filtro" quando há termo ou filtro de URL, e "Nenhum/Nenhuma &lt;singular&gt; cadastrado(a)" com botão **Adicionar** quando a tabela está vazia (usa `feminine` do `CrudResource` para concordar).
- **A busca rápida dos monitores é local** (filtra só as páginas já carregadas), e o placeholder diz isso: "Filtrar os registros carregados", o mesmo texto do cadastro. Antes prometia busca por código ou assunto, e quem não achava um registro antigo concluía que ele não existia.
- **Ações da linha** em coluna "Ação" com `thl-row-actions` (`type: 'cellTemplate'`), não no `p-actions` do `po-table`.
- Templates novos usam o controle de fluxo do Angular (`@if`), não `*ngIf`.

## Observações

- `mensageria\services\` tem um só serviço: `mensagem.service.ts` (listagem e conteúdo). O `mensageria.service.ts` saiu com o Dashboard Msg em 09/10/2026.
- ⚠️ **Dois componentes órfãos** (verificado em 09/10/2026): `email/pages/email-detail` e `mensageria/pages/mensagem-detail` (356 linhas) não têm rota nem importador — o detalhe dessas features acontece em modal (`email-detail-modal`, `message-detail-modal`). Escaparam da limpeza de 08/10. O `auditoria/pages/auditoria-detail` é parecido mas **está em uso** pelo monitor de auditoria: é componente morando em `pages/`, não página.
- ⚠️ **Testes não executáveis:** existem `.spec.ts` (Jasmine), mas não há alvo `test` no `angular.json` nem biblioteca de teste no `package.json`.
- `.claude\launch.json` na raiz e `Fontes\web\.claude\launch.json` duplicam a configuração do dev server.
- `node_modules\`, `dist\` e `.angular\` são ignorados pelo `Fontes\web\.gitignore`; nada de `Fontes\web\` está versionado hoje.
