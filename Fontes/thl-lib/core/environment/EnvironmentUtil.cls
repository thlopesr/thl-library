 
 /*----------------------------------------------------------------------
    File        : EnvironmentUtil
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Wed May 21 08:21:55 BRT 2025
    Notes       : 
  -----------------------------------------------------------------------*/

routine-level on error undo, throw.

using thl-lib.core.environment.repository.EnvironmentRepository.

class thl-lib.core.environment.EnvironmentUtil serializable. 

    define private static property environment as character no-undo get. set.  

    method public static final character getEnvironment().
        
        if environment <> '' then
            return environment.
        
        assign environment = new EnvironmentRepository():findEnvironmentCodeByPropath( propath ).
        
        return environment.
        
    end.
    
    method public static final void reset().
        assign environment = ''.
    end method.

end class.