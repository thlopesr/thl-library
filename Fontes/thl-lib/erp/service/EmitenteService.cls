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

class thl-lib.erp.service.EmitenteService inherits Service.

    define private buffer b-emitente for emitente.

    method public override character getEntityName().
        return 'Emitente'.
    end method.

    method public override character loadReferenceCode().
        if available b-emitente then
            return b-emitente.nome-abrev.
        return ''.
    end method.
    
    //GET pelo Processor: le os filtros da query e devolve o mesmo objeto do get()
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getInteger( 'codigo', 0  ),
                                queryParameters:getText   ( 'nome'  , '' ) ).
    end method.

    method public JsonObject get ( input cod-emitente as integer   ,
                                   input nome-abrev   as character ).

        define variable emitente   as JsonObject no-undo.

        find first b-emitente no-lock
            where b-emitente.nome-abrev   = nome-abrev
               or b-emitente.cod-emitente = cod-emitente no-error.
           
        if not available b-emitente then  
            undo, throw new ThlError( this-object:GetClass():TypeName, 'get',
                substitute( 'Emitente nao localizado &1/&2', nome-abrev, cod-emitente) ).
            
        assign emitente = new JsonObject().

        emitente:Add( 'codigoEmitente', b-emitente.cod-emitente        ).
        emitente:Add( 'nomeAbreviado' , b-emitente.nome-abrev          ).
        emitente:Add( 'referenceCode' , this-object:loadReferenceCode()).

        return emitente.

    end method.
    
end class.
