---
tipo: guia
camada: ambos
status: vigente
tags: [indice, kb]
updated: 2026-10-13
---

# THL-Library — Índice de documentação compartilhada

**Última sincronização:** 13/10/2026, por inventário e leitura estática. Nenhuma compilação ou validação de implantação nesta revisão.

**Atualização 19/10/2026 (skill thl-docs):** instalada a skill `thl-docs` (fechamento documental) em [.claude/skills/thl-docs/SKILL.md](../../.claude/skills/thl-docs/SKILL.md) e registrada na tabela de tarefas do `AGENTS.md`; criado o [notion-map.md](notion-map.md) vazio, com candidatas a publicação. Verificado por leitura e comparação de frontmatter, sem execução.

**Atualização 19/10/2026 (skill thl-docs, Postman):** o passo 7 da skill [thl-docs](../../.claude/skills/thl-docs/SKILL.md) virou um procedimento executável pelo conector do Postman (subpasta junto, examples por cenário, segredos fora do repositório, apagar só com confirmação), e o caminho da collection foi corrigido para `THL-Library > THL`. Verificado por leitura; o fluxo não foi executado contra o Postman.

**Atualização 19/10/2026 (dicionário de cadastros):** as seis notas de `Documentos/obsidian/THL/` (grupo thl003, conexão REST) foram movidas para [thl/cadastros/](thl/cadastros/cadastros-thl.md), com nomes em kebab-case, wikilinks trocados por links relativos e frontmatter padrão; a pasta `obsidian/` deixa de ser destino de notas. Verificado por leitura e checagem de links, sem execução.

**Decisão 19/10/2026 (métricas de e-mail):** cartão conta `programa + paramAmbiente` e a listagem conta só `programa` — divergência por desenho (250 × 268 no caso `tkn4001e`), mantida a pedido; ver [web/app-web.md](web/app-web.md).

**Atualização 19/10/2026 (monitor de e-mail):** `STATUS_EMAIL_LABELS` passa a incluir `Pendente` e o monitor ganhou o chip — o e-mail pendente aparecia sem status e fora de todos os chips. Ver [web/poui-licoes.md](web/poui-licoes.md).

**Atualização 19/10/2026 (pacotes web):** `META-INF` e `WEB-INF` saíram dos dois pacotes a pedido — `dist	hl-html-consulta` e `dist	hl-html-cadastro` passam a conter só as subpastas `html.*`. Sem `WEB-INF/web.xml` o Tomcat perde o recurso vigiado que recarregaria o contexto na publicação. Ver [web/app-web.md](web/app-web.md).

**Atualização 19/10/2026 (métricas gerais):** o cartão Mensageria da tela raiz deixa de contar o tráfego interno do THL (`interna = true`) por padrão — era gerado pelo próprio monitor e fazia a tela geral divergir da de mensageria (124 × 4 no mesmo período) — e a tela ganhou o mesmo botão de tráfego interno da de mensageria, com estado em `?internas=1` — ver [web/app-web.md](web/app-web.md). Verificado com `ng build web` e executando a linha do serviço sobre dados no formato do retorno real.

**Atualização 19/10/2026 (deploy web):** `build-deploy.ps1` e `build-deploy-cadastro.ps1` publicam em duas fases (copia para `<pasta>.novo`, confere `index.html` e contagem de arquivos, troca por rename com desfazimento) em vez de apagar as subpastas antes de copiar, e passam a gerar `WEB-INF\web.xml` nos dois pacotes — regravado a cada publicação para recarregar o contexto no Tomcat. Ver [web/app-web.md](web/app-web.md). Verificado: publicação limpa OK, publicação com arquivo travado abortou sem alterar o publicado, e o `web.xml` gerado é XML válido (467 bytes, UTF-8 sem BOM).

**Atualização 13/10/2026 (Obsidian, Fase 3):** frontmatter padronizado (`tipo`, `camada`, `status`, `tags`) em todas as notas da KB e pasta [moc/](moc/moc-geral.md) com seis mapas por módulo; links continuam Markdown relativos (sem wikilinks, regra do `AGENTS.md`). `camada: ambos` marca nota que atravessa core e extensão.

**Atualização 13/10/2026 (revisão documental, Fase 2):** nota de tela `thl0120c` (detalhe do conteúdo da mensagem) em [thl/camada-datasul.md](thl/camada-datasul.md); referências de linha do `AuditLogService` corrigidas em [logging/auditoria.md](logging/auditoria.md); contagem de classes corrigida para **145 (94 + 51)**; contagem de fontes ABL ainda em UTF-8 atualizada em [convencoes.md](convencoes.md) §1. **Divergência de código × cadastro:** `MetricsProcessor` e `IMetricsService` estão em `thl-extensions`, mas as cargas e scripts de acerto gravam `thl-lib.integration.messaging.inbound.process.MetricsProcessor` — corrigido nas notas, **cadastros e scripts não foram alterados** ([TD-001](tech-debt/REGISTRO.md)). Novo [tech-debt/REGISTRO.md](tech-debt/REGISTRO.md) e três ADRs retroativas: [separacao-core-extensoes](adr/separacao-core-extensoes.md) e [codificacao-iso-8859-1-crlf](adr/codificacao-iso-8859-1-crlf.md) (aceitas) e [niveis-sensibilidade-auditoria](adr/niveis-sensibilidade-auditoria.md) (**proposta**: aguarda decisão sobre 5/9). Por leitura, sem compilação.

