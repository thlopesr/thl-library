 
 /*------------------------------------------------------------------------
    File        : MessageRepository
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Sat Mar 07 08:34:45 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.util.string.StringUtil.
using thl-lib.core.error.ThlError.
using thl-lib.logging.LogUtil.
using thl-lib.integration.messaging.enum.MessageStatusEnum.

block-level on error undo, throw.

class thl-lib.integration.messaging.repository.MessageRepository.  

    define protected buffer b-thl-mensagem           for thl-mensagem.
    define protected buffer b-thl-mensagem-historico for thl-mensagem-historico.
    define protected buffer b-thl-mensagem-item      for thl-mensagem-item.
    define protected buffer b-thl-mensagem-conteudo  for thl-mensagem-conteudo.
    
    define public property messageCode           as character no-undo get. set.
    define public property referenceCode         as character no-undo get. set.
    define public property objectName            as character no-undo get. set.
    define public property applicationName       as character no-undo get. set.
    define public property externalReferenceCode as character no-undo get. set.
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    method public void generateMessageCode().
        assign this-object:messageCode = guid( generate-uuid ).
    end method.

    //Metodos relacionado a tabela thl-mensagem    
    method public void createMessage( objectName           as character ,
                                      applicationName      as character ,
                                      integrationOperation as character ,
                                      methodType           as integer   ,
                                      connectorType        as integer   ,
                                      integrationDirection as logical   ,
                                      executionMode        as integer   ).

        this-object:ensureMessageCode().

        create b-thl-mensagem.
        assign b-thl-mensagem.codigo-mensagem   = this-object:messageCode
               b-thl-mensagem.dt-criacao        = now
               b-thl-mensagem.objeto            = objectName
               b-thl-mensagem.aplicacao         = applicationName
               b-thl-mensagem.operacao          = integrationOperation
               b-thl-mensagem.metodo            = methodType
               b-thl-mensagem.forma-execucao    = executionMode
               b-thl-mensagem.modelo-integracao = connectorType
               b-thl-mensagem.qtd-tentativas    = 0
               b-thl-mensagem.sentido-fluxo     = integrationDirection
               b-thl-mensagem.sit-processamento = MessageStatusEnum:PENDING:getValue()
               b-thl-mensagem.sit-requisicao    = MessageStatusEnum:PENDING:getValue()
               b-thl-mensagem.sit-retorno       = MessageStatusEnum:PENDING:getValue()
               b-thl-mensagem.sit-mensagem      = MessageStatusEnum:PENDING:getValue()
               .

        assign this-object:objectName      = objectName
               this-object:applicationName = applicationName.

    end method.
    
    method public void loadMessage().
        this-object:ensureMessageCode().

        find first b-thl-mensagem exclusive-lock
            where b-thl-mensagem.codigo-mensagem = this-object:messageCode
            no-wait no-error.

        if not available b-thl-mensagem then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'loadMessage',
                substitute( 'Mensagem &1 nao encontrada ou esta bloqueada por outra sessao.', this-object:messageCode ) ).
    end method.
    
    method public void saveResultMessage( destination     as character,
                                          successRequest  as logical  ,  
                                          successResponse as logical  ,
                                          successProcess  as logical  ,
                                          statusCode      as integer  ,
                                          statusMessage   as character).
        
        assign b-thl-mensagem.destino            = if length( destination ) > 200 then substring(destination, 1 , 200) else destination
               b-thl-mensagem.dt-integracao      = now
               b-thl-mensagem.qtd-tentativas     = b-thl-mensagem.qtd-tentativas + 1
               b-thl-mensagem.sit-processamento  = if successProcess  = ? then MessageStatusEnum:NOT_APPLICABLE:getValue() else if successProcess  then MessageStatusEnum:SUCCESS:getValue() else MessageStatusEnum:ERROR:getValue()
               b-thl-mensagem.sit-requisicao     = if successRequest  = ? then MessageStatusEnum:NOT_APPLICABLE:getValue() else if successRequest  then MessageStatusEnum:SUCCESS:getValue() else MessageStatusEnum:ERROR:getValue()
               b-thl-mensagem.sit-retorno        = if successResponse = ? then MessageStatusEnum:NOT_APPLICABLE:getValue() else if successResponse then MessageStatusEnum:SUCCESS:getValue() else MessageStatusEnum:ERROR:getValue()
               b-thl-mensagem.cod-status-retorno = statusCode
               b-thl-mensagem.descr-retorno      = if length (statusMessage) > 200 then substring( statusMessage, 1, 200)
                                                                                   else statusMessage
               .

        //depois das tres fases gravadas: a situacao geral e derivada delas
        assign b-thl-mensagem.sit-mensagem = this-object:resolveOverallStatus():getValue().

    end method.

    //Agendamento aceito: as fases ficam como aceitas, mas a mensagem so
    //conclui quando o RPW executar e gravar o resultado de verdade.
    method public void markMessagePending().
        assign b-thl-mensagem.sit-mensagem = MessageStatusEnum:PENDING:getValue().
    end method.

    //Situacao geral (thl-mensagem.sit-mensagem) a partir das tres fases:
    //alguma em erro -> Erro; senao, alguma pendente -> Pendente; todas em
    //sucesso ou nao aplicavel -> Sucesso.
    method private MessageStatusEnum resolveOverallStatus().

        if b-thl-mensagem.sit-requisicao    = MessageStatusEnum:ERROR:getValue() or
           b-thl-mensagem.sit-processamento = MessageStatusEnum:ERROR:getValue() or
           b-thl-mensagem.sit-retorno       = MessageStatusEnum:ERROR:getValue() then
            return MessageStatusEnum:ERROR.

        if b-thl-mensagem.sit-requisicao    = MessageStatusEnum:PENDING:getValue() or
           b-thl-mensagem.sit-processamento = MessageStatusEnum:PENDING:getValue() or
           b-thl-mensagem.sit-retorno       = MessageStatusEnum:PENDING:getValue() then
            return MessageStatusEnum:PENDING.

        return MessageStatusEnum:SUCCESS.

    end method.
    
    //Metodos relacionado a tabela thl-mensagem-historico
    method public void createHistoryMessage().
        
        this-object:ensureMessageCode().

        create b-thl-mensagem-historico.
        buffer-copy b-thl-mensagem to b-thl-mensagem-historico
            assign b-thl-mensagem-historico.tentativa = b-thl-mensagem.qtd-tentativas.

    end method.
    
    //Metodos relacionado a tabela thl-mensagem-item
    method public void createItemMessage().
        
        this-object:ensureMessageCode().
        this-object:ensureReferenceCode().

        create b-thl-mensagem-item.
        assign b-thl-mensagem-item.codigo-mensagem     = this-object:messageCode
               b-thl-mensagem-item.chave-registro      = this-object:referenceCode
               b-thl-mensagem-item.chave-registro-ext  = this-object:ExternalReferenceCode.

    end method.
    
    method public logical hasExistingMessageItemForReference().
        return available b-thl-mensagem-item.
    end method.    

    method public void loadMessageItemByReference( objectName      as character ,
                                                   applicationName as character ).

        this-object:ensureReferenceCode().

        find first b-thl-mensagem-item exclusive-lock
            where b-thl-mensagem-item.chave-registro = this-object:referenceCode
              and can-find( first thl-mensagem of b-thl-mensagem-item
                                where thl-mensagem.objeto    = objectName
                                  and thl-mensagem.aplicacao = applicationName ) no-error.

    end method.
    
    method public void loadMessageCodeFromItem().
        assign this-object:messageCode = b-thl-mensagem-item.codigo-mensagem.
    end method.
    
    //Metodos relacionado a tabela thl-mensagem-conteudo
    method public void createMessageContent( typeContent as int64 ).
        
        this-object:ensureMessageCode().

        create b-thl-mensagem-conteudo.
        assign b-thl-mensagem-conteudo.codigo-mensagem = this-object:messageCode
               b-thl-mensagem-conteudo.tipo-conteudo   = typeContent.

    end method.

    method public logical hasExistingMessageContentForObject().
        return available b-thl-mensagem-conteudo.
    end method.

    method public longchar loadContentMessage().
        define variable conteudo as longchar no-undo.
        assign conteudo = b-thl-mensagem-conteudo.conteudo.
        return conteudo.   
    end method.
    
    method public void loadMessageContent  ( typeContent as int64 ).
        
        this-object:ensureMessageCode().
        
        find first b-thl-mensagem-conteudo exclusive-lock
            where b-thl-mensagem-conteudo.codigo-mensagem = this-object:messageCode 
              and b-thl-mensagem-conteudo.tipo-conteudo   = typeContent             no-error.
              
    end method.
    
    method public void saveContentMessage( content as longchar ).
        assign b-thl-mensagem-conteudo.conteudo =  content.   
    end method.

    //Metodo de validacao
    method protected void ensureMessageCode().
        if not StringUtil:hasValue( this-object:messageCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'ensureMessageCode', 'Codigo de mensagem nao informado.' ).
    end method.
    
    method protected void ensureReferenceCode().
        if not StringUtil:hasValue( this-object:referenceCode         ) and
           not StringUtil:hasValue( this-object:externalReferenceCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'ensureReferenceCode', 'Codigo de referencia nao informado.' ).
    end method.
    
end class.