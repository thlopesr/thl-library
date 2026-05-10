
/*------------------------------------------------------------------------
    File        : gerarRecebimento.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Lopes
    Created     : Fri Apr 24 17:09:56 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/
using Progress.Json.ObjectModel.*.

block-level on error undo, throw.

/* ***************************  Definitions  ************************** */
define input parameter documento  as JsonObject no-undo.
    
define shared temp-table rowErrors no-undo
    field ErrorSequence    as integer
    field ErrorNumber      as integer
    field ErrorDescription as character
    field ErrorParameters  as character
    field ErrorType        as character
    field ErrorHelp        as character
    field ErrorSubType     as character.  

define variable h-boin090 as handle no-undo.
define variable h-boin176 as handle no-undo.
define variable h-boin092 as handle no-undo.

define variable incide-pis    as logical no-undo.
define variable incide-confis as logical no-undo.
define variable incide-icms   as logical no-undo.

define variable cdn-munpio-ibge-dest as character no-undo.
define variable estado-dest          as character no-undo.

define temp-table tt-docum-est     no-undo like docum-est
    field r-rowid   as rowid.

define temp-table tt-item-doc-est  no-undo like item-doc-est
    field r-rowid   as rowid.

define temp-table tt-dupli-apagar  no-undo like dupli-apagar
    field r-rowid   as rowid.

/* ***************************  Main Block  *************************** */
define buffer b-transportadora for emitente.

empty temp-table tt-docum-est    no-error.
empty temp-table tt-item-doc-est no-error.
empty temp-table tt-dupli-apagar no-error.

find first estabelec no-lock
    where estabelec.cgc = documento:GetCharacter( 'cnpjEstabelecimento' ) no-error.
    
if not available estabelec then 
    undo, throw new Progress.Lang.AppError( 'Estabelecimento nao localizado', 17006 ).      

find first mg.cidade   no-lock
    where cidade.pais   = estabelec.pais
      and cidade.estado = estabelec.estado
      and cidade.cidade = estabelec.cidade no-error.

if not available cidade then 
    undo, throw new Progress.Lang.AppError( 'Muncipio Origem nao localizado', 17006 ). 

find first emitente no-lock
    where emitente.cgc = documento:GetCharacter( 'numeroDocumentoCliente' ) no-error.

find first mg.cidade   no-lock
    where cidade.pais   = emitente.pais
      and cidade.estado = emitente.estado
      and cidade.cidade = emitente.cidade no-error.

if not available cidade then 
    undo, throw new Progress.Lang.AppError( 'Muncipio Destino nao localizado', 17006 ).   

assign cdn-munpio-ibge-dest = string( cidade.cdn-munpio-ibge )
       estado-dest          = cidade.estado.
    
find first b-transportadora no-lock
    where b-transportadora.cgc = documento:GetCharacter( 'cnpjTransportadora' ) no-error.

if not available b-transportadora then 
    undo, throw new Progress.Lang.AppError( 'Transportadora nao localizado', 17006 ).      

find first cond-pagto no-lock
    where cond-pagto.cod-cond-pag = b-transportadora.cod-cond-pag no-error.

if not available cond-pagto then 
    undo, throw new Progress.Lang.AppError( 'Cond. pagamento nao localizado', 17006 ).      

assign incide-pis    = documento:GetCharacter( 'aliquotaPis'    ) <> '0.00'  
       incide-confis = documento:GetCharacter( 'aliquotaCofins' ) <> '0.00' 
       incide-icms   = documento:GetCharacter( 'aliquotaIcms'   ) <> '0.00'.

find first nit-loog-natur-oper no-lock
    where nit-loog-natur-oper.incide-pis    = incide-pis   
      and nit-loog-natur-oper.incide-confis = incide-confis
      and nit-loog-natur-oper.incide-icms   = incide-icms  
    no-error.
    
create tt-docum-est.
assign tt-docum-est.serie        = documento:GetCharacter('serie' )          
       tt-docum-est.nro-docto    = documento:GetCharacter('numeroDocumento' )
       tt-docum-est.cod-estabel  = estabelec.cod-estabel
       tt-docum-est.cod-emitente = b-transportadora.cod-emitente
       tt-docum-est.cod-observa  = 1
       tt-docum-est.dt-emissao   = documento:GetDate('dataEmissao' )
       tt-docum-est.dt-tran      = today     
       tt-docum-est.tot-valor    = documento:GetDecimal('valorTotal' )
       tt-docum-est.valor-mercad = tt-docum-est.tot-valor
       tt-docum-est.base-ipi     = tt-docum-est.tot-valor
       tt-docum-est.tot-peso     = 1
       tt-docum-est.nat-operacao = if estabelec.estado = estado-dest then nit-loog-natur-oper.nat-operacao-est
                                                                     else nit-loog-natur-oper.nat-operacao-inter
       tt-docum-est.peso-liquido-tot          = 1
       tt-docum-est.cod-chave-aces-nf-eletro  = documento:GetCharacter('chaveAcesso' ) 
       overlay(tt-docum-est.char-2, 143, 02 ) = '9' 
       overlay(tt-docum-est.char-2, 151, 02 ) = '1'   
       overlay(tt-docum-est.char-2, 211, 02 ) = cidade.estado                    // estadoOrigem
       overlay(tt-docum-est.char-2, 236, 10 ) = string( cidade.cdn-munpio-ibge ) // ibgeMuncipioOrigem
       overlay(tt-docum-est.char-2, 246, 10 ) = string( cdn-munpio-ibge-dest   ) // ibgeMuncipioDestino    
       .    

