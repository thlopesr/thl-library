/*------------------------------------------------------------------------
    File        : TableImpactCompiler
    Purpose     : Fachada que combina FileScanner, FileContentSearcher e
                  ProgramCompiler para recompilar programas que referenciam
                  uma tabela, programa ou include OpenEdge.
                  Retorna JsonArray do scanner enriquecido com atributos
                  de compilacao: compiled, reason, succeeded, errorMessage,
                  errorFile, errorRow, errorColumn.
    Author(s)   : Lopes
    Created     : 2026-09-16
    Notes       : Dois modos:
                  - execute(searchText): passada unica — busca direta.
                    Para programas ou includes.
                  - executeForTable(tableName): duas passadas — busca
                    direta + busca por includes afetados.
                    executeForTable chama executeSearchInternal para a
                    tabela, coleta includes (.i*) com match, e chama
                    executeSearchInternal N vezes para cada include.
                  Usar JsonArrayCsvExporter para gerar CSV do resultado.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonObject.

using thl-lib.core.error.ErrorHandler.
using thl-lib.core.error.ThlError.
using thl-lib.util.compile.CompilationResult.
using thl-lib.util.compile.ProgramCompiler.
using thl-lib.util.scanner.FileContentSearcher.
using thl-lib.util.scanner.FileScanner.
using thl-lib.util.scanner.ScannedFileSet.

block-level on error undo, throw.

class thl-lib.util.compile.TableImpactCompiler.

    define private static variable ABL_DELIMITERS as character no-undo
        initial ' ,~t,.,:'.

    define private static variable ABL_EXTENSIONS as character no-undo
        initial 'w,p,cls,i*'.

    define public property saveDirectory as character no-undo get. set.

    define private temp-table ttDirectory no-undo
        field directoryPath as character
        index ix-path is primary unique directoryPath.

    define private temp-table ttExclusion no-undo
        field pattern as character
        index ix-pattern is primary unique pattern.

    define private temp-table ttAffectedInclude no-undo
        field includeName as character
        index ix-name is primary unique includeName.

    define private temp-table ttCompiledFile no-undo
        field fullPath     as character
        field reason       as character
        field succeeded    as logical
        field errorMessage as character
        field errorFile    as character
        field errorRow     as integer
        field errorColumn  as integer
        index ix-path is primary unique fullPath.

    define private variable errorHandler as ErrorHandler no-undo.

    constructor public TableImpactCompiler().

        assign errorHandler              = new ErrorHandler( this-object:GetClass():TypeName )
               this-object:saveDirectory = ''.

    end constructor.

    method public void addDirectory( input directoryPath as character ).

        define variable normalizedPath as character no-undo.

        assign normalizedPath = right-trim( trim( directoryPath ), '/\' ).

        if normalizedPath = '' then return.

        if can-find( ttDirectory where ttDirectory.directoryPath = normalizedPath ) then return.

        create ttDirectory.
        assign ttDirectory.directoryPath = normalizedPath.

    end method.

    method public void addExclusionPattern( input pattern as character ).

        define variable trimmedPattern as character no-undo.

        assign trimmedPattern = trim( pattern ).

        if trimmedPattern = '' then return.

        if can-find( ttExclusion where ttExclusion.pattern = trimmedPattern ) then return.

        create ttExclusion.
        assign ttExclusion.pattern = trimmedPattern.

    end method.

    /* ---- execute: passada unica (programa ou include) ---- */

    method public JsonArray execute( input searchText as character ).

        define variable fileSet as ScannedFileSet no-undo.

        empty temp-table ttCompiledFile.

        assign fileSet = executeSearchInternal( searchText, ?,
                            this-object:saveDirectory, ABL_DELIMITERS, 'direct' ).

        return enrichResult( fileSet:toJsonArray() ).

        catch execError as Progress.Lang.Error:

            if type-of( execError, Progress.Lang.AppError ) then
                undo, throw execError.

            undo, throw new ThlError( this-object:GetClass():TypeName,
                                       'execute', execError ).

        end catch.

        finally:
            empty temp-table ttCompiledFile.
        end finally.

    end method.

    method public JsonArray execute( input rootDirectory as character,
                                      input searchText    as character ).

        return this-object:execute( rootDirectory, searchText, '' ).

    end method.

    method public JsonArray execute( input rootDirectory  as character,
                                      input searchText     as character,
                                      input pSaveDirectory as character ).

        define variable fileSet as ScannedFileSet no-undo.

        empty temp-table ttCompiledFile.

        assign fileSet = executeSearchInternal( searchText, rootDirectory,
                            pSaveDirectory, ABL_DELIMITERS, 'direct' ).

        return enrichResult( fileSet:toJsonArray() ).

        catch execError as Progress.Lang.Error:

            if type-of( execError, Progress.Lang.AppError ) then
                undo, throw execError.

            undo, throw new ThlError( this-object:GetClass():TypeName,
                                       'execute', execError ).

        end catch.

        finally:
            empty temp-table ttCompiledFile.
        end finally.

    end method.

    /* ---- executeForTable: duas passadas ---- */

    method public JsonArray executeForTable( input tableName as character ).

        return executeForTableInternal( tableName, ?, this-object:saveDirectory ).

    end method.

    method public JsonArray executeForTable( input rootDirectory as character,
                                               input tableName     as character ).

        return this-object:executeForTable( rootDirectory, tableName, '' ).

    end method.

    method public JsonArray executeForTable( input rootDirectory  as character,
                                               input tableName      as character,
                                               input pSaveDirectory as character ).

        return executeForTableInternal( tableName, rootDirectory, pSaveDirectory ).

    end method.

    /* ---- Private: orquestracao para tabela ---- */

    method private JsonArray executeForTableInternal( input tableName      as character,
                                                        input rootDirectory  as character,
                                                        input pSaveDirectory as character ).

        define variable fileSet      as ScannedFileSet no-undo.
        define variable strippedName as character      no-undo.
        define variable fullPath     as character      no-undo.
        define variable fileName     as character      no-undo.
        define variable extension    as character      no-undo.
        define variable excluded     as logical        no-undo.
        define variable found        as logical        no-undo.

        empty temp-table ttCompiledFile.
        empty temp-table ttAffectedInclude.

        assign strippedName = stripDatabaseQualifier( tableName ).

        /* Passada 1: busca direta da tabela */

        assign fileSet = executeSearchInternal( strippedName, rootDirectory,
                            pSaveDirectory, ABL_DELIMITERS, 'direct' ).

        /* Coleta includes (.i*) com match */

        fileSet:openQuery().

        repeat:

            if not fileSet:getNextDetail( output fullPath, output fileName,
                                           output extension, output excluded,
                                           output found ) then leave.

            if excluded or not found then next.
            if not isIncludeExtension( extension ) then next.

            if not can-find( ttAffectedInclude
                             where ttAffectedInclude.includeName = fileName ) then do:
                create ttAffectedInclude.
                assign ttAffectedInclude.includeName = fileName.
            end.

        end.

        /* Passada 2: para cada include, busca programas que o referenciam */

        for each ttAffectedInclude no-lock:
            executeSearchInternal( ttAffectedInclude.includeName, rootDirectory,
                pSaveDirectory, '', ttAffectedInclude.includeName ).
        end.

        return enrichResult( fileSet:toJsonArray() ).

        catch execError as Progress.Lang.Error:

            if type-of( execError, Progress.Lang.AppError ) then
                undo, throw execError.

            undo, throw new ThlError( this-object:GetClass():TypeName,
                                       'executeForTable', execError ).

        end catch.

        finally:
            empty temp-table ttCompiledFile.
            empty temp-table ttAffectedInclude.
        end finally.

    end method.

    /* ---- Private: scan + search + compila programas ---- */

    method private ScannedFileSet executeSearchInternal( input pSearchText    as character,
                                                          input rootDirectory  as character,
                                                          input pSaveDirectory as character,
                                                          input pDelimiters    as character,
                                                          input pReason        as character ).

        define variable scanner     as FileScanner         no-undo.
        define variable fileSet     as ScannedFileSet      no-undo.
        define variable searcher    as FileContentSearcher no-undo.
        define variable compiler_   as ProgramCompiler     no-undo.
        define variable compilation as CompilationResult   no-undo.
        define variable fullPath    as character            no-undo.
        define variable fileName    as character            no-undo.
        define variable extension   as character            no-undo.
        define variable excluded    as logical              no-undo.
        define variable found       as logical              no-undo.

        if rootDirectory <> ? then
            assign scanner = buildScanner( rootDirectory ).
        else
            assign scanner = buildScanner().

        assign fileSet  = scanner:scan()
               searcher = new FileContentSearcher( pSearchText, pDelimiters ).

        searcher:enrich( fileSet ).

        assign compiler_ = new ProgramCompiler( pSaveDirectory ).

        fileSet:openQuery().

        repeat:

            if not fileSet:getNextDetail( output fullPath, output fileName,
                                           output extension, output excluded,
                                           output found ) then leave.

            if excluded or not found then next.
            if not isProgramExtension( extension ) then next.
            if can-find( ttCompiledFile where ttCompiledFile.fullPath = fullPath ) then next.

            assign compilation = compiler_:compileFile( fullPath ).

            create ttCompiledFile.
            assign ttCompiledFile.fullPath     = fullPath
                   ttCompiledFile.reason       = pReason
                   ttCompiledFile.succeeded    = compilation:succeeded
                   ttCompiledFile.errorMessage = compilation:errorMessage
                   ttCompiledFile.errorFile    = compilation:errorFile
                   ttCompiledFile.errorRow     = compilation:errorRow
                   ttCompiledFile.errorColumn  = compilation:errorColumn.

        end.

        return fileSet.

    end method.

    /* ---- Private: enriquece JsonArray com dados de compilacao ---- */

    method private JsonArray enrichResult( input result as JsonArray ).

        define variable idx as integer    no-undo.
        define variable obj as JsonObject no-undo.

        do idx = 1 to result:Length:

            assign obj = result:GetJsonObject( idx ).

            find ttCompiledFile
                 where ttCompiledFile.fullPath = obj:GetCharacter( 'fullPath' )
                 no-lock no-error.

            if available ttCompiledFile then do:
                obj:Add( 'compiled',     true ).
                obj:Add( 'reason',       ttCompiledFile.reason ).
                obj:Add( 'succeeded',    ttCompiledFile.succeeded ).
                obj:Add( 'errorMessage', ttCompiledFile.errorMessage ).
                obj:Add( 'errorFile',    ttCompiledFile.errorFile ).
                obj:Add( 'errorRow',     ttCompiledFile.errorRow ).
                obj:Add( 'errorColumn',  ttCompiledFile.errorColumn ).
            end.
            else do:
                obj:Add( 'compiled',     false ).
                obj:Add( 'reason',       '' ).
                obj:Add( 'succeeded',    false ).
                obj:Add( 'errorMessage', '' ).
                obj:Add( 'errorFile',    '' ).
                obj:Add( 'errorRow',     0 ).
                obj:Add( 'errorColumn',  0 ).
            end.

        end.

        return result.

    end method.

    /* ---- Private: helpers ---- */

    method private FileScanner buildScanner().

        define variable scanner as FileScanner no-undo.

        assign scanner = new FileScanner().

        for each ttDirectory no-lock:
            scanner:addDirectory( ttDirectory.directoryPath ).
        end.

        for each ttExclusion no-lock:
            scanner:addExclusionPattern( ttExclusion.pattern ).
        end.

        assign scanner:fileExtensions = ABL_EXTENSIONS.

        return scanner.

    end method.

    method private FileScanner buildScanner( input rootDirectory as character ).

        define variable scanner as FileScanner no-undo.

        assign scanner = new FileScanner().

        scanner:addDirectory( rootDirectory ).

        for each ttExclusion no-lock:
            scanner:addExclusionPattern( ttExclusion.pattern ).
        end.

        assign scanner:fileExtensions = ABL_EXTENSIONS.

        return scanner.

    end method.

    method private static character stripDatabaseQualifier( input tableName as character ).

        define variable dotPosition as integer no-undo.

        assign dotPosition = index( tableName, '.' ).

        if dotPosition > 0 then
            return substring( tableName, dotPosition + 1 ).

        return tableName.

    end method.

    method private static logical isIncludeExtension( input extension as character ).
        return extension begins 'i'.
    end method.

    method private static logical isProgramExtension( input extension as character ).
        return lookup( extension, 'w,p,cls' ) > 0.
    end method.

    method public void reset().

        empty temp-table ttDirectory.
        empty temp-table ttExclusion.
        empty temp-table ttAffectedInclude.
        empty temp-table ttCompiledFile.

        assign this-object:saveDirectory = ''.

    end method.

end class.
