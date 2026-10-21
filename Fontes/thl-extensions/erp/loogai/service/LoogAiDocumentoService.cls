/*------------------------------------------------------------------------
    File        : LoogAiDocumentoService
    Purpose     : Especializacao de DocumentoService para a Loog.ai.
                  Sobrescreve prepareDocumentData com a logica de lookup de
                  estabelecimento, transportadora, condicao de pagamento e
                  determinacao da natureza de operacao por incidencia
                  fiscal (PIS/COFINS/ICMS) via nit-loog-natur-oper.
    Author(s)   : Lopes
    Created     : 2026-07-24
    Notes       : Extraido de LoogAiDocumentoMessage (SRP) — a Message
                  passou a delegar a DocumentoMessage:createService(), que
                  esta classe sobrescreve para injetar este Service.
                  Movido de
                  integration.loogai.messaging.inbound.service para
                  erp.loogai.service em 2026-07-24 (sessao 6) — cria
                  registro no ERP independente de ser chamado por um fluxo
                  de integracao ou nao.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.
using thl-lib.core.error.*.
using thl-lib.erp.enum.ActionEnum.
using thl-lib.erp.service.DocumentoService.
using thl-lib.logging.LogUtil.

block-level on error undo, throw.

class thl-extensions.erp.loogai.service.LoogAiDocumentoService inherits DocumentoService.

    //incide PIS
    define protected property hasPis    as logical   no-undo get. protected set.
    //incide COFINS
    define protected property hasCofins as logical   no-undo get. protected set.
    //incide ICMS
    define protected property hasIcms   as logical   no-undo get. protected set.
    //estado destino
    define protected property destinationState as character no-undo get. protected set.

    //numero NF cliente
    define protected property clientInvoiceNumber as character no-undo get. protected set.
    //serie NF cliente
    define protected property clientInvoiceSeries    as character no-undo get. protected set.
    define protected property clientInvoiceAccessKey as character no-undo get. protected set.
    
    //transportadora
    define protected buffer b-emitente for emitente.
    
    //frete realizado
    define protected temp-table tt-frete-realizado no-undo like nit-frete-real.

    //buffer para persistencia do frete realizado
    define private buffer b-nit-frete-real for nit-frete-real.
    define private buffer b-nota-fiscal    for nota-fiscal.
    define private buffer b-cidade         for mg.cidade.
    

    define private variable CHAR2_TIPO_NF_ENTRADA        as integer no-undo initial 143.
    define private variable CHAR2_ORIGEM_LOOGAI          as integer no-undo initial 151.
    define private variable CHAR2_ESTADO_ORIGEM          as integer no-undo initial 211.
    define private variable CHAR2_IBGE_MUNICIPIO_ORIGEM  as integer no-undo initial 246.
    define private variable CHAR2_IBGE_MUNICIPIO_DESTINO as integer no-undo initial 236.

    //preparar dados do documento
    method protected override void prepareDocumentData( input payload as JsonObject ).

        this-object:resolveEntities      ( payload ).
        this-object:parseClientInvoice   ( payload ).
        this-object:buildDocumentHeader  ( payload ).

        if payload:GetCharacter( 'tipoDocumento' ) = 'Entrada' then do.
            this-object:resolveEntry( payload ).
            this-object:resolveOperationNature( payload ).
            this-object:buildEntryItem( payload ).
        end.
        else do.
            this-object:resolveExit( payload ).
            this-object:resolveOperationNature( payload ).
            this-object:buildExitItem( payload ).
        end.

        this-object:buildPayableDuplicate().

    end method.

    //localizar estabelecimento, transportadora e condicao de pagamento
    method protected void resolveEntities( input payload as JsonObject ).

        find first estabelec no-lock
            where estabelec.cgc = payload:GetCharacter( 'cnpjEstabelecimento' ) no-error.

        if not available estabelec then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveEntities', 'Estabelecimento nao localizado.' ).

        find first b-emitente no-lock
            where b-emitente.cgc = payload:GetCharacter( 'cnpjTransportadora' ) no-error.

        if not available b-emitente then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveEntities', 'Transportadora nao localizada.' ).

        find first cond-pagto no-lock
            where cond-pagto.cod-cond-pag = b-emitente.cod-cond-pag no-error.

        if not available cond-pagto then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveEntities', 'Cond. pagamento nao localizado.' ).

    end method.

    //extrair numero e serie da NF do cliente a partir do array notaFiscalTransportada
    method protected void parseClientInvoice( input payload as JsonObject ).

        define variable invoiceArray as JsonArray  no-undo.
        define variable invoiceItem  as JsonObject no-undo.

        if not payload:Has( 'notaFiscalTransportada' ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'parseClientInvoice', 'Array notaFiscalTransportada nao informado.' ).

        invoiceArray = payload:GetJsonArray( 'notaFiscalTransportada' ).

        if invoiceArray:Length = 0 then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'parseClientInvoice', 'Array notaFiscalTransportada vazio.' ).

        assign invoiceItem            = invoiceArray:GetJsonObject( 1 )
               clientInvoiceNumber    = invoiceItem:GetCharacter( 'numero' )
               clientInvoiceSeries    = invoiceItem:GetCharacter( 'serie' )
               clientInvoiceAccessKey = invoiceItem:GetCharacter( 'chaveAcesso' )
               clientInvoiceNumber    = fill( '0', 7 - length( clientInvoiceNumber ) ) + clientInvoiceNumber.

    end method.

    //montar cabecalho do documento de estoque
    method protected void buildDocumentHeader( input payload as JsonObject ).

        create tt-docum-est.
        assign tt-docum-est.serie-docto              = payload:GetCharacter( 'serie'           )
               tt-docum-est.nro-docto                = payload:GetCharacter( 'numeroDocumento' )
               tt-docum-est.dt-emissao               = payload:GetDate     ( 'dataEmissao'     )
               tt-docum-est.dt-trans                 = today
               tt-docum-est.tot-valor                = payload:GetDecimal  ( 'valorTotal'      )
               tt-docum-est.valor-mercad             = tt-docum-est.tot-valor
               tt-docum-est.cod-estabel              = estabelec.cod-estabel
               tt-docum-est.cod-emitente             = b-emitente.cod-emitente
               tt-docum-est.cod-observa              = 1
               tt-docum-est.base-ipi                 = tt-docum-est.tot-valor
               tt-docum-est.tot-peso                 = 1
               tt-docum-est.peso-liquido-tot         = 1
               tt-docum-est.cod-chave-aces-nf-eletro = payload:GetCharacter( 'chaveAcesso'     )
               tt-docum-est.aliquota-icm             = decimal( payload:GetCharacter( 'aliquotaIcms' ) ) / 100
               tt-docum-est.base-icm                 = payload:GetDecimal( 'basecalculoIcms'     )
               tt-docum-est.origem                   = 'loogai'
               overlay(tt-docum-est.char-2, CHAR2_ORIGEM_LOOGAI, 02) = '1'
               .

    end method.

    //resolver NF de entrada: emitente, municipio origem, docum-est referencia, incidencia fiscal
    method protected void resolveEntry( input payload as JsonObject ).

        find first docum-est no-lock
            where docum-est.cod-chave-aces-nf-eletro = clientInvoiceAccessKey
               or docum-est.cod-estabel  = estabelec.cod-estabel
              and docum-est.cod-emitente = emitente.cod-emitente
              and docum-est.serie-docto  = clientInvoiceSeries
              and docum-est.nro-docto    = clientInvoiceNumber
            no-error.

        if not available docum-est then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveEntry', 'Nota Fiscal nao localizada.' ).

        find first emitente no-lock
            where emitente.cod-emitente = docum-est.cod-emitente
            no-error.
            
        if emitente.pais = 'EX' then 
            find first emitente no-lock
                where emitente.cgc = payload:GetCharacter( 'cnpjTransportadora' )
                no-error.

        find first b-cidade no-lock
            where b-cidade.pais   = emitente.pais
              and b-cidade.estado = emitente.estado
              and b-cidade.cidade = emitente.cidade no-error.

        if not available b-cidade then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveEntry', 'Municipio de origem nao localizado.'  ).

        assign overlay(tt-docum-est.char-2, CHAR2_TIPO_NF_ENTRADA, 02)       = '1'
               overlay(tt-docum-est.char-2, CHAR2_ESTADO_ORIGEM, 02)         = b-cidade.estado
               overlay(tt-docum-est.char-2, CHAR2_IBGE_MUNICIPIO_ORIGEM, 10) = string( b-cidade.cdn-munpio-ibge )
               hasPis         = can-find( first item-doc-est of docum-est no-lock
                                              where item-doc-est.val-aliq-pis    <> 0
                                                and item-doc-est.val-aliq-cofins <> 0 )
               hasCofins      = hasPis.

        find first b-cidade no-lock
            where b-cidade.pais   = docum-est.pais
              and b-cidade.estado = docum-est.uf
              and b-cidade.cidade = docum-est.cidade 
            no-error.

    end method.

    //resolver NF de saida: municipio origem, nota fiscal, incidencia fiscal, emitente destino
    method protected void resolveExit( input payload as JsonObject ).

        find first b-cidade no-lock
            where b-cidade.pais   = estabelec.pais
              and b-cidade.estado = estabelec.estado
              and b-cidade.cidade = estabelec.cidade
            no-error.

        if not available b-cidade then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveExit', 'Municipio de origem nao localizado.' ).

        find first b-nota-fiscal no-lock
            where b-nota-fiscal.cod-estabel = estabelec.cod-estabel
              and b-nota-fiscal.serie       = clientInvoiceSeries
              and b-nota-fiscal.nr-nota-fis = clientInvoiceNumber no-error.

        if not available b-nota-fiscal then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveExit', 'Nota Fiscal nao localizada.' ).

        assign hasPis    = can-find( first it-nota-fisc of b-nota-fiscal no-lock
                                         where it-nota-fisc.val-unit-pis    <> 0
                                            or it-nota-fisc.val-unit-cofins <> 0
                                            or substring( it-nota-fisc.char-2, 76, 5) <> '00.00'
                                            or substring( it-nota-fisc.char-2, 81, 5) <> '00.00' )
               hasCofins = hasPis
               overlay(tt-docum-est.char-2, CHAR2_TIPO_NF_ENTRADA, 02)       = '0'
               overlay(tt-docum-est.char-2, CHAR2_ESTADO_ORIGEM, 02)         = b-cidade.estado
               overlay(tt-docum-est.char-2, CHAR2_IBGE_MUNICIPIO_ORIGEM, 10) = string( b-cidade.cdn-munpio-ibge )
               .

        find first emitente no-lock
            where emitente.cgc       = payload:GetCharacter( 'documentoCliente' )
              and emitente.natureza <> 3 no-error.

        find first b-cidade no-lock
            where b-cidade.pais   = emitente.pais
              and b-cidade.estado = emitente.estado
              and b-cidade.cidade = emitente.cidade no-error.

    end method.

    //determinar natureza de operacao por incidencia fiscal via nit-loog-natur-oper
    method protected void resolveOperationNature( input payload as JsonObject ).

        if not available b-cidade then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveOperationNature', 'Municipio de destino nao localizado.' ).

        assign destinationState = b-cidade.estado
               hasIcms          = payload:GetCharacter( 'aliquotaIcms' ) <> '0.00'.

        find first nit-loog-natur-oper no-lock
            where nit-loog-natur-oper.incide-pis    = hasPis
              and nit-loog-natur-oper.incide-confis = hasCofins
              and nit-loog-natur-oper.incide-icms   = hasIcms
            no-error.

        assign tt-docum-est.nat-operacao = if estabelec.estado = destinationState then nit-loog-natur-oper.nat-operacao-est
                                                                                  else nit-loog-natur-oper.nat-operacao-inter
               overlay(tt-docum-est.char-2, CHAR2_IBGE_MUNICIPIO_DESTINO, 10) = string( b-cidade.cdn-munpio-ibge )
               .

    end method.

    //montar item e rateio para NF de entrada
    method protected void buildEntryItem( input payload as JsonObject ).

        create tt-rat-docum.
        buffer-copy tt-docum-est to tt-rat-docum
            assign tt-rat-docum.nf-emitente   = docum-est.cod-emitente
                   tt-rat-docum.nf-nat-oper   = docum-est.nat-operacao
                   tt-rat-docum.nf-nro        = docum-est.nro-docto
                   tt-rat-docum.nf-serie      = docum-est.serie-docto
                   tt-rat-docum.Ind-origem-nf = 1
                   tt-rat-docum.tipo-nota     = 1
                   tt-rat-docum.dec-1         = docum-est.tot-valor.

        find first item-doc-est of docum-est no-lock no-error.

        create tt-item-doc-est.
        assign tt-item-doc-est.serie-docto    = tt-docum-est.serie-docto
               tt-item-doc-est.nro-docto      = tt-docum-est.nro-docto
               tt-item-doc-est.cod-emitente   = tt-docum-est.cod-emitente
               tt-item-doc-est.nat-operacao   = tt-docum-est.nat-operacao
               tt-item-doc-est.it-codigo      = item-doc-est.it-codigo
               tt-item-doc-est.qt-do-forn     = 0
               tt-item-doc-est.quantidade     = 0
               tt-item-doc-est.base-icm       = tt-docum-est.base-icm
               tt-item-doc-est.aliquota-icm   = tt-docum-est.aliquota-icm
               tt-item-doc-est.preco-total[1] = tt-docum-est.tot-valor
               tt-item-doc-est.preco-unit[1]  = tt-docum-est.tot-valor
               tt-item-doc-est.desconto[1]    = 0
               tt-item-doc-est.nro-comp       = docum-est.nro-docto
               tt-item-doc-est.nat-comp       = docum-est.nat-operacao
               tt-item-doc-est.serie-comp     = docum-est.serie-docto
               tt-item-doc-est.seq-comp       = item-doc-est.sequencia
               tt-item-doc-est.sequencia      = 1
               tt-item-doc-est.nat-of-comp    = docum-est.nat-operacao
               .

    end method.

    //montar item para NF de saida
    method protected void buildExitItem( input payload as JsonObject ).
    
        find first nit-loogai-natur-oper-item no-lock
            where nit-loogai-natur-oper-item.nat-operacao = b-nota-fiscal.nat-operacao
            no-error.

        create tt-item-doc-est.
        assign tt-item-doc-est.serie-docto    = tt-docum-est.serie-docto
               tt-item-doc-est.nro-docto      = tt-docum-est.nro-docto
               tt-item-doc-est.cod-emitente   = tt-docum-est.cod-emitente
               tt-item-doc-est.nat-operacao   = tt-docum-est.nat-operacao
               tt-item-doc-est.it-codigo      = if available nit-loogai-natur-oper-item then nit-loogai-natur-oper-item.it-codigo else '19077'
               tt-item-doc-est.qt-do-forn     = 1
               tt-item-doc-est.quantidade     = 1
               tt-item-doc-est.base-icm       = tt-docum-est.base-icm
               tt-item-doc-est.aliquota-icm   = tt-docum-est.aliquota-icm
               tt-item-doc-est.preco-total[1] = tt-docum-est.tot-valor
               tt-item-doc-est.preco-unit[1]  = tt-docum-est.tot-valor
               tt-item-doc-est.desconto[1]    = 0
               tt-item-doc-est.sequencia      = 1
               .

    end method.

    //montar duplicata a pagar
    method protected void buildPayableDuplicate().

        create tt-dupli-apagar.
        assign tt-dupli-apagar.serie-docto  = tt-docum-est.serie
               tt-dupli-apagar.nro-docto    = tt-docum-est.nro-docto
               tt-dupli-apagar.cod-emitente = tt-docum-est.cod-emitente
               tt-dupli-apagar.nat-operacao = tt-docum-est.nat-operacao
               tt-dupli-apagar.parcela      = '01'
               tt-dupli-apagar.nr-duplic    = tt-docum-est.nro-docto
               tt-dupli-apagar.cod-esp      = 'GF'
               tt-dupli-apagar.tp-despesa   = 208
               tt-dupli-apagar.dt-emissao   = tt-docum-est.dt-emissao
               tt-dupli-apagar.dt-trans     = today
               tt-dupli-apagar.dt-vencim    = tt-docum-est.dt-emissao + cond-pagto.prazos[1]
               tt-dupli-apagar.vl-a-pagar   = tt-docum-est.tot-valor
               .

    end method.

    //cria o documento e, em seguida, o frete realizado (antes ficava num
    //execute() sobrescrito; o execute saiu do Service em 2026-10-04)
    method public override void create().

        super:create().

        this-object:loadActualFreight( inContext ).
        this-object:createActualFreight().

    end method.

    //popular tt-frete-realizado a partir do array notaFiscalTransportada
    method protected void loadActualFreight( input payload as JsonObject ).

        define variable invoiceArray as JsonArray  no-undo.
        define variable invoiceItem  as JsonObject no-undo.
        define variable idx          as integer    no-undo.

        empty temp-table tt-frete-realizado no-error.

        if not payload:Has( 'notaFiscalTransportada' )              and
               payload:GetCharacter( 'tipoDocumento' ) <> 'Entrada' then
            return.

        invoiceArray = payload:GetJsonArray( 'notaFiscalTransportada' ).

        do idx = 1 to invoiceArray:Length.

            invoiceItem = invoiceArray:GetJsonObject( idx ).

            create tt-frete-realizado.
            assign
                //chave docum-est (documento de recebimento criado)
                tt-frete-realizado.serie-docto    = tt-docum-est.serie-docto
                tt-frete-realizado.nro-docto      = tt-docum-est.nro-docto
                tt-frete-realizado.cod-emitente   = tt-docum-est.cod-emitente
                tt-frete-realizado.nat-operacao   = tt-docum-est.nat-operacao
                tt-frete-realizado.cod-estabel    = tt-docum-est.cod-estabel
                //chave NF de origem (do array)
                tt-frete-realizado.serie          = invoiceItem:GetCharacter( 'serie' )
                tt-frete-realizado.nr-nota-fis    = invoiceItem:GetCharacter( 'numero' )
                tt-frete-realizado.idi-tipo-frete = invoiceItem:GetInteger( 'tipoFrete' )
                tt-frete-realizado.val-frete      = if invoiceItem:GetType( 'valorFrete' ) = 1 then 
                                                        if invoiceItem:GetCharacter( 'valorFrete' ) = '' then 0
                                                                                                         else decimal( invoiceItem:GetCharacter( 'valorFrete' ) )
                                                                                               else invoiceItem:GetDecimal( 'valorFrete' )           
                tt-frete-realizado.idi-situacao   = 1
                tt-frete-realizado.des-observacao = if invoiceItem:Has( 'observacaoFrete' ) then invoiceItem:GetCharacter( 'observacaoFrete' ) 
                                                                                            else ''
                .

        end.

    end method.

    //persistir frete realizado na tabela nit-frete-real
    method protected void createActualFreight().

        if not can-find( first tt-frete-realizado ) then
            return.

        for each tt-frete-realizado.
            create b-nit-frete-real.
            buffer-copy tt-frete-realizado to b-nit-frete-real.
        end.

    end method.

end class.