create tt-dupli-apagar.
assign tt-dupli-apagar.serie-docto    = tt-docum-est.serie
       tt-dupli-apagar.nro-docto      = tt-docum-est.nro-docto 
       tt-dupli-apagar.cod-emitente   = tt-docum-est.cod-emitente
       tt-dupli-apagar.nat-operacao   = tt-docum-est.nat-operacao
       tt-dupli-apagar.parcela        = '01'
       tt-dupli-apagar.nr-duplic      = tt-docum-est.nro-docto 
       tt-dupli-apagar.cod-esp        = 'GF'
       tt-dupli-apagar.tp-despesa     = 208
       tt-dupli-apagar.dt-emissao     = tt-docum-est.dt-emissao
       tt-dupli-apagar.dt-trans       = today
       tt-dupli-apagar.dt-vencim      = tt-docum-est.dt-emissao + cond-pagto.prazos[1]
       tt-dupli-apagar.vl-a-pagar     = tt-docum-est.tot-valor
       .
       
create tt-item-doc-est.
assign tt-item-doc-est.sequencia      = 1
       tt-item-doc-est.serie-docto    = tt-docum-est.serie
       tt-item-doc-est.nro-docto      = tt-docum-est.nro-docto 
       tt-item-doc-est.cod-emitente   = tt-docum-est.cod-emitente
       tt-item-doc-est.nat-operacao   = tt-docum-est.nat-operacao
       tt-item-doc-est.it-codigo      = '19077' 
       tt-item-doc-est.qt-do-forn     = 1
       tt-item-doc-est.quantidade     = 1
       tt-item-doc-est.preco-total[1] = tt-docum-est.tot-valor
       tt-item-doc-est.preco-unit[1]  = tt-docum-est.tot-valor
       tt-item-doc-est.desconto[1]    = 0.
       .

run inbo/boin176.p      persistent set h-boin176.
run inbo/boin090.p      persistent set h-boin090.
run inbo/boin092.p      persistent set h-boin092.

run emptyRowErrors in h-boin176.
run emptyRowErrors in h-boin090.
run emptyRowErrors in h-boin092.

do transaction.   
 
    run openQueryStatic         in h-boin090 (  input 'Main' ).
    run setRecord               in h-boin090 (  input table tt-docum-est ).           
    run createRecord            in h-boin090.
    run getRowErrors            in h-boin090 ( output table rowErrors ).
    
    if can-find( first rowErrors 
                    where rowErrors.errorsubtype = 'Error' ) then
        undo, throw new Progress.Lang.AppError( 'Erro criacao docum-est', 17006 ). 
        
    run openQueryStatic         in h-boin176 (  input 'Main' ).
    run setRecord               in h-boin176 (  input table tt-item-doc-est ).           
    run createRecord            in h-boin176.
    run getRowErrors            in h-boin176 ( output table rowErrors ).
    
    if can-find( first rowErrors 
                    where rowErrors.errorsubtype = 'Error' ) then
        undo, throw new Progress.Lang.AppError( 'Erro criacao item-doc-est', 17006 ).    
    
    run openQueryStatic         in h-boin092 (  input 'Main' ).
    run setRecord               in h-boin092 (  input table tt-dupli-apagar ).           
    run createRecord            in h-boin092.
    run getRowErrors            in h-boin092 ( output table rowErrors ).
    
    if can-find( first rowErrors 
                    where rowErrors.errorsubtype = 'Error' ) then
        undo, throw new Progress.Lang.AppError( 'Erro criacao dupli-apagar', 17006 ).   
        
end.

return 'Documento Gerado'.

finally.

    if valid-handle(h-boin176) then
        run destroy in h-boin176.  
    
    if valid-handle(h-boin090) then
        run destroy in h-boin090.

    if valid-handle(h-boin092) then
        run destroy in h-boin092.
            
end finally.    
    


