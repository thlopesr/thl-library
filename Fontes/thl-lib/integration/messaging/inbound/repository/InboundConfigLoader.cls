/*------------------------------------------------------------------------
    File        : InboundConfigLoader
    Purpose     : Carrega a configuracao de uma mensagem de entrada: objeto,
                  operacao (pelo metodo recebido), extensao REST e as
                  classes de message, processor e service.
    Author(s)   : Lopes
    Created     : 2026-10-04
    Notes       : - O metodo da requisicao (POST, PUT, PATCH, DELETE, GET) e o
                    campo metodo da chave da operacao.
                  - Linha da operacao, nesta ordem:
                    1. operacao da URL + metodo (filho de agregado, metricas...);
                    2. operacao em branco + metodo: a linha do PAI, obrigatoria.
                       E ela que atende a operacao da URL sem linha propria e que
                       declara os metodos que o objeto aceita.
                    Sem a linha do pai, erro: nao ha busca pela primeira linha
                    do metodo nem pelo nome do verbo.
                  - Classes (message, processor e service): so as da linha. Elas
                    nascem copiadas de thl-objeto na criacao da linha (thl0022,
                    API objeto/parametro, cargas); a execucao nao le mais as
                    classes de thl-objeto. As tres precisam estar preenchidas.
                  - A operacao da URL, quando informada, e a que vai para a
                    configuracao e para a mensagem.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.integration.connectors.enum.MethodTypeEnum.
using thl-lib.integration.messaging.inbound.core.InboundMessageConfig.
using thl-lib.integration.messaging.repository.MessageConfigLoader.
using thl-lib.util.string.StringUtil.

block-level on error undo, throw.

class thl-lib.integration.messaging.inbound.repository.InboundConfigLoader inherits MessageConfigLoader.

    method public InboundMessageConfig load( applicationName as character ,
                                             objectName      as character ,
                                             methodType      as integer   ,
                                             operation       as character ).

        define variable configuration as InboundMessageConfig no-undo.

        this-object:findObject( applicationName, objectName ).

        if not available b-thl-objeto then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'load', substitute( 'Objeto para aplicacao &3 e objeto &1 nao encontrada.[thl-objeto]', objectName, methodType, applicationName ) ).

        this-object:findParameter( applicationName, objectName, methodType, operation ).

        if not available b-thl-objeto-parametro then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'load', substitute( 'Parametro para aplicacao &3, objeto &1, metodo &2 e operacao &4 nao encontrado. Cadastre a linha do objeto (operacao em branco) para o metodo no thl0022.[thl-objeto-parametro]', objectName, methodType, applicationName, operation ) ).

        if b-thl-objeto.ind-inativo           or
           b-thl-objeto-parametro.ind-inativo then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'load', substitute( 'Objeto &1 e/ou metodo &2 esta inativo.', objectName, methodType ) ).

        this-object:findRestExtension().
        this-object:ensureClasses().

        //o verbo e o da requisicao: a linha foi escolhida por ele
        assign configuration = new InboundMessageConfig( b-thl-objeto.objeto                      ,
                                                         b-thl-objeto.aplicacao                   ,
                                                         methodType                               ,
                                                         this-object:resolveMessageClass()        ,
                                                         b-thl-objeto.modelo-integracao           ,
                                                         b-thl-objeto.ind-gera-historico or b-thl-objeto-parametro.ind-gera-historico,
                                                         b-thl-objeto.sentido-fluxo               ,
                                                         b-thl-objeto-parametro.forma-execucao    ,
                                                         b-thl-objeto-parametro.ind-mensagem-simples,
                                                         b-thl-objeto-parametro.cod-param-ambiente  ,
                                                         b-thl-objeto-parametro.cod-param-ambiente-destino ,
                                                         ( if StringUtil:hasValue( operation ) then operation
                                                                                               else b-thl-objeto-parametro.operacao ),
                                                         b-thl-objeto-parametro.tipo-grava-conteudo ,
                                                         this-object:resolveProcessorClass()        ,
                                                         this-object:resolveServiceClass()          ).

        //contrato do payload, cadastrado na extensao REST da operacao
        if available b-thl-objeto-parametro-rest then
            configuration:setContract( b-thl-objeto-parametro-rest.campos-obrigatorios,
                                       b-thl-objeto-parametro-rest.chave-externa      ).

        return configuration.

    end method.

    //Linha da operacao pelo metodo da requisicao, que faz parte da chave: a da operacao
    //da URL e, sem ela, a do pai (operacao em branco). Sem nenhuma das duas, nao posiciona.
    method private void findParameter( input applicationName as character ,
                                       input objectName      as character ,
                                       input methodType      as integer   ,
                                       input operation       as character ).

        define variable methodEnum as MethodTypeEnum no-undo.

        release b-thl-objeto-parametro.

        //metodo fora do enum lanca erro aqui
        assign methodEnum = MethodTypeEnum:GetEnum( methodType ).

        if StringUtil:hasValue( operation ) then
            find first b-thl-objeto-parametro no-lock
                where b-thl-objeto-parametro.aplicacao = applicationName
                  and b-thl-objeto-parametro.objeto    = objectName
                  and b-thl-objeto-parametro.operacao  = operation
                  and b-thl-objeto-parametro.metodo    = methodType
                no-error.

        if available b-thl-objeto-parametro then
            return.

        find first b-thl-objeto-parametro no-lock
            where b-thl-objeto-parametro.aplicacao = applicationName
              and b-thl-objeto-parametro.objeto    = objectName
              and b-thl-objeto-parametro.operacao  = ''
              and b-thl-objeto-parametro.metodo    = methodType
            no-error.

    end method.

    //As tres classes precisam estar preenchidas na linha da operacao (thl0022, aba Classe)
    method private void ensureClasses().

        define variable missingClasses as character no-undo.

        if not StringUtil:hasValue( this-object:resolveMessageClass() ) then
            assign missingClasses = 'message'.

        if not StringUtil:hasValue( this-object:resolveProcessorClass() ) then
            assign missingClasses = missingClasses + ( if missingClasses = '' then '' else ', ' ) + 'processor'.

        if not StringUtil:hasValue( this-object:resolveServiceClass() ) then
            assign missingClasses = missingClasses + ( if missingClasses = '' then '' else ', ' ) + 'service'.

        if missingClasses <> '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'ensureClasses',
                substitute( 'Aplicacao &1 objeto &2 operacao &3 sem classe obrigatoria no cadastro &4.',
                            b-thl-objeto-parametro.aplicacao, b-thl-objeto-parametro.objeto,
                            b-thl-objeto-parametro.operacao, missingClasses ) ).

    end method.

end class.
