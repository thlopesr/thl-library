 
 /*------------------------------------------------------------------------
    File        : StringUtil
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Tue Mar 25 17:28:20 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using thl-lib.core.error.ThlError.

block-level on error undo, throw.

class thl-lib.util.string.StringUtil serializable.
    
    method public static final character getText( variavel as longchar).
        return if variavel = ? then '' else variavel.  
    end method.

    method public static final character getText( variavel as integer  ).
        return getText( string( variavel ) ).
    end method.

    method public static final character getText( variavel as decimal  ).
        return getText( string( variavel ) ).
    end method.

    method public static final logical hasValue( input valueText as longchar ).
        return trim( getText(valueText) ) <> ''.
    end method.
    
    // Codigo de variavel a partir do nome do membro do enum, com '_' virando '.' (a busca nao
    // diferencia maiusculas: MENSAGEM_ENTRADA -> MENSAGEM.ENTRADA acha mensagem.entrada).
    method public static final character enumToCode( input enumValue as Progress.Lang.Enum ).
        return replace( enumValue:toString(), '_', '.' ).
    end method.

    method public static final longchar removeCr( input valueText as longchar ).
        return replace( getText(valueText), chr(13), '||' ).
    end method.

    method public static final longchar removeLf( input valueText as longchar ).
        return replace( getText(valueText), chr(10), '||' ).
    end method.
    
    method public static final character removeCrLf( input valueText as longchar ).
        return string( removeLf( removeCr(valueText) ) ).
    end method.

    method public static final character formatIsoDate( input inputDate as date ).
        if inputDate = ? then return ''.
        return substitute( '&1-&2-&3',
                           string( year(inputDate), '9999'),
                           string(month(inputDate), '99'  ),
                           string(  day(inputDate), '99'  )
                         ). 
    end method.

    method public static final datetime parseDate( input dateString   as character ,
                                                   input defaultValue as datetime  ).

        define variable iYear  as integer no-undo.
        define variable iMonth as integer no-undo.
        define variable iDay   as integer no-undo.

        if dateString = '' or dateString = ? then
            return defaultValue.

        assign iYear  = integer( entry( 1, dateString, '-' ) )
               iMonth = integer( entry( 2, dateString, '-' ) )
               iDay   = integer( entry( 3, dateString, '-' ) ).

        return datetime( iMonth, iDay, iYear, 0, 0, 0 ).

    end method.

    //Data com hora das rotas de metricas, somente no formato yyyy-MM-ddTHH:mm
    //(hora local, sem segundos e sem fuso). O parseDate das consultas nao muda.
    method public static final datetime parseDateTime( input dateString   as character ,
                                                       input defaultValue as datetime  ).

        if dateString = '' or dateString = ? then
            return defaultValue.

        assign dateString = trim( dateString ).

        if length( dateString )       <> 16  or
           substring( dateString,  5, 1 ) <> '-' or
           substring( dateString,  8, 1 ) <> '-' or
           substring( dateString, 11, 1 ) <> 'T' or
           substring( dateString, 14, 1 ) <> ':' then
            undo, throw new ThlError( 'thl-lib.util.string.StringUtil', 'parseDateTime',
                substitute( 'Data e hora invalida: &1. Informe no formato yyyy-MM-ddTHH:mm.', dateString ) ).

        return datetime( integer( substring( dateString,  6, 2 ) ),
                         integer( substring( dateString,  9, 2 ) ),
                         integer( substring( dateString,  1, 4 ) ),
                         integer( substring( dateString, 12, 2 ) ),
                         integer( substring( dateString, 15, 2 ) ),
                         0 ).

    end method.

end class.

