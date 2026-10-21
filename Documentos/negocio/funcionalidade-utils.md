# Funcionalidade Utils — utilitários de uso geral da THL

Conjunto de classes prontas que **qualquer programa** (`.p` ou `.cls`) pode chamar para resolver tarefas comuns de customização: tratar texto e datas, ler e gerar JSON, trabalhar com arquivos, consultar o dicionário de dados, exportar CSV, varrer fontes e compilar programas. Nenhuma delas exige cadastro prévio na THL; basta declarar o `using` e chamar.

Os exemplos abaixo são **simples e só ilustram a chamada**. Não foram compilados nem executados para este guia; a assinatura completa de cada método está em [util/util.md](../.claude/util/util.md).

> A paginação das consultas REST (`PaginationHelper`) não está aqui: ela só serve à integração de entrada e é explicada em [funcionalidade-integracao.md](funcionalidade-integracao.md).

## Quando usar

| Preciso de… | Use |
|---|---|
| Evitar erro com valor desconhecido (`?`), formatar ou ler data | `StringUtil` |
| Calcular uma data e hora (24 horas atrás, daqui a 3 dias) | `DateTimeUtil` |
| Ler campos de um JSON para variáveis | `JsonSetter` |
| Transformar dados do banco em JSON | `JsonWriter` |
| Saber se um JSON tem certos campos | `JsonUtil` |
| Conferir ou ler um arquivo (por exemplo, para anexar) | `FileUtil` |
| Descobrir campos e chave primária de uma tabela | `SchemaUtil` |
| Gerar um arquivo CSV a partir de uma lista | `JsonArrayCsvExporter` |
| Achar quais fontes usam uma palavra ou tabela | `FileScanner` e `FileContentSearcher` |
| Descobrir e compilar os programas afetados por uma tabela | `TableImpactCompiler` |

## Texto e datas — `StringUtil`

Trata texto e datas de forma segura. O principal uso é proteger contra valor desconhecido (`?`), que costuma derrubar um programa.

```abl
using thl-lib.util.string.StringUtil.

define variable nome as character no-undo.

/* devolve '' em vez de ? */
assign nome = StringUtil:getText( 'ABC' ).

/* testa se há conteúdo (não vazio) */
if StringUtil:hasValue( nome ) then
    message 'Preenchido' view-as alert-box.

/* data no formato ISO: 2026-10-21 */
message StringUtil:formatIsoDate( today ) view-as alert-box.
```

## Datas e horas — `DateTimeUtil`

Soma ou subtrai horas, dias, meses e anos. Quantidade negativa volta no tempo. É o padrão usado nas consultas de "últimas 24 horas".

```abl
using thl-lib.util.date.DateTimeUtil.

define variable inicio as datetime no-undo.

/* 24 horas atrás */
assign inicio = DateTimeUtil:addHours( now, -24 ).

/* daqui a 7 dias */
assign inicio = DateTimeUtil:addDays( now, 7 ).
```

## Ler JSON — `JsonSetter`

Copia campos de um JSON para variáveis. Se o campo não existir, a variável **mantém o valor que já tinha**, sem erro. Aceita texto, número, decimal, data e lógico.

```abl
using Progress.Json.ObjectModel.JsonObject.
using thl-lib.util.json.JsonSetter.

define variable payload as JsonObject no-undo.
define variable setter  as JsonSetter no-undo.
define variable placa   as character  no-undo.
define variable peso    as decimal    no-undo.

assign payload = new JsonObject().
payload:Add( 'placa', 'ABC1234' ).

assign setter = new JsonSetter( payload ).
setter:SetValue( input-output placa, 'placa' ).
setter:SetValue( input-output peso,  'peso' ).   /* ausente: peso não muda */
```

## Gerar JSON — `JsonWriter`

Transforma o registro de um buffer em JSON, ou uma lista separada por vírgula em um array.

```abl
using thl-lib.util.json.JsonWriter.

/* lista vira array: ["a","b","c"] */
message string( JsonWriter:charListToJsonArray( 'a,b,c' ) ) view-as alert-box.

/* registro de uma tabela vira JSON */
find first ped-venda no-lock no-error.
if available ped-venda then
    message string( JsonWriter:toJsonFromBuffer( buffer ped-venda:handle ) )
        view-as alert-box.
```

## Consultar um JSON — `JsonUtil`

Responde se o JSON tem ao menos um dos campos informados. Serve, por exemplo, para recusar uma alteração (PATCH) sem nenhum campo útil.

```abl
using thl-lib.util.json.JsonUtil.

if not JsonUtil:hasAnyProperty( payload, 'placa,motorista' ) then
    message 'Informe placa ou motorista' view-as alert-box.
```

