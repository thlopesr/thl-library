/*------------------------------------------------------------------------
    File        : FileScanner
    Purpose     : Varre um ou mais diretorios recursivamente e produz um
                  ScannedFileSet com os metadados de cada arquivo.
    Author(s)   : Lopes
    Created     : 2026-09-16
    Notes       : Classe generica de descoberta de arquivos — sem
                  conhecimento de ABL, tabelas ou busca textual.
                  Configuracao via metodos addDirectory, addExclusionPattern
                  e property fileExtensions. Arquivos excluidos sao
                  incluidos no resultado com excluded = true.
                  A varredura e feita por fila (ttPendingDirectory), nao
                  por chamada recursiva.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

using thl-lib.logging.LogUtil.
using thl-lib.util.scanner.ScannedFileSet.

block-level on error undo, throw.

class thl-lib.util.scanner.FileScanner.

    define private temp-table ttRootDirectory no-undo
        field directoryPath as character
        index ix-path is primary unique directoryPath.

    define private temp-table ttExclusionPattern no-undo
        field pattern as character
        index ix-pattern is primary unique pattern.

    define private temp-table ttPendingDirectory no-undo
        field directoryPath   as character
        field rootDirectory   as character
        field processed       as logical
        index ix-processed processed.

    define private stream dirStream.

    define public property fileExtensions as character no-undo get. set.

    constructor public FileScanner().
        assign this-object:fileExtensions = ''.
    end constructor.

    method public void addDirectory( input directoryPath as character ).

        define variable normalizedPath as character no-undo.

        assign normalizedPath = right-trim( trim( directoryPath ), '/\' ).

        if normalizedPath = '' then return.

        if can-find( ttRootDirectory where ttRootDirectory.directoryPath = normalizedPath ) then return.

        create ttRootDirectory.
        assign ttRootDirectory.directoryPath = normalizedPath.

    end method.

    method public void addExclusionPattern( input pattern as character ).

        define variable trimmedPattern as character no-undo.

        assign trimmedPattern = trim( pattern ).

        if trimmedPattern = '' then return.

        if can-find( ttExclusionPattern where ttExclusionPattern.pattern = trimmedPattern ) then return.

        create ttExclusionPattern.
        assign ttExclusionPattern.pattern = trimmedPattern.

    end method.

    method public ScannedFileSet scan().

        define variable fileSet as ScannedFileSet no-undo.

        assign fileSet = new ScannedFileSet().

        empty temp-table ttPendingDirectory.

        for each ttRootDirectory no-lock:
            enqueueDirectory( ttRootDirectory.directoryPath, ttRootDirectory.directoryPath ).
        end.

        repeat:

            find first ttPendingDirectory where not ttPendingDirectory.processed no-error.

            if not available ttPendingDirectory then leave.

            assign ttPendingDirectory.processed = true.

            listDirectory( ttPendingDirectory.directoryPath,
                           ttPendingDirectory.rootDirectory,
                           fileSet ).

        end.

        LogUtil:write( substitute( 'Varredura concluida: &1 arquivo(s), &2 excluido(s)',
                                   fileSet:fileCount, fileSet:excludedCount ),
                       this-object:GetClass():TypeName ).

        return fileSet.

        finally:
            empty temp-table ttPendingDirectory.
        end finally.

    end method.

    method public void reset().

        empty temp-table ttRootDirectory.
        empty temp-table ttExclusionPattern.
        empty temp-table ttPendingDirectory.

        assign this-object:fileExtensions = ''.

    end method.

    method private void enqueueDirectory( input directoryPath as character,
                                          input rootDirectory as character ).

        create ttPendingDirectory.
        assign ttPendingDirectory.directoryPath = directoryPath
               ttPendingDirectory.rootDirectory = rootDirectory
               ttPendingDirectory.processed     = false.

    end method.

    method private void listDirectory( input directoryPath as character,
                                       input rootDirectory as character,
                                       input fileSet       as ScannedFileSet ).

        define variable entryName       as character no-undo.
        define variable entryPath       as character no-undo.
        define variable entryAttributes as character no-undo.

        input stream dirStream from os-dir( directoryPath ).

        repeat:

            import stream dirStream entryName entryPath entryAttributes.

            if entryName = '.' or entryName = '..' then next.

            if index( entryAttributes, 'D' ) > 0 then do:
                enqueueDirectory( entryPath, rootDirectory ).
                next.
            end.

            if index( entryAttributes, 'F' ) = 0 then next.

            registerFile( entryName, entryPath, rootDirectory, fileSet ).

        end.

        finally:
            input stream dirStream close.
        end finally.

    end method.

    method private void registerFile( input entryName     as character,
                                      input entryPath     as character,
                                      input rootDirectory as character,
                                      input fileSet       as ScannedFileSet ).

        define variable extension       as character no-undo.
        define variable isExcluded      as logical   no-undo.
        define variable excludedPattern as character no-undo.
        define variable fileSize        as int64     no-undo.
        define variable lastModified    as date      no-undo.

        assign extension = resolveExtension( entryName ).

        if this-object:fileExtensions <> '' then do:
            if extension = '' or not matchesExtension( extension ) then return.
        end.

        assign isExcluded = checkExclusion( entryName ).

        if isExcluded then
            assign excludedPattern = getExcludedPattern( entryName ).
        else
            assign excludedPattern = ''.

        file-info:file-name = entryPath.

        if file-info:full-pathname <> ? then
            assign fileSize     = file-info:file-size
                   lastModified = file-info:file-mod-date.
        else
            assign fileSize     = 0
                   lastModified = ?.

        fileSet:addFile( entryName,
                         entryPath,
                         extractFolder( entryPath ),
                         extension,
                         fileSize,
                         lastModified,
                         rootDirectory,
                         extractRelativePath( entryPath, rootDirectory ),
                         isExcluded,
                         excludedPattern ).

    end method.

    method private logical matchesExtension( input extension as character ).

        define variable patternIndex as integer   no-undo.
        define variable pattern      as character no-undo.
        define variable extPattern   as character no-undo.

        do patternIndex = 1 to num-entries( this-object:fileExtensions ):

            assign pattern = lc( trim( entry( patternIndex, this-object:fileExtensions ) ) ).

            if pattern begins '*.' then
                assign extPattern = substring( pattern, 3 ).
            else
                assign extPattern = pattern.

            if index( extPattern, '*' ) > 0 then do:
                assign extPattern = replace( extPattern, '*', '' ).
                if extension begins extPattern then
                    return true.
            end.
            else do:
                if extension = extPattern then
                    return true.
            end.

        end.

        return false.

    end method.

    method private logical checkExclusion( input fileName as character ).

        for each ttExclusionPattern no-lock:
            if fileName matches ttExclusionPattern.pattern then
                return true.
        end.

        return false.

    end method.

    method private character getExcludedPattern( input fileName as character ).

        for each ttExclusionPattern no-lock:
            if fileName matches ttExclusionPattern.pattern then
                return ttExclusionPattern.pattern.
        end.

        return ''.

    end method.

    method private static character resolveExtension( input entryName as character ).

        if num-entries( entryName, '.' ) < 2 then
            return ''.

        return lc( entry( num-entries( entryName, '.' ), entryName, '.' ) ).

    end method.

    method private static character extractFolder( input fullPath as character ).

        define variable lastSlash as integer no-undo.

        assign lastSlash = r-index( fullPath, '/' ).

        if r-index( fullPath, '\' ) > lastSlash then
            assign lastSlash = r-index( fullPath, '\' ).

        if lastSlash > 0 then
            return substring( fullPath, 1, lastSlash - 1 ).

        return ''.

    end method.

    method private static character extractRelativePath( input fullPath      as character,
                                                         input rootDirectory as character ).

        define variable prefixLength as integer no-undo.

        if not fullPath begins rootDirectory then
            return fullPath.

        assign prefixLength = length( rootDirectory ) + 1.

        if prefixLength >= length( fullPath ) then
            return ''.

        return substring( fullPath, prefixLength + 1 ).

    end method.

end class.
