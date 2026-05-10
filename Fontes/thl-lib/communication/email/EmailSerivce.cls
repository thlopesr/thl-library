     
 /*------------------------------------------------------------------------
    File        : Email
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Thu Jan 09 09:18:08 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.communication.email.EmailMessageFactory.
using thl-lib.communication.email.EmailLogger.

routine-level on error undo, throw.

class thl-lib.communication.email.EmailSerivce.

    {utp/utapi019.i2}

    define variable emailMessageFactory as emailMessageFactory no-undo.
    
    constructor public EmailSerivce().
        assign emailMessageFactory = new emailMessageFactory().
    end constructor. 
    
    constructor public EmailSerivce( pMessageFactory as emailMessageFactory ).
        assign this-object:emailMessageFactory = pMessageFactory. 
    end constructor.  

    method public void sender().
        executeDatasulMailService().
        saveReturn().
    end method.
    
    method public void executeDatasulMailService().
    
        define variable hUtapi019 as handle no-undo.
        
        empty temp-table tt-envio2      no-error.
        empty temp-table tt-mensagem    no-error.
        empty temp-table tt-paramEmail2 no-error.
    
        run utp/utapi019.p persistent set hUtapi019.
    
        create tt-envio2.
        assign tt-envio2.versao-integracao  = 1                
               tt-envio2.remetente          = emailMessageFactory:sender
               tt-envio2.destino            = emailMessageFactory:toRecipients
               tt-envio2.copia              = emailMessageFactory:ccRecipients
               tt-envio2.assunto            = emailMessageFactory:subject
               tt-envio2.importancia        = emailMessageFactory:importance
               tt-envio2.log-enviada        = no
               tt-envio2.log-lida           = no
               tt-envio2.arq-anexo          = emailMessageFactory:attachmentPath
               tt-envio2.formato            = 'HTML'
               tt-envio2.servidor           = emailMessageFactory:smtpServer
               tt-envio2.porta              = emailMessageFactory:smtpPort.
                       
        create tt-mensagem.
        assign tt-mensagem.seq-mensagem = 1
               tt-mensagem.mensagem     = emailMessageFactory:body. 
               
        create tt-paramEmail2.
        assign tt-paramEmail2.caminhoEmail = 5 
               tt-paramEmail2.TLS          = emailMessageFactory:useTLS
               tt-paramEmail2.debug        = emailMessageFactory:debug
               tt-paramEmail2.SSL          = emailMessageFactory:useSSL . 
               
        run pi-execute4 in hUtapi019(  input table tt-envio2     ,
                                       input table tt-mensagem   ,
                                       input table tt-paramEmail2,
                                       input table ttAttachment  ,
                                      output table tt-erros      ).                 

        delete procedure hUtapi019.
        
    end.
    
    method public void saveReturn().
        
        define variable emailLogger  as EmailLogger no-undo.
        
        if not emailMessageFactory:saveReturn then
            return.
        
        assign emailLogger = new EmailLogger().
    
        temp-table    tt-erros:write-json ('LONGCHAR', emailLogger:returnPayload ).
        temp-table tt-mensagem:write-json ('LONGCHAR', emailLogger:messageText   ).
        temp-table   tt-envio2:write-json ('LONGCHAR', emailLogger:sendInfo      ). 
    
        emailLogger:save( emailMessageFactory, not temp-table tt-erros:has-records ).  
            
    end.

end class.