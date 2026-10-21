/*------------------------------------------------------------------------
    File        : acerto-thl-sit-mensagem.p
    Purpose     : Preenche a situacao geral (thl-mensagem.sit-mensagem) das
                  mensagens gravadas antes de o campo existir.
    Created     : 2026-10-03
    Notes       : - ADR Documentos/.claude/adr/metricas-conteudo-expurgo-mensagens.md.
                  - Mesma regra do MessageRepository: alguma fase em erro ->
                    2 Erro; senao, alguma pendente -> 1 Pendente; todas em
                    sucesso ou nao aplicavel -> 3 Sucesso.
                  - Outbound agendado aceito e ainda nao executado (destino
                    RPW, requisicao e retorno em sucesso, processamento nao
                    aplicavel) fica como 1 Pendente.
                  - Idempotente: so altera mensagem cuja situacao difere.
                  - Roda em SIMULACAO por padrao (simulate = yes): so conta.
                    Para gravar, altere simulate para no e rode de novo.
                  - Uma transacao por mensagem; mensagem bloqueada por outra
                    sessao e pulada e contada (rodar de novo depois).
                  - Le a thl-mensagem inteira: rodar fora do horario de pico.
                  - Log: <session:temp-directory>acerto-thl-sit-mensagem.log
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

define variable simulate     as logical   no-undo initial yes.
define variable logFile      as character no-undo.
define variable newStatus    as integer   no-undo.
define variable totalRead    as integer   no-undo.
define variable totalChanged as integer   no-undo.
define variable totalLocked  as integer   no-undo.
define variable statusCount  as integer   no-undo extent 3.

define buffer b-thl-mensagem for thl-mensagem.

define stream logStream.

/* ***************************  Main Block  *************************** */

for each thl-mensagem no-lock:

    if thl-mensagem.sit-requisicao    = 2 or
       thl-mensagem.sit-processamento = 2 or
       thl-mensagem.sit-retorno       = 2 then
        assign newStatus = 2.

    else if thl-mensagem.sit-requisicao    = 1 or
            thl-mensagem.sit-processamento = 1 or
            thl-mensagem.sit-retorno       = 1 then
        assign newStatus = 1.

    // agendamento outbound aceito, RPW ainda nao executou
    else if thl-mensagem.sentido-fluxo and
            thl-mensagem.destino           = "RPW" and
            thl-mensagem.sit-processamento = 4     then
        assign newStatus = 1.

    else
        assign newStatus = 3.

    assign totalRead              = totalRead + 1
           statusCount[newStatus] = statusCount[newStatus] + 1.

    if thl-mensagem.sit-mensagem = newStatus then
        next.

    if simulate then do:
        assign totalChanged = totalChanged + 1.
        next.
    end.

    do transaction:

        find b-thl-mensagem exclusive-lock
            where rowid( b-thl-mensagem ) = rowid( thl-mensagem )
            no-wait no-error.

        if not available b-thl-mensagem then do:
            assign totalLocked = totalLocked + 1.
            next.
        end.

        assign b-thl-mensagem.sit-mensagem = newStatus
               totalChanged                = totalChanged + 1.

        release b-thl-mensagem.

    end.

end.

logFile = session:temp-directory + "acerto-thl-sit-mensagem.log".

output stream logStream to value( logFile ).
put stream logStream unformatted
    "Acerto de thl-mensagem.sit-mensagem em " string( now ) ( if simulate then " - SIMULACAO (nada gravado)" else "" ) skip
    "Mensagens lidas: " totalRead skip
    "1 - Pendente: " statusCount[1] skip
    "2 - Erro: " statusCount[2] skip
    "3 - Sucesso: " statusCount[3] skip
    ( if simulate then "Seriam alteradas: " else "Alteradas: " ) totalChanged skip
    "Bloqueadas (puladas): " totalLocked skip.
output stream logStream close.

message ( if simulate then "SIMULACAO - nada foi gravado." + chr(10) else "" )
        "Mensagens lidas: " totalRead chr(10)
        "1 - Pendente: " statusCount[1] chr(10)
        "2 - Erro: " statusCount[2] chr(10)
        "3 - Sucesso: " statusCount[3] chr(10)
        ( if simulate then "Seriam alteradas: " else "Alteradas: " ) totalChanged chr(10)
        "Bloqueadas (puladas): " totalLocked chr(10)
        "Log: " logFile
    view-as alert-box information.
