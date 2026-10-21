using Progress.Json.ObjectModel.JsonArray.
using thl-lib.util.scanner.FileScanner.
using thl-lib.util.scanner.FileContentSearcher.
using thl-lib.util.scanner.ScannedFileSet.
using thl-lib.util.export.JsonArrayCsvExporter.

//Definitions
define variable scanner  as FileScanner          no-undo.
define variable fileSet  as ScannedFileSet        no-undo.
define variable searcher as FileContentSearcher   no-undo.
define variable exporter as JsonArrayCsvExporter  no-undo.
define variable csvPath  as character             no-undo.

//Main Block
assign scanner  = new FileScanner()
       exporter = new JsonArrayCsvExporter( ';' ).

scanner:addDirectory( '\\10.55.7.242\datasul\dts11\ERP\Espec\NITRO\ems2' ).
scanner:addDirectory( '\\10.55.7.242\datasul\dts11\ERP\Espec\NITRO\ems5' ).
scanner:addDirectory( '\\10.55.7.242\datasul\dts11\ERP\Espec\NITRO\hcm'  ).
scanner:addDirectory( '\\10.55.7.242\datasul\dts11\ERP\Espec\NITRO\THL-Library' ).

scanner:addExclusionPattern( '*Bkp*' ).
scanner:addExclusionPattern( '*Old*' ).
scanner:addExclusionPattern( '*Antigo*' ).

assign scanner:fileExtensions = 'i*'.

/* Cenario 1 — Varredura com filtro de extensao */

assign fileSet = scanner:scan()
       csvPath = exporter:export( fileSet:toJsonArray(),
                                   'c:\temp\scanner-varredura.csv' ).

message 'Cenario 1 — Varredura'                 skip
        'Total:' fileSet:fileCount              skip
        'Excluidos:' fileSet:excludedCount      skip
        'CSV em:' csvPath
    view-as alert-box information.


/* Cenario 2 — Busca textual com delimiters (word-boundary) */

assign searcher = new FileContentSearcher( 'es_ped_venda', ' ,~t,.,:' ).

searcher:enrich( fileSet ).

assign csvPath = exporter:export( fileSet:toJsonArray(), 'c:\temp\scanner-busca.csv' ).

message 'Cenario 2 — Busca "es_ped_venda"'       skip
        'Arquivos com match:' fileSet:matchedFileCount skip
        'Total ocorrencias:' fileSet:totalMatchCount   skip
        'CSV em:' csvPath
    view-as alert-box information.