**Atualização 13/10/2026 (rota):** `thl-objeto-rota` com chave aplicação + objeto + rota pública (várias rotas por objeto; `idx-rota-publica` único); `NotaFiscalProcessor` pega a etapa pela última parte e o Service pela linha do thl0022. ADR §15 e §16 de [adr/operacao-acao-extensao-rest.md](adr/operacao-acao-extensao-rest.md). Não compilado.

**Atualização 13/10/2026 (telas, chave e combo):** vá para do `thl0021` pela chave inteira (aplicação + objeto; o `ut-table.i` apontava para tabela de cliente); zooms `thl0021-b01`, `thl0040-b01` e `thl0050-b01` com faixa também por aplicação, objeto e banco; `thl0051c` com o viewer no tamanho do `thl0051b-v01` (botões cobertos) e nível de sensibilidade em COMBO-BOX. Escrito, sem compilação nem abertura no AppBuilder. ⚠️ Divergência a decidir: o `thl.df` descreve 5=Restrito/9=Crítico; as telas, o include `i01thl026.i`, o web e as notas usam 5=Crítico/9=Restrito.

**Atualização 13/10/2026 (automatizador):** nova `ProcessoExportacaoMessage` (outbound, Multiple) e RPW `esex1987rp.p` no lugar do envio direto de `esex1986rp.p`; escrito, sem compilação nem teste. Detalhe em [extensions/automatizador.md](extensions/automatizador.md).

**Atualização 13/10/2026 (ambiente):** `core/environment.md` e `fluxos/fluxo-ambiente.md` diziam que `findEnvironmentCodeByPropath` devolve um ambiente de fallback quando nenhum `ip` casa; o código lança `ThlError`. Corrigido por leitura estática (não executado).

**Atualização 16/10/2026 (web, visual dos cartões e sentido):** o `thl-metric-card` passou a ter **duas escalas e dois significados de cor** — nas telas de assunto a moldura é estado; em Métricas gerais é só separação por assunto (azul/roxo/verde-azulado, fora da paleta de estado) com `[grande]` e tipografia maior. Cartões ganharam sombra (combinada com a barra lateral `inset`), ícones do menu nos títulos e ícone por linha. No monitor da mensageria entrou o **seletor de sentido** na faixa da engrenagem, no mesmo molde dela, e a coluna Dispositivo ganhou o avião via `p-table-column-template` (que exige `type: 'columnTemplate'`).

**Atualização 16/10/2026 (web, tarde):** tela raiz renomeada para **Métricas gerais**; o cartão dela contava erro só do processamento e contradizia o aviso da própria tela (agora os dois saem do mesmo `comErro`, por pior estado entre as fases); o **"duplo clique" da mensageria e do e-mail era detecção de mudanças** — o app é **zoneless** e o `setTimeout` que abria o modal não agendava CD, então ele abria invisível (lição em `poui-licoes.md`, com a regra de fechar todo `setTimeout` com `markForCheck()`); cartões da auditoria passaram a ter a cor da **ação predominante**.

**Atualização 16/10/2026 (web, cartão de métrica em tabela de fases):** cada fase virou linha com quatro colunas (sucesso · pendente · erro · n/a) sob cabeçalho de ícones — os mesmos dos chips, o que dispensa legenda. As quatro somam o total do cartão, deixando as fases comparáveis; a coluna N/A evita que retorno inexistente pareça sucesso. Saúde ficou, com `an-heartbeat`, e a borda passou a usar o pior estado (erro > alerta > sucesso) no tratamento do chip selecionado. E-mail tem fase única; auditoria segue inalterada. Corrigida colisão entre o modificador de estado e as classes de cor (`--estado-*`).

**Atualização 16/10/2026 (web, ajustes com o ambiente real):** colunas da auditoria alargadas (Operação 160, Dt. Criação 200, Usuário 150) porque as larguras medidas em dados de teste cortavam o conteúdo real; Retorno e Parâmetro do detalhe de e-mail ganharam **realce de JSON** (`shared/domain/json-view.ts`), com quebra de linha e desembrulho de JSON gravado dentro de string; e `.po-tooltip { pointer-events: none }` global, para que nenhum tooltip preso consuma o primeiro clique no menu de ações. O duplo clique em mensageria/e-mail **não foi reproduzido em dev** — confirmar com o pacote novo publicado.

**Atualização 15/10/2026 (web, estado na navegação):** voltar para uma tela não recomeça mais do zero — `pagina` (quantas páginas do "Carregar mais") nos três monitores, `chip` e `todos` nas três telas de métricas, e rolagem restaurada por `withInMemoryScrolling` nos dois apps. Restaurar a página não custa requisição: a paginação é fatiada no navegador. A restauração só é consumida quando há linhas (senão a carga que falha a gastava) e a URL guarda a página **desejada**, não a atual (senão o parâmetro se apagava na entrada). Cache dos dados ficou de fora de propósito.

**Atualização 15/10/2026 (web, tooltip preso no menu):** o tooltip do `po-menu` recolhido não sumia ao tirar o mouse e **acumulava** um por item visitado (defeito do PO UI, reproduzido do zero). Contorno em `shared/directives/thl-menu-tooltip-fix.directive.ts`, aplicado ao `<po-menu>` do `app.html` — shell comum aos dois apps. Ele avisa os itens de que o ponteiro saiu em vez de remover o elemento na mão, deixando a diretiva do PO UI limpar. Diagnóstico medido em `poui-licoes.md`.

