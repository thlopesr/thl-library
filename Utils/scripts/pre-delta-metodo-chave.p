/*------------------------------------------------------------------------
    File        : pre-delta-metodo-chave.p
    Purpose     : Prepara os dados para o Database/delta-thl-2026-10-08.df, que
                  elimina a coluna metodo antiga e renomeia o campo acao (da
                  chave) para metodo, em thl-objeto-parametro e em
                  thl-objeto-parametro-rest. Depois do delta so existe o campo
                  da chave: este programa deixa nele o metodo certo.
    Created     : 2026-10-08
    Notes       : - Rodar ANTES do delta, com os fontes ainda da estrutura
                    antiga (este programa cita o campo acao: depois do delta
                    ele nao compila e nao e mais necessario).
                  - Regra: acao = metodo quando o metodo esta no dominio (1 a
                    8). Cobre a base em que o acerto antigo gravou a acao
                    neutra (1 criar, 2 alterar, 3 eliminar, 4 consultar) e a
                    base em que a acao ficou zerada.
                  - Extensao REST: vale o metodo da propria linha; zerado, o
                    da operacao (procurada pela chave atual).
                  - Linha sem metodo fica no log: informar pelo thl0022 depois
                    do delta (o carregador nao acha operacao sem metodo).
                  - Chave repetida depois da troca: nada e gravado; resolver
                    pelo thl0022 e rodar de novo.
                  - A troca passa por um valor provisorio (+100) para a chave
                    unica nao bater no meio do caminho.
                  - Idempotente. Roda em SIMULACAO por padrao (simulate = yes).
                  - Log: <session:temp-directory>pre-delta-metodo-chave.log
  ----------------------------------------------------------------------*/

define variable simulate as logical no-undo initial yes.

define variable logFile      as character no-undo.
define variable totalRead    as integer   no-undo.
define variable totalChange  as integer   no-undo.
define variable totalNoValue as integer   no-undo.
define variable totalRepeat  as integer   no-undo.
define variable newMethod    as integer   no-undo.

define stream logStream.

define buffer b-thl-objeto-parametro      for thl-objeto-parametro.
define buffer b-thl-objeto-parametro-rest for thl-objeto-parametro-rest.

define temp-table tt-acerto no-undo
    field tabela      as character
    field id-registro as rowid
    field chave       as character
    field atual       as integer
    field novo        as integer
    index idx-chave tabela chave novo.

define buffer b-tt-acerto for tt-acerto.

assign logFile = session:temp-directory + "pre-delta-metodo-chave.log".

output stream logStream to value( logFile ).

put stream logStream unformatted
    ( if simulate then "SIMULACAO - nada foi gravado" else "EXECUCAO" ) skip(1)
    "tabela;estabelecimento/aplicacao/objeto/operacao;acao atual;metodo que fica na chave;situacao" skip.

// ------------------------------------------------------------ levantamento

for each b-thl-objeto-parametro no-lock:

    assign newMethod = if b-thl-objeto-parametro.metodo >= 1 and b-thl-objeto-parametro.metodo <= 8
                       then b-thl-objeto-parametro.metodo
                       else b-thl-objeto-parametro.acao.

    create tt-acerto.
    assign tt-acerto.tabela      = "thl-objeto-parametro"
           tt-acerto.id-registro = rowid( b-thl-objeto-parametro )
           tt-acerto.chave       = substitute( "&1/&2/&3/&4", b-thl-objeto-parametro.cod-estabel, b-thl-objeto-parametro.aplicacao,
                                                              b-thl-objeto-parametro.objeto, b-thl-objeto-parametro.operacao )
           tt-acerto.atual       = b-thl-objeto-parametro.acao
           tt-acerto.novo        = newMethod.
end.

for each b-thl-objeto-parametro-rest no-lock:

    assign newMethod = b-thl-objeto-parametro-rest.acao.

    if b-thl-objeto-parametro-rest.metodo >= 1 and b-thl-objeto-parametro-rest.metodo <= 8 then
        assign newMethod = b-thl-objeto-parametro-rest.metodo.
    else do:
        // metodo da operacao, pela chave atual
        find first b-thl-objeto-parametro no-lock
            where b-thl-objeto-parametro.cod-estabel = b-thl-objeto-parametro-rest.cod-estabel
              and b-thl-objeto-parametro.aplicacao   = b-thl-objeto-parametro-rest.aplicacao
              and b-thl-objeto-parametro.objeto      = b-thl-objeto-parametro-rest.objeto
              and b-thl-objeto-parametro.operacao    = b-thl-objeto-parametro-rest.operacao
              and b-thl-objeto-parametro.acao        = b-thl-objeto-parametro-rest.acao
            no-error.

        if available b-thl-objeto-parametro    and
           b-thl-objeto-parametro.metodo >= 1 and
           b-thl-objeto-parametro.metodo <= 8 then
            assign newMethod = b-thl-objeto-parametro.metodo.
    end.

    create tt-acerto.
    assign tt-acerto.tabela      = "thl-objeto-parametro-rest"
           tt-acerto.id-registro = rowid( b-thl-objeto-parametro-rest )
           tt-acerto.chave       = substitute( "&1/&2/&3/&4", b-thl-objeto-parametro-rest.cod-estabel, b-thl-objeto-parametro-rest.aplicacao,
                                                              b-thl-objeto-parametro-rest.objeto, b-thl-objeto-parametro-rest.operacao )
           tt-acerto.atual       = b-thl-objeto-parametro-rest.acao
           tt-acerto.novo        = newMethod.
