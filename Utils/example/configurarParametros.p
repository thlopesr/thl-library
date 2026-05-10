
/*------------------------------------------------------------------------
    File        : configurarParametros.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Lopes
    Created     : Sat Mar 14 12:33:00 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
create thl-objeto.
update thl-objeto
    with width 333 1 col.
    
create thl-objeto-parametro.
update thl-objeto-parametro
    with width 333 1 col.
    
create thl-ambiente.    
update thl-ambiente
    with width 333 1 col. 
    
create thl-ambiente-param.
update thl-ambiente-param
    with width 333 1 col.
              
//for each thl-objeto.
//    update thl-objeto.
//        with width 333 1 col.
//end.
//
//for each thl-objeto-parametro.
//    update thl-objeto-parametro
//        with width 333 1 col.
//end.
//
//for each thl-ambiente.
//    update thl-ambiente
//        with width 333 1 col.
//end.
//
//for each thl-ambiente-param.
//    update thl-ambiente-param
//        with width 333 1 col.
//end.

//run criarVriavelAmbiente (  'baseUrl'             , 'https://nitro-api-roteirizador.loog.ai' ).
//run criarVriavelAmbiente (  'pathToken'           , '' ).
//run criarVriavelAmbiente (  'requiresTokenRequest', 'Não' ).
//run criarVriavelAmbiente (  'authenticationType'  , 'Bearer' ).
//run criarVriavelAmbiente (  'token'               , 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyIjoiZWxlY3Ryb2x1eF9vdXRib3VuZCIsInNlcnZpY2UiOiJhcGlfbGlzdCJ9.MxHerBdCARvO6JfXg1B3kWM1wU3jF2CM8nUYgwsrEr4' ).
//run criarVriavelAmbiente (  'userName'            , '' ).
//run criarVriavelAmbiente (  'password'            , '' ).
//run criarVriavelAmbiente (  'timeout'             , '3000' ).

//run criarVriavelAmbiente (  'path'                , '/itens' ).
//run criarVriavelAmbiente (  'contentType'         , 'application/json' ).
//run criarVriavelAmbiente (  'headers'             , '' ).
//run criarVriavelAmbiente (  'parameters'          , '' ).

/*
procedure criarVriavelAmbiente.

    define input  parameter cod-variavel as character no-undo.
    define input  parameter val-variavel as character no-undo.


    create thl-ambiente-param-variavel.
    assign thl-ambiente-param-variavel.cod-ambiente = 'PRD'
           thl-ambiente-param-variavel.cod-param    = 'loog.ai.item'
           thl-ambiente-param-variavel.cod-variavel = cod-variavel
           thl-ambiente-param-variavel.val-variavel = val-variavel.                            
                              
end procedure.       */                       
                              
                              
                              
                              
                              
                              
                              
                              