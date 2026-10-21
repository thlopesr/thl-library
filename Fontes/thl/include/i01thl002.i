/*------------------------------------------------------------------------------
  Include:     i01thl002.i
  Purpose:     Procedimento interno comum das viewers com campos que tem padrao no thl0002.
  Notes:       Quem usa precisa de: using thl-lib.core.environment.EnvironmentResource.
               O parametro do thl0002 vem do programa que chama (aba Programa), sem literal.
               Sem vinculo do programa, sem a variavel ou com valor em branco, o campo fica
               como esta (valor inicial do banco).
------------------------------------------------------------------------------*/
procedure pi-padrao-campo.

    define input parameter h-campo  as handle              no-undo.
    define input parameter e-padrao as Progress.Lang.Enum no-undo.

    define variable c-valor as character no-undo.

    if not valid-handle( h-campo ) then
        return.

    assign c-valor = new EnvironmentResource():getEnvironmentVariable( e-padrao ) no-error.

    if c-valor = '' or c-valor = ? then
        return.

    assign h-campo:screen-value = c-valor no-error.

end procedure.