end.

// ------------------------------------------------------------ conferencia

for each tt-acerto:

    assign totalRead = totalRead + 1.

    if tt-acerto.novo < 1 then do:
        assign totalNoValue = totalNoValue + 1.
        put stream logStream unformatted tt-acerto.tabela ";" tt-acerto.chave ";" tt-acerto.atual ";" tt-acerto.novo ";sem metodo - informar pelo thl0022 depois do delta" skip.
        next.
    end.

    if can-find( first b-tt-acerto
                 where b-tt-acerto.tabela = tt-acerto.tabela
                   and b-tt-acerto.chave  = tt-acerto.chave
                   and b-tt-acerto.novo   = tt-acerto.novo
                   and rowid( b-tt-acerto ) <> rowid( tt-acerto ) ) then do:
        assign totalRepeat = totalRepeat + 1.
        put stream logStream unformatted tt-acerto.tabela ";" tt-acerto.chave ";" tt-acerto.atual ";" tt-acerto.novo ";CHAVE REPETIDA - mais de uma linha ficaria com este metodo" skip.
        next.
    end.

    if tt-acerto.atual <> tt-acerto.novo then do:
        assign totalChange = totalChange + 1.
        put stream logStream unformatted tt-acerto.tabela ";" tt-acerto.chave ";" tt-acerto.atual ";" tt-acerto.novo ";"
            ( if simulate then "seria alterado" else "alterado" ) skip.
    end.

end.

// ------------------------------------------------------------ gravacao

if not simulate and totalRepeat = 0 then do transaction:

    // 1a passada: valor provisorio, para a chave unica nao bater
    for each tt-acerto
        where tt-acerto.novo  >= 1
          and tt-acerto.atual <> tt-acerto.novo:
        run setKey( tt-acerto.tabela, tt-acerto.id-registro, tt-acerto.novo + 100 ).
    end.

    // 2a passada: o metodo
    for each tt-acerto
        where tt-acerto.novo  >= 1
          and tt-acerto.atual <> tt-acerto.novo:
        run setKey( tt-acerto.tabela, tt-acerto.id-registro, tt-acerto.novo ).
    end.

end.

put stream logStream unformatted skip(1)
    "Linhas lidas: " totalRead skip
    ( if simulate then "Seriam alteradas: " else "Alteradas: " ) ( if not simulate and totalRepeat > 0 then 0 else totalChange ) skip
    "Sem metodo: " totalNoValue skip
    "Chave repetida (impede a gravacao): " totalRepeat skip.
output stream logStream close.

message ( if simulate then "SIMULACAO - nada foi gravado." + chr(10) else "" )
        ( if totalRepeat > 0 then "CHAVE REPETIDA: nada foi gravado. Veja o log." + chr(10) else "" )
        "Linhas lidas: " totalRead chr(10)
        ( if simulate then "Seriam alteradas: " else "Alteradas: " ) ( if not simulate and totalRepeat > 0 then 0 else totalChange ) chr(10)
        "Sem metodo: " totalNoValue chr(10)
        "Chave repetida: " totalRepeat chr(10)
        "Log: " logFile
    view-as alert-box information.

procedure setKey private:
    define input parameter tableName as character no-undo.
    define input parameter recordId  as rowid     no-undo.
    define input parameter keyValue  as integer   no-undo.

    if tableName = "thl-objeto-parametro" then do:
        find b-thl-objeto-parametro exclusive-lock
            where rowid( b-thl-objeto-parametro ) = recordId.
        assign b-thl-objeto-parametro.acao = keyValue.
        release b-thl-objeto-parametro.
    end.
    else do:
        find b-thl-objeto-parametro-rest exclusive-lock
            where rowid( b-thl-objeto-parametro-rest ) = recordId.
        assign b-thl-objeto-parametro-rest.acao = keyValue.
        release b-thl-objeto-parametro-rest.
    end.
end procedure.