**Atualização 15/10/2026 (web, seletor de período em ícones):** as telas de métricas trocaram os rótulos por **cronômetro com 1** (1h) e **calendário com 1 · 7 · 21** (dias), mais `an-calendar-gear` no Personalizado; barra de 398px para 320px. Os ícones são **SVG inline** no `thl-filter-tabs`, porque o `an-calendar` da fonte Animalia tem "12" impresso no glifo. `ThlFilterTab` ganhou `glifo`, `icone` e `tooltip` — o `label` segue curto por também virar subtítulo da página. Centralização dos dígitos medida pelo `getBBox` (desvio 0,00). ⚠️ tooltip não existe em toque.

**Atualização 15/10/2026 (web, atalhos de período):** os filtros avançados dos três monitores ganharam **Hoje · 7 dias · Mês · Mês anterior** (`thl-date-shortcuts`), como links discretos **abaixo** do campo, que **preenchem os campos de data à vista** em vez de filtrar escondido; dias inteiros, 00:00 a 23:59. Dentro do calendário não dá: o `po-calendar-footer` do PO UI é interno e não projeta conteúdo (registrado em `poui-licoes.md`). Digitar data na mão volta para Personalizado e Limpar solta o atalho. A mensageria mostra aviso de expurgo acima de 21 dias com a data-limite calculada — a retenção é por objeto (21 sucesso / 42 erro), por isso o texto diz "pode". Trimestral ficou de fora: os monitores ainda não enviam `page`/`pageSize` e baixam a faixa inteira no navegador. Verificado no navegador.

**Atualização 15/10/2026 (web, ajustes nos monitores):** menu da coluna Ação passou a abrir **ao lado** (`p-position="right-bottom"`) — na posição padrão ele cobria o "⋯" das linhas de baixo e o clique caía no menu da linha anterior, o que o usuário via como "clicar duas vezes"; vale para os três monitores e os nove cadastros. Mensageria sem `Código do status` e `Descrição do retorno` no browse; e-mail com `Dt. Envio` e `Status` na frente e sem `Programa`/`Ambiente`; auditoria com larguras **em px** e `Campos` elástica (o `po-table` **ignora porcentagem** — medido); cartões de métrica com falha ganham sombreado vermelho suave. Verificado no navegador com linhas injetadas; **nada conferido contra PASOE**. As três listas passaram a vir **mais recentes primeiro** (`maisRecentePrimeiro()` em `shared/domain/ordenacao.ts`): a API devolve agrupada e sem ordenação, e o `po-table` não tem ordenação inicial, então o subtítulo das telas declara a ordem. O JSON formatado no detalhe de e-mail ficou de fora desta rodada.

**Atualização 14/10/2026 (web, Painel de Cadastros):** `#/` do app `cadastro` deixou de redirecionar para Ambiente e virou o **Painel de Cadastros**: os nove cadastros em três grupos, cada um com uma linha dizendo para que serve. A tela **não faz nenhuma requisição** — a contagem de registros foi retirada a pedido do usuário, e com ela sumiram carregando, erro e a dependência do `total` que a API não devolve. Cada destino é uma âncora (`thl-nav-card`, novo em `shared/components`), com Ctrl+clique e foco por teclado funcionando. Títulos vêm das definições do motor; descrições ficam no componente. Verificado no navegador: zero chamadas em `/api/`, navegação e anel de foco.

**Atualização 14/10/2026 (web, filtro dos monitores na URL):** completa a correção de estado: os três monitores guardam filtro avançado, busca rápida e chip de situação em `queryParams` (`shared/domain/filtro-url.ts`, `replaceUrl: true`). Sair e voltar restaura tudo, inclusive o chip marcado e o texto no campo. Os parâmetros curtos dos atalhos das métricas continuam valendo e prevalecem sobre as chaves longas; ao carregar, a URL é reescrita na forma longa. Verificado no navegador: os três atalhos de cartão seguem aplicando o filtro, e **nenhum cenário voltou a duplicar a consulta** (seis rotas testadas, 1 chamada cada).

**Atualização 14/10/2026 (web, consulta duplicada e período na URL):** dois defeitos reproduzidos e corrigidos. (1) Abrir monitor com filtro na URL fazia **duas consultas idênticas** — o `(p-change)` do `po-disclaimer-group` dispara também quando a tela monta a lista, e o handler de remoção recarregava; agora os três monitores comparam a assinatura da lista que montaram. Remover chip continua funcionando. (2) As quatro telas de métricas guardam o período em `queryParams` (`atalho`, `ini`/`fin` no personalizado, `internas=1` na mensageria): voltar restaura o que estava escolhido e o link ficou compartilhável — antes a tela voltava ao padrão de 24h porque a rota é lazy. Verificado no navegador com `XMLHttpRequest` instrumentado. ⚠️ O filtro dos **monitores** continua sem persistência.

**Atualização 14/10/2026 (web, filtro da mensageria em abas):** os 18 campos viraram duas abas — **Principal** (datas, aplicação, objeto, operação: consultam a base) e **Avançado** (Cód. Mensagem + os seis filtros que atuam só sobre o que já está carregado). O levantamento revelou que **6 dos 18 campos nunca foram para a API** (`aplicarFiltrosLocais`), sem nada na tela dizendo isso: agora há aviso sobre esse grupo. Cód. Mensagem ficou na segunda aba por decisão de uso, então a aba tem duas seções e o aviso cobre apenas o grupo local. Contador por aba e `Limpar` nas duas verificados no navegador. Lição nova em [web/poui-licoes.md](web/poui-licoes.md): campo em `po-tab` oculto **funciona** (ao contrário do `po-table`), e `p-active` é booleano. ⚠️ Pendência para `thl-coding`: aceitar `metodo`, `dispositivo`, as situações e `codStatusRetorno` como query param no `MensageriaService.cls` dispensaria a seção local e o aviso.

