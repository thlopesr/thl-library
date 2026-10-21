/*------------------------------------------------------------------------
    File        : thl0250rp.p
    Purpose     : Expurgo da auditoria (thl-audit-registro e filhas)
    Description : Para cada tabela com retencao cadastrada em
                  thl-audit-tabela-purge (faixa de banco/tabela informada no
                  thl0250), elimina os registros de auditoria criados antes
                  de (hoje - retencao-dias), com detalhe e notificacao, e
                  grava thl-audit-tabela-purge.dt-ultima-execucao.
    Created     : 2026-09-25
    Notes       : - Retencao zero ou em branco: tabela ignorada.
                  - thl-audit-registro lido por idx-tabela-data (banco,
                    tabela, data-criacao): igualdade em banco e tabela e
                    intervalo na data, delimitados pelo indice.
                  - Uma transacao por registro auditado (com as filhas).
                  - O relatorio traz so o resumo por tabela: o conteudo
                    auditado pode ser sensivel.
  ----------------------------------------------------------------------*/

{include/i-prgvrs.i thl0250rp 12.00.00.000}

/* pre-processador para ativar ou nao a saida para RTF */
&GLOBAL-DEFINE RTF NO

/* pre-processador para setar o tamanho da pagina */
&SCOPED-DEFINE pagesize 42

define temp-table tt-param no-undo
    field destino                as integer
    field arquivo                as character format "x(35)"
    field usuario                as character format "x(12)"
    field data-exec              as date
    field hora-exec              as integer
    field classifica             as integer
    field desc-classifica        as character format "x(40)"
    field modelo-rtf             as character format "x(35)"
    field l-habilitaRtf          as logical
    field banco-ini              like thl-audit-tabela-purge.banco
    field banco-fin              like thl-audit-tabela-purge.banco
    field tabela-ini             like thl-audit-tabela-purge.tabela
    field tabela-fin             like thl-audit-tabela-purge.tabela.

define temp-table tt-raw-digita no-undo
    field raw-digita as raw.

define input parameter raw-param as raw no-undo.
define input parameter table for tt-raw-digita.

create tt-param.
raw-transfer raw-param to tt-param.

{include/i-rpvar.i}

define new global shared variable c-seg-usuario as character format 'x(12)' no-undo.

define variable progressHandle as handle    no-undo.
define variable cutoffDate     as datetime  no-undo.
define variable deletedCount   as integer   no-undo.
define variable totalDeleted   as integer   no-undo.
define variable purgeStatus    as character no-undo format 'x(30)'.
define variable messageIndex   as integer   no-undo.
define variable errorText      as character no-undo format 'x(200)'.

form tt-param.banco-ini   format 'x(30)'  column-label 'Banco Inicial'
     tt-param.banco-fin   format 'x(30)'  column-label 'Banco Final'
     tt-param.tabela-ini  format 'x(30)'  column-label 'Tabela Inicial'
     tt-param.tabela-fin  format 'x(30)'  column-label 'Tabela Final'
     c-seg-usuario        format 'x(30)'  column-label 'Usuario'
    with width 268 frame f-param down stream-io.

form thl-audit-tabela-purge.banco          format 'x(30)'
     thl-audit-tabela-purge.tabela         format 'x(40)'
     thl-audit-tabela-purge.retencao-dias  column-label 'Manter Dias'
     cutoffDate                            column-label 'Eliminar Antes De'
     deletedCount                          column-label 'Registros Eliminados'
     purgeStatus                           column-label 'Situacao'
    with width 268 frame f-tabela down stream-io.

form totalDeleted column-label 'Total Eliminado'
    with width 268 frame f-total down stream-io.

form errorText column-label 'Erro'
    with width 268 frame f-erro down stream-io.

{include/i-rpout.i &STREAM="stream str-rp"}
{include/i-rpcab.i &STREAM="str-rp"}

assign c-programa     = 'thl0250'
       c-versao       = '12.00'
       c-revisao      = '.00.000'
       c-empresa      = 'Nitro'
       c-sistema      = 'Totvs'
       c-titulo-relat = 'Expurgo da Auditoria'.

view stream str-rp frame f-cabec.
view stream str-rp frame f-rodape.

run utp/ut-acomp.p persistent set progressHandle.

run pi-inicializar in progressHandle ( input 'Expurgo da Auditoria' ).

display stream str-rp
        tt-param.banco-ini
        tt-param.banco-fin
        tt-param.tabela-ini
        tt-param.tabela-fin
        c-seg-usuario       with frame f-param.
    down stream str-rp with frame f-param.

for each thl-audit-tabela-purge no-lock
    where thl-audit-tabela-purge.banco  >= tt-param.banco-ini
      and thl-audit-tabela-purge.banco  <= tt-param.banco-fin
      and thl-audit-tabela-purge.tabela >= tt-param.tabela-ini
      and thl-audit-tabela-purge.tabela <= tt-param.tabela-fin.

    run pi-acompanhar in progressHandle ( thl-audit-tabela-purge.tabela ).

    assign deletedCount = 0
           cutoffDate   = ?.

    if thl-audit-tabela-purge.retencao-dias  = ? or 
       thl-audit-tabela-purge.retencao-dias <= 0 then assign purgeStatus = 'Sem retencao - ignorada'.
       
    else do.
    
        // meia-noite do dia-limite: os ultimos retencao-dias ficam inteiros
        assign cutoffDate = datetime( today - thl-audit-tabela-purge.retencao-dias ).

        // cada iteracao e uma transacao (registro + filhas): nao acumula locks
        for each thl-audit-registro exclusive-lock
            where thl-audit-registro.banco        = thl-audit-tabela-purge.banco
              and thl-audit-registro.tabela       = thl-audit-tabela-purge.tabela
              and thl-audit-registro.data-criacao < cutoffDate.

            for each thl-audit-registro-detalhe exclusive-lock
                where thl-audit-registro-detalhe.id-registro = thl-audit-registro.id-registro.
                delete thl-audit-registro-detalhe.
            end.

            for each thl-audit-registro-notificar exclusive-lock
                where thl-audit-registro-notificar.id-registro = thl-audit-registro.id-registro.
                delete thl-audit-registro-notificar.
            end.

            delete thl-audit-registro.
            assign deletedCount = deletedCount + 1.
            
        end.
        
        assign thl-audit-tabela-purge.dt-ultima-execucao = now
               purgeStatus                               = 'Expurgada'.
               
    end.

    assign totalDeleted = totalDeleted + deletedCount.

    display stream str-rp
         thl-audit-tabela-purge.banco
         thl-audit-tabela-purge.tabela
         thl-audit-tabela-purge.retencao-dias
         cutoffDate
         deletedCount
         purgeStatus        with frame f-tabela.
    down stream str-rp with frame f-tabela.
    
end.

display stream str-rp totalDeleted with frame f-total.
    down stream str-rp with frame f-total.

{include/i-rpclo.i &STREAM="stream str-rp"}

return 'OK':U.

catch err as Progress.Lang.Error.

    do messageIndex = 1 to err:NumMessages.
        display stream str-rp err:GetMessage( messageIndex ) @ errorText with frame f-erro.
            down stream str-rp with frame f-erro.
    end.

end catch.

finally.

    if valid-handle( progressHandle ) then
        run pi-finalizar in progressHandle.

end finally.
