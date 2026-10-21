/*------------------------------------------------------------------------
    File        : ItemService
    Purpose     : Servico de dominio para consulta de item (it-codigo)
                  na tabela item do Datasul.
    Author(s)   : Lopes
    Created     : 2026-08-11
    Notes       : Servico de consulta puro — nao implementa IService.
                  Busca case-sensitive por it-codigo (padrao Datasul).
  ----------------------------------------------------------------------*/


using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-lib.erp.service.ItemService inherits Service.

    define private buffer b-item for item.

    method public override character getEntityName().
        return 'Item'.
    end method.

    method public override character loadReferenceCode().
        if available b-item then
            return b-item.it-codigo.
        return ''.
    end method.
    
    //GET pelo Processor: le os filtros da query e devolve o mesmo objeto do get()
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getText( 'codigo', '' ) ).
    end method.

    method public JsonObject get ( input it-codigo as character ).

        define variable item   as JsonObject no-undo.

        find first b-item no-lock
            where b-item.it-codigo = it-codigo no-error.
           
        if not available b-item then  
            undo, throw new ThlError( this-object:GetClass():TypeName, 'get',
                substitute( 'Item nao localizado &1', it-codigo ) ).
            
        assign item = new JsonObject().

        item:Add( 'codigoEmitente', b-item.it-codigo               ).
        item:Add( 'descricao'     , b-item.desc-item               ).
        item:Add( 'obsoleto'      , b-item.cod-obsoleto            ).
        item:Add( 'referenceCode' , this-object:loadReferenceCode()).

        return item.

    end method.
    
end class.
