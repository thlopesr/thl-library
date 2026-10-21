/*------------------------------------------------------------------------
    File        : FileContentSearcher
    Purpose     : Implementacao de IFileEnricher que busca uma palavra-chave
                  no conteudo dos arquivos de um ScannedFileSet.
                  Enriquece cada arquivo com searchText, found, matchCount,
                  firstMatchLine.
    Author(s)   : Lopes
    Created     : 2026-09-16
    Notes       : Arquivos com excluded = true sao ignorados.
                  Busca por word-boundary quando delimiters preenchido
                  (LOOKUP em lista separada por virgula); substring pura
                  quando delimiters vazio.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

using thl-lib.logging.LogUtil.
using thl-lib.util.scanner.IFileEnricher.
using thl-lib.util.scanner.ScannedFileSet.

block-level on error undo, throw.

class thl-lib.util.scanner.FileContentSearcher implements IFileEnricher.

    define private stream fileStream.

    define public property searchText as character no-undo get. private set.
    define public property delimiters as character no-undo get. private set.

    constructor public FileContentSearcher( input searchText as character,
                                            input delimiters as character ).

        assign this-object:searchText = searchText
               this-object:delimiters = delimiters.

    end constructor.

    method public void enrich( input fileSet as ScannedFileSet ).

        define variable fullPath  as character no-undo.
        define variable excluded  as logical   no-undo.
        define variable lowerText as character no-undo.

        assign lowerText = lc( trim( this-object:searchText ) ).

        fileSet:openQuery().

        repeat:

            if not fileSet:getNext( output fullPath, output excluded ) then leave.

            if excluded then do:
                fileSet:setSearchResult( fullPath, this-object:searchText, false, 0, 0 ).
                next.
            end.

            searchInFile( fullPath, lowerText, fileSet ).

        end.

        LogUtil:write( substitute( 'Busca concluida: texto=&1 arquivos-com-match=&2 total-ocorrencias=&3',
                                   this-object:searchText,
                                   fileSet:matchedFileCount,
                                   fileSet:totalMatchCount ),
                       this-object:GetClass():TypeName ).

    end method.

    method private void searchInFile( input fullPath  as character,
                                      input lowerText as character,
                                      input fileSet   as ScannedFileSet ).

        define variable lineText       as character no-undo.
        define variable lineNumber     as integer   no-undo.
        define variable matchCount     as integer   no-undo.
        define variable firstMatchLine as integer   no-undo.
        define variable lineMatches    as integer   no-undo.

        assign lineNumber     = 0
               matchCount     = 0
               firstMatchLine = 0.

        input stream fileStream from value( fullPath ) no-echo.

        repeat:

            import stream fileStream unformatted lineText.

            assign lineNumber = lineNumber + 1.

            if this-object:delimiters <> '' then
                assign lineMatches = countTokenOccurrences( lc( lineText ), lowerText, this-object:delimiters ).
            else
                assign lineMatches = countSubstringOccurrences( lc( lineText ), lowerText ).

            if lineMatches > 0 then do:

                assign matchCount = matchCount + lineMatches.

                if firstMatchLine = 0 then
                    assign firstMatchLine = lineNumber.

            end.

        end.

        fileSet:setSearchResult( fullPath, this-object:searchText,
                                 matchCount > 0, matchCount, firstMatchLine ).

        finally:
            input stream fileStream close.
        end finally.

    end method.

    method private static integer countTokenOccurrences( input lineText   as character,
                                                         input searchText as character,
                                                         input delimiters as character ).

        define variable count      as integer   no-undo.
        define variable startPos   as integer   no-undo.
        define variable foundPos   as integer   no-undo.
        define variable endPos     as integer   no-undo.
        define variable charBefore as character no-undo.
        define variable charAfter  as character no-undo.

        assign count    = 0
               startPos = 1.

        repeat:

            assign foundPos = index( lineText, searchText, startPos ).

            if foundPos = 0 then leave.

            assign endPos = foundPos + length( searchText ).

            if foundPos = 1 then
                assign charBefore = ''.
            else
                assign charBefore = substring( lineText, foundPos - 1, 1 ).

            if endPos > length( lineText ) then
                assign charAfter = ''.
            else
                assign charAfter = substring( lineText, endPos, 1 ).

            if ( charBefore = '' or isDelimiter( charBefore, delimiters ) ) and
               ( charAfter  = '' or isDelimiter( charAfter, delimiters ) ) then
                assign count = count + 1.

            assign startPos = endPos.

        end.

        return count.

    end method.

    method private static integer countSubstringOccurrences( input lineText   as character,
                                                             input searchText as character ).

        define variable count    as integer no-undo.
        define variable startPos as integer no-undo.
        define variable foundPos as integer no-undo.

        assign count    = 0
               startPos = 1.

        repeat:

            assign foundPos = index( lineText, searchText, startPos ).

            if foundPos = 0 then leave.

            assign count    = count + 1
                   startPos = foundPos + length( searchText ).

        end.

        return count.

    end method.

    method private static logical isDelimiter( input singleChar as character,
                                               input delimiters as character ).

        return lookup( singleChar, delimiters ) > 0.

    end method.

end class.