**Atualização 13/10/2026 (web, filtro com hora):** os filtros avançados dos três monitores passaram de `po-datepicker` para **`po-datetimepicker`** — o usuário informa data **e** hora. Três armadilhas do componente foram descobertas rodando e estão em [web/poui-licoes.md](web/poui-licoes.md): o modelo é texto ISO **com fuso**; campo incompleto grava a string `"Data/hora inválida"` no modelo (chegou a virar filtro antes da correção); e incompleto **não é sinalizado** (fica `ng-valid`), então o valor digitado é lido do input como resgate e data sem hora vale o dia inteiro. O filtro da mensageria passou a 2 campos por linha (`po-md-6`): em `po-md-3` o rótulo e o placeholder truncavam. Verificado nos três monitores pela query string, com hora digitada e com data sozinha.

**Atualização 13/10/2026 (web, data e hora nas listagens):** o backend passou a ler as três listagens com `getDateTime`, e o front foi alinhado. O filtro avançado dos monitores completa o dia escolhido (`T00:00` / `T23:59`) pelo novo `diaParaFaixa` em `shared/domain/periodo.ts`, e as navegações de cartão deixaram de cortar a hora (quatro `substring(0,10)` removidos). O texto do filtro ativo usa `rotuloDeDataHora`, que esconde 00:00/23:59 e mostra a hora quando ela foi escolhida. ⚠️ Como `parseDateTime` exige 16 caracteres, **toda consulta filtrada estava falhando** entre a mudança do backend e esta correção. Também mudou o padrão do backend sem filtro: antes 3 dias (mensageria) e 30 dias (e-mail, auditoria), agora **24 horas** nas três. Verificado no navegador pela query string das três rotas; sem PASOE real.

**Atualização 09/10/2026 (web, nomes dos arquivos de rota):** `mensageria-routing.module.ts`, `email-routing.module.ts` e `auditoria-routing.module.ts` renomeados para `<feature>-routing.ts`, o padrão que a skill define e que `metricas` já seguia — o sufixo `.module` era herança dos NgModules, que não existem mais. Renomeado com `git mv` (histórico preservado) e os três imports de `app.routes.ts` ajustados. As oito rotas foram percorridas no navegador e os lazy chunks continuam separados por feature.

**Atualização 09/10/2026 (web, remoção do Dashboard Msg):** tela removida (850 linhas em 11 arquivos) por duplicar `#/mensageria/metricas` com outro recorte. `#/dashboard-mensageria` virou **redirect** para `mensageria/metricas`. Removidos por ficarem sem referência: `MensageriaDashboardService`, `integration-card`, `integration-route.model.ts`, `health-score.pipe.ts`, `relative-time.pipe.ts` e o `dashboard-mensageria.model.ts` (este já órfão desde 08/10). Build limpo e redirect verificado no navegador. Removido também o `mensageria.module.ts`, que era o **último `@NgModule` do projeto** e não tinha importadores — resíduo da migração para standalone. O app `web` agora não tem nenhum NgModule.

**Atualização 09/10/2026 (web, menu da consulta):** as telas de métricas saíram do botão no cabeçalho dos monitores e viraram itens do **menu lateral**, agrupados por assunto com linha divisória: Métricas · Mensageria + Métrica Mensageria · E-mail + Métrica E-mail · Auditoria + Métrica Auditoria. O `p-actions` dos três monitores foi removido (e o `Router` que só ele usava). ⚠️ O **Dashboard Msg** deixou de ter entrada no menu — a rota `#/dashboard-mensageria` continua válida por URL; decidir se é removida.

**Atualização 09/10/2026 (fluxos):** nova pasta [fluxos/](fluxos/) com as quatro visões ponta a ponta — entrada, saída, ambiente e e-mail —, escritas a partir da leitura do código e ligando cada etapa ao cadastro que a governa. A leitura corrigiu quatro pontos que estavam errados na documentação: a resolução de rota usa `thl-objeto-rota` (não `thl-inbound-rota`) e tem busca por prefixo e `inicio-operacao`; `thl-objeto-parametro.cod-param-ambiente` guarda **nome de variável**, não de parâmetro, e o parâmetro vem do vínculo `APLICACAO.OBJETO` em `thl-ambiente-param-prog`; essa tabela de vínculo é **funcional e obrigatória**; e o e-mail alternativo **soma** ao endereço do `usuar_mestre`, não substitui. `messaging-inbound.md` foi corrigida; as demais notas por classe já estavam certas.

**Atualização 09/10/2026 (documentação para pessoas):** novo [../negocio/guia-telas-web.md](../negocio/guia-telas-web.md) — guia das 14 telas web, uma seção por tela, com finalidade, programa Datasul equivalente, rota da API, tabelas usadas e o que cada campo faz (97 campos dos 9 cadastros, mais filtros e colunas dos monitores). O [../negocio/guia-cadastros-thl.md](../negocio/guia-cadastros-thl.md), que cobre os programas .w, recebeu aviso de desatualizacao: nao acompanhou as mudancas de outubro (rota como aba do objeto, Origem na aplicacao, metodo na chave da operacao, classes por operacao).

