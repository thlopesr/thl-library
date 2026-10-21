/*------------------------------------------------------------------------
    File        : PaginationHelper
    Purpose     : Infraestrutura reutilizavel de paginacao offset-based.
                  Encapsula o controle de skip/stop para queries FOR EACH
                  paginadas. Extraido de LpcoService (SRP).
    Author(s)   : Lopes
    Created     : 2026-07-25
    Notes       : Composicao — Services que precisam de GET paginado
                  instanciam este helper sem consumir slot de heranca.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

block-level on error undo, throw.

class thl-lib.util.pagination.PaginationHelper.

    define private property pageSize   as integer no-undo get. private set.
    define private property skipCount  as integer no-undo get. private set.
    define private property entryCount as integer no-undo get. private set.

    constructor public PaginationHelper ( pageSize   as integer,
                                          pageOffset as integer ).

        if pageSize   < 1 then assign pageSize   = 1.
        if pageOffset < 1 then assign pageOffset = 1.

        assign this-object:pageSize = pageSize
               skipCount            = ( pageOffset - 1 ) * pageSize
               entryCount           = 0.

    end method.

    method public void incrementPageCount().
        assign entryCount = entryCount + 1.
    end method.

    method public logical shouldSkipEntry().
        return entryCount <= skipCount.
    end method.

    method public logical shouldStopPaging().
        return entryCount > skipCount + pageSize.
    end method.

end class.
