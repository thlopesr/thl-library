/*------------------------------------------------------------------------
    File        : NotaFiscalProcessor
    Purpose     : Orquestracao da nota fiscal: um objeto, varios Services e
                  varias operacoes (etapas) na mesma acao (POST).
                  /resourcen/notafiscal/<etapa>
                  /resourcen/notafiscal/embarque/<etapa>
                  /resourcen/notafiscal/ninahub/<etapa>
    Author(s)   : Lopes
    Created     : 2026-10-06
    Notes       : Filha de thl-lib.integration.messaging.inbound.core.Processor.
                  - Etapa: sempre a ULTIMA parte da operacao (geracao,
                    geracao-xml, autorizacao-sefaz, impressao, notificacao,
                    processamento). O que vem antes (embarque/, ninahub/) so
                    escolhe a linha do thl0022 e nao e lido aqui.
                  - Service: vem da linha da operacao cadastrada no thl0022
                    (classe-service, por exemplo operacao embarque/geracao ->
                    NotaFiscalPorEmbarqueService). Este Processor nao instancia
                    Service nenhum; ele precisa herdar de NotaFiscalBaseService.
                  - Quem chama o metodo da etapa e este Processor (invokeWrite).
                    O Service nao le a operacao para se despachar.
                  - processamento: encadeia as etapas da nota direta, em uma
                    transacao, com a espera do retorno da SEFAZ entre o XML e
                    a autorizacao. Nao existe para a nota por embarque.
                  - O Processor nao le a rota.
                  Registrada em thl-objeto.classe-processor pelo nome completo.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.erp.enum.ActionEnum.
using thl-lib.erp.service.NotaFiscalBaseService.
using thl-lib.erp.service.NotaFiscalPorEmbarqueService.
using thl-lib.integration.messaging.inbound.core.Processor.

block-level on error undo, throw.

class thl-lib.integration.messaging.inbound.process.NotaFiscalProcessor inherits Processor.

    method public override JsonObject execute( input  action        as ActionEnum ,
                                               input  operation     as character  ,
                                               input  context       as JsonObject ,
                                               output referenceCode as character  ).

        define variable stage as character no-undo.

        if operation = ? then
            assign operation = ''.

        //a etapa e a ultima parte (geracao, embarque/geracao, ninahub/geracao...); o Service
        //da linha do cadastro ja foi escolhido pelo carregador
        assign stage = entry( num-entries( operation, '/' ), operation, '/' ).

        return super:execute( action, stage, context, output referenceCode ).

    end method.

    //A criacao (POST) tem uma operacao por etapa: este Processor chama o metodo
    //do Service de cada uma. Alterar e eliminar seguem o padrao.
    method protected override void invokeWrite( input action        as ActionEnum ,
                                                input targetService as Service    ,
                                                input operation     as character  ).

        define variable invoiceService as NotaFiscalBaseService no-undo.

        if action <> ActionEnum:CRIADO then do.
            super:invokeWrite( action, targetService, operation ).
            return.
        end.

        if not type-of( targetService, NotaFiscalBaseService ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'invokeWrite',
                substitute( 'Service &1 nao e de nota fiscal (NotaFiscalBaseService).', targetService:GetClass():TypeName ) ).

        assign invoiceService = cast( targetService, NotaFiscalBaseService ).

        case operation.
            when 'geracao'           then invoiceService:generateInvoice().
            when 'geracao-xml'       then invoiceService:generateNfeXml().
            when 'autorizacao-sefaz' then invoiceService:authorizeSefaz().
            when 'impressao'         then invoiceService:printInvoice().
            when 'notificacao'       then invoiceService:notifyInvoice().
            //when 'processamento'     then this-object:processSteps( invoiceService ).
            otherwise
                undo, throw new ThlError( this-object:GetClass():TypeName, 'invokeWrite',
                    substitute( 'Operacao nao suportada: &1', operation ) ).
        end case.

    end method.

end class.