**Atualização 09/10/2026 (web, revisão do modelo de cadastros):** registrada em [web/motor-cadastro.md](web/motor-cadastro.md) a comparação medida entre o motor genérico e um componente por cadastro — bundle, runtime e o teste de que o motor não conhece nenhum cadastro pelo nome —, além do critério para abrir exceção e dos sinais de alerta. Inventário da parte web revisado: dois componentes órfãos (`email-detail`, `mensagem-detail`, 356 linhas) que a limpeza de 08/10 não pegou, anotados em [web/app-web.md](web/app-web.md); **ainda não removidos**.

**Atualização 09/10/2026 (web, lotes C e D):** a tela **Métricas** da raiz virou resumo — três cartões (`thl-metric-card`), um por assunto, com atalho **Ver métricas** para `/<assunto>/metricas`; saíram o KPI antigo, os cartões de fase e 261 linhas de SCSS próprio (a tela passou a usar o estilo compartilhado). O seletor de período foi unificado em `thl-period-filter` (1h · 24h · 7 dias · 21 dias · Personalizado com hora) na raiz e no Dashboard Msg: com isso caiu o atalho **30d** do dashboard, que `faixaDoAtalho` não conhecia e que buscava 24 horas prometendo 30 dias. Detalhes: `role="alert"` no erro do período, `aria-pressed` nos chips, o dashboard deixou de travar a tela ao carregar, chip de erro marcado por chave e não por índice, e o aviso `NG8107` do build foi resolvido. Build dos dois apps limpo; telas verificadas no navegador.

**Atualização 09/10/2026 (web, lote A — a tela não pode enganar):** estado de erro e estado de vazio viraram os componentes compartilhados `thl-error-state` e `thl-empty-state`, usados nas 8 telas dos dois apps. Corrigidos dois casos em que a falha não se apresentava como falha: a tela **Métricas** da raiz engolia o erro e ficava em branco, e o **Dashboard Msg** zerava a lista e afirmava "não há rotas de integração no período". Também: o placeholder da busca dos três monitores passou a dizer que o filtro é local; o motor ganhou vazio orientado na lista principal; e o alerta da raiz deixou de anunciar o período escolhido para um número que é sempre de 24 horas. Descoberto no caminho: `.thl-erro`, `.thl-crud-erro` e `.empty-container` nunca tiveram estilo. Build dos dois apps e telas verificadas no navegador (erro real, sem PASOE; vazio com o mock).

**Atualização 08/10/2026 (validador):** script `Utils/scripts/validador-endpoints/` valida os endpoints da collection Postman (pasta THL-Library > THL) com tela HTML local; guia em [../tecnico/guia-validador-endpoints.md](../tecnico/guia-validador-endpoints.md). Testado só contra servidor simulado.

**Atualização 09/10/2026 (web, revisão das métricas):** seis correções apontadas em revisão de código. Dois defeitos de comportamento: os chips "Entregues"/"Sem erro"/"Pendentes" filtravam os cartões **com falha** (tipo do filtro não cobria as chaves dos chips) e o atalho do cartão não levava o período para o monitor. Mais: dashboard deixou de exibir método fixo `POST` (a rota de métricas não devolve o método), nível de sensibilidade fora do domínio passa a aparecer cru, e os campos do período personalizado nascem no período em uso. Verificado no navegador tela a tela.

**Atualização 08/10/2026 (web, limpeza):** removidos os componentes sem rota `src/app/dashboard/`, `mensageria/pages/dashboard-mensageria/` e o `dashboard-mensageria.service.ts` que só ela usava — 7 arquivos, 948 linhas, nenhuma referência fora deles. As oito rotas do app foram percorridas depois da remoção, sem erro.

**Atualização 08/10/2026 (web, métricas — fonte única):** a tela de Métricas da raiz e o Dashboard Msg passaram a consumir `<assunto>/metricas`, eliminando a divergência com as telas novas (antes somavam listagens limitadas por página); atalho de 30 dias virou 21. Também: troca de período cancela a busca anterior, grade limitada a 12 cartões com "Ver todos" e "última atualização" no cabeçalho. ⚠️ A navegação do dashboard para a listagem envia **só data** — a hora vale apenas nas rotas de métricas.

**Atualização 08/10/2026 (web, métricas — correções):** o atalho dos cartões passou a filtrar de verdade (auditoria e e-mail não liam queryParams; o e-mail navegava com `programa` em vez de `codProgDtsul`), e a faixa personalizada acima de 21 dias passou a avisar sobre o expurgo. Verificado no navegador com estado injetado.

**Atualização 08/10/2026 (web, métricas):** três telas `<assunto>/metricas` no app de consulta, sobre as rotas novas do backend, com filtro de data **e hora** (`yyyy-MM-ddTHH:mm`) e atalhos até 21 dias (retenção). Peças compartilhadas: `periodo.ts`, `metricas.service.ts`, `thl-period-filter`, `thl-metric-card`. Acesso pela ação Métricas em cada monitor. Verificado com dados injetados no componente; **sem chamada real ao PASOE**.

**Atualização 08/10/2026 (web, lote 3):** tela de **Aplicação** (thl0020) no menu Integração, com `indInterna` como Origem (Interna/Externa) — é o campo que separa o tráfego do próprio THL nas métricas. Novo `links` no `CrudResource`: atalho **Ver objetos** abre `objeto` filtrado pela aplicação, via `?aplicacao=THL`, com tag do filtro e botão **Limpar filtro**. Verificado no mock; sem teste contra PASOE.

