 
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

block-level on error undo, throw.

class thl-lib.integration.messaging.repository.MessageRepository.  

    define protected buffer b-thl-mensagem           for thl-mensagem.
    define protected buffer b-thl-mensagem-historico for thl-mensagem-historico.
    define protected buffer b-thl-mensagem-item      for thl-mensagem-item.
    define protected buffer b-thl-mensagem-conteudo  for thl-mensagem-conteudo.
    
    define public property messageCode   as character no-undo get. set.
    define public property referenceCode as character no-undo get. set.
    define public property objectName    as character no-undo get. set.

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    method public void generateMessageCode().
        assign this-object:messageCode = guid( generate-uuid ).
    end method.

    //Metodos relacionado a tabela thl-mensagem    
    method public void createMessage( objectName           as character ,
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
               b-thl-mensagem.operacao          = integrationOperation
               b-thl-mensagem.metodo            = methodType
               b-thl-mensagem.forma-execucao    = connectorType
               b-thl-mensagem.modelo-integracao = executionMode
               b-thl-mensagem.qtd-tentativas    = 0
               b-thl-mensagem.sentido-fluxo     = integrationDirection
               b-thl-mensagem.sit-processamento = 1
               b-thl-mensagem.sit-requisicao    = 1
               b-thl-mensagem.sit-retorno       = 1
               .
               
        assign this-object:objectName = objectName.
        
    end method.
    
    method public void loadMessage().
        this-object:ensureMessageCode().
        find first b-thl-mensagem exclusive-lock
            where b-thl-mensagem.codigo-mensagem = this-object:messageCode no-error.
    end method.
    
    method public void saveResultMessage( destination     as character,
                                          successRequest  as logical  ,  
                                          successResponse as logical  ,
                                          successProcess  as logical  ,
                                          statusCode      as integer  ,
                                          statusMessage   as character).
                                          
        assign b-thl-mensagem.destino            = destination
               b-thl-mensagem.dt-integracao      = now
               b-thl-mensagem.qtd-tentativas     = b-thl-mensagem.qtd-tentativas + 1
               b-thl-mensagem.sit-processamento  = if successProcess  = ? then 4 else if successProcess  then 3 else 2
               b-thl-mensagem.sit-requisicao     = if successResponse = ? then 4 else if successRequest  then 3 else 2
               b-thl-mensagem.sit-retorno        = if successResponse = ? then 4 else if successResponse then 3 else 2
               b-thl-mensagem.cod-status-retorno = statusCode
               b-thl-mensagem.descr-retorno      = statusMessage
               .
                  
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
        assign b-thl-mensagem-item.codigo-mensagem = this-object:messageCode
               b-thl-mensagem-item.chave-registro  = this-object:referenceCode. 
    end method.
    
    method public logical hasExistingMessageItemForReference().
        return available b-thl-mensagem-item.
    end method.    

    method public void loadMessageItemByReference( objectName as character ).
        
        this-object:ensureReferenceCode().
        
        find first b-thl-mensagem-item exclusive-lock
            where b-thl-mensagem-item.chave-registro = this-object:referenceCode 
              and can-find( first thl-mensagem of b-thl-mensagem-item 
                                where thl-mensagem.objeto = objectName )no-error.
            
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
        if this-object:messageCode = '' then
            undo, throw new AppError( 'Message code was not informed.', 17006 ).
    end method.
    
    method protected void ensureReferenceCode().
        if this-object:referenceCode = '' then
            undo, throw new AppError( 'Reference code was not informed.', 17006 ).
    end method.
    
end class.