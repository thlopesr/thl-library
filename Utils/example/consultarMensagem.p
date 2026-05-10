
/*------------------------------------------------------------------------
    File        : consultarMensagem.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Lopes
    Created     : Sat Mar 07 19:45:35 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */



output to \\tsclient\c\temp\thl-mensagem-conteudo.txt.
for each thl-mensagem
    where thl-mensagem.objeto      = 'NotaFiscal'
      and thl-mensagem.dt-criacao >= datetime( today ) 
      .
    
    disp thl-mensagem
        with width 333 1 col.
    
    for each thl-mensagem-conteudo of thl-mensagem.
    
        disp thl-mensagem-conteudo except conteudo
            with width 333 1 col.
            
        export thl-mensagem-conteudo.conteudo.
            
    end.             
        
end.
output close.

//for each thl-mensagem.
//    delete thl-mensagem.
//end.
//
//for each thl-mensagem-historico.
//    delete thl-mensagem-historico.
//end.
