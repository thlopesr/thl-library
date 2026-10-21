/*------------------------------------------------------------------------
    File        : 
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Lopes
    Created     : 
    Notes       :
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

using thl-lib.core.error.ThlError.

/* ***************************  Definitions  ************************** */
{include/i-prgvrs.i thl0220z 12.00.00.000}

define  input parameter codigo-mensagem like thl-mensagem.codigo-mensagem  no-undo.
define output parameter num-ped-exec    as   integer                       no-undo.

define new global shared variable v_rec_servid_exec          as recid     no-undo.
define new global shared variable v_cod_estab_usuar          as character no-undo.
define new global shared variable v_cod_idiom_usuar          as character no-undo.
define new global shared variable v_cod_pais_empres_usuar    as character no-undo.
define new global shared variable v_cod_modul_dtsul_corren   as character no-undo.
define new global shared variable v_cod_aplicat_dtsul_corren as character no-undo.
define new global shared variable v_cod_unid_negoc_usuar     as character no-undo.
define new global shared variable v_cod_funcao_negoc_empres  as character no-undo.
define new global shared variable v_cod_modul_dtsul_empres   as character no-undo.
define new global shared variable v_cod_ccusto_corren        as character no-undo.
define new global shared variable v_cod_usuar_corren_criptog as character no-undo.
define new global shared variable v_cod_usuar_corren         as character no-undo.
define new global shared variable v_cod_empres_usuar         as character no-undo.
define new global shared variable v_cdn_empres_usuar         as character no-undo.
define new global shared variable i-ep-codigo-usuario        as character no-undo.
define new global shared variable c-seg-usuario              as character no-undo.

define temp-table tt-param no-undo
    field destino                as integer
    field arquivo                as character format "x(35)"
    field usuario                as character format "x(12)"
    field data-exec              as date
    field hora-exec              as integer
    field classifica             as integer
    field desc-classifica        as character format "x(40)"
    field modelo-rtf             as character format "x(35)"
    field l-habilitaRtf          as logical
    field codigo-ini             like thl-mensagem.codigo-mensagem             
    field codigo-fin             like thl-mensagem.codigo-mensagem              
    field objeto-ini             like thl-mensagem.objeto             
    field objeto-fin             like thl-mensagem.objeto
    field aplicacao-ini           like thl-mensagem.aplicacao
    field aplicacao-fin           like thl-mensagem.aplicacao
    field operacao-ini            like thl-mensagem.operacao
    field operacao-fin            like thl-mensagem.operacao
    field metodo-ini                like thl-mensagem.metodo
    field metodo-fin                like thl-mensagem.metodo.  
    
define variable raw-tt-param  as raw      no-undo.    

/* ***************************  Main Block  *************************** */
find first thl-mensagem no-lock
    where thl-mensagem.codigo-mensagem = codigo-mensagem no-error.

if not available thl-mensagem then
    undo, throw new ThlError(
        this-procedure:name,
        'thl0220z'         ,
        substitute( 'Mensagem &1 nao encontrada para agendamento.', codigo-mensagem ) ).

/* o metodo faz parte da chave da operacao: primeiro a linha da operacao da mensagem com o metodo dela;
   sem ela, a linha do objeto (operacao em branco) do mesmo metodo, como o InboundConfigLoader e o
   MessageConfigLoader */
find first thl-objeto-parametro no-lock
    where thl-objeto-parametro.cod-estabel = '*'
      and thl-objeto-parametro.objeto      = thl-mensagem.objeto
      and thl-objeto-parametro.aplicacao   = thl-mensagem.aplicacao
      and thl-objeto-parametro.operacao    = thl-mensagem.operacao
      and thl-objeto-parametro.metodo      = thl-mensagem.metodo
    no-error.

if not available thl-objeto-parametro then
    find first thl-objeto-parametro no-lock
        where thl-objeto-parametro.cod-estabel = '*'
          and thl-objeto-parametro.objeto      = thl-mensagem.objeto
          and thl-objeto-parametro.aplicacao   = thl-mensagem.aplicacao
          and thl-objeto-parametro.operacao    = ''
          and thl-objeto-parametro.metodo      = thl-mensagem.metodo
        no-error.

if not available thl-objeto-parametro then
    undo, throw new ThlError( 
        this-procedure:name, 
        'thl0220z'         , 
        substitute(
            'thl-objeto-parametro nao encontrado &1-&2-&3 (metodo &4)', 
            thl-mensagem.objeto                           , 
            thl-mensagem.operacao                         , 
            thl-mensagem.aplicacao                        ,
            thl-mensagem.metodo
        ) 
    ).
        
if thl-objeto-parametro.cod-servid-exec = '' then
    undo, throw new ThlError( 
        this-procedure:name, 
        'thl0220z'         , 
        substitute(
            'Servidor de execucao nao informado para &1-&2-&3 (metodo &4). Informe na aba Servidor do thl0022a.', 
            thl-objeto-parametro.objeto                   , 
            thl-objeto-parametro.operacao                 , 
            thl-objeto-parametro.aplicacao                ,
            thl-objeto-parametro.metodo
        ) 
    ).         

