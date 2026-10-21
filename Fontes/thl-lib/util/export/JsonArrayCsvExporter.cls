/*------------------------------------------------------------------------
    File        : JsonArrayCsvExporter
    Purpose     : Exporta um JsonArray para arquivo CSV.
                  Cada JsonObject do array vira uma linha.
                  Colunas podem ser auto-detectadas (propriedades do
                  primeiro objeto) ou informadas explicitamente.
    Author(s)   : Lopes
    Created     : 2026-09-17
    Notes       : Reutilizavel com qualquer JsonArray — resultado de
                  ScannedFileSet:toJsonArray(), consultas JSON, etc.
                  Valores que contenham o delimitador, aspas ou
                  quebra de linha sao escapados conforme RFC 4180.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.JsonDataType.

block-level on error undo, throw.

class thl-lib.util.export.JsonArrayCsvExporter.

    define private stream csvStream.

    define public property delimiter as character no-undo get. private set.

    constructor public JsonArrayCsvExporter().
        assign this-object:delimiter = ';'.
    end constructor.

    constructor public JsonArrayCsvExporter( input pDelimiter as character ).

        assign this-object:delimiter = pDelimiter.

    end constructor.

    method public character export( input data     as JsonArray,
                                     input filePath as character ).

        if data:Length = 0 then do:
            output stream csvStream to value( filePath ).
            output stream csvStream close.
            return filePath.
        end.

        return this-object:exportData( data, filePath, resolveColumns( data:GetJsonObject( 1 ) ) ).

    end method.

    method public character exportData( input data      as JsonArray ,
                                        input filePath  as character ,
                                        input columns_  as character ).

        define variable idx      as integer    no-undo.
        define variable colIdx   as integer    no-undo.
        define variable colName  as character  no-undo.
        define variable colCount as integer    no-undo.
        define variable line     as character  no-undo.
        define variable obj      as JsonObject no-undo.

        assign colCount = num-entries( columns_ ).

        output stream csvStream to value( filePath ).

        assign line = ''.

        do colIdx = 1 to colCount:
            if colIdx > 1 then
                assign line = line + this-object:delimiter.
            assign line = line + entry( colIdx, columns_ ).
        end.

        put stream csvStream unformatted line skip.

        do idx = 1 to data:Length:

            assign obj  = data:GetJsonObject( idx )
                   line = ''.

            do colIdx = 1 to colCount:

                assign colName = entry( colIdx, columns_ ).

                if colIdx > 1 then
                    assign line = line + this-object:delimiter.

                if obj:Has( colName ) then
                    assign line = line + escapeValue( getValueAsString( obj, colName ) ).

            end.

            put stream csvStream unformatted line skip.

        end.

        return filePath.

        finally:
            output stream csvStream close.
        end finally.

    end method.

    method private character resolveColumns( input obj as JsonObject ).

        define variable names  as character extent no-undo.
        define variable result as character        no-undo.
        define variable idx    as integer          no-undo.

        assign names  = obj:GetNames()
               result = ''.

        do idx = 1 to extent( names ).
            if idx > 1 then
                assign result = result + ','.
            assign result = result + names[idx].
        end.

        return result.

    end method.

    method private character getValueAsString( input obj      as JsonObject,
                                                input propName as character ).

        define variable propType as integer no-undo.

        assign propType = obj:GetType( propName ).

        case propType:

            when JsonDataType:STRING  then
                return obj:GetCharacter( propName ).

            when JsonDataType:NUMBER  then
                return string( obj:GetInt64( propName ) ).

            when JsonDataType:BOOLEAN then
                return string( obj:GetLogical( propName ) ).

            otherwise
                return ''.

        end case.

    end method.

    method private character escapeValue( input val as character ).

        if index( val, this-object:delimiter ) > 0
        or index( val, '"' ) > 0
        or index( val, '~n' ) > 0 then do:
            assign val = replace( val, '"', '""' ).
            return '"' + val + '"'.
        end.

        return val.

    end method.

end class.
