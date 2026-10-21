/*------------------------------------------------------------------------
    File        : BusinessObject
    Purpose     : Classe abstrata base para services que operam BOFs TOTVS
                  (bodi*.p via RUN PERSISTENT). Centraliza a definicao de
                  RowErrors e a logica de traducao de erros retornados por
                  devolveErros*.
    Author(s)   : Lopes
    Created     : 2026-07-17
    Notes       : Nao gerencia handle de BOF — cada metodo concreto declara
                  seu handle local e o finaliza no proprio FINALLY
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

using thl-lib.core.error.*.
using thl-lib.erp.core.Service.

block-level on error undo, throw.

class thl-lib.erp.core.BusinessObject abstract inherits Service.

    define protected property error  as ErrorHandler   no-undo get. set.

    define protected temp-table RowErrors no-undo
        field ErrorSequence    as integer
        field ErrorNumber      as integer
        field ErrorDescription as character
        field ErrorParameters  as character
        field ErrorType        as character
        field ErrorHelp        as character
        field ErrorSubType     as character.

    //Invariante: error e valido durante todo o ciclo de vida do Service —
    //subclasses podem chamar error:throwError antes de qualquer
    //throwRowErrorsIfAny (que o reinstancia com metodo/etapa especificos).
    constructor public BusinessObject().
        assign this-object:error = new ErrorHandler( this-object:GetClass():TypeName ).
    end constructor.

    method protected void throwRowErrorsIfAny( methodName  as character ).
        this-object:throwRowErrorsIfAny( methodName, '' ).
    end method.
    
    method protected void throwRowErrorsIfAny( methodName  as character ,
                                               stepName    as character ).
        
        if can-find( first RowErrors where RowErrors.ErrorSubType = 'Error' ) then do.
            assign this-object:error = new ErrorHandler( this-object:GetClass():TypeName, methodName, stepName ).

            for each RowErrors.
                error:addError(RowErrors.ErrorNumber, RowErrors.ErrorDescription ).
            end.
            error:throwIfHasErrors().
        end.
                
    end method.

end class.
