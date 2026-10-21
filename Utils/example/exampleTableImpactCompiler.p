/*------------------------------------------------------------------------
    File        : exampleTableImpactCompiler.p
    Purpose     : Exemplo de uso do TableImpactCompiler com
                  JsonArrayCsvExporter.
                  Cenarios:
                  1) executeForTable — tabela (duas passadas) + CSV
                  2) execute — programa (passada unica) + CSV
                  3) executeForTable com rootDirectory

    Syntax      : RUN Utils/example/exampleTableImpactCompiler.p

    Author(s)   : Lopes
    Created     : 2026-09-16
    Notes       : Ajuste os caminhos conforme o seu ambiente.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.JsonArray.
using thl-lib.util.compile.TableImpactCompiler.
using thl-lib.util.export.JsonArrayCsvExporter.

//Definitions
define variable compiler_ as TableImpactCompiler  no-undo.
define variable exporter  as JsonArrayCsvExporter no-undo.
define variable result    as JsonArray            no-undo.
define variable csvPath   as character            no-undo.

//Main Block
assign compiler_ = new TableImpactCompiler()
       exporter  = new JsonArrayCsvExporter( ';' ).

compiler_:addDirectory( '\\10.55.7.242\datasul\dts11\ERP\Espec\NITRO\ems2' ).
compiler_:addDirectory( '\\10.55.7.242\datasul\dts11\ERP\Espec\NITRO\ems5' ).
compiler_:addDirectory( '\\10.55.7.242\datasul\dts11\ERP\Espec\NITRO\hcm'  ).
compiler_:addDirectory( '\\10.55.7.242\datasul\dts11\ERP\Espec\NITRO\THL-Library' ).

compiler_:addExclusionPattern( '*Bkp*' ).
compiler_:addExclusionPattern( '*Old*' ).
compiler_:addExclusionPattern( '*Antigo*' ).

assign result  = compiler_:executeForTable( 'es_ped_venda' )
       csvPath = exporter:export( result, 'c:\temp\impact-tabela.csv' ).

message 'Cenario 1 a Tabela (duas passadas)' skip
        'Busca: "es_ped_venda"'              skip
        'Registros:' result:Length           skip
        'CSV em:' csvPath
    view-as alert-box information.

/*
/* ------------------------------------------------------------------ */
/* Cenario 2: Programa — passada unica                                */
/*   Busca "ut-acomp" nos fontes e compila programas encontrados.     */
/*   Nao faz busca de includes (nao se aplica a programas).           */
/* ------------------------------------------------------------------ */

assign result  = compiler_:execute( 'ut-acomp' )
       csvPath = exporter:export( result, 'c:\temp\impact-programa.csv' ).

message
    'Cenario 2 — Programa (passada unica)' skip(1)
    'Busca: "ut-acomp"' skip
    'Registros:' result:Length skip
    'CSV em:' csvPath
    view-as alert-box information.


/* ------------------------------------------------------------------ */
/* Cenario 3: Tabela com rootDirectory (sem addDirectory)             */
/*   Variante que recebe diretorio direto no metodo.                  */
/* ------------------------------------------------------------------ */

assign result  = compiler_:executeForTable(
                    '\\10.55.7.242\datasul\dts11\ERP\Espec\NITRO\ems2',
                    'es_pedido_venda' )
       csvPath = exporter:export( result, 'c:\temp\impact-tabela-ems2.csv' ).

message
    'Cenario 3 — Tabela com rootDirectory' skip(1)
    'Busca: "es_pedido_venda"' skip
    'Diretorio: ems2' skip
    'Registros:' result:Length skip
    'CSV em:' csvPath
    view-as alert-box information.*/
