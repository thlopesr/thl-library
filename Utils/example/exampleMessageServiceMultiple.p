
/*------------------------------------------------------------------------
    File        : 
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Lopes
    Created     : Sat Mar 07 19:25:40 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */
using thl-lib.integration.messaging.service.MessageService.


/* ***************************  Main Block  *************************** */

define variable service as MessageService no-undo.

for each thl-mensagem
    where thl-mensagem.objeto = 'PedidoVenda'.
    
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
        
end.

find last ped-venda no-lock.

assign service = new MessageService ( 'PedidoVenda', 'loog.ai', 1 ).

//service:beginBuild ().
//service:addObject  ( recid(ped-venda) ).
//service:finishBuild().
//service:process    ().
    
