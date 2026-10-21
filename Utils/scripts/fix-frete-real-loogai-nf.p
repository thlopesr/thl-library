/*------------------------------------------------------------------------
    File        : fix-frete-real-loogai-nf.p
    Purpose     : Script temporario - releitura de mensagens Loog.ai com
                  array notaFiscalTransportada para popular nit-frete-real.
    Author(s)   : Lopes
    Created     : 2026-08-27
    Notes       : Layout com tipoDocumento no raiz e NFs no array
                  notaFiscalTransportada (serie, numero, tipoFrete,
                  valorFrete, observacaoFrete).
                  Log gerado em \\tsclient\c\temp\log.csv (append).
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.

define variable iCriados   as integer no-undo.
define variable iIgnorados as integer no-undo.
define variable iErros     as integer no-undo.

define variable oParser      as ObjectModelParser no-undo.
define variable oJson        as JsonObject        no-undo.
define variable oNfArray     as JsonArray         no-undo.
define variable oNfItem      as JsonObject        no-undo.
define variable lcJson       as longchar          no-undo.
define variable iNf          as integer           no-undo.

define buffer b-mensagem   for thl-mensagem.
define buffer b-conteudo   for thl-mensagem-conteudo.
define buffer b-emitente   for emitente.
define buffer b-estabelec  for estabelec.
define buffer b-docum-est  for docum-est.
define buffer b-frete-real for nit-frete-real.

define stream s-log.

assign oParser              = new ObjectModelParser()
       fix-codepage(lcJson) = 'UTF-8'.

output stream s-log to '\\tsclient\c\temp\log.csv' append.
put stream s-log unformatted 'Tipo;CodigoMensagem;DocSerie;DocNumero;NFSerie;NFNumero;Valor;Detalhe' skip.

for each b-mensagem no-lock
    where b-mensagem.objeto            = 'Documento'
      //and b-mensagem.aplicacao         = 'Loog.ai'
      //and b-mensagem.operacao          = 'Loogai'
      //and b-mensagem.modelo-integracao = 1    /* ConnectorTypeEnum:REST   */
      //and b-mensagem.metodo            = 1    /* MethodTypeEnum:POST      */
      //and b-mensagem.sentido-fluxo     = true /* Entrada / inbound        */
      //and b-mensagem.sit-processamento = 3   /* MessageStatusEnum:SUCCESS */
    .
    
    find first b-conteudo no-lock
        where b-conteudo.codigo-mensagem = b-mensagem.codigo-mensagem
          and b-conteudo.tipo-conteudo   = 2
        no-error.

    if not available b-conteudo then
        next.

    assign lcJson = b-conteudo.conteudo
           oJson  = cast(oParser:Parse(lcJson), JsonObject).

    if not valid-object(oJson) then
        next.

    if not oJson:Has('tipoDocumento')          or
       not oJson:Has('cnpjEstabelecimento')    or
       not oJson:Has('cnpjTransportadora')     or
       not oJson:Has('serie')                  or
       not oJson:Has('numeroDocumento')        or
       not oJson:Has('notaFiscalTransportada') or
       not oJson:Has('valorTotal')             then
        next.

    if oJson:GetCharacter('tipoDocumento') <> 'Saida' then
        next.

    assign oNfArray = oJson:GetJsonArray('notaFiscalTransportada').

    if not valid-object(oNfArray) or oNfArray:Length = 0 then
        next.

    find first b-estabelec no-lock
        where b-estabelec.cgc = oJson:GetCharacter('cnpjEstabelecimento')
        no-error.

    if not available b-estabelec then do:
        assign iErros = iErros + 1.
        put stream s-log unformatted
            substitute('ERRO;&1;;;;; ;Estabelecimento nao localizado - CNPJ: &2',
                b-mensagem.codigo-mensagem,
                oJson:GetCharacter('cnpjEstabelecimento')) skip.
        next.
    end.

    find first b-emitente no-lock
        where b-emitente.cgc = oJson:GetCharacter('cnpjTransportadora')
        no-error.

    if not available b-emitente then do:
        assign iErros = iErros + 1.
        put stream s-log unformatted
            substitute('ERRO;&1;;;;; ;Transportadora nao localizada - CNPJ: &2',
                b-mensagem.codigo-mensagem,
                oJson:GetCharacter('cnpjTransportadora')) skip.
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
        put stream s-log unformatted
            substitute('ERRO;&1;&2;&3;;; ;Documento nao localizado - Emit: &4 Estabel: &5',
                b-mensagem.codigo-mensagem,
                oJson:GetCharacter('serie'),
                oJson:GetCharacter('numeroDocumento'),
                b-emitente.cod-emitente,
                b-estabelec.cod-estabel) skip.
        next.
    end.

    do iNf = 1 to oNfArray:Length.

        assign oNfItem = oNfArray:GetJsonObject(iNf).

        if not valid-object(oNfItem)     or
           not oNfItem:Has('serie')      or
           not oNfItem:Has('numero')     or
           not oNfItem:Has('tipoFrete')  or
           not oNfItem:Has('valorFrete') then
            next.

        if can-find(first b-frete-real
                        where b-frete-real.serie-docto  = b-docum-est.serie-docto
                          and b-frete-real.nro-docto    = b-docum-est.nro-docto
                          and b-frete-real.cod-emitente = b-docum-est.cod-emitente
                          and b-frete-real.nat-operacao = b-docum-est.nat-operacao
                          and b-frete-real.cod-estabel  = b-docum-est.cod-estabel
                          and b-frete-real.serie        = oNfItem:GetCharacter('serie')
                          and b-frete-real.nr-nota-fis  = oNfItem:GetCharacter('numero')) then do:
            assign iIgnorados = iIgnorados + 1.
            put stream s-log unformatted
                substitute('SKIP;&1;&2;&3;&4;&5;; ',
                    b-mensagem.codigo-mensagem,
                    b-docum-est.serie-docto,
                    b-docum-est.nro-docto,
                    oNfItem:GetCharacter('serie'),
                    oNfItem:GetCharacter('numero')) skip.
            next.
        end.

        do transaction on error undo, next:

            create b-frete-real.
            assign b-frete-real.serie-docto    = b-docum-est.serie-docto
                   b-frete-real.nro-docto      = b-docum-est.nro-docto
                   b-frete-real.cod-emitente   = b-docum-est.cod-emitente
                   b-frete-real.nat-operacao   = b-docum-est.nat-operacao
                   b-frete-real.cod-estabel    = b-docum-est.cod-estabel
                   b-frete-real.serie          = oNfItem:GetCharacter('serie')
                   b-frete-real.nr-nota-fis    = oNfItem:GetCharacter('numero')
                   b-frete-real.idi-tipo-frete = oNfItem:GetInteger('tipoFrete')
                   b-frete-real.val-frete      = oJson:GetDecimal('valorTotal') / oNfArray:Length 
                   b-frete-real.idi-situacao   = 1
                   b-frete-real.des-observacao = 'Importado Modelo Novo'
                   .

            assign iCriados = iCriados + 1.
            put stream s-log unformatted
                substitute('OK;&1;&2;&3;&4;&5;&6; ',
                    b-mensagem.codigo-mensagem,
                    b-docum-est.serie-docto,
                    b-docum-est.nro-docto,
                    oNfItem:GetCharacter('serie'),
                    oNfItem:GetCharacter('numero'),
                    oNfItem:GetDecimal('valorFrete')) skip.

        end. /* do transaction */

    end. /* do iNf */

end. /* for each b-mensagem */

put stream s-log unformatted
    substitute('RESUMO;;;;;; ;Criados: &1 | Ignorados: &2 | Erros: &3',
        iCriados, iIgnorados, iErros) skip.

output stream s-log close.

message substitute('=== Concluido: &1 criados | &2 ignorados/pulados | &3 erros ===~nLog: \\tsclient\c\temp\log.csv',
    iCriados, iIgnorados, iErros).
