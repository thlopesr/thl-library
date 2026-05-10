 
 /*------------------------------------------------------------------------
    File        : TextoUtil
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Tue Mar 25 17:28:20 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

class thl-lib.util.string.StringUtil serializable.
    
    method public static final character getText( variavel as character).
        return if variavel = ? then '' else variavel.  
    end method.

    method public static final character getText( variavel as integer  ).
        return getText( string( variavel ) ).
    end method.

    method public static final character getText( variavel as decimal  ).
        return getText( string( variavel ) ).
    end method.

end class.

