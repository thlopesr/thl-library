
 /*------------------------------------------------------------------------
    File        : EnvironmentRepository
    Purpose     : Acesso a dados do modulo de ambiente
    Author(s)   : Lopes
  ----------------------------------------------------------------------*/

using thl-lib.core.error.ThlError.

block-level on error undo, throw.

class thl-lib.core.environment.repository.EnvironmentRepository.

    define static private buffer b-thl-ambiente                for thl-ambiente.
    define static private buffer b-thl-ambiente-param-prog     for thl-ambiente-param-prog.
    define static private buffer b-thl-ambiente-param-variavel for thl-ambiente-param-variavel.

    method public static final character findEnvironmentCodeByPropath( input propathValue as character ).

        for each b-thl-ambiente no-lock
             where b-thl-ambiente.ip <> ''.
            if index( propathValue, b-thl-ambiente.ip ) > 0 then
                return b-thl-ambiente.cod-ambiente.
        end.

        if available b-thl-ambiente then
            return b-thl-ambiente.cod-ambiente.

        undo, throw new ThlError( 'EnvironmentRepository', 'findEnvironmentCodeByPropath',
            'Ambiente nao identificado.' ).
            
        finally.
            release b-thl-ambiente no-error.                
        end finally.

    end method.

    method public static final character findParameterCodeByProgram( input programName as character ).

        find first b-thl-ambiente-param-prog no-lock
             where b-thl-ambiente-param-prog.cod-prog-dtsul = programName no-error.

        if not available b-thl-ambiente-param-prog then
            return ''.

        return b-thl-ambiente-param-prog.cod-param-ambiente.

        finally.
            release b-thl-ambiente-param-prog no-error.                
        end finally.
        
    end method.

    method public static final character findVariableValue( input environmentCode as character ,
                                                            input parameterCode   as character ,
                                                            input variableCode    as character ).

        find first b-thl-ambiente-param-variavel no-lock
             where b-thl-ambiente-param-variavel.cod-ambiente       = environmentCode
               and b-thl-ambiente-param-variavel.cod-param-ambiente = parameterCode
               and b-thl-ambiente-param-variavel.cod-variavel       = variableCode
             no-error.

        if available b-thl-ambiente-param-variavel then
            return b-thl-ambiente-param-variavel.valor-variavel.

        find first b-thl-ambiente-param-variavel no-lock
            where b-thl-ambiente-param-variavel.cod-ambiente       = '*'
              and b-thl-ambiente-param-variavel.cod-param-ambiente = parameterCode
              and b-thl-ambiente-param-variavel.cod-variavel       = variableCode
            no-error.

        if not available b-thl-ambiente-param-variavel then
            return ''.

        return b-thl-ambiente-param-variavel.valor-variavel.
        
        finally.
            release b-thl-ambiente-param-variavel no-error.                
        end finally.
        

    end method.

end class.
