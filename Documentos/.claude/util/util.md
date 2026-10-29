---
tipo: modulo
camada: core
status: vigente
tags: [thl-lib, util]
updated: 2026-10-13
---

# Pacote: util

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| StringUtil | Utilitários estáticos para verificação, conversão e formatação de strings/longchar/datas | Nenhum | — | Praticamente toda a biblioteca (EnvironmentUtil, LogUtil, RestConnector, InboundMessage, OutboundMessage, AuthenticationConfig, EmailParamRepository, etc. — 20+ consumidores) |
| DateTimeUtil | Soma de horas, dias, meses e anos devolvendo `datetime` (sem fuso); faz num lugar só a conversão do `datetime-tz` do `now` | Métodos `static` | — | MensageriaService, EmailService e AuditoriaService (padrão das faixas de data: últimas 24 horas, na listagem de mensageria e nos `consultMetrics`) |
| JsonSetter | Mapeia campos de um `JsonObject` para variáveis ABL de diferentes tipos, sem lançar erro para campos ausentes | Nenhum | ThlError | resourcen.p, OutboundMessage, EmbarqueService, UsuarioService, LpcoService, ItemService, CentroCustoService, RequisicaoService |
| JsonWriter | Serializa buffer handle para JSON e converte listas delimitadas para JsonArray | Nenhum | — | AuditLogService |
| JsonUtil | Consultas estáticas sobre `JsonObject` (`hasAnyProperty`, `requireProperties`, `getText`) | Nenhum | — | EmbarqueService, LoogAiEmbarqueService |
| FileUtil | Utilitários estáticos para verificação e leitura de arquivos | Nenhum | StringUtil, ThlError | PedidoMessage, NinahubNotaFiscalService, StatusDocumento, ItemRequisicaoMessage, RequisicaoMessage (gestãoEPI) |
| Base64File | Um arquivo em base64: `fileName`, `extension`, `content`; nome e extensão limpos por `FileUtil:sanitizeFileName`; nome e conteúdo obrigatórios; `save( diretorio )` grava e devolve o caminho | Nenhum | FileUtil, StringUtil, ThlError | Base64Files |
| Base64Files | Conjunto de `Base64File` com `directory`: `fromJson( JsonArray, diretorio )` (`[ { nome, extensao, conteudoBase64 } ]`), `add`, `save()` (cria a pasta se faltar; mesmo nome sobrescreve), `rollback()` (apaga o que gravou) | Nenhum | Base64File, JsonUtil, StringUtil, ThlError | AutomatizadorMedicaoContratoService |
| PaginationHelper | Infraestrutura reutilizável de paginação offset-based (skip/stop para FOR EACH paginados) | Helper | — | LpcoService, ItemService, EmailService, MensageriaService, CentroCustoService, MensageriaConteudoService, AuditoriaService, LpcoMessage, AuditoriaMessage, EmailMessage, MensageriaMessage |
| SchemaUtil | Consulta o Data Dictionary via handles dinâmicos de schema; retorna campos do índice PRIMARY e propriedades completas dos campos via `getFieldSchema` | Métodos `static` | ThlError (apenas em `getFieldSchema`) | thl0050-v01.w, thl0051h.w |
| **JsonArrayCsvExporter** | Exporta JsonArray para arquivo CSV (RFC 4180). Auto-detecta colunas ou aceita lista explícita | Nenhum | — | exampleFileScanner.p, exampleTableImpactCompiler.p |
| **FileScanner** | Varre N diretórios recursivamente e retorna ScannedFileSet com metadados de cada arquivo | Discovery | LogUtil | FileContentSearcher, TableImpactCompiler, consumidores genéricos |
| **ScannedFileSet** | Coleção tipada de arquivos varridos; contrato central entre produtor e enrichers | Collection | — | FileScanner, FileContentSearcher, TableImpactCompiler |
| **IFileEnricher** | Interface de extensão para enriquecimento de ScannedFileSet | Interface | — | FileContentSearcher |
| **FileContentSearcher** | Implementa IFileEnricher: busca palavra-chave no conteúdo dos arquivos e enriquece ScannedFileSet com found, matchCount, firstMatchLine | Enricher | LogUtil | TableImpactCompiler, consumidores genéricos |
| **CompilationResult** | Value-object com resultado de compilação de um arquivo (sucesso/erro com detalhes) | Value-object | — | ProgramCompiler, TableImpactCompiler |
| **ProgramCompiler** | Executa `COMPILE ... SAVE NO-ERROR` um arquivo por vez e captura `COMPILER:*` | Helper | ErrorHandler, LogUtil, StringUtil | TableImpactCompiler |
| **TableImpactCompiler** | Fachada ABL: busca direta ou pipeline de duas passadas (busca direta + via includes) com FileScanner + FileContentSearcher + ProgramCompiler. Retorna `JsonArray` enriquecido com atributos de compilação | Facade | FileScanner, FileContentSearcher, ScannedFileSet, ProgramCompiler, CompilationResult, ErrorHandler, ThlError | (consumidores a definir) |

