/*------------------------------------------------------------------------
    File        : ItemRequisicaoService
    Purpose     : Servico de dominio para exclusao de itens de requisicao
                  via boin168. Recebe o nr-requisicao e uma lista de itens
                  (sequencia + it-codigo) e remove cada item individualmente
                  pelo rowid da base via repositionRecord.
    Author(s)   : Lopes
    Created     : 2026-08-17
    Notes       : Herda BusinessObject (RowErrors para BOFs). Suporta
                  apenas a acao DELETADO.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.BusinessObject.

block-level on error undo, throw.

class thl-lib.erp.service.ItemRequisicaoService inherits BusinessObject.

    define private buffer b-it-requisicao for it-requisicao.

    method public override character getEntityName().
        return 'Item Requisicao'.
    end method.

    method public override character loadReferenceCode().
        return string( inContext:GetInteger('nr-requisicao') ).
    end method.

    method public override void delete().

        define variable h-boin168         as handle   no-undo.
        define variable items             as JsonArray no-undo.
        define variable requisitionNumber as integer  no-undo.
        define variable sequenceNumber    as integer  no-undo.
        define variable counter           as integer  no-undo.

        assign requisitionNumber = inContext:GetInteger('nr-requisicao')
               items             = inContext:GetJsonArray('items').

        do transaction.

            do counter = 1 to items:Length.

                assign sequenceNumber = items:GetJsonObject(counter):GetInteger('sequencia').

                find b-it-requisicao no-lock
                    where b-it-requisicao.nr-requisicao = requisitionNumber
                      and b-it-requisicao.sequencia     = sequenceNumber
                    no-error.

                if not available b-it-requisicao then
                    undo, throw new ThlError( this-object:GetClass():TypeName, 'delete',
                        substitute( 'Item nao localizado - requisicao &1 sequencia &2',
                                    requisitionNumber, sequenceNumber ) ).

                run inbo/boin168.p persistent set h-boin168.

                run openQueryStatic  in h-boin168 ( input 'main' ).
                run repositionRecord in h-boin168 ( input rowid( b-it-requisicao ) ).
                run emptyRowErrors   in h-boin168.
                run deleteRecord     in h-boin168.
                run getRowErrors     in h-boin168 ( output table RowErrors ).
                this-object:throwRowErrorsIfAny(
                    substitute( 'delete - requisicao &1 - sequencia &2',
                                requisitionNumber, sequenceNumber ),
                    'boin168' ).

                if valid-handle( h-boin168 ) then delete procedure h-boin168 no-error.

            end.

        end. // do transaction

        finally.
            if valid-handle( h-boin168 ) then delete procedure h-boin168 no-error.
        end finally.

    end method.

end class.