## Arquivos — `FileUtil`

Confere se um arquivo existe e o lê em Base64, formato exigido por muitas APIs para enviar anexos.

```abl
using thl-lib.util.file.FileUtil.

define variable conteudo as longchar no-undo.

if FileUtil:exists( 'C:\temp\nota.pdf' ) then
    assign conteudo = FileUtil:loadFileAsBase64( 'C:\temp\nota.pdf' ).
```

## Dicionário de dados — `SchemaUtil`

Descobre a estrutura de uma tabela em tempo de execução: os campos da chave primária e as propriedades de cada campo (tipo, formato, rótulo).

```abl
using thl-lib.util.schema.SchemaUtil.

/* campos da chave primária, separados por vírgula */
message SchemaUtil:getPrimaryIndexfieldsName( 'ems2cad', 'emitente' )
    view-as alert-box.
```

Para a lista completa de campos (`getFieldSchema`), o programa precisa definir a temp-table `ttFieldSchema`; o exemplo está em [util/util.md](../.claude/util/util.md).

## Exportar CSV — `JsonArrayCsvExporter`

Grava um arquivo CSV a partir de uma lista de objetos JSON. Cada objeto vira uma linha; as colunas saem do primeiro objeto, ou de uma lista informada.

```abl
using Progress.Json.ObjectModel.JsonArray.
using thl-lib.util.export.JsonArrayCsvExporter.

define variable exporter as JsonArrayCsvExporter no-undo.

assign exporter = new JsonArrayCsvExporter( ';' ).
exporter:export( dados, 'C:\temp\resultado.csv' ).   /* dados é um JsonArray */
```

## Varrer fontes — `FileScanner` e `FileContentSearcher`

O `FileScanner` lista os arquivos de uma ou mais pastas (inclusive subpastas), filtrando por extensão. O `FileContentSearcher` marca quais deles contêm um texto. Juntos respondem "quais fontes usam esta tabela ou campo?".

```abl
using thl-lib.util.scanner.FileScanner.
using thl-lib.util.scanner.FileContentSearcher.
using thl-lib.util.scanner.ScannedFileSet.

define variable scanner  as FileScanner         no-undo.
define variable searcher as FileContentSearcher no-undo.
define variable fileSet  as ScannedFileSet      no-undo.

assign scanner = new FileScanner().
scanner:addDirectory( 'C:\fontes\customizacao' ).
assign scanner:fileExtensions = 'w,p,cls,i*'.

assign fileSet  = scanner:scan()
       searcher = new FileContentSearcher( 'es_ped_venda', ' ,~t,.,:', ).
searcher:enrich( fileSet ).

message 'Arquivos com a tabela:' fileSet:matchedFileCount view-as alert-box.
```

## Impacto de uma tabela — `TableImpactCompiler`

Reúne a varredura, a busca e a compilação: informa quais programas usam uma tabela (direto ou por include) e se **ainda compilam**. O resultado é uma lista JSON que pode ser exportada para CSV. É útil antes de alterar a estrutura de uma tabela.

```abl
using Progress.Json.ObjectModel.JsonArray.
using thl-lib.util.compile.TableImpactCompiler.
using thl-lib.util.export.JsonArrayCsvExporter.

define variable compiler_ as TableImpactCompiler  no-undo.
define variable exporter  as JsonArrayCsvExporter no-undo.
define variable result    as JsonArray            no-undo.

assign compiler_ = new TableImpactCompiler()
       result    = compiler_:executeForTable( 'C:\fontes\customizacao', 'es_ped_venda' ).

assign exporter = new JsonArrayCsvExporter( ';' ).
exporter:export( result, 'C:\temp\impacto.csv' ).
```

Cada linha do resultado traz o arquivo, se foi compilado, o motivo (direto ou por qual include) e, em caso de erro, a mensagem, o arquivo, a linha e a coluna.

## Exemplos prontos no repositório

A pasta `Utils/example/` tem programas de exemplo completos: `exampleStringUtil.p`, `exampleFileScanner.p` e `exampleTableImpactCompiler.p`.

## Limites a conhecer

- Os exemplos são ilustrativos; ajuste nomes de tabelas, pastas e variáveis ao seu caso.
- `JsonWriter:toJsonFromBuffer` devolve texto vazio, sem erro, se o buffer for inválido.
- `SchemaUtil:getFieldSchema` lança erro se o banco não estiver conectado ou a tabela não existir; os outros métodos do `SchemaUtil` devolvem vazio.
- `TableImpactCompiler` compila de verdade os programas encontrados: use em ambiente de desenvolvimento.
