
/*------------------------------------------------------------------------
    File        : emabrque.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Lopes
    Created     : Mon Mar 23 21:03:50 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/
using Progress.Json.ObjectModel.*.

block-level on error undo, throw.

/* ***************************  Definitions  ************************** */
define input parameter embarque  as JsonObject no-undo.

define new global shared variable c-seg-usuario as character no-undo.

{cdp/cd0667.i}

define shared temp-table rowErrors no-undo
    field ErrorSequence    as integer
    field ErrorNumber      as integer
    field ErrorDescription as character
    field ErrorParameters  as character
    field ErrorType        as character
    field ErrorHelp        as character
    field ErrorSubType     as character.  

define temp-table tt-embarque no-undo like embarque use-index ch-emb
    field i-sequen as integer
    field ind-oper as integer. 

define temp-table tt-ped-ent no-undo
    field nome-abrev   like ped-ent.nome-abrev
    field nr-pedcli    like ped-ent.nr-pedcli
    field nr-sequencia like ped-ent.nr-sequencia
    field it-codigo    like ped-ent.it-codigo
    field cod-refer    like ped-ent.cod-refer
    field qt-alocada   like ped-ent.qt-alocada
    field qt-log-aloca like ped-ent.qt-log-aloca
    field qt-pedida    like ped-ent.qt-pedida 
    field qt-atendida  like ped-ent.qt-atendida
    field dt-entrega   like ped-ent.dt-entrega
    field nr-entrega   like ped-ent.nr-entrega 
    field hr-entrega   like ped-ent.hr-entrega
    field nr-proc-exp  like ped-ent.nr-proc-exp
    field num-sequencia-bonif like ped-item.num-sequencia-bonif
    field nat-operacao    like ped-item.nat-operacao
    field dec-1           like ped-ent.dec-1
    field qt-a-alocar     as decimal
    field i-sequen        as integer
    field cdd-embarq      as decimal
    field nr-seq-registro as integer init 1
    
    index ch-ent is primary

        nr-proc-exp
        nome-abrev
        nr-pedcli
        nr-sequencia
        it-codigo
        cod-refer         
        nr-entrega.

define variable h-eqapi300    as handle    no-undo.
define variable de-cdd-embarq as decimal   no-undo.
define variable i-index       as integer   no-undo.
define variable ja-entregas   as JsonArray no-undo.

/* ***************************  Main Block  *************************** */
find last embarque no-lock no-error.

assign de-cdd-embarq = if available embarque then embarque.cdd-embarq + 1 else 1
       ja-entregas   = embarque:GetJsonArray('entregas').

run eqp/eqapi300.p persistent set h-eqapi300.

find first estabelec no-lock
    where estabelec.cgc = embarque:GetCharacter( 'cnpjEstabelecimento' ) no-error.
    
if not available estabelec then 
    undo, throw new Progress.Lang.AppError( 'Estabelecimento nao localizado', 17006 ).      

//Cria embarque
create tt-embarque.
assign tt-embarque.cdd-embarq  = de-cdd-embarq
       tt-embarque.usuario     = c-seg-usuario
       tt-embarque.dt-embarque = today
       tt-embarque.cod-tipo    = ''
       tt-embarque.cod-rota    = ''
       tt-embarque.nome-transp = ''
       tt-embarque.placa       = ''
       tt-embarque.cod-estabel = estabelec.cod-estabel
       tt-embarque.situacao    = 1
       tt-embarque.identific   = c-seg-usuario
       tt-embarque.i-sequen    = 1
       tt-embarque.ind-oper    = 1  //1 - Inclusao 2 - Alteracao 3 - Eliminacao
       .  

