---
tipo: guia
camada: ambos
status: vigente
tags: [indice, kb]
updated: 2026-10-21
---

# THL-Library — Índice de documentação compartilhada

**Última sincronização:** 13/10/2026, por inventário e leitura estática. Nenhuma compilação ou validação de implantação nesta revisão.

**Atualização 19/10/2026 (skill thl-docs):** instalada a skill `thl-docs` (fechamento documental) em [.claude/skills/thl-docs/SKILL.md](../../.claude/skills/thl-docs/SKILL.md) e registrada na tabela de tarefas do `AGENTS.md`; criado o [notion-map.md](notion-map.md) vazio, com candidatas a publicação. Verificado por leitura e comparação de frontmatter, sem execução.

**Atualização 21/10/2026 (medição de contrato):** `MedicaoContratoService` (`thl-lib/erp/service`, API `cnapi040`) e `AutomatizadorMedicaoContratoService` (`thl-extensions/erp/automatizador/service`, regras das UPCs cn0302a, tabelas do RPA/lotação e arquivos base64); `FileUtil:saveBase64AsFile` e `sanitizeFileName`, `JsonUtil:getText` e as classes `Base64File` e `Base64Files` (arquivos base64 com rollback). Notas: [erp-services](erp/erp-services.md), [automatizador](extensions/automatizador.md), [util](util/util.md). Não compilado; falta cadastrar objeto/operação/rota `medicao-contrato/automatizador` e a variável `medicao.pasta.arquivos` no thl0002.

**Atualização 21/10/2026 (limpeza do INDEX e links):** as 44 entradas de changelog anteriores a 19/10 foram movidas, sem alteração, para o [CHANGELOG](CHANGELOG.md); os dois links quebrados de [integration/messaging-inbound.md](integration/messaging-inbound.md) foram retirados (as classes `ObjetoMessage` e `NotaFiscalMessage` inbound não existem mais) e a pasta `Documentos/obsidian/` foi apagada, pois as notas estão em [thl/cadastros/](thl/cadastros/cadastros-thl.md). Verificado por leitura e checagem de links.

**Atualização 21/10/2026 (funcionalidades em nível de negócio):** seis guias novos em `Documentos/negocio/` — [funcionalidades-thl.md](../negocio/funcionalidades-thl.md) (índice) e um por funcionalidade: Utils (com exemplos de chamada, incluindo `scanner` e `compile`), Integração (com o `PaginationHelper`, restrito à entrada), E-mail, Variável de ambiente e Auditoria, com a explicação dos cadastros de cada uma. Escritos a partir das notas e do código por leitura; exemplos não compilados. Publicados no Notion (espaço Informações THL, página "THL-Library — Funcionalidades" com 5 subpáginas); mapa em [notion-map.md](notion-map.md).

**Atualização 21/10/2026 (atualizar tudo):** a skill [thl-docs](../../.claude/skills/thl-docs/SKILL.md) ganhou o comando **"atualizar tudo"** (todas as frentes de uma vez); criadas as entradas Codex de `thl-adr`, `thl-tech-debt` e `thl-git` em `.agents/skills/`; nova seção 5.1 em [thl/camada-datasul.md](thl/camada-datasul.md) sobre o módulo TOTVS Helper Library no menu Foundation; o [notion-map.md](notion-map.md) deixou de listar as 4 páginas de checklist de teste como publicação. Verificado por leitura, sem execução.

**Atualização 19/10/2026 (skill thl-docs, Postman):** o passo 7 da skill [thl-docs](../../.claude/skills/thl-docs/SKILL.md) virou um procedimento executável pelo conector do Postman (subpasta junto, examples por cenário, segredos fora do repositório, apagar só com confirmação), e o caminho da collection foi corrigido para `THL-Library > THL`. Verificado por leitura; o fluxo não foi executado contra o Postman.

**Atualização 19/10/2026 (dicionário de cadastros):** as seis notas de `Documentos/obsidian/THL/` (grupo thl003, conexão REST) foram movidas para [thl/cadastros/](thl/cadastros/cadastros-thl.md), com nomes em kebab-case, wikilinks trocados por links relativos e frontmatter padrão; a pasta `obsidian/` deixa de ser destino de notas. Verificado por leitura e checagem de links, sem execução.

**Decisão 19/10/2026 (métricas de e-mail):** cartão conta `programa + paramAmbiente` e a listagem conta só `programa` — divergência por desenho (250 × 268 no caso `tkn4001e`), mantida a pedido; ver [web/app-web.md](web/app-web.md).

**Atualização 19/10/2026 (monitor de e-mail):** `STATUS_EMAIL_LABELS` passa a incluir `Pendente` e o monitor ganhou o chip — o e-mail pendente aparecia sem status e fora de todos os chips. Ver [web/poui-licoes.md](web/poui-licoes.md).

**Atualização 19/10/2026 (pacotes web):** `META-INF` e `WEB-INF` saíram dos dois pacotes a pedido — `dist	hl-html-consulta` e `dist	hl-html-cadastro` passam a conter só as subpastas `html.*`. Sem `WEB-INF/web.xml` o Tomcat perde o recurso vigiado que recarregaria o contexto na publicação. Ver [web/app-web.md](web/app-web.md).

**Atualização 19/10/2026 (métricas gerais):** o cartão Mensageria da tela raiz deixa de contar o tráfego interno do THL (`interna = true`) por padrão — era gerado pelo próprio monitor e fazia a tela geral divergir da de mensageria (124 × 4 no mesmo período) — e a tela ganhou o mesmo botão de tráfego interno da de mensageria, com estado em `?internas=1` — ver [web/app-web.md](web/app-web.md). Verificado com `ng build web` e executando a linha do serviço sobre dados no formato do retorno real.

**Atualização 19/10/2026 (deploy web):** `build-deploy.ps1` e `build-deploy-cadastro.ps1` publicam em duas fases (copia para `<pasta>.novo`, confere `index.html` e contagem de arquivos, troca por rename com desfazimento) em vez de apagar as subpastas antes de copiar, e passam a gerar `WEB-INF\web.xml` nos dois pacotes — regravado a cada publicação para recarregar o contexto no Tomcat. Ver [web/app-web.md](web/app-web.md). Verificado: publicação limpa OK, publicação com arquivo travado abortou sem alterar o publicado, e o `web.xml` gerado é XML válido (467 bytes, UTF-8 sem BOM).

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
| [../negocio/funcionalidades-thl.md](../negocio/funcionalidades-thl.md) | **Funcionalidades em nível de negócio** (guias para pessoas): Utils, Integração, E-mail, Variável de ambiente e Auditoria, cada uma com seus cadastros. Utils traz exemplos de chamada |
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

Contagem em 13/10/2026: **152 classes = 98 em `thl-lib` + 54 em `thl-extensions`** (arquivos `.cls.old` não contam). Inclui interfaces e enums em arquivos `.cls`; exclui worktrees e gerados.

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
