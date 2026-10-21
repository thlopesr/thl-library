
 /*------------------------------------------------------------------------
    File        : JsonSetter
    Purpose     :
    Syntax      :
    Description :
    Author(s)   : Lopes
    Created     : Tue Sep 02 21:18:10 BRT 2025
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using thl-lib.core.error.ThlError.

routine-level on error undo, throw.

class thl-lib.util.json.JsonSetter.

    define private property payload as JsonObject no-undo get. set.

    constructor public JsonSetter( input payload as JsonObject ).
        this-object:setPayload(payload).
    end constructor.

    method public void setPayload( input payload as JsonObject ).
        if not valid-object(payload) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'setPayload', 'payload nao informado.' ).
        assign this-object:payload = payload.
    end method.

    method public void SetValue( input-output valueField as character,
                                 input        nameField  as character ).

        define variable valueFieldNew as longchar no-undo.

        assign fix-codepage(valueFieldNew) = 'UTF-8'
               valueFieldNew               = if payload:Has( trim(nameField) ) then payload:GetCharacter( trim(nameField) ) else valueField
               valueField                  = valueFieldNew.

    end method.

    //Numero que a integracao manda entre aspas ("10") tambem vale, se for numerico;
    //texto em branco mantem o valor atual, como campo ausente.
    method public void SetValue( input-output valueField as integer,
                                 input        nameField  as character ).

        define variable fieldName as character no-undo.

        assign fieldName = trim( nameField ).

        if not payload:Has( fieldName ) then
            return.

        if payload:GetType( fieldName ) = JsonDataType:STRING then do.
            if trim( payload:GetCharacter( fieldName ) ) <> '' then
                assign valueField = integer( trim( payload:GetCharacter( fieldName ) ) ).
            return.
        end.

        assign valueField = payload:GetInteger( fieldName ).

    end method.

    //Numero que a integracao manda entre aspas ("100" ou "100.50") tambem vale, se for
    //numerico; o ponto do JSON vira o separador decimal da sessao. Texto em branco
    //mantem o valor atual, como campo ausente.
    method public void SetValue( input-output valueField as decimal,
                                 input        nameField  as character ).

        define variable fieldName as character no-undo.

        assign fieldName = trim( nameField ).

        if not payload:Has( fieldName ) then
            return.

        if payload:GetType( fieldName ) = JsonDataType:STRING then do.
            if trim( payload:GetCharacter( fieldName ) ) <> '' then
                assign valueField = decimal( replace( trim( payload:GetCharacter( fieldName ) ), '.', session:numeric-decimal-point ) ).
            return.
        end.

        assign valueField = payload:GetDecimal( fieldName ).

    end method.

    method public void SetValue( input-output valueField as date,
                                 input        nameField  as character ).
        assign valueField = if payload:Has(trim(nameField)) then payload:GetDate(trim(nameField)) else valueField.
    end method.

    method public void SetValue( input-output valueField as logical,
                                 input        nameField  as character ).
        assign valueField = if payload:Has(trim(nameField)) then payload:GetLogical(trim(nameField)) else valueField.
    end method.

end class.