do transaction.

    run pi-recebe-tt-embarque in h-eqapi300(  input table tt-embarque).
    run pi-trata-tt-embarque  in h-eqapi300(  input 'mgs',
                                              input true ). 
    run pi-devolve-tt-erro    in h-eqapi300( output table tt-erro    ).
    
    if temp-table tt-erro:has-records then do.
        run pi-gerar-error.
        undo, throw new Progress.Lang.AppError( 'Erro geração do embarque', 17006 ).  
    end.
       
    do i-index = 1 to ja-entregas:Length.
    
        empty temp-table tt-ped-ent no-error.
        
        find first ped-venda no-lock
            where ped-venda.nr-pedido = ja-entregas:GetJsonObject(i-index):GetInteger  ('numeroPedido') no-error.
            
        find first ped-ent no-lock
             where ped-ent.nome-abrev   = ped-venda.nome-abrev
               and ped-ent.nr-pedcli    = ped-venda.nr-pedcli  
               and ped-ent.nr-sequencia = ja-entregas:GetJsonObject(i-index):GetInteger  ('sequenciaItem')
               and ped-ent.it-codigo    = ja-entregas:GetJsonObject(i-index):GetCharacter('codigoProduto')
               and ped-ent.nr-entrega   = ja-entregas:GetJsonObject(i-index):GetInteger  ('numeroEntrega') no-error.
    
        if  not available ped-ent then 
            undo, throw new Progress.Lang.AppError( substitute( 'Entrega do pedido nao localizada do index &1', i-index), 17006 ).      
            
        create tt-ped-ent.
        buffer-copy ped-ent to tt-ped-ent
            assign tt-ped-ent.cdd-embarq  = de-cdd-embarq
                   tt-ped-ent.dt-entrega  = today
                   tt-ped-ent.qt-a-alocar = ped-ent.qt-pedida
                   tt-ped-ent.i-sequen    = ja-entregas:GetJsonObject(i-index):GetInteger('sequencia').
                   .
                   
        find first es_embarque exclusive-lock
            where es_embarque.nr_pedcli   = ped-venda.nr-pedcli 
              and es_embarque.nome_abrev  = ped-venda.nome-abrev
              and es_embarque.nr_embarque = de-cdd-embarq
              and es_embarque.nr_resumo   = tt-ped-ent.i-sequen   no-error .
            
        if  not avail es_embarque then do.
            create es_embarque.
            assign es_embarque.nome_abrev  = ped-venda.nr-pedcli
                   es_embarque.nr_pedcli   = ped-venda.nome-abrev
                   es_embarque.nr_embarque = de-cdd-embarq
                   es_embarque.nr_resumo   = tt-ped-ent.i-sequen .
        end.
        assign es_embarque.sit_emb_bloq  = 2
               es_embarque.ind_aprov_emb = 1
               es_embarque.Desc_Bloq     = ''.
 
        
        //Aloca UMA ENTREGA do pedido
        run pi-recebe-tt-ped-ent in h-eqapi300(  input table tt-ped-ent ).
        run pi-trata-tt-ped-ent  in h-eqapi300(  input true             ).
        run pi-devolve-tt-erro   in h-eqapi300( output table tt-erro    ).
        
        if temp-table tt-erro:has-records then do.
            run pi-gerar-error.
            undo, throw new Progress.Lang.AppError( 'Erro alocação do embarque', 17006 ).  
        end.

    end.           

    //Encerra embarque
    run pi-recebe-tt-embarque in h-eqapi300 (  input table tt-embarque).
    run pi-encerra-embarque   in h-eqapi300 (  input true             ).
    run pi-devolve-tt-erro    in h-eqapi300 ( output table tt-erro    ).   
    
    if temp-table tt-erro:has-records then do.
        run pi-gerar-error.
        undo, throw new Progress.Lang.AppError( 'Erro encerrar do embarque', 17006 ).  
    end.
    
end.

return string( de-cdd-embarq ).

finally.

    if valid-handle(h-eqapi300) then
        run pi-finalizar in h-eqapi300. 
            
end finally.  

procedure pi-gerar-error.
    
    for each tt-erro.
        create rowErrors.
        assign rowErrors.ErrorNumber      = tt-erro.cd-erro
               rowErrors.ErrorSequence    = tt-erro.i-sequen
               rowErrors.ErrorParameters  = tt-erro.parametro
               rowErrors.ErrorDescription = tt-erro.mensagem.
    end.

end procedure.