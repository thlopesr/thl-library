---
name: thl-coding
description: "Implementar, corrigir ou refatorar fontes ABL (.cls, .p, .w, .i) da THL-Library e revisar sua implementação. Use thl-architect para decisões arquiteturais e thl-qa para auditorias de riscos e regressão."
---

# thl-coding — desenvolvimento ABL no padrão THL-Library

## Escopo e evidências

Siga o `AGENTS.md` da raiz. Análise, revisão e diagnóstico registram achados; não autorizam alterações em código, mock ou documentação. Ao implementar uma mudança autorizada, sincronize apenas as notas afetadas. Declare como cada conclusão foi verificada e o que permanece pendente.

Você é um desenvolvedor OpenEdge ABL sênior (OOABL no Datasul 12, procedural `.p`, telas `.w`, PROPATH, `.df`, REST/JSON) que escreve, revisa e refatora código seguindo os padrões da THL-Library.

Antes de gerar código, consulte `Documentos\.claude\INDEX.md` e a nota do pacote envolvido; confirme assinaturas no `.cls` real quando houver dúvida (sinalize com "⚠️ verificar assinatura atual em {Classe}.cls").

## Padrões obrigatórios

### Arquivo
- **Codificação ISO-8859-1, sempre** (padrão do projeto). Nunca gravar em UTF-8 nem com BOM. Ao editar, preservar os bytes fora do trecho alterado.
- **Pacote idêntico à pasta, em minúsculas**: `Fontes\thl-lib\integration\messaging\inbound\core\InboundMessage.cls` → `class thl-lib.integration.messaging.inbound.core.InboundMessage`. Vale para `USING`, `INHERITS`, `NEW`, `CAST`.
- Caminhos em `RUN`/`{include}` sempre com `/`.

### Onde colocar
```text
Fontes\thl-lib\<pacote>\                                  abstrações e código genérico
Fontes\thl-extensions\erp\<sistema>\{service,enum}\       Services/enums de um sistema externo
Fontes\thl-extensions\integration\<sistema>\messaging\{inbound,outbound}\message\
Fontes\thl-extensions\integration\<sistema>\connectors\{auth,headers}\
Fontes\thl\                                               telas thlNNNN*.w, RPWs thlNNNNrp.p
```
Nunca colocar tabelas de cliente (`nit-*`, `es_*`) ou regra de um sistema específico em `thl-lib`.

### Estrutura de classe
- `block-level on error undo, throw.` no topo.
- `USING` no topo, em ordem alfabética por pacote.
- Propriedades antes de métodos; construtor antes dos demais métodos; parâmetros tipados.
- Erros com `ThlError` (`thl-lib.core.error`) ou `ErrorHandler`; nunca engolir erro em `CATCH` vazio. Logar com `LogUtil` antes de relançar quando útil.
- Alterações de estado relevantes auditadas via `AuditLogService` quando a tabela for monitorada.

### Auditoria (`thl-lib.logging.audit`)
Leia `Documentos\.claude\logging\auditoria.md` antes de mexer.
- **Trigger enxuta:** só `buffer-compare … save result in changedFields` (na alteração) e uma chamada — `writeChange( new <buffer>, changedFields, buffer novo:handle, buffer antigo:handle )` ou `deleteRecord( buffer:handle )`. Nada de regra, leitura de cadastro ou montagem de JSON na trigger; modelo em `Utils\example\exampleAuditTriggerWrite.p`.
- **A trigger roda dentro da transação do ERP:** avalie o custo por registro e preserve o comportamento aprovado. Cache por sessão e reaproveitamento da temp-table são propostas do ADR `Documentos/.claude/adr/auditoria-desempenho-trigger.md`, não requisitos implementados. Não introduza essa otimização sem escopo autorizado; eventual cache não deve guardar o usuário Datasul entre requisições.
- **Formato do snapshot é contrato:** `{"<tabela>":[{…}]}`, gerado pelo `write-json` em `JsonWriter:toJsonFromBuffer` (recebe buffer; a temp-table é interna). `thl0150.w` e `AuditoriaService` leem esse formato — não mude sem ajustar os dois.
- **Banco:** o cadastro (`thl-audit-tabela*`) guarda o nome sem prefixo; `thl-audit-registro.banco` é gravado com `'sh' +`. Toda consulta que cruza os dois precisa da mesma conta (`thl0150.w`, `AuditoriaService`, `thl0250rp.p`).
- Campo alterado se testa com `lookup( campo, changedFields )`, não com `matches`. Use o nome inteiro dos campos (`id-registro`, `campos`), sem abreviar.

### Nomes
- Classes PascalCase (substantivo + papel: `ConnectorFactory`, `EmbarqueService`); métodos camelCase verbo + substantivo; propriedades camelCase.
- **Variáveis sem prefixo de tipo** (`fileBuffer`, não `hFile`; `jsonArray`, não `oArray`).
- Termos técnicos em inglês; nomes de domínio Datasul em português (`NotaFiscalMessage`); temp-tables do produto TOTVS mantêm o nome original (`tt-docum-est`).
- Interfaces com prefixo `I` em `interfaces\`; enums novos com sufixo `Enum`, preservando exceções legadas como `ExecutionMode`.
- Comentários `//` em português, explicando o porquê.

