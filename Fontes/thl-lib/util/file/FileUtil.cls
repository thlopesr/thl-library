 
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

end class.