# Extensão: thl (API REST dos cadastros do próprio THL)

O THL tratado como sistema externo `thl` (aplicação `THL`): GET/POST/PATCH/DELETE dos cadastros para telas PO UI e automação. Decisões em [adr/api-rest-cadastros-thl.md](../adr/api-rest-cadastros-thl.md); modelo seguido: [automatizador.md](automatizador.md) (`LpcoMessage`/`LpcoService`). Piloto criado em 2026-09-25 — **não compilado** (compilar no PDSOE ou com `Utils\scripts\compilar-thl.p`).

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| AmbienteService | CRUD de `thl-ambiente` (thl0001); `ip` único; não elimina ambiente com variáveis | Service (Template Method via `Service`) | Service, JsonSetter, PaginationHelper, ThlError | AmbienteMessage |
| ParametroAmbienteService | CRUD de `thl-ambiente-param` (thl0002); não elimina parâmetro com variáveis/programas | Service | idem | ParametroAmbienteMessage |
| ParametroVariavelService | CRUD de `thl-ambiente-param-variavel` (thl0002b); pai/ambiente inexistente → 2; valor sensível mascarado | Service | idem | ParametroAmbienteMessage (rota `parametro-variavel`) |
| ParametroProgramaService | Inclui/elimina/lista `thl-ambiente-param-prog` (thl0002c); sem `update()` | Service | Service, PaginationHelper, ThlError | ParametroAmbienteMessage (rota `parametro-programa`) |
| AplicacaoService | CRUD de `thl-aplicacao` (thl0020); não elimina aplicação com objetos (`thl-objeto`) | Service | Service, JsonSetter, PaginationHelper, ThlError | AplicacaoMessage |
| AplicacaoMessage | Contrato inbound de `/resourcen/aplicacao` | Template Method + Factory Method | InboundMessage, AplicacaoService | InboundMessageService (via `thl-objeto.classe-objeto`) |
| AmbienteMessage | Contrato inbound de `/resourcen/ambiente` | Template Method + Factory Method | InboundMessage, AmbienteService | InboundMessageService (via `thl-objeto.classe-objeto`) |
| ParametroAmbienteMessage | Contrato inbound do agregado Parâmetro: `/resourcen/parametro-ambiente`, `/parametro-variavel` e `/parametro-programa`; mascara o conteúdo gravado (`saveContentByType`) | idem | InboundMessage, ParametroAmbienteService, ParametroVariavelService, ParametroProgramaService | idem |

## Uma Message por agregado (2026-10-02)

Decisão do responsável em 2026-10-02 (revisão do [ADR](../adr/api-rest-cadastros-thl.md) §2.4): o cadastro pai e os filhos que não existem sem ele usam **uma Message**; cada tabela continua com o **próprio Service**. `createService()` é o Factory Method e escolhe o Service pela rota pública (`context:routePath`), como a `NotaFiscalMessage` de `thl-lib`. Aplicado nos cinco agregados — **não compilado**.

| Message (objeto) | Rota → Service |
|---|---|
| `ParametroAmbienteMessage` (PARAMETRO) | `parametro-ambiente` → `ParametroAmbienteService` · `parametro-variavel` → `ParametroVariavelService` · `parametro-programa` → `ParametroProgramaService` |
| `ObjetoMessage` (OBJETO) | `objeto` → `ObjetoService` · `objeto-parametro` → `ObjetoParametroService` · `objeto-usuario` → `ObjetoUsuarioService` |
| `ConexaoRestMessage` (CONEXAO-REST) | `conexao-rest` → `ConexaoRestService` · `conexao-rest-autenticacao` → `ConexaoRestAutenticacaoService` · `conexao-rest-header` → `ConexaoRestHeaderService` |
| `AuditoriaTabelaMessage` (AUDIT-TABELA) | `auditoria-tabela` → `AuditoriaTabelaService` · `-acesso`, `-campo`, `-notificacao`, `-expurgo` → o Service de cada filho |
| `GrupoEmailMessage` (GRUPO-EMAIL) | `grupo-email` → `GrupoEmailService` · `grupo-email-usuario` → `GrupoEmailUsuarioService` |

