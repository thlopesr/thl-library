 
 /*------------------------------------------------------------------------
    File        : Message
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Thu Jul 01 08:25:57 BRT 2021
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-lib.erp.core.Service.
using thl-lib.erp.enum.ActionEnum.
using thl-lib.integration.messaging.inbound.core.Processor.
using thl-lib.integration.connectors.enum.MethodTypeEnum.
using thl-lib.integration.messaging.core.Message.
using thl-lib.integration.messaging.enum.DirectionEnum.
using thl-lib.integration.messaging.inbound.core.InboundObjectContext.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.
using thl-lib.util.string.StringUtil.

block-level on error undo, throw.

class thl-lib.integration.messaging.inbound.core.InboundMessage inherits Message.

    define protected property context    as InboundObjectContext  no-undo get. private set.

    //classes do cadastro do objeto (thl-objeto.classe-processor e classe-service),
    //informadas pelo InboundMessageService depois de criar a mensagem
    define private variable processorClass as character no-undo.
    define private variable serviceClass   as character no-undo.

    //contrato do payload cadastrado na operacao (thl-objeto-parametro-rest), em
    //array JSON de texto: campos obrigatorios e campos da chave externa
    define private variable requiredFieldsConfig    as character no-undo.
    define private variable externalReferenceConfig as character no-undo.

    //o item da mensagem (referencias) ja foi gravado por executeService
    define private variable referenceRegistered as logical no-undo.

    constructor public InboundMessage ( objectName           as character ,
                                        applicationName      as character ,
                                        integrationOperation as character ,
                                        methodType           as integer   ,
                                        connectorType        as integer   ,
                                        integrationDirection as logical   ,
                                        executionMode        as integer   ).
        super( objectName, applicationName, integrationOperation, methodType, connectorType, integrationDirection, executionMode).
    end constructor.
     
    method public void processInbound( context as InboundObjectContext ).
        assign this-object:context = context.
        this-object:dispatchInbound().
    end method.

    method public void dispatchInbound().

        case this-object:methodType.

            when MethodTypeEnum:POST:GetValue() then do.
                this-object:validate    ( context:payload ).
                this-object:methodpost  ().                
            end.
            when MethodTypeEnum:PATCH:GetValue() or
            when MethodTypeEnum:PUT:GetValue()   then do.
                this-object:validate    ( context:payload ).
                this-object:methodpatch ( ).
            end.
            when MethodTypeEnum:DELETE:GetValue() then  do.
                this-object:validate    ( context:payload ).
                this-object:methodDelete( ).
            end.
            when MethodTypeEnum:GET:GetValue() then do.
                this-object:methodGet( ).
            end.

            otherwise
                this-object:errorHandler:throwError( 'dispatchInbound',
                    substitute( 'Metodo inbound &1 nao suportado.',
                                this-object:methodType ) ).

        end case.

    end method.

    method protected void executeService( action as ActionEnum ).

        //antes do Service: a referencia externa vem do payload e, se o Service
        //falhar, ainda e gravada no item da mensagem (saveInboundError)
        assign this-object:externalReferenceCode = loadExternalReference( context:payload ).

        assign this-object:payload               = this-object:createProcessor():execute( action, context:operation, context:payload, referenceCode )
               this-object:externalReferenceCode = loadExternalReference( context:payload ).

        this-object:appendItem().

        assign referenceRegistered = true.

    end method.

    method protected void methodPost().
        this-object:executeService( ActionEnum:CRIADO ).
    end method.

    method protected void methodPatch().
        this-object:executeService( ActionEnum:ATUALIZADO ).
    end method.

    method protected void methodDelete().
        this-object:executeService( ActionEnum:DELETADO ).
    end method.

    //GET pelo execute do Processor, como os demais verbos: o Service le os filtros
    //da query e devolve o resultado. Message que sobrescreve continua valendo.
    method protected void methodGet().

        define variable queryResult as JsonObject no-undo.

        assign queryResult         = this-object:createProcessor():execute( ActionEnum:CONSULTADO, context:operation, context:queryParameters, referenceCode )
               this-object:payload = queryResult.

        this-object:registerQueryItems( queryResult ).

    end method.

    //Liga a mensagem aos registros consultados: um item para cada resultado que
    //traga referenceCode (montado pelo Service). Resultado sem referencia nao gera item.
    method private void registerQueryItems( input queryResult as JsonObject ).

        define variable resultItems as JsonArray no-undo.
        define variable itemIndex   as integer   no-undo.

        if not valid-object( queryResult ) then
            return.

        if queryResult:Has( 'items' ) and
           queryResult:GetType( 'items' ) = JsonDataType:ARRAY then do.

            assign resultItems = queryResult:GetJsonArray( 'items' ).

            do itemIndex = 1 to resultItems:Length.
                if resultItems:GetType( itemIndex ) = JsonDataType:OBJECT then
                    this-object:registerQueryItem( resultItems:GetJsonObject( itemIndex ) ).
            end.

            return.

        end.

        this-object:registerQueryItem( queryResult ).

    end method.

    method private void registerQueryItem( input resultItem as JsonObject ).

        if not resultItem:Has( 'referenceCode' ) or
           resultItem:GetType( 'referenceCode' ) <> JsonDataType:STRING then
            return.

        assign this-object:referenceCode         = resultItem:GetCharacter( 'referenceCode' )
               this-object:externalReferenceCode = loadExternalReference( resultItem ).

        if this-object:referenceCode = '' and this-object:externalReferenceCode = '' then
            return.

        this-object:appendItem().

    end method.
    
    method protected void validateRequiredFields( payload         as JsonObject,
                                                  requiredFields  as character ).

        define variable fieldName as character no-undo.
        define variable fieldIdx  as integer   no-undo.
    
        if requiredFields = ? then
            this-object:errorHandler:throwError( 'validateRequiredFields', 'getRequiredFields retornou ?.' ).

        if not StringUtil:hasValue( requiredFields ) then
            return.

        do fieldIdx = 1 to num-entries( requiredFields ).

            assign fieldName = trim( entry( fieldIdx, requiredFields ) ).

            if not payload:Has( fieldName ) then
                this-object:errorHandler:addError( 17006, substitute( 'InboundMessage: campo obrigatorio &1 nao foi informado.', fieldName ) ).

        end.

        this-object:errorHandler:throwIfHasErrors().

    end method.
    
    method protected void validatePayload( payload as JsonObject ).
        if not valid-object( payload ) then
            this-object:errorHandler:throwError( 'validatePayload', 'Payload JSON nao informado.' ).
    end method.
    
    method protected void validate( payload as JsonObject ).
        this-object:validatePayload       ( payload ).
        this-object:validateRequiredFields( payload, this-object:getRequiredFields() ).
    end method.
        
    method public void saveInboundSuccess( routePath as character ).
        repository:saveResultMessage   ( routePath, true,  true,  true, 200, 'Mensagem processada com sucesso.' ).
        repository:createHistoryMessage( ).
    end method.
    
    method public void saveInboundError( routePath   as character           ,
                                         errorObject as Progress.Lang.Error ).
        
        repository:loadMessage      ().

        //na opcao somente em erro, e aqui que a requisicao e o erro passam a ser gravados
        this-object:markFailed().

        //mensagem com erro tambem fica ligada ao registro: grava o item so com a
        //referencia externa (a interna so existe quando o Service conclui)
        if not referenceRegistered and this-object:externalReferenceCode <> '' then do.
            assign this-object:referenceCode = ''.
            this-object:appendItem().
            assign referenceRegistered = true.
        end.

        repository:saveResultMessage(
            routePath,
            true ,
            false,
            false,
            this-object:errorHandler:getErrorStatusCode(errorObject),
            this-object:errorHandler:getErrorMessage(errorObject)
        ).
        this-object:saveContentByType( 
            DirectionEnum:OUTBOUND:GetValue(), 
            this-object:errorHandler:getErrorJsonText(errorObject)
        ).
        repository:createHistoryMessage ( ).
    
    end method.
    
    //Hook: nome do campo do payload que carrega a referencia do sistema
    //externo. Default 'referenciaID'; subclasse sobrescreve o nome do
    //campo (caso comum) ou loadExternalReference inteiro (caso complexo).
    //Retornar '' desativa a referencia externa para o objeto.
    method protected character getExternalReferenceField().
        return 'externalID'.
    end method.

    method protected character loadExternalReference( context as JsonObject ).

        define variable fieldName as character no-undo.

        //chave externa cadastrada na operacao: [] desliga a referencia; em
        //branco vale o hook getExternalReferenceField
        if StringUtil:hasValue( externalReferenceConfig ) then
            return this-object:loadConfiguredReference( context ).

        assign fieldName = this-object:getExternalReferenceField().

        if fieldName <> '' and context:Has( fieldName ) then
            return context:GetCharacter( fieldName ).

        return ''.

    end method.
    
    method public void restoreForScheduledProcessing( messageCode as character ).
        repository:messageCode = messageCode.
        repository:loadMessage       ().
        repository:loadMessageContent( DirectionEnum:INBOUND:GetValue() ).
        this-object:loadPersistedPayload().
    end method.
    
    //Campos obrigatorios do payload: os do cadastro da operacao. Message
    //especifica que sobrescreve continua valendo.
    method protected character getRequiredFields().
        return JsonUtil:nameListToCsv( requiredFieldsConfig ).
    end method.

    //Referencia externa pelos campos cadastrados na operacao, na ordem da
    //chave, unidos por #. Chave composta so vale inteira: faltando um campo,
    //nao ha referencia.
    method private character loadConfiguredReference( context as JsonObject ).

        define variable fieldList as character no-undo.
        define variable fieldName as character no-undo.
        define variable fieldIdx  as integer   no-undo.
        define variable reference as character no-undo.

        if not valid-object( context ) then
            return ''.

        assign fieldList = JsonUtil:nameListToCsv( externalReferenceConfig ).

        do fieldIdx = 1 to num-entries( fieldList ).

            assign fieldName = entry( fieldIdx, fieldList ).

            if not context:Has( fieldName ) or context:IsNull( fieldName ) then
                return ''.

            assign reference = reference + ( if fieldIdx = 1 then '' else '#' )
                             + ( if context:GetType( fieldName ) = JsonDataType:STRING
                                 then context:GetCharacter( fieldName )
                                 else string( context:GetJsonText( fieldName ) ) ).

        end.

        return reference.

    end method.

    method protected PaginationHelper createPagination( input defaultPageSize as integer ).
        return new PaginationHelper(
            context:getQueryParamInt( 'pageSize', defaultPageSize ),
            context:getQueryParamInt( 'page'    , 1               )
        ).
    end method.

    //Contrato do payload cadastrado na operacao (arrays JSON de texto)
    method public void setContract( input requiredFields          as character ,
                                    input externalReferenceFields as character ).

        assign this-object:requiredFieldsConfig    = requiredFields
               this-object:externalReferenceConfig = externalReferenceFields.

    end method.

    //Classes de orquestracao e de service do objeto, vindas do cadastro
    method public void setProcessing( input processorClass as character ,
                                      input serviceClass   as character ).

        assign this-object:processorClass = processorClass
               this-object:serviceClass   = serviceClass.

    end method.

    //Message especifica que ainda escolhe o Service no codigo sobrescreve e devolve
    //a instancia; a padrao devolve ? e o Processor usa o Service do cadastro.
    method protected Service createService().
        return ?.
    end method.

    //Instancia a classe de orquestracao do objeto (thl-objeto.classe-processor) e
    //entrega a ela o Service: o da Message especifica, se houver, ou o do cadastro.
    method protected Processor createProcessor().

        define variable targetProcessor as Processor no-undo.
        define variable messageService  as Service   no-undo.
        define variable className       as character no-undo.

        //mensagem criada fora do InboundMessageService: vale a orquestracao padrao
        assign className = this-object:processorClass.

        //dynamic-new e instrucao propria: nao pode vir dentro de assign. A variavel e
        //do tipo Processor: classe que nao herda dele gera erro na atribuicao.
        targetProcessor = dynamic-new className ( ).

        if not valid-object( targetProcessor ) then
            this-object:errorHandler:throwError( 'createProcessor',
                substitute( 'Nao foi possivel instanciar o Processor: &1', className ) ).

        assign messageService = this-object:createService().

        targetProcessor:setServiceClass( this-object:serviceClass ).

        if valid-object( messageService ) then
            targetProcessor:setService( messageService ).

        return targetProcessor.

    end method.

end class.