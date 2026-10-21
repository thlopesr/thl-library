/*------------------------------------------------------------------------
    File        : ObjetoParametroService
    Purpose     : Servico de dominio do cadastro de operacoes do objeto de integracao
                  (thl-objeto-parametro, tela thl0022a) e da extensao REST da operacao
                  (thl-objeto-parametro-rest): criacao, atualizacao, exclusao e
                  listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : Padrao AmbienteService (thl-extensions.erp.thl.service).
                  Regras do Pi-validate da tela thl0022a:
                  17006 para validacao, 2 para registro relacionado inexistente.
                  Chave (cod-estabel, aplicacao, objeto, operacao, metodo) so e
                  gravada na criacao.
                  2026-10-05: classes por operacao; extensao REST.
                  2026-10-08: o metodo e o campo da chave (campo unico).
                  - Classes (classeObjeto, classeProcessor, classeService): em branco
                    na criacao ou na alteracao, copiam as do objeto (thl-objeto);
                    a execucao le so a linha.
                  - Metodo da operacao (REST: 1 POST, 2 PUT, 3 PATCH, 4 DELETE,
                    5 GET): propriedade metodo do JSON. Na alteracao e na
                    exclusao, sem ele, vale a unica linha da operacao (mais de
                    uma -> erro).
                  - Operacao e extensao sao um registro so para a API: mesmo JSON
                    e mesma transacao. A extensao e criada junto quando o objeto
                    e REST (thl-objeto.modelo-integracao = 1) e repete a chave.
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

class thl-extensions.erp.thl.service.ObjetoParametroService inherits Service.

    define private buffer b-thl-objeto-parametro      for thl-objeto-parametro.
    define private buffer b-thl-objeto-parametro-rest for thl-objeto-parametro-rest.

    //chave sem o metodo e operacao com mais de um metodo: nao da para saber qual linha
    define private variable ambiguousKey as logical no-undo.

    method public override character getEntityName().
        return 'Parametro do Objeto'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'estabelecimento,aplicacao,objeto,operacao', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable establishmentCode as character no-undo.
        define variable applicationCode   as character no-undo.
        define variable objectCode        as character no-undo.
        define variable operationCode     as character no-undo.
        define variable methodCode        as integer   no-undo.

        assign establishmentCode = inContext:GetCharacter( 'estabelecimento' )
               applicationCode   = inContext:GetCharacter( 'aplicacao'       )
               objectCode        = inContext:GetCharacter( 'objeto'          )
               operationCode     = inContext:GetCharacter( 'operacao'        )
               methodCode        = this-object:readMethod().

        if establishmentCode = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Estabelecimento nao informado. Informe o estabelecimento ou * para todos.' ).

        //estabelecimento deve existir no Datasul; '*' vale para todos
        if establishmentCode <> '*' and
           not can-find( estabelec
                         where estabelec.cod-estabel = establishmentCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Estabelecimento nao cadastrado.', 2 ).

        if not can-find( thl-objeto
                         where thl-objeto.aplicacao = applicationCode
                           and thl-objeto.objeto    = objectCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Objeto nao cadastrado.', 2 ).

        if methodCode < 1 or methodCode > 8 then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Metodo nao informado. Informe o metodo da operacao (REST: 1 POST, 2 PUT, 3 PATCH, 4 DELETE, 5 GET).' ).

        if can-find( thl-objeto-parametro
                     where thl-objeto-parametro.cod-estabel = establishmentCode
                       and thl-objeto-parametro.aplicacao   = applicationCode
                       and thl-objeto-parametro.objeto      = objectCode
                       and thl-objeto-parametro.operacao    = operationCode
                       and thl-objeto-parametro.metodo      = methodCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Operacao ja cadastrada. Ja existe esta operacao e metodo para o estabelecimento neste objeto.' ).

        do transaction.

            create b-thl-objeto-parametro.
            assign b-thl-objeto-parametro.cod-estabel = establishmentCode
                   b-thl-objeto-parametro.aplicacao   = applicationCode
                   b-thl-objeto-parametro.objeto      = objectCode
                   b-thl-objeto-parametro.operacao    = operationCode
                   b-thl-objeto-parametro.metodo      = methodCode.

            this-object:fillDefaultFields().
            this-object:mapFields( new JsonSetter( inContext ) ).
            this-object:validateRecord().
            this-object:saveRestExtension().

        end.

    end method.

    method public override void update().

        this-object:ensureUniqueKey().

        if not available b-thl-objeto-parametro then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Parametro do objeto nao localizado.' ).

        do transaction.

            this-object:mapFields( new JsonSetter( inContext ) ).
            this-object:validateRecord().
            this-object:saveRestExtension().

        end.

    end method.

    method public override void delete().

        this-object:ensureUniqueKey().

        if not available b-thl-objeto-parametro then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Parametro do objeto nao localizado.' ).

        do transaction.

            this-object:findRestExtension( true ).

            if available b-thl-objeto-parametro-rest then
                delete b-thl-objeto-parametro-rest.

            delete b-thl-objeto-parametro.

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

        for each b-thl-objeto-parametro no-lock
            where b-thl-objeto-parametro.aplicacao   >= applicationCodeStart
              and b-thl-objeto-parametro.aplicacao   <= applicationCodeEnd
              and b-thl-objeto-parametro.objeto      >= objectCodeStart
              and b-thl-objeto-parametro.objeto      <= objectCodeEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            this-object:findRestExtension( false ).

            assign recordItem = new JsonObject().

            recordItem:Add( 'estabelecimento'     , b-thl-objeto-parametro.cod-estabel ).
            recordItem:Add( 'aplicacao'           , b-thl-objeto-parametro.aplicacao ).
            recordItem:Add( 'objeto'              , b-thl-objeto-parametro.objeto ).
            recordItem:Add( 'operacao'            , b-thl-objeto-parametro.operacao ).
            recordItem:Add( 'metodo'              , b-thl-objeto-parametro.metodo ).
            recordItem:Add( 'formaExecucao'       , b-thl-objeto-parametro.forma-execucao ).
            recordItem:Add( 'indInativo'          , b-thl-objeto-parametro.ind-inativo ).
            recordItem:Add( 'indGeraHistorico'    , b-thl-objeto-parametro.ind-gera-historico ).
            recordItem:Add( 'indMensagemSimples'  , b-thl-objeto-parametro.ind-mensagem-simples ).
            recordItem:Add( 'paramAmbiente'       , b-thl-objeto-parametro.cod-param-ambiente ).
            recordItem:Add( 'paramAmbienteDestino', b-thl-objeto-parametro.cod-param-ambiente-destino ).
            recordItem:Add( 'indPersistente'      , b-thl-objeto-parametro.ind-persistente ).
            recordItem:Add( 'frequenciaExecucao'  , b-thl-objeto-parametro.frequencia-execucao ).
            recordItem:Add( 'servidorExecucao'    , b-thl-objeto-parametro.cod-servid-exec ).
            recordItem:Add( 'qtdTentativasPersist', b-thl-objeto-parametro.qtd-tentativas-persist ).
            recordItem:Add( 'qtdDiasPersist'      , b-thl-objeto-parametro.qtd-dias-persist ).
            recordItem:Add( 'tipoLogRequisicao'   , b-thl-objeto-parametro.tipo-log-requisicao ).
            recordItem:Add( 'tipoLogRetorno'      , b-thl-objeto-parametro.tipo-log-retorno ).
            recordItem:Add( 'tipoGravaConteudo'   , b-thl-objeto-parametro.tipo-grava-conteudo ).
            recordItem:Add( 'classeObjeto'        , b-thl-objeto-parametro.classe-objeto ).
            recordItem:Add( 'classeProcessor'     , b-thl-objeto-parametro.classe-processor ).
            recordItem:Add( 'classeService'       , b-thl-objeto-parametro.classe-service ).

            //extensao REST: listas em array; chaveExterna nula = padrao da mensagem
            recordItem:Add( 'camposObrigatorios', this-object:toNameArray( if available b-thl-objeto-parametro-rest
                                                                           then b-thl-objeto-parametro-rest.campos-obrigatorios
                                                                           else '' ) ).

            if available b-thl-objeto-parametro-rest         and
               b-thl-objeto-parametro-rest.chave-externa <> '' then
                recordItem:Add( 'chaveExterna', this-object:toNameArray( b-thl-objeto-parametro-rest.chave-externa ) ).
            else
                recordItem:AddNull( 'chaveExterna' ).

            recordItem:Add( 'referenceCode'       , this-object:loadReferenceCode() ).

            recordList:Add( recordItem ).

        end.

        return recordList.

    end method.

    //so os campos fora da chave: a chave nao muda depois de criada
    method private void mapFields( input jsonSetter as JsonSetter ).
        jsonSetter:SetValue( input-output b-thl-objeto-parametro.forma-execucao            , input 'formaExecucao'        ).
        jsonSetter:SetValue( input-output b-thl-objeto-parametro.ind-inativo               , input 'indInativo'           ).
        jsonSetter:SetValue( input-output b-thl-objeto-parametro.ind-gera-historico        , input 'indGeraHistorico'     ).
        jsonSetter:SetValue( input-output b-thl-objeto-parametro.ind-mensagem-simples      , input 'indMensagemSimples'   ).
        jsonSetter:SetValue( input-output b-thl-objeto-parametro.cod-param-ambiente        , input 'paramAmbiente'        ).
        jsonSetter:SetValue( input-output b-thl-objeto-parametro.cod-param-ambiente-destino, input 'paramAmbienteDestino' ).
        jsonSetter:SetValue( input-output b-thl-objeto-parametro.ind-persistente           , input 'indPersistente'       ).
        jsonSetter:SetValue( input-output b-thl-objeto-parametro.frequencia-execucao       , input 'frequenciaExecucao'   ).
        jsonSetter:SetValue( input-output b-thl-objeto-parametro.cod-servid-exec           , input 'servidorExecucao'     ).
        jsonSetter:SetValue( input-output b-thl-objeto-parametro.qtd-tentativas-persist    , input 'qtdTentativasPersist' ).
        jsonSetter:SetValue( input-output b-thl-objeto-parametro.qtd-dias-persist          , input 'qtdDiasPersist'       ).
        jsonSetter:SetValue( input-output b-thl-objeto-parametro.tipo-log-requisicao       , input 'tipoLogRequisicao'    ).
        jsonSetter:SetValue( input-output b-thl-objeto-parametro.tipo-log-retorno          , input 'tipoLogRetorno'       ).
        jsonSetter:SetValue( input-output b-thl-objeto-parametro.tipo-grava-conteudo       , input 'tipoGravaConteudo'    ).
        jsonSetter:SetValue( input-output b-thl-objeto-parametro.classe-objeto             , input 'classeObjeto'         ).
        jsonSetter:SetValue( input-output b-thl-objeto-parametro.classe-processor          , input 'classeProcessor'      ).
        jsonSetter:SetValue( input-output b-thl-objeto-parametro.classe-service            , input 'classeService'        ).
    end method.

    //regras que valem na criacao e na alteracao; valida antes do commit
    method private void validateRecord().

        //servidor de execucao so vale em operacao Batch ou Agendar, como na aba Servidor do thl0022:
        //em operacao Online (forma de execucao 1), servidor informado e recusado
        if b-thl-objeto-parametro.forma-execucao = 1 and
           b-thl-objeto-parametro.cod-servid-exec <> '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord',
                'Servidor de execucao so vale em operacao Batch ou Agendar. Operacao Online (formaExecucao 1): nao informe servidorExecucao.' ).

        //persistencia (reenvio) so vale em operacao de saida, como na aba Persistencia do thl0022:
        //em objeto de entrada, valor informado diferente de falso ou zero e recusado
        if not can-find( thl-objeto
                         where thl-objeto.aplicacao     = b-thl-objeto-parametro.aplicacao
                           and thl-objeto.objeto        = b-thl-objeto-parametro.objeto
                           and thl-objeto.sentido-fluxo = yes )
           and this-object:hasPersistenceInput() then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord',
                'Persistencia so vale em operacao de saida. Objeto de entrada: nao informe indPersistente, frequenciaExecucao, qtdDiasPersist nem qtdTentativasPersist.' ).

        this-object:fillClassesFromObject().

        if b-thl-objeto-parametro.classe-objeto = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord', 'Classe nao informada. Informe o nome completo da classe da mensagem da operacao.' ).

        //entrada: processor e service tambem obrigatorios; saida (sentido-fluxo = yes): so a mensagem
        if not can-find( thl-objeto
                         where thl-objeto.aplicacao    = b-thl-objeto-parametro.aplicacao
                           and thl-objeto.objeto       = b-thl-objeto-parametro.objeto
                           and thl-objeto.sentido-fluxo = yes ) then do.

            if b-thl-objeto-parametro.classe-processor = '' then
                undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord', 'Classe processor nao informada. Operacao de entrada: informe o nome completo da classe de orquestracao.' ).

            if b-thl-objeto-parametro.classe-service = '' then
                undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord', 'Classe service nao informada. Operacao de entrada: informe o nome completo da classe do Service.' ).

        end.

        //dominio do ContentStorageEnum (thl/include/i05thl011.i)
        if b-thl-objeto-parametro.tipo-grava-conteudo < 1 or
           b-thl-objeto-parametro.tipo-grava-conteudo > 3 then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord', 'Gravacao de conteudo invalida. Informe 1 (sempre), 2 (somente em erro) ou 3 (nunca).' ).

    end method.

    //Criacao: os campos com padrao no thl0002 (FieldDefaultEnum) nascem com ele; o que vier no JSON
    //prevalece, porque mapFields roda depois. O metodo e a chave e nao tem padrao aqui. Sem o vinculo do
    //programa a variavel e ignorada; sem a variavel ou em branco vale o valor inicial do banco; valor
    //invalido lanca ThlError.
    method private void fillDefaultFields().

        define variable environment as EnvironmentResource no-undo.

        assign environment = new EnvironmentResource() no-error.

        if not valid-object( environment ) then
            return.

        assign b-thl-objeto-parametro.ind-inativo             = environment:getEnvironmentVariable( FieldDefaultEnum:OPERACAO_IND_INATIVO         , b-thl-objeto-parametro.ind-inativo             )
               b-thl-objeto-parametro.ind-gera-historico      = environment:getEnvironmentVariable( FieldDefaultEnum:OPERACAO_IND_GERA_HISTORICO  , b-thl-objeto-parametro.ind-gera-historico      )
               b-thl-objeto-parametro.tipo-grava-conteudo     = environment:getEnvironmentVariable( FieldDefaultEnum:OPERACAO_TIPO_GRAVA_CONTEUDO , b-thl-objeto-parametro.tipo-grava-conteudo     )
               b-thl-objeto-parametro.forma-execucao          = environment:getEnvironmentVariable( FieldDefaultEnum:OPERACAO_FORMA_EXECUCAO      , b-thl-objeto-parametro.forma-execucao          )
               b-thl-objeto-parametro.ind-persistente         = environment:getEnvironmentVariable( FieldDefaultEnum:OPERACAO_IND_PERSISTENTE     , b-thl-objeto-parametro.ind-persistente         )
               b-thl-objeto-parametro.frequencia-execucao     = environment:getEnvironmentVariable( FieldDefaultEnum:OPERACAO_FREQUENCIA_EXECUCAO , b-thl-objeto-parametro.frequencia-execucao     )
               b-thl-objeto-parametro.qtd-dias-persist        = environment:getEnvironmentVariable( FieldDefaultEnum:OPERACAO_DIAS_PERSIST        , b-thl-objeto-parametro.qtd-dias-persist        )
               b-thl-objeto-parametro.qtd-tentativas-persist  = environment:getEnvironmentVariable( FieldDefaultEnum:OPERACAO_TENTATIVAS_PERSIST  , b-thl-objeto-parametro.qtd-tentativas-persist  )
               b-thl-objeto-parametro.tipo-log-requisicao     = environment:getEnvironmentVariable( FieldDefaultEnum:OPERACAO_TIPO_LOG_REQUISICAO , b-thl-objeto-parametro.tipo-log-requisicao     )
               b-thl-objeto-parametro.tipo-log-retorno        = environment:getEnvironmentVariable( FieldDefaultEnum:OPERACAO_TIPO_LOG_RETORNO    , b-thl-objeto-parametro.tipo-log-retorno        )
               b-thl-objeto-parametro.ind-mensagem-simples    = environment:getEnvironmentVariable( FieldDefaultEnum:OPERACAO_IND_MENSAGEM_SIMPLES, b-thl-objeto-parametro.ind-mensagem-simples    )
               b-thl-objeto-parametro.cod-param-ambiente         = environment:getEnvironmentVariable( FieldDefaultEnum:OPERACAO_PARAM_AMBIENTE     , b-thl-objeto-parametro.cod-param-ambiente         )
               b-thl-objeto-parametro.cod-param-ambiente-destino = environment:getEnvironmentVariable( FieldDefaultEnum:OPERACAO_PARAM_AMB_DESTINO  , b-thl-objeto-parametro.cod-param-ambiente-destino )
               b-thl-objeto-parametro.cod-servid-exec            = environment:getEnvironmentVariable( FieldDefaultEnum:OPERACAO_SERVIDOR_EXECUCAO  , b-thl-objeto-parametro.cod-servid-exec            ).

    end method.

    //Classes da operacao: as informadas no JSON; em branco, copia as do objeto (thl-objeto);
    //ainda em branco (objeto sem a classe), o padrao do thl0002, como na criacao do objeto.
    //A execucao le so a linha da operacao, nunca o objeto.
    method private void fillClassesFromObject().

        define variable messageVariable as ClassVariableEnum no-undo.

        find first thl-objeto no-lock
            where thl-objeto.aplicacao = b-thl-objeto-parametro.aplicacao
              and thl-objeto.objeto    = b-thl-objeto-parametro.objeto
            no-error.

        if not available thl-objeto then
            return.

        if b-thl-objeto-parametro.classe-objeto = '' then
            assign b-thl-objeto-parametro.classe-objeto = thl-objeto.classe-objeto.

        if b-thl-objeto-parametro.classe-processor = '' then
            assign b-thl-objeto-parametro.classe-processor = thl-objeto.classe-processor.

        if b-thl-objeto-parametro.classe-service = '' then
            assign b-thl-objeto-parametro.classe-service = thl-objeto.classe-service.

        //padrao do thl0002 (parametro thl.classe, achado pelo programa vinculado): a mensagem
        //(entrada ou saida) e, so na entrada, processor e service. Sem o vinculo ou sem a variavel
        //a classe segue em branco e a validacao recusa (no-error: o EnvironmentResource lanca erro
        //quando nenhum programa da pilha tem parametro).
        if b-thl-objeto-parametro.classe-objeto = '' then do.

            if thl-objeto.sentido-fluxo then
                assign messageVariable = ClassVariableEnum:MENSAGEM_SAIDA.
            else
                assign messageVariable = ClassVariableEnum:MENSAGEM_ENTRADA.

            assign b-thl-objeto-parametro.classe-objeto = new EnvironmentResource():getEnvironmentVariable( messageVariable ) no-error.

        end.

        if not thl-objeto.sentido-fluxo then do.

            if b-thl-objeto-parametro.classe-processor = '' then
                assign b-thl-objeto-parametro.classe-processor = new EnvironmentResource():getEnvironmentVariable( ClassVariableEnum:PROCESSOR_ENTRADA ) no-error.

            if b-thl-objeto-parametro.classe-service = '' then
                assign b-thl-objeto-parametro.classe-service = new EnvironmentResource():getEnvironmentVariable( ClassVariableEnum:SERVICE_ENTRADA ) no-error.

        end.

    end method.

    //Extensao REST da operacao: criada junto, na mesma transacao, quando o objeto e REST.
    //O contrato do payload (camposObrigatorios e chaveExterna) so vale na entrada, como na aba REST
    //do thl0022: em objeto de saida a extensao nasce sem contrato, lista preenchida e recusada e
    //lista vazia ou nula e ignorada.
    method private void saveRestExtension().

        define variable isOutput as logical no-undo.

        if not can-find( thl-objeto
                         where thl-objeto.aplicacao         = b-thl-objeto-parametro.aplicacao
                           and thl-objeto.objeto            = b-thl-objeto-parametro.objeto
                           and thl-objeto.modelo-integracao = 1 ) then
            return.

        assign isOutput = can-find( thl-objeto
                                    where thl-objeto.aplicacao     = b-thl-objeto-parametro.aplicacao
                                      and thl-objeto.objeto        = b-thl-objeto-parametro.objeto
                                      and thl-objeto.sentido-fluxo = yes ).

        if isOutput and ( this-object:hasContractValue( 'camposObrigatorios' ) or
                          this-object:hasContractValue( 'chaveExterna'       ) ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'saveRestExtension',
                'Contrato do payload so vale em operacao de entrada. Objeto de saida: nao informe camposObrigatorios nem chaveExterna.' ).

        this-object:findRestExtension( true ).

        if not available b-thl-objeto-parametro-rest then do.
            create b-thl-objeto-parametro-rest.
            assign b-thl-objeto-parametro-rest.cod-estabel = b-thl-objeto-parametro.cod-estabel
                   b-thl-objeto-parametro-rest.aplicacao   = b-thl-objeto-parametro.aplicacao
                   b-thl-objeto-parametro-rest.objeto      = b-thl-objeto-parametro.objeto
                   b-thl-objeto-parametro-rest.operacao    = b-thl-objeto-parametro.operacao
                   b-thl-objeto-parametro-rest.metodo      = b-thl-objeto-parametro.metodo.
        end.

        if isOutput then
            return.

        if inContext:Has( 'camposObrigatorios' ) then
            assign b-thl-objeto-parametro-rest.campos-obrigatorios = this-object:readNameList( 'camposObrigatorios' ).

        if inContext:Has( 'chaveExterna' ) then
            assign b-thl-objeto-parametro-rest.chave-externa = this-object:readNameList( 'chaveExterna' ).

    end method.

    //O JSON de entrada traz algum campo de persistencia com valor diferente de falso ou zero
    //(ausente, nulo, false e 0 nao contam)
    method private logical hasPersistenceInput().

        define variable jsonSetter as JsonSetter no-undo.
        define variable persistentValue as logical    no-undo initial false.
        define variable frequency  as integer    no-undo initial 0.
        define variable days       as integer    no-undo initial 0.
        define variable attempts   as integer    no-undo initial 0.

        assign jsonSetter = new JsonSetter( inContext ).

        jsonSetter:SetValue( input-output persistentValue, input 'indPersistente'       ).
        jsonSetter:SetValue( input-output frequency , input 'frequenciaExecucao'   ).
        jsonSetter:SetValue( input-output days      , input 'qtdDiasPersist'       ).
        jsonSetter:SetValue( input-output attempts  , input 'qtdTentativasPersist' ).

        return persistentValue = true                       or
               ( frequency <> ? and frequency <> 0 )   or
               ( days      <> ? and days      <> 0 )   or
               ( attempts  <> ? and attempts  <> 0 ).

    end method.

    //A propriedade veio com pelo menos um nome na lista (nula, ausente e [] nao contam)
    method private logical hasContractValue( input propertyName as character ).

        define variable listText as character no-undo.

        if not inContext:Has( propertyName ) then
            return false.

        assign listText = this-object:readNameList( propertyName ).

        if listText = '' then
            return false.

        return JsonUtil:nameListToCsv( listText ) <> ''.

    end method.

    //Lista de nomes do JSON de entrada: array de texto (ou o mesmo array em
    //texto); nulo = em branco. Devolve o texto gravado no cadastro.
    method private character readNameList( input propertyName as character ).

        define variable listText as character no-undo.

        if inContext:IsNull( propertyName ) then
            return ''.

        case inContext:GetType( propertyName ).
            when JsonDataType:ARRAY  then assign listText = string( inContext:GetJsonArray( propertyName ):GetJsonText() ).
            when JsonDataType:STRING then assign listText = trim( inContext:GetCharacter( propertyName ) ).
            otherwise
                undo, throw new ThlError( this-object:GetClass():TypeName, 'readNameList',
                    substitute( '&1 invalido. Informe um array JSON de texto.', propertyName ) ).
        end case.

        //confere o formato; lanca erro se nao for um array de nomes
        JsonUtil:nameListToCsv( listText ).

        return listText.

    end method.

    //Texto do cadastro -> array para a resposta; em branco vira array vazio
    method private JsonArray toNameArray( input listText as character ).

        define variable nameList as JsonArray no-undo.
        define variable csv      as character no-undo.
        define variable nameIdx  as integer   no-undo.

        assign nameList = new JsonArray()
               csv      = JsonUtil:nameListToCsv( listText ).

        do nameIdx = 1 to num-entries( csv ).
            nameList:Add( entry( nameIdx, csv ) ).
        end.

        return nameList.

    end method.

    //Metodo da operacao no JSON; zero = nao informado
    method private integer readMethod().

        if not inContext:Has( 'metodo' ) or inContext:IsNull( 'metodo' ) then
            return 0.

        return inContext:GetInteger( 'metodo' ).

    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-objeto-parametro then
            return substitute( '&1#&2#&3#&4#&5', b-thl-objeto-parametro.cod-estabel,
                                                 b-thl-objeto-parametro.aplicacao,
                                                 b-thl-objeto-parametro.objeto,
                                                 b-thl-objeto-parametro.operacao,
                                                 b-thl-objeto-parametro.metodo ).
        return ''.
    end method.

    //Com o metodo no JSON, a chave e completa. Sem ele, vale a unica linha da
    //operacao; havendo mais de um metodo, a chave e ambigua.
    method private void positionRecord().

        define buffer b-other for thl-objeto-parametro.

        if inContext:Has( 'metodo' ) and not inContext:IsNull( 'metodo' ) then do.

            find first b-thl-objeto-parametro exclusive-lock
                where b-thl-objeto-parametro.cod-estabel = inContext:GetCharacter( 'estabelecimento' )
                  and b-thl-objeto-parametro.aplicacao   = inContext:GetCharacter( 'aplicacao'       )
                  and b-thl-objeto-parametro.objeto      = inContext:GetCharacter( 'objeto'          )
                  and b-thl-objeto-parametro.operacao    = inContext:GetCharacter( 'operacao'        )
                  and b-thl-objeto-parametro.metodo      = inContext:GetInteger  ( 'metodo'          )
                no-error.

            return.

        end.

        find first b-thl-objeto-parametro exclusive-lock
            where b-thl-objeto-parametro.cod-estabel = inContext:GetCharacter( 'estabelecimento' )
              and b-thl-objeto-parametro.aplicacao   = inContext:GetCharacter( 'aplicacao'       )
              and b-thl-objeto-parametro.objeto      = inContext:GetCharacter( 'objeto'          )
              and b-thl-objeto-parametro.operacao    = inContext:GetCharacter( 'operacao'        )
            no-error.

        if available b-thl-objeto-parametro and
           can-find( first b-other
                     where b-other.cod-estabel = b-thl-objeto-parametro.cod-estabel
                       and b-other.aplicacao   = b-thl-objeto-parametro.aplicacao
                       and b-other.objeto      = b-thl-objeto-parametro.objeto
                       and b-other.operacao    = b-thl-objeto-parametro.operacao
                       and b-other.metodo     <> b-thl-objeto-parametro.metodo ) then do.

            //a criacao confere a propria chave; alteracao e exclusao precisam do metodo
            release b-thl-objeto-parametro.

            assign ambiguousKey = true.

        end.

    end method.

    method private void ensureUniqueKey().

        if ambiguousKey then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'ensureUniqueKey',
                'Operacao com mais de um metodo. Informe o metodo da linha.' ).

    end method.

    //Extensao REST da operacao posicionada
    method private void findRestExtension( input forUpdate as logical ).

        if forUpdate then
            find first b-thl-objeto-parametro-rest exclusive-lock
                where b-thl-objeto-parametro-rest.cod-estabel = b-thl-objeto-parametro.cod-estabel
                  and b-thl-objeto-parametro-rest.aplicacao   = b-thl-objeto-parametro.aplicacao
                  and b-thl-objeto-parametro-rest.objeto      = b-thl-objeto-parametro.objeto
                  and b-thl-objeto-parametro-rest.operacao    = b-thl-objeto-parametro.operacao
                  and b-thl-objeto-parametro-rest.metodo      = b-thl-objeto-parametro.metodo
                no-error.
        else
            find first b-thl-objeto-parametro-rest no-lock
                where b-thl-objeto-parametro-rest.cod-estabel = b-thl-objeto-parametro.cod-estabel
                  and b-thl-objeto-parametro-rest.aplicacao   = b-thl-objeto-parametro.aplicacao
                  and b-thl-objeto-parametro-rest.objeto      = b-thl-objeto-parametro.objeto
                  and b-thl-objeto-parametro-rest.operacao    = b-thl-objeto-parametro.operacao
                  and b-thl-objeto-parametro-rest.metodo      = b-thl-objeto-parametro.metodo
                no-error.

    end method.

end class.
