 
 /*------------------------------------------------------------------------
    File        : FileUtil
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Tue Mar 25 17:28:20 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/
using Progress.Lang.*.
using thl-lib.util.string.StringUtil.
using thl-lib.util.date.DateTimeUtil.
using thl-lib.core.error.ThlError.

block-level on error undo, throw.

class thl-lib.util.file.FileUtil serializable.

    method public static final logical exists( input filePath as character ).

        if not StringUtil:hasValue( filePath ) then
            return false.

        assign file-info:file-name = filePath.

        return file-info:full-pathname <> ?.

    end method.


    method public static final character getFullPathName( input filePath as character ).

        if not StringUtil:hasValue( filePath ) then
            return ?.

        assign file-info:file-name = filePath.

        return file-info:full-pathname.

    end method.


    method private static final character getRequiredFullPathName( input filePath as character ).

        define variable fullPathName as character no-undo.

        if not StringUtil:hasValue( filePath ) then
            undo, throw new ThlError( 'FileUtil', 'getRequiredFullPathName', 'Arquivo nao informado.' ).

        assign fullPathName = getFullPathName( filePath ).

        if fullPathName = ? then
            undo, throw new ThlError( 'FileUtil', 'getRequiredFullPathName', substitute( 'Arquivo &1 nao encontrado.', filePath ) ).

        return fullPathName.

    end method.


    method public static final longchar loadFileAsBase64( input filePath as character ).

        define variable fileMemptr   as memptr    no-undo.
        define variable fullPathName as character no-undo.

        assign fullPathName = getRequiredFullPathName( filePath ).

        copy-lob from file fullPathName to fileMemptr.

        return base64-encode( fileMemptr ).

        finally.
            assign set-size( fileMemptr ) = 0.
        end finally.

    end method.

    //Decodifica o base64 e grava o arquivo (sobrescreve se ja existir). A pasta precisa existir.
    method public static final void saveBase64AsFile( input filePath      as character,
                                                      input base64Content as longchar ).

        define variable fileMemptr as memptr no-undo.

        if not StringUtil:hasValue( filePath ) then
            undo, throw new ThlError( 'FileUtil', 'saveBase64AsFile', 'Caminho do arquivo nao informado.' ).

        if not StringUtil:hasValue( base64Content ) then
            undo, throw new ThlError( 'FileUtil', 'saveBase64AsFile', substitute( 'Conteudo do arquivo &1 nao informado.', filePath ) ).

        assign fileMemptr = base64-decode( base64Content ).

        copy-lob from fileMemptr to file filePath.

        finally.
            assign set-size( fileMemptr ) = 0.
        end finally.

    end method.

    //Nome (ou extensao) de arquivo seguro: sem separador de pasta, caractere invalido nem ponto no inicio.
    method public static final character sanitizeFileName( input rawName as character ).

        define variable cleaned as character no-undo.
        define variable counter as integer   no-undo.
        define variable charAt  as character no-undo.

        if rawName = ? then
            return ''.

        do counter = 1 to length( rawName ).

            assign charAt = substring( rawName, counter, 1 ).

            if index( '/~\:*?"<>|', charAt ) > 0 or asc( charAt ) < 32 then
                next.

            assign cleaned = cleaned + charAt.

        end.

        assign cleaned = trim( cleaned ).

        do while cleaned begins '.'.
            assign cleaned = substring( cleaned, 2 ).
        end.

        return cleaned.

    end method.

    //Acrescenta _ddMMyyyyHHmmss (agora) antes da extensao: C:\TEMP\a.xls -> C:\TEMP\a_28102026105700.xls.
    //Sem extensao, acrescenta no fim. Caminho sem valor devolve ?.
    method public static final character formatFileNameWithTimestamp( input filePath as character ).
        return formatFileNameWithTimestamp( filePath, DateTimeUtil:currentDateTime() ).
    end method.

    //Igual ao formatFileNameWithTimestamp( filePath ), usando a data e hora informadas.
    method public static final character formatFileNameWithTimestamp( input filePath     as character   ,
                                                                      input baseDateTime as datetime-tz ).

        define variable timestamp   as character no-undo.
        define variable dotPosition as integer   no-undo.

        if not StringUtil:hasValue( filePath ) then
            return ?.

        assign timestamp         = DateTimeUtil:formatTimestamp( baseDateTime )
               dotPosition       = r-index( filePath, '.' ).

        //Ponto numa pasta (antes do ultimo separador) nao e extensao
        return substitute( '&1_&2&3', substring( filePath, 1, dotPosition - 1 ), timestamp, substring( filePath, dotPosition ) ).

    end method.

end class.