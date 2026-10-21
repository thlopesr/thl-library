/*------------------------------------------------------------------------
    File        : ObjetoService
    Purpose     : Servico de dominio do cadastro de objetos de integracao
                  (thl-objeto, tela thl0021): criacao, atualizacao, exclusao e
                  listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : Padrao AmbienteService (thl-extensions.erp.thl.service).
                  Regras do Pi-validate da tela thl0021:
                  17006 para validacao, 2 para registro relacionado inexistente.
                  Chave (aplicacao, objeto) so e gravada na criacao.
                  2026-10-08: as classes do objeto sao o padrao das operacoes novas
                  (thl-objeto-parametro); ao alterar, as linhas que ainda tem a
                  classe antiga acompanham a mudanca.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.
using thl-lib.core.environment.EnvironmentResource.
using thl-extensions.erp.thl.enum.ClassVariableEnum.
using thl-extensions.erp.thl.enum.FieldDefaultEnum.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.ObjetoService inherits Service.

    define private buffer b-thl-objeto for thl-objeto.

    method public override character getEntityName().
        return 'Objeto de Integracao'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'aplicacao,objeto', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable applicationCode as character no-undo.
        define variable objectCode      as character no-undo.

        assign applicationCode = inContext:GetCharacter( 'aplicacao' )
               objectCode      = inContext:GetCharacter( 'objeto'    ).

        if not can-find( thl-aplicacao
                         where thl-aplicacao.aplicacao = applicationCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Aplicacao nao cadastrada.', 2 ).

        if objectCode = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Objeto nao informado. Informe o codigo do objeto de integracao.' ).

        if available b-thl-objeto then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Objeto ja cadastrado. Ja existe este objeto para a aplicacao.' ).

        do transaction.

            create b-thl-objeto.
            assign b-thl-objeto.aplicacao = applicationCode
                   b-thl-objeto.objeto    = objectCode.

            this-object:fillDefaultFields().
            this-object:mapFields( new JsonSetter( inContext ) ).
            this-object:fillDefaultClasses().
            this-object:validateRecord().

        end.

    end method.

    method public override void update().

        define variable oldMessage   as character no-undo.
        define variable oldProcessor as character no-undo.
        define variable oldService   as character no-undo.

        if not available b-thl-objeto then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Objeto nao localizado.' ).

        assign oldMessage   = b-thl-objeto.classe-objeto
               oldProcessor = b-thl-objeto.classe-processor
               oldService   = b-thl-objeto.classe-service.

        this-object:mapFields( new JsonSetter( inContext ) ).
        this-object:validateRecord().
        this-object:propagateClasses( oldMessage, oldProcessor, oldService ).

    end method.

    method public override void delete().

        if not available b-thl-objeto then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Objeto nao localizado.' ).

        //elimina tambem as operacoes (e a extensao REST), os usuarios e a rota do objeto; mensagens gravadas ficam
        do transaction.

            for each thl-objeto-parametro-rest exclusive-lock
                where thl-objeto-parametro-rest.aplicacao = b-thl-objeto.aplicacao and thl-objeto-parametro-rest.objeto = b-thl-objeto.objeto.
                delete thl-objeto-parametro-rest.
            end.

            for each thl-objeto-parametro exclusive-lock
                where thl-objeto-parametro.aplicacao = b-thl-objeto.aplicacao and thl-objeto-parametro.objeto = b-thl-objeto.objeto.
                delete thl-objeto-parametro.
            end.

            for each thl-objeto-usuario exclusive-lock
                where thl-objeto-usuario.aplicacao = b-thl-objeto.aplicacao and thl-objeto-usuario.objeto = b-thl-objeto.objeto.
                delete thl-objeto-usuario.
            end.

            for each thl-objeto-rota exclusive-lock
                where thl-objeto-rota.aplicacao = b-thl-objeto.aplicacao and thl-objeto-rota.objeto = b-thl-objeto.objeto.
                delete thl-objeto-rota.
            end.

            delete b-thl-objeto.

        end.

    end method.

    //Consulta (GET pelo execute): le os proprios filtros da query
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getPager( 100 ),
                                queryParameters:getText( 'aplicacaoIni', '' ),
                                queryParameters:getText( 'aplicacaoFin', fill( 'z', 100 ) ),
                                queryParameters:getText( 'objetoIni', '' ),
                                queryParameters:getText( 'objetoFin', fill( 'z', 60 ) ) ).
    end method.

    method public JsonArray get ( pager                as PaginationHelper ,
                                  applicationCodeStart as character        ,
                                  applicationCodeEnd   as character        ,
                                  objectCodeStart      as character        ,
                                  objectCodeEnd        as character        ).

        define variable recordItem as JsonObject no-undo.
        define variable recordList as JsonArray  no-undo.

        assign recordList = new JsonArray().

        for each b-thl-objeto no-lock
            where b-thl-objeto.aplicacao >= applicationCodeStart
              and b-thl-objeto.aplicacao <= applicationCodeEnd
              and b-thl-objeto.objeto    >= objectCodeStart
              and b-thl-objeto.objeto    <= objectCodeEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign recordItem = new JsonObject().

            recordItem:Add( 'aplicacao'       , b-thl-objeto.aplicacao ).
            recordItem:Add( 'objeto'          , b-thl-objeto.objeto ).
            recordItem:Add( 'classeObjeto'    , b-thl-objeto.classe-objeto ).
            recordItem:Add( 'classeProcessor' , b-thl-objeto.classe-processor ).
            recordItem:Add( 'classeService'   , b-thl-objeto.classe-service ).
            recordItem:Add( 'modeloIntegracao', b-thl-objeto.modelo-integracao ).
            recordItem:Add( 'sentidoFluxo'    , b-thl-objeto.sentido-fluxo ).
            recordItem:Add( 'indInativo'      , b-thl-objeto.ind-inativo ).
            recordItem:Add( 'indGeraHistorico', b-thl-objeto.ind-gera-historico ).
            recordItem:Add( 'programaConsulta', b-thl-objeto.programa-consulta ).
            recordItem:Add( 'retencaoDiasSucesso', b-thl-objeto.retencao-dias-sucesso ).
            recordItem:Add( 'retencaoDiasErro'   , b-thl-objeto.retencao-dias-erro    ).
            recordItem:Add( 'referenceCode'   , this-object:loadReferenceCode() ).

            recordList:Add( recordItem ).

        end.

        return recordList.

    end method.

    //so os campos fora da chave: a chave nao muda depois de criada
    method private void mapFields( input jsonSetter as JsonSetter ).
        jsonSetter:SetValue( input-output b-thl-objeto.classe-objeto     , input 'classeObjeto'     ).
        jsonSetter:SetValue( input-output b-thl-objeto.classe-processor  , input 'classeProcessor'  ).
        jsonSetter:SetValue( input-output b-thl-objeto.classe-service    , input 'classeService'    ).
        jsonSetter:SetValue( input-output b-thl-objeto.modelo-integracao , input 'modeloIntegracao' ).
        jsonSetter:SetValue( input-output b-thl-objeto.sentido-fluxo     , input 'sentidoFluxo'     ).
        jsonSetter:SetValue( input-output b-thl-objeto.ind-inativo       , input 'indInativo'       ).
        jsonSetter:SetValue( input-output b-thl-objeto.ind-gera-historico, input 'indGeraHistorico' ).
        jsonSetter:SetValue( input-output b-thl-objeto.programa-consulta , input 'programaConsulta' ).
        jsonSetter:SetValue( input-output b-thl-objeto.retencao-dias-sucesso, input 'retencaoDiasSucesso' ).
        jsonSetter:SetValue( input-output b-thl-objeto.retencao-dias-erro   , input 'retencaoDiasErro'    ).
    end method.

    //Criacao: os campos com padrao no thl0002 (FieldDefaultEnum) nascem com ele; o que vier no JSON
    //prevalece, porque mapFields roda depois. Sem o vinculo do programa a variavel e ignorada;
    //sem a variavel ou em branco vale o valor inicial do banco; valor invalido lanca ThlError.
    method private void fillDefaultFields().

        define variable environment as EnvironmentResource no-undo.

        assign environment = new EnvironmentResource() no-error.

        if not valid-object( environment ) then
            return.

        assign b-thl-objeto.ind-inativo            = environment:getEnvironmentVariable( FieldDefaultEnum:OBJETO_IND_INATIVO           , b-thl-objeto.ind-inativo            )
               b-thl-objeto.ind-gera-historico     = environment:getEnvironmentVariable( FieldDefaultEnum:OBJETO_IND_GERA_HISTORICO    , b-thl-objeto.ind-gera-historico     )
               b-thl-objeto.sentido-fluxo          = environment:getEnvironmentVariable( FieldDefaultEnum:OBJETO_SENTIDO_FLUXO         , b-thl-objeto.sentido-fluxo          )
               b-thl-objeto.modelo-integracao      = environment:getEnvironmentVariable( FieldDefaultEnum:OBJETO_MODELO_INTEGRACAO     , b-thl-objeto.modelo-integracao      )
               b-thl-objeto.retencao-dias-sucesso  = environment:getEnvironmentVariable( FieldDefaultEnum:OBJETO_RETENCAO_DIAS_SUCESSO , b-thl-objeto.retencao-dias-sucesso  )
               b-thl-objeto.retencao-dias-erro     = environment:getEnvironmentVariable( FieldDefaultEnum:OBJETO_RETENCAO_DIAS_ERRO    , b-thl-objeto.retencao-dias-erro     )
               b-thl-objeto.programa-consulta      = environment:getEnvironmentVariable( FieldDefaultEnum:OBJETO_PROGRAMA_CONSULTA     , b-thl-objeto.programa-consulta      ).

    end method.

    //Criacao: classe em branco recebe o padrao do thl0002 (parametro thl.classe, achado pelo programa
    //vinculado na aba Programa), como na tela thl0021: a mensagem (entrada ou saida) e, so na entrada,
    //processor e service. Sem o vinculo ou sem a variavel a classe segue em branco e a validacao recusa
    //(no-error: o EnvironmentResource lanca erro quando nenhum programa da pilha tem parametro).
    method private void fillDefaultClasses().

        define variable messageVariable as ClassVariableEnum no-undo.

        if b-thl-objeto.classe-objeto = '' then do.

            if b-thl-objeto.sentido-fluxo then
                assign messageVariable = ClassVariableEnum:MENSAGEM_SAIDA.
            else
                assign messageVariable = ClassVariableEnum:MENSAGEM_ENTRADA.

            assign b-thl-objeto.classe-objeto = new EnvironmentResource():getEnvironmentVariable( messageVariable ) no-error.

        end.

        if not b-thl-objeto.sentido-fluxo then do.

            if b-thl-objeto.classe-processor = '' then
                assign b-thl-objeto.classe-processor = new EnvironmentResource():getEnvironmentVariable( ClassVariableEnum:PROCESSOR_ENTRADA ) no-error.

            if b-thl-objeto.classe-service = '' then
                assign b-thl-objeto.classe-service = new EnvironmentResource():getEnvironmentVariable( ClassVariableEnum:SERVICE_ENTRADA ) no-error.

        end.

    end method.

    //regras do Pi-validate que valem na criacao e na alteracao; valida antes do commit
    method private void validateRecord().

        if b-thl-objeto.classe-objeto = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord', 'Classe nao informada. Informe o nome completo da classe da mensagem (ex.: thl-extensions.integration.<sistema>...).' ).

        //entrada (sentido-fluxo = no): mensagem, processor e service obrigatorios; saida: so a mensagem
        if not b-thl-objeto.sentido-fluxo then do.

            if b-thl-objeto.classe-processor = '' then
                undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord', 'Classe processor nao informada. Objeto de entrada: informe o nome completo da classe de orquestracao (padrao: thl-lib.integration.messaging.inbound.core.Processor).' ).

            if b-thl-objeto.classe-service = '' then
                undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord', 'Classe service nao informada. Objeto de entrada: informe o nome completo da classe do Service (ex.: thl-extensions.erp.<sistema>.service...).' ).

        end.

        //retencao do expurgo (thl0222): zero = nao expurga
        if b-thl-objeto.retencao-dias-sucesso < 0 or
           b-thl-objeto.retencao-dias-erro    < 0 then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord', 'Retencao invalida. Informe 0 (nao expurga) ou a quantidade de dias a manter.' ).

    end method.

    //As linhas de thl-objeto-parametro que ainda tem a classe antiga do objeto (ou em branco)
    //passam a ter a nova; linha personalizada na operacao (thl0022, aba Classe) fica como esta.
    method private void propagateClasses( input oldMessage   as character ,
                                          input oldProcessor as character ,
                                          input oldService   as character ).

        define buffer b-linha for thl-objeto-parametro.

        if b-thl-objeto.classe-objeto    = oldMessage   and
           b-thl-objeto.classe-processor = oldProcessor and
           b-thl-objeto.classe-service   = oldService   then
            return.

        do transaction.

            for each b-linha exclusive-lock
                where b-linha.aplicacao = b-thl-objeto.aplicacao
                  and b-linha.objeto    = b-thl-objeto.objeto.

                if b-linha.classe-objeto = oldMessage or b-linha.classe-objeto = '' then
                    assign b-linha.classe-objeto = b-thl-objeto.classe-objeto.

                if b-linha.classe-processor = oldProcessor or b-linha.classe-processor = '' then
                    assign b-linha.classe-processor = b-thl-objeto.classe-processor.

                if b-linha.classe-service = oldService or b-linha.classe-service = '' then
                    assign b-linha.classe-service = b-thl-objeto.classe-service.

            end.

        end.

    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-objeto then
            return substitute( '&1#&2', b-thl-objeto.aplicacao,
                                        b-thl-objeto.objeto ).
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-objeto exclusive-lock
            where b-thl-objeto.aplicacao = inContext:GetCharacter( 'aplicacao' )
              and b-thl-objeto.objeto    = inContext:GetCharacter( 'objeto'    )
            no-error.
    end method.

end class.
