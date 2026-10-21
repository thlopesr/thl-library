/*------------------------------------------------------------------------
    File        : EmitenteService
    Purpose     : Servico de dominio para consulta de emitente e local de
                  entrega nas tabelas emitente e loc-entr do Datasul.
                  Sem logica de apresentacao ou serializacao JSON.
    Author(s)   : Lopes
    Created     : 2026-08-11
    Notes       : Servico de consulta puro — nao implementa IService.
                  Fallback: busca por cod-emitente quando informado (> 0);
                  por nome-abrev quando cod-emitente = 0.
                  Mesmo criterio para loc-entr: chave composta quando ambos
                  informados; fallback por nome-abrev.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.

block-level on error undo, throw.

class thl-lib.erp.service.LocalEntregaService inherits Service.

    define private buffer b-emitente for emitente.
    define private buffer b-loc-entr for loc-entr.

    method public override character getEntityName().
        return 'Local Entrega'.
    end method.

    method public override character loadReferenceCode().
        if available b-loc-entr then
            return substitute( '&1#&2', b-loc-entr.nome-abrev, b-loc-entr.cod-entrega).
        return ''.
    end method.
    
    //GET pelo Processor: le os filtros da query e devolve o mesmo objeto do get()
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getInteger( 'codigo' , 0  ),
                                queryParameters:getText   ( 'nome'   , '' ),
                                queryParameters:getText   ( 'entrega', '' ) ).
    end method.

    method public JsonObject get ( input cod-emitente as integer   ,
                                   input nome-abrev   as character ,
                                   input cod-entrega  as character ).

        define variable localEntrega   as JsonObject no-undo.

        find first b-emitente no-lock
            where b-emitente.nome-abrev   = nome-abrev
               or b-emitente.cod-emitente = cod-emitente no-error.
               
        find first b-loc-entr of b-loc-entr no-lock
            where b-loc-entr.cod-entrega = cod-entrega no-error.
           
        if not available b-loc-entr then  
            undo, throw new ThlError( this-object:GetClass():TypeName, 'get',
                substitute( 'Local de entrega nao localizado &1/&2/&3', nome-abrev, cod-emitente, cod-entrega ) ).
            
        assign localEntrega = new JsonObject().

        localEntrega:Add( 'codigoEmitente', b-emitente.cod-emitente         ).
        localEntrega:Add( 'nomeAbreviado' , b-emitente.nome-abrev           ).
        localEntrega:Add( 'codigoEntrega' , b-loc-entr.cod-entrega          ).
        localEntrega:Add( 'endereco'      , b-loc-entr.endereco             ).
        localEntrega:Add( 'referenceCode' , this-object:loadReferenceCode() ).

        return localEntrega.

    end method.
    
end class.
