/*------------------------------------------------------------------------
    File        : CompilationResult
    Purpose     : Objeto de valor com o resultado da compilacao de um
                  unico arquivo (sucesso ou detalhes da falha).
    Author(s)   : Lopes
    Created     : 2026-09-16
    Notes       : errorFile pode diferir de filePath quando o erro ocorre
                  dentro de um include (COMPILER:FILE-NAME).
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

block-level on error undo, throw.

class thl-lib.util.compile.CompilationResult.

    define public property filePath     as character no-undo get. private set.
    define public property succeeded    as logical   no-undo get. private set.
    define public property errorMessage as character no-undo get. private set.
    define public property errorFile    as character no-undo get. private set.
    define public property errorRow     as integer   no-undo get. private set.
    define public property errorColumn  as integer   no-undo get. private set.

    constructor public CompilationResult( input filePath as character ).

        assign this-object:filePath     = filePath
               this-object:succeeded    = false
               this-object:errorMessage = ''
               this-object:errorFile    = ''
               this-object:errorRow     = 0
               this-object:errorColumn  = 0.

    end constructor.

    method public void setSuccess().
        assign this-object:succeeded = true.
    end method.

    method public void setError( input pErrorMessage as character,
                                 input pErrorFile    as character,
                                 input pErrorRow     as integer,
                                 input pErrorColumn  as integer ).
        assign this-object:succeeded    = false
               this-object:errorMessage = pErrorMessage
               this-object:errorFile    = pErrorFile
               this-object:errorRow     = pErrorRow
               this-object:errorColumn  = pErrorColumn.
    end method.

    method public void setError( input pErrorMessage as character ).
        assign this-object:succeeded    = false
               this-object:errorMessage = pErrorMessage.
    end method.

end class.
