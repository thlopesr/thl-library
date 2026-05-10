 
 /*________________________________________________________________________
    File        : 
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Wed May 21 08:21:55 BRT 2025
    Notes       : 
  ______________________________________________________________________*/

routine-level on error undo, throw.

using thl-lib.core.environment.EnvironmentUtil.
using thl-lib.core.context.ContextService.
using thl-lib.core.environment.repository.EnvironmentRepository.

class thl-lib.core.environment.EnvironmentResource serializable.

    method public static final void initializeEnvironmentParameter().
        ContextService:reset().
        ContextService:setEnvirommentParameter().                                                                  
    end method.

    method public static final character getEnvironmentVariable().
        initializeEnvironmentParameter().
        return getEnvironmentVariable( EnvironmentUtil:getEnvironment(), ContextService:envirommentParameter, '' ).                                                              
    end method.

    method public static final character getEnvironmentVariable( variableCode  as character ).
        validateEnvirommentParameter().
        return getEnvironmentVariable( EnvironmentUtil:getEnvironment(), ContextService:envirommentParameter, variableCode ).                                                               
    end method.
    
    method public static final character getEnvironmentVariable( codeParameter as character ,
                                                                 variableCode  as character ).
        return getEnvironmentVariable( EnvironmentUtil:getEnvironment(), codeParameter, variableCode ).                                                              
    end method.

    method public static final character getEnvironmentVariable( environment   as character ,
                                                                 codeParameter as character ,
                                                                 variableCode  as character ).
        return new EnvironmentRepository():findVariableValue( environment, codeParameter, variableCode).
    end.

    method public static final character getEnvirommentParameter().
        return ContextService:envirommentParameter.                                                              
    end method. 
    
    method public static final void validateEnvirommentParameter().
        if ContextService:envirommentParameter = '' then 
            undo, throw new Progress.Lang.AppError( 'Environment parameter not initialized. Call ContextService:setEnvirommentParameter() before using EnvironmentResource.', 17006).    
    end.
    
    method public static final character getProgramName().
        return ContextService:programName.                                                              
    end method.    

end class.