Seguem com Message própria (não são filhos): `AmbienteMessage`, `AplicacaoMessage`, `ConexaoRestPathMessage` (o path não pertence a uma conexão), `InboundRotaMessage`, `EmailParametroMessage`, além das consultas `AuditoriaMessage`, `EmailMessage` e `MensageriaMessage`.

**O que não mudou:** URLs, contrato JSON, filtros do GET, Services, app web e coleção Postman.

**O que mudou:**
- 11 Messages de filhos foram retiradas (cópias em `Documentos\arquivo\2026-10-02-messages-filhas-thl\`): `ParametroVariavel`, `ParametroPrograma`, `ObjetoParametro`, `ObjetoUsuario`, `ConexaoRestAutenticacao`, `ConexaoRestHeader`, `AuditoriaTabelaAcesso`/`Campo`/`Notificacao`/`Expurgo` e `GrupoEmailUsuario`. `thl-extensions` passa de 75 para **64 classes**.
- As rotas dos filhos apontam para o **objeto do pai** em `thl-inbound-rota`. Os objetos próprios dos filhos (`PARAMETRO-VARIAVEL`, `OBJETO-USUARIO`, …) ficam sem uso.
- Em cada Message unificada há três `case context:routePath`: `createService()` (rota desconhecida lança `ThlError`), `methodGet()` e `getRequiredFields()`.
- A máscara de segredo (`saveContentByType`) roda em `InboundMessageService:accept`, **antes** de o contexto existir. Por isso não depende da rota: instancia o Service direto (`new ParametroVariavelService()` / `new ConexaoRestAutenticacaoService()`) e age sobre qualquer item que tenha os campos sensíveis.
- Programa do parâmetro, usuário do objeto e usuário do grupo não tinham parâmetro de PATCH; agora o PATCH chega ao Service e cai no `update()` de `Service` ("Acao nao suportada", 17006).
- `thl-objeto-usuario` (visibilidade no monitor) passa a valer para o agregado inteiro; no monitor de mensageria as chamadas dos filhos aparecem no objeto do pai, distinguidas pela rota gravada.

**Por que pela rota e não pela operação (`pai/filho`):** com operação na URL, o `MessageConfigLoader` procura `thl-objeto-parametro` por método **e** operação, mas a chave primária (`cod-estabel`, `aplicacao`, `objeto`, `operacao`) não inclui o método — só caberia **um verbo por filho** (é o caso de `mensageria/conteudo`, só GET). Sem mudar o `.df` nem `thl-lib`, a escolha pela rota é a que aceita os quatro verbos.

**Implantação (ordem):** 1) compilar e publicar as cinco Messages; 2) apontar as rotas dos filhos para o objeto do pai — `Utils\scripts\carga-thl-api-cadastros.p` (ABL) ou `Utils\scripts\cadastrar-thl-api-rotas.ps1` / `.cmd` (pelos próprios endpoints; simulação por padrão, `-Executar` grava, `-EliminarObsoletos` elimina os objetos dos filhos); 3) apagar os `.r` das 11 classes retiradas. ⚠️ Entre o passo 1 e o 2, as rotas dos filhos ficam fora do ar (apontam para classe que não existe mais); `inbound-rota` não é afetada.

**A testar no PASOE (nada foi executado):** cada rota × verbo; rota desconhecida apontada para o objeto devolve erro; `valor` de variável sensível e `senha`/`token` da autenticação saem como `********` no conteúdo gravado da mensagem (entrada e saída); campos obrigatórios por rota; PATCH nas três rotas sem alteração.

⚠️ Achado: `thl-conexao-rest-header.parameters` pode guardar segredo (ex.: HMAC do `gestaoepi`) e **não** é mascarado no conteúdo gravado — já era assim antes da unificação.

### Demais cadastros (gerados em 2026-10-01, não compilados)

Um `<Recurso>Service` por tabela; a Message é a do agregado (seção anterior) — a coluna "Rota · objeto" mostra o objeto do pai nos filhos. Gerados por tabela a partir do `Pi-validate` (criação/alteração) e do `local-delete-record` (exclusão) da tela. Nos nomes JSON o prefixo `cod-` foi retirado (`conexao`, `usuario`, `rota`); os demais campos são o nome do banco em camelCase.

| Recurso (classes) | Tabela / tela | Rota · objeto | Chave JSON | Demais campos | Regras |
|---|---|---|---|---|---|
| `AuditoriaTabela` | `thl-audit-tabela` / thl0050 | `auditoria-tabela` · AUDIT-TABELA | `banco`, `tabela` | `pk`, `indAtivoCreate`, `indAtivoUpdate`, `indAtivoDelete`, `nivelSensibilidade`, `indAuditTabela`; só leitura: `dtAtualizacao`, `usuario` (gravados pelo Service: `now` e `ContextService:getErpUser()`) | banco/tabela obrigatórios; não elimina com campo, acesso, notificação ou expurgo |
| `AuditoriaTabelaAcesso` | `thl-audit-tabela-acesso` / thl0051b | `auditoria-tabela-acesso` · AUDIT-TABELA | `banco`, `tabela`, `usuario` | `nivelAcesso`, `indAtivo` | tabela auditada existe (2); usuário obrigatório e existente em `usuar_mestre` (2) |
| `AuditoriaTabelaCampo` | `thl-audit-tabela-campo` / thl0051c | `auditoria-tabela-campo` · AUDIT-TABELA | `banco`, `tabela`, `campo` | `nivelSensibilidade`, `indAtivo` | tabela auditada existe (2); campo obrigatório |
| `AuditoriaTabelaNotificacao` | `thl-audit-tabela-notificacao` / thl0051d | `auditoria-tabela-notificacao` · AUDIT-TABELA | `banco`, `tabela`, `nivelSensibilidade` (inteiro) | `grupoEmail`, `indAtivo` | tabela auditada existe (2); grupo obrigatório e existente em `thl-ambiente-param-grupo` (2) |
| `AuditoriaTabelaExpurgo` | `thl-audit-tabela-purge` / thl0051e | `auditoria-tabela-expurgo` · AUDIT-TABELA | `banco`, `tabela` | `retencaoDias`; só leitura: `dtUltimaExecucao` | tabela auditada existe (2); retenção ≥ 0 |
| `ConexaoRest` | `thl-conexao-rest` / thl0030 | `conexao-rest` · CONEXAO-REST | `conexao` | `descricao`, `urlBase`, `indRequisitaAutenticacao`, `indRequisitaHeader` | URL base obrigatória; não elimina com autenticação ou cabeçalho |
| `ConexaoRestAutenticacao` | `thl-conexao-rest-autenticacao` / thl0032 | `conexao-rest-autenticacao` · CONEXAO-REST | `conexao` | `urlToken`, `contentTypeToken`, `acceptToken`, `tipoAutenticacao`, `indRequisitaToken`, `usuario`, `classeParserToken`; mascarados: `headersToken`, `parametersToken`, `senha`; mascarados e só leitura: `token`, `rawTokenData`; só leitura: `dtExpiracaoToken` | conexão existe (2); uma configuração por conexão |
| `ConexaoRestHeader` | `thl-conexao-rest-header` / thl0033 | `conexao-rest-header` · CONEXAO-REST | `conexao` | `classeParser`, `parameters` | conexão existe (2); classe obrigatória |
| `ConexaoRestPath` | `thl-conexao-rest-path` / thl0031 | `conexao-rest-path` · CONEXAO-REST-PATH | `endpoint` (`cod-path`; `path` é o campo do caminho) | `descricao`, `path`, `contentType`, `accept`, `timeout`, `parameters`, `headers` | código obrigatório |
| `Objeto` | `thl-objeto` / thl0021 | `objeto` · OBJETO | `aplicacao`, `objeto` | `classeObjeto`, `modeloIntegracao`, `sentidoFluxo`, `indInativo`, `indGeraHistorico`, `programaConsulta` | aplicação existe (2); classe obrigatória; sem bloqueio de exclusão (a tela não tem) |
| `ObjetoParametro` | `thl-objeto-parametro` / thl0022a | `objeto-parametro` · OBJETO | `estabelecimento`, `aplicacao`, `objeto`, `operacao` | `metodo`, `formaExecucao`, `indInativo`, `indGeraHistorico`, `indMensagemSimples`, `paramAmbiente`, `paramAmbienteDestino`, `indPersistente`, `frequenciaExecucao`, `servidorExecucao`, `qtdTentativasPersist`, `qtdDiasPersist`, `tipoLogRequisicao`, `tipoLogRetorno` | estabelecimento `*` ou existente em `estabelec` (2); objeto existe (2) |
| `ObjetoUsuario` | `thl-objeto-usuario` / thl0022b | `objeto-usuario` · OBJETO | `aplicacao`, `objeto`, `usuario` | — (sem PATCH) | usuário obrigatório e existente em `usuar_mestre` (2); objeto existe (2) |
| `InboundRota` | `thl-inbound-rota` / thl0040 | `inbound-rota` · INBOUND-ROTA | `rota` | `rotaPublica`, `aplicacao`, `objeto`, `descricao`, `indAtivo` | aplicação e objeto existem (2); rota pública obrigatória e única |
| `EmailParametro` | `thl-email-param` / thl0010 | `email-parametro` · EMAIL-PARAMETRO | `emailParam` | `assunto`, `grupoEmail`, `remetente`, `copia`, `mensagem`, `importancia`, `logGerar` | grupo obrigatório e existente (2) |
| `GrupoEmail` | `thl-ambiente-param-grupo` / thl0011 | `grupo-email` · GRUPO-EMAIL | `grupoEmail` | `descricao` | não elimina com parâmetros de e-mail (17006) ou notificações de auditoria (17006) vinculadas |
| `GrupoEmailUsuario` | `thl-ambiente-param-grupo-usuar` / thl0011b | `grupo-email-usuario` · GRUPO-EMAIL | `grupoEmail`, `usuario`, `emailAlternativo` | — (sem PATCH) | usuário obrigatório e existente em `usuar_mestre` (2); grupo existe (2); sem duplicata (17006) |

- Filtros do GET: `<chave>Ini`/`<chave>Fin` — `bancoIni/Fin` + `tabelaIni/Fin` (auditoria), `conexaoIni/Fin`, `endpointIni/Fin`, `aplicacaoIni/Fin` + `objetoIni/Fin` (objeto, parâmetro e usuário), `rotaIni/Fin`, `emailParamIni/Fin`, `grupoEmailIni/Fin` (grupo e usuário do grupo).
- `referenceCode` de chave composta: partes unidas por `#`, na ordem da tabela acima.
- Regras que valem na criação e na alteração ficam no método privado `validateRecord()` do Service (lê o buffer depois do `mapFields`, antes do commit).
- Campos sensíveis da autenticação: `********` no GET quando há valor (vazio continua vazio); PATCH com `********` mantém o valor; `ConexaoRestMessage` mascara o conteúdo gravado (`saveContentByType`) pela lista `SensitiveFields` do Service.
- `AuditoriaTabelaAcessoService`, `ObjetoUsuarioService`, `GrupoEmailUsuarioService` (`usuar_mestre`) e `ObjetoParametroService` (`estabelec`) precisam dos bancos Datasul conectados para compilar e rodar.
- `objeto`, `objeto-parametro` e `inbound-rota` alteram a configuração da própria API (aplicação `THL`): erro nesses registros derruba a API; a recuperação é pela tela `.w`.
- `cod-rota` da carga = `THL-` + objeto (por isso os objetos de auditoria usam `AUDIT-`, para caber em 30 caracteres). As rotas dos filhos mantêm o código da carga anterior (`THL-` + objeto antigo do filho, ex.: `THL-OBJETO-USUARIO`), mesmo apontando para o objeto do pai.

## Caminhos e pacotes

```text
Fontes\thl-extensions\erp\thl\service\<Recurso>Service.cls                 thl-extensions.erp.thl.service.<Recurso>Service
Fontes\thl-extensions\integration\thl\messaging\inbound\message\<Recurso>Message.cls
                                                                            thl-extensions.integration.thl.messaging.inbound.message.<Recurso>Message
```

## Rotas e cadastros

Carga: `Utils\scripts\carga-thl-api-cadastros.p` (simulação por padrão; idempotente; desde 2026-10-02 repõe para o objeto do pai a rota de filho criada por carga anterior e avisa dos objetos sem uso). Pelos endpoints, com a API já no ar: `Utils\scripts\cadastrar-thl-api-rotas.ps1` (ou `.cmd`) — `-BaseUrl`, simulação por padrão, `-Executar`, `-EliminarObsoletos`; usuário e senha pedidos na hora, nada gravado no arquivo. O roteador (`InboundRouteResolver`) não foi alterado: 1 segmento = rota; um 2º segmento seria a operação.

| URL (`…/api/thl/integration/v1/resourcen/…`) | `thl-inbound-rota` (`cod-rota`) | Objeto (aplicação `THL`) | `thl-objeto-parametro` (cod-estabel `*`) |
|---|---|---|---|
| `ambiente` | `THL-AMBIENTE` | AMBIENTE | operações GET, POST, PATCH, DELETE (métodos 5, 1, 3, 4) |
| `parametro-ambiente` | `THL-PARAMETRO` | PARAMETRO | GET, POST, PATCH, DELETE |
| `parametro-variavel` | `THL-PARAMETRO-VARIAVEL` | PARAMETRO (do pai) | os do objeto PARAMETRO |
| `parametro-programa` | `THL-PARAMETRO-PROGRAMA` | PARAMETRO (do pai) | os do objeto PARAMETRO (PATCH → "Acao nao suportada") |
| `aplicacao` | `THL-APLICACAO` | APLICACAO | GET, POST, PATCH, DELETE |

Sem operação na URL, o `MessageConfigLoader` acha o `thl-objeto-parametro` pelo **método**; como a chave primária inclui a operação, cada método usa o próprio nome como operação. Mover/renomear uma Message exige atualizar `thl-objeto.classe-objeto`.

## Teste (Postman)

Coleção **Nitro** no Postman do responsável (nuvem, workspace pessoal — não há mais cópia em `Utils\postman`, removida em 2026-10-01): `TOTVS > Projeto > THL-Library > THL` (a pasta `Biblioteca` foi renomeada para `THL-Library` em 2026-10-01), uma subpasta por cadastro — as URLs não mudaram com a unificação das Messages de 2026-10-02, então a coleção segue válida (Ambiente, Parametro, Parametro Variavel, Parametro Programa, Aplicação e, desde 2026-10-01, Auditoria Tabela, Auditoria Tabela Acesso/Campo/Notificacao/Expurgo, Conexao REST, Conexao REST Autenticacao/Header/Path, Objeto, Objeto Parametro, Objeto Usuario, Inbound Rota, Email Parametro — estas 14 com examples de sucesso: lista, lista vazia, criado, alteração parcial, eliminado). Desde 2026-10-01 cada subpasta tem as requests `GET Lista`, `POST`, `PATCH` e `DELETE` (sem `GET Por Chave`: a leitura por chave é o `GET Lista` com a mesma chave em `Ini`/`Fin`), com descrição, teste leve (status 200 + `items`/`hasNext` ou `success`) e os cenários salvos como **examples** (`<Pasta> - <Cenário>`: filtro pela chave, lista vazia, alteração parcial, senha mascarada, `********` mantém valor). Os examples foram derivados do código, ainda não capturados de execução real; os de erro entram depois do primeiro teste contra o PASOE. Autenticação herdada da pasta `Projeto`; URL sempre `{{URI-BASE-PROJETO-INTERNO}}`. Host e credenciais ficam só nas variáveis da coleção, nunca no repositório. Dados de teste: ambiente `TSA`, parâmetro `TSTAPI`.

## Contrato JSON

| Recurso | Campos (chave em **negrito**) | Filtros do GET (query string) |
|---|---|---|
| Ambiente | **`codAmbiente`**, `nomeAmbiente`, `ip` | `ambienteIni`, `ambienteFin` |
| Parâmetro | **`codParametro`**, `descricao` | `parametroIni`, `parametroFin` |
| Variável | **`codAmbiente`** (`*` = todos), **`codParametro`**, **`codVariavel`**, `descricao`, `valor` | `ambienteIni/Fin`, `parametroIni/Fin` |
| Programa | **`codParametro`**, **`codPrograma`** | `parametroIni`, `parametroFin` |
| Aplicação | **`aplicacao`**, `descricao` | `aplicacaoIni`, `aplicacaoFin` |

Os filtros do GET são sempre faixas (`Ini`/`Fin`) sobre campos da chave primária (`pk-*`); para ler um registro, informar a mesma chave nos dois.

Todos os GET aceitam `page` e `pageSize` (padrão 100); o Service devolve um array com `referenceCode` por item e o `resourcen.p` o entrega ao cliente como `{ "items": [...], "hasNext": false }` (`JsonAPIResponseBuilder:ok( JsonArray, false )` — `hasNext` é sempre `false`). POST/PATCH/DELETE levam a chave no corpo JSON (o DELETE também exige payload) e devolvem `ServiceResponse:success`. `getRequiredFields()` = campos da chave; `getExternalReferenceField()` = `''`.

## Regras (paridade com as telas)

- Erros com os códigos das telas: `ThlError` de 3 parâmetros → **17006**; pai/relacionado inexistente → `ThlError(…, 2)`.
- A chave só é gravada na criação; `mapFields()` grava só os demais campos presentes no payload (`JsonSetter`).
- Exclusão bloqueada com vínculo: ambiente com variáveis (a tela thl0001 ganhou o mesmo bloqueio); parâmetro com variáveis ou programas.
- Aplicação: exclusão bloqueada se houver `thl-objeto` da aplicação (igual ao `local-delete-record` do thl0020).
- Programa: PATCH cai no `update()` de `Service` → "Acao nao suportada" (17006).

## Valores sensíveis

- `isSensitive( codVariavel )` (método de instância do `ParametroVariavelService`): nome contém `SENHA`, `PASSWORD`, `SECRET`, `TOKEN`, `KEY` ou `CHAVE` (piloto; definitivo seria `ind-sensivel` no `.df`).
- GET devolve `"********"` (propriedade `MaskedValue` do Service) no `valor` dessas variáveis; PATCH com `"********"` mantém o valor gravado.
- O THL sempre grava o conteúdo das mensagens: `ParametroAmbienteMessage` sobrescreve `saveContentByType( typeContent, content )` e mascara o `valor` sensível (objeto ou array JSON) antes do `super`, usando uma instância direta do Service (`new ParametroVariavelService()` — o `createService()` depende da rota, que ainda não existe quando a entrada é gravada); conteúdo que não é JSON é gravado como veio.

## Observações

- Todas as chamadas (inclusive GET) geram `thl-mensagem`: incluir a aplicação `THL` no expurgo de mensagens (thl0222).
- Sem autorização por usuário (fora do escopo); vale a autenticação do PASOE/Datasul.
- PATCH sem controle de concorrência ("último grava vence").
- Exemplos e testes sem IP, host ou senha reais.

## Correção de pacotes — 01/10/2026

As definições de MensageriaMessage, AuditoriaService, MensageriaService e MensageriaConteudoService foram alinhadas aos caminhos atuais em thl-extensions. Os USING de AuditoriaMessage e MensageriaMessage apontam para thl-extensions.erp.thl.service. A alteração foi validada estaticamente, sem compilação OpenEdge.

Se thl-objeto.classe-objeto ainda contiver thl-lib.integration.messaging.inbound.message.MensageriaMessage, atualizar para thl-extensions.integration.thl.messaging.inbound.message.MensageriaMessage. Conferir também referências históricas em thl-mensagem.pacote utilizadas no reprocessamento. Nenhum cadastro do banco foi alterado pelo agente.
