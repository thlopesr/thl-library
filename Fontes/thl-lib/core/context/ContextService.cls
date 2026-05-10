 
 /*------------------------------------------------------------------------
    File        : ContextService
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Fri Oct 03 15:38:28 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.core.environment.repository.EnvironmentRepository.

routine-level on error undo, throw.

class thl-lib.core.context.ContextService serializable.

    define public static property envirommentParameter as character no-undo get. set.  
    define public static property programName          as character no-undo get. set.

    method public static final character getUser().
        return os-getenv('USERNAME').
    end method.
    
    method public static final character getProgramsCaller().
        
        define variable programs as character no-undo.
        define variable level    as integer   no-undo initial 1.
        
        repeat while program-name(level) <> ?.
            assign programs = substitute( '&1 | &2 - &3', programs, level, program-name(level) )
                   level    = level + 1.
        end.
        return programs.
        
    end method. 
    
    method public static final void setEnvirommentParameter().
        
        define variable level                 as integer               no-undo initial 1.
        define variable environmentRepository as EnvironmentRepository no-undo.
        
        
        assign environmentRepository = new EnvironmentRepository().
        
        repeat while program-name(level) <> ?.
        
            assign programName          = normalizeProgramName( program-name( level ) )
                   envirommentParameter = environmentRepository:findParameterCodeByProgram( programName )
                   level                = level + 1.
            
            if envirommentParameter <> '' then
                return.
                    
        end.
        undo, throw new AppError('Parameter code not found in thl-ambiente-param-prog for current execution context.', 17006).
        
        finally.
            delete object environmentRepository no-error.            
        end finally.
        
    end.
    
    method public static final void reset( ).
        assign envirommentParameter = ''.
    end method.
    
    method private static final character normalizeProgramName( input program as character).
        assign program = replace( program, '\', '/')
               program = entry( num-entries( program, '/'), program, '/' ).
        
        if num-entries( program , '.' ) = 1 then
            return program.
            
        return entry( 1, program, '.' ).
    end method.

end class.