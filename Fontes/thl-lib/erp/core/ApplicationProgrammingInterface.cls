/*------------------------------------------------------------------------
    File        : ApplicationProgrammingInterface
    Purpose     : Classe abstrata base para services que operam APIs TOTVS
                  internas (.p persistentes via RUN PERSISTENT). Centraliza
                  a definicao de tt-erro e a logica de traducao de erros
                  retornados por pi-devolve-tt-erro.
    Author(s)   : Lopes
    Created     : 2026-07-17
    Notes       : Nao gerencia handle de API — cada metodo concreto declara
                  seu apiHandle local e o finaliza no proprio FINALLY
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

using thl-lib.core.error.*.
using thl-lib.erp.core.Service.

block-level on error undo, throw.

class thl-lib.erp.core.ApplicationProgrammingInterface abstract inherits Service.

    define protected property error  as ErrorHandler   no-undo get. private   set. 

    define protected temp-table tt-erro no-undo
        field i-sequen  as integer
        field cd-erro   as integer
        field mensagem  as character
        field parametro as character
        index ch-seq is primary i-sequen.

    method protected void throwApiErrorsIfAny( methodName  as character ).
        this-object:throwApiErrorsIfAny( methodName, '' ).
    end method.
    
    method protected void throwApiErrorsIfAny( methodName  as character ,
                                               stepName    as character ).
        assign this-object:error = new ErrorHandler( this-object:GetClass():TypeName, methodName, stepName ).

        for each tt-erro.
            error:addError(tt-erro.cd-erro, tt-erro.mensagem).
        end.
        error:throwIfHasErrors().
        
    end method.

end class.
