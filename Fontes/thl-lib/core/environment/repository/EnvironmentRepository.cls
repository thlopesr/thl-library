 
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

class thl-lib.core.environment.repository.EnvironmentRepository. 

    method public character findEnvironmentCodeByPropath( input propathValue as character ).
        
        find first thl-ambiente no-lock
             where thl-ambiente.ip                        <> ''
               and index( propathValue, thl-ambiente.ip )  > 0
             no-error.

        if not available thl-ambiente then
            undo, throw new Progress.Lang.AppError('Environment not identified.', 17006). 

        return thl-ambiente.cod-ambiente.

    end method.

    method public character findParameterCodeByProgram( input programName as character ).
        
        find first thl-ambiente-param-prog no-lock
             where thl-ambiente-param-prog.cod-prog-dtsul = programName no-error.

        if not available thl-ambiente-param-prog then
            return ''.

        return thl-ambiente-param-prog.cod-param-ambiente.

    end method.

    method public character findVariableValue( input environmentCode as character ,
                                               input parameterCode   as character ,
                                               input variableCode    as character ).

        find first thl-ambiente-param-variavel no-lock
             where thl-ambiente-param-variavel.cod-ambiente       = environmentCode
               and thl-ambiente-param-variavel.cod-param-ambiente = parameterCode
               and thl-ambiente-param-variavel.cod-variavel       = variableCode
             no-error.

        if not available thl-ambiente-param-variavel then
            return ''.

        return thl-ambiente-param-variavel.valor-variavel.

    end method.

end class.