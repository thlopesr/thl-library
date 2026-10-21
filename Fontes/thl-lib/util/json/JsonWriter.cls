 
 /*------------------------------------------------------------------------
    File        : JsonWriter
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Fri Oct 03 15:42:29 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

using Progress.Json.ObjectModel.JsonArray.
using Progress.Lang.*.

class thl-lib.util.json.JsonWriter serializable.

    //Serializa um BUFFER handle (record buffer) para JSON
    method public static longchar toJsonFromBuffer( input bufferHandle as handle   ,
                                                    input prettyPrint  as logical  ).
                                                    

        define variable ttHandle as handle   no-undo.
        define variable ttBuffer as handle   no-undo.
        define variable context  as longchar no-undo.

        if not valid-handle(bufferHandle) then
            return ''. 
        
        create temp-table ttHandle.
        ttHandle:create-like-sequential(bufferHandle).
        ttHandle:temp-table-prepare(bufferHandle:table).
        
        ttBuffer = ttHandle:default-buffer-handle.
        ttBuffer:buffer-create().
        ttBuffer:buffer-copy(bufferHandle).
        
        ttBuffer:write-json('LONGCHAR', context, true).
                
        return context.
        
        finally:
            delete object ttHandle no-error.
            delete object ttBuffer no-error.
        end finally.
        
    end method.

    //Overload simples
    method public static longchar toJsonFromBuffer( input bufferHandle as handle ).
        return toJsonFromBuffer( bufferHandle, true ).
    end method.

    // Converte lista delimitada em JSON array de strings.
    // Ex: charListToJsonArray("a,b,c", ",") => ["a","b","c"]
    method public static longchar charListToJsonArray( input cList      as character,
                                                       input cDelimiter as character ).

        define variable jsonArray as JsonArray no-undo.
        define variable i         as integer   no-undo.

        if cList = '':u or cList = ? then return '[]':u.

        jsonArray = new JsonArray().

        do i = 1 to num-entries( cList, cDelimiter ):
            jsonArray:Add( entry( i, cList, cDelimiter ) ).
        end.

        return jsonArray:GetJsonText().

        finally.
            delete object jsonArray no-error.
        end finally.

    end method.

    // Overload com delimitador padrao ","
    method public static longchar charListToJsonArray( input cList as character ).
        return charListToJsonArray( cList, ',':u ).
    end method.

end class.