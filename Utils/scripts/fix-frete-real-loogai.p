using Progress.Json.ObjectModel.*.

block-level on error undo, throw.

define variable iCriados   as integer no-undo.
define variable iIgnorados as integer no-undo.
define variable iErros     as integer no-undo.

define variable oParser         as ObjectModelParser no-undo.
define variable oJson           as JsonObject        no-undo.
define variable lcJson          as longchar          no-undo.
define variable cSeries         as character         no-undo.
define variable cNotas          as character         no-undo.
define variable iIdx            as integer           no-undo.

define buffer b-mensagem   for thl-mensagem.
define buffer b-conteudo   for thl-mensagem-conteudo.
define buffer b-emitente   for emitente.
define buffer b-estabelec  for estabelec.
define buffer b-docum-est  for docum-est.
define buffer b-frete-real for nit-frete-real.

assign oParser = new ObjectModelParser()
       fix-codepage(lcJson) = 'UTF-8'.
       
for each b-frete-real
    where b-frete-real.des-observacao = 'Importado'.
    delete b-frete-real.
end.

for each b-mensagem no-lock
    where b-mensagem.objeto            = 'Documento'
    .

    find first b-conteudo no-lock
        where b-conteudo.codigo-mensagem = b-mensagem.codigo-mensagem
          and b-conteudo.tipo-conteudo   = 2
        no-error.

    if not available b-conteudo then
        next.

    assign lcJson               = b-conteudo.conteudo
           oJson                = cast(oParser:Parse(lcJson), JsonObject).

    if not valid-object(oJson) then
        next.

    if not oJson:Has('TipoNf')              or
       not oJson:Has('cnpjEstabelecimento') or 
       not oJson:Has('cnpjTransportadora')  or 
       not oJson:Has('serie')               or 
       not oJson:Has('numeroDocumento')     or 
       not oJson:Has('serieNFCliente')      or
       not oJson:Has('numeroNFCliente')     or 
       not oJson:Has('valorTotal')          then next.

    if oJson:GetCharacter('TipoNf') <> 'Saida' then
        next.

    find first b-estabelec no-lock
        where b-estabelec.cgc = oJson:GetCharacter('cnpjEstabelecimento')
        no-error.

    if not available b-estabelec then do:
        assign iErros = iErros + 1.
        message substitute('[ERRO] Estabelecimento nao localizado - CNPJ: &1 - Msg: &2',
            oJson:GetCharacter('cnpjEstabelecimento'), b-mensagem.codigo-mensagem).
        next.
    end.

    find first b-emitente no-lock
        where b-emitente.cgc = oJson:GetCharacter('cnpjTransportadora')
        no-error.

    if not available b-emitente then do:
        assign iErros = iErros + 1.
        message substitute('[ERRO] Transportadora nao localizada - CNPJ: &1 - Msg: &2',
            oJson:GetCharacter('cnpjTransportadora'), b-mensagem.codigo-mensagem).
        next.
    end.

    find first b-docum-est no-lock
        where b-docum-est.cod-estabel  = b-estabelec.cod-estabel
          and b-docum-est.cod-emitente = b-emitente.cod-emitente
          and b-docum-est.serie-docto  = oJson:GetCharacter('serie')
          and b-docum-est.nro-docto    = oJson:GetCharacter('numeroDocumento')
        no-error.

    if not available b-docum-est then do:
        assign iErros = iErros + 1.
        message substitute('[ERRO] Documento nao localizado - Emit: &1 Estabel: &2 Serie: &3 Nr: &4 - Msg: &5',
            b-emitente.cod-emitente, b-estabelec.cod-estabel,
            oJson:GetCharacter('serie'), oJson:GetCharacter('numeroDocumento'),
            b-mensagem.codigo-mensagem).
        next.
    end.

    assign cSeries = oJson:GetCharacter('serieNFCliente')
           cNotas  = oJson:GetCharacter('numeroNFCliente').

    do iIdx = 1 to num-entries(cSeries):

        if can-find(first b-frete-real
                        where b-frete-real.serie-docto  = b-docum-est.serie-docto
                          and b-frete-real.nro-docto    = b-docum-est.nro-docto
                          and b-frete-real.cod-emitente = b-docum-est.cod-emitente
                          and b-frete-real.nat-operacao = b-docum-est.nat-operacao
                          and b-frete-real.cod-estabel  = b-docum-est.cod-estabel
                          and b-frete-real.serie        = trim( entry(iIdx, cSeries) )
                          and b-frete-real.nr-nota-fis  = trim( entry(iIdx, cNotas)) ) then do.
            assign iIgnorados = iIgnorados + 1.
            message substitute('[SKIP] Registro ja existe - Doc: &1/&2 NF: &3/&4',
                b-docum-est.serie-docto, b-docum-est.nro-docto,
                entry(iIdx, cSeries), entry(iIdx, cNotas)).
            next.
        end.

        do transaction on error undo, next:

            create b-frete-real.
            assign
                /* chave docum-est (documento de recebimento criado) */
                b-frete-real.serie-docto    = b-docum-est.serie-docto
                b-frete-real.nro-docto      = b-docum-est.nro-docto
                b-frete-real.cod-emitente   = b-docum-est.cod-emitente
                b-frete-real.nat-operacao   = b-docum-est.nat-operacao
                b-frete-real.cod-estabel    = b-docum-est.cod-estabel
                /* chave NF de origem - entry(iIdx) para suportar multiplos pares serie,nota */
                b-frete-real.serie          = trim( entry(iIdx, cSeries) )
                b-frete-real.nr-nota-fis    = trim( entry(iIdx, cNotas ) )
                b-frete-real.idi-tipo-frete = if oJson:Has('tipoFrete') then oJson:GetInteger('tipoFrete')
                                                                        else 150
                b-frete-real.val-frete      = oJson:GetDecimal('valorTotal') / num-entries(cSeries)
                b-frete-real.idi-situacao   = 1
                b-frete-real.des-observacao = 'Importado Modelo Antigo'
                .

            assign iCriados = iCriados + 1.
            message substitute('[OK] Frete criado - Doc: &1/&2 NF: &3/&4 Valor: &5',
                b-docum-est.serie-docto, b-docum-est.nro-docto,
                entry(iIdx, cSeries), entry(iIdx, cNotas),
                oJson:GetDecimal('valorTotal')).

        end. /* do transaction */

    end. /* do iIdx */

end. /* for each b-mensagem */

message substitute('=== Concluido: &1 criados | &2 ignorados/pulados | &3 erros ===',
    iCriados, iIgnorados, iErros).
