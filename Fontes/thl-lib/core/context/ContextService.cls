
 /*------------------------------------------------------------------------
    File        : ContextService
    Purpose     : Generic execution context utilities — current OS user
                  and formatted call stack for diagnostics.
    Author(s)   : Lopes
    Created     : Fri Oct 03 15:38:28 BRT 2025
    Notes       :
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

class thl-lib.core.context.ContextService serializable.

    method public static final character getUser().
        return os-getenv('USERNAME').
    end method.

    method public static final character getErpUser().
        run thl/api/geterpuser.p.
        return return-value.
    end method.

    method public static final character getProgramsCaller().

        define variable programs as character no-undo.
        define variable level    as integer   no-undo initial 1.

        do while program-name(level) <> ?.
            assign programs = if programs = '' then substitute( '&1 - &2', level, program-name(level) )
                                               else substitute( '&1 | &2 - &3', programs, level, program-name(level) )
                   level    = level + 1.
        end.

        return programs.

    end method.

end class.
