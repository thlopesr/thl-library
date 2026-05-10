 
 /*------------------------------------------------------------------------
    File        : JsonService
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Fri Oct 03 15:42:29 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

routine-level on error undo, throw.

class thl-lib.util.json.JsonWriter serializable.

    //Serializa um BUFFER handle (record buffer) para JSON
    method public static longchar toJsonFromBuffer( input bufferHandle as handle   ,
                                                    input rootName     as character,
                                                    input prettyPrint  as logical  ).
                                                    
        define variable ds     as handle   no-undo.
        define variable json   as longchar no-undo.

        if bufferHandle = ? or not valid-handle(bufferHandle) then
            undo, throw new AppError('toJsonFromBuffer: invalid handle.', 17006).
        
        create dataset ds.
        assign ds:serialize-name = rootName.

        ds:add-buffer( bufferHandle ).
        ds:write-json( 'LONGCHAR', json, prettyPrint).

        return json.
        
        finally.
            delete object ds no-error.
        end finally.
        
    end method.

    //Overload simples
    method public static longchar toJsonFromBuffer( input bufferHandle as handle ).
        return toJsonFromBuffer( bufferHandle, 'register', true ).
    end method.

end class.