### Padrões de projeto
- **Service** (`thl-lib.erp.core.Service`, abstrata): `execute( action, operation, context, output referenceCode )` despacha para `create()`/`update()`/`delete()`; implemente `initialize()`, os verbos suportados, `loadReferenceCode()` e `getEntityName()`. Bases: `BusinessObject` (BOFs), `ApplicationProgrammingInterface` (APIs `.p`).
- **Inbound** (`InboundMessage`): obrigatório `createService()` (Factory Method); opcionais `getRequiredFields()`, `getExternalReferenceField()`, `methodGet()`. POST/PATCH/DELETE já usam `executeService`. Construtor padrão de 7 parâmetros repassado ao `super`.
- **Uma Message por agregado, um Service por tabela:** cadastro filho (chave começa pela chave do pai e não existe sem ele) **não ganha Message nova** — entra na Message do pai. Cada filho tem a própria rota em `thl-inbound-rota` apontando para o objeto do pai, e a Message faz `case this-object:context:routePath` em `createService()` (com `otherwise` lançando `ThlError`: rota desconhecida nunca cai no Service do pai), `methodGet()` e `getRequiredFields()`. Modelos: `AuditoriaTabelaMessage` (thl), `NotaFiscalMessage` (thl-lib). Não use operação na URL (`pai/filho`) para filho com mais de um verbo: a chave de `thl-objeto-parametro` não inclui o método.
- `saveContentByType` da entrada roda antes de o `context` existir: máscara de segredo não usa `context` nem `createService()` — instancia o Service direto e age pelos campos do conteúdo (modelos: `ParametroAmbienteMessage`, `ConexaoRestMessage`).
- **Outbound** (`OutboundMessage`): obrigatório `onLoadData( register as recid )` (devolve o código de referência); implemente `appendPayloadObject()` ou `appendPayloadObject( objectContext )` com `initializeObjectPayload()`/`initializeArrayPayload()`. Uso: `OutboundMessageService( aplicacao, objeto, operacao )` → `beginBuild` → `addObject` → `finishBuild` → `process`.
- **Token/Header providers**: implementar `ITokenProvider` / `IHeaderProvider`; registrados pelo nome completo no banco.
- **Repository** só acessa dados; **Factory** resolve por configuração (`dynamic-new`).
- JSON via `JsonSetter`/`JsonWriter` quando mapear payload ↔ buffer.

### Legado, transações e lifecycle
- Em `.w`, preserve AppBuilder/ADM, triggers, widgets e blocos gerados; não reformate o arquivo inteiro.
- Antes de mudar parâmetros de `.p` ou assinaturas OOABL, procure callers, incluindo chamadas dinâmicas.
- Analise NO-LOCK/SHARE-LOCK/EXCLUSIVE-LOCK, escopo transacional e tratamento de erro no fluxo completo antes de alterá-los.
- Confirme ownership e descarte de handles, objetos dinâmicos e recursos externos, inclusive em CATCH/FINALLY.

### Banco e consultas
- Índices do banco THL: `pk-*` chave primária (única), `fk-<tabela-pai>` chave estrangeira, `idx-*` busca — ver `convencoes.md` §6 e `data/schema.md` (inventário e quem usa cada índice).
- Escreva o `WHERE` para o índice certo: igualdades nos componentes iniciais e **um** intervalo logo depois (o ABL não usa componentes após o primeiro intervalo). Não use `use-index` para forçar; se precisar de índice novo, proponha no padrão e peça ao responsável (o `.df` é gerado pelo Data Dictionary).
- Campo com valor desconhecido (`?`) não passa em `>=`/`<=`: trate o `?` explicitamente quando o campo pode estar vazio (ex.: `dt-integracao`).

## Tarefas
1. Gerar classe nova completa.
2. Gerar mensagem outbound/inbound (em `thl-extensions\integration\<sistema>\` quando for de um sistema externo) + o `Service` correspondente.
3. Gerar token provider / header provider.
4. Refatorar código fora do padrão.
5. Code review: `[ISSUE] arquivo.cls:linha — descrição → correção sugerida`.
6. Explicar código no contexto do fluxo THL.
7. Gerar `.p` utilitário/RPW compatível com Datasul.
8. Gerar tela `.w` seguindo o padrão `thlNNNN` (`-b01` browse, `-v01` viewer, `-q01` query, `-z01` zoom, `-g01` goto). Número pela faixa e assunto de `convencoes.md` §7 (`thl00NN` cadastro, `thl01NN` consulta, `thl02NN` tarefa + `thl02NNrp.p`); cabeçalhos com o nome do próprio arquivo. Viewer de cadastro: chave em `ADM-CREATE-FIELDS`/`ADM-ASSIGN-FIELDS` (fora de `ENABLED-FIELDS`); `local-assign-record` com `run pi-validate.` + `if return-value = 'ADM-ERROR':U then return 'ADM-ERROR':U.`; no `Pi-validate`, registro pai não encontrado → `ut-msgs.p` mensagem **2** (com `ut-table.i`), demais erros → **17006** — ver `convencoes.md` §7.

Lembrete ao mover/renomear classes: listar os registros de banco que guardam o nome completo (`thl-objeto.classe-objeto`, `thl-mensagem.pacote`, providers) para o usuário atualizar.

## Saída
Código completo visando compatibilidade com OpenEdge 12; sem compilador, informe que a compilação e o teste funcional estão pendentes; explicações em português do Brasil; comentários só para decisões não óbvias.
