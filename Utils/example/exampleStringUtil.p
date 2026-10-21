/*------------------------------------------------------------------------
    File        : exampleStringUtil.p
    Purpose     : Demonstra uso tipico de StringUtil em contexto real:
                  guardar contra unknown value, formatar datas para API,
                  e parsear datas de payload JSON.
    Author(s)   : Claude (audit QA)
    Created     : 2026-09-17
    Notes       : Sem assercoes — referencia para desenvolvedores.
  ----------------------------------------------------------------------*/

using thl-lib.util.string.StringUtil.

/* Cenario 1: guardar contra unknown value antes de concatenar */

define variable nomeEmitente as character no-undo initial ?.

message 'Nome seguro:' StringUtil:getText( nomeEmitente ).

/* Cenario 2: verificar se campo tem conteudo antes de processar */

define variable codigoItem as character no-undo initial '  '.

if StringUtil:hasValue( codigoItem ) then
    message 'Item informado:' codigoItem.
else
    message 'Item nao informado — usando default'.

/* Cenario 3: formatar data para payload REST (ISO 8601) */

define variable dataEmbarque as date no-undo initial today.

message 'Data ISO:' StringUtil:formatIsoDate( dataEmbarque ).

/* Cenario 4: parsear data de payload JSON (YYYY-MM-DD) */

define variable dtRecebida as datetime no-undo.

assign dtRecebida = StringUtil:parseDate( '2026-09-17', ? ).
message 'Data parseada:' dtRecebida.

/* Cenario 5: limpar texto com quebras de linha para log ou campo */

define variable textoComQuebra as longchar no-undo.

assign textoComQuebra = 'Primeira linha' + chr(13) + chr(10) + 'Segunda linha'.

message 'Texto limpo:' StringUtil:removeCrLf( textoComQuebra ).
