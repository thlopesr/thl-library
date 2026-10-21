 
 /*----------------------------------------------------------------------
    File        : EnvironmentUtil
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Wed May 21 08:21:55 BRT 2025
    Notes       : 
  -----------------------------------------------------------------------*/

block-level on error undo, throw.

using thl-lib.core.environment.repository.EnvironmentRepository.
using thl-lib.util.string.StringUtil.

class thl-lib.core.environment.EnvironmentUtil serializable. 

    define private static property environment as character no-undo get. set.  

    method public static final character getEnvironment().
        
        if StringUtil:hasValue( environment ) then
            return environment.
        
        assign environment = EnvironmentRepository:findEnvironmentCodeByPropath( propath ).
        
        return environment.
        
    end.
    
end class.