> ⚠️ **Classe removida:** `DocumentConversionService` (bridge CLR DOCX→PDF) documentada anteriormente — arquivo `.cls` não existe no working copy atual. A nota dedicada (`document-conversion.md`) foi removida em 2026-09-24. (`testDocxToPdf.p` foi removido junto com o conteúdo de `Utils\test\`.)
>
> ⚠️ **Classe removida:** `CompilationReport` (gerava `compilation-result-{timestamp}.log`) — absorvida pelo `TableImpactCompiler`, que agora retorna `JsonArray` em vez de gerar arquivo de log.

---

## StringUtil

**Caminho:** `thl-lib\util\string\StringUtil.cls`

**Namespace ABL:** `thl-lib.util.string.StringUtil`

**Responsabilidade:** Utilitários estáticos para normalizar, verificar e formatar strings e datas. Converte `?` (unknown) para `''`, verifica se um valor tem conteúdo (não vazio após trim), remove caracteres de controle, formata datas ISO 8601 e parseia datas de payloads JSON. Declarado `serializable`.

> ⚠️ **Risco (QA 2026-09-17):** Classe **sem** `block-level on error undo, throw`. Exceções em `parseDate` (chamada a `entry()` com input malformado) podem escapar silenciosamente. Header do arquivo diz "TextoUtil" (nome antigo).

**Dependências diretas THL:** Nenhuma.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public static final character getText( variavel as longchar )` | Retorna `''` se `variavel = ?`, caso contrário retorna o valor. |
| `method public static final character getText( variavel as integer )` | Converte integer para string e aplica `getText(longchar)`. |
| `method public static final character getText( variavel as decimal )` | Converte decimal para string e aplica `getText(longchar)`. |
| `method public static final logical hasValue( input valueText as longchar )` | Retorna `true` se `trim(getText(valueText)) <> ''`. |
| `method public static final character enumToCode( input enumValue as Progress.Lang.Enum )` | Código de variável a partir do membro do enum: `replace( enumValue:toString(), '_', '.' )` (`MENSAGEM_ENTRADA` → `MENSAGEM.ENTRADA`; a busca não diferencia maiúsculas, então acha `mensagem.entrada`). Usado pelo `EnvironmentResource:getEnvironmentVariable( enum )`. |
| `method public static final character requireValue( input valueText as longchar, input errorText as character )` | Exige valor: vazio, só espaços ou `?` lança `ThlError` (17006, origem `StringUtil.requireValue`) com `errorText`; com conteúdo devolve o texto sem espaços nas pontas. |
| `method public static final character requireValue( input valueText as longchar, input className as character, input methodName as character, input errorText as character )` | Mesma regra, com a origem do erro apontando para a classe e o método informados (quem chamou). Usado por `EnvironmentResource:getRequiredEnvironmentVariable`. |
| `method public static final longchar removeCr( input valueText as longchar )` | Substitui `chr(13)` (CR) por `'||'`. |
| `method public static final longchar removeLf( input valueText as longchar )` | Substitui `chr(10)` (LF) por `'||'`. |
| `method public static final character removeCrLf( input valueText as longchar )` | Aplica `removeLf(removeCr(valueText))` e converte para `character`. |
| `method public static final character formatIsoDate( input inputDate as date )` | Retorna data no formato ISO 8601 (`YYYY-MM-DD`). Retorna `""` para `?`. |
| `method public static final datetime parseDate( input dateString as character, input defaultValue as datetime )` | Parseia string `YYYY-MM-DD` para `datetime`. Retorna `defaultValue` se input vazio ou `?`. Usa `entry()` para split — **não protege input malformado** (sem `block-level`, erro pode escapar). |

**Observações:**
- Usado amplamente como guarda contra `?` antes de operações que não aceitam unknown value.
- `removeCr`/`removeLf`/`removeCrLf` — sem consumidores conhecidos em `Fontes/` (possível código morto, verificar procedures externas).

---

## DateTimeUtil

**Caminho:** `thl-lib\util\date\DateTimeUtil.cls`

**Namespace ABL:** `thl-lib.util.date.DateTimeUtil`

**Responsabilidade:** `add-interval` sobre `now` devolve `datetime-tz`, e esse valor não pode ser passado direto onde se espera `datetime`; a classe converte (atribui a uma variável `datetime`) num lugar só. Quantidade negativa volta no tempo; base `?` devolve `?`. Criada em 2026-10-13, não compilada.

| Método | Descrição |
|---|---|
| `method public static final datetime currentDateTime()` | Data e hora atuais como `datetime` |
| `method public static final datetime addHours( input baseDateTime as datetime-tz, input hours as integer )` | Soma (ou subtrai) horas |
| `method public static final datetime addDays( input baseDateTime as datetime-tz, input days as integer )` | Soma (ou subtrai) dias |
| `method public static final datetime addMonths( input baseDateTime as datetime-tz, input months as integer )` | Soma (ou subtrai) meses |
| `method public static final datetime addYears( input baseDateTime as datetime-tz, input years as integer )` | Soma (ou subtrai) anos |
| `method public static final character formatDate( input baseDateTime as datetime-tz )` | Data no formato `dd/MM/yyyy`; base `?` devolve `''` |
| `method public static final character formatTime()` | Hora atual no formato `HH:mm:ss` (`string( time, 'HH:MM:SS' )`) |
| `method public static final character formatTime( input baseDateTime as datetime-tz )` | Hora no formato `HH:mm:ss`; base `?` devolve `''` |
| `method public static final character formatTimestamp( input baseDateTime as datetime-tz )` | Data e hora no formato `ddMMyyyyHHmmss` (serve para nome de arquivo); base `?` devolve `''` |

Uso: `DateTimeUtil:addHours( now, -24 )` (padrão: últimas 24 horas) e `DateTimeUtil:currentDateTime()`, nos `consultMetrics` dos três serviços de consulta e na listagem de mensageria.

---

## JsonSetter

**Caminho:** `thl-lib\util\json\JsonSetter.cls`

**Namespace ABL:** `thl-lib.util.json.JsonSetter`

**Responsabilidade:** Facilita o mapeamento de campos JSON para variáveis ABL: se o campo existir no payload, atribui o valor convertido; caso contrário, mantém o valor atual da variável. Suporta os tipos `character`, `integer`, `decimal`, `date` e `logical`. O payload pode ser substituído em tempo de execução via `setPayload`.

**Diretiva de erro:** `routine-level on error undo, throw.`

**Dependências diretas THL:** `ThlError`.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `constructor public JsonSetter( input payload as JsonObject )` | Inicializa com o payload. Lança `ThlError` se inválido. |
| `method public void setPayload( input payload as JsonObject )` | Substitui o payload ativo. Lança `ThlError` se inválido. Útil para reusar instância em sub-objetos. |
| `method public void SetValue( input-output valueField as character, input nameField as character )` | Atribui valor character (UTF-8) se campo presente no payload. |
| `method public void SetValue( input-output valueField as integer, input nameField as character )` | Atribui valor integer se campo presente; aceita também o número entre aspas (`"10"`) e texto em branco mantém o valor. |
| `method public void SetValue( input-output valueField as decimal, input nameField as character )` | Atribui valor decimal se campo presente; aceita também o número entre aspas (`"100"`, `"100.50"`: o ponto vira o separador da sessão) e texto em branco mantém o valor. |
| `method public void SetValue( input-output valueField as date, input nameField as character )` | Atribui valor date se campo presente. |
| `method public void SetValue( input-output valueField as logical, input nameField as character )` | Atribui valor logical se campo presente. |

**Observações:**
- `payload` é property **privada de instância** — não é acessível estaticamente. (O antigo `testJsonSetter.p`, que acessava `payload` como estático e não compilava, foi removido junto com o conteúdo de `Utils\test\` em 2026-09.)
- `nameField` é sempre passado por `trim()` antes da verificação — campos com espaços em branco são normalizados automaticamente.

---

## JsonUtil

**Caminho:** `thl-lib\util\json\JsonUtil.cls`

**Namespace ABL:** `thl-lib.util.json.JsonUtil`

**Responsabilidade:** Consultas genéricas sobre `JsonObject`, sem mapear para buffer (papel do `JsonSetter`) nem serializar (papel do `JsonWriter`). Classe só com métodos estáticos.

| Assinatura | Descrição |
|---|---|
| `method public static final logical hasAnyProperty( input json as JsonObject, input propertyList as character )` | `true` se o JSON tiver ao menos uma das propriedades da lista (separada por vírgula; espaços em volta dos nomes são ignorados). JSON inválido (`?`) → `false`. |

Uso típico: validar PATCH com campos opcionais — `if not JsonUtil:hasAnyProperty( inContext, 'placa,motorista' ) then ...`.

---

`JsonUtil:getText( json, propertyName )` (2026-10-21, não compilado): texto de uma propriedade que pode vir como string ou número (nota fiscal, códigos); ausente, nula ou de outro tipo devolve `''`.

## JsonWriter

**Caminho:** `thl-lib\util\json\JsonWriter.cls`

**Namespace ABL:** `thl-lib.util.json.JsonWriter`

**Responsabilidade:** Serializa um buffer handle para JSON usando temp-table dinâmica, e converte listas delimitadas em JsonArray. Declarado `serializable`.

> ⚠️ **Risco (QA 2026-09-17, revisto em 2026-10-01):** a classe já tem `block-level on error undo, throw` e o header já diz `JsonWriter`. Segue valendo: `toJsonFromBuffer` retorna `''` silenciosamente para handle inválido em vez de lançar `ThlError`.

**Dependências diretas THL:** Nenhuma (ThlError listado no doc anterior não é usado no código real).

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public static longchar toJsonFromBuffer( input bufferHandle as handle, input prettyPrint as logical )` | Cria temp-table dinâmica via `create-like-sequential`, copia o buffer e serializa para JSON via `write-json`. Retorna `''` se handle inválido. Libera objetos no `FINALLY`. |
| `method public static longchar toJsonFromBuffer( input bufferHandle as handle )` | Overload simplificado: chama `toJsonFromBuffer(bufferHandle, true)`. |
| `method public static longchar charListToJsonArray( input cList as character, input cDelimiter as character )` | Converte lista delimitada em JSON array de strings. Ex: `charListToJsonArray("a,b,c", ",")` → `["a","b","c"]`. Retorna `'[]'` se lista vazia ou `?`. Libera `JsonArray` no `FINALLY`. |
| `method public static longchar charListToJsonArray( input cList as character )` | Overload com delimitador padrão `','`. |

**Observações:**
- ⚠️ O parâmetro `prettyPrint` **é ignorado**: o `write-json` recebe `true` fixo, então o JSON sai sempre formatado (maior). Único chamador: `AuditLogService.logRecordDetail`.
- Formato de saída: `{"<tabela>":[{…campos…}]}`. Os leitores da auditoria dependem dele — `AuditoriaService.parseSnapshot`/`filterSnapshot` (primeiro nome = array de registros) e `thl0150.w` (`read-json` com `APPEND` numa temp-table dinâmica).
- A temp-table dinâmica é criada, preparada e destruída **a cada chamada** (duas vezes por alteração auditada); não há reaproveitamento.
- O `FINALLY` apaga `ttHandle` e depois `ttBuffer` (o buffer padrão já morreu com a temp-table; `no-error` torna inofensivo). A variável `ds` citada em versões anteriores desta nota não existe mais.

---

## FileUtil

**Caminho:** `thl-lib\util\file\FileUtil.cls`

**Namespace ABL:** `thl-lib.util.file.FileUtil`

**Responsabilidade:** Utilitários estáticos para trabalhar com arquivos via `FILE-INFO`. Verifica existência, obtém caminho completo e carrega arquivo como Base64 (útil para envio de anexos em APIs). Declarado `serializable`.

**Diretiva de erro:** `block-level on error undo, throw.`

**Dependências diretas THL:** `StringUtil`, `DateTimeUtil`, `ThlError`.

> ⚠️ Header do arquivo diz "TextoUtil" (copy-paste de StringUtil).

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public static final logical exists( input filePath as character )` | Retorna `true` se arquivo encontrado via `FILE-INFO`. Retorna `false` para path vazio. |
| `method public static final character getFullPathName( input filePath as character )` | Retorna `file-info:full-pathname` ou `?` se não encontrado. |
| `method public static final longchar loadFileAsBase64( input filePath as character )` | Carrega arquivo em memptr via `COPY-LOB` e retorna `BASE64-ENCODE`. Lança `ThlError` se path vazio ou arquivo não encontrado. Libera memptr no `FINALLY`. |
| `method public static final void saveBase64AsFile( input filePath as character, input base64Content as longchar )` | Decodifica o base64 e grava o arquivo com `COPY-LOB` (sobrescreve se existir; a pasta precisa existir). Erro (`ThlError`) se caminho ou conteúdo vazios. |
| `method public static final character sanitizeFileName( input rawName as character )` | Nome (ou extensão) de arquivo seguro: remove barras, dois-pontos, asterisco, interrogação, aspas, sinais de menor/maior, pipe, caracteres de controle e pontos no início. `?` devolve `''`. |
| `method public static final character formatFileNameWithTimestamp( input filePath as character )` | Acrescenta `_ddMMyyyyHHmmss` (agora) antes da extensão: `C:\TEMP\a.xls` → `C:\TEMP\a_28102026105700.xls`. Sem extensão, acrescenta no fim; ponto em nome de pasta não conta como extensão; path vazio devolve `?`. |
| `method public static final character formatFileNameWithTimestamp( input filePath as character, input baseDateTime as datetime-tz )` | Igual ao anterior, com a data e hora informadas |

**Método privado:** `getRequiredFullPathName(filePath)` — helper que valida existência e lança `ThlError`; usado por `loadFileAsBase64`.

---

## PaginationHelper

**Caminho:** `thl-lib\util\pagination\PaginationHelper.cls`

**Namespace ABL:** `thl-lib.util.pagination.PaginationHelper`

**Responsabilidade:** Infraestrutura reutilizável de paginação offset-based. Encapsula o controle de skip/stop para queries `FOR EACH` paginadas. Extraído de `LpcoService` em 2026-07-25 (P1 — SRP). Sem dependências THL.

**Diretiva de erro:** `block-level on error undo, throw.`

**Padrão de projeto:** Helper (composição — Services instanciam sem consumir slot de herança).

> ⚠️ **Bug (QA 2026-09-17):** No construtor, `this-object:pageSize` recebe o valor do parâmetro **antes** da normalização `if pageSize < 1 then assign pageSize = 1`. Se caller passar `pageSize=0`, a property privada fica 0 enquanto `skipCount` é calculado com o local já corrigido. `shouldStopPaging()` usa a property — com valor 0, toda paginação para na primeira entrada.

**Construtor:**

| Assinatura | Descrição |
|---|---|
| `constructor public PaginationHelper( pageSize as integer, pageOffset as integer )` | Configura paginação no instante da criação: normaliza limites, calcula `skipCount = (pageOffset - 1) * pageSize`, reseta `entryCount`. |

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public void incrementPageCount()` | Incrementa o contador de entradas processadas. Chamar uma vez por iteração do `FOR EACH`. |
| `method public logical shouldSkipEntry()` | `true` se a entrada corrente está antes do offset — o caller deve `NEXT`. |
| `method public logical shouldStopPaging()` | `true` se a página já foi preenchida — o caller deve `LEAVE`. |

**Exemplo de uso (padrão canônico — Message cria, Service recebe):**
```
/* Na Message (methodGet): */
lpcoService:get( new PaginationHelper( pageSize, pageOffset ), ini, fin )

/* No Service (get): */
method public JsonArray get ( pager as PaginationHelper, ... ).
    for each registro no-lock.
        pager:incrementPageCount().
        if pager:shouldSkipEntry()  then next.
        if pager:shouldStopPaging() then leave.
        /* ... monta resposta ... */
    end.
end method.
```

**Usado por:** `LpcoService`, `ItemService`, `EmailService`, `MensageriaService`, `CentroCustoService`, `MensageriaConteudoService`, `AuditoriaService` (Services) + `LpcoMessage`, `AuditoriaMessage`, `EmailMessage`, `MensageriaMessage` (Messages).

---

## SchemaUtil

**Caminho:** `thl-lib\util\schema\SchemaUtil.cls`

**Namespace ABL:** `thl-lib.util.schema.SchemaUtil`

**Responsabilidade:** Consulta o Data Dictionary do OpenEdge via handles dinâmicos de schema (tabelas `_File`, `_Index`, `_Index-field`, `_Field`) para localizar os campos do índice `PRIMARY` de uma tabela e retornar propriedades completas dos campos. Classe pura de consulta — sem efeitos colaterais, sem escrita em banco. Declarada `serializable`.

**Diretiva de erro:** `block-level on error undo, throw.`

**Padrão de projeto:** Métodos `STATIC FINAL` (mesmo padrão de `StringUtil` e `FileUtil`).

**Dependências diretas THL:** `ThlError` (apenas em `getFieldSchema`).

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public static final longchar getPrimaryIndexFieldsAsJson( input databaseName as character, input tableName as character )` | Retorna os campos do índice PRIMARY único como JSON array (ex: `["cod-empresa","num-embarque"]`). Retorna `'[]'` para qualquer falha. Não propaga exceção. |
| `method public static final character getPrimaryIndexfieldsName( input databaseName as character, input tableName as character )` | Compatibilidade: retorna os campos do índice PRIMARY concatenados por vírgula (`"campo1,campo2"`). Retorna `''` para qualquer falha. Não propaga exceção. Prefira `getPrimaryIndexFieldsAsJson` para output serializado. |
| `method public static final void getFieldSchema( input databaseName as character, input tableName as character, output table for ttFieldSchema )` | Retorna **todos os campos** da tabela com suas propriedades completas. **Lança `ThlError`** se `databaseName`/`tableName` forem inválidos, se o banco não estiver conectado, ou se a tabela não existir. TT ordenada por `field-order` (`_Field._Order`). |

**Temp-table de retorno — `ttFieldSchema`** (definida como `define static temp-table` no body da classe):

| Campo TT | Tipo | Campo `_Field` | Observação |
|---|---|---|---|
| `field-name` | CHARACTER | `_Field-name` | Nome do campo |
| `data-type_` | CHARACTER | `_Data-type` | Sufixo `_` evita conflito com ABL |
| `field-format` | CHARACTER | `_Format` | Formato de display |
| `label_` | CHARACTER | `_Label` | Sufixo `_` evita conflito com ABL |
| `column-label_` | CHARACTER | `_Col-label` | Sufixo `_` evita conflito com ABL |
| `mandatory_` | LOGICAL | `_Mandatory` | Sufixo `_` evita conflito com ABL |
| `extent_` | INTEGER | `_Extent` | 0 = escalar; ≥1 = array. Sufixo `_` |
| `initial-value` | CHARACTER | `_Initial` | Valor padrão |
| `description_` | CHARACTER | `_Desc` | Sufixo `_` evita conflito com ABL |
| `field-order` | INTEGER | `_Order` | Ordem de definição no schema |

> ⚠️ Campos com sufixo `_` (`data-type_`, `label_`, `column-label_`, `mandatory_`, `extent_`, `description_`) — necessário porque os nomes sem sufixo são palavras reservadas ou colidem com atributos ABL. O caller **deve** definir a TT com os mesmos nomes incluindo o `_` para que `OUTPUT TABLE FOR` funcione.

**Sequência interna de acesso ao schema (getPrimaryIndex*):**
1. `CREATE BUFFER FOR TABLE '{banco}._File'` → `FIND-FIRST WHERE _File-name = tabela`
2. `CREATE BUFFER FOR TABLE '{banco}._Index'` → `FIND-FIRST WHERE _File-recid = ... AND _Unique = TRUE`
3. `CREATE BUFFER FOR TABLE '{banco}._Index-field'` e `'{banco}._Field'`
4. Loop `DO fieldOrder = 1 TO _Num-comp` → resolve `_Field-name` via `FIND-FIRST WHERE recid(_Field) = _Field-recid`

**Tratamento de erro:**
- `getPrimaryIndex*`: `DO ON ERROR UNDO, RETURN ''/[]':` suprime qualquer erro; FINALLY libera 4 handles.
- `getFieldSchema`: lança `ThlError` via `UNDO, THROW NEW ThlError(...)` para erros de input e banco/tabela não encontrada; FINALLY libera query + 2 handles mesmo em caso de exceção.
- Todos os acessos a `_File`/`_Field` usam `CREATE BUFFER ... NO-ERROR` + verificação `VALID-HANDLE` / `:AVAILABLE` antes de prosseguir.
- Sem `CONNECT` explícito — acessa banco já conectado pelo nome (correto para PASOE multi-agente).

**Exemplo de uso — getFieldSchema:**
```abl
using thl-lib.util.schema.SchemaUtil.

define temp-table ttFieldSchema no-undo
    field field-name    as character
    field data-type_    as character
    field field-format  as character
    field label_        as character
    field column-label_ as character
    field mandatory_    as logical
    field extent_       as integer   initial 0
    field initial-value as character
    field description_  as character
    field field-order   as integer   initial 0
    index ix-order is primary unique field-order.

SchemaUtil:getFieldSchema('ems2cad', 'emitente', output table ttFieldSchema).

for each ttFieldSchema no-lock by ttFieldSchema.field-order:
    display ttFieldSchema.field-name ttFieldSchema.data-type_.
end.
```

---

## JsonArrayCsvExporter

**Caminho:** `thl-lib\util\export\JsonArrayCsvExporter.cls`

**Namespace ABL:** `thl-lib.util.export.JsonArrayCsvExporter`

**Responsabilidade:** Exporta um `JsonArray` de `JsonObject` para arquivo CSV. Cada objeto do array vira uma linha. Colunas podem ser auto-detectadas (propriedades do primeiro objeto) ou informadas explicitamente. Valores com delimitador, aspas ou quebra de linha são escapados conforme RFC 4180.

**Diretiva de erro:** `block-level on error undo, throw.`

**Dependências diretas THL:** Nenhuma.

**Construtores:**

| Assinatura | Descrição |
|---|---|
| `constructor public JsonArrayCsvExporter()` | Delimitador padrão: `';'`. |
| `constructor public JsonArrayCsvExporter( input pDelimiter as character )` | Delimitador customizado. |

**Properties públicas:**

| Property | Tipo | Descrição |
|---|---|---|
| `delimiter` | CHARACTER | Delimitador CSV (read-only após construção). |

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public character export( input data as JsonArray, input filePath as character )` | Exporta com colunas auto-detectadas do primeiro objeto. Retorna `filePath`. Grava arquivo vazio se array vazio. |
| `method public character exportData( input data as JsonArray, input filePath as character, input columns_ as character )` | Exporta com colunas explícitas (lista separada por vírgula). Retorna `filePath`. |

**Tipos JSON suportados:** `STRING`, `NUMBER` (via `GetInt64`), `BOOLEAN`. Outros tipos retornam `''`.

**Exemplo de uso:**
```abl
using thl-lib.util.export.JsonArrayCsvExporter.
using thl-lib.util.scanner.FileScanner.
using thl-lib.util.scanner.ScannedFileSet.

define variable exporter as JsonArrayCsvExporter no-undo.
define variable scanner  as FileScanner          no-undo.
define variable fileSet  as ScannedFileSet       no-undo.

assign scanner = new FileScanner().
scanner:addDirectory( 'C:\fontes\customizacao' ).
assign fileSet = scanner:scan().

assign exporter = new JsonArrayCsvExporter( ',' ).
exporter:export( fileSet:toJsonArray(), 'C:\output\resultado.csv' ).
```

---

## Pacote scanner/ — arquitetura OO

**Caminho:** `thl-lib\util\scanner\` (4 classes)

**Namespace ABL:** `thl-lib.util.scanner.*`

**Responsabilidade:** Descoberta genérica de arquivos e enriquecimento extensível. Sem conhecimento de ABL, tabelas ou compilação. Contrato tipado via `ScannedFileSet` (temp-table interna); conversão para `JsonArray` apenas na borda de saída (`toJsonArray`).

### Arquitetura

```
FileScanner (produtor)
  └──► ScannedFileSet (contrato tipado — temp-table ttScannedFile)
           ▲
           │  enrich(fileSet)
       IFileEnricher (interface)
           │
       FileContentSearcher (implementação — busca textual)
```

### ScannedFileSet (coleção tipada)

**Caminho:** `thl-lib\util\scanner\ScannedFileSet.cls`

**Diretiva de erro:** `block-level on error undo, throw.`

**Responsabilidade:** Coleção tipada de arquivos varridos. Contrato central entre o produtor (`FileScanner`) e consumidores (`IFileEnricher`). Encapsula `ttScannedFile` com campos de descoberta e enriquecimento. Buffer separado (`bUpdateFile`) para atualização sem quebrar iteração do query.

**Padrão de projeto:** Collection / Typed Contract.

**Construtor:** `ScannedFileSet()` — sem parâmetros.

**Temp-table `ttScannedFile` (campos tipados):**

| Campo | Tipo ABL | Descrição |
|---|---|---|
| `fullPath` | CHARACTER (PK) | Caminho completo do arquivo |
| `fileName` | CHARACTER | Nome do arquivo |
| `folderName` | CHARACTER | Diretório pai |
| `extension` | CHARACTER | Extensão em lowercase |
| `fileSize` | INT64 | Tamanho em bytes |
| `lastModified` | DATE | Data de modificação |
| `rootDirectory` | CHARACTER | Diretório raiz de origem |
| `relativePath` | CHARACTER | Caminho relativo ao rootDirectory |
| `excluded` | LOGICAL | Excluído por padrão? |
| `excludedPattern` | CHARACTER | Padrão que causou a exclusão |
| `searchText` | CHARACTER | Texto pesquisado (preenchido pelo enricher) |
| `found` | LOGICAL | Texto localizado? |
| `matchCount` | INTEGER | Quantidade de ocorrências |
| `firstMatchLine` | INTEGER | Linha da primeira ocorrência |

**Properties públicas:**

| Property | Tipo | Descrição |
|---|---|---|
| `fileCount` | INTEGER | Total de arquivos na coleção (read-only) |
| `excludedCount` | INTEGER | Total de excluídos (read-only) |
| `matchedFileCount` | INTEGER | Arquivos onde found = true (read-only) |
| `totalMatchCount` | INTEGER | Soma de matchCount (read-only) |

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `addFile( fileName, fullPath, folderName, extension, fileSize, lastModified, rootDirectory, relativePath, excluded, excludedPattern )` | Adiciona arquivo à coleção. |
| `openQuery()` | Abre cursor para iteração (usar com `getNext`). |
| `getNext( OUTPUT fullPath, OUTPUT excluded ) : LOGICAL` | Avança cursor; retorna FALSE quando não há mais registros. |
| `getNextDetail( OUTPUT fullPath, OUTPUT fileName, OUTPUT extension, OUTPUT excluded, OUTPUT found ) : LOGICAL` | Avança cursor com campos detalhados para consumidores que precisam de mais contexto. |
| `setSearchResult( fullPath, searchText, found, matchCount, firstMatchLine )` | Atualiza resultado de busca de um arquivo (usa buffer separado). |
| `toJsonArray() : JsonArray` | Converte toda a coleção para JsonArray (borda de saída). |
| `reset()` | Limpa coleção e contadores. |

---

### IFileEnricher (interface)

**Caminho:** `thl-lib\util\scanner\IFileEnricher.cls`

**Responsabilidade:** Ponto de extensão para qualquer enriquecimento de um `ScannedFileSet`. Busca textual é uma implementação; futuras (classificação, contagem de linhas, etc.) seguem o mesmo contrato.

| Assinatura | Descrição |
|---|---|
| `enrich( fileSet as ScannedFileSet )` | Processa e enriquece os arquivos da coleção. |

---

### FileScanner (produtor)

**Caminho:** `thl-lib\util\scanner\FileScanner.cls`

**Diretiva de erro:** `block-level on error undo, throw.`

**Responsabilidade:** Varre N diretórios recursivamente via `INPUT FROM OS-DIR` (fila interna via `ttPendingDirectory`, não recursão) e produz um `ScannedFileSet` tipado. Não conhece busca textual — pura descoberta de sistema de arquivos.

**Padrão de projeto:** Producer / Builder.

**Construtor:** `FileScanner()` — sem parâmetros.

**Dependências diretas THL:** `LogUtil`.

**Properties públicas:**

| Property | Tipo | Default | Descrição |
|---|---|---|---|
| `fileExtensions` | CHARACTER | `''` (todos) | Extensões separadas por vírgula, padrões com wildcard (ex.: `'w,p,cls,i*'`) |

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `addDirectory( directoryPath as CHARACTER )` | Adiciona diretório raiz para varredura; pode ser chamado N vezes. Duplicatas ignoradas. Path normalizado (trailing slashes removidos). |
| `addExclusionPattern( pattern as CHARACTER )` | Adiciona padrão MATCHES para excluir arquivos (ex.: `'*Bkp*'`, `'*Old*'`). Arquivos excluídos são incluídos no resultado com `excluded = true`. |
| `scan() : ScannedFileSet` | Executa a varredura e retorna coleção tipada. Loga contagem via `LogUtil`. |
| `reset()` | Limpa diretórios, padrões e extensões. |

---

### FileContentSearcher (enricher — busca textual)

**Caminho:** `thl-lib\util\scanner\FileContentSearcher.cls`

**Diretiva de erro:** `block-level on error undo, throw.`

**Responsabilidade:** Implementação de `IFileEnricher` que busca uma palavra-chave no conteúdo de cada arquivo. Arquivos com `excluded = true` são ignorados (marcados como `found = false`). Busca por word-boundary quando delimitadores preenchido; substring pura quando vazio.

**Padrão de projeto:** Enricher (implementa `IFileEnricher`).

**Dependências diretas THL:** `LogUtil`.

**Construtor:** `FileContentSearcher( searchText as CHARACTER, delimiters as CHARACTER )` — configuração imutável.

**Properties públicas:**

| Property | Tipo | Descrição |
|---|---|---|
| `searchText` | CHARACTER | Texto de busca (read-only, definido no construtor) |
| `delimiters` | CHARACTER | Delimitadores separados por vírgula (read-only, definido no construtor) |

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `enrich( fileSet as ScannedFileSet )` | Busca `searchText` nos arquivos do fileSet. Atualiza `searchText`, `found`, `matchCount`, `firstMatchLine` via `setSearchResult`. Loga contagem via `LogUtil`. |

---

### Pipeline completo

```
FileScanner:scan()              → ScannedFileSet (contrato tipado)
FileContentSearcher:enrich()    → ScannedFileSet (enriquecido com busca)
ScannedFileSet:toJsonArray()    → JsonArray (borda de saída — 14 propriedades)
```

### Exemplo de uso

```abl
using Progress.Json.ObjectModel.JsonArray.
using thl-lib.util.scanner.FileScanner.
using thl-lib.util.scanner.FileContentSearcher.
using thl-lib.util.scanner.ScannedFileSet.

define variable scanner  as FileScanner         no-undo.
define variable searcher as FileContentSearcher no-undo.
define variable fileSet  as ScannedFileSet      no-undo.
define variable result   as JsonArray           no-undo.

assign scanner = new FileScanner().
scanner:addDirectory( 'C:\fontes\customizacao' ).
scanner:addExclusionPattern( '*Bkp*' ).
assign scanner:fileExtensions = 'w,p,cls,i*'.

assign fileSet  = scanner:scan()
       searcher = new FileContentSearcher( 'es_ped_venda', ' ,~t,.,:', ).

searcher:enrich( fileSet ).

assign result = fileSet:toJsonArray().

message 'Arquivos:' fileSet:fileCount
        'Match:' fileSet:matchedFileCount
        'Ocorrencias:' fileSet:totalMatchCount
    view-as alert-box.
```

**Sem dependência de banco** — utilitário puro de sistema de arquivos.

---

## Pacote compile/ — compilação ABL

**Caminho:** `thl-lib\util\compile\` (3 classes)

**Namespace ABL:** `thl-lib.util.compile.*`

**Responsabilidade:** Fachada ABL-específica que combina o pipeline de scanner (FileScanner + FileContentSearcher) com compilação. Retorna `JsonArray` enriquecido com atributos de compilação por arquivo. Conhece delimitadores ABL (espaço, tab, `.`, `:`) e strip de qualificador de banco.

**Padrão de projeto:** Facade (`TableImpactCompiler`) + Value-Object (`CompilationResult`).

### CompilationResult (value-object)

**Caminho:** `thl-lib\util\compile\CompilationResult.cls`

**Diretiva de erro:** `block-level on error undo, throw.`

**Construtor:** `CompilationResult( filePath as character )` — inicializa com `succeeded = false`.

**Properties:**

| Property | Tipo | Acesso | Descrição |
|---|---|---|---|
| `filePath` | CHARACTER | public get, **private set** | Caminho do arquivo compilado |
| `succeeded` | LOGICAL | public get, **private set** | Compilação bem-sucedida? |
| `errorMessage` | CHARACTER | public get, **private set** | Mensagens de erro concatenadas |
| `errorFile` | CHARACTER | public get, **private set** | Arquivo onde o erro ocorreu (pode ser include) |
| `errorRow` | INTEGER | public get, **private set** | Linha do erro |
| `errorColumn` | INTEGER | public get, **private set** | Coluna do erro |

**Métodos:** `setSuccess()`; `setError( pErrorMessage as character, … )` (com arquivo/linha/coluna) e `setError( pErrorMessage as character )`.

> ✅ Risco do QA de 2026-09-17 (`public set`) **resolvido**: as propriedades agora são `private set` e só mudam por `setSuccess`/`setError` (sincronizado em 2026-09-24).

### ProgramCompiler

**Caminho:** `thl-lib\util\compile\ProgramCompiler.cls`

**Diretiva de erro:** `block-level on error undo, throw.`

**Dependências diretas THL:** `ErrorHandler`, `LogUtil`, `StringUtil`.

**Construtor:** `ProgramCompiler( saveDirectory as character )` — diretório destino do r-code (vazio = ao lado do fonte).

`compileFile(filePath)` executa `COMPILE value(filePath) SAVE NO-ERROR` e captura:
- `COMPILER:ERROR` / `COMPILER:ERROR-ROW` / `COMPILER:ERROR-COLUMN` / `COMPILER:FILE-NAME`
- `ERROR-STATUS:GET-MESSAGE(i)` para todas as mensagens

Nunca propaga exceção — CATCH interno retorna `CompilationResult` com erro. Loga resultado via `LogUtil`.

### TableImpactCompiler (fachada)

**Caminho:** `thl-lib\util\compile\TableImpactCompiler.cls`

**Diretiva de erro:** `block-level on error undo, throw.`

**Dependências diretas THL:** `ErrorHandler`, `ThlError`, `FileScanner`, `FileContentSearcher`, `ScannedFileSet`, `ProgramCompiler`, `CompilationResult`.

**Construtor:** `TableImpactCompiler()` — sem parâmetros.

**Constantes privadas:**
- `ABL_DELIMITERS = ' ,~t,.,:' ` — delimitadores para busca por word-boundary
- `ABL_EXTENSIONS = 'w,p,cls,i*'` — extensões ABL para varredura

**Properties públicas:**

| Property | Tipo | Default | Descrição |
|---|---|---|---|
| `saveDirectory` | CHARACTER | `''` | Diretório de destino do r-code (vazio = ao lado do fonte). |

**Métodos públicos — busca simples (passada única):**

| Assinatura | Descrição |
|---|---|
| `method public JsonArray execute( input searchText as character )` | Busca direta com os diretórios acumulados via `addDirectory`. Retorna `JsonArray` enriquecido. |
| `method public JsonArray execute( input rootDirectory as character, input searchText as character )` | Busca direta em diretório único, r-code ao lado do fonte. |
| `method public JsonArray execute( input rootDirectory as character, input searchText as character, input pSaveDirectory as character )` | Busca direta em diretório único com destino do r-code. |

**Métodos públicos — busca de tabela (duas passadas):**

| Assinatura | Descrição |
|---|---|
| `method public JsonArray executeForTable( input tableName as character )` | Duas passadas com diretórios acumulados. Strip de qualificador de banco (`erp.pedido` → `pedido`). |
| `method public JsonArray executeForTable( input rootDirectory as character, input tableName as character )` | Duas passadas em diretório único. |
| `method public JsonArray executeForTable( input rootDirectory as character, input tableName as character, input pSaveDirectory as character )` | Duas passadas com destino do r-code. |

**Métodos públicos — configuração:**

| Assinatura | Descrição |
|---|---|
| `addDirectory( directoryPath as CHARACTER )` | Adiciona diretório para varredura (multi-diretório). Duplicatas ignoradas. |
| `addExclusionPattern( pattern as CHARACTER )` | Adiciona padrão MATCHES para excluir arquivos. |
| `reset()` | Limpa diretórios, exclusões, properties. |

### Retorno — JsonArray enriquecido

Cada objeto do `JsonArray` retornado contém os 14 campos do `ScannedFileSet:toJsonArray()` **mais** 7 atributos de compilação:

| Atributo | Tipo | Descrição |
|---|---|---|
| `compiled` | LOGICAL | `true` se o arquivo foi compilado (programa com match) |
| `reason` | CHARACTER | Motivo da compilação: `'direct'` ou nome do include que causou |
| `succeeded` | LOGICAL | Compilação bem-sucedida? |
| `errorMessage` | CHARACTER | Mensagem de erro de compilação |
| `errorFile` | CHARACTER | Arquivo onde o erro ocorreu |
| `errorRow` | INTEGER | Linha do erro |
| `errorColumn` | INTEGER | Coluna do erro |

### Arquitetura — pipeline

**`execute` (passada única):**
```
FileScanner:scan()                → ScannedFileSet
    ▼
FileContentSearcher:enrich()      → busca com word-boundary (ABL_DELIMITERS)
    ▼
compila programas (.w/.p/.cls)    → ProgramCompiler:compileFile()
    ▼
enrichResult()                    → JsonArray com 14 + 7 atributos
```

**`executeForTable` (duas passadas):**
```
Passada 1: FileContentSearcher busca tableName (word-boundary)
    ▼
Coleta programas com match direto + includes (.i*) com match
    ▼
Passada 2: Para cada include afetado, nova busca substring
           nos programas restantes
    ▼
Compila a união (diretos + via include)
    ▼
enrichResult() → JsonArray com 14 + 7 atributos
```

**Exemplos de uso:**

```abl
using thl-lib.util.compile.TableImpactCompiler.
using thl-lib.util.export.JsonArrayCsvExporter.
using Progress.Json.ObjectModel.JsonArray.

define variable compiler_ as TableImpactCompiler   no-undo.
define variable exporter  as JsonArrayCsvExporter   no-undo.
define variable result    as JsonArray              no-undo.

/* Busca simples por programa ou include */
assign compiler_ = new TableImpactCompiler()
       result    = compiler_:execute( 'C:\fontes\customizacao', 'es_ped_venda' ).

/* Busca por tabela (duas passadas) — multi-diretório */
assign compiler_ = new TableImpactCompiler().
compiler_:addDirectory( 'C:\fontes\customizacao' ).
compiler_:addDirectory( 'C:\fontes\padrao' ).
compiler_:addExclusionPattern( '*Bkp*' ).
assign compiler_:saveDirectory = 'C:\compilados'
       result = compiler_:executeForTable( 'erp.pedido' ).

/* Exportar resultado para CSV */
assign exporter = new JsonArrayCsvExporter( ',' ).
exporter:export( result, 'C:\output\impacto.csv' ).
```

## StringUtil — `parseDateTime` (2026-10-03, não compilado)

`method public static final datetime parseDateTime( input dateString as character, input defaultValue as datetime )` — lê **somente** `yyyy-MM-ddTHH:mm` (hora local, sem segundos e sem fuso). Vazio ou `?` devolve `defaultValue`; qualquer outro formato lança `ThlError` ("Data e hora invalida…"). A classe passou a usar `thl-lib.core.error.ThlError`. Usado só pelas rotas de métricas ([extensions/thl.md](../extensions/thl.md)). O `parseDate` não mudou: continua devolvendo meia-noite e falha com data ISO que traga hora.

## JsonUtil — `requireProperties` (2026-10-03, não compilado)

`method public static final void requireProperties( input json as JsonObject, input propertyList as character, input ownerName as character )` — exige que o JSON traga todas as propriedades da lista (separada por vírgula); confere só a presença. Faltando alguma, lança `ThlError( ownerName, 'requireProperties', 'Campo obrigatorio nao informado: …' )` (17006) com todas as ausentes. Usado pelos Services de cadastro do THL em `initialize()`. A classe passou a usar `thl-lib.core.error.ThlError`.

## `JsonUtil:nameListToCsv` (2026-10-05, não compilado)

`method public static final character nameListToCsv( input jsonText as character )` — lista de nomes gravada no cadastro como array JSON de texto (`["a","b"]`) → nomes separados por vírgula. Em branco ou `[]` devolve `''`. JSON mal formado, valor que não é array ou item que não é texto lança `ThlError`. Usado por `InboundMessage` (campos obrigatórios e chave externa), `ObjetoParametroService` e pelo `Pi-validate` da aba REST (`thl0022a-v05.w`).
