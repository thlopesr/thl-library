/*------------------------------------------------------------------------
    File        : compilar-thl.p
    Purpose     : Compilar em lote todos os .cls da THL-Library
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

security-policy:xcode-session-key = "THL2K99".

define variable cDirFontes  as character no-undo
    initial "\\10.55.7.242\datasul\dts11\ERP\Espec\NITRO\THL-Library\thl-lib".

define variable cLogFile    as character no-undo
    initial "\\tsclient\c\temp\compilar-thl.log".

define variable cDirAtual   as character no-undo.
define variable cNome       as character no-undo.
define variable cFullPath   as character no-undo.
define variable cAttr       as character no-undo.
define variable iOk         as integer   no-undo.
define variable iErro       as integer   no-undo.

define temp-table ttFila no-undo
    field cDir as character.

procedure pLog private:
    define input parameter cLinha as character no-undo.
    output TO VALUE(cLogFile) APPEND.
    put unformatted cLinha skip.
    output CLOSE.
end procedure.

run pLog("=================================================================").
run pLog("INICIO : " + STRING(today, "9999-99-99") + " " + STRING(time, "HH:MM:SS")).
run pLog("Fontes : " + cDirFontes).
run pLog("=================================================================").

create ttFila.
assign ttFila.cDir = cDirFontes.

VARREDURA:
repeat:
    find first ttFila exclusive-lock no-error.
    if not available ttFila then leave VARREDURA.
    assign cDirAtual = ttFila.cDir.
    delete ttFila.

    input FROM OS-DIR(cDirAtual).
    repeat on error undo, next:
        import cNome cFullPath cAttr.
        if cNome = "." or cNome = ".." then next.

        if index(cAttr, "D") > 0 then do:
            create ttFila.
            assign ttFila.cDir = cFullPath.
            next.
        end.

        if not cNome matches "*~.cls" then next.

        compile VALUE(cFullPath) save no-error.

        if compiler:error then do:
            run pLog("ERRO  | " + cFullPath + " | " + error-status:get-message(1)).
            assign iErro = iErro + 1.
        end.
        else do:
            //run pLog("OK    | " + cFullPath).
            assign iOk = iOk + 1.
        end.
    end.
    input CLOSE.
end.

run pLog("=================================================================").
run pLog("FIM    : " + STRING(today, "9999-99-99") + " " + STRING(time, "HH:MM:SS")).
run pLog("OK     : " + STRING(iOk)).
run pLog("Erros  : " + STRING(iErro)).
run pLog("=================================================================").

message "Concluido. OK: " iOk " | Erros: " iErro view-as alert-box.
