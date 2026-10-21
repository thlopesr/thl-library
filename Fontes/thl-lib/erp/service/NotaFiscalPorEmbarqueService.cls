 /*------------------------------------------------------------------------
    File        : NotaFiscalPorEmbarqueService
    Purpose     : Operacoes de negocio de notas fiscais POR EMBARQUE:
                  calculo/geracao via bodi317/ft4001a, XML NF-e,
                  autorizacao SEFAZ, impressao e notificacao.
    Author(s)   : Lopes
    Created     : 2026-06-11
    Notes       : Fase 4 (2026-07-26) - implementa IService; dispatcher
                  execute(action, operation) substitui os 5 metodos publicos
                  P3. O embarque e localizado em initialize (toda
                  operacao depende dele).
                  2026-10-08: o roteamento por operacao foi para o
                  NotaFiscalProcessor; aqui ficam as etapas, publicas.
                  Chaves de resposta historicas ('sefaz'/'arquivoValido')
                  preservadas via hooks - unificacao pendente (item 3.3).
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-lib.core.error.*.
using thl-lib.erp.core.ServiceResponse.
using thl-lib.erp.enum.ActionEnum.
using thl-lib.erp.enum.SituacaoNfeEnum.
using thl-lib.erp.service.NotaFiscalBaseService.

block-level on error undo, throw.

class thl-lib.erp.service.NotaFiscalPorEmbarqueService inherits NotaFiscalBaseService.

    define private buffer b-embarque for embarque.

    method public override character getEntityName().
        return 'Nota Fiscal Embarque'.
    end method.

    method public override void initialize().
        super:initialize().
        find first b-embarque no-lock
            where b-embarque.cdd-embarq = this-object:inContext:GetDecimal('codigoEmbarque') no-error.
        if not available b-embarque then
            this-object:error:throwError( 'initialize', 'Embarque nao localizado.' ).
    end method.

    //Um metodo por acao: criar = gerar as notas do embarque. As demais etapas
    //sao chamadas pelo NotaFiscalProcessor, que orquestra pela operacao da URL.
    method public override void create().
        this-object:generateInvoice().
    end method.

    //a geracao por embarque ja exporta o XML das notas geradas
    method public override void generateInvoice().
        this-object:createByShipment().
        this-object:generateNfeXmlWorker().
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
        if available b-embarque then
           return string(b-embarque.cdd-embarq).
        return ''.
    end method.

    //Contrato externo historico da rota notafiscal/embarque - item 3.3.
    method protected override character getStatusMessageKey().
        return 'sefaz'.
    end method.

    method protected override character getValidFileKey().
        return 'arquivoValido'.
    end method.

    /*--------------------------------------------------------------------------
      Calcula o embarque via BOFs e gera as notas fiscais (ft4001a).
      setPreFaturFree e executado no FINALLY para garantir liberacao do embarque
      mesmo em caso de excecao.
    --------------------------------------------------------------------------*/
    method private void createByShipment().

        define variable h-bodi176            as handle    no-undo.
        define variable h-bodi317            as handle    no-undo.
        define variable h-bodi317pr          as handle    no-undo.
        define variable h-bodi317sd          as handle    no-undo.
        define variable h-bodi317im1bra      as handle    no-undo.
        define variable h-bodi317va          as handle    no-undo.
        define variable h-bodi317in          as handle    no-undo.
        define variable h-bodi162            as handle    no-undo.
        define variable l-proc-ok-aux        as logical   no-undo.
        define variable i-linhas             as integer   no-undo.
        define variable c-ultimo-metodo-exec as character no-undo.

        find first estabelec of b-embarque no-lock no-error.

        run dibo/bodi162-2.p persistent set h-bodi162.
        run dibo/bodi317in.p persistent set h-bodi317in.
        run dibo/bodi176.p   persistent set h-bodi176.
        run dibo/bodi317.p   persistent set h-bodi317.

        run inicializaBOS in h-bodi317in( output h-bodi317pr    ,
                                          output h-bodi317sd    ,
                                          output h-bodi317im1bra,
                                          output h-bodi317va    ).

        do transaction.

            run setConstraintEmbarque in h-bodi176 ( input b-embarque.cdd-embarq ).
            run openQueryEmbarque     in h-bodi176.
            run getBatchRecords       in h-bodi176 (  input  ?  ,
                                                      input  yes,
                                                      input  ?  ,
                                                     output i-linhas        ,
                                                     output table tt-res-cli).

            run emptyRowErrors        in h-bodi317in.

            run validaNrEmbarque      in h-bodi317va(  input  b-embarque.cdd-embarq,
                                                      output  l-proc-ok-aux        ).

            run devolveErrosbodi317va in h-bodi317va( output c-ultimo-metodo-exec,
                                                      output table RowErrors     ).

            this-object:throwRowErrorsIfAny( 'createByShipment', 'h-bodi317va validaNrEmbarque' ).

            run setPreFaturInUse in h-bodi162( input b-embarque.cdd-embarq ).

            run emptyRowErrors            in h-bodi317in.
            run validaCabecalhoDoEmbarque in h-bodi317va(  input  b-embarque.cdd-embarq ,
                                                           input  b-embarque.cod-estabel,
                                                           input  estabelec.serie       ,
                                                           input  today                 ,
                                                           input  today                 ,
                                                           input  ?                     ,
                                                          output  l-proc-ok-aux         ).

            run devolveErrosbodi317va     in h-bodi317va( output c-ultimo-metodo-exec,
                                                          output table RowErrors     ).

            this-object:throwRowErrorsIfAny( 'createByShipment', 'h-bodi317va validaCabecalhoDoEmbarque' ).

            for each tt-res-cli.
                assign tt-res-cli.log-2 = yes.
            end.

            run liberaWtDoctoDoEbmarque in h-bodi317pr (  input  b-embarque.cdd-embarq,
                                                         output  l-proc-ok-aux        ).

            if not l-proc-ok-aux then
                undo, throw new ThlError( this-object:GetClass():TypeName, 'createByShipment',
                    'Falha na liberacao de wt-docto do embarque.' ).

            run ftp/ft4001a.p (  input  true           ,
                                 input  estabelec.serie,
                                 input  today          ,
                                 input  today          ,
                                 input  ?              ,
                                 input  table tt-res-cli,
                                 input  ?              ,
                                output table RowErrors     ,
                                output table tt-nota-gerada,
                                output l-proc-ok-aux       ).

            this-object:throwRowErrorsIfAny( 'createByShipment', 'Efetua o calculo do embarque' ).

        end.

        run eliminaRegistrosWorkTableXEmbarque in h-bodi317sd(  input  b-embarque.cdd-embarq,
                                                                input  0                    ,
                                                                input  9999999              ,
                                                               output  l-proc-ok-aux        ).

        for each tt-nota-gerada no-lock.
            this-object:addInvoicePayload( b-embarque.cod-estabel,
                                           estabelec.serie       ,
                                           tt-nota-gerada.nr-nota,
                                           ''                    ,
                                           ''                    ,
                                           true                  ).
        end.

        finally.
            run setPreFaturFree               in h-bodi162    ( input b-embarque.cdd-embarq ) no-error.
            run finalizaBOS                   in h-bodi317in  no-error.
            delete procedure h-bodi162        no-error.
            delete procedure h-bodi176        no-error.
            delete procedure h-bodi317        no-error.
            delete procedure h-bodi317in      no-error.
            delete procedure h-bodi317pr      no-error.
            delete procedure h-bodi317sd      no-error.
            delete procedure h-bodi317im1bra  no-error.
            delete procedure h-bodi317va      no-error.
        end finally.

    end method.

    method private void printInvoiceWorker().

        define variable invoiceFile as character no-undo.

        for each b-nota-fiscal of b-embarque no-lock
            where b-nota-fiscal.idi-sit-nf-eletro = SituacaoNfeEnum:AUTORIZADA:GetValue().

            assign invoiceFile = this-object:printInvoiceDocument().

            this-object:addInvoicePayload( b-nota-fiscal.cod-estabel,
                                           b-nota-fiscal.serie      ,
                                           b-nota-fiscal.nr-nota-fis,
                                           ''                       ,
                                           invoiceFile              ,
                                           search(invoiceFile) <> ? ).

        end.

    end method.

    method private void generateNfeXmlWorker().

        define buffer b-nota-fiscal-ult for nota-fiscal.

        define variable tempFile      as character no-undo.
        define variable resultMessage as character no-undo.

        find first b-nota-fiscal     of b-embarque no-lock no-error.
        find last  b-nota-fiscal-ult of b-embarque no-lock no-error.
        
        if not available b-nota-fiscal     or
           not available b-nota-fiscal-ult then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'generateNfeXmlWorker',
                    'Nota Fiscal nao localizada.' ).

        assign tempFile = this-object:exportNfeXml(  input b-nota-fiscal.cod-estabel    ,
                                                     input b-nota-fiscal.serie          ,
                                                     input b-nota-fiscal.nr-nota-fis    ,
                                                     input b-nota-fiscal-ult.nr-nota-fis,
                                                    output resultMessage                ).

        this-object:addInvoicePayload( b-nota-fiscal-ult.cod-estabel,
                                       b-nota-fiscal-ult.serie      ,
                                       b-nota-fiscal-ult.nr-nota-fis,
                                       resultMessage                ,
                                       tempFile                     ,
                                       search(tempFile) <> ?        ).

    end method.

    method private void updateSefazWorker().

        define variable h-acompanhar as handle    no-undo.
        define variable sitCode      as integer   no-undo.
        define variable sitMessage   as character no-undo.
        define variable attemptsUsed as integer   no-undo.

        run utp/ut-acomp.p persistent set h-acompanhar.

        run pi-inicializar in h-acompanhar ( input 'Atualizando' ).

        for each b-nota-fiscal of b-embarque no-lock
            where b-nota-fiscal.idi-sit-nf-eletro <> SituacaoNfeEnum:AUTORIZADA:GetValue(). //{diinc/i01di135.i 2}

            empty temp-table tt-nota-fiscal no-error.

            create tt-nota-fiscal.
            buffer-copy b-nota-fiscal to tt-nota-fiscal
                assign tt-nota-fiscal.r-Rowid = rowid( b-nota-fiscal ).

            this-object:runSefazAuthorization(  input h-acompanhar,
                                               output sitCode     ,
                                               output sitMessage  ,
                                               output attemptsUsed).

            if attemptsUsed > this-object:getSefazMaxAttempts() then
                this-object:addInvoicePayload( b-nota-fiscal.cod-estabel,
                                               b-nota-fiscal.serie      ,
                                               b-nota-fiscal.nr-nota-fis,
                                               substitute('[Tentativas &1] &2 - &3', attemptsUsed, sitCode, sitMessage ),
                                               ''                       ,
                                               true                     ).
            else
                this-object:addInvoicePayload( b-nota-fiscal.cod-estabel,
                                               b-nota-fiscal.serie      ,
                                               b-nota-fiscal.nr-nota-fis,
                                               sitMessage               ,
                                               ''                       ,
                                               true                     ).

        end.

        finally.
            if valid-handle( h-acompanhar ) then
                run pi-finalizar in h-acompanhar.
        end finally.

    end method.

    method private void notifyInvoiceWorker().

        define variable detail as character no-undo.
        define variable count  as integer   no-undo.

        if inPayload:has('details')                      and
           inPayload:GetJsonArray('details'):Length <> 0 then do.

            do count = 1 to inPayload:GetJsonArray('details'):Length.
                assign detail = substitute( '&1<br>&2 - &3',
                                            detail         ,
                                            inPayload:GetJsonArray('details'):GetJsonObject(count):GetCharacter('code')   ,
                                            inPayload:GetJsonArray('details'):GetJsonObject(count):GetCharacter('message')
                                          ).
            end.

        end.

        run ftp/esft1932a.p (  input b-embarque.cdd-embarq,
                               input detail               ).

        outPayload:add( return-value ).

    end method.

end class.