**Atualização 08/10/2026 (web, lote 2):** Rota virou a terceira aba do Objeto (`objeto/rota`, uma por objeto) e saiu do menu — `#/rota` redireciona para `#/objeto`; `tipoGravaConteudo` no parâmetro do objeto; a confirmação de exclusão passou a dizer o que a cascata leva junto (`cascadeDelete`), e o erro de exclusão mostra a mensagem do backend. Verificado no mock; sem teste contra PASOE.

**Atualização 08/10/2026 (web):** app de cadastro alinhado às URLs `pai/filho` (lote 1) — nove recursos de filho em `cadastros.defs.ts` e no mock; o motor não mudou, só o texto do `resource`. Verificado no mock; sem teste contra PASOE. ⚠️ Resta a tela de Rota, que ainda aponta para `inbound-rota` (URL extinta). Detalhe em [web/app-web.md](web/app-web.md).

**Atualização 08/10/2026:** exclusão em cascata nos cadastros pai (thl0001, thl0011, thl0021, thl0030, thl0050 e as APIs correspondentes), seguindo o thl0002; thl0020 segue bloqueado. Não compilado. Detalhe em [CHANGELOG.md](CHANGELOG.md).

**Atualização 06/10/2026:** rota com início da operação (`thl-inbound-rota.inicio-operacao`) para URL de três níveis; nota fiscal em um objeto com `NotaFiscalProcessor`. Detalhe em [adr/operacao-acao-extensao-rest.md](adr/operacao-acao-extensao-rest.md) §8.

**Atualização 05/10/2026:** operação com ação neutra na chave, classes por operação e extensão REST (verbo, campos obrigatórios, chave externa); contrato do payload pelo cadastro; restam 2 Messages de entrada (as de máscara de segredo). Escrito, sem compilação nem teste. Detalhe em [adr/operacao-acao-extensao-rest.md](adr/operacao-acao-extensao-rest.md).

**Atualização 04/10/2026:** entrada em três camadas — `InboundMessage` (concreta) → `Processor` → `Service` (sem `execute`); classes de message, processor e service no cadastro do objeto; um objeto por agregado com os filhos como operação da URL. Escrito, sem compilação nem teste. Detalhe em [adr/inbound-message-processor-service.md](adr/inbound-message-processor-service.md).

**Atualização 03/10/2026:** ADR de métricas, situação geral da mensagem, gravação de conteúdo, aplicação interna e expurgo aceita; as oito fases do backend estão escritas, sem compilação nem teste (delta do banco gerado e não carregado; as fases 4 a 8 só compilam com ele). Detalhe em [adr/metricas-conteudo-expurgo-mensagens.md](adr/metricas-conteudo-expurgo-mensagens.md).

**Atualização 02/10/2026:** lote 3 concluído; referências e contagens sincronizadas, limitação inbound agendada registrada. Histórico completo em [CHANGELOG.md](CHANGELOG.md).

## Como consultar

Comece por [convencoes.md](convencoes.md) e [arquitetura.md](arquitetura.md); abra apenas a nota do pacote pertinente. Confirme assinaturas e comportamento no código quando a precisão importar.

| Conteúdo | Autoridade e uso |
|---|---|
| Convenções e ADR aceita | Regra ou decisão aprovada; aprovação não comprova implantação |
| Nota de pacote | Descrição atual, confirmável no código |
| ADR proposta e backlog | Alternativa ou planejamento; não autoriza implementação |
| Catálogo PO UI e pesquisa | Referência externa; priorize decisões do projeto e confirme versão |
| Changelog, relatórios e arquivo | Evidência histórica; não define comportamento atual |

## Mapa de documentos

