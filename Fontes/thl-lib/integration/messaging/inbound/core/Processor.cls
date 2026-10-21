
/*------------------------------------------------------------------------
    File        : Processor
    Purpose     : Orquestracao entre a Message e o Service. Recebe a acao
                  (criar, alterar, eliminar, consultar), escolhe o Service,
                  prepara, chama o verbo, pega a referencia e monta a resposta.
    Author(s)   : Lopes
    Created     : 2026-10-04
    Notes       : Classe concreta: atende o caso 1 para 1 com o Service do
                  cadastro do objeto (thl-objeto.classe-service).
                  Filhas atendem o caso 1 para N: sobrescrevem
                  resolveService() para escolher o Service pela operacao da
                  URL (pai e filhos de um agregado) ou execute() para
                  encadear varios Services.
                  A classe vem de thl-objeto.classe-processor (dynamic-new).
                  Um .p ou RPW pode usar o mesmo contrato:
                  new Processor():setServiceClass( ... ) + execute( ... ).
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.erp.enum.ActionEnum.

block-level on error undo, throw.

class thl-lib.integration.messaging.inbound.core.Processor.

    //nome completo da classe do Service do cadastro (thl-objeto.classe-service)
    define protected property serviceClass  as character no-undo get. private set.

    //Service ja escolhido por quem chama (Message que ainda sobrescreve createService)
    define protected property domainService as Service   no-undo get. private set.

    constructor public Processor ( ).
    end constructor.

    method public void setServiceClass( input serviceClass as character ).
        assign this-object:serviceClass = serviceClass.
    end method.

    method public void setService( input domainService as Service ).
        assign this-object:domainService = domainService.
    end method.

    method public JsonObject execute(  input action        as ActionEnum ,
                                       input operation     as character  ,
                                       input context       as JsonObject ,
                                      output referenceCode as character  ).

        define variable targetService as Service no-undo.

        if operation = ? then
            assign operation = ''.

        assign targetService = this-object:resolveService( operation ).

        if not valid-object( targetService ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'execute', 'Service nao foi resolvido para a operacao.' ).

        //As quatro acoes no mesmo lugar. A escrita prepara o Service (payload,
        //chave, registro posicionado) e chama o metodo da acao (invokeWrite); a
        //consulta le os parametros da query e nao passa pelo initialize().
        case action.

            when ActionEnum:CRIADO     or
            when ActionEnum:ATUALIZADO or
            when ActionEnum:DELETADO   then do.
                this-object:prepareWrite( targetService, operation, context ).
                this-object:invokeWrite( action, targetService, operation ).
            end.

            when ActionEnum:CONSULTADO then do.
                targetService:prepareQuery( operation, context ).
                assign referenceCode = ''.
                return targetService:buildQueryResponse( this-object:invokeQuery( targetService, operation ) ).
            end.

            otherwise
                undo, throw new ThlError( this-object:GetClass():TypeName, 'execute',
                    substitute( 'Acao nao suportada &1', action ) ).

        end case.

        assign referenceCode = targetService:loadReferenceCode().

        return targetService:buildResponse( action, referenceCode ).

    end method.

    //Preparo comum de criar, alterar e eliminar
    method private void prepareWrite( input targetService as Service    ,
                                      input operation     as character  ,
                                      input context       as JsonObject ).

        targetService:prepare( operation, context ).
        targetService:initialize().

    end method.

    //Chamada do Service na escrita: um metodo por acao (criar, alterar, eliminar).
    //Quem orquestra e o Processor: objeto em que a mesma acao tem varias operacoes
    //(ex.: nota fiscal, POST com geracao, XML, SEFAZ...) tem Processor proprio, que
    //sobrescreve este metodo e chama o metodo do Service de cada operacao.
    method protected void invokeWrite( input action        as ActionEnum ,
                                       input targetService as Service    ,
                                       input operation     as character  ).

        case action.
            when ActionEnum:CRIADO     then targetService:create().
            when ActionEnum:ATUALIZADO then targetService:update().
            when ActionEnum:DELETADO   then targetService:delete().
        end case.

    end method.

    //Chamada do Service na consulta: um metodo por acao. Processor de objeto com
    //mais de uma operacao de consulta (ex.: listagem e metricas) sobrescreve.
    method protected JsonConstruct invokeQuery( input targetService as Service   ,
                                                input operation     as character ).

        return targetService:consult().

    end method.

    //1 para 1: o Service informado por quem chama ou o do cadastro do objeto.
    //Filha de agregado sobrescreve e escolhe pela operacao; operacao que ela
    //nao conhece deve lancar erro, nunca cair no Service do pai.
    method protected Service resolveService( input operation as character ).

        if valid-object( this-object:domainService ) then
            return this-object:domainService.

        return this-object:createService( this-object:serviceClass ).

    end method.

    //Instancia um Service pelo nome completo (dynamic-new). A variavel e do tipo
    //Service: classe que nao herda de thl-lib.erp.core.Service gera erro na atribuicao.
    method protected Service createService( input className as character ).

        define variable instance as Service no-undo.

        if className = '' or className = ? then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'createService',
                'Classe do Service nao informada no cadastro do objeto (thl0021).' ).

        //dynamic-new e instrucao propria: nao pode vir dentro de assign
        instance = dynamic-new className ( ).

        if not valid-object( instance ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'createService',
                substitute( 'Nao foi possivel instanciar o Service: &1', className ) ).

        return instance.

    end method.

end class.
