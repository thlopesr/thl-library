 
 /*------------------------------------------------------------------------
    File        : logUtils
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Wed May 21 08:21:55 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

class thl-lib.logging.LogUtil serializable.

    method private static final void printLog( valueLog as character ,
                                               labelLog as character ).

        if log-manager:logfile-name <> ?  and
           log-manager:logfile-name <> '' then 
        log-manager:write-message ( substitute('- Got here, &1 = &2', labelLog, valueLog )  , 'logUtil.cls' ).
        
    end method.
    
    method public static final void printLog( valueLog as logical   ,
                                              labelLog as character ).
        printLog( string(valueLog), labelLog ).    
    end method.
    
    method public static final void printLog( valueLog as decimal   ,
                                              labelLog as character ).
        printLog( string(valueLog), labelLog ).    
    end method.
    
    method public static final void printLog( valueLog as integer   ,
                                              labelLog as character ).
        printLog( string(valueLog), labelLog ).    
    end method. 
    
    method public static final void printLog( valueLog as date      ,
                                              labelLog as character ).
        printLog( string(valueLog), labelLog ).    
    end method.     

end class.