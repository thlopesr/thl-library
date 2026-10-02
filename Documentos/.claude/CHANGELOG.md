# Histórico documental da THL-Library

[Índice atual](INDEX.md). Registros abaixo descrevem sessões e estados anteriores; não são instruções vigentes nem comprovação de implantação.

## 02/10/2026 — Lote 3: sincronização documental

- Separado o histórico do índice, preservando os registros anteriores. Recontados pacotes e heranças; corrigidas referências ERP e web. Registrada a limitação do contexto inbound agendado. Validação por leitura e inventário; nenhum fonte alterado, compilado ou executado.

**Changelog 2026-10-02 (API de cadastros — uma Message por agregado):**
- ✅ Decisão do responsável: **uma Message por agregado** (pai + filhos), um Service por tabela. Regravadas (não compiladas) `ParametroAmbienteMessage`, `ObjetoMessage`, `ConexaoRestMessage`, `AuditoriaTabelaMessage` e `GrupoEmailMessage`: `createService()` escolhe o Service por `context:routePath`. Retiradas 11 Messages de filhos (cópias em `Documentos\arquivo\2026-10-02-messages-filhas-thl\`). Contagem: **160 classes = 96 `thl-lib` + 64 `thl-extensions`**.
- ℹ️ A escolha é pela **rota**, não por `pai/filho`: a chave de `thl-objeto-parametro` não inclui o método, então a operação na URL só aceitaria um verbo por filho. URLs, contrato JSON, app web e Postman **não mudaram**; `thl-lib`, `.df` e `resourcen.p` também não.
- ✅ `Utils\scripts\carga-thl-api-cadastros.p`: rotas dos filhos apontam para o objeto do pai (rota de carga anterior é alterada; objetos dos filhos são só avisados no log). Novos `cadastrar-thl-api-rotas.ps1` e `.cmd`: o mesmo cadastro pelos endpoints (simulação por padrão, `-Executar`, `-EliminarObsoletos`). Sintaxe do PowerShell conferida; **não executado contra servidor**.
- ⚠️ Implantação: compilar e publicar as cinco Messages **antes** de apontar as rotas; apagar os `.r` das 11 classes retiradas; os objetos próprios dos filhos ficam sem uso. Achado: `thl-conexao-rest-header.parameters` não é mascarado no conteúdo gravado.
- 📝 [extensions/thl.md](extensions/thl.md), [adr/api-rest-cadastros-thl.md](adr/api-rest-cadastros-thl.md) (§6), [arquitetura/InboundMessage.md](arquitetura/InboundMessage.md), [integration/messaging-inbound.md](integration/messaging-inbound.md), [logging/auditoria.md](logging/auditoria.md), `AGENTS.md` e skills `thl-coding`, `thl-qa`, `thl-architect`.

**Changelog 2026-10-02 (auditoria — análise do módulo):**
- 📝 Nova [adr/auditoria-desempenho-trigger.md](adr/auditoria-desempenho-trigger.md) (**proposta**, nada implementado): cache do cadastro por sessão, chave interpretada, temp-table de serialização reaproveitada, JSON sem formatação, remoção de `idx-audit-data`; trigger e formato do snapshot inalterados.
- 📝 Nova nota [logging/auditoria.md](logging/auditoria.md): visão de ponta a ponta das 15 classes da auditoria (gravação, consulta, cadastro), telas, expurgo, achados e plano de desempenho da trigger (P1–P6, não implementado).
- 🔴 Achados por leitura: `AuditLogService.writeChange` grava inclusão como alteração quando só a alteração está habilitada e a tabela é auditada inteira; a classe não tem `block-level`; `thl0250rp.p` está sem o prefixo `sh` (o expurgo não acha registros — a correção de 2026-09-25 não está no fonte) e grava em registro `no-lock`. Nenhum fonte alterado.
- 📝 Pacotes conferidos em disco: `AuditoriaService`, `EmailService` (consulta), `MensageriaService`, `MensageriaConteudoService` e as mensagens `Auditoria`/`Email`/`Mensageria` estão em `thl-extensions\{erp,integration}\thl`. Contagem: **171 classes = 96 `thl-lib` + 75 `thl-extensions`** (era 103 + 68). Ajustados [erp/erp-services.md](erp/erp-services.md), [arquitetura/Service.md](arquitetura/Service.md), [arquitetura/InboundMessage.md](arquitetura/InboundMessage.md), [integration/messaging-inbound.md](integration/messaging-inbound.md), [thl/camada-datasul.md](thl/camada-datasul.md), `AGENTS.md` e as skills `thl-coding`, `thl-qa` e `thl-architect`.

**Changelog 2026-10-01 (auditoria — sincronização da nota):**
- 📝 [logging/logging.md](logging/logging.md): assinaturas de `AuditLogService.writeChange`/`deleteRecord` corrigidas (o parâmetro `reference` não existe mais; a referência vem de `buildReference`); registrado que a configuração é resolvida a cada gravação por `dbname` + `table` do buffer, sem cache, e que o código usa `id` como abreviação de `id-registro`.
- 📝 [util/util.md](util/util.md): `JsonWriter.toJsonFromBuffer` ignora `prettyPrint` (sempre formatado); formato de saída do qual `AuditoriaService` e `thl0150.w` dependem; temp-table recriada a cada chamada; removidos avisos já resolvidos (`block-level`, header, variável `ds`).

**Changelog 2026-10-01 (cadastro web — campos de e-mail e Detalhar):**
- `CrudField` ganhou `icon`, `placeholder` e `clean`, repassados ao `po-dynamic-form`; aplicados nos campos de e-mail, usuário, URL, path e classe ABL.
- `copia` (parâmetro de e-mail) agora valida lista de e-mails **separada por vírgula** — o separador do `EmailParamRepository`; a ajuda dizia ponto e vírgula.
- **Estados e leitura dos browses**: erro de carregamento agora mostra a mensagem do backend e "Tentar novamente" (antes era indistinguível de lista vazia); busca renomeada para "Filtrar os registros carregados" com aviso quando a API devolve mais do que o exibido (`CrudService.list` passa a devolver `{ items, total, hasNext }`); contador de registros no subtítulo; `columnLabel` para cabeçalhos curtos; larguras fixas só nas colunas curtas; gerenciador de colunas escondido abaixo de 3 colunas.
- **Tags coloridas nos browses**: novo `tagColumn` no `CrudField`. Colunas `Inativo`/`Ativo` unificadas como **Situação** (Ativo verde / Inativo cinza) — eram polaridades opostas entre telas, obrigando a ler "Inativo: Não"; Nível de sensibilidade/acesso como escala (neutro/laranja/vermelho); Sentido com seta. Valor fora do domínio vira tag neutra com o valor cru, nunca célula vazia.
- **Detalhar com a mesma aparência do Editar** (pai e filhos): `po-dynamic-form` com campos `readonly` no lugar do `po-dynamic-view`; domínios, booleanos, números e senha viram texto em leitura. `readonly` em vez de `disabled` para não tirar os campos do teclado/leitor de tela.
- **Editor de HTML na Mensagem do e-mail**: novo `richText` no `CrudField` — o campo vira `po-rich-text` no Novo/Editar, só na aba ativa; mensagem em texto puro é convertida (quebras → `<br>`) com aviso. Os marcadores `#1#` sobrevivem sem escape.
- **Tipo da autenticação virou domínio fixo** (`BASIC`, `BEARER`, `TOKEN`, `CUSTOM.BODY`): era texto livre e o `case` do `RestConnector` ignora qualquer outro valor, saindo sem cabeçalho de autenticação. Dados de exemplo corrigidos (usavam `OAUTH2`, inexistente).
- Largura dos formulários: identificador + descrição em 4 + 8 colunas (Banco + Tabela em 3 + 9); Estabelecimento + Operação + Método numa linha; Código + Grupo de e-mail juntos.
- Ícones em Banco (`an-database`), Tabela (`an-table`) e Estabelecimento (`an-buildings`).
- Placeholder de exemplo nos campos de texto dos 9 cadastros (código, descrição, variável, endpoint, operação, servidor, tabela, chave primária, parâmetros/headers e mensagem) e ícone `an-user` nos demais campos de usuário. Regra: ícone só quando comunica o formato; `po-select`/`po-number`/`po-textarea`/`po-password` não aceitam ícone.
- Detalhar: campo `html` com marcação ganhou o alternador **Visualizar · Código**. Dados de exemplo passaram a usar os marcadores reais `#1#` do `applyPlaceholder`.
- ⚠️ `NotaFiscalService.cls:494` concatena destinatário com `;` numa lista montada com `,` — provável defeito de envio, não corrigido. Ver [web/app-web.md](web/app-web.md).

**Changelog 2026-10-02 (menu sobrepondo o conteúdo):**
- ✅ Corrigido nos dois apps (`app.css` é compartilhado): `.app-content` tinha margem fixa de 56px, então o `po-menu` expandido (290px) cobria o conteúdo. Agora o conteúdo é deslocado via `:host(:not(.po-collapsed-menu))`, dentro de `@media (min-width: 1200px)` — abaixo disso o PO UI tira o menu da tela e o abre sobreposto, medido com viewport de 1100px. Comportamento registrado em [web/poui-licoes.md](web/poui-licoes.md). Abaixo de 1200px a margem passou a ser **zero** (antes sobravam 56px reservados para um menu que nem está na tela).

**Changelog 2026-10-02 (ADR do front-end):**
- 📝 Criada [adr/arquitetura-front-end-web.md](adr/arquitetura-front-end-web.md) (aceita e aplicada): registra as quatro decisões estruturais do web que até agora só existiam como descrição — dois apps (`web`/`cadastro`), cadastro como definição do motor, standalone por feature e mock em memória por `fileReplacements` — cada uma com a alternativa descartada e as consequências. Decisões de interface ficam em [web/motor-cadastro.md](web/motor-cadastro.md), fora da ADR. A [ADR da API REST](adr/api-rest-cadastros-thl.md) tinha colocado as telas PO UI fora do escopo; esta preenche a lacuna.

**Changelog 2026-10-02 (skill de QA do front-end):**
- ✅ Nova skill **`thl-web-qa`** (`.claude\skills	hl-web-qa\SKILL.md`): auditoria e teste de telas Angular + PO UI + tema TOTVS. Parte da restrição real do projeto — **não há runner de teste instalado** —, então define as três evidências aceitas (build, verificação no navegador, leitura dirigida) e exige que o relatório diga qual delas sustenta cada afirmação. Traz as 11 dimensões de QA, os checklists de regressão do motor de cadastro e dos monitores, e a técnica de verificar tela sem backend (`ng.getComponent`/`ng.applyChanges`, injeção de erro no mock com reversão obrigatória).
- Registrada em `AGENTS.md` (tabela de guias por tarefa) e `CLAUDE.md` (lista de skills do projeto).

**Changelog 2026-10-02 (documentação web):**
- 📝 Duas notas novas: [web/motor-cadastro.md](web/motor-cadastro.md) (contrato do motor, decisões de layout/cor, domínios, pendências) e [web/poui-licoes.md](web/poui-licoes.md) (armadilhas do PO UI confirmadas rodando). [web/app-web.md](web/app-web.md) enxugada de 146 para 89 linhas, com o detalhe movido para as notas novas.
- 📝 Skills `thl-web-coding` e `thl-poui-design` atualizadas: leitura obrigatória por tipo de tarefa, armadilhas do PO UI, regras de design já decididas (ícone só quando comunica formato, tag só para estado/severidade, Situação em vez de Inativo, 4+8 colunas, Detalhar igual ao Editar, erro nunca parece vazio). Corrigida na `thl-web-coding` a afirmação de que a situação chega como código 1/2/3/4 — os monitores recebem texto.

**Changelog 2026-10-02 (consulta — padronização com o cadastro):**
- **Defeito corrigido:** as colunas de situação dos três monitores mostravam `1`/`2`/`3` em vez de Sucesso/Erro/Pendente (e Criação/Atualização/Deleção na auditoria) — `value` e `label` estavam invertidos no `PoTableColumnLabel`. Rótulos movidos para `shared/domain/status-labels.ts`.
- Estado de erro com **Tentar novamente** nos monitores (antes a falha de API aparecia como "Nenhum registro encontrado — ajuste os filtros").
- Coluna "Ação" com `thl-row-actions` no lugar do `p-actions` do `po-table`; cabeçalhos por extenso (Requisição, Retorno, Processamento, Dispositivo, Operação); `@if` no lugar de `*ngIf`.
- Mantidos como estão: paginação "Carregar mais", ordenação no servidor e filtro avançado por tela — nesses pontos a consulta é mais completa que o cadastro.

**Changelog 2026-10-01 (correção de pacotes THL):**
- Corrigidos os pacotes de MensageriaMessage e dos Services AuditoriaService, MensageriaService e MensageriaConteudoService, além dos USING envolvidos; validação estática, sem compilação. Conferir cadastros com nomes antigos — [extensions/thl.md](extensions/thl.md).

**Changelog 2026-10-01 (API REST dos cadastros — GrupoEmail, thl0011/thl0011b):**
- ✅ Criadas (não compiladas) 4 classes em `thl-extensions\{erp,integration}\thl`: `GrupoEmailService`/`GrupoEmailMessage` (CRUD de `thl-ambiente-param-grupo`, rota `grupo-email`; bloqueia exclusão com e-mail param ou notificação de auditoria vinculados) e `GrupoEmailUsuarioService`/`GrupoEmailUsuarioMessage` (criação/exclusão de `thl-ambiente-param-grupo-usuar`, rota `grupo-email-usuario`, sem PATCH; chave composta `grupoEmail#usuario#emailAlternativo`; valida `usuar_mestre` e grupo pai). `carga-thl-api-cadastros.p` com os 2 recursos. Contagem em disco: **171 classes** (103 `thl-lib` + 68 `thl-extensions`). Detalhe em [extensions/thl.md](extensions/thl.md).
- ⚠️ `GrupoEmailUsuarioService` usa `usuar_mestre` (banco emsfnd): compilar com emsfnd conectado.

**Changelog 2026-10-01 (API REST dos cadastros — demais 14 tabelas):**
- ✅ Criadas (não compiladas) 28 classes em `thl-extensions\{erp,integration}\thl`: `AuditoriaTabela`, `AuditoriaTabelaAcesso`, `AuditoriaTabelaCampo`, `AuditoriaTabelaNotificacao`, `AuditoriaTabelaExpurgo`, `ConexaoRest`, `ConexaoRestAutenticacao` (campos sensíveis mascarados), `ConexaoRestHeader`, `ConexaoRestPath`, `Objeto`, `ObjetoParametro`, `ObjetoUsuario` (sem PATCH), `InboundRota`, `EmailParametro` — cada uma com `…Service` e `…Message`. Regras do `Pi-validate` (criação/alteração) e do `local-delete-record` (exclusão) de cada tela; JSON sem o prefixo `cod`. `Utils\scripts\carga-thl-api-cadastros.p` com os 14 recursos. Contagem em disco: 167 classes (103 `thl-lib` + 64 `thl-extensions`). Detalhe em [extensions/thl.md](extensions/thl.md); [arquitetura/InboundMessage.md](arquitetura/InboundMessage.md) e [arquitetura/Service.md](arquitetura/Service.md) atualizadas.
- ⚠️ Três Services usam tabelas do Datasul (`usuar_mestre`, `estabelec`): compilar com `emsfnd` e `mgadm` conectados.

**Changelog 2026-10-01 (API REST dos cadastros — Aplicação, thl0020):**
- ✅ Criados (não compilados) `thl-extensions.erp.thl.service.AplicacaoService` e `thl-extensions.integration.thl.messaging.inbound.message.AplicacaoMessage` (CRUD de `thl-aplicacao`, rota `aplicacao`, objeto `THL/APLICACAO`), no padrão `AmbienteService`/`AmbienteMessage`; GET por faixa da chave (`aplicacaoIni`/`aplicacaoFin`). `Utils\scripts\carga-thl-api-cadastros.p` ganhou o recurso `APLICACAO`; teste e exemplos ficam só no Postman (coleção Nitro, pasta `THL`). Classes: +2 em `thl-extensions`. [extensions/thl.md](extensions/thl.md) (também corrigida: o cliente recebe `{items, hasNext}`, não um array), [arquitetura/InboundMessage.md](arquitetura/InboundMessage.md) e [arquitetura/Service.md](arquitetura/Service.md) (filhas do sistema `thl`, que faltavam).

**Changelog 2026-10-01 (Postman — coleção só na nuvem):**
- ✅ Pasta `Utils\postman` removida pelo responsável (as três coleções exportadas não eram versionadas). A referência de teste passa a ser a coleção **Nitro** no Postman (pasta `THL` para a API de cadastros), mantida direto na nuvem, sem exportar JSON para o repositório — [extensions/thl.md](extensions/thl.md) e [web/app-web.md](web/app-web.md) atualizadas. Entradas antigas deste changelog que citam `Utils\postman` ficam como histórico.
- ✅ Pasta `THL` da coleção conferida contra o código (rotas da carga, campos dos Services, filtros das Messages): Ambiente, Parametro, Parametro Variavel e Parametro Programa sem diferença. Criadas as 4 requests da Aplicacao (`/resourcen/aplicacao`, com descrição, teste e examples derivados do código) na subpasta `Aplicação` (criada pelo responsável; conferido pela API), com os mesmos nomes das demais (`GET Lista`, `POST`, `PATCH`, `DELETE`) — [extensions/thl.md](extensions/thl.md).
- ✅ Coleção reorganizada: `TOTVS > Projeto > Biblioteca` renomeada para `THL-Library`; as 20 requests que estavam soltas nela foram movidas para uma pasta por recurso (LPCO, Usuario, Embarque, Frete, Documento, Requisição, Item Requisição, NotaFiscalPorEmbarque, Item, Centro Custo, Emitente, Transporte), sem alterar nome nem conteúdo das requests. `Ninahub` e `THL` não mudaram. A `Biblioteca` de `TOTVS > Amarela` não foi tocada.

**Changelog 2026-09-30 (EmbarqueService — PATCH de dados de transporte):**
- ✅ `EmbarqueService.update()` (PATCH → `ActionEnum:ATUALIZADO`) com `ind-oper = OPER_ALTER_EMBARQ`: altera `nome-transp`, `motorista`, `placa`, `uf-placa` do `embarque` (JSON `nomeTransportadora`, `motorista`, `placa`, `ufPlaca`; ausentes mantêm o valor atual). `EmbarqueMessage` passa a exigir `codigoEmbarque` no PATCH. Corrigido `delete()`: variável local `eqapi300` escondia a propriedade usada por `processShipment()` (handle inválido na exclusão).
- ✅ `LoogAiEmbarqueService` sobrescreve `create()`/`update()` (chamando `super`) e grava `ext-embarque` pelo método private `saveShipmentExtension` (`valorFrete` → `valor-frete`, `telefoneMotorista` → `telefone-motorista`, ambos opcionais) no POST e no PATCH; sobrescreve `validateTransportContext` para aceitar PATCH só com esses campos. `EmbarqueService` não tem hook de extensão de cliente. `prepareWarehouseData` (depósitos por `param-dep-exc`) e a `tt-deposito` saíram do `EmbarqueService` (hook vazio, mesmo ponto do laço de entregas) para o `LoogAiEmbarqueService`. Nova classe `thl-lib.util.json.JsonUtil` com `hasAnyProperty( json, lista )` (checagem de campos presentes usada pelos dois services — [util/util.md](util/util.md)); `LoogAiEmbarqueMessage` exige `codigoEmbarque` no PATCH. PATCH só com campos de extensão não chama o `eqapi300`. Não compilado — [extensions/loogai.md](extensions/loogai.md). Arquivo do service regravado em ISO-8859-1/CRLF (estava UTF-8/LF). Não compilado — [erp/erp-services.md](erp/erp-services.md).

**Changelog 2026-09-30 (consulta de transportador — GET):**
- ✅ Criados (não compilados) `thl-lib.erp.service.TransporteService` (`get( cod-transp, nome-abrev )` na tabela `transporte`) e `thl-lib.integration.messaging.inbound.message.TransporteMessage` (só GET, query params `codigo`/`nome`), no modelo `EmitenteService`/`EmitenteMessage`. Cadastros (objeto `TRANSPORTE`, parâmetro GET e rota `transporte`) em `Utils\scripts\carga-thl-transporte.p` (aplicação `THL` por padrão; simulação por padrão). [erp/erp-services.md](erp/erp-services.md), [integration/messaging-inbound.md](integration/messaging-inbound.md).

**Changelog 2026-09-30 (DocumentoService — recálculo de impostos do item):**
- ✅ `DocumentoService.executeBOFs` passa a enviar os itens à boin176 um a um (antes, `setRecord` com a tabela inteira gravava só o primeiro) e chama o novo hook protected `recalculateItemTaxes` (`recalculateImpostoICMS` — ICMS/IPI/ISS) entre `setRecord` e `createRecord`. Arquivo regravado em ISO-8859-1/CRLF. Não compilado — [erp/erp-services.md](erp/erp-services.md).

**Changelog 2026-10-01 (web — Ambiente no modelo de browse; pacote de cadastro gerado):**
- ✅ Lista de Ambiente com o cabeçalho do modelo (busca local + "Novo ambiente"), mas como **cadastro simples**, sem linha expansível — vínculos (variáveis e programas) aparecem só no Parâmetro. Estilos do modelo movidos para `shared\styles\`. Services conferidos contra `Utils\postman\thl-api-cadastros.postman_collection.json`.
- ✅ `build-deploy-cadastro.ps1` executado: `dist\thl-html-cadastro` e `html-thl-cadastro.zip` (produção, sem mock, endpoint real na mesma origem). ⚠️ Ainda não testado contra o PASOE — depende das classes da API compiladas e da carga `carga-thl-api-cadastros.p`.

- ✅ Pasta de deploy da consulta renomeada: `dist\thl-html-menu` → `dist\thl-html-consulta` (`build-deploy.ps1`, `AGENTS.md`, skills `thl-web-coding`/`thl-poui-design`, [web/app-web.md](web/app-web.md)). Subpastas (`html.mensageria`, `html.menu`) e o zip `html-thl-mensageria.zip` inalterados. ⚠️ Se a pasta for copiada com o nome novo para o webapps, o cadastro dos programas no menu Datasul precisa apontar para `thl-html-consulta`.

- ✅ Nomes dos pacotes padronizados: pasta do `dist`, zip e pasta interna do zip são `thl-html-consulta` e `thl-html-cadastro` (antes os zips eram `html-thl-mensageria`/`html-thl-cadastro`). ⚠️ O nome publicado no webapps muda — atualizar o cadastro dos programas no menu Datasul.
- ✅ `build-deploy.ps1` e `build-deploy-cadastro.ps1`: zip gerado com `ZipFile` do .NET (leitura compartilhada — o `Compress-Archive` falhava com arquivo em uso pelo antivírus e o script dizia "Pacote gerado" mesmo assim), entradas com `/` (extração correta em Linux) e saída com erro se o zip não existir.

- ✅ `dist` só com as pastas `thl-html-consulta` e `thl-html-cadastro` (decisão do responsável): os scripts de deploy deixaram de gerar zip e apagam a saída bruta do build (`dist\web`, `dist\cadastro`); `-DeployPath` copia a pasta para o webapps. As linhas acima sobre zip ficam como histórico.

- ✅ Rotas do app cadastro corrigidas para as vigentes: `parametro-ambiente`, `parametro-variavel`, `parametro-programa` (services e mock). Alinhados também `Utils\scripts\carga-thl-api-cadastros.p` (3 chamadas `addResource`), as coleções `thl-api-cadastros`/`Nitro-THL` e [extensions/thl.md](extensions/thl.md). ⚠️ Pendente: ADR [api-rest-cadastros-thl.md](adr/api-rest-cadastros-thl.md) (decisão nº 1) e comentários de cabeçalho das `Parametro*Message.cls` ainda citam os nomes antigos; onde a carga já rodou, ajustar `thl-inbound-rota.rota-publica` (a carga não renomeia).

- 🐛 Aba Programas em branco até passar o mouse: o `po-table` criado dentro de um `po-tab` oculto (display none) não desenha as linhas. `variavel-tab`/`programa-tab` ganharam `@Input() visivel` e só renderizam o `po-table` com a aba ativa (`parametro-filhos` controla `abaAtiva` pelo `(p-click)` do `po-tab`); os dados e o contador continuam carregando ao expandir.

- ✅ Abas Variáveis e Programas: ações da linha viraram coluna de ícones (lixeira vermelha `color-07` com tooltip "Excluir"; lápis "Editar" em Variáveis), no lugar do link "Excluir" e do menu "⋯".

- ✅ Card do Parâmetro: removido o botão "Editar parâmetro" (edição só pelo "⋯" da linha); botões das abas padronizados como "Adicionar"; coluna de ícones com título "Ações". Lista principal mantém "⋯" sem título (limite do `po-table`).

- ✅ Novo `shared\components\thl-row-actions` ("⋯" + `po-popup`) e regra única da coluna "Ações": mais de uma ação → "⋯" em coluna `cellTemplate` com título; uma ação → ícone. Aplicado nas listas de Parâmetro e Ambiente e na aba Variáveis (que volta ao "⋯"); Programas segue com a lixeira. Substitui o `p-actions` do `po-table`, cuja coluna não aceita título.

- ✅ Coluna de ações padronizada: título "Ação" (singular) e "⋯" (`thl-row-actions`) em todas as tabelas do cadastro, inclusive na aba Programas, que tem uma única ação (sai a lixeira solta). "⋯" centralizado na linha (`thl-row-actions` passou a `display: flex`).

- ✅ Nomes de rota vigentes (`parametro-ambiente`, `parametro-variavel`, `parametro-programa`) também na ADR [api-rest-cadastros-thl.md](adr/api-rest-cadastros-thl.md) (tabela de rotas e decisão nº 1, revista em 2026-10-01), em [thl/camada-datasul.md](thl/camada-datasul.md) e no comentário de cabeçalho de `ParametroAmbienteMessage.cls`, `ParametroVariavelMessage.cls` e `ParametroProgramaMessage.cls` (só comentário; fontes não compilados). Encerra a pendência anotada acima.

- ✅ Menu do app cadastro agrupado (`po-menu` com `subItems`): grupo **Configuração** com Ambiente e Parâmetro. Planejados para os próximos cadastros (14 recursos novos da API): E-mail em Configuração; **Integração** (Objeto, Conexão REST, Rota) e **Auditoria** — ver [web/app-web.md](web/app-web.md).

- ✅ **Motor genérico de cadastros** (`Fontes\web\src\app\shared\crud\`): `CrudService`, `thl-crud-list` (browse reduzido, Ação com Detalhar/Editar/Excluir, formulário e detalhe em modal com abas por bloco), `thl-crud-children` e `thl-crud-page`. Seis cadastros novos por definição em `cadastros\cadastros.defs.ts`: E-mail, Objeto (+ Parâmetros, Usuários), Conexão (+ Autenticação, Header), Path, Rota e Auditoria (+ Campos, Acessos, Notificações, Expurgo) — 12 recursos da coleção Nitro. Menu plano com títulos de seção e linha separadora (`app-cadastro.css`). `ng build web` e `ng build cadastro` OK; testado só contra o mock. Pendências da versão 2 em [web/app-web.md](web/app-web.md).

- ✅ **Ambiente e Parâmetro migrados para o motor genérico**: viraram `ambienteDef` e `parametroDef` em `cadastros.defs.ts`; removidas as pastas `src\app\ambiente\` e `src\app\parametro\` (componentes, services e models próprios) e as rotas `new`/`edit` (incluir e editar agora em modal). O motor ganhou `parentFilter` (filtro `parametroIni/Fin` para o campo `codParametro`) e `optionsFromExtra`; o campo Ambiente da variável virou zoom do cadastro de Ambiente + `*`. Os oito cadastros usam o mesmo código. `ng build web` e `ng build cadastro` OK.

- ✅ Cadastros: modais do formulário e do **Detalhar** sem abas — os blocos (`group`) viram divisores empilhados (decisão do responsável). Domínios aplicados como combo/rótulo: modelo de integração, forma de execução, tipo de log (requisição e retorno) e nível de sensibilidade; `nivelAcesso` e `importancia` seguem numéricos. O browse mostra o rótulo em texto com reserva para valor fora do domínio (`type: 'label'` do `po-table` escondia a célula).

- ✅ Novo cadastro **Grupo de e-mail** (`grupo-email` + `grupo-email-usuario`, tabelas `thl-ambiente-param-grupo` e `-usuar`, tela thl0011): grupo na lista e destinatários na linha expandida; a chave do filho inclui `emailAlternativo`, então o mesmo usuário entra mais de uma vez com endereços diferentes (sem PATCH). Com o endpoint disponível, o campo Grupo de e-mail do E-mail e da notificação de auditoria virou **zoom** (era texto livre). ⚠️ A rota `aplicacao` (thl0020) existe no backend e ainda não tem tela.

- ✅ Botão de inclusão padronizado como **"Adicionar"** nas nove telas de cadastro (era "Novo <registro>", com concordância de gênero); o nome do registro permanece no título do modal.

- ✅ Modais do cadastro voltam a ter **abas** (`tab` no campo; `group` passa a divisor dentro da aba), no padrão do detalhe da mensageria: Parâmetro do objeto (Geral · Ambiente · Persistência · Servidor), Autenticação (Acesso · Token), Path (Geral · Parâmetros · Headers) e E-mail (Geral · Mensagem); o Salvar valida todas as abas. Também: validação de formato nos campos de e-mail, zoom de Aplicação no Objeto (rota `aplicacao`) e nível de acesso com o domínio Normal/Crítico/Restrito.

- ✅ Mensagem do parâmetro de e-mail renderizada como **HTML** no Detalhar (campo `html` no motor; `[innerHTML]` com a sanitização padrão do Angular). Encerra a pendência anotada acima.

**Changelog 2026-09-30 (web — modelo de browse pai + filhos no Parâmetro):**
- ✅ Lista de Parâmetro no modelo do mockup: `thl-page-header` + busca local + "Novo parâmetro"; linha expandida em card com "Editar parâmetro" e `po-tabs` com contador (Variáveis (N) / Programas (N)); estado vazio com "Adicionar". `thl-page-header` mostra "Última atualização" só com `lastUpdate`. `ng build web` e `ng build cadastro` OK. Padrão descrito em [web/app-web.md](web/app-web.md).

**Changelog 2026-09-25 (web — app de cadastro thl-html-cadastro):**
- ✅ Novo projeto `cadastro` no `Fontes\web\angular.json` (entrada `main-cadastro.ts`, root `app-cadastro.ts`, `cadastro.routes.ts`), separado do app de consulta `web` como as seções do menu Datasul. Features `ambiente\` (thl0001: lista + form) e `parametro\` (thl0002: lista com linha expansível no browse — abas Variáveis/Programas com CRUD em `po-modal` — + form), consumindo `ambiente`, `parametro`, `parametroVariavel` e `parametroPrograma` (DELETE com chave no corpo).
- ✅ `build-deploy-cadastro.ps1` → `dist\thl-html-cadastro` (`html.cadastro`, `html.menu`) e `html-thl-cadastro.zip`; `.claude\launch.json` ganhou `cadastro-dev` (4201) com backend mock em memória só em development (`fileReplacements`).
- ⚠️ Workspace multi-projeto: `ng serve`/`ng build` sem nome falham ("Cannot determine project") — corrigidos `build-deploy.ps1` (`ng build web`), `package.json` e `launch.json`. `ng build web` e `ng build cadastro` OK em produção.
- 📝 [web/app-web.md](web/app-web.md), `AGENTS.md`, `CLAUDE.md` e skill `thl-web-coding` atualizados.

**Changelog 2026-09-25 (Postman do piloto):**
- ✅ `Utils\postman	hl-api-cadastros.postman_collection.json` refeita no formato da coleção do projeto (a 1ª versão, com scripts de teste e auth na coleção, não importou): pasta `THL` com 18 requisições, host em `{{URI-BASE}}`; filtros do GET conforme as classes ajustadas pelo responsável (`ambienteIni/Fin`, `parametroIni/Fin`) — [extensions/thl.md](extensions/thl.md) atualizada.

**Changelog 2026-09-25 (piloto da API REST dos cadastros — thl0001/thl0002):**
- ✅ Criados (não compilados): `thl-extensions\erp	hl\service\` `AmbienteService`, `ParametroAmbienteService`, `ParametroVariavelService`, `ParametroProgramaService`; `thl-extensions\integration	hl\messaging\inbound\message\` `AmbienteMessage`, `ParametroAmbienteMessage`, `ParametroVariavelMessage` (mascara valor sensível em `saveContentByType`), `ParametroProgramaMessage`; `Utils\scripts\carga-thl-api-cadastros.p` (aplicação THL, 4 objetos, parâmetros por método, 4 rotas; simulação por padrão). Padrão `LpcoMessage`/`LpcoService`; `thl-lib` e `resourcen.p` inalterados. Classes: +8 em `thl-extensions`.
- ✅ `thl0001-v01.w`: `local-delete-record` — não elimina ambiente com variáveis (17006), paridade com a API.
- 📝 Nova nota [extensions/thl.md](extensions/thl.md); [adr/api-rest-cadastros-thl.md](adr/api-rest-cadastros-thl.md) aceita; [arquitetura.md](arquitetura.md) §5 e [thl/camada-datasul.md](thl/camada-datasul.md) atualizadas.

**Changelog 2026-09-25 (ADR API REST dos cadastros):**
- 📝 Nova [adr/api-rest-cadastros-thl.md](adr/api-rest-cadastros-thl.md) (proposta): GET/POST/PATCH/DELETE dos cadastros em `thl-extensions\{erp,integration}	hl` (THL como sistema externo `thl`); piloto thl0001 Ambiente e thl0002 Parâmetro (+ variável e programa). Decidido: padrão `LpcoMessage`/`LpcoService` (sem classe-base), `InboundRouteResolver` inalterado (rotas por cadastro em `thl-inbound-rota`), erros 2/17006, THL sempre armazena (valor sensível mascarado em `saveContentByType`), sem autorização por usuário. Em aberto: nome das rotas, bloqueio no thl0001, regra única tela × API. Nenhum fonte criado.

**Changelog 2026-09-25 (grafo do Obsidian):**
- ✅ Notas PO UI deixam de ser órfãs: [poui/INDEX.md](poui/INDEX.md) passa a linkar as 14 notas (antes só citava os nomes em código) e aponta para [web/app-web.md](web/app-web.md), [arquitetura.md](arquitetura.md) e este índice; `app-web.md` linka o KB PO UI; [arquitetura.md](arquitetura.md) ganhou a camada `web` (diagrama e tabela).

**Changelog 2026-09-25 (segunda lista de ajustes do teste):**
- ✅ `local-delete-record` com mensagem 17006 (não elimina com vínculo): thl0002-v01 (variáveis/programas do parâmetro), thl0011-v01 (grupo usado em thl0010 e na notificação do thl0051), thl0020-v01 (objetos do thl0021), thl0030-v01 (autenticação thl0032 e cabeçalho thl0033), thl0050-v01 (campo/acesso/notificação/expurgo do thl0051). Sem `{include/i-vldprg.i}` — ele usa `i_page-viewer`, definida pelo `i-vldfrm.i`, e só compila dentro do `Pi-validate` (erro 201/198 no thl0011-v01).
- ✅ `thl0021-b01.w` (zoom de objeto): coluna **Aplicação**; o `FIELDS` da query não trazia `aplicacao`, então o retorno ia vazio (afetava o zoom do thl0040).
- ✅ Zoom de usuário (`fnzoom/z01fn017.w`): `&campozoom=cod_usuario` (campo do `usuar_mestre`) em thl0051b-v01, thl0011b-v01 e thl0022b-v01 — estava `cod-usuario`.
- ✅ THL0022B refeito: `thl0022b-v01.w` gerado do padrão do thl0051b-v01 (tinha tabela em `espmulti` e `mgnitro`, trigger `DO.` e atributos de execução cortados); `thl0022b-q01.w` sem `espmulti`; `thl0022-b02.w` só com incluir/eliminar.
- ⏸️ THL0032/THL0033 com o vá-para/zoom do thl0030: não aplicado — devolvem o ROWID de `thl-conexao-rest` e a query do thl0032/0033 reposiciona pelo ROWID da própria tabela.
- 📝 Docs: [thl/camada-datasul.md](thl/camada-datasul.md) (tabela de cadastros: eliminação com vínculo, zooms, thl0022b; removidas as menções à descrição da aplicação no thl0022/thl0040) e [convencoes.md §7](convencoes.md) (regra do `local-delete-record`, `i-vldprg.i` só no `Pi-validate`, `&campozoom` e `FIELDS` do zoom).
- ⚠️ Acentuação: os arquivos apontados estão corretos em ISO-8859-1 (são justamente os que têm texto acentuado literal); o ambiente continua lendo as telas como CP850. Aguardando decisão.

**Changelog 2026-09-25 (lista de ajustes do teste):**
- ✅ THL0022: `thl0022-v01.w` sem a descrição da aplicação (campo, `local-display-fields`, `pi-desc-aplicacao` removidos; campo volta a 35).
- ✅ THL0040: `thl0040-v01.w` sem a descrição da aplicação; F5/duplo clique em **aplicação** ou **objeto** abrem `thl/thl0021-z01.w`, que devolve os dois campos; campo aplicação volta a 54. `thl0021-b01.w` ganhou o `pi-retorna-valor` (`aplicacao`, `objeto`).
- ✅ THL0032/THL0033: zoom da conexão (`thl/thl0030-z01.w`) em `cod-conexao`, sem descrição ao lado; `thl0030-b01.w` ganhou o `pi-retorna-valor` (`cod-conexao`, `des-conexao`).
- ✅ **Acentuação — decisão: tudo em ISO-8859-1.** Trechos CP850 dos templates em `Fontes\thl` convertidos palavra a palavra (1.279 ocorrências, 126 arquivos; empates mantidos; erros do template corrigidos: "Conexção", "váriáveis", "inicializaçcao"; rótulos `\xbb`+CP850 do thl0032). `Fontes\thl` 100% ISO-8859-1/ASCII. ⚠️ O ambiente precisa ler as telas como ISO-8859-1. [convencoes.md §1](convencoes.md).
- ✅ **Títulos ("validar tudo"):** 45 janelas padronizadas — `Manutenção <Nome>` (principal), `Inclui/Modifica <Nome>` (filhas), `Pesquisa de <Nome>` (zoom), `Vá Para <Nome>` (vá para), nome simples (consultas/tarefas). Eram títulos-modelo (`<Insira o complemento>`, `<Title>`, "Template Livre") ou copiados de outro programa (thl0033 "Autenticacao REST"; thl0051b/c/d/e **"Natureza Tipo Operação"**). Abas dos zooms e rótulos dos vá-para corrigidos (thl0002 "Paranetro", thl0033, thl0050, "Codigo …", "Conexao").
- ℹ️ THL0020 "tamanho do campo": não aplicar (decisão do responsável).

**Changelog 2026-09-25 (zoom de grupo no thl0051d):**
- ✅ `thl0051d-v01.w` (notificação da auditoria): `grupo-email` com zoom `thl/thl0011-z01.w` (F5/duplo clique) e descrição do grupo ao lado (`fi-desc-grupo`, LEAVE + `local-display-fields` via `pi-desc-grupo`); campo reduzido para 21 colunas. Editável também na alteração (não é chave); validação (mensagem 2) já existia.
- ✅ `thl0010-v01.w` (parâmetro de e-mail): mesmo zoom de grupo em `cod-grp-usuar` (`thl/thl0011-z01.w`, F5/duplo clique) com descrição ao lado (`fi-desc-grupo`, LEAVE + `local-display-fields` via `pi-desc-grupo`); editável na inclusão e na alteração; validação (mensagem 2) já existia.
- ✅ `thl0011-b02.w`: `pi-retorna-valor` implementado (`cod-grp-usuar`, `descricao`) — estava "Procedure desativada".
- ℹ️ Levantamento: todos os zooms usados por `zoomvar.i` (thl0001, thl0011, thl0020) devolvem valores. Os demais browses de zoom (`thl0002-b03`, `thl0010`, `thl0021`, `thl0030`…`thl0033`, `thl0040`, `thl0050-b01`) seguem com o retorno desativado/vazio — servem só como `ProgPesquisa` (navega por ROWID); implementar ao usá-los como zoom de campo.

**Changelog 2026-09-25 (zoom de usuário no thl0051b):**
- ✅ `thl0011b-v01.w` (usuário do grupo de e-mail): mesmo zoom de usuário (`fnzoom/z01fn017.w`, F5/duplo clique) e nome ao lado (`fi-nome-usuario`, LEAVE + `local-display-fields` via `pi-nome-usuario`). Funciona na inclusão e na alteração (a chave do thl0011b ainda é editável — pendência do `email-alternativo`).
- ✅ `thl0051b-v01.w` (acesso à auditoria): `cod-usuario` com zoom `fnzoom/z01fn017.w` (o mesmo do thl0022b; F5/duplo clique) e nome do usuário ao lado (`fi-nome-usuario`, LEAVE + `local-display-fields` via `pi-nome-usuario`, lido de `usuar_mestre`); campo reduzido para 16 colunas. Só na inclusão (campo da chave); a validação (mensagem 2) já existia.

**Changelog 2026-09-25 (varredura dos Pi-validate):**
- ✅ 52 validações novas em 20 viewers, pela regra do [convencoes.md §7](convencoes.md) (registro relacionado → **2**; demais → **17006**; `i-vldprg.i` antes de cada `ut-msgs.p`; chave só com `adm-new-record`; pai por `v-row-parent`):
  - **17006:** chave vazia/duplicada em todos os cadastros; `thl0001` IP vazio e **IP repetido** (resolve o ambiente); `thl0002c` **programa em outro parâmetro** (a biblioteca pega o primeiro); `thl0010`/`thl0051d` grupo vazio; `thl0021` **classe vazia**; `thl0022a` estabelecimento vazio (`*` = todos); `thl0030` URL base vazia; `thl0032`/`thl0033` uma configuração por conexão; `thl0033` classe vazia; `thl0040` rota pública vazia/repetida e objeto vazio; `thl0051e` retenção negativa e uma por tabela; `thl0011b` duplicado também na alteração (chave editável).
  - **2:** grupo de e-mail (`thl0010`, `thl0051d`), usuário Datasul `usuar_mestre`/`emsfnd` (`thl0011b`, `thl0022b`, `thl0051b`), conexão (`thl0032`, `thl0033`), objeto da rota (`thl0040`).
  - Fora: `thl0022a-v02` (variáveis do parâmetro do programa), `thl0022a-v03/v04` (campos ainda não lidos), viewers só de exibição. Em seguida, `thl0022a-v01` ganhou a validação do estabelecimento no Datasul (`estabelec`, mensagem **2**, `ut-table.i mgadm estabelec 1`; `*` aceito, só na inclusão) — ⚠️ confirmar na compilação o banco `mgadm`. Depois, zoom de estabelecimento no mesmo viewer: F5/duplo clique abrem `adzoom/z01ad107.w` (zoom TOTVS de Estabelecimento — ⚠️ confirmar o nome na base), nome ao lado (`fi-nome-estab`, LEAVE + `local-display-fields` via `pi-nome-estab`; `*` = "Todos os estabelecimentos"); só na inclusão (campo da chave). `thl0020-v01` ganhou o `i-vldprg.i` que faltava.

**Changelog 2026-09-25 (validação no local-assign-record):**
- ✅ Nos 28 viewers com gravação (`TableIO-Target`), o `{include/i-valid.i}` do `local-assign-record` foi trocado por `run pi-validate.` + `if return-value = 'ADM-ERROR':U then return 'ADM-ERROR':U.` (substituído, não duplicado — o include já rodava o `pi-validate`). Ordem conferida: validação antes do `dispatch 'assign-record'`, e o ADM-ERROR do assign continua tratado.
- ✅ Regra registrada em [convencoes.md §7](convencoes.md) e na skill `thl-coding`: registro pai não encontrado → `ut-msgs.p` **2** (`i-vldprg.i` + `ut-table.i`), demais erros → **17006**. As validações existentes (thl0002b, thl0020, thl0021, thl0040) já seguem a regra.

**Changelog 2026-09-25 (lógicos em toggle-box):**
- ✅ Levantamento dos 20 campos `logical` do `.df` nos viewers: 3 estavam em FILL-IN e viraram **TOGGLE-BOX** — `thl0032-v01` (`ind-requisita-token`, "Requer Token"), `thl0040-v01` (`ind-ativo`, "Ativa") e `thl0051c-v01` (`ind-ativo`, "Ativo"). Sem `COLON-ALIGNED` (coluna +2, alinhada com os demais campos), `FORMAT "Sim/Nao"`/`EXP-FORMAT` removidos no thl0051c. Em seguida, os 8 combos Sim/Não também viraram TOGGLE-BOX: `thl0021-v01` (`ind-inativo`, `ind-gera-historico`), `thl0022a-v01` (`ind-inativo`, `ind-gera-historico`), `thl0022a-v02` (`ind-mensagem-simples`), `thl0022a-v03` (`ind-persistente`), `thl0030-v01` (`ind-requisita-autenticacao`, `ind-requisita-header`; rótulo "Requisita Autenticação" passou de CP850 corrompido para ISO-8859-1). Mantido como combo: `thl-objeto.sentido-fluxo` (Saída/Entrada).

**Changelog 2026-09-25 (faixa nos zooms):**
- ✅ Browses de zoom sem WHERE da faixa (a tela tinha "inicial/final" e o botão confirmar, mas a query ignorava): `thl0001-b01` (`cod-ambiente`), `thl0002-b03` (`cod-param-ambiente`), `thl0011-b02` (`cod-grp-usuar`, herdado do thl0002-b03) e `thl0050-b01` (`tabela`). WHERE incluído no `QUERY-STRING`/`OPEN-QUERY-br-table` e no `_Where[1]` do AppBuilder, no formato do `thl0040-b01`. Os 12 zooms agora filtram pela faixa.

**Changelog 2026-09-25 (thl0002c só incluir/eliminar):**
- ✅ `thl0002-b02.w` (aba Programa do THL0002, abre o `thl0002c`): botão **Modificar** oculto (fora de `ENABLED-OBJECTS`, `HIDDEN = TRUE` nos atributos de execução), gatilho CHOOSE sem `pi-Incmod('modificar')` e duplo clique sem `New-State('DblClick')`; Eliminar movido para a posição do Modificar. O widget continua definido porque o `include/c-brows3.i` (TOTVS) pode referenciá-lo. Motivo: `thl-ambiente-param-prog` só tem a chave.

**Changelog 2026-09-25 (chave só na inclusão — thl0001):**
- ✅ `thl0001-v01.w`: `cod-ambiente` saiu de `ENABLED-FIELDS` e entrou em `ADM-CREATE-FIELDS` (habilitado só na inclusão) e `ADM-ASSIGN-FIELDS` (gravado mesmo fora de `ENABLED-FIELDS`), com o SETTINGS `NO-ENABLE 1 2` para o AppBuilder — mesmo padrão do `thl0002b-v01.w`.
- ✅ Mesmo ajuste aplicado em 14 viewers: `thl0002-v01` (cod-param-ambiente), `thl0010-v01` (cod-email-param), `thl0011-v01` (cod-grp-usuar), `thl0021-v01` (aplicacao, objeto), `thl0022a-v01` (cod-estabel, operacao), `thl0030`/`0032`/`0033-v01` (cod-conexao), `thl0031-v01` (cod-path), `thl0040-v01` (cod-rota), `thl0050-v01` (banco, tabela), `thl0051b-v01` (cod-usuario), `thl0051c-v01` (campo), `thl0051d-v01` (nivel-sensibilidade). SETTINGS com `NO-ENABLE 1 2` preservando os demais atributos; CRLF conferido.
- ⚠️ Não aplicado: `thl0011b-v01` (chave inclui `email-alternativo` — decidir antes) e `thl0002c-v01` (o único campo editável é a chave `cod-prog-dtsul`; resolvido tirando a alteração no `thl0002-b02`). `thl0022-v01` e `thl0051-v01` são viewers do pai sem TableIO — nunca editáveis.

**Changelog 2026-09-25 (zoom de Ambiente no thl0002b):**
- ✅ `thl0002b-v01.w` (variável do parâmetro): `cod-ambiente` com zoom do `thl/thl0001-z01.w` (F5/duplo clique, `include/zoomvar.i`) e nome do ambiente ao lado (`fi-nome-ambiente`, LEAVE + `local-display-fields` via `pi-nome-ambiente`; `*` mostra "Todos os ambientes"). Campo é chave: zoom só na inclusão. Validado no `Pi-validate` **só na inclusão** (`adm-new-record`): ambiente inexistente em `thl-ambiente` → mensagem TOTVS 2 (`i-vldprg.i` + `ut-table.i mgnitro thl-ambiente 1` + `ut-msgs.p`); `*` aceito.
- ✅ `thl0001-b01.w`: `pi-retorna-valor` implementado (`cod-ambiente`, `nome-ambiente`, `ip`) — estava "Procedure desativada", o que impedia o zoom de devolver valores.

**Changelog 2026-09-25 (validação de Aplicação):**
- ✅ `Pi-validate` de `thl0021-v01.w` (Objeto) e `thl0040-v01.w` (Rota inbound): aplicação inexistente em `thl-aplicacao` bloqueia a gravação com a mensagem TOTVS **2** (`{include/i-vldprg.i}` + `{utp/ut-table.i mgnitro thl-aplicacao 1}` + `utp/ut-msgs.p`), foco no campo. Vale na inclusão e na alteração. Demais telas não recebem: thl0020 é o próprio cadastro; thl0022-v01 é só exibição; thl0022a/b copiam do objeto. ⚠️ Rodar `Utils\scripts\carga-thl-aplicacao.p` antes de publicar, senão objetos e rotas antigos não gravam.
- ⚠️ `thl0021-v01.w` foi alterado no AppBuilder (11:16): novo layout e **retirada da descrição** da aplicação (`fi-desc-aplicacao`, LEAVE, `pi-desc-aplicacao`); o `local-display-fields`, que só servia para a descrição e chamava a procedure removida, também foi retirado (a pedido do responsável). O thl0021 fica com zoom + validação, sem descrição ao lado.
- ✅ Removido do `Pi-validate` do `thl0040-v01.w` o comentário copiado do cadastro de autenticação ("Ponto de validacao manual THL0032…"). ⚠️ Ainda há comentários "Ponto de validação manual" de outro cadastro em `thl0032-v01.w` e `thl0033-v01.w` (dizem THL0031 e citam `des-path`, que não existe nessas tabelas); os de `thl0030`, `thl0031`, `thl0050` e `thl0051` correspondem à própria tabela.

**Changelog 2026-09-25 (Aplicação no thl0022 e thl0040):**
- ✅ `thl0040-v01.w` (Rota inbound): campo `aplicacao` com zoom do `thl/thl0020-z01.w` (F5/duplo clique, `include/zoomvar.i`) e descrição ao lado (`fi-desc-aplicacao`, LEAVE + `local-display-fields` via `pi-desc-aplicacao`); campo reduzido para 30 colunas.
- ✅ `thl0022-v01.w` (objeto pai do Parâmetro Objeto): **só a descrição** da aplicação ao lado do campo — o viewer não tem link `TableIO` (campos sempre desabilitados), então F5 não dispararia; a aplicação vem do objeto navegado. Sem validação bloqueante em nenhum dos dois.

**Changelog 2026-09-25 (zoom e vá para nos cadastros):**
- ✅ Levantamento das 14 janelas de cadastro: faltavam zoom (`ProgPesquisa`) e vá para (`ProgVaPara`) em **thl0010**, **thl0011** e **thl0030**. Agora todas estão ligadas (thl0022 e thl0051 usam os do pai, como antes).
- ✅ **thl0011** (Grupo de E-mail): criados `thl0011-z01.w`, `thl0011-b02.w` (browse do zoom; `-b01` é o dos usuários) e `thl0011-g01.w`, a partir do thl0002 (mesmo template pai-filho).
- ✅ **thl0010** e **thl0030**: os satélites já existiam, mas as janelas passavam `''` à query; agora passam `ProgPesquisa`/`ProgVaPara`. Textos corrigidos: `thl0010-g01` ("Cod. Prog." → "Parâmetro E-mail"), pasta do `thl0010-z01` ("Programa" → "Parâmetro E-mail") e títulos-modelo dos zooms. `thl0010-g01.w` e `thl0010-z01.w` estavam em LF → CRLF.

**Changelog 2026-09-25 (guia do conector REST):**
- ✅ `Documentos	ecnico\guia-configuracao-conector-rest.md` reescrito contra o código: path **não** pertence a uma conexão; nova seção 3 com a resolução real (programa `aplicacao.objeto` em `thl-ambiente-param-prog` → parâmetro; **Parâmetro Conexão**/**Parâmetro Destino** do THL0022 são **códigos de variável**; o valor das variáveis é o `cod-conexao`/`cod-path`, ambiente corrente ou `*`), exemplo completo, mensagens de erro do `ConnectorConfig` e campo **Requer Cabeçalho**.
- ✅ [data/er-diagrama.md](data/er-diagrama.md) corrigido: saiu `thl-objeto-parametro` → `thl-ambiente-param`; entraram `thl-objeto-parametro` → `thl-ambiente-param-variavel` (valor = `cod-variavel`) e `thl-objeto` → `thl-ambiente-param-prog` (`aplicacao.objeto` = `cod-prog-dtsul`). [integration/connectors.md](integration/connectors.md) detalha a mesma resolução.
- ✅ `Database	hl.df`: DESCRIPTION e HELP de `thl-objeto-parametro.cod-param-ambiente`/`-destino` reescritos (código da **variável** cujo valor é o `cod-conexao`/`cod-path`) e rótulos trocados para **"Variável Conexão"** / **"Variável Destino"** (LABEL e COLUMN-LABEL; as telas `thl0022-b01.w` e `thl0022a-v02.w` herdam do dicionário — recompilar). Trailer recalculado (84234), ISO-8859-1/CRLF conferidos.

**Changelog 2026-09-25 (diagrama de vínculos das tabelas):**
- ✅ Nova nota [data/er-diagrama.md](data/er-diagrama.md): `flowchart` Mermaid com as 30 tabelas THL agrupadas pelas dezenas da numeração, 13 vínculos `fk-*` (linha contínua) e 15 vínculos só de código ou por valor (tracejada, cada um conferido no código). Sem cardinalidade e sem tabelas do ERP. Gerado por `Utils/scripts/gerar-er-diagrama.py` a partir do `.df` (renderização validada no Mermaid 10). A árvore em texto do [schema.md §3](data/schema.md) foi substituída pelo link (estava errada em 3 pontos).
- 🔴 **Corrigido `thl0250rp.p`:** comparava `thl-audit-registro.banco` com o banco da configuração sem o prefixo `sh` que o `AuditLogService` grava — o expurgo da auditoria não encontraria nenhum registro. Agora `banco = 'sh' + thl-audit-tabela-purge.banco`, como no `thl0150.w`.
- ⚠️ Achados: `thl-conexao-rest-path` não pertence a uma conexão (o guia `tecnico\guia-configuracao-conector-rest.md` diz o contrário); `thl-audit-tabela-notificacao.grupo-email` não é lido por nenhum código; `thl-aplicacao` só é usada pelo zoom do thl0021.

**Changelog 2026-09-25 (sincronização dos .md):**
- ✅ [convencoes.md](convencoes.md): §1 com a situação de codificação de 2026-09-25 (`Fontes\thl` sem UTF-8; os 121 "unknown-8bit" são **CP850** dos templates TOTVS, não Windows-1252 — converter decodificando como CP850); **novo §7 — numeração dos programas** (`thl00NN` cadastro, `thl01NN` consulta, `thl02NN` tarefa, mesmo `NN` por assunto; mapa das dezenas; cabeçalhos com o nome do arquivo).
- ✅ Ponteiros para o §7 em `AGENTS.md`, skill `thl-coding` e [thl/camada-datasul.md](thl/camada-datasul.md) §1 (observação de codificação corrigida). [data/schema.md](data/schema.md): uso de `idx-data-envio` pelo expurgo thl0210.
- ✅ Guias: `negocio\guia-cadastros-thl.md` (seção THL0020 Aplicação; retenção da auditoria e THL0250), `negocio\guia-operacional-biblioteca-thl.md` (THL0020 e nova tabela **Rotinas de execução**: THL0210/0220/0221/0222/0250), `tecnico\guia-monitoramento-tecnico.md` (rotinas de limpeza), `tecnico\guia-reprocessamento-mensagem.md` (THL0220 e correção do agendador), `README.md` (programas novos e regra de numeração). Links relativos validados (202 ok; o único "quebrado" é o exemplo de sintaxe no `AGENTS.md`).

**Changelog 2026-09-25 (expurgo da auditoria — thl0250):**
- ✅ `Fontes	hl	hl0250.w` (w-relat, gerado do thl0210) + `thl0250rp.p` (novo, ISO-8859-1/CRLF). Seleção **só pela faixa da chave** de `thl-audit-tabela-purge` (banco, tabela); os dias vêm de `retencao-dias` de cada tabela (0 ou em branco = ignorada). Elimina `thl-audit-registro` + `-detalhe` + `-notificar` criados antes de hoje − retenção, por `idx-tabela-data` (igualdade + intervalo), uma transação por registro, e grava `dt-ultima-execucao`. Relatório só com resumo por tabela (conteúdo auditado pode ser sensível). [thl/camada-datasul.md](thl/camada-datasul.md), [data/schema.md](data/schema.md).

**Changelog 2026-09-25 (expurgo de e-mails — thl0210):**
- ✅ `Fontes	hl	hl0210.w` (w-relat, gerado do thl0222) + `thl0210rp.p` (novo, ISO-8859-1/CRLF): elimina `thl-email` por faixa de programa e dias mantidos (mínimo 1, validado na tela). O RPW percorre `idx-data-envio` programa a programa (igualdade + intervalo em `data-envio`), uma transação por registro, com buffer próprio para o `delete`; e-mail sem `data-envio` não é eliminado. [thl/camada-datasul.md](thl/camada-datasul.md).
- ✅ Rótulo do campo de dias trocado de "Qtd. Dias" para **"Manter Dias"** em `thl0210.w` e `thl0222.w` (campo movido para a coluna 13.43 para o rótulo caber) e na coluna do relatório do `thl0210rp.p`.
- ✅ `thl0222.w`: carga dos combos de objeto corrigida — estava depois do `wait-for` (só rodava ao fechar a tela); agora roda antes e também quando a tela é aberta persistente. `ADD-LAST` com 1 parâmetro (combo `LIST-ITEMS`), `first-of` para não repetir objeto de aplicações diferentes, `can-find` com `aplicacao` (chave inteira de `pk-objeto-usuario`) e faixa padrão do primeiro ao último objeto.
- ✅ `thl0222.w` (expurgo de mensagens): combos sem o filtro `sentido-fluxo` — listam objetos inbound e outbound, coerente com o `thl0222rp.p`, que elimina mensagens dos dois sentidos na faixa.
- ✅ Mesma correção em `thl0220.w` (outbound) e `thl0221.w` (inbound). No `thl0220.w` também corrigido o filtro `thl-objeto.ind-inativo` sem `not`, que listava só objetos **inativos**. `thl0221.w` e `thl0222rp.p` convertidos para **ISO-8859-1** (CRLF mantido); os acentos perdidos (`�`) foram restaurados pela mesma linha do template em `thl0220.w`. `thl0120.w` também convertido (13 acentos restaurados pelas telas do mesmo template). **Nenhum fonte de `Fontes	hl` segue em UTF-8.**

**Changelog 2026-09-25 (.df — números de programa nas descrições):**
- ✅ `Database\thl.df`: 18 citações de programas nas DESCRIPTION trocadas para a numeração nova (`thl0004→0011`, `0005→0021`, `0006→0022`, `0011→0010`, `0020/0021→0050/0051`, `thl2000→0110`, `thl1986→0120`, `thl1989z.p→thl0220z.p`); a descrição nova de `thl-aplicacao` (thl0020) mantida. Tamanho em bytes inalterado, trailer conferido (83942). Pendência "descrições do `.df`" do [ADR](adr/renumeracao-cadastros-depara.md) resolvida.

**Changelog 2026-09-25 (cadastro de Aplicação — thl0020):**
- ✅ `Database\thl.df`: `thl-aplicacao` (já incluída pelo responsável: `aplicacao`, `descricao`, `pk-aplicacao`) ganhou LABEL/DESCRIPTION da tabela, descrição e ajuda de `descricao` e DESCRIPTION do índice; trailer recalculado (83942). Agora 30 tabelas, 188 campos, 59 índices.
- ✅ Cadastro **thl0020** (`w-cadsim`) gerado da família thl0021: `thl0020.w`, `-q01`, `-v01`, `-b01`, `-z01`, `-g01` (ISO-8859-1, CRLF). Viewer com código só na inclusão (`ADM-CREATE/ASSIGN/MODIFY-FIELDS`) e validação de obrigatório/duplicado em `Pi-validate`. [data/schema.md](data/schema.md), [thl/camada-datasul.md](thl/camada-datasul.md).
- ✅ `Utils\scripts\carga-thl-aplicacao.p`: carga inicial de `thl-aplicacao` com os valores distintos de `aplicacao` em `thl-objeto`, `-parametro`, `-usuario`, `thl-inbound-rota` e `thl-mensagem` (salto por índice, idempotente, **simulação por padrão**, log em `session:temp-directory`).
- ✅ Zoom de Aplicação no cadastro de Objeto: `thl0021-v01.w` abre `thl/thl0020-z01.w` por F5/duplo clique em `thl-objeto.aplicacao` (`include/zoomvar.i`) e mostra a descrição em `fi-desc-aplicacao` (LEAVE e `local-display-fields`, via `pi-desc-aplicacao`); **sem validação bloqueante** (aplicação fora do cadastro só fica sem descrição). `thl0020-b01.w` ganhou o `pi-retorna-valor` (`aplicacao`, `descricao`) usado pelo zoom.
- ⚠️ `thl0021-g01.w` usa `ut-table.i ... es_solic_lote_impl_tit_ap` (tabela de cliente copiada de outro programa) e está em LF — corrigido só no thl0020-g01. `thl-aplicacao` ainda não é validada pelas outras tabelas (campo `aplicacao` segue texto livre).

**Changelog 2026-09-25 (renumeração das tarefas + correção do agendador):**
- ✅ Regra: tarefa = `thl02NN`. `thl1988 → thl0220` (reprocessamento outbound), `thl1991 → thl0221` (inbound agendado), `thl1989 → thl0222` (expurgo), `thl1989z.p → thl0220z.p` (agendador). `SchedulingService`/`InboundSchedulingService` chamam `run thl/thl0220z.p`. [ADR §8](adr/renumeracao-cadastros-depara.md).
- 🔴 **Defeito corrigido:** o agendador criava o `ped_exec` outbound com `thl/thl1989rp.p`, o runner de **expurgo** (os ids internos dos dois runners estavam invertidos). A mensagem outbound agendada não era enviada e uma já integrada podia ser apagada. Agora aponta para `thl/thl0220rp.p`. ⚠️ Esvaziar a fila RPW antes de publicar; cadastrar os programas no Datasul; testar o agendamento outbound.
- Notas atualizadas: [thl/camada-datasul.md](thl/camada-datasul.md), [integration/messaging-outbound.md](integration/messaging-outbound.md), [integration/messaging-inbound.md](integration/messaging-inbound.md), [data/schema.md](data/schema.md), [core/context.md](core/context.md), guias de `negocio\`/`tecnico\` e skill `thl-qa`.

**Changelog 2026-09-25 (renumeração das consultas):**
- ✅ Regra: consulta = `thl01NN` (mesmo `NN` do cadastro). `thl2000 → thl0110` (e-mail), `thl1986 → thl0120` (mensageria; passou por `thl0121` e foi ajustado), `thl2020 → thl0150` (auditoria) — 9 telas, cabeçalhos corrigidos (`thl2020b` se identificava como `thl2000a`), comentários de 3 classes de mensageria. [ADR §7](adr/renumeracao-cadastros-depara.md). ⚠️ `thl0121.w` em UTF-8 (já estava); `RUN thl\thl0121h.w` segue apontando para tela inexistente.
- ✅ Números novos em `Documentos\negocio\` (inclusive os de cadastro em maiúsculas que tinham ficado para trás), `Documentos\tecnico\`, `README.md`, skill `thl-qa`, `erp/erp-services.md`, `data/schema.md`, `thl/camada-datasul.md`.

**Changelog 2026-09-25 (renumeração dos cadastros executada):**
- ✅ 110 telas `thl00*.w` renomeadas conforme o [ADR](adr/renumeracao-cadastros-depara.md) (agora `status: aceita`, §6): Ambiente 0001, Parâmetro 0002, Email 0010, Grupo Email 0011, Objeto 0021, Parâmetro Objeto 0022, Conexão REST 0030–0033, Rota 0040, Auditoria 0050/0051; 0020 reservado para Aplicação. Referências internas trocadas byte a byte (ISO-8859-1/CRLF preservados) e cabeçalhos `i-prgvrs.i`/`ut9000.i` corrigidos. ⚠️ Recompilar; atualizar menu/permissões Datasul e apagar `.r` antigos; descrições do `.df` pendentes.
- ✅ Números novos em `README.md`, [thl/camada-datasul.md](thl/camada-datasul.md), [data/schema.md](data/schema.md), [util/util.md](util/util.md) e guias de `Documentos\tecnico\`.

**Changelog 2026-09-25 (ADR — renumeração dos cadastros):**
- ✅ Criado [adr/renumeracao-cadastros-depara.md](adr/renumeracao-cadastros-depara.md) (status: proposta, **só levantamento**, nenhum fonte alterado): 13 cadastros associados pela tabela principal, 5 números novos em conflito (thl0002, 0010, 0011, 0020, 0021), 2 dúvidas (thl0007 → URI; `thl0021h` órfã), ordem de migração sem ciclo, referências arquivo:linha. Nenhuma referência em `.cls`, RPW ou web.
- ✅ [thl/camada-datasul.md](thl/camada-datasul.md): `thl-conexao-rest-header` já existe no `.df` (a nota dizia ausente); thl0021 inclui `-acesso` e `-campo`; cabeçalhos `i-prgvrs.i` com identificação errada (`thl0021.w` = `thl0006`, `thl0021b/d/e` = `thl0020b..e`, `thl0020.w` = `XX9999`).

**Changelog 2026-09-24 (sincronização das notas):**
- ✅ [logging/logging.md](logging/logging.md): nome certo da tabela (`thl-audit-tabela-campo`, não `thl-audit-campo-tabela`), flags reais (`ind-ativo-create/-update/-delete`, `ind-audit-tabela`), o que vai em cada campo de `thl-audit-registro` (usuários corrigidos), `buildReference` documentado (`pk` = array JSON, referência unida por `|`) e alerta do `matches` (falso positivo).
- ✅ [erp/erp-services.md](erp/erp-services.md): `AuditoriaService` lê (não grava) o usuário, índices usados, e o filtro de sensibilidade por tabela que a API não aplica (em vez do aviso antigo de tabelas ausentes do `.df`). [integration/connectors.md](integration/connectors.md): header único por conexão.
- ✅ `.df`: descrições de `thl-audit-tabela.pk`, `thl-audit-registro.referencia` e `.campos` corrigidas (array JSON / `|` / `Todos`). Skills `thl-coding` e `thl-qa`: regras de índice e consulta (`pk`/`fk`/`idx`, igualdades + um intervalo, `?` em intervalos, `XREF`).

**Changelog 2026-09-24 (.df — rótulos e descrições):**
- ✅ `Database\thl.df`: LABEL e DESCRIPTION das 29 tabelas; LABEL, COLUMN-LABEL, DESCRIPTION e HELP dos 186 campos; DESCRIPTION dos 58 índices. Textos em português com acentos (ISO-8859-1), com o domínio dos campos codificados tirado dos enums (MessageStatusEnum, MethodTypeEnum, ConnectorTypeEnum, ExecutionMode, DirectionEnum, AuditOperationEnum, AuditSnapshotEnum). Corrigidos rótulos errados (`thl-email-param.copia` dizia Remetente; `Emial`, `Ambeinte`, `hearder`). Nomes de tabelas, campos e índices inalterados (só os 4 atributos de texto mudaram); aplicado sobre o `.df` sem a sequência `thl-seq-id-email` (removida pelo responsável); trailer recalculado.
- Campos que só existem nas telas (`ind-persistente`, `qtd-*-persist`, `frequencia-execucao`, `tipo-log-*`, `programa-consulta`) descritos como ainda não lidos pela biblioteca.
- ✅ Corrigido em seguida: `AuditLogService.cls:172-173` gravava os usuários trocados; agora `usuario` = `ContextService:getErpUser()` (Datasul) e `usuario-so` = `getUser()` (SO). Registros gravados antes da correção continuam trocados. `core/context.md`, `erp/erp-services.md` e `thl/camada-datasul.md` atualizados para o nome atual `getErpUser()` (era `getDatasulUser()`).

**Changelog 2026-09-24 (.df com a convenção aplicada):**
- ✅ `Database\thl.df` completo regerado com a convenção `pk-`/`fk-`/`idx-` (tabelas serão apagadas e recriadas no ambiente): 44 índices renomeados, `thl-audit-tabela-purge.idx-tabela` removido (idêntico à chave), `thl-conexao-rest-header.pk-conexao-rest` agora `UNIQUE`. 58 índices = 29 `pk` + 13 `fk` + 16 `idx`; trailer recalculado. [data/schema.md](data/schema.md) §2/§4 com os nomes novos; §6 virou histórico de nomes.

**Changelog 2026-09-24 (convenção de índices):**
- ✅ Convenção de nomes de índice decidida: `pk-` chave primária (única, uma por tabela), `fk-<tabela-pai>` chave estrangeira, `idx-` busca — [convencoes.md §6](convencoes.md) e `AGENTS.md`.
- ✅ [data/schema.md §6](data/schema.md): plano de renomeação do `.df` atual (44 `RENAME INDEX` + 1 `DROP INDEX`), gerado do próprio `.df`. `.df` relido: `thl-mensagem.idx-objeto-criacao` virou `PRIMARY` (resolve o empate pela regra do primário); `thl-conexao-rest-header` ganhou índice (falta `UNIQUE`).

**Changelog 2026-09-24 (schema / índices):**
- ✅ [data/schema.md](data/schema.md) reescrita a partir do `Database\thl.df` refeito (29 tabelas, 186 campos, 58 índices, ISO-8859-1): tabelas por domínio com dump-name, **inventário completo de índices** com quem usa cada um, relações da auditoria e divergências.
- Índices novos para busca: `thl-mensagem.idx-objeto-criacao`, `thl-objeto-usuario.idx-usuario`, `thl-audit-registro.idx-tabela-data`, `thl-audit-tabela-acesso.idx-usuario` (refeito). 13 índices renomeados `ind-*` → `idx-*` (nenhum `use-index` afetado).
- ⚠️ Pendentes: `idx-objeto-parametro` empata com `idx-objeto-criacao` (vence pelo nome); índices redundantes listados em §2; `thl-conexao-rest-header` sem índice; `thl-mensagem.pacote` usado em `thl1986.w` e inexistente no banco.

**Changelog 2026-09-24 (arquitetura):**
- ✅ Criada a nota central [arquitetura.md](arquitetura.md) (camadas, mapa das hierarquias, fluxos inbound/outbound em Mermaid, onde estender) e a pasta `arquitetura\` com uma nota por classe-base: [Message](arquitetura/Message.md), [InboundMessage](arquitetura/InboundMessage.md), [OutboundMessage](arquitetura/OutboundMessage.md), [MessageStructureStrategy](arquitetura/MessageStructureStrategy.md), [Service](arquitetura/Service.md), [BusinessObject](arquitetura/BusinessObject.md), [IntegrationConnector](arquitetura/IntegrationConnector.md), [ITokenProvider](arquitetura/ITokenProvider.md), [IHeaderProvider](arquitetura/IHeaderProvider.md), [AppError](arquitetura/AppError.md).
- Hierarquia extraída do código (58 `inherits`, 3 `implements`). Cada nota lista as filhas e aponta para a nota de pacote e de extensão — é a rede exibida no Graph view do Obsidian (`.obsidian\graph.json`: cores por camada, `poui\` oculta).
- ⚠️ Achados: `ErrorHandler` herda de `AppError` mas é usado como utilitário; nomes repetidos `LpcoMessage` (inbound/outbound) e `NotaFiscalMessage` (thl-lib inbound × loogai outbound).

**Changelog 2026-09-24 (thl-architect — sync core/context.md):**
- 🔴 **Divergência corrigida em `core/context.md`:** faltava `ContextService:getDatasulUser()` (criado em 2026-09-15). Documentados o método, a ponte `thl/api/geterpuser.p` (lê `c-seg-usuario` NEW GLOBAL SHARED), a dependência de PROPATH do `RUN` literal e os consumidores reais (`AuditoriaService`, `MensageriaService`; `AuditLogService` usa `getUser`/`getProgramsCaller`).
- ✅ `ContextService.cls:20` corrigido: `run thl-lib/core/context/getdatasuluser.p` → `run thl/api/geterpuser.p` (o `.p` foi movido e renomeado; a chamada antiga falhava em tempo de execução).
- Contagem de classes: inalterada (nenhuma classe nova).

**Changelog 2026-09-24 (Obsidian):**
- ✅ `Documentos\.claude\` configurada como vault do Obsidian (`.obsidian\app.json`: links Markdown relativos, sem wikilinks, para continuar legível por agentes e pelo GitHub). `workspace*.json`, `cache\` e `.trash\` ignorados no Git (`**/.obsidian/...` no `.gitignore` da raiz). Os 30 links relativos entre notas foram validados (0 quebrados).

**Changelog 2026-09-24 (web — migração para standalone):**
- ✅ `Fontes\web\src\app\modules\` (3 NgModules + 2 routing modules) migrada para standalone por feature e removida: `metricas\` virou feature (`metricas-routing.ts`); painel de integrações, `integration-card`, pipes (`standalone: true`) e `message-detail-modal` → `mensageria\`; `email-detail-modal` → `email\`. Rotas mantidas (`''`, `dashboard-mensageria`). `ng build` OK antes e depois; specs ajustados (`imports` no lugar de `declarations`), mas o projeto não tem alvo de teste configurado.
- `web/app-web.md`, `convencoes.md` e skill `thl-web-coding` atualizados.

**Changelog 2026-09-24 (skills web):**
- ✅ Criadas as skills de projeto `thl-poui-design` (especificação de telas com PO UI + Angular + componentes `thl-*` + TOTVS) e `thl-web-coding` (Angular 21 standalone por feature, services para `resourcen`, testes, build/deploy).
- ✅ `convencoes.md`: exceção **UTF-8 para o front-end web** e padrão standalone por feature; `web/app-web.md`: seção "Padrão adotado".

**Changelog 2026-09-24 (skills no projeto):**
- ✅ Skills `thl-architect`, `thl-coding` e `thl-qa` copiadas para o repositório em `.claude\skills\<nome>\SKILL.md` e atualizadas: ISO-8859-1, pacote em minúsculas, layout `thl-extensions\{erp,integration}\<sistema>\`, contrato `Service`, 126 classes, `Utils\test\` vazio, variáveis sem prefixo de tipo. As versões da conta Claude continuam com o texto antigo.

**Changelog 2026-09-24 (thl-coding — grafia de pacotes + padrão de codificação):**
- ✅ **Grafia `Inbound`/`Outbound` corrigida** no código: 44 ocorrências em 33 arquivos (11 declarações `class` + `USING`/`INHERITS` em thl-lib, thl-extensions e `resourcen.p`). As 126 classes batem pacote × pasta. Troca feita byte a byte (codificação e CRLF preservados). ⚠️ Recompilar messaging + extensões + `resourcen.p`; os valores de `thl-objeto.classe-objeto` com maiúscula funcionam no Windows, mas devem ser padronizados.
- ✅ **`convencoes.md` criado:** padrão de codificação **ISO-8859-1** (decisão do responsável), pacote em minúsculas, localização e nomes. Conversão dos 58 fontes UTF-8 pendente.
- Notas e guias atualizados para a grafia minúscula: `messaging-inbound.md`, `messaging-outbound.md`, `automatizador.md`, `ninahub.md`, 3 guias de `tecnico\`.

**Changelog 2026-09-24 (thl-architect — sincronização geral da base com o código):**
- 🔴 **Reescritas a partir do código:** `erp/erp-services.md` (sem `IService`/`failure()`/`buscarEmitente`; 27 classes) e `integration/messaging-inbound.md` (fluxo REST completo; sem `executeAndRegister`/`methodPost(context)`/`NotaFiscalPorEmbarqueMessage`).
- ✅ **Corrigidas:** `extensions/loogai.md` (contrato `Service`, hooks sem `payload`, `buildResponse`, `StatusDocumento`), `extensions/ninahub.md` (absorveu `nina.md`; `NinahubNotaFiscalService` com todos os overrides), `integration/messaging-core.md` (+9 métodos), `integration/messaging-outbound.md` (−`hasRecordId/hasReferenceCode`, +protected), `logging/logging.md` (`hasChangedMonitoredField`), `util/util.md` (`CompilationResult` com `private set`), `refactoring/backlog-inbound-erp.md` (estado atual), `poui/INDEX.md` (versões do projeto).
- ✅ **Criadas:** `extensions/gestaoepi.md`, `extensions/iacompras.md`, `extensions/powerautomate.md`, `data/schema.md`, `thl/camada-datasul.md`, `web/app-web.md`.
- 🗑️ **Removidas (a pedido):** `classes/` (10 notas duplicadas), `extensions/nina.md`, `integration/totvs-api.md`, `util/document-conversion.md` (módulo inexistente), `INDEX.zip`.
- ✅ Tabela de arquivos e "Distribuição por pacote" refeitas: **126 classes** (105 thl-lib + 21 thl-extensions). Risco de `FretePrevistoService` (des-observacao) marcado como reaberto.
- Também revisados fora da `.claude\`: `Documentos\tecnico\*` (6 guias) e `Documentos\negocio\*` (5 guias).

**Changelog 2026-09-24 (thl-coding + thl-architect — Lpco/Frete saem de thl-lib):**
- 🔴 **Violação de camada corrigida:** `LpcoService`, `LpcoMessage` (inbound), `FretePrevistoService`, `FreteMessage` e `SituacaoFreteEnum` usavam tabelas do cliente (`nit-lpco`, `nit-frete-prev`) dentro de `thl-lib`. Movidos para `thl-extensions\erp\automatizador\service\`, `thl-extensions\integration\automatizador\messaging\inbound\message\`, `thl-extensions\erp\dvv\{service,enum}\` e `thl-extensions\integration\dvv\messaging\inbound\message\`. `thl-lib` não referencia mais nenhuma tabela `nit-*`.
- ✅ `extensions/automatizador.md` atualizado (LpcoMessage inbound + LpcoService); **`extensions/dvv.md` criado** (FreteMessage, FretePrevistoService, SituacaoFreteEnum).
- ⚠️ Pendente (fora do código): `thl-objeto.classe-objeto` de LpcoMessage/FreteMessage → novos nomes completos; recompilar.
- ⚠️ Pendente (documentação): `erp/erp-services.md` e `integration/messaging-inbound.md` ainda descrevem essas 5 classes em `thl-lib`; a tabela "Distribuição por pacote" deste índice ainda não reflete a mudança.
- Contagem de classes: inalterada no total (5 classes mudam de `thl-lib` para `thl-extensions`).

**Changelog 2026-09-17 (thl-qa — auditoria completa util + sync util.md):**
- 🔴 **8 divergências corrigidas em `util.md`** — reescrita completa sincronizada com código real:
  1. `DocumentConversionService` removida (arquivo `.cls` não existe no working copy)
  2. `CompilationReport` removida (classe absorvida por `TableImpactCompiler`)
  3. `JsonArrayCsvExporter` adicionada (nova classe `util/export/`, criada 2026-09-17, RFC 4180)
  4. `StringUtil`: 5 métodos não documentados adicionados (`removeCr`, `removeLf`, `removeCrLf`, `formatIsoDate`, `parseDate`)
  5. `JsonWriter`: 2 métodos `charListToJsonArray` adicionados; parâmetro falso `rootName` removido de `toJsonFromBuffer`
  6. `SchemaUtil`: nomes de campos TT corrigidos com sufixo `_` (`data-type_`, `label_`, `column-label_`, `mandatory_`, `extent_`, `description_`)
  7. `TableImpactCompiler`: API reescrita — `execute()` retorna `JsonArray` (não `CHARACTER`); novos `executeForTable()` para pipeline de duas passadas; `logDirectory` property removida; referências a `CompilationReport` removidas
  8. Scanner: documentação alinhada com arquitetura real (4 classes: `FileScanner`, `ScannedFileSet`, `IFileEnricher`, `FileContentSearcher`)
- ⚠️ **17 findings QA registrados** (7 HIGH, 6 MED, 4 LOW): StringUtil sem `block-level`, JsonWriter sem `block-level`, PaginationHelper bug no construtor (pageSize=0), CompilationResult `public set`, testJsonSetter.p quebrado, headers incorretos em StringUtil/JsonWriter/FileUtil
- ✅ **Artefatos de teste criados:** `testStringUtil.p` (17 testes), `exampleStringUtil.p` (5 cenários)
- Contagem real de classes util: **14** (7 base + 4 scanner + 3 compile). Anteriormente documentado como 18 — delta causado por 2 classes fantasma (DocumentConversionService, CompilationReport) e contagem inflada do scanner (doc dizia 7, real são 4).

**Changelog 2026-09-16 (thl-coding — scanner genérico + compile separado):**
- ✅ **Pacote `thl-lib.util.scanner` reestruturado** (7 classes): scanner genérico de texto em fontes — não conhece ABL, tabelas ou compilação. Busca configurável por substring ou word-boundary via `delimiters`. Exclusões de arquivo via JSON (`scanner-exclusions.json`).
- ✅ **Classes scanner:** `ScannerConfig` (searchText + delimiters), `FileSystemWalker` (varredura OS-DIR), `SourceFileAnalyzer` (abstract Template Method com word-boundary), `IncludeAnalyzer` (referencesText), `ProgramAnalyzer` (referência direta + includes), `ScannerReport` (sem compilação), `ProgramScanner` (fachada genérica + getMatchedPrograms).
- ✅ **Pacote `thl-lib.util.compile` criado** (4 classes): compilação ABL-específica separada do scanner genérico.
- ✅ **Classes compile:** `CompilationResult` (value-object), `ProgramCompiler` (COMPILE SAVE NO-ERROR), `CompilationReport` (grava .log de compilação), `TableImpactCompiler` (fachada ABL: strip qualificador de banco + delimitadores ABL + scan + compile).
- ✅ `util.md` atualizado: tabela-resumo com 11 novas entradas (7 scanner + 4 compile), seções detalhadas com arquitetura, contratos, exemplos.
- ✅ Exemplos atualizados: `exampleProgramScanner.p` (3 cenários: substring, word-boundary, self-scan), `exampleProgramScannerTwoPass.p` (ProgramScanner para listagem + TableImpactCompiler para compilação).
- Contagem de classes: **92** (+11: 7 scanner + 4 compile). `thl-lib.util` passa de 7 para 18 classes.

**Changelog 2026-08-28 (thl-architect + thl-coding — SchemaUtil:getFieldSchema adicionado):**
- 🔴 **Divergência corrigida:** `util.md` documentava `getPrimaryIndexFields` (método único inexistente). O código real tem `getPrimaryIndexFieldsAsJson` (retorna `LONGCHAR` JSON array) e `getPrimaryIndexfieldsName` (retorna `CHARACTER` CSV). `util.md` corrigido com ambos os métodos reais.
- ✅ **`SchemaUtil:getFieldSchema` adicionado** — `METHOD PUBLIC STATIC VOID`, retorna `OUTPUT TABLE FOR ttFieldSchema` com 10 campos do `_Field` (`field-name`, `data-type`, `field-format`, `label`, `column-label`, `mandatory`, `extent`, `initial-value`, `description`, `field-order`). Acesso via `CREATE BUFFER FOR TABLE '{banco}._Field'` — sem CONNECT, sem DICTDB, seguro em PASOE multi-agente. Lança `ErrorHandler` para banco não conectado ou tabela não encontrada. `DEFINE TEMP-TABLE ttFieldSchema` adicionada ao body da classe. Nova dependência: `USING thl-lib.core.error.ErrorHandler`.
- ✅ `util.md` atualizado: tabela-resumo de SchemaUtil, contrato completo de ttFieldSchema, diferença de tratamento de erro entre `getPrimaryIndex*` e `getFieldSchema`.
- Contagem de classes: **81** (inalterada — apenas método novo em classe existente).

**Changelog 2026-08-24 (thl-architect — sync global ThlError + InboundMessage API + novos: IHeaderProvider, HeaderProviderFactory, RequisicaoMessage):**
- ✅ **`ThlAppError` → `ThlError` (rename global):** `ThlAppError.cls` renomeado para `ThlError.cls` (`thl-lib.core.error`). Formato de mensagem invertido: era `[Classe.metodo] msg`, agora `msg [Classe.metodo]`. Todos os `.md` do projeto atualizados (util.md, erp-services.md, loogai.md, nina.md, mmcm.md, document-conversion.md, classes/core.md, classes/erp.md, classes/INDEX.md, connectors.md, messaging-core.md, messaging-outbound.md, messaging-inbound.md, email.md, environment.md, error.md).
- ✅ **`ErrorHandler` reescrito:** agora `inherits Progress.Lang.AppError`; novo construtor `(className, methodName, stepName)`; `clearErrors()`/`createError()` removidos; `getErrorJson()` agora privado; `addError` auto-formata via `createErrorMessage`.
- ✅ **`InboundMessage` API atualizada:** `dispatchInbound(context)` → `dispatchInbound()` (sem parâmetro); `executeAndRegister` → `executeService`; `createService()` retorna `Service` (não `IService`); `methodPost/Patch/Delete` sem parâmetro `context`; `getRequiredFields()` não é mais `abstract` (default `''`); `getExternalReferenceField()` default mudou de `'referenciaID'` para `'externalID'`.
- ✅ **`IHeaderProvider` criado** (`thl-lib.integration.connectors.headers.interfaces`): interface `getHeaders(body as longchar, parameters as character): JsonArray`.
- ✅ **`HeaderProviderFactory` criado** (`thl-lib.integration.connectors.headers.factory`): factory estática `getProvider(className)` via `dynamic-new`. Documentados em `integration/connectors.md`.
- ✅ **`ConnectorConfig` ampliado:** 3 novas propriedades (`requiresHeaderProvider`, `headerProviderClass`, `headerParameter`) + nova tabela `thl-conexao-rest-header`.
- ✅ **`RestConnector` ampliado:** 9 métodos `protected` novos + `applyCalculatedHeaders` integrado ao fluxo de envio.
- ✅ **`RequisicaoMessage` documentado** (`thl-lib.integration.messaging.inbound.message`): roteamento por `context:operation` (`'item'` → `ItemRequisicaoService`, else → `RequisicaoService`); `loadExternalReference()` retorna `''`; `getRequiredFields()` exige `nr-requisicao` para DELETE.
- Contagem de classes: **81** (+3: `IHeaderProvider`, `HeaderProviderFactory`, `RequisicaoMessage`; ThlError substitui ThlAppError — contagem líquida zero).

**Changelog 2026-08-15b (thl-architect — sync logging.md):**
- 🔴 **Divergência crítica corrigida:** `logging.md` documentava `AuditLogService` com API de 2025 (métodos `insertRecord/updateRecord/deleteRecord` com assinaturas antigas, sem enums, sem `thl-audit-registro-detalhe`). Classe foi completamente reescrita. Documentação reescrita do zero com estado real.
- ✅ **`AuditOperationEnum` e `AuditSnapshotEnum` documentados** (`thl-lib.logging.audit.enum`) — criados em 2026-08-14, não existiam na doc.
- ✅ **Todos os métodos privados documentados:** `logRecord` (2 overloads), `logRecordDetail`, `hasChangedMonitoredField`, `hasChangedMonitoredTable`.
- ✅ **Tabelas reais documentadas:** `thl-audit-tabela`, `thl-audit-campo-tabela`, `thl-audit-registro`, `thl-audit-registro-detalhe`.
- Contagem de classes: **78** (+2 enums — `AuditOperationEnum`, `AuditSnapshotEnum`). Documentação sincronizada: `logging/logging.md`, INDEX.md.

**Changelog 2026-08-15 (thl-coding — SchemaUtil criado):**
- ✅ **`SchemaUtil.cls` criado** (`thl-lib.util.schema`): consulta Data Dictionary via 4 handles dinâmicos de schema (`_File`, `_Index`, `_Index-field`, `_Field`). Método único `buscarCamposIndicePrimario(pcBanco, pcTabela)` — `STATIC FINAL`, retorna campos do índice PRIMARY concatenados por vírgula ou `''` em qualquer falha. `DO ON ERROR UNDO, RETURN '':` suprime exceções; FINALLY libera todos os handles. Padrão idêntico a `StringUtil`/`FileUtil` (sem herança, `serializable`).
- Contagem de classes: **76** (+1 `SchemaUtil`). `thl-lib.util` passa de 6 para 7 classes. Documentação sincronizada: `util/util.md`, INDEX.md.

**Changelog 2026-08-12 (thl-architect — hierarquia Service com Template Method):**
- ✅ **`IErpService` renomeado para `IService`** (`thl-lib.erp.core`): o pacote `erp.core` já qualifica o domínio — `ErpService` era redundante. Interface continua lean (apenas `execute()`).
- ✅ **`Service.cls` criado** (`thl-lib.erp.core`): classe abstrata base com padrão Template Method. `execute()` despacha para `create()/update()/delete()` (defaults lançam `ThlAppError`). Properties: `inContext` (public get, protected set), `outContext`, `operation` (protected get, private set). Abstratos: `loadReferenceCode()`, `getEntityName()`. Hooks: `initialize()` (vazio), `buildResponse()` (retorna `ServiceResponse:success`).
- ✅ **`BusinessObject` e `ApplicationProgrammingInterface`** agora `inherits Service` — herdeiros recebem `execute()` sem implementá-lo.
- ✅ **10 Services concretos migrados** — `execute()` e `inContext` removidos de todos, `create/update/delete/loadReferenceCode` mudaram para `protected override`, `getEntityName()` adicionado:
  - **Standalone** (inherits Service): `LpcoService` (+ `initialize()` para `positionRecord`), `FretePrevistoService` (+ `initialize()` para `setValue`), `EmitenteService`, `ItemService`, `LocalEntregaService`.
  - **BO** (inherits BusinessObject, sem implements IService): `DocumentoService`, `UsuarioService`.
  - **API** (inherits ApplicationProgrammingInterface, sem implements IService): `EmbarqueService`.
  - **NF Base** (`NotaFiscalBaseService`): `initializeExecution(payload)` → `initialize()` override (usa `this-object:inContext`); abstract `loadReferenceCode()` removido (herdado de Service).
  - **NF Concretas** (`NotaFiscalService`, `NotaFiscalPorEmbarqueService`): `create()` override com roteamento por `this-object:operation`; `buildResponse()` override adiciona `outPayload`.
- ✅ **3 extension Services verificados** — nenhuma alteração necessária: `LoogAiEmbarqueService` (hooks), `LoogAiDocumentoService` (override de `execute()` compatível com `Service:execute()`), `NinaNotaFiscalService` (hooks).
- Contagem de classes: **75** (+1 `Service`). `thl-lib.erp.core` agora tem 5 classes. Documentação sincronizada: `erp/erp-services.md`, INDEX.md.

**Changelog 2026-08-11 (thl-architect + thl-coding — revisão Nina NF):**
- ✅ **`NinaNotaFiscalMessage.cls` corrigido** (`thl-extensions.integration.nina`): cabeçalho corrigido (dizia "LoogAiEmbarqueMessage"), 4 USINGs órfãos removidos (`MethodTypeEnum`, `InboundMessage`, `InboundObjectContext`, `Progress.Json.ObjectModel`).
- ✅ **`NinaNotaFiscalService.cls` corrigido** (`thl-extensions.erp.nina.service`): cabeçalho corrigido (dizia "NotaFiscalService"), 6 USINGs órfãos removidos, buffer `b-nit-tipo-oper-natur` adicionado, FIND de `item` (tabela) removido de `resolveNature()` (código morto), `NO-ERROR` substituído por CATCH com `ThlAppError` em ambos os métodos, buffers nomeados usados consistentemente. FIND de `item` removido de `resolveNatureItem()` (não contribuía para determinação da natureza).
- ✅ **`NotaFiscalService.cls`** — hooks `resolveNature()` e `resolveNatureItem()` documentados em `erp-services.md` (padrão Template Method para natureza de operação).
- ✅ **`extensions/nina.md` criado** — documentação de `NinaNotaFiscalMessage` e `NinaNotaFiscalService`.
- Contagem de classes: **74** (+2 — `NinaNotaFiscalMessage`, `NinaNotaFiscalService`). Documentação sincronizada: `erp/erp-services.md`, `extensions/nina.md`, INDEX.md.

**Changelog 2026-08-11 (thl-coding — scaffolding consultas MMCM NF):**
- ✅ **`EmitenteService.cls` criado** (`thl-lib.erp.service`): consulta pura de `emitente` e `loc-entr`. Dois métodos públicos — `buscarEmitente(integer, character)` e `buscarLocalEntrega(integer, character, character)` — retornam `JsonObject`. Fallback por `nome-abrev`. **Não implementa `IErpService`** (serviço de consulta, sem CRUD). Query e montagem JSON marcadas como `/* TODO */`.
- ✅ **`ItemService.cls` criado** (`thl-lib.erp.service`): consulta pura de `item` por `it-codigo` (case-sensitive). Método `buscarItem(character)` retorna `JsonObject`. **Não implementa `IErpService`**. Query e montagem JSON marcadas como `/* TODO */`.
- ✅ **`EmitenteMessage.cls` criado** (`thl-lib.integration.messaging.inbound.message`): GET-only. Distingue `emitente/{codEmitente}` vs `emitente/{codEmitente}/locais-entrega/{codEntrega}` por `pathParameters:Length`. Extrai `codEmitente` de `context:operation` (endpoint simples) ou `pathParameters:GetCharacter(2)` (endpoint composto). `createService()` retorna `?`.
- ✅ **`ItemMessage.cls` criado** (`thl-lib.integration.messaging.inbound.message`): GET-only. `codigo = context:operation`. `createService()` retorna `?`.
- ⚠️ **`resourcen.p` precisa de novo padrão GET de 4 segmentos** (`/~*/~*/~*/~*`) para o endpoint `emitente/{codEmitente}/locais-entrega/{codEntrega}` — pendente com Thiago.
- ⚠️ Índices de `pathParameters` a verificar na compilação — dependem do mapeamento PASOE real.
- Contagem de classes: **72** (+4). Documentação sincronizada: `erp/erp-services.md`, `integration/messaging-inbound.md`, INDEX.md.

**Changelog 2026-07-31 sessão 10c (thl-coding — defaults do contrato Loog.ai migrados para o Service):**
- ✅ **`LoogAiEmbarqueMessage:methodPost` voltou a uma linha.** Deixou de injetar 6 campos no payload (`dataEmbarque`, `codigoTipo`, `codigoRota`, `nomeTransportadora`, `placa`, `sequencia`) + `dataEntrega` em cada item de `entregas`.
- ✅ **3 hooks novos em `EmbarqueService`:** `resolveShipmentDate`, `resolveSequence`, `resolveDeliveryDate` — base lê do payload e lança `ThlAppError` se ausente (coerente com `EmbarqueMessage:getRequiredFields`).
- ✅ **`prepareShipmentData` migrado para `JsonSetter`** nos 4 campos de transporte: ausentes no payload agora permanecem em branco naturalmente, dispensando os defaults vazios que a Message injetava. Alinha `EmbarqueService` ao padrão de `LpcoService`/`UsuarioService`.
- ✅ **`LoogAiEmbarqueService` passou de 2 para 5 overrides** — concentra todas as particularidades do contrato: CNPJ, usuário `'loogai'`, `today` para embarque e entrega, sequência `1`.
- **Motivação:** o Service só funcionava se chamado pela Message; um `.p` interno instanciando `LoogAiEmbarqueService` direto quebraria em `GetDate('dataEmbarque')`. Agora é autossuficiente — coerente com a decisão da sessão 6 de mover os Services para `erp.service` porque "criam registro no ERP independente de integração".
- Contagem de classes inalterada (82). Documentação sincronizada: `erp-services.md`, `loogai.md`, INDEX.md.

**Changelog 2026-07-31 sessão 10b (thl-architect — mutação de `inContext` esclarecida):**
- ✅ **Risco "mutação de `inContext` em `EmbarqueService:create`" ENCERRADO** — é decisão de design do usuário, não dívida. Objetivo: manter `loadReferenceCode()` como método único para CREATE e DELETE (no DELETE o `codigoEmbarque` vem no payload; no CREATE é gerado), evitando `find` no buffer a cada chamada.
- Verificação que sustenta o encerramento: `payloadText` é serializado na borda REST (`resourcen.p:63` → `setPayloadText()`) e gravado por `InboundMessageService:accept()` **antes** de `processOnline`/`scheduleProcessing` — a persistência em `thl-mensagem-conteudo` recebe o payload original. No fluxo RPW, `restoreForScheduledProcessing` reidrata do texto original, produzindo `JsonObject` limpo a cada reexecução.
- ⚠️ Único resíduo registrado: `JsonObject:Add()` lança se a chave existir; trocar por `Set()` blindaria o caso de um integrador enviar `codigoEmbarque` no POST. Pendente de decisão.
- Documentação sincronizada: `erp-services.md` (seção EmbarqueService).

**Changelog 2026-07-31 sessão 10 (thl-architect + thl-coding — parse × orquestração nos Services ERP):**
- 📋 **Parecer arquitetural:** avaliada a separação de parse JSON × processamento BO/API. **Veredicto: não separar em classes** — o `JsonSetter` implementa partial-update (`if payload:Has(x) then ... else mantém valor atual`), que um DTO intermediário destruiria; o contrato `IErpService:execute(..., context as JsonObject, ...)` já cristalizou `JsonObject`; e todas as entradas hoje são JSON (inclusive o fluxo agendado). Diagnóstico: **3 dos 5 Services já separavam** (`FretePrevistoService` via properties, `DocumentoService` e `EmbarqueService` via hooks `prepare*`) — faltava padronizar, não fragmentar.
- ✅ **`UsuarioService` decomposto:** `create()` (240 linhas) reduzido à orquestração das 5 BOFs. Mapeamento extraído para 5 hooks protected: `mapUserMaster` (49 SetValue), `mapUserExtension` (16 SetValue, retorna `logical` para createRecord×updateRecord), `mapUserGroup`, `mapUserCompany`, `mapUserUniverse`. Todos recebem o `jsonSetter` **já posicionado**. Temp-tables e buffer promovidos a `protected`.
- ⚠️ **Sequência da `bofn017` preservada:** `createRecord` → `gotokey`/`getRecord` → reaplica `dataValidadeSenha` → `updateRecord`. É exigência da BOF (o create sobrescreve o campo), agora documentada em comentário no código.
- ✅ **`LpcoService:loadReferenceCode` corrigido:** lia de `inContext`, obrigando o `get()` a fazer `inContext = new JsonObject()` dentro do loop — o método de listagem sobrescrevia o estado de entrada da classe. Agora lê de `b-nit-lpco`. Comportamento externo idêntico.
- ℹ️ Nomes `mapUserGroup`/`mapUserCompany` ficaram no singular (operam por item dentro do loop), divergindo do plural sugerido no parecer.
- Contagem de classes inalterada (82). Documentação sincronizada: `erp-services.md`, INDEX.md.

**Changelog 2026-07-31 sessão 9 (mapa de riscos + correções aprovadas):**
- ✅ **Mapa de riscos**: 17 riscos identificados, avaliados pelo usuário. 7 aceitos/explicados, 5 corrigidos, 5 pendentes.
- ✅ **Sequencial de embarque com retry** (#5): `EmbarqueService:create` agora faz retry 3x com `pause 1` quando `find last embarque` está locked, em vez de falhar imediato. Constante `MAX_SEQ_RETRIES = 3`.
- ✅ **`error-status` resetado** (#9): `EmailService:executeDatasulMailService` agora reseta `error-status:error = false` antes da execução.
- ✅ **Referência externa de NF** (#16): `NotaFiscalMessage` agora sobrescreve `loadExternalReference` retornando `estabelecimento#serie#numero` (campos `codigoEstabelecimento`, `serie`, `numeroDocumento` do payload). Item 2.6 do backlog resolvido.
- ✅ **`loogai.md` sincronizada** (#7): seção `LoogAiEmbarqueService` corrigida — `resolveIntegrationUser` retorna `'loogai'` fixo, dependência `EnvironmentResource` removida.
- ✅ **Risco ChamadoMessage** (#8): `block-level` já estava ativo no código real (L16) — risco na doc era falso. Tabela de riscos corrigida.
- ℹ️ **Decisões registradas**: tipoFrete 999 é tipo de despesa válido; item 19077 é serviço de frete Loog.ai; data.data.token é contrato correto MMCM; char-1/char-2 são campos coringas TOTVS; pause SEFAZ mantido por design (processo encadeado).

**Changelog 2026-07-27 sessão 6 (thl-coding — decomposição OO LoogAiDocumentoService):**
- ✅ **`LoogAiDocumentoService.cls` refatorado**: método monolítico `prepareDocumentData` (~235 linhas) decomposto em 8 métodos protected: `resolveEntities`, `parseNfCliente`, `buildDocumentHeader`, `resolveEntrada`, `resolveSaida`, `resolveNaturezaOperacao`, `buildItemEntrada`, `buildItemSaida`, `buildDuplicataAPagar`.
- ✅ **Properties protected adicionadas**: `incidePis`, `incideConfis`, `incideIcms`, `estadoDest`, `numeroNfeCliente`, `serieNfeCliente` — substituem variáveis locais compartilhadas por efeito colateral.
- ✅ **Constantes nomeadas para `char-2`**: `CHAR2_TIPO_NF_ENTRADA`(143), `CHAR2_ORIGEM_LOOGAI`(151), `CHAR2_ESTADO_ORIGEM`(211), `CHAR2_IBGE_MUNICIPIO_ORIGEM`(246), `CHAR2_IBGE_MUNICIPIO_DESTINO`(236).
- Hardcode `'19077'` mantido por decisão do usuário. Contagem de classes inalterada (82). Documentação sincronizada: `loogai.md`, INDEX.md.

**Changelog 2026-07-26 sessão 5 (thl-coding — inbound async/schedule via RPW):**
- ✅ **`InboundSchedulingService.cls` criado** (`messaging.inbound.service`): agenda mensagem inbound via `thl1989z.p`, retorna `{ messageCode, pedidoExecucao, status: 'agendado' }`. Não salva resposta — `dt-integracao` permanece `?` para o runner.
- ✅ **`InboundMessageService.cls` refatorado**: `receive()` reestruturado em `accept` (etapas 1-2, sempre síncrono) + branch por `ExecutionMode` (`ONLINE` → `processOnline`, `SCHEDULE` → `scheduleProcessing`). Novo `processScheduled(messageCode)` como ponto de entrada RPW.
- ✅ **`InboundMessage.cls`**: adicionado `restoreForScheduledProcessing(messageCode)` — restaura estado da mensagem persistida para processamento via runner RPW.
- ✅ **`thl1989z.p` modificado**: branch por `thl-mensagem.sentido-fluxo` para 5 campos (`tt-param.arquivo`, `ped_exec.cod_prog_dtsul`, `ped_exec.nom_prog_ext`, `ped_exec_param.cod_dwb_file`, `ped_exec_param.nom_dwb_printer`).
- ✅ **`thl1991rp.p` criado**: runner RPW inbound — itera `thl-mensagem` pendentes (`dt-integracao = ?`, `not sentido-fluxo`) e chama `InboundMessageService:processScheduled`.
- ✅ **`thl1991.w` criado**: monitor/agendamento inbound (w-relat), baseado em `thl1989.w` com filtro `not thl-objeto.sentido-fluxo` e referência a `thl1991rp.p`.
- Contagem de classes: 82 (+1 `InboundSchedulingService`). Documentação sincronizada: `messaging-inbound.md`, INDEX.md.

**Changelog 2026-07-26 sessão 4b (thl-coding — refatoração de paginação + enums de situação):**
- ✅ **Paginação removida de InboundMessage:** propriedades `pageSize`, `pageOffset`, `skipCount`, `entryCount` e métodos `loadPageParams`, `getQueryParamInt` removidos.
- ✅ **`getQueryParamInt` movido para `InboundObjectContext`:** leitura de query params é responsabilidade do DTO de contexto (`context:getQueryParamInt('paramName', default)`).
- ✅ **`LpcoMessage:methodGet` atualizado:** cria `PaginationHelper` diretamente com `context:getQueryParamInt(...)` — composição pura, sem estado na base.
- ✅ **`dispatchInbound` simplificado:** chamada de `loadPageParams` removida do case GET.
- ✅ **`SituacaoFreteEnum` criado** (`erp.enum`): ATIVO=1, CANCELADO=2. Substitui static properties de `FretePrevistoService` (inclusive hardcode `= 1` em `localizarFretePrevistoAtivo`).
- ✅ **`SituacaoEmbarqueEnum` criado** (`erp.enum`): ATIVA=1. Substitui static property `SITUACAO_ATIVA` de `EmbarqueService`.
- ✅ **`SituacaoNfeEnum` criado** (`erp.enum`): AUTORIZADA=3, DENEGADA=4, REJEITADA=5, CANCELADA=6, INUTILIZADA=7. Substitui magic number `= 3` em 8 pontos nos 3 arquivos NF (NotaFiscalBaseService, NotaFiscalService, NotaFiscalPorEmbarqueService).
- ✅ **Orphan usings removidos (5):** `JsonSetter` em InboundMessage, `Message` em LpcoMessage e UsuarioMessage, `LogUtil` em LpcoService, buffer morto `b-nota-fiscal` em FretePrevistoService.
- Contagem de classes: 81 (+3 enums). Documentação sincronizada: `messaging-inbound.md`, `erp-services.md`, INDEX.md.

**Changelog 2026-07-26 sessão 4 (thl-coding — migração completa IErpService + ActionEnum + overrides explícitos):**
- ✅ **ICrudService → IErpService (rename):** interface renomeada em 26 arquivos (código + testes + documentação).
- ✅ **ActionEnum criado** (`thl-lib.erp.enum.ActionEnum`): CRIADO=1, ATUALIZADO=2, DELETADO=3. Parâmetro `action` mudou de `character` para `ActionEnum` em `IErpService:execute()`, `InboundMessage:executeAndRegister()` e todos os 7 Services.
- ✅ **InboundMessage redesenhado:** `context` armazenado como property; `executeAndRegister(ActionEnum)` centraliza Service→payload→rastreabilidade; `methodPost/Patch/Delete` lançam erro por default — **subclasses sobrescrevem explicitamente** cada verbo com `executeAndRegister(ActionEnum:XXX)`.
- ✅ **Todas as 7 Messages com overrides explícitos:** cada Message declara quais verbos suporta. Padrão: `methodPost → executeAndRegister(ActionEnum:CRIADO)` etc.
- ✅ **UsuarioService migrado para execute() dispatcher** — problema de compilação encerrado.
- ✅ **NotaFiscalService e NotaFiscalPorEmbarqueService migrados para execute() dispatcher** (IErpService). `case operation` dentro dos Services. `NotaFiscalMessage` simplificada a `createService()` por `context:routePath`.
- ✅ **FreteMessage:** `createService()` usa `context:operation` para selecionar modalidade.
- ⚠️ **Riscos preservados (sem alteração):** `EmbarqueService` mutação de `inContext`; `DocumentoService` silent no-op (sem `otherwise`). Itens `[DECIDIR]` do backlog mantidos.
- Contagem de classes: 78 (+1 `ActionEnum`). Documentação sincronizada: `erp-services.md`, `messaging-inbound.md`, `backlog-inbound-erp.md`, `loogai.md`, INDEX.md.

**Changelog 2026-07-25 sessão 2g (thl-coding — Fase 5 do backlog executada):**
- **Procedures de regressão gerados (5.1):** 6 arquivos em `Utils/test/`: `testRegressaoLpco.p` (CRUD completo + idempotência, 5 testes), `testRegressaoFretePrevisto.p` (POST/PUT/DELETE + duplicidade, 4 testes), `testRegressaoEmbarque.p` (POST/DELETE, 2 testes), `testRegressaoUsuario.p` (POST + duplicidade, 2 testes), `testRegressaoDocumento.p` (POST, 1 teste), `testRegressaoNotaFiscal.p` (NF direta geracao + processamento + NF por embarque geracao, 3 testes).
- **Fluxo thl-mensagem validado (5.2):** `testRegressaoMensagem.p` (5 testes: criação de thl-mensagem, payload gravado, thl-mensagem-item com referenceCode/ExternalReferenceCode, histórico de status, reprocessamento/idempotência).
- **Documentação sincronizada (5.3):** INDEX.md e backlog atualizados. Fases 0–5 completas. Itens `[DECIDIR]` preservados sem alteração.
- Total de procedures de teste: 7 novos (regressão) + 14 pré-existentes = 21 em `Utils/test/`.

**Changelog 2026-07-25 sessão 2f (thl-coding — Fase 4 do backlog executada):**
- **Código morto removido (4.1):** `EmbarqueService:loadReferenceCode` (retornava `''`, nunca chamado), bloco comentado `updateShipmentApproval` + chamada comentada. Buffers/usings órfãos já limpos em Fases 2–3; `AuditLogService`/`LogUtil` em FretePrevisto mantidos (item 0.4 `[DECIDIR]`).
- **Cabeçalhos corrigidos (4.2):** `BusinessObject` (era "BoService"), `ApplicationProgrammingInterface` (era "ApiService"), `FretePrevistoService` (era "FreteService"). Notes de `UsuarioService`/`DocumentoService` atualizadas.
- **`mapFields` extraído em LpcoService (4.3):** 15 `SetValue` duplicados entre create/update agora em método privado único.
- **Casing padronizado (4.4):** `loadReferenceCode` (camelCase) em 7 Services + base abstrata; `this-object:` adicionado em todas as chamadas.
- **Convenção `this-object:` (4.7):** definida e aplicada em 6 Services (~20 pontos corrigidos).
- **Constantes nomeadas (4.11):** `EmbarqueService` (4 constantes: `OPER_INCLUSAO/ELIMINACAO_EMBARQ/ELIMINACAO_PED`, `SITUACAO_ATIVA`), `FretePrevistoService` (2: `SITUACAO_ATIVO/CANCELADO`).
- **Documentação (4.8/4.12):** tabela de convenção de handles e classificação de parâmetros registradas em `erp-services.md`.
- Itens `[DECIDIR]` preservados: 4.9 (referenceCode no GET LPCO), 4.10 (universo 1ª empresa). Contagem de classes inalterada (77).

**Changelog 2026-07-25 sessão 2e (thl-coding — Fase 3 do backlog executada):**
- **`NotaFiscalBaseService.cls` (novo)** — base abstrata do par NF em `thl-lib.erp.service`: 6 temp-tables, buffer `b-nota-fiscal`, estado `inPayload`/`outPayload` (invariante `initializeExecution` documentada), `exportNfeXml`, `runSefazAuthorization` (retry unificado), `printInvoiceDocument`, `addInvoicePayload` com hooks de chave (`mensagem`/`valido` default; por embarque preserva `sefaz`/`arquivoValido` — item 3.3 pendente), helpers de env SEFAZ (defaults unificados 3/5).
- **`NotaFiscalService` e `NotaFiscalPorEmbarqueService` reescritos** sobre a base. ⚠️ **Evoluído em sessão 4:** métodos individuais (P3) substituídos por dispatcher `execute(action, operation, context, output referenceCode)` (IErpService). `NotaFiscalMessage` simplificada a `createService()` por `routePath`.
- ⚠️ Mudanças de comportamento intencionais: retry SEFAZ por embarque passa de fallback 1×/0s para 3×/5s sem env vars; mensagens de erro trocam nomes de método antigos pelos novos no texto `[Classe.metodo]`.
- Contagem de classes: 77 (+1 `NotaFiscalBaseService`). **Fase de maior risco — compilação e regressão (5.1) obrigatórias antes de qualquer deploy.**

**Changelog 2026-07-25 sessão 2d (thl-coding — Fase 2 do backlog executada):**
- **`IErpService.cls` (novo)** — `thl-lib.erp.core.IErpService`: contrato inicial `create/update/delete` individual. ⚠️ **Substituído em sessão 3/4:** redesenhado para dispatcher `execute(action, operation, context, output referenceCode): JsonObject` e renomeado de ICrudService para IErpService.
- **`InboundMessage` ganhou o miolo do Template Method:** `createService(): IErpService`, defaults de `methodPost/Patch/Delete`, e `loadExternalReference` (default por `getExternalReferenceField()`). ⚠️ **Evoluído em sessão 4:** `registerResult` → `executeAndRegister`; `createService`/`getRequiredFields` agora abstract; `routePath`/`routeOperation` properties adicionadas.
- **Messages migradas:** `LpcoMessage` (piloto — só GET custom), `UsuarioMessage`/`DocumentoMessage`/`EmbarqueMessage` (pura configuração, sem verbos), `FreteMessage` (verbos antepõem `validateModality` e delegam a `super:methodX`; `createService(operation)` morto removido), `NotaFiscalMessage` (excepcional — mantém `case routePath`, agora com `registerResult` + 2 Factory Methods; cabeçalho corrigido). `LoogAiDocumentoMessage` (thl-extensions) atualizada para retorno `IErpService`.
- Contagem de classes: 76 (+1 `IErpService`; `thl-lib.erp.core` = 4). Compilação/regressão (5.1) pendente — sem OpenEdge neste ambiente.

**Changelog 2026-07-25 sessão 2c (thl-coding — Fase 1 do backlog executada):**
- **`ServiceResponse.cls` (novo)** — `thl-lib.erp.core.ServiceResponse`: métodos estáticos `success(entidade, acao)` / `success(entidade, acao, referenceCode)` (opt-in) / `failure(code, message)`. Ponto único do shape `{success, code, message}` dos Services ERP.
- Os 5 `buildSuccessPayload` removidos (Lpco, FretePrevisto, Usuario, Embarque, Documento) — 9 pontos de retorno migrados para `ServiceResponse:success(...)`. Grep confirma zero referências remanescentes em `Fontes\`.
- `FretePrevistoService`: usos órfãos de `outPayload` (property removida manualmente pelo usuário) concluídos — métodos retornam `ServiceResponse` direto; demais ajustes manuais do usuário preservados.
- Item 1.3 verificado sem mudança: `Message:setSuccessPayload` já produz o mesmo shape; `messaging` segue sem depender de `erp.core`.
- Risco transversal "buildSuccessPayload duplicado ×5" **encerrado**. Contagem de classes: 75 (+1 `ServiceResponse`; `thl-lib.erp.core` = 3).

**Changelog 2026-07-25 sessão 2b (thl-coding — Fase 0 do backlog executada):**
- 7 correções aplicadas em `Fontes\` (detalhe em [`refactoring/backlog-inbound-erp.md`](refactoring/backlog-inbound-erp.md), Fase 0 ☑): `getEnvironmentIntegerCapped` (NotaFiscalService), construtor de `BusinessObject` inicializa `error`, textos de `buildSuccessPayload` (Lpco/Documento/Embarque), `des-observacao`+transação (FretePrevistoService), `resolveIntegrationUser` substitui `'loogai'` (EmbarqueService), transações em `LpcoService:update/delete`, default de `opcao` em `NotaFiscalPorEmbarqueService:printInvoice`.
- ⚠️ Pré-requisitos de deploy: provisionar env var `usuario.integracao` (PRD/TST/HOM); avisar consumidores sobre mudança dos textos de `message`; validar retry SEFAZ em TST (passa a executar de fato). Compilação/regressão (item 5.1) pendente.

**Total de classes documentadas:** 76 (69 anteriores + UsuarioService, LpcoService, DocumentoService, LoogAiDocumentoService — separação Message/Service; +1 PaginationHelper — P1; + 1 classe C# `Thl.Interop.DocxToPdfConverter` fora da contagem ABL)  
**Arquivos não legíveis:** nenhum  
**Sessão:** análise estática read-only de `Fontes\thl-lib\` e `Fontes\thl-extensions\`

**Changelog 2026-07-25 sessão 2 (thl-architect — análise de repetição inbound/erp + sincronização):**
- 🔄 **Novo subpacote `thl-lib.erp.core`:** bases renomeadas/movidas — `BusinessObjectService` → `BusinessObject` e `ApplicationProgramInterfaceService` → `ApplicationProgrammingInterface` (agora com "Programming" completo), caminho `Fontes\thl-lib\erp\core\`. `erp-services.md` atualizado.
- 🔄 **`FreteService` → `FretePrevistoService`** (arquivo e classe renomeados; cabeçalho interno ainda diz "FreteService").
- ✅ **P0 concluído:** as 6 Messages inbound (`NotaFiscal`, `Frete`, `Embarque`, `Documento`, `Usuario`, `Lpco`) migradas para o padrão `loadExternalReference` + `appendItem()` — nenhuma usa mais `onLoadData`/`appendMessageItemBy*`; todas compilam com o novo contrato.
- ✅ **Lacuna de rastreabilidade THL de NF fechada:** `NotaFiscalMessage:methodPost` agora chama `appendItem()` com `referenceCode` do Service — risco transversal encerrado.
- ✅ **P3 aplicado aos Services:** `UsuarioService:create` e `DocumentoService:create` substituíram os antigos `execute(operation, payload)`; `EmbarqueService` expõe `create`/`delete`. Dispatcher `execute` sobrevive só no par NotaFiscal (legado).
- 🔴 **Regressão:** hardcode `'loogai'` voltou em `EmbarqueService:create` (`tt-embarque.usuario`/`identific`; leitura de `codigoUsuario` comentada) — a correção de 2026-07-17 foi desfeita.
- 🔴 **Bugs novos detectados na análise** (registrados na tabela de riscos): `getEnvironmentIntegerCapped` retorna sempre 0 (mata retry SEFAZ em `NotaFiscalService`); `error` usado sem inicialização em `NotaFiscalPorEmbarqueService:execute`; `buildSuccessPayload` duplicado ×5 com texto errado "Frete previsto" em Lpco/Embarque/Documento; `des-observacao = numeroNota` em `FretePrevistoService:create`.
- Parecer de refatoração emitido (ServiceResponse + registerResult + IErpService + NotaFiscalBaseService) — nenhuma alteração de código aplicada. **Backlog completo (sem exceção de complexidade) registrado em [`refactoring/backlog-inbound-erp.md`](refactoring/backlog-inbound-erp.md)**: 5 fases, 35 itens rastreáveis com dependências e decisões pendentes.
- Documentação atualizada: `erp/erp-services.md` (reescrito), `integration/messaging-inbound.md` (seções das 6 Messages + InboundMessage + stubs MOVIDO), este INDEX.

**Changelog 2026-07-25 (thl-architect + thl-coding — parecer canônico LPCO + aplicação P1/P2/P3):**
- 🔴 **Divergência crítica (self-healing):** `Message.cls` no working copy removeu `onLoadData(recid)` abstract, `appendMessageItemByReference(recid)` e `appendMessageItemByExternalReference(character)`. Estes métodos permanecem em `OutboundMessage.cls` (lado outbound). Novo padrão inbound: subclasse seta `referenceCode` + `ExternalReferenceCode` + chama `appendItem()`.
- 🔴 **Divergência crítica (self-healing):** `InboundMessage.cls` no working copy removeu `RowErrors` temp-table, `addRowErrorsToErrorHandler`, `throwRowErrorsIfAny`, `appendPayloadObject`, `incrementPageCount`, `shouldSkipEntry`, `shouldStopPaging`. Adicionou `loadExternalReference(JsonObject)` abstract — novo hook para referência externa (substitui `onLoadData` para inbound).
- **P1 — `PaginationHelper.cls` (novo):** `thl-lib.util.pagination.PaginationHelper` — helper de paginação offset-based, imutável (parâmetros no construtor). Extraído de `LpcoService` (SRP). Service recebe o helper como parâmetro de `get()`, não possui estado de paginação.
- **P2 — Factory Method em `LpcoMessage`:** `createService(): LpcoService` — permite subclasses injetarem Service alternativo (mesmo padrão de `DocumentoMessage:createService()`). Todos os `new LpcoService()` substituídos por `this-object:createService()`.
- **P3 — Padrão canônico de assinatura:** métodos individuais (`create`/`update`/`delete`/`get`) no Service, sem dispatcher `execute(operation, payload)`. A Message é o dispatcher (via `methodPost`/`methodPatch`/`methodDelete`/`methodGet`).
- Documentação atualizada: `integration/messaging-core.md`, `integration/messaging-inbound.md`, `erp/erp-services.md`, `util/util.md` (PaginationHelper adicionado).
- ⚠️ **Refatoração incompleta (P0 pendente):** `NotaFiscalMessage`, `FreteMessage`, `EmbarqueMessage`, `DocumentoMessage`, `UsuarioMessage` ainda usam padrão antigo (`onLoadData`/`appendMessageItemByReference`) e não implementam `loadExternalReference` abstract — não compilam até serem migradas.
- **Contagem de classes:** 74 (+1 `PaginationHelper`).

**Changelog 2026-07-24 sessão 6 (thl-architect — realocação de pacote: Services de domínio para erp.service):**
- Usuário questionou por que os Services de domínio inbound (novos e pré-existentes) não vivem em `thl-lib.erp.service`, já que criam registro no ERP independente de serem chamados por integração ou não — mesmo raciocínio já usado para mover `BusinessObjectService`/`ApplicationProgramInterfaceService` na sessão 3.
- Discussão resolvida: o tipo do parâmetro (`payload as JsonObject`) não é sinal de acoplamento à integração — é apenas uma estrutura de dados (`Progress.Json.ObjectModel`), sem relação com HTTP/REST; um `.p` interno pode montá-la e consumi-la em processo, sem qualquer camada de rede envolvida.
- **Movidos de `thl-lib.integration.messaging.inbound.service` para `thl-lib.erp.service`:** `UsuarioService`, `LpcoService`, `DocumentoService`, `EmbarqueService`, `FreteService`, `NotaFiscalService`, `NotaFiscalPorEmbarqueService` (7 classes — os 4 novos da sessão 5 + os 3 pré-existentes que também se qualificam pelo mesmo critério).
- **Movido de `thl-extensions.integration.loogai.messaging.inbound.service` para `thl-extensions.erp.loogai.service`:** `LoogAiDocumentoService` (acompanha o pai `DocumentoService`).
- Nenhuma Message se moveu — todas continuam em `thl-lib.integration.messaging.inbound.message` (ou `thl-extensions...message`), apenas com o `using` do Service atualizado para o novo pacote. Nenhuma lógica de negócio foi alterada — troca pura de namespace/pasta física.
- Documentação atualizada: `erp/erp-services.md` (canônico agora para os 7 Services de thl-lib — seções completas adicionadas), `integration/messaging-inbound.md` (7 seções de Service viraram stubs "— MOVIDO", tabela-resumo atualizada com links), `extensions/loogai.md` (seção `LoogAiDocumentoService` com novo caminho).
- Contagem total de classes **inalterada** (73) — realocação, não criação.

**Changelog 2026-07-24 sessão 5 (thl-architect → thl-coding — separação Message/Service em inbound sem Service):**
- Parecer arquitetural (thl-architect) identificou 4 Messages inbound sem Service correspondente: `UsuarioMessage` (SEPARAR/ALTA), `LpcoMessage` (SEPARAR/MÉDIA), `DocumentoMessage` (AVALIAR COM LOPES — já separava via herança/hook), `LoogAiDocumentoMessage` (SEPARAR/ALTA). Usuário confirmou separar todos os 4, incluindo o par Documento/LoogAiDocumento, com assinatura padronizada `execute(operation, payload)` (estilo `NotaFiscalService`).
- **`UsuarioService.cls` (novo)** — `thl-lib.integration.messaging.inbound.service`, herda `BusinessObjectService`. Extraído de `UsuarioMessage:methodPost` (5 BOFs: bofn017/027/030/168/169). `UsuarioMessage` virou thin-wrapper; `onLoadData` passou a retornar `referenceCode` (mesmo padrão de correção já aplicado em `NotaFiscalMessage` — antes lia um buffer nunca conectado a `appendMessageItemByReference`, código morto).
- **`LpcoService.cls` (novo)** — `thl-lib.integration.messaging.inbound.service`, sem herança (mesmo perfil de `FreteService`). Extraído de `LpcoMessage` POST/PATCH/DELETE. GET (listagem paginada) **permanece em `LpcoMessage`** — decisão de design: paginação é infraestrutura de `InboundMessage`, não é movida em nenhum dos pares já separados.
- **`DocumentoService.cls` (novo)** — `thl-lib.integration.messaging.inbound.service`, herda `BusinessObjectService`. Extraído de `DocumentoMessage` (hook `prepareDocumentos` + `executeBOFs`, BOFs boin090/176/092/366). `DocumentoMessage` ganhou o método `createService()` (Factory Method) como novo ponto de extensão, substituindo o antigo override direto de `prepareDocumentos` na Message.
- **`LoogAiDocumentoService.cls` (novo)** — `thl-extensions.integration.loogai.messaging.inbound.service`, herda `DocumentoService`. Extraído de `LoogAiDocumentoMessage:prepareDocumentos` (lógica fiscal PIS/COFINS/ICMS via `nit-loog-natur-oper`). `LoogAiDocumentoMessage` passou a sobrescrever `createService()` em vez de `prepareDocumentos`.
- Documentação atualizada: `integration/messaging-inbound.md` (UsuarioMessage/UsuarioService, LpcoMessage/LpcoService, DocumentoMessage/DocumentoService) e `extensions/loogai.md` (LoogAiDocumentoMessage/LoogAiDocumentoService).

**Changelog 2026-07-24 sessão 4 (thl-architect — parecer arquitetural NotaFiscal/BusinessObjectService, confronto doc × código real):**
- Sessão solicitou parecer sobre uma arquitetura (`NotaFiscalMessage`/`NotaFiscalService`/`NotaFiscalPorEmbarqueService`/`BusinessObjectService`) que **já estava implementada e decidida** nas sessões 2–3 do mesmo dia — parecer emitido em cima do código real, não de uma proposta hipotética.
- 🔴 **Divergência corrigida (self-healing):** `messaging-inbound.md` e este risco transversal diziam que `onLoadData` de `NotaFiscalMessage` era stub (`return ''`). **Falso hoje** — `onLoadData` retorna `referenceCode`, populado via `output` de `execute()` de cada Service (`LoadReferenceCode()` diferencia corretamente NF direta vs. por embarque). **Mas o efeito prático não mudou:** `methodPost` nunca chama `appendMessageItemByReference`/`appendMessageItemByExternalReference` (únicos pontos que de fato acionam `onLoadData` e persistem rastreabilidade) — `onLoadData` é código morto, a lacuna de rastreabilidade THL para NF permanece. Ver detalhe em `integration/messaging-inbound.md`.
- Confirmado por leitura direta dos `.cls`: `BusinessObjectService` em `thl-lib\erp\service\`, herdada (não composta) por `NotaFiscalService` e `NotaFiscalPorEmbarqueService`; assinatura de `execute` idêntica nas duas (`input operation, input payload, output referenceCode`) — decisões das sessões 2–3 confirmadas consistentes com o código.

**Changelog 2026-07-24 sessão 3 (thl-architect — confirmação final + decisões de design do usuário):**
- ✅ **R7 resolvido pelo usuário:** `BusinessObjectService` e `ApplicationProgramInterfaceService` confirmadas em `thl-lib.erp.service` — caminho físico (`Fontes\thl-lib\erp\service\`), namespace declarado na classe e `USING` dos 3 consumidores (`NotaFiscalPorEmbarqueService`, `NotaFiscalService`, `EmbarqueService`) agora **consistentes entre si**.
- Pacote novo `thl-lib.erp.service` documentado em [`erp/erp-services.md`](erp/erp-services.md) (canônico). `integration/totvs-api.md` e a seção antiga em `messaging-inbound.md` viraram stubs de redirecionamento.
- **Decisão de design confirmada (usuário):** `thl-lib.erp.service` é irmão de `integration`, não aninhado sob ele — as bases servem qualquer código que chame BO/API do ERP, não só integrações.
- **Decisão de design confirmada (usuário):** `BusinessObjectService` e `ApplicationProgramInterfaceService` permanecem bases irmãs sem hierarquia comum, por design — BO (`RowErrors`, com severidade) e API (`tt-erro`, sem severidade) têm contratos de erro estruturalmente diferentes no ERP; forçar uma base comum criaria um contrato artificial. Risco R6 do parecer anterior **fechado** (não é dívida técnica).
- **Esclarecido (usuário):** colisão de nome simples `NotaFiscalMessage` (inbound vs. `thl-extensions.loogai` outbound) é aceitável — pacotes diferentes, padrão já usado no projeto. Risco R5 do parecer anterior **fechado**.
- **Esclarecido (usuário):** o `pause`/loop de tentativas em `NotaFiscalService:updateSefaz`/`processSteps` é necessário — aguarda resposta assíncrona do serviço TSS na autenticação SEFAZ, não é código a "corrigir". Risco R3 permanece como **restrição de negócio conhecida**, não como bug; ver observação de risco atualizada abaixo (a questão residual é *onde* esperar, não *se* deve esperar).

**Changelog 2026-07-24 sessão 2 (thl-architect — reavaliação pós-refatoração manual do usuário):**
- Usuário renomeou/moveu manualmente `BoService`→`BusinessObjectService` e `ApiService`→`ApplicationProgramInterfaceService`.
- 🔴 Divergência crítica de 3 caminhos detectada nesta sessão — **ver sessão 3 acima para resolução.**
- ✅ Bug crítico L78 de `NotaFiscalPorEmbarqueService:execute` (throw incondicional) **foi corrigido** pelo usuário nesta mesma refatoração.

**Changelog 2026-07-24 (thl-architect — parecer NotaFiscal + sync):**
- **`NotaFiscalPorEmbarqueMessage.cls` deletado** de `Fontes\` (git D) e **substituído** por novo `NotaFiscalMessage.cls` inbound (thin-wrapper que roteia por `routePath`: `notafiscal/embarque`→NotaFiscalPorEmbarqueService, `notafiscal`→NotaFiscalService). Documentado em `messaging-inbound.md`; seção antiga removida.
- **`BoService.cls` (novo, não documentado)** adicionado ao `messaging-inbound.md` — classe abstrata base, irmã de `ApiService`, centraliza `RowErrors` + `throwRowErrorsIfAny`. Herdada por `NotaFiscalPorEmbarqueService` e `NotaFiscalService`.
- **`NotaFiscalPorEmbarqueService`**: doc atualizada — agora `inherits BoService`; assinatura de `execute` mudou para `execute(operation, payload): JsonArray` (embarque localizado internamente). ⚠️ Registrado **bug crítico L78** (`error:throwError` incondicional aborta `execute`).
- **`NotaFiscalService`**: deixou de ser "ARTEFATO INACABADO" — refatorado, `inherits BoService`, buffer `b-nota-fiscal` declarado, `execute` compatível, **em produção** via rota `notafiscal`. Seção reescrita.
- Divergência pendente (fora do escopo deste parecer, não sincronizada): outbound `thl-lib\...\NotaFiscalMessage.cls` e `EntregaPedidoMessage.cls` deletados (git D) — validar impacto em `messaging-outbound.md`/`extensions/loogai.md`.

**Changelog 2026-07-18 sessão 2:**
- Criados `FreteMessage.cls` (inbound/message) e `FreteService.cls` (inbound/service) — manutenção de frete previsto (`nit-frete-prev`): POST cria, PUT atualiza, DELETE cancela logicamente (`idi-situacao = 2`). Padrão thin-wrapper + Service (mesmo de EmbarqueMessage/EmbarqueService). Modalidade `frete/realizado` reconhecida com erro controlado (stub). Documentados em `integration/messaging-inbound.md`.
- Divergência corrigida (self-healing): `ApiService.cls` estava documentado em `thl-lib\integration\totvs\` mas o arquivo real vive em `thl-lib\integration\messaging\inbound\service\`. Corrigidos `integration/totvs-api.md` (caminho, namespace, dependências, overloads reais de `throwApiErrorsIfAny`) e a linha INHERITS de `EmbarqueService` em `messaging-inbound.md`.

**Changelog 2026-07-18:**
- Novo módulo de conversão DOCX → PDF via bridge CLR: projeto C# `Thl.Interop` (`Fontes\thl-lib\Interop\`, Aspose.Words, sem Word/COM — restrições do msagent: 1 CLR por processo, AppDomain único, estáticos globais ao agente) + `DocumentConversionService.cls` em `thl-lib.util.file`. Documentado em `util/document-conversion.md`; linha adicionada em `util/util.md`. Licença Aspose em estado PoC (marca d'água "Evaluation Only").
- Divergência: `Utils\test\testWordToPdf.p` referencia `thl-lib.util.file.WordToPdfConverter` (rota antiga via `doc2pdf.exe`) que não existe mais em `Fontes\` — teste legado obsoleto, substituído por `Utils\test\testDocxToPdf.p`.

**Changelog 2026-07-17 sessão 2:**
- Criado `ApiService.cls` — nova classe abstrata base em `thl-lib/integration/totvs/`. Centraliza `tt-erro` e `throwApiErrorsIfAny` para Services que chamam APIs TOTVS internas. Documentado em `integration/totvs-api.md`.
- `EmbarqueService.cls` refatorado para `inherits ApiService` — remove duplicata de `tt-erro` e `throwApiErrorsIfAny`; corrige bug de descarte de `cd-erro`. Documentação atualizada em `messaging-inbound.md`.
- (Anterior) `messaging-inbound.md` — divergência de comportamento de `throwApiErrorsIfAny` documentada.

**Changelog 2026-07-17:**
- Detectado `NotaFiscalService.cls` não documentado — artefato inacabado com erros de compilação. Adicionado ao `messaging-inbound.md` com marcação de risco.
- Criado `EmbarqueService.cls` (novo) por extração de `EmbarqueMessage` (SRP). Documentado em `messaging-inbound.md`.
- `EmbarqueMessage.cls` refatorado para thin-wrapper. Documentação atualizada.

---


## Observações preservadas do índice anterior

O quadro a seguir é um snapshot histórico; reconfirme os itens no código antes de agir.

## Riscos e observações transversais

| Risco | Localização |
|---|---|
| ~~`usuario='loogai'` hardcoded~~ — **RESOLVIDO**: `EmbarqueService` base exige `codigoUsuario` no payload (genérico); `LoogAiEmbarqueService` retorna `'loogai'` fixo (decisão intencional — identifica embarques Loog.ai). Sem env var necessária | `EmbarqueService` / `LoogAiEmbarqueService` |
| ~~`getEnvironmentIntegerCapped` retorna sempre 0~~ — **CORRIGIDO** (Fase 0.1): `maxValue` como default + teto `min()`; agora `protected`. ⚠️ Comportamento SEFAZ muda em runtime (retry passa a executar) — validar em TST | `NotaFiscalService` |
| ~~`error` não instanciada em `execute`~~ — **CORRIGIDO** (Fase 0.2): construtor de `BusinessObject` inicializa `error` | `NotaFiscalPorEmbarqueService:execute` |
| ~~`buildSuccessPayload` duplicado ×5~~ — **ENCERRADO** (Fase 1.1, 2026-07-25): centralizado em `erp.core.ServiceResponse`; métodos locais removidos | `LpcoService`, `EmbarqueService`, `DocumentoService`, `FretePrevistoService`, `UsuarioService` |
| ⚠️ `des-observacao = numeroNota` em `create()` — **REABERTO** (o código de 2026-09-24 ainda grava `numeroNota`; `USING` de `AuditLogService`/`LogUtil` sem uso) | `FretePrevistoService:create` (`thl-extensions\erp\dvv`) |
| ⚠️ Contrato de resposta divergente entre os pares NF (`mensagem`/`valido` vs `sefaz`/`arquivoValido`) — desde a Fase 3.1 isolado nos hooks `getStatusMessageKey`/`getValidFileKey` de `NotaFiscalBaseService`; unificar = apagar 2 overrides, após alinhamento com o integrador (item 3.3) | `NotaFiscalPorEmbarqueService` (overrides) |
| ~~`block-level` comentado~~ — **FALSO**: código real tem `block-level on error undo, throw` ativo (L16). Risco inexistente | `ChamadoMessage` (ninahub) |
| ~~`error-status:error` não resetado~~ — **CORRIGIDO** (sessão 9, 2026-07-31): `error-status:error = false` adicionado no início de `executeDatasulMailService` | `EmailService` |
| Envelope duplo `data.data.token` frágil | `TokenProvider` (mmcm) |
| Apenas último item serializado por pré-fatura | `PrePedidoMessage` (mmcm) — possível bug |
| Código de item `'19077'` hardcoded | `LoogAiDocumentoMessage` |
| Layout de campo livre (`char-1`, `char-2`) acoplado a posições fixas | `EntregaPedidoMessage`, `LoogAiDocumentoMessage`, `LpcoMessage` (automatizador) |
| Verificação de duplicata em `AuditLogService` por `now` — falha em operações simultâneas | `AuditLogService` |
| ~~`error:throwError('methodPost', operation)` incondicional (L78) abortava `execute` sempre~~ — corrigido em 2026-07-24 | `NotaFiscalPorEmbarqueService` |
| ~~Lacuna de rastreabilidade THL para NF~~ — **ENCERRADO** (2026-07-25 sessão 2 + sessão 9): `NotaFiscalMessage:methodPost` chama `appendItem()` com `referenceCode`. Referência externa implementada (sessão 9): `loadExternalReference` retorna `estabelecimento#serie#numero` | `NotaFiscalMessage` (inbound) |
| `pause`/loop de tentativas em `updateSefaz`/`processSteps`, dentro de `do transaction` — **necessário por design** (aguarda autenticação SEFAZ via serviço TSS, assíncrono). Risco residual não é "deveria esperar", é *onde*: hoje a espera segura o agente PASOE e a transação pelo tempo todo; se o TSS demorar, prende um agente do pool. Alternativa a avaliar no futuro: mover para fluxo assíncrono/reprocessamento (padrão já existente no reenvio outbound do `thl1986`) em vez de espera síncrona bloqueante | `NotaFiscalService` |
