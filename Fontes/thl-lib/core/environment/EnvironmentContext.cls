
 /*------------------------------------------------------------------------
    File        : EnvironmentContext
    Purpose     : Manages the current execution context for the environment
                  module — resolves which parameter group is active and
                  which program was identified in the call stack.
    Author(s)   : Lopes
    Created     : Wed May 28 2026
    Notes       :
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

using thl-lib.core.environment.repository.EnvironmentRepository.
using thl-lib.core.error.ThlError.

class thl-lib.core.environment.EnvironmentContext.

    define public static property environmentParameter as character no-undo get. private set.
    define public static property programName          as character no-undo get. private set.

    method public static final character setParameterCode().

        define variable level       as integer   no-undo initial 1.
        define variable programList as character no-undo.

        repeat while program-name( level ) <> ?.
            assign programName          = normalizeProgramName( program-name( level ) )
                   programList          = substitute( '&1|&2', programList, programName )
                   environmentParameter = EnvironmentRepository:findParameterCodeByProgram( programName )
                   level                = level + 1.
            if environmentParameter <> '' then
                return environmentParameter.
        end.

        undo, throw new ThlError( 'EnvironmentContext', 'setParameterCode', substitute('Programa nao encontrado para o contexto de execucao. &1', programList ) ).

    end method.

    method public static final character normalizeProgramName( input program as character ).
        
        assign program = replace( program, '\', '/' ).
        
        if index( program, '/' ) <> 0 then do.
        
            assign program = entry( num-entries( program, '/' ), program, '/' ).

            if num-entries( program, '.' ) = 1 then
                return program.
    
            return entry( 1, program, '.' ).
            
        end.
        
        assign program = entry( num-entries( program, '.' ), program, '.' ).

        return program.
        
    end method.

end class.
