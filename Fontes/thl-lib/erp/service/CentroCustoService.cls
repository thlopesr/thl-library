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

class thl-lib.erp.service.CentroCustoService inherits Service.

    define private buffer b_ccusto for ems.ccusto.

    method public override character getEntityName().
        return 'Centro Custo'.
    end method.

    method public override character loadReferenceCode().
        return substitute( '&1#&2#&3', b_ccusto.cod_empresa, b_ccusto.cod_plano_ccusto, b_ccusto.cod_ccusto).
    end method.
    
    //GET pelo Processor: le os filtros da query e devolve o mesmo objeto do get()
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getText( 'empresa', '' ),
                                queryParameters:getText( 'plano'  , '' ),
                                queryParameters:getText( 'custo'  , '' ) ).
    end method.

    method public JsonObject get ( input cod_empresa      as character,
                                   input cod_plano_ccusto as character,
                                   input cod_ccusto       as character).

        define variable centroCusto as JsonObject no-undo.

        find first b_ccusto no-lock
            where b_ccusto.cod_empresa      = cod_empresa
              and b_ccusto.cod_plano_ccusto = cod_plano_ccusto
              and b_ccusto.cod_ccusto       = cod_ccusto
            no-error.
           
        if not available b_ccusto then  
            undo, throw new ThlError( this-object:GetClass():TypeName, 'get',
                substitute( 'Centro custo nao localizado &1', cod_ccusto ) ).
            
        assign centroCusto = new JsonObject().

        centroCusto:Add( 'empresa', b_ccusto.cod_empresa           ).
        centroCusto:Add( 'plano'  , b_ccusto.cod_plano_ccusto      ).
        centroCusto:Add( 'custo'  , b_ccusto.cod_ccusto            ).
        centroCusto:Add( 'referenceCode' , this-object:loadReferenceCode()).

        return centroCusto.

    end method.
    
end class.
