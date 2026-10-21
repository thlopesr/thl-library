/*------------------------------------------------------------------------
    File        : ProcessoExportacaoMessage
    Purpose     : Envia ao Automatizador (RPA) o lote de processos de exportacao
    Syntax      :
    Description : Substitui o envio direto do esex1986rp.p. Modo Multiple: todos
                  os processos vao no mesmo corpo { "processos": [ ... ] }.
    Author(s)   : Lopes
    Created     : Tue Oct 13 2026
    Notes       : Destino (conexao/path), autenticacao e headers ficam nos
                  cadastros thl0030-thl0033; nada fixo neste fonte.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using thl-lib.integration.messaging.outbound.core.OutboundMessage.

block-level on error undo, throw.

class thl-extensions.integration.automatizador.messaging.outbound.message.ProcessoExportacaoMessage inherits OutboundMessage.

    define private buffer b-processo-exp    for processo-exp.
    define private buffer b-proces-exp-adic for proces-exp-adic.
    define private buffer b-es-processo-exp for es_processo_exp.

    constructor public ProcessoExportacaoMessage ( objectName           as character ,
                                                   applicationName      as character ,
                                                   integrationOperation as character ,
                                                   methodType           as integer   ,
                                                   connectorType        as integer   ,
                                                   integrationDirection as logical   ,
                                                   executionMode        as integer   ).
        super( objectName, applicationName, integrationOperation, methodType, connectorType, integrationDirection, executionMode ).
    end constructor.

    // Cria o objeto raiz com o array na primeira chamada e acrescenta um item por processo
    method public override void appendPayloadObject().

        define variable processo  as JsonObject no-undo.
        define variable processos as JsonArray  no-undo.

        this-object:initializeObjectPayload().
        cast( payload, JsonObject ):add( 'processos', new JsonArray() ).

        assign processos = cast( payload, JsonObject ):GetJsonArray( 'processos' )
               processo  = new JsonObject().

        processo:add( 'codigoEstabelecimento'   , b-processo-exp.cod-estabel                    ).
        processo:add( 'numeroProcessoExportacao', b-processo-exp.nr-proc-exp                    ).
        processo:add( 'codigoSituacao'          ,    string( b-processo-exp.cod-sit-proc )      ).
        processo:add( 'terminalEmbarque'        , substring( b-es-processo-exp.char-1, 40, 10 ) ).
        processo:add( 'idVeiculo'               , b-processo-exp.veic-transp                    ).
        processo:add( 'numeroViagem'            , b-es-processo-exp.nr_viagem                   ).

        processos:add( processo ).

    end method.

    method public override character onLoadData( register as recid ).

        find first b-processo-exp no-lock
            where recid( b-processo-exp ) = register
            no-error.

        if not available b-processo-exp then
            this-object:errorHandler:throwError( 'onLoadData', 'Processo de exportacao nao encontrado.' ).

        if not can-find( b-proces-exp-adic of b-processo-exp ) then
            this-object:errorHandler:throwError( 'onLoadData',
                substitute( 'Dados adicionais nao encontrados para o processo &1/&2.',
                            b-processo-exp.cod-estabel,
                            b-processo-exp.nr-proc-exp ) ).

        find first b-es-processo-exp no-lock
            where b-es-processo-exp.cod_estabel = b-processo-exp.cod-estabel
              and b-es-processo-exp.nr_proc_exp = b-processo-exp.nr-proc-exp
            no-error.

        if not available b-es-processo-exp then
            this-object:errorHandler:throwError( 'onLoadData',
                substitute( 'Complemento (es_processo_exp) nao encontrado para o processo &1/&2.',
                            b-processo-exp.cod-estabel,
                            b-processo-exp.nr-proc-exp ) ).

        return substitute( '&1#&2', b-processo-exp.cod-estabel, b-processo-exp.nr-proc-exp ).

    end method.

end class.
