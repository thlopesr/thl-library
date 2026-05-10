/*------------------------------------------------------------------------
    File        : ErrorHandler
    Purpose     : Centralized error handling for THL-Lib
    Description : Accumulates one or many errors and converts them to
                  AppError or JSON.
    Author(s)   : Lopes
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

block-level on error undo, throw.

class thl-lib.core.error.ErrorHandler.

    define private temp-table ttError no-undo
        field errorNumber  as integer
        field errorMessage as character.

    constructor public ErrorHandler().
    end constructor.

    method public void clearErrors().
        empty temp-table ttError no-error.
    end method.

    method public void createError().
        this-object:clearErrors().
    end method.

    method public void addError( errorNumber  as integer  ,
                                 errorMessage as character).
        create ttError.
        assign ttError.errorNumber  = errorNumber
               ttError.errorMessage = errorMessage.
    end method.

    method public logical hasErrors().
        return temp-table ttError:has-records.
    end method.

    method public AppError getError().

        define variable currentError as AppError no-undo.

        if this-object:hasErrors() then do.
            assign currentError = new AppError().
            for each ttError no-lock.
                currentError:AddMessage( ttError.errorMessage,
                                         ttError.errorNumber ).
            end.
        end.

        return currentError.

    end method.

    method public void throwIfHasErrors().
        if this-object:hasErrors() then
            undo, throw getError().
    end method.

    method public void throwError( errorNumber  as integer   ,
                                   errorMessage as character ).
  
        this-object:clearErrors().
        this-object:addError(errorNumber, errorMessage).

        this-object:throwIfHasErrors().

    end method.

    method public integer getErrorStatusCode(input errorObject as Error).

        if valid-object(errorObject) and
           errorObject:NumMessages > 0 and
           errorObject:GetMessageNum(1) <> 0 then
            return errorObject:GetMessageNum(1).

        return 500.

    end method.


    method public character getErrorMessage( errorObject as Error ).

        define variable errorIndex   as integer   no-undo.
        define variable errorMessage as character no-undo.

        if not isValideErrorObject(errorObject) then
            return 'Erro nao identificado no processamento da mensagem.'.

        do errorIndex = 1 to errorObject:NumMessages.
            assign errorMessage = errorMessage + ' | ' +  errorObject:GetMessage(errorIndex).
        end.

        return substring(errorMessage, 1, 200).

    end method.
    
    
    method public logical isValideErrorObject ( errorObject as Error).
        return valid-object(errorObject) and errorObject:NumMessages <> 0.
    end method.

    method public JsonObject getErrorJson(input errorObject as Error).

        define variable errorJson  as JsonObject no-undo.
        define variable errorsJson as JsonArray  no-undo.
        define variable itemJson   as JsonObject no-undo.
        define variable errorIndex as integer    no-undo.
        define variable errorCode  as integer    no-undo.

        assign errorJson  = new JsonObject()
               errorsJson = new JsonArray().

        errorJson:Add('success', false).

        if not isValideErrorObject(errorObject) then do.

            assign itemJson = new JsonObject().

            itemJson:Add('code', 500).
            itemJson:Add('message', 'Erro nao identificado no processamento da mensagem.').

            errorsJson:Add(itemJson).
            errorJson:Add('errors', errorsJson).

            return errorJson.

        end.

        do errorIndex = 1 to errorObject:NumMessages.

            assign itemJson  = new JsonObject().

            itemJson:Add('code'   , errorObject:GetMessageNum(errorIndex)).
            itemJson:Add('message', errorObject:GetMessage(errorIndex)   ).

            errorsJson:Add(itemJson).

        end.

        errorJson:Add('errors', errorsJson).

        return errorJson.

    end method.

    method public longchar getErrorJsonText(input errorObject as Error).

        define variable errorJson as JsonObject no-undo.
        define variable jsonText  as longchar   no-undo.

        assign errorJson = this-object:getErrorJson(errorObject).

        assign fix-codepage(jsonText) = 'UTF-8'
               jsonText              = errorJson:GetJsonText().

        return jsonText.

    end method.

end class.