
/*------------------------------------------------------------------------
    File        : 
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Lopes
    Created     : Sat Mar 07 19:25:40 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/
using thl-lib.integration.messaging.service.MessageService.

/* ***************************  Definitions  ************************** */
define variable service as MessageService no-undo.


/* ***************************  Main Block  *************************** */
/*for each thl-mensagem
    where thl-mensagem.objeto = 'item'.
    
    for each thl-mensagem-historico of thl-mensagem.
        delete thl-mensagem-historico.
    end.
    
    for each thl-mensagem-item of thl-mensagem.
        delete thl-mensagem-item.
    end. 
    
    for each thl-mensagem-conteudo of thl-mensagem.
        delete thl-mensagem-conteudo.             
    end. 
    
    delete thl-mensagem.               
        
end.  */



find last item no-lock.

assign service = new MessageService ( 'Item', 1 ).

service:beginBuild ().
service:addObject  ( recid(item) ).
service:finishBuild().
service:process    ().