| Arquivo | Descrição |
|---|---|
| [moc/moc-geral.md](moc/moc-geral.md) | **Mapas de navegação (Obsidian)**: MOCs de Ambiente, E-mail, Mensageria, REST/Conectores, Auditoria e Jobs RPW; só links, sem conteúdo duplicado; vocabulário do frontmatter |
| [notion-map.md](notion-map.md) | **Mapa de publicação no Notion**: nota → página Notion (ids), com as guias candidatas de `negocio/` e `tecnico/` |
| [convencoes.md](convencoes.md) | **Convenções do projeto** — codificação **ISO-8859-1**, pacote = pasta em minúsculas, onde colocar o código, nomes |
| **Núcleo (`thl-lib`)** | |
| [core/context.md](core/context.md) | `ContextService` — usuário do SO, usuário Datasul (`getErpUser` via `thl/api/geterpuser.p`) e call stack |
| [core/environment.md](core/environment.md) | `EnvironmentUtil`, `EnvironmentContext`, `EnvironmentResource` (Facade), `EnvironmentRepository` — ambiente e parâmetros |
| [core/error.md](core/error.md) | `ThlError` (formata `msg [Classe.metodo]`) e `ErrorHandler` (acumulação e conversão de erros) |
| [erp/erp-services.md](erp/erp-services.md) | **Processor e Service**: `Processor` (orquestração, `execute`), `Service` abstrata (regra; verbos públicos, sem `execute`), bases `BusinessObject`/`ApplicationProgrammingInterface`, `ServiceResponse`, enums e os 14 Services de `thl-lib.erp.service` |
| [integration/connectors.md](integration/connectors.md) | Conectores REST: config, request/response, `RestConnector`, factories, `ITokenProvider`, `IHeaderProvider` |
| [integration/messaging-core.md](integration/messaging-core.md) | `Message`, `MessageConfig`, enums Direction/ExecutionMode/Status, `MessageFactory`, `MessageConfigLoader` (pai abstrata) e os carregadores `InboundConfigLoader`/`OutboundConfigLoader`, `MessageRepository` |
| [integration/messaging-outbound.md](integration/messaging-outbound.md) | `OutboundMessage`, `OutboundObjectContext`, estratégias Single/Multiple, `MessageExecutionService`, `OutboundMessageService`, `SchedulingService` |
| [integration/messaging-inbound.md](integration/messaging-inbound.md) | **Fluxo REST completo** (`resourcen.p` → `InboundRouteResolver` → `InboundMessageService` → `InboundMessage` → `Processor` → `Service`), `InboundConfigLoader` e as 9 mensagens inbound de `thl-lib` |
| [fluxos/fluxo-entrada.md](fluxos/fluxo-entrada.md) | **Fluxo ponta a ponta — entrada**: cadeia de chamadas, resolução de rota (`thl-objeto-rota`, prefixo, `inicio-operacao`), posicionamento da operação pelo método, situações e o cadastro que governa cada etapa |
| [fluxos/fluxo-saida.md](fluxos/fluxo-saida.md) | **Fluxo ponta a ponta — saída**: montagem, a indireção variável → conexão/path, autenticação, reprocessamento e armadilhas (BATCH não age) |
| [fluxos/fluxo-ambiente.md](fluxos/fluxo-ambiente.md) | **Fluxo ponta a ponta — ambiente**: PROPATH, vínculo programa → parâmetro, fallback `*`, cache de sessão |
| [fluxos/fluxo-email.md](fluxos/fluxo-email.md) | **Fluxo ponta a ponta — e-mail**: `codigo.email`, destinatários que somam, utapi019 e o registro condicionado a `log-gerar` |
| [communication/email.md](communication/email.md) | `EmailMessageFactory`, `EmailService` (utapi019), `EmailLogger`, `EmailParamRepository` |
| [logging/logging.md](logging/logging.md) | `LogUtil` (log-manager) e `AuditLogService` (tabelas `thl-audit-*`) |
| [logging/auditoria.md](logging/auditoria.md) | **Módulo de auditoria de ponta a ponta**: gravação pela trigger, consulta, cadastros, expurgo, achados e plano de desempenho |
| [util/util.md](util/util.md) | `StringUtil`, `JsonSetter`, `JsonWriter`, `FileUtil`, `PaginationHelper`, `SchemaUtil`, `JsonArrayCsvExporter`, scanner (4) e compile (3) |
| **Extensões (`thl-extensions\{erp,integration}\<sistema>\`)** | |
| [extensions/thl.md](extensions/thl.md) | API REST dos cadastros e consultas do próprio THL: um Service por tabela, **um objeto por agregado** (filhos como operação da URL), Processors de agregado, 2 Messages de máscara, carga `.p`, acerto das classes e script pelos endpoints |
| [extensions/automatizador.md](extensions/automatizador.md) | `LpcoMessage` outbound e inbound, `LpcoService` (`nit-lpco`) |
| [extensions/dvv.md](extensions/dvv.md) | `FreteMessage` inbound, `FretePrevistoService` (`nit-frete-prev`), `SituacaoFreteEnum` |
| [extensions/gestaoepi.md](extensions/gestaoepi.md) | `HeaderProvider` (HMAC-SHA256), `RequisicaoMessage`, `ItemRequisicaoMessage` |
| [extensions/iacompras.md](extensions/iacompras.md) | `ProcessoCompraMessage` (processo de compra, fornecedores, ordens) |
| [extensions/loogai.md](extensions/loogai.md) | `EntregaPedidoMessage`, `NotaFiscalMessage`, `StatusDocumento` (outbound); `LoogAiDocumentoMessage`/`Service`, `LoogAiEmbarqueMessage`/`Service` (inbound) |
| [extensions/mmcm.md](extensions/mmcm.md) | `TokenProvider` (parser `data.data.token`), `PrePedidoMessage`, `PedidoMessage` |
| [extensions/ninahub.md](extensions/ninahub.md) | `ChamadoMessage` (outbound), `NinahubNotaFiscalMessage`/`Service` (inbound NF) |
| [extensions/powerautomate.md](extensions/powerautomate.md) | `SolicitacaoCompraMessage` (ordem de compra / solicitação), `OrderStatusEnum`, `RequestStatusEnum` |
| **Dados, camada Datasul e web** | |
| [data/schema.md](data/schema.md) | Tabelas `thl-*` por domínio, relações, domínios de códigos e divergências `.df` × código |
| [data/er-diagrama.md](data/er-diagrama.md) | Diagrama (Mermaid) dos vínculos entre as 30 tabelas THL — contínua = `fk-*`, tracejada = só código/valor; gerado por `Utils/scripts/gerar-er-diagrama.py` |
| [thl/cadastros/cadastros-thl.md](thl/cadastros/cadastros-thl.md) | **Dicionário de campos das telas de cadastro**: índice por grupo; gerado só o grupo thl003 (conexão REST: thl0030–thl0033), aguardando revisão. Páginas ligadas no Notion — ver [notion-map.md](notion-map.md) |
| [thl/camada-datasul.md](thl/camada-datasul.md) | Telas `thlNNNN`, monitores, RPWs (`thl0220rp`/`thl0221rp`/`thl0222rp`), `thl0220z.p`, `geterpuser.p`, endpoint `resourcen.p`, includes |
| [web/app-web.md](web/app-web.md) | App Angular + PO UI: rotas, serviços, endpoints `resourcen`, componentes `thl-*`, build/deploy |
| [web/motor-cadastro.md](web/motor-cadastro.md) | Contrato do motor genérico de cadastros: `CrudResource`/`CrudField`, regras, decisões de layout e cor, cadastros em uso, domínios, pendências da v2 |
| [web/poui-licoes.md](web/poui-licoes.md) | Armadilhas do PO UI 21 confirmadas rodando (o que o componente **não** faz) |
| [poui/INDEX.md](poui/INDEX.md) | KB de referência PO UI 21 (15 notas) para gerar telas web |
| **Decisões e planejamento (consulte o status)** | |
| [adr/api-rest-cadastros-thl.md](adr/api-rest-cadastros-thl.md) | ADR aceita: API REST e uma Message por agregado, um Service por tabela |
| [adr/arquitetura-front-end-web.md](adr/arquitetura-front-end-web.md) | ADR (aceita e aplicada, 2026-10-02): dois apps separados, cadastro como definição do motor, standalone por feature, mock por `fileReplacements` — com alternativas descartadas e pontos em aberto |
| [adr/auditoria-desempenho-trigger.md](adr/auditoria-desempenho-trigger.md) | ADR (**proposta**, 2026-10-02): desempenho da gravação de auditoria na trigger — cache por sessão, temp-table reaproveitada, restrições de PASOE e formato do snapshot |
| [adr/get-no-execute-do-service.md](adr/get-no-execute-do-service.md) | ADR (aceita, 2026-10-03; **parcialmente substituída** em 2026-10-04): GET no mesmo caminho dos outros verbos — ação `Consultado`, `consult()`, `QueryParameters`; o `execute` foi para o `Processor` |
| [adr/inbound-message-processor-service.md](adr/inbound-message-processor-service.md) | ADR (aceita, 2026-10-04; aplicada, não compilada): Message padrão → `Processor` → Service; classes no cadastro do objeto; um objeto por agregado, filho como operação da URL; carregador pai + inbound/outbound |
| [adr/operacao-acao-extensao-rest.md](adr/operacao-acao-extensao-rest.md) | ADR (aceita, 2026-10-04; aplicada, não compilada): ação neutra na chave da operação, classes por operação, extensão REST (verbo, campos obrigatórios, chave externa), contrato do payload pelo cadastro e revisão das Messages específicas |
| [adr/metricas-conteudo-expurgo-mensagens.md](adr/metricas-conteudo-expurgo-mensagens.md) | ADR (aceita, 2026-10-03, em aplicação por fases): rotas de métricas, situação geral da mensagem, gravação de conteúdo por operação, aplicação interna e expurgo com dois prazos |
| [adr/separacao-core-extensoes.md](adr/separacao-core-extensoes.md) | ADR (aceita, retroativa, 2026-10-13): `thl-lib` genérico × `thl-extensions` por sistema; core sem tabela de cliente; classes ligadas por cadastro e `dynamic-new` |
| [adr/codificacao-iso-8859-1-crlf.md](adr/codificacao-iso-8859-1-crlf.md) | ADR (aceita, retroativa, 2026-10-13): fontes ABL em ISO-8859-1/CRLF; web e `.md` em UTF-8/LF; `Fontes\thl` em ASCII |
| [adr/niveis-sensibilidade-auditoria.md](adr/niveis-sensibilidade-auditoria.md) | ADR (**proposta**, retroativa, 2026-10-13): níveis 1/5/9 da auditoria; `.df` × telas/web com rótulos de 5 e 9 invertidos — aguarda decisão |
| [adr/renumeracao-cadastros-depara.md](adr/renumeracao-cadastros-depara.md) | ADR (aceita e executada, 2026-09-25): DE-PARA da renumeração dos cadastros `thl0xxx`, conflitos de número, ordem de migração e referências por programa |
| [tech-debt/REGISTRO.md](tech-debt/REGISTRO.md) | Registro vivo de dívida técnica (TD-NNN) com pontuação, local e skill que executa a correção |
| [refactoring/backlog-inbound-erp.md](refactoring/backlog-inbound-erp.md) | Backlog inbound × ERP (2026-07-25) — nomes das Fases 0–2 superados; decisões abertas 2.6, 3.7, 4.9, 4.10; item 0.4 reaberto |

---

## Distribuição por pacote

Contagem em 13/10/2026: **148 classes = 95 em `thl-lib` + 53 em `thl-extensions`** (arquivos `.cls.old` não contam). Inclui interfaces e enums em arquivos `.cls`; exclui worktrees e gerados.

| Pacote | Arquivos `.cls` |
|---|---:|
| `thl-lib.communication` | 4 |
| `thl-lib.core` | 7 |
| `thl-lib.erp` | 22 |
| `thl-lib.integration` | 42 |
| `thl-lib.logging` | 4 |
| `thl-lib.util` | 15 |
| `thl-extensions — automatizador` | 3 |
| `thl-extensions — dvv` | 2 |
| `thl-extensions — gestaoepi` | 3 |
| `thl-extensions — iacompras` | 1 |
| `thl-extensions — loogai` | 5 |
| `thl-extensions — mmcm` | 3 |
| `thl-extensions — ninahub` | 2 |
| `thl-extensions — powerautomate` | 3 |
| `thl-extensions — thl` | 29 |
| **Total** | **145** |

## Limitação funcional a validar

O contexto inbound agendado não restaura rota, query nem path parameters: veja [messaging-inbound.md](integration/messaging-inbound.md#limitação-do-contexto-agendado). Messages que escolhem Service pela rota exigem análise antes de habilitar SCHEDULE.
