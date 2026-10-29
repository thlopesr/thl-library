/*------------------------------------------------------------------------
    File        : NotaFiscalBaseService
    Purpose     : Base abstrata dos Services de nota fiscal (NF direta e
                  NF por embarque). Concentra o que era duplicado entre
                  NotaFiscalService e NotaFiscalPorEmbarqueService:
                  temp-tables, exportacao de XML NF-e (ft0910rp), nucleo
                  de autorizacao SEFAZ com retry (ft0915a/bodi135na),
                  impressao (esft1932i), montagem do item de resposta e
                  leitura de variaveis de ambiente.
    Author(s)   : Lopes
    Created     : 2026-07-25 (Fase 3.1 do backlog inbound-erp)
    Notes       : As chaves do item de resposta divergem entre as duas
                  concretas por contrato externo historico - hooks
                  getStatusMessageKey/getValidFileKey preservam isso ate a
                  decisao do item 3.3 (unificacao com o integrador).
                  Estado de instancia (inPayload/outPayload/b-nota-fiscal)
                  e intencional: as operacoes encadeadas (ex: process)
                  compartilham o posicionamento entre etapas. Invariante:
                  toda operacao publica DEVE iniciar por
                  initialize() - item 3.5.
                  2026-10-08: as etapas sao metodos publicos (generateInvoice,
                  generateNfeXml, authorizeSefaz, printInvoice, notifyInvoice);
                  quem escolhe a etapa e o NotaFiscalProcessor, nao o create().
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-lib.core.environment.EnvironmentResource.
using thl-lib.core.error.*.
using thl-lib.erp.core.BusinessObject.
using thl-lib.erp.enum.SituacaoNfeEnum.


block-level on error undo, throw.

class thl-lib.erp.service.NotaFiscalBaseService abstract inherits BusinessObject.

    define protected temp-table tt-res-cli no-undo like res-cli
           field r-rowid as rowid.

    define protected temp-table tt-nota-gerada no-undo
        field rw-nota-fiscal as rowid
        field nr-nota        like nota-fiscal.nr-nota-fis
        field seq-wt-docto   like wt-docto.seq-wt-docto.

    define protected temp-table tt-nota-fiscal no-undo like nota-fiscal
        field r-Rowid as rowid.

    define protected temp-table tt-param no-undo
        field destino            as integer
        field arquivo            as character
        field usuario            as character
        field data-exec          as date
        field hora-exec          as integer
        field cod-estabel-ini    like nota-fiscal.cod-estabel
        field cod-estabel-fim    like nota-fiscal.cod-estabel
        field serie-ini          like nota-fiscal.serie
        field serie-fim          like nota-fiscal.serie
        field nr-nota-fis-ini    like nota-fiscal.nr-nota-fis
        field nr-nota-fis-fim    like nota-fiscal.nr-nota-fis
        field nome-ab-cli-ini    like nota-fiscal.nome-ab-cli
        field nome-ab-cli-fim    like nota-fiscal.nome-ab-cli
        field dt-emis-nota-ini   like nota-fiscal.dt-emis-nota
        field dt-emis-nota-fim   like nota-fiscal.dt-emis-nota
        field gera-nfe-n-gerada  as logical
        field gera-nfe-gerada    as logical
        field gera-nfe-rejeitada as logical
        field exporta-est-txt    as logical
        field gera-nfe-cancel    as logical
        field gera-nfe-inut      as logical
        field c-motivo           as character.

    define protected temp-table tt-digita no-undo
        field nat-operacao     like natur-oper.nat-operacao
        field descricao        as character
        index id nat-operacao.

    define protected temp-table tt-raw-digita no-undo
        field raw-digita as raw.

    define protected buffer b-nota-fiscal for nota-fiscal.

    define protected property outPayload  as JsonArray  no-undo get. private set.
    define protected property inPayload   as JsonObject no-undo get. private set.

    method public override void initialize().
        assign outPayload = new JsonArray()
               inPayload  = this-object:inContext.
    end method.

    //Etapas da nota fiscal. Quem escolhe a etapa e o NotaFiscalProcessor
    //(orquestracao); o Service so executa. create() = geracao.
    method public abstract void generateInvoice().
    method public abstract void generateNfeXml().
    method public abstract void authorizeSefaz().
    method public abstract void printInvoice().
    method public abstract void notifyInvoice().

    //Espera sincrona do retorno da SEFAZ (TSS) entre o XML e a autorizacao, no
    //encadeamento completo. Restricao de plataforma: o Datasul nao tem integracao
    //assincrona nativa. Variavel de ambiente intervalo.processamento (teto 60s).
    method public void waitSefazProcessing().
        pause this-object:getEnvironmentIntegerCapped( 'intervalo.processamento', 60 ).
    end method.

    //Diretorio dos arquivos da nota (XML e documento impresso), sempre com separador no fim.
    //Padrao: diretorio temporario da sessao; o Service que configura outro sobrescreve.
    method protected character getDirectory().
        return session:temp-directory.
    end method.

    /*--------------------------------------------------------------------------
      Exporta o XML NF-e da faixa de notas informada via ftp/ft0910rp.p.
      resultMessage: return-value do programa. Retorna o arquivo temporario.
    --------------------------------------------------------------------------*/
    method protected character exportNfeXml(  input establishmentCode as character,
                                              input seriesCode        as character,
                                              input invoiceNumberIni  as character,
                                              input invoiceNumberFin  as character,
                                             output resultMessage     as character ).

        define variable rawParam as raw       no-undo.
        define variable tempFile as character no-undo.

        empty temp-table tt-param      no-error.
        empty temp-table tt-raw-digita no-error.

        assign tempFile = this-object:getDirectory() + 'FT0910.tmp'.

        create tt-param.
        assign tt-param.usuario            = new EnvironmentResource():getEnvironmentVariable( 'usuario.nfe' )
               tt-param.destino            = 2
               tt-param.data-exec          = today
               tt-param.hora-exec          = time
               tt-param.arquivo            = tempFile
               tt-param.cod-estabel-ini    = establishmentCode
               tt-param.cod-estabel-fim    = establishmentCode
               tt-param.serie-ini          = seriesCode
               tt-param.serie-fim          = seriesCode
               tt-param.nr-nota-fis-ini    = invoiceNumberIni
               tt-param.nr-nota-fis-fim    = invoiceNumberFin
               tt-param.nome-ab-cli-ini    = ''
               tt-param.nome-ab-cli-fim    = 'ZZZZZZZZZZZZ'
               tt-param.dt-emis-nota-ini   = 01/01/0001
               tt-param.dt-emis-nota-fim   = 12/31/9999
               tt-param.gera-nfe-n-gerada  = true
               tt-param.gera-nfe-gerada    = true
               tt-param.gera-nfe-rejeitada = true
               tt-param.exporta-est-txt    = false
               tt-param.gera-nfe-cancel    = false
               tt-param.gera-nfe-inut      = false
               tt-param.c-motivo           = ''.

        raw-transfer tt-param to rawParam.

        run ftp/ft0910rp.p ( input       rawParam     ,
                             input table tt-raw-digita).

        assign resultMessage = return-value.

        return tempFile.

    end method.

    /*--------------------------------------------------------------------------
      Nucleo de autorizacao SEFAZ com retry, operando sobre tt-nota-fiscal
      (populada pelo chamador a partir de b-nota-fiscal posicionado).
      Sai quando a nota autoriza (sitCode 3), atinge estado final (4-7) ou
      esgota as tentativas (attemptsUsed > getSefazMaxAttempts()).
    --------------------------------------------------------------------------*/
    method protected void runSefazAuthorization(  input h-acompanhar as handle   ,
                                                 output sitCode      as integer  ,
                                                 output sitMessage   as character,
                                                 output attemptsUsed as integer  ).

        define variable hBodi135na     as handle  no-undo.
        define variable iMaxTentativas as integer no-undo.
        define variable iPausaSeg      as integer no-undo.

        assign iMaxTentativas = this-object:getSefazMaxAttempts  ()
               iPausaSeg      = this-object:getSefazPauseSeconds ().

        sefaz:
        do attemptsUsed = 1 to iMaxTentativas.

            run ftp/ft0915a.p (  input  table tt-nota-fiscal,
                                 input  false               ,
                                 input  h-acompanhar        ,
                                output  table RowErrors     ).

            this-object:throwRowErrorsIfAny( 'runSefazAuthorization', 'ft0915a' ).

            run dibo/bodi135na.p persistent set hBodi135na.

            run retornaSitNF-e in hBodi135na (  input  tt-nota-fiscal.cod-estabel ,
                                                input  tt-nota-fiscal.serie       ,
                                                input  tt-nota-fiscal.nr-nota-fis ,
                                                input  tt-nota-fiscal.dt-emis-nota,
                                               output  sitCode                    ,
                                               output  sitMessage                 ).

            delete procedure hBodi135na no-error.

            if sitCode = SituacaoNfeEnum:AUTORIZADA:GetValue()  then leave sefaz.

            if sitCode >= SituacaoNfeEnum:DENEGADA:GetValue() and
               sitCode <= SituacaoNfeEnum:INUTILIZADA:GetValue() then leave sefaz.

            //NOTA ARQUITETURAL: TOTVS/Datasul nao possui mecanismo de integracao
            //assincrona nativo. Esta espera sincrona (pause) e necessaria para
            //aguardar a autenticacao SEFAZ via TSS - restricao de plataforma,
            //nao e bug nem candidato a refatoracao para fluxo assincrono.
            pause iPausaSeg.

        end.

    end method.

    /*--------------------------------------------------------------------------
      Imprime a nota posicionada em b-nota-fiscal via ftp\esft1932i.p.
      Opcao de impressao vem de inPayload('opcao'), default 1.
      Retorna o caminho do arquivo gerado.
    --------------------------------------------------------------------------*/
    method protected character printInvoiceDocument().

        define variable invoiceFile as character no-undo.
        define variable printOption as integer   no-undo.

        assign printOption = if inPayload:Has('opcao') then inPayload:GetInteger('opcao')
                                                       else 1
               invoiceFile = substitute( '&1&2-&3-&4-.doc'         ,
                                         this-object:getDirectory(),
                                         b-nota-fiscal.cod-estabel ,
                                         b-nota-fiscal.serie       ,
                                         b-nota-fiscal.nr-nota-fis ).

        run ftp\esft1932i.p ( b-nota-fiscal.cod-estabel ,
                              b-nota-fiscal.serie       ,
                              b-nota-fiscal.nr-nota-fis ,
                              printOption               ,
                              invoiceFile               ).

        return invoiceFile.

    end method.

    /*--------------------------------------------------------------------------
      Item de resposta unificado. As chaves de status/validade divergem por
      contrato externo historico entre NF direta e NF por embarque - hooks
      abaixo preservam o contrato ate a decisao do item 3.3 do backlog.
    --------------------------------------------------------------------------*/
    method protected void addInvoicePayload( input establishmentCode as character,
                                             input seriesCode        as character,
                                             input invoiceNumber     as character,
                                             input statusMessage     as character,
                                             input file_             as character,
                                             input validFile         as logical  ).

        define variable invoice as JsonObject no-undo.

        assign invoice = new JsonObject().

        invoice:Add( 'codigoEstabelecimento'          , establishmentCode ).
        invoice:Add( 'serie'                          , seriesCode        ).
        invoice:Add( 'numeroNotaFiscal'               , invoiceNumber     ).
        invoice:Add( this-object:getStatusMessageKey(), statusMessage     ).
        invoice:Add( 'arquivo'                        , file_             ).
        invoice:Add( this-object:getValidFileKey()    , validFile         ).

        outPayload:Add( invoice ).

    end method.

    method protected character getStatusMessageKey().
        return 'mensagem'.
    end method.

    method protected character getValidFileKey().
        return 'valido'.
    end method.

    //Item 3.2: defaults de retry SEFAZ unificados entre as concretas
    //(3 tentativas / 5s), sobrepostos pelas env vars sefaz.tentativa e
    //sefaz.pausa quando configuradas.
    method protected integer getSefazMaxAttempts().
        return this-object:getEnvironmentIntegerCapped( 'sefaz.tentativa', 3 ).
    end method.

    method protected integer getSefazPauseSeconds().
        return this-object:getEnvironmentIntegerCapped( 'sefaz.pausa', 5 ).
    end method.

    //Le a variavel de ambiente como inteiro, usando maxValue como default
    //quando nao configurada e como teto quando o valor configurado excede.
    method protected integer getEnvironmentIntegerCapped( input variableCode as character ,
                                                          input maxValue     as integer   ).

        define variable cEnvValue as character no-undo.

        assign cEnvValue = new EnvironmentResource():getEnvironmentVariable( variableCode ).

        if cEnvValue = '' then
            return maxValue.

        return minimum( integer( cEnvValue ), maxValue ).

    end method.

end class.
