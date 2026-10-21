 /*------------------------------------------------------------------------
    File        : NotaFiscalService
    Purpose     : Operacoes de negocio de nota fiscal DIRETA (sem embarque):
                  geracao item a item via bodi317*, XML NF-e, autorizacao
                  SEFAZ, impressao, notificacao por e-mail e o encadeamento
                  completo (process).
    Author(s)   : Lopes
    Created     : 2026-06-11
    Notes       : Fase 4 (2026-07-26) - implementa IService; dispatcher
                  execute(action, operation) substitui os 6 metodos publicos
                  P3. O roteamento por operacao que antes vivia em
                  NotaFiscalMessage agora vive aqui, consistente com os
                  demais Services.
                  2026-10-08: o roteamento por operacao e o encadeamento
                  (processamento) foram para o NotaFiscalProcessor; aqui
                  ficam as etapas, como metodos publicos.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-lib.communication.email.*.
using thl-lib.core.error.*.
using thl-lib.erp.core.ServiceResponse.
using thl-lib.erp.enum.ActionEnum.
using thl-lib.erp.enum.SituacaoNfeEnum.
using thl-lib.erp.service.NotaFiscalBaseService.

block-level on error undo, throw.

class thl-lib.erp.service.NotaFiscalService inherits NotaFiscalBaseService.

    define variable hBodi317sd             as handle     no-undo.
    
    define temp-table tt-wt-docto      no-undo like wt-docto
        field r-rowid as rowid.  
    
    method public override character getEntityName().
        return 'Nota Fiscal'.
    end method.

    //Um metodo por acao: criar = gerar a nota. As demais etapas sao chamadas
    //pelo NotaFiscalProcessor, que orquestra pela operacao da URL.
    method public override void create().
        this-object:createInvoice().
    end method.

    method public override void generateInvoice().
        this-object:createInvoice().
    end method.

    method public override void generateNfeXml().
        this-object:generateNfeXmlWorker().
    end method.

    method public override void authorizeSefaz().
        this-object:updateSefazWorker().
    end method.

    method public override void printInvoice().
        this-object:printInvoiceWorker().
    end method.

    method public override void notifyInvoice().
        this-object:notifyInvoiceWorker().
    end method.

    method public override JsonObject buildResponse( input action as ActionEnum, input referenceCode as character ).
        define variable response as JsonObject no-undo.
        assign response = ServiceResponse:success( this-object:getEntityName(), this-object:operation, referenceCode ).
        response:Add( 'data', outPayload ).
        return response.
    end method.

    method public override character loadReferenceCode().
        if available b-nota-fiscal then
           return substitute( '&1#&2#&3', b-nota-fiscal.cod-estabel, b-nota-fiscal.serie, b-nota-fiscal.nr-nota-fis).
        return ''.
    end method.

    //Monta a NF item a item via bodi317* e efetiva (bodi317ef).
    method protected void createInvoice().

        //Definicao da variaveis
        define variable hBodi317               as handle     no-undo.
        define variable hBodi317pr             as handle     no-undo.
        define variable hBodi317im1bra         as handle     no-undo.
        define variable hBodi317va             as handle     no-undo.
        define variable hBodi317in             as handle     no-undo.
        define variable hBodi317ef             as handle     no-undo.
        define variable hShowmsg               as handle     no-undo.
        define variable lProcessaComSucesso    as logical    no-undo.
        define variable cUltimoMetodoExecutado as character  no-undo.
        define variable cSerie                 as character  no-undo.
        define variable cUnidadeMedida         as character  no-undo.
        define variable cNaturezaItem          as character  no-undo.
        define variable deQuantidadeItem       as decimal    no-undo.
        define variable iSequenciaItem         as integer    no-undo.
        define variable iSequenciaWtDocto      as integer    no-undo.
        define variable iSequenciaWtItDocto    as integer    no-undo.
        define variable item                   as JsonObject no-undo.
        define variable contador               as integer    no-undo.

        //Bloco a ser repetido para cada item da nota
        if not inPayload:Has('items') then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'createInvoice', 'Objeto items' ).
            
        this-object:initialize().    

        //Inicializa o das BOS para Calculo
        run dibo/bodi317in.p persistent set hBodi317in.

        run inicializaBOS in hBodi317in ( output hBodi317pr     ,
                                          output hBodi317sd     ,
                                          output hBodi317im1bra ,
                                          output hBodi317va     ).

        //Busca Serie
        run leaveCodEstabel in hBodi317sd (  input inPayload:GetCharacter('cod-estabel'),  //Estabelec
                                             input false                              ,  //Se e nota manual
                                            output cSerie                             ). //Serie da nota

        do transaction.

            run emptyRowErrors in hBodi317in.

            run criaWtDocto in hBodi317sd (  input inPayload:GetCharacter('usuario')    ,     //Usuario do sistema
                                             input inPayload:GetCharacter('cod-estabel'),     //Codigo do estabelecimento da nota
                                             input cSerie,                                    //Serie da nota fiscal
                                             input '1'   ,                                    //Numero da nota fiscal, para notas manuais
                                             input inPayload:GetCharacter('nome-abrev') ,     //Codigo, nome abreviado ou CGC do cliente
                                             input ?    ,                                     //Numero do pedido de venda, quando existir
                                             input 1    ,                                     //Tipo da nota fiscal - 04: Complementar de mercadoria
                                             input 9999 ,                                     //Codigo do programa que gerou a nota - 0032
                                             input today,                                     //Data de emissao da nota fiscal
                                             input 0    ,                                     //Numero do embarque, quando existir
                                             input resolveNature()      ,                     //Codigo da natureza de opera cao
                                             input resolveSalesChannel(),                     //Codigo do canal de venda do cliente, quando existir
                                            output iSequenciaWtDocto     ,                    //Sequencia do documento (chave unica)
                                            output lProcessaComSucesso   ).                   //Execu cao do m etodo com sucesso ou nao

            //Busca possiveis erros que ocorreram nas validacoes
            run devolveErrosbodi317sd in hBodi317sd ( output cUltimoMetodoExecutado,
                                                      output table RowErrors       ).

            this-object:throwRowErrorsIfAny( 'createInvoice', 'criaWtDocto' ).

            //Disponibilizar o registro WT-DOCTO na bodi317sd
            run localizaWtDocto in hBodi317sd(  input iSequenciaWtDocto   ,
                                               output lProcessaComSucesso ).

            do contador = 1 to inPayload:GetJsonArray('items'):Length.

                assign item = inPayload:GetJsonArray('items'):GetJsonObject(contador).

                //Busca unidade de medida do item
                run searchDefaultUOM in hBodi317sd (  input item:GetCharacter('it-codigo'),
                                                      input iSequenciaWtDocto             ,
                                                     output cUnidadeMedida                ,
                                                     output lProcessaComSucesso           ).

                run emptyRowErrors        in hBodi317in.

                //Cria um item para nota fiscal
                run criaWtItDocto in hBodi317sd (  input ? ,
                                                   input item:GetCharacter('tabela')   ,
                                                   input 10 * contador                 ,
                                                   input item:GetCharacter('it-codigo'),
                                                   input item:GetCharacter('cod-refer'),
                                                   input resolveNatureItem( item )     ,
                                                  output iSequenciaWtItDocto           ,
                                                  output lProcessaComSucesso           ).

                //Busca poss veis erros que ocorreram nas validacao
                run devolveErrosbodi317sd in hBodi317sd( output cUltimoMetodoExecutado,
                                                         output table RowErrors       ).

                //Caso tenha achado algum erro ou advertencia, mostra em tela
                this-object:throwRowErrorsIfAny( 'createInvoice', 'criaWtItDocto' ).
                
                item:add('sequencia-wt-docto', iSequenciaWtDocto).
                item:add('unidade-medida'    , cUnidadeMedida   ).
                
                assign item = getPrice( item ).

                //Grava informacoes gerais para o item da nota
                run gravaInfGeraisWtItDocto in hBodi317sd ( input iSequenciaWtDocto  ,
                                                            input iSequenciaWtItDocto,
                                                            input item:GetDecimal('quantidade'),
                                                            input item:GetDecimal('valor')     ,
                                                            input 0               ,  //Percentual de desconto da tabela de preco, nao informar
                                                            input 0               ). //Percentual de desconto do item, nao informar

                find first wt-it-docto exclusive-lock
                    where wt-it-docto.seq-wt-docto    = iSequenciaWtDocto
                      and wt-it-docto.seq-wt-it-docto = iSequenciaWtItDocto
                    no-error.

                if available wt-it-docto then
                    assign wt-it-docto.quantidade[2] = item:GetDecimal  ('quantidade')
                           wt-it-docto.un[2]         = cUnidadeMedida
                           wt-it-docto.peso-bru-it-inf = if item:has('peso-bru-tot') then item:GetDecimal('peso-bru-tot') else wt-it-docto.peso-bru-it-inf
                           wt-it-docto.peso-liq-it-inf = if item:has('peso-liq-tot') then item:GetDecimal('peso-liq-tot') else wt-it-docto.peso-liq-it-inf
                           .
                           
                release wt-it-docto no-error.

                run emptyRowErrors        in hBodi317in.

                //Disp. registro WT-DOCTO, WT-IT-DOCTO e WT-IT-IMPOSTO na bodi317pr
                run localizaWtDocto     in hBodi317pr(  input iSequenciaWtDocto   ,
                                                       output lProcessaComSucesso ).

                run localizaWtItDocto   in hBodi317pr (  input iSequenciaWtDocto   ,
                                                         input iSequenciaWtItDocto ,
                                                        output lProcessaComSucesso ).

                run localizaWtItImposto in hBodi317pr (  input iSequenciaWtDocto   ,
                                                         input iSequenciaWtItDocto ,
                                                        output lProcessaComSucesso ).

                //Atualiza dados c lculados do item
                run atualizaDadosItemNota in hBodi317pr( output lProcessaComSucesso ).

                run devolveErrosbodi317pr in hBodi317pr( output cUltimoMetodoExecutado,
                                                         output table RowErrors       ).

                //Caso tenha achado algum erro ou advertencia, mostra em tela
                this-object:throwRowErrorsIfAny( 'createInvoice', 'atualizaDadosItemNota' ).

                //Valida informacoes do item
                run validaItemDaNota      in hBodi317va (  input iSequenciaWtDocto   ,
                                                           input iSequenciaWtItDocto ,
                                                          output lProcessaComSucesso ).

                run devolveErrosbodi317va in hBodi317va( output cUltimoMetodoExecutado,
                                                         output table RowErrors       ).

                this-object:throwRowErrorsIfAny( 'createInvoice', 'validaItemDaNota' ).

            end.

            if  not valid-handle( hBodi317 ) then
                run dibo/bodi317.p persistent set hBodi317.
    
            run openQueryStatic      in hBodi317( input 'Default':U       ).
            run gotokey              in hBodi317( input iSequenciaWtDocto ).        
                
            empty temp-table tt-wt-docto no-error.    
            
            run getRecord in hBodi317 ( output table tt-wt-docto ).
 
            find first tt-wt-docto no-error.
            assign tt-wt-docto.nome-transp  = resolveTransport()
                   tt-wt-docto.observ-nota  = tt-wt-docto.observ-nota + resolverObservation()
                   overlay( tt-wt-docto.char-1, 158, 8 ) = if inPayload:has('modalid-frete') then inPayload:GetCharacter('modalid-frete') else ''
                   .
                   
            run setRecord    in hBodi317 ( input table tt-wt-docto ).
            run updateRecord in hBodi317.
        
            run emptyRowErrors        in hBodi317in.

            //Calcula o pedido, com acompanhamento
            run inicializaAcompanhamento in hBodi317pr.
            run confirmaCalculo          in hBodi317pr (  input iSequenciaWtDocto,
                                                         output lProcessaComSucesso ).
            run finalizaAcompanhamento   in hBodi317pr.

            run devolveErrosbodi317pr    in hBodi317pr ( output cUltimoMetodoExecutado,
                                                         output table RowErrors     ).

            this-object:throwRowErrorsIfAny( 'createInvoice', 'confirmaCalculo' ).

            //Efetiva os pedidos e cria a nota
            run dibo/bodi317ef.p persistent set hBodi317ef.

            run inicializaAcompanhamento in hBodi317ef.
            run setaHandlesBOS           in hBodi317ef(  input hBodi317pr     ,
                                                         input hBodi317sd     ,
                                                         input hBodi317im1bra ,
                                                         input hBodi317va     ).
            run efetivaNota              in hBodi317ef(  input iSequenciaWtDocto   ,
                                                         input true                ,
                                                        output lProcessaComSucesso ).
            run finalizaAcompanhamento   in hBodi317ef.
            run devolveErrosbodi317ef    in hBodi317ef( output cUltimoMetodoExecutado ,
                                                        output table RowErrors        ).

            this-object:throwRowErrorsIfAny( 'createInvoice', 'efetivaNota' ).

            //Busca as notas fiscais geradas
            run buscaTTNotasGeradas in hBodi317ef( output lProcessaComSucesso  ,
                                                   output table tt-nota-gerada ).

            //Elimina o handle do programa bodi317ef
            delete procedure hBodi317ef.

            find first tt-nota-gerada no-lock no-error.
            find first b-nota-fiscal  no-lock
                where rowid( b-nota-fiscal ) = tt-nota-gerada.rw-nota-fiscal
                no-error.

            inPayload:add( 'codigoEstabelecimento', b-nota-fiscal.cod-estabel).
            inPayload:add( 'serie'                , b-nota-fiscal.serie      ).
            inPayload:add( 'numeroNotaFiscal'     , b-nota-fiscal.nr-nota-fis).
            inPayload:add( 'seqWtDocto'           , iSequenciaWtDocto        ).

            this-object:addInvoicePayload( b-nota-fiscal.cod-estabel ,
                                           b-nota-fiscal.serie       ,
                                           b-nota-fiscal.nr-nota-fis ,
                                           ''                        ,
                                           ''                        ,
                                           true                      ).

        end.

        //Finaliza o das BOS utilizada no calculo
        run finalizaBOS in hBodi317in.

    end method.
    
    method protected character resolveNature ().
        return inPayload:GetCharacter('nat-operacao').
    end method.
    
    method protected character resolveNatureItem( item as JsonObject).
        return item:GetCharacter('nat-operacao').
    end method.
    
    method protected character resolveTransport().
        return inPayload:GetCharacter('nome-transp').
    end method.
    
    method protected integer resolveSalesChannel().
        return inPayload:GetInteger  ('cod-canal-venda').
    end method.
    
    method protected character resolverObservation ().
        return if inPayload:has('observacao') then inPayload:GetCharacter('observacao') else ''.
    end method.
    
    method protected JsonObject getPrice( item as JsonObject).
        
        define variable dePrecoItemTabela      as decimal    no-undo.
        define variable dePrecoItemOriginal    as decimal    no-undo.
        define variable deDesconto             as decimal    no-undo.
    
        //Busca preco do item
        run leaveQuantidade in hBodi317sd (  input item:GetInteger  ('sequencia-wt-docto'),
                                             input item:GetCharacter('it-codigo')     ,
                                             input item:GetCharacter('cod-refer')     , //Referencia
                                             input item:GetCharacter('unidade-medida'),
                                             input item:GetDecimal  ('quantidade')    ,
                                            output dePrecoItemTabela                  ,
                                            output dePrecoItemOriginal                ,
                                            output deDesconto                         ).
                                            
        item:add( 'valor'       , dePrecoItemOriginal      ).
        item:add( 'val-desconto', deDesconto               ).
                                                       
        return item.
    end method.
    
    method protected void printInvoiceWorker().

        define variable invoiceFile as character no-undo.

        if not available b-nota-fiscal then
            find first b-nota-fiscal  no-lock
                where b-nota-fiscal.cod-estabel       = inPayload:GetCharacter('codigoEstabelecimento')
                  and b-nota-fiscal.serie             = inPayload:GetCharacter('serie')
                  and b-nota-fiscal.nr-nota-fis       = inPayload:GetCharacter('numeroNotaFiscal')
                  and b-nota-fiscal.idi-sit-nf-eletro = SituacaoNfeEnum:AUTORIZADA:GetValue()
                no-error.

        if available b-nota-fiscal then do.

            assign invoiceFile = this-object:printInvoiceDocument().

            this-object:addInvoicePayload( b-nota-fiscal.cod-estabel,
                                           b-nota-fiscal.serie      ,
                                           b-nota-fiscal.nr-nota-fis,
                                           'impressao'              ,
                                           invoiceFile              ,
                                           search(invoiceFile) <> ? ).

            if search(invoiceFile) = ? then
                undo, throw new ThlError( this-object:GetClass():TypeName, 'printInvoiceWorker', 'Nota Fiscal nao gerada' ).

            inPayload :add( 'arquivo' , invoiceFile ).
            
        end.

    end method.

    method private void generateNfeXmlWorker().

        define variable tempFile      as character no-undo.
        define variable resultMessage as character no-undo.

        if not available b-nota-fiscal then
            find first b-nota-fiscal  no-lock
                where b-nota-fiscal.cod-estabel = inPayload:GetCharacter('codigoEstabelecimento')
                  and b-nota-fiscal.serie       = inPayload:GetCharacter('serie')
                  and b-nota-fiscal.nr-nota-fis = inPayload:GetCharacter('numeroNotaFiscal')
                no-error.

        assign tempFile = this-object:exportNfeXml(  input b-nota-fiscal.cod-estabel,
                                                     input b-nota-fiscal.serie      ,
                                                     input b-nota-fiscal.nr-nota-fis,
                                                     input b-nota-fiscal.nr-nota-fis,
                                                    output resultMessage            ).

        this-object:addInvoicePayload( b-nota-fiscal.cod-estabel,
                                       b-nota-fiscal.serie      ,
                                       b-nota-fiscal.nr-nota-fis,
                                       resultMessage            ,
                                       tempFile                 ,
                                       search(tempFile) <> ?    ).

    end method.

    method private void updateSefazWorker().

        define variable h-acompanhar as handle    no-undo.
        define variable sitCode      as integer   no-undo.
        define variable sitMessage   as character no-undo.
        define variable attemptsUsed as integer   no-undo.

        run utp/ut-acomp.p persistent set h-acompanhar.

        run pi-inicializar in h-acompanhar ( input 'Atualizando' ).

        if not available b-nota-fiscal then
            find first b-nota-fiscal  no-lock
                where b-nota-fiscal.cod-estabel        = inPayload:GetCharacter('codigoEstabelecimento')
                  and b-nota-fiscal.serie              = inPayload:GetCharacter('serie')
                  and b-nota-fiscal.nr-nota-fis        = inPayload:GetCharacter('numeroNotaFiscal')
                  and b-nota-fiscal.idi-sit-nf-eletro <> SituacaoNfeEnum:AUTORIZADA:GetValue()
                no-error.

        if available b-nota-fiscal then do.

            empty temp-table tt-nota-fiscal no-error.

            create tt-nota-fiscal.
            buffer-copy b-nota-fiscal to tt-nota-fiscal
                assign tt-nota-fiscal.r-Rowid = rowid( b-nota-fiscal ).

            this-object:runSefazAuthorization(  input h-acompanhar,
                                               output sitCode     ,
                                               output sitMessage  ,
                                               output attemptsUsed).

            if sitCode = 3 then
                this-object:addInvoicePayload( b-nota-fiscal.cod-estabel,
                                               b-nota-fiscal.serie      ,
                                               b-nota-fiscal.nr-nota-fis,
                                               sitMessage               ,
                                               ''                       ,
                                               true                     ).

            if b-nota-fiscal.idi-sit-nf-eletro <> SituacaoNfeEnum:AUTORIZADA:GetValue() then
                undo, throw new ThlError( this-object:GetClass():TypeName,
                                             'updateSefazWorker'            ,
                                             substitute(
                                                'Atualizacao Sefaz &1/&2/&3 &4 - &5',
                                                b-nota-fiscal.cod-estabel           ,
                                                b-nota-fiscal.serie                 ,
                                                b-nota-fiscal.nr-nota-fis           ,
                                                sitCode                             ,
                                                sitMessage
                                             )
                                           ).

        end.

        finally.
            if valid-handle( h-acompanhar ) then
                run pi-finalizar in h-acompanhar.
        end finally.

    end method.

    method private void notifyInvoiceWorker().

        define variable messageBody   as character           no-undo.
        define variable emailFactory  as EmailMessageFactory no-undo.

        if not available b-nota-fiscal then
            find first b-nota-fiscal  no-lock
                where b-nota-fiscal.cod-estabel        = inPayload:GetCharacter('codigoEstabelecimento')
                  and b-nota-fiscal.serie              = inPayload:GetCharacter('serie')
                  and b-nota-fiscal.nr-nota-fis        = inPayload:GetCharacter('numeroNotaFiscal')
                  and b-nota-fiscal.idi-sit-nf-eletro <> SituacaoNfeEnum:AUTORIZADA:GetValue()
                no-error.

        if available b-nota-fiscal then do.

            assign emailFactory = new EmailMessageFactory()
                   messageBody  = '<tr>' +
                                  '<td style="padding:10px;border:1px solid #ccc;vertical-align:top;">&1</td>' +
                                  '<td style="padding:10px;border:1px solid #ccc;vertical-align:top;">&2</td>' +
                                  '<td style="padding:10px;border:1px solid #ccc;vertical-align:top;word-break:break-word;">&3</td>' +
                                  '</tr>'
                   messageBody  = substitute( messageBody, b-nota-fiscal.cod-estabel, b-nota-fiscal.serie, b-nota-fiscal.nr-nota-fis )
                   emailFactory:attachmentPath = inPayload:GetCharacter('arquivo')
                   emailFactory:toRecipients   = emailFactory:toRecipients + if inPayload:has('email') then ';' + inPayload:GetCharacter('email')
                                                                                                       else ''.

            emailFactory:applyPlaceholder('body', '#1#', messageBody).
            new EmailService(emailFactory):sender().

            this-object:addInvoicePayload( b-nota-fiscal.cod-estabel        ,
                                           b-nota-fiscal.serie              ,
                                           b-nota-fiscal.nr-nota-fis        ,
                                           'envio de e-mail'                ,
                                           inPayload:GetCharacter('arquivo'),
                                           true                             ).

        end.

    end method.


end class.
