/*------------------------------------------------------------------------
    File        : ProgramCompiler
    Purpose     : Compila um arquivo por vez com COMPILE ... SAVE NO-ERROR e
                  devolve o resultado individual (COMPILER:ERROR,
                  COMPILER:ERROR-ROW, COMPILER:ERROR-COLUMN, COMPILER:FILE-NAME
                  e mensagens de ERROR-STATUS).
    Author(s)   : Lopes
    Created     : 2026-09-16
    Notes       : Compilacao individual, e nao em lote: COMPILE aceita um
                  arquivo por instrucao e o objetivo e capturar a falha de
                  cada fonte sem abortar os demais.
                  Nao altera o PROPATH: includes e classes referenciadas
                  precisam estar resolviveis na sessao chamadora.
                  COMPILE exige licenca de desenvolvimento OpenEdge.
                  saveDirectory vazio grava o r-code no diretorio do fonte.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

using thl-lib.core.error.ErrorHandler.
using thl-lib.logging.LogUtil.
using thl-lib.util.compile.CompilationResult.
using thl-lib.util.string.StringUtil.

block-level on error undo, throw.

class thl-lib.util.compile.ProgramCompiler.

    define private property saveDirectory as character no-undo get. private set.

    define private variable errorHandler as ErrorHandler no-undo.

    constructor public ProgramCompiler( input saveDirectory as character ).

        assign this-object:saveDirectory = StringUtil:getText( saveDirectory )
               errorHandler              = new ErrorHandler( this-object:GetClass():TypeName ).

    end constructor.

    method public CompilationResult compileFile( input filePath as character ).

        define variable compilation as CompilationResult no-undo.

        assign compilation = new CompilationResult( filePath ).

        if this-object:saveDirectory = '' then
            compile value( filePath ) save no-error.
        else
            compile value( filePath ) save into value( this-object:saveDirectory ) no-error.

        if compiler:error then
            compilation:setError( collectErrorMessages(),
                                  StringUtil:getText( compiler:file-name ),
                                  compiler:error-row,
                                  compiler:error-column ).
        else
            compilation:setSuccess().

        LogUtil:write( substitute( 'Compilacao &1: &2 &3',
                                   if compilation:succeeded then 'OK' else 'ERRO',
                                   filePath,
                                   compilation:errorMessage ),
                       this-object:GetClass():TypeName ).

        return compilation.

        catch compileError as Progress.Lang.Error:

            compilation:setError( errorHandler:getErrorMessage( compileError ) ).

            LogUtil:write( substitute( 'Compilacao ERRO: &1 &2', filePath, compilation:errorMessage ),
                           this-object:GetClass():TypeName ).

            return compilation.

        end catch.

    end method.

    method private character collectErrorMessages().

        define variable messageIndex  as integer   no-undo.
        define variable errorMessages as character no-undo.

        do messageIndex = 1 to error-status:num-messages:
            assign errorMessages = errorMessages
                                 + ( if errorMessages = '' then '' else ' | ' )
                                 + error-status:get-message( messageIndex ).
        end.

        if errorMessages = '' then
            assign errorMessages = 'Erro de compilacao sem mensagem detalhada.'.

        return errorMessages.

    end method.

end class.
