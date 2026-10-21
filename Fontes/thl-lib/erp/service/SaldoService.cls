/*------------------------------------------------------------------------
    File        : SaldoService
    Purpose     : Servico de consulta de saldo disponivel de item por
                  estabelecimento. Agrega saldo-estoq por cod-estabel +
                  it-codigo e calcula qt-disponivel.
    Author(s)   : Lopes
    Created     : 2026-08-11
    Notes       : Servico de consulta puro — nao implementa acoes CRIADO/
                  ATUALIZADO/DELETADO. Valida existencia do item antes
                  de consultar saldo.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.

block-level on error undo, throw.

class thl-lib.erp.service.SaldoService inherits Service.

    define private buffer b-item-estab for item-estab.

    method public override character getEntityName().
        return 'Saldo Item'.
    end method.

    method public override character loadReferenceCode().
        return substitute('&1#&2', b-item-estab.cod-estabel, b-item-estab.it-codigo ).
    end method.

    //GET pelo Processor: le os filtros da query e devolve o mesmo objeto do get()
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getText( 'estabel', '' ),
                                queryParameters:getText( 'codigo' , '' ) ).
    end method.

    method public JsonObject get( input cod-estabel as character,
                                  input it-codigo   as character ).

        define variable result              as JsonObject no-undo.
        define variable currentQuantity     as decimal    no-undo.
        define variable allocatedQuantity   as decimal    no-undo.
        define variable prodAllocQuantity   as decimal    no-undo.
        define variable orderAllocQuantity  as decimal    no-undo.
        define variable availableQuantity   as decimal    no-undo.

        find first b-item-estab no-lock
            where b-item-estab.cod-estabel = cod-estabel
              and b-item-estab.it-codigo   = it-codigo no-error.

        if not available b-item-estab then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'get',
                substitute( 'Item do estabel nao localizado &1/&2', it-codigo, cod-estabel ) ).

        for each saldo-estoq no-lock
            where saldo-estoq.cod-estabel = cod-estabel
              and saldo-estoq.it-codigo   = it-codigo.

            assign currentQuantity    = currentQuantity    + saldo-estoq.qtidade-atu
                   allocatedQuantity  = allocatedQuantity  + saldo-estoq.qt-alocada
                   prodAllocQuantity  = prodAllocQuantity  + saldo-estoq.qt-aloc-prod
                   orderAllocQuantity = orderAllocQuantity + saldo-estoq.qt-aloc-ped.

        end.

        assign availableQuantity = currentQuantity - allocatedQuantity
                                                   - prodAllocQuantity
                                                   - orderAllocQuantity.

        assign result = new JsonObject().
        result:Add( 'it-codigo'    , it-codigo           ).
        result:Add( 'cod-estabel'  , cod-estabel         ).
        result:Add( 'qtidade-atu'  , currentQuantity     ).
        result:Add( 'qt-alocada'   , allocatedQuantity   ).
        result:Add( 'qt-aloc-prod' , prodAllocQuantity   ).
        result:Add( 'qt-aloc-ped'  , orderAllocQuantity  ).
        result:Add( 'qt-disponivel', availableQuantity   ).
        result:Add( 'referenceCode' , this-object:loadReferenceCode()).

        return result.

    end method.

end class.
