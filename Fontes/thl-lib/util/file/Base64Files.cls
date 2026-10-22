/*------------------------------------------------------------------------
    File        : Base64Files
    Purpose     : Conjunto de arquivos em base64 (Base64File) com o diretorio
                  onde gravar. Grava todos e sabe desfazer.
    Author(s)   : Lopes
    Created     : 2026-10-21
    Notes       : fromJson monta o conjunto a partir de um array
                  [ { nome, extensao, conteudoBase64 } ]. O diretorio nao vem
                  do JSON: quem chama define (a pasta e criada em save() se nao
                  existir, so o ultimo nivel). Arquivo de mesmo nome e
                  sobrescrito. rollback() apaga o que esta instancia gravou,
                  para quando uma transacao do banco e desfeita depois da
                  gravacao.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.util.file.Base64File.
using thl-lib.util.file.Base64Files.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.string.StringUtil.

block-level on error undo, throw.

class thl-lib.util.file.Base64Files.

    define public property directory as character no-undo get. private set.

    define private temp-table tt-file no-undo
        field seq        as integer
        field fileObject as Progress.Lang.Object
        index ch-seq is primary unique seq.

    define private variable writtenFiles as character no-undo.

    constructor public Base64Files( input directory as character ).

        if not StringUtil:hasValue( directory ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor', 'Diretorio dos arquivos nao informado.' ).

        assign this-object:directory = right-trim( trim( directory ), '/~\' ).

    end constructor.

    //Monta o conjunto a partir do array de arquivos do JSON
    method public static Base64Files fromJson( input files     as JsonArray,
                                               input directory as character ).

        define variable result   as Base64Files no-undo.
        define variable fileItem as JsonObject  no-undo.
        define variable content  as longchar    no-undo.
        define variable counter  as integer     no-undo.

        assign result = new Base64Files( directory ).

        if not valid-object( files ) then
            return result.

        do counter = 1 to files:Length.

            assign fileItem = files:GetJsonObject( counter )
                   content  = ''.

            if fileItem:Has( 'conteudoBase64' ) then
                assign content = fileItem:GetLongchar( 'conteudoBase64' ).

            result:add( new Base64File( JsonUtil:getText( fileItem, 'nome' ),
                                        JsonUtil:getText( fileItem, 'extensao' ),
                                        content ) ).

        end.

        return result.

    end method.

    method public void add( input fileItem as Base64File ).

        define variable nextSeq as integer no-undo.

        if not valid-object( fileItem ) then
            return.

        find last tt-file no-lock no-error.

        assign nextSeq = if available tt-file then tt-file.seq + 1 else 1.

        create tt-file.

        assign tt-file.seq        = nextSeq
               tt-file.fileObject = fileItem.

    end method.

    method public integer getFileCount():

        define buffer b-file for tt-file.

        define variable total as integer no-undo.

        for each b-file no-lock.
            assign total = total + 1.
        end.

        return total.

    end method.

    //Grava todos os arquivos no diretorio. Se um falhar, o que ja foi gravado continua rastreado
    //para o rollback().
    method public void save().

        define buffer b-file for tt-file.

        define variable savedPath as character no-undo.

        if this-object:getFileCount() = 0 then
            return.

        this-object:ensureDirectory().

        for each b-file no-lock by b-file.seq.

            assign savedPath    = cast( b-file.fileObject, Base64File ):save( this-object:directory )
                   writtenFiles = writtenFiles + ( if writtenFiles = '' then '' else chr(1) ) + savedPath.

        end.

    end method.

    //Apaga os arquivos gravados por esta instancia
    method public void rollback().

        define variable counter as integer no-undo.

        do counter = 1 to num-entries( writtenFiles, chr(1) ).
            if entry( counter, writtenFiles, chr(1) ) <> '' then
                os-delete value( entry( counter, writtenFiles, chr(1) ) ).
        end.

        assign writtenFiles = ''.

    end method.

    method private void ensureDirectory().

        assign file-info:file-name = this-object:directory.

        if file-info:full-pathname <> ? then
            return.

        os-create-dir value( this-object:directory ).

        if os-error <> 0 then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'ensureDirectory',
                substitute( 'Nao foi possivel criar a pasta &1 (erro &2).', this-object:directory, os-error ) ).

    end method.

end class.
