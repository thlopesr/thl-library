/*------------------------------------------------------------------------
    File        : ScannedFileSet
    Purpose     : Colecao tipada de arquivos varridos. Contrato central
                  entre FileScanner (produtor) e IFileEnricher (consumidor).
                  Encapsula temp-table ttScannedFile com campos de
                  descoberta e enriquecimento. Conversao para JsonArray
                  ocorre somente na borda (toJsonArray).
    Author(s)   : Lopes
    Created     : 2026-09-16
    Notes       : Buffer separado (bUpdateFile) para atualizacao sem
                  quebrar iteracao do query qFile.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Lang.*.

block-level on error undo, throw.

class thl-lib.util.scanner.ScannedFileSet.

    define private temp-table ttScannedFile no-undo
        field fullPath        as character
        field fileName        as character
        field folderName      as character
        field extension       as character
        field fileSize        as int64
        field lastModified    as date
        field rootDirectory   as character
        field relativePath    as character
        field excluded        as logical   initial false
        field excludedPattern as character
        field searchText      as character
        field found           as logical   initial false
        field matchCount      as integer   initial 0
        field firstMatchLine  as integer   initial 0
        index ix-path is primary unique fullPath.

    define private buffer bUpdateFile for ttScannedFile.
    define private query qFile for ttScannedFile.

    define public property fileCount as integer no-undo get. private set.
    define public property excludedCount as integer no-undo get. private set.
    define public property matchedFileCount as integer no-undo get. private set.
    define public property totalMatchCount as integer no-undo get. private set.

    constructor public ScannedFileSet().
    end constructor.

    method public void addFile( input pFileName        as character,
                                input pFullPath        as character,
                                input pFolderName      as character,
                                input pExtension       as character,
                                input pFileSize        as int64,
                                input pLastModified    as date,
                                input pRootDirectory   as character,
                                input pRelativePath    as character,
                                input pExcluded        as logical,
                                input pExcludedPattern as character ).

        create ttScannedFile.
        assign ttScannedFile.fileName        = pFileName
               ttScannedFile.fullPath        = pFullPath
               ttScannedFile.folderName      = pFolderName
               ttScannedFile.extension       = pExtension
               ttScannedFile.fileSize        = pFileSize
               ttScannedFile.lastModified    = pLastModified
               ttScannedFile.rootDirectory   = pRootDirectory
               ttScannedFile.relativePath    = pRelativePath
               ttScannedFile.excluded        = pExcluded
               ttScannedFile.excludedPattern = pExcludedPattern
               this-object:fileCount         = this-object:fileCount + 1.

        if pExcluded then
            assign this-object:excludedCount = this-object:excludedCount + 1.

    end method.

    // Abre cursor para iteracao; usar com getNext()
    method public void openQuery().
        close query qFile.
        open query qFile for each ttScannedFile no-lock.
    end method.

    // Avanca cursor; retorna FALSE quando nao ha mais registros
    method public logical getNext( output pFullPath  as character,
                                   output pExcluded  as logical ).

        get next qFile.

        if not available ttScannedFile then
            return false.

        assign pFullPath = ttScannedFile.fullPath
               pExcluded = ttScannedFile.excluded.

        return true.

    end method.

    // Avanca cursor com campos detalhados para consumidores que precisam de mais contexto
    method public logical getNextDetail( output pFullPath  as character,
                                         output pFileName  as character,
                                         output pExtension as character,
                                         output pExcluded  as logical,
                                         output pFound     as logical ).

        get next qFile.

        if not available ttScannedFile then
            return false.

        assign pFullPath  = ttScannedFile.fullPath
               pFileName  = ttScannedFile.fileName
               pExtension = ttScannedFile.extension
               pExcluded  = ttScannedFile.excluded
               pFound     = ttScannedFile.found.

        return true.

    end method.

    // Atualiza resultado de busca de um arquivo (usa buffer separado para nao quebrar iteracao)
    method public void setSearchResult( input pFullPath       as character,
                                        input pSearchText     as character,
                                        input pFound          as logical,
                                        input pMatchCount     as integer,
                                        input pFirstMatchLine as integer ).

        find bUpdateFile where bUpdateFile.fullPath = pFullPath exclusive-lock no-error.

        if not available bUpdateFile then return.

        assign bUpdateFile.searchText     = pSearchText
               bUpdateFile.found          = pFound
               bUpdateFile.matchCount     = pMatchCount
               bUpdateFile.firstMatchLine = pFirstMatchLine.

        if pFound then
            assign this-object:matchedFileCount = this-object:matchedFileCount + 1
                   this-object:totalMatchCount  = this-object:totalMatchCount + pMatchCount.

    end method.

    method public JsonArray toJsonArray().

        define variable result    as JsonArray  no-undo.
        define variable fileEntry as JsonObject no-undo.

        assign result = new JsonArray().

        for each ttScannedFile no-lock:

            assign fileEntry = new JsonObject().

            fileEntry:Add( 'fileName',        ttScannedFile.fileName ).
            fileEntry:Add( 'folderName',      ttScannedFile.folderName ).
            fileEntry:Add( 'fullPath',        ttScannedFile.fullPath ).
            fileEntry:Add( 'extension',       ttScannedFile.extension ).
            fileEntry:Add( 'fileSize',        ttScannedFile.fileSize ).
            fileEntry:Add( 'lastModified',    if ttScannedFile.lastModified <> ? then string( ttScannedFile.lastModified ) else '' ).
            fileEntry:Add( 'rootDirectory',   ttScannedFile.rootDirectory ).
            fileEntry:Add( 'relativePath',    ttScannedFile.relativePath ).
            fileEntry:Add( 'excluded',        ttScannedFile.excluded ).
            fileEntry:Add( 'excludedPattern', ttScannedFile.excludedPattern ).
            fileEntry:Add( 'searchText',      ttScannedFile.searchText ).
            fileEntry:Add( 'found',           ttScannedFile.found ).
            fileEntry:Add( 'matchCount',      ttScannedFile.matchCount ).
            fileEntry:Add( 'firstMatchLine',  ttScannedFile.firstMatchLine ).

            result:Add( fileEntry ).

        end.

        return result.

    end method.

    method public void reset().

        empty temp-table ttScannedFile.

        assign this-object:fileCount        = 0
               this-object:excludedCount    = 0
               this-object:matchedFileCount = 0
               this-object:totalMatchCount  = 0.

    end method.

end class.
