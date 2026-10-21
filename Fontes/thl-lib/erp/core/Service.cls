/*------------------------------------------------------------------------
   File        : Service
   Purpose     : Base abstrata de todos os Services ERP da THL-Library:
                 regra e dados de uma entidade. Os verbos (create, update,
                 delete, consult) tem defaults que lancam ThlError;
                 subclasses sobrescrevem apenas os que suportam.
   Author(s)   : Lopes
   Created     : 2026-08-12
   Notes       : Desde 2026-10-04 o Service nao orquestra: quem recebe a acao,
                 prepara o Service, chama o verbo, pega a referencia e monta a
                 resposta e o Processor (thl-lib.integration.messaging.inbound.core.Processor). Por
                 isso os verbos sao publicos e o execute() saiu daqui.
                 BusinessObject e ApplicationProgrammingInterface herdam
                 desta classe, adicionando tratamento de erro especifico
                 (RowErrors / tt-erro). Services sem BOF/API herdam direto.
                 operation fica como property para subclasses que precisam
                 (ex: resposta com a operacao). Escolher o metodo pela
                 operacao e papel do Processor (ex: NotaFiscalProcessor).
 ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.QueryParameters.
using thl-lib.erp.core.ServiceResponse.
using thl-lib.erp.enum.ActionEnum.

block-level on error undo, throw.

class thl-lib.erp.core.Service abstract.

    define public    property inContext  as JsonObject no-undo get. protected set.
    define public    property outContext as JsonObject no-undo get. protected set.
    define protected property operation  as character  no-undo get. private   set.

    //parametros da consulta (acao Consultado); preenchido por prepareQuery()
    define protected property queryParameters as QueryParameters no-undo get. private set.

    //Escrita: o Processor informa a operacao e o payload antes de initialize() e do verbo
    method public void prepare( input operation as character  ,
                                input context   as JsonObject ).

        assign this-object:inContext = context
               this-object:operation = operation.

    end method.

    //Consulta: o contexto traz os parametros da query, nao um payload
    method public void prepareQuery( input operation as character  ,
                                     input context   as JsonObject ).

        assign this-object:inContext       = context
               this-object:operation       = operation
               this-object:queryParameters = new QueryParameters( context ).

    end method.

    //Prepara a escrita (chave, registro posicionado). Nao e chamado na consulta.
    method public void initialize().
    end method.

    method public void create().
        undo, throw new ThlError( this-object:GetClass():TypeName, 'create',
            substitute( 'Acao nao suportada &1', ActionEnum:CRIADO ) ).
    end method.

    method public void update().
        undo, throw new ThlError( this-object:GetClass():TypeName, 'update',
            substitute( 'Acao nao suportada &1', ActionEnum:ATUALIZADO ) ).
    end method.

    method public void delete().
        undo, throw new ThlError( this-object:GetClass():TypeName, 'delete',
            substitute( 'Acao nao suportada &1', ActionEnum:DELETADO ) ).
    end method.

    //Consulta: cada Service le os proprios filtros de queryParameters e devolve
    //a lista (JsonArray) ou um objeto unico (JsonObject).
    method public JsonConstruct consult().
        undo, throw new ThlError( this-object:GetClass():TypeName, 'consult',
            substitute( 'Acao nao suportada &1', ActionEnum:CONSULTADO ) ).
    end method.

    //Lista vira { items, hasNext }, o formato que o cliente ja recebe; objeto
    //unico segue como veio.
    method public JsonObject buildQueryResponse( input result as JsonConstruct ).

        define variable response as JsonObject no-undo.

        if valid-object( result ) and type-of( result, JsonObject ) then
            return cast( result, JsonObject ).

        assign response = new JsonObject().

        if valid-object( result ) and type-of( result, JsonArray ) then
            response:Add( 'items', cast( result, JsonArray ) ).
        else
            response:Add( 'items', new JsonArray() ).

        response:Add( 'hasNext', false ).

        return response.

    end method.

    method public JsonObject buildResponse( input action        as ActionEnum,
                                            input referenceCode as character ).
        return ServiceResponse:success( this-object:getEntityName(), action, referenceCode ).
    end method.

    method public abstract character loadReferenceCode().
    method public abstract character getEntityName().

end class.
