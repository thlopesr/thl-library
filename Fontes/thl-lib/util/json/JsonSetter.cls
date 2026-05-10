 
 /*------------------------------------------------------------------------
    File        : 
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Tue Sep 02 21:18:10 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*. 

routine-level on error undo, throw.

class thl-lib.util.json.JsonSetter serializable.

    define public static property payload as JsonObject no-undo get. set. 

    method public static final void setValue( input-output valueField  as character ,
                                              input        nameField   as character ).
        
        define variable valueFieldNew as longchar no-undo.
                                                   
        assign fix-codepage(valueFieldNew) = 'UTF-8'
               valueFieldNew               = if payload:Has( trim(nameField) ) then payload:GetCharacter( trim(nameField) ) else valueField
               valueField                  = valueFieldNew.   
                                                                          
    end method.
    
    method public static final void setValue( input-output valueField  as integer   ,
                                              input        nameField   as character ).
        assign valueField = if payload:Has(trim(nameField)) then payload:GetInteger(trim(nameField)) else valueField.                                                              
    end method.
    
    method public static final void setValue( input-output valueField  as decimal   ,
                                              input        nameField   as character ).
        assign valueField = if payload:Has(trim(nameField)) then payload:GetDecimal(trim(nameField)) else valueField.                                                              
    end method.
    
    method public static final void setValue( input-output valueField  as date      ,
                                              input        nameField   as character ).
        assign valueField = if payload:Has(trim(nameField)) then payload:GetDate(trim(nameField)) else valueField.                                                              
    end method.
    
    method public static final void setValue( input-output valueField  as logical   ,
                                              input        nameField   as character ).
        assign valueField = if payload:Has(trim(nameField)) then payload:GetLogical(trim(nameField)) else valueField.                                                              
    end method.

end class.