create tt-param.
assign tt-param.arquivo    = if thl-mensagem.sentido-fluxo then 'thl0220rp.txt'
                                                           else 'thl0221rp.txt'
       tt-param.data-exec  = today
       tt-param.destino    = 2
       tt-param.hora-exec  = integer( replace( substring( string(now), 12, 8), ':', '' ) )
       tt-param.usuario    = c-seg-usuario
       tt-param.codigo-ini = thl-mensagem.codigo-mensagem             
       tt-param.codigo-fin = thl-mensagem.codigo-mensagem              
       tt-param.aplicacao-ini = thl-mensagem.aplicacao
       tt-param.aplicacao-fin = thl-mensagem.aplicacao
       tt-param.objeto-ini = thl-mensagem.objeto
       tt-param.objeto-fin = thl-mensagem.objeto
       tt-param.operacao-ini = thl-mensagem.operacao
       tt-param.operacao-fin = thl-mensagem.operacao
       tt-param.metodo-ini   = thl-mensagem.metodo
       tt-param.metodo-fin   = thl-mensagem.metodo.
raw-transfer tt-param    to raw-tt-param.

create ped_exec.
assign ped_exec.cdn_estil_dwb          = 97
       ped_exec.cod_prog_dtsul         = if thl-mensagem.sentido-fluxo then 'thl0220'
                                                                       else 'thl0221'
       ped_exec.cod_release_prog_dtsul = '12.00.00.000'
       ped_exec.cod_servid_exec        = thl-objeto-parametro.cod-servid-exec
       ped_exec.cod_agrpdor            = 'default'
       ped_exec.cod_usuario            = c-seg-usuario //tt-param.usuario
       ped_exec.cod_empresa            = v_cdn_empres_usuar
       ped_exec.dat_criac_ped_exec     = today 
       ped_exec.dat_exec_ped_exec      = today
       ped_exec.hra_criac_ped_exec     = replace( string( time, 'hh:mm:ss' ), ':', '' )
       ped_exec.hra_exec_ped_exec      = replace( string( time, 'hh:mm:ss' ), ':', '' )
       ped_exec.ind_motiv_sit_ped_exec = '14'
       ped_exec.ind_sit_ped_exec       = '1'
       ped_exec.nom_prog_ext           = if thl-mensagem.sentido-fluxo then 'thl/thl0220rp.p'
                                                                       else 'thl/thl0221rp.p'
       ped_exec.num_ped_exec           = next-value(seq_ped_exec).

create ped_exec_param.
assign ped_exec_param.cod_aplicat_dtsul       = 'fnd'
       ped_exec_param.cod_dwb_file            = ped_exec.nom_prog_ext
       ped_exec_param.cod_dwb_output          = 'Arquivo'
       ped_exec_param.cod_idiom_trad          = v_cod_idiom_usuar
       ped_exec_param.cod_modul_dtsul         = v_cod_modul_dtsul_corren
       ped_exec_param.cod_pais                = v_cod_pais_empres_usuar
       ped_exec_param.cod_usuar_criptog       = v_cod_usuar_corren_criptog
       ped_exec_param.nom_dwb_printer         = if thl-mensagem.sentido-fluxo then 'thl0220.LST'
                                                                              else 'thl0221.LST'
       ped_exec_param.cod_estab               = v_cod_estab_usuar
       ped_exec_param.cod_aplicat_dtsul       = v_cod_aplicat_dtsul_corren
       ped_exec_param.cod_unid_negoc          = v_cod_unid_negoc_usuar
       ped_exec_param.cod_funcao_negoc_empres = v_cod_funcao_negoc_empres
       ped_exec_param.cod_modul_dtsul_empres  = v_cod_modul_dtsul_empres
       ped_exec_param.raw_param_ped_exec      = raw-tt-param
       ped_exec_param.num_ped_exec            = ped_exec.num_ped_exec
       ped_exec_param.cod_empresa             = if v_cod_empres_usuar <> ?  then v_cod_empres_usuar                                                
                                                                            else ''
       ped_exec_param.cod_empresa             = if v_cdn_empres_usuar <> ?  then ped_exec_param.cod_empresa + chr(10) + string(v_cdn_empres_usuar) 
                                                                            else ped_exec_param.cod_empresa + chr(10) + ''
       ped_exec_param.cod_empresa             = if i-ep-codigo-usuario <> ? then ped_exec_param.cod_empresa + chr(10) + string(i-ep-codigo-usuario)
                                                                            else ped_exec_param.cod_empresa + chr(10) + ''.

create thl-mensagem-ped-exec.
assign thl-mensagem-ped-exec.codigo-mensagem  = codigo-mensagem
       thl-mensagem-ped-exec.data-agendamento = now
       thl-mensagem-ped-exec.num-ped-exec     = ped_exec.num_ped_exec.

assign num-ped-exec = ped_exec.num_ped_exec.

return 'OK'.

