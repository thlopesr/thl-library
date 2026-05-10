
/*------------------------------------------------------------------------
    File        : limparConteudo.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Lopes
    Created     : Tue Apr 28 18:29:46 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
for each thl-mensagem
    where thl-mensagem.objeto = 'LPCO'.
    
    for each thl-mensagem-conteudo of thl-mensagem.
        delete  thl-mensagem-conteudo.          
    end.    
    
    for each thl-mensagem-historico of thl-mensagem.
        delete  thl-mensagem-historico.          
    end.  
    
    for each thl-mensagem-item of thl-mensagem.
        delete  thl-mensagem-item.          
    end. 
    
    delete thl-mensagem.      
        
end.