&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME wWindow
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS wWindow 
/*:T*******************************************************************************
** Copyright TOTVS S.A. (2009)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da TOTVS, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
//using thl.objeto.Mensagem from propath.

{include/i-prgvrs.i thl1986 12.00.00.000}

/* Chamada a include do gerenciador de licen‡as. Necessario alterar os parametros */
/*                                                                                */
/* <programa>:  Informar qual o nome do programa.                                 */
/* <m¢dulo>:  Informar qual o m¢dulo a qual o programa pertence.                  */

{include/i-license-manager.i thl1986 THL}

create widget-pool.

/* Preprocessors Definitions ---                                      */
&GLOBAL-DEFINE Program        thl1986
&GLOBAL-DEFINE Version        12.00.00.0000

&GLOBAL-DEFINE WindowType     Master/Detail

&GLOBAL-DEFINE Folder         NO
&GLOBAL-DEFINE InitialPage    0 
&GLOBAL-DEFINE FolderLabels   

&GLOBAL-DEFINE page0Widgets   brIntegracao btQueryJoins btReportsJoins btExit btHelp btSelecao
&GLOBAL-DEFINE page1Widgets   
&GLOBAL-DEFINE page2Widgets   

/* Parameters Definitions ---                                           */
define new global shared variable c-seg-usuario as character  format 'x(12)' no-undo.

define new shared variable codigo-mensagem-ini  like thl-mensagem.codigo-mensagem no-undo.
define new shared variable codigo-mensagem-fin  like thl-mensagem.codigo-mensagem no-undo.
define new shared variable objeto-ini           like thl-mensagem.objeto          no-undo.
define new shared variable objeto-fin           like thl-mensagem.objeto          no-undo.
define new shared variable operacao-ini         like thl-mensagem.operacao        no-undo.
define new shared variable operacao-fin         like thl-mensagem.operacao        no-undo.
define new shared variable aplicacao-ini        like thl-objeto.aplicacao         no-undo.
define new shared variable aplicacao-fin        like thl-objeto.aplicacao         no-undo.
define new shared variable dt-criacao-ini       like thl-mensagem.dt-criacao      no-undo.
define new shared variable dt-criacao-fin       like thl-mensagem.dt-criacao      no-undo.
define new shared variable dt-integracao-ini    like thl-mensagem.dt-integracao   no-undo.
define new shared variable dt-integracao-fin    like thl-mensagem.dt-integracao   no-undo.
define new shared variable chave-registro-ini   like thl-mensagem-item.chave-registro no-undo.
define new shared variable chave-registro-fin   like thl-mensagem-item.chave-registro no-undo.

define new shared variable log-atualizar as logical no-undo.

/* Local Variable Definitions ---                                       */
define temp-table tt-thl-mensagem no-undo like thl-mensagem 
    field aplicacao          like thl-objeto.aplicacao
    field row-thl-mensagem   as rowid
    field dispositivo        as logical
    field desc-integracao    as character 
    field desc-metodo        as character 
    field desc-requisicao    as character
    field desc-retorno       as character
    field desc-processamento as character.

define variable dWinXC        as decimal                  no-undo.
define variable dWinYC        as decimal                  no-undo.

define variable hConsulta as handle  no-undo.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE Window
&Scoped-define DB-AWARE no

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME fpage0
&Scoped-define BROWSE-NAME brIntegracao

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-thl-mensagem

/* Definitions for BROWSE brIntegracao                                  */
&Scoped-define FIELDS-IN-QUERY-brIntegracao tt-thl-mensagem.codigo tt-thl-mensagem.objeto tt-thl-mensagem.desc-requisicao tt-thl-mensagem.desc-retorno tt-thl-mensagem.desc-processamento tt-thl-mensagem.data-integracao tt-thl-mensagem.data-criacao tt-thl-mensagem.tentativa tt-thl-mensagem.aplicacao tt-thl-mensagem.pacote tt-thl-mensagem.desc-integracao tt-thl-mensagem.desc-metodo tt-thl-mensagem.dispositivo tt-thl-mensagem.chave-registro tt-thl-mensagem.chave-registro-ext tt-thl-mensagem.corpo-retorno tt-thl-mensagem.corpo-requisicao   
&Scoped-define ENABLED-FIELDS-IN-QUERY-brIntegracao tt-thl-mensagem.codigo   tt-thl-mensagem.data-integracao ~
tt-thl-mensagem.objeto   
&Scoped-define ENABLED-TABLES-IN-QUERY-brIntegracao tt-thl-mensagem
&Scoped-define FIRST-ENABLED-TABLE-IN-QUERY-brIntegracao tt-thl-mensagem
&Scoped-define SELF-NAME brIntegracao
&Scoped-define QUERY-STRING-brIntegracao FOR EACH tt-thl-mensagem
&Scoped-define OPEN-QUERY-brIntegracao OPEN QUERY {&SELF-NAME} FOR EACH tt-thl-mensagem.
&Scoped-define TABLES-IN-QUERY-brIntegracao tt-thl-mensagem
&Scoped-define FIRST-TABLE-IN-QUERY-brIntegracao tt-thl-mensagem


/* Definitions for FRAME fpage0                                         */

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rtToolBar rtMain btSelecao btQueryJoins ~
btReportsJoins btExit btHelp brIntegracao 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
define var wWindow as widget-handle no-undo.

/* Menu Definitions                                                     */
define sub-menu smFile 
       menu-item miQueryJoins   label "&Consultas"    
       menu-item miReportsJoins label "&Relat¢rios"   
       rule
       menu-item miExit         label "&Sair"          accelerator "CTRL-X".

define sub-menu smHelp 
       menu-item miContents     label "&Conte£do"     
       menu-item miAbout        label "&Sobre..."     .

define menu mbMain menubar
       sub-menu  smFile         label "&Arquivo"      
       sub-menu  smHelp         label "&Ajuda"        .

define menu POPUP-MENU-brIntegracao 
       menu-item m_Integrao     label "Integrar"      
       rule
       menu-item m_Consulta_Mensagem label "Consultar Mensagem"
       menu-item m_Consulta_TOTVS label "Consultar TOTVS"
       menu-item m_Consultar_Historico label "Consultar Hist¢rico"
       rule
       menu-item m_Gerar_Contedo_Integrao label "Gerar Conte£do Integra‡Æo".


/* Definitions of the field level widgets                               */
define button btExit 
     image-up file "image\im-exi":U
     image-insensitive file "image\ii-exi":U
     label "Exit" 
     size 4 by 1.25
     font 4.

define button btHelp 
     image-up file "image\im-hel":U
     image-insensitive file "image\ii-hel":U
     label "Help" 
     size 4 by 1.25
     font 4.

define button btQueryJoins 
     image-up file "image\im-joi":U
     image-insensitive file "image\ii-joi":U
     label "Query Joins" 
     size 4 by 1.25
     font 4.

define button btReportsJoins 
     image-up file "image\im-pri":U
     image-insensitive file "image\ii-pri":U
     label "Reports Joins" 
     size 4 by 1.25
     font 4.

define button btSelecao 
     image-up file "image\im-ran":U
     image-insensitive file "image\ii-ran":U
     label "Sele‡Æo" 
     size 4 by 1.25
     font 4.

define rectangle rtMain
     edge-pixels 2 graphic-edge  no-fill   
     size 88.57 by 15.

define rectangle rtToolBar
     edge-pixels 2 graphic-edge    
     size 88.57 by 1.5
     bgcolor 7 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
define query brIntegracao for 
      tt-thl-mensagem scrolling.
&ANALYZE-RESUME

/* Browse definitions                                                   */
define browse brIntegracao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS brIntegracao wWindow _FREEFORM
  query brIntegracao display
    tt-thl-mensagem.codigo               width 30
    tt-thl-mensagem.objeto               width 16
    tt-thl-mensagem.operacao             width 16
    tt-thl-mensagem.aplicacao            width 14                        column-label 'Aplicacao'
    tt-thl-mensagem.desc-integracao      width 10                        column-label 'Modelo'
    tt-thl-mensagem.desc-metodo          width 10                        column-label 'Metodo'
    tt-thl-mensagem.dispositivo          width 08 format 'Saida/Entrada' column-label 'Disposit.'
    tt-thl-mensagem.dt-integracao                                        column-label 'Data Integracao'
    tt-thl-mensagem.dt-criacao                                           column-label 'Data Criacao'
    tt-thl-mensagem.desc-requisicao      width 10 format 'x(15)'         column-label 'Requis.' 
    tt-thl-mensagem.desc-retorno         width 10 format 'x(15)'         column-label 'Retorno' 
    tt-thl-mensagem.desc-processamento   width 10 format 'x(15)'         column-label 'Proces.' 
    tt-thl-mensagem.destino              width 20 format 'x(60)'
    tt-thl-mensagem.cod-status-retorno   
    tt-thl-mensagem.descr-retorno        width 10 format 'x(50)'  
    //enable 
    //tt-thl-mensagem.dt-integracao  
    //tt-thl-mensagem.objeto
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 86 BY 14
         FONT 1 ROW-HEIGHT-CHARS .46 FIT-LAST-COLUMN.


/* ************************  Frame Definitions  *********************** */

define frame fpage0
     btSelecao at row 1.25 col 2.72 help
          "Parƒmetros de Sele‡Æo" widget-id 6
     btQueryJoins at row 1.25 col 73.57 help
          "Consultas relacionadas"
     btReportsJoins at row 1.25 col 77.57 help
          "Relat¢rios relacionados"
     btExit at row 1.25 col 81.57 help
          "Sair"
     btHelp at row 1.25 col 85.57 help
          "Ajuda"
     brIntegracao at row 3.25 col 3 widget-id 200
     rtToolBar at row 1.08 col 1.86
     rtMain at row 2.75 col 1.86 widget-id 2
    with 1 down no-box keep-tab-order overlay 
         side-labels no-underline three-d 
         at col 1 row 1
         size 90 by 17.21
         font 1 widget-id 100.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: Window
   Allow: Basic,Browse,DB-Fields,Window,Query
   Add Fields to: Neither
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
if session:display-type = "GUI":U then
  create window wWindow assign
         hidden             = yes
         title              = ""
         height             = 17
         width              = 90
         max-height         = 40.5
         max-width          = 365.72
         virtual-height     = 40.5
         virtual-width      = 365.72
         resize             = no
         scroll-bars        = no
         status-area        = yes
         bgcolor            = ?
         fgcolor            = ?
         keep-frame-z-order = yes
         three-d            = yes
         message-area       = no
         sensitive          = yes.
else {&WINDOW-NAME} = current-window.

assign {&WINDOW-NAME}:MENUBAR    = menu mbMain:HANDLE.
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB wWindow 
/* ************************* Included-Libraries *********************** */

{window/window.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW wWindow
  NOT-VISIBLE,,RUN-PERSISTENT                                           */
/* SETTINGS FOR FRAME fpage0
   FRAME-NAME                                                           */
/* BROWSE-TAB brIntegracao btHelp fpage0 */
assign 
       brIntegracao:POPUP-MENU in frame fpage0             = menu POPUP-MENU-brIntegracao:HANDLE.

if session:display-type = "GUI":U and VALID-HANDLE(wWindow)
then wWindow:hidden = no.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE brIntegracao
/* Query rebuild information for BROWSE brIntegracao
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH tt-thl-mensagem.
     _END_FREEFORM
     _Query            is NOT OPENED
*/  /* BROWSE brIntegracao */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK FRAME fpage0
/* Query rebuild information for FRAME fpage0
     _Options          = "SHARE-LOCK KEEP-EMPTY"
     _Query            is NOT OPENED
*/  /* FRAME fpage0 */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME wWindow
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL wWindow wWindow
on end-error of wWindow
or endkey of {&WINDOW-NAME} anywhere do:
    /* This case occurs when the user presses the "Esc" key.
       In a persistently run window, just ignore this.  If we did not, the
       application would exit. */
    if this-procedure:persistent then return no-apply.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL wWindow wWindow
on window-close of wWindow
do:
    /* This event will close the window and terminate the procedure.  */
    apply "CLOSE":U to this-procedure.
    return no-apply.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL wWindow wWindow
on window-maximized of wWindow
do.    

    define variable dXC      as decimal    no-undo.                                                                           
    define variable dYC      as decimal    no-undo.                                                                           

    assign // Tamanho da tela 
           dXC      = wWindow:width-chars  - dWinXC                                
           dYC      = wWindow:height-chars - dWinYC                                
           dWinXC   = wWindow:width-chars                                          
           dWinYC   = wWindow:height-chars
           // Tamanho dos frames 
           frame fPage0:width-chars    = wWindow:width-chars                                          
           frame fPage0:height-chars   = wWindow:height-chars                                         
           // Objetos em tela
           rtToolBar:width-chars in frame fPage0 = rtToolBar:width-chars in frame fPage0 + dXC 
           rtMain:width-chars in frame fPage0    = rtMain:width-chars in frame fPage0 + dXC
           rtMain:HEIGHT-chars in frame fPage0   = rtMain:HEIGHT-chars in frame fPage0 + dYC
           btExit:column in frame fPage0         = btExit:column in frame fPage0 + dXC
           btQueryJoins:column in frame fPage0   = btQueryJoins:column in frame fPage0 + dXC
           btReportsJoins:column in frame fPage0 = btReportsJoins:column in frame fPage0 + dXC
           btHelp:column in frame fPage0         = btHelp:column in frame fPage0 + dXC
           brIntegracao:WIDTH in frame fPage0    = brIntegracao:WIDTH in frame fPage0 + dXC
           brIntegracao:HEIGHT in frame fPage0   = brIntegracao:HEIGHT in frame fPage0 + dYC.

end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL wWindow wWindow
on window-restored of wWindow
do.
    
    define variable dXC      as decimal    no-undo.                                                                           
    define variable dYC      as decimal    no-undo.                                                                           

    assign // Tamanho da tela
           dXC    = dWinXC - wWindow:width-chars                         
           dYC    = dWinYC - wWindow:height-chars                        
           dWinXC = wWindow:width-chars                                  
           dWinYC = wWindow:height-chars                                 
           // Objetos em tela
           rtToolBar:width-chars in frame fPage0 = rtToolBar:width-chars in frame fPage0 - dXC 
           rtMain:width-chars in frame fPage0    = rtMain:width-chars in frame fPage0 - dXC
           rtMain:HEIGHT-chars in frame fPage0   = rtMain:HEIGHT-chars in frame fPage0 - dYC
           btExit:column in frame fPage0         = btExit:column in frame fPage0 - dXC
           btQueryJoins:column in frame fPage0   = btQueryJoins:column in frame fPage0 - dXC
           btReportsJoins:column in frame fPage0 = btReportsJoins:column in frame fPage0 - dXC
           btHelp:column in frame fPage0         = btHelp:column in frame fPage0 - dXC
           brIntegracao:WIDTH in frame fPage0    = brIntegracao:WIDTH in frame fPage0 - dXC
           brIntegracao:HEIGHT in frame fPage0   = brIntegracao:HEIGHT in frame fPage0 - dYC.

end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME brIntegracao
&Scoped-define SELF-NAME brIntegracao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL brIntegracao wWindow
on mouse-select-dblclick of brIntegracao in frame fpage0
do:

    /*define variable mensagem as class Mensagem  no-undo.

    run utp/ut-msgs.p (input 'show':U,
                       input 27100,
                       input 'Deseja enviar integracao?').
                       
    if return-value = 'yes' then do.
    
        mensagem = dynamic-new tt-thl-mensagem.pacote + tt-thl-mensagem.objeto( tt-thl-mensagem.row-thl-mensagem ).
        
        mensagem:possicionarResgitroObjeto().
        mensagem:gerarConteudo().
        mensagem:salvarConteudo().
        
        mensagem:salvarCorpoRequisicao().
        
        mensagem:conectar().         
        mensagem:integrar().
        
        mensagem:resetarRetorno().
        mensagem:salvarRetorno().

        delete object mensagem no-error.
                
        run piObterInegracao.
    end.*/

end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL brIntegracao wWindow
on start-search of brIntegracao in frame fpage0
do:
    
    define variable columnHandle as handle no-undo.
    
    assign columnHandle = {&BROWSE-NAME}:CURRENT-COLUMN.
    apply 'END-SEARCH' to {&BROWSE-NAME}.

    case columnHandle:name.

        when 'dt-criacao'      then
            open query {&BROWSE-NAME}
                 for each tt-thl-mensagem no-lock by tt-thl-mensagem.dt-criacao.

        when 'objeto' then
            open query {&BROWSE-NAME}
                 for each tt-thl-mensagem no-lock by tt-thl-mensagem.objeto.

    end case. 

end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btExit
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btExit wWindow
on choose of btExit in frame fpage0 /* Exit */
or choose of menu-item miExit in menu mbMain do:
    apply "CLOSE":U to this-procedure.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btHelp
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btHelp wWindow
on choose of btHelp in frame fpage0 /* Help */
or choose of menu-item miContents in menu mbMain do:
    {include/ajuda.i}
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btQueryJoins
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btQueryJoins wWindow
on choose of btQueryJoins in frame fpage0 /* Query Joins */
or choose of menu-item miQueryJoins in menu mbMain do:
    run showQueryJoins in this-procedure.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btReportsJoins
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btReportsJoins wWindow
on choose of btReportsJoins in frame fpage0 /* Reports Joins */
or choose of menu-item miReportsJoins in menu mbMain do:
    run showReportsJoins in this-procedure.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btSelecao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btSelecao wWindow
on choose of btSelecao in frame fpage0 /* Sele‡Æo */
do.
    run thl\thl1986a.w.
    if log-atualizar then
        run piObterInegracao.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME miAbout
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL miAbout wWindow
on choose of menu-item miAbout /* Sobre... */
do:
    {include/sobre.i}
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME m_Consultar_Historico
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL m_Consultar_Historico wWindow
on choose of menu-item m_Consultar_Historico /* Consultar Hist¢rico */
do:
    /*if available tt-thl-mensagem then do.
        
        assign i-codigo-objeto = tt-thl-mensagem.codigo.

        RUN thl\thl1986h.w PERSISTENT SET hConsulta.

        run dispatch         in hConsulta ( input 'initialize':U  ).
        RUN local-initialize in hConsulta.

        wait-for close of hConsulta.

        delete OBJECT  hConsulta NO-ERROR.
        
    end.*/
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME m_Consulta_Mensagem
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL m_Consulta_Mensagem wWindow
on choose of menu-item m_Consulta_Mensagem /* Consultar Mensagem */
do:

    /*if available tt-thl-mensagem then do.
        
        assign i-codigo-objeto = tt-thl-mensagem.codigo.

        RUN thl\thl1986c.w PERSISTENT SET hConsulta.

        run dispatch         in hConsulta ( input 'initialize':U  ).
        RUN local-initialize in hConsulta.

        wait-for close of hConsulta.

        delete OBJECT  hConsulta NO-ERROR.
        
    end.*/

end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME m_Consulta_TOTVS
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL m_Consulta_TOTVS wWindow
on choose of menu-item m_Consulta_TOTVS /* Consultar TOTVS */
do:
    
    /*if available tt-thl-mensagem then do.
    
        mensagem = dynamic-new tt-thl-mensagem.pacote + tt-thl-mensagem.objeto( input tt-thl-mensagem.row-thl-mensagem ).
            
        //mensagem:possicionarRegistroIntegracao( input tt-thl-mensagem.row-thl-mensagem ).
        mensagem:possicionarResgitroObjeto().
        mensagem:possicionarRegistroTotvs().
        mensagem:chamarConsulta().
        
        delete object mensagem no-error.
        
    end.*/
    
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME m_Gerar_Contedo_Integrao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL m_Gerar_Contedo_Integrao wWindow
on choose of menu-item m_Gerar_Contedo_Integrao /* Gerar Conte£do Integra‡Æo */
do:
    /*if available tt-thl-mensagem then do.

        mensagem = dynamic-new tt-thl-mensagem.pacote + tt-thl-mensagem.objeto( input tt-thl-mensagem.row-thl-mensagem ).
            
        mensagem:possicionarResgitroObjeto().
        mensagem:gerarConteudo().
        
        mensagem:salvarConteudo().
        mensagem:salvarCorpoRequisicao().
        
        delete object mensagem no-error.
        
    end.*/
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME m_Integrao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL m_Integrao wWindow
on choose of menu-item m_Integrao /* Integrar */
do:
    apply 'mouse-select-dblclick' to brIntegracao IN FRAME {&FRAME-NAME}.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK wWindow 


{window/mainblock.i}

assign codigo-mensagem-ini = ''
       codigo-mensagem-fin = 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'
       objeto-ini          = ''
       objeto-fin          = 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'
       operacao-ini        = ''
       operacao-fin        = 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'
       aplicacao-ini       = ''
       aplicacao-fin       = 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'
       dt-criacao-ini      = today - 3
       dt-criacao-fin      = today + 1
       dt-integracao-ini   = today - 3
       dt-integracao-fin   = today + 1
       chave-registro-ini  = ''
       chave-registro-fin  = 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'
       dWinXC              = wWindow:width-chars
       dWinYC              = wWindow:height-chars.

run piObterInegracao.

//apply 'CHOOSE' to btSelecao.

//assign tt-thl-mensagem.dt-criacao:read-only in browse brIntegracao = true
//       tt-thl-mensagem.objeto    :read-only in browse brIntegracao = true.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE piObterInegracao wWindow 
procedure piObterInegracao :
/*------------------------------------------------------------------------------
      Purpose:     
      Parameters:  <none>
      Notes:       
    ------------------------------------------------------------------------------*/

    define variable h-acompanhar as handle   no-undo.

    run utp/ut-acomp.p persistent set h-acompanhar.
    run pi-inicializar in h-acompanhar (input 'Lendo Mensagens').
    
    empty temp-table tt-thl-mensagem no-error.    

    for each thl-objeto no-lock
        where thl-objeto.aplicacao >= aplicacao-ini
          and thl-objeto.aplicacao <= aplicacao-fin
          and thl-objeto.objeto    >= objeto-ini          
          and thl-objeto.objeto    <= objeto-fin 
          and can-find( first thl-objeto-usuario no-lock
                            where thl-objeto-usuario.objeto      = thl-objeto.objeto
                              and thl-objeto-usuario.cod-usuario = c-seg-usuario ),
        each thl-mensagem no-lock
            where thl-mensagem.objeto           = thl-objeto.objeto
              and thl-mensagem.operacao        >= operacao-ini
              and thl-mensagem.operacao        <= operacao-fin
              and thl-mensagem.dt-criacao      >= dt-criacao-ini
              and thl-mensagem.dt-criacao      <= dt-criacao-fin
              and thl-mensagem.dt-integracao   >= dt-integracao-ini
              and thl-mensagem.dt-integracao   <= dt-integracao-fin
              and thl-mensagem.codigo-mensagem >= codigo-mensagem-ini
              and thl-mensagem.codigo-mensagem <= codigo-mensagem-fin
              //and can-find( first thl-mensagem-item of thl-mensagem no-lock
                                //where thl-mensagem-item.chave-registro >= chave-registro-ini
                                //  and thl-mensagem-item.chave-registro <= chave-registro-fin 
              //                  )
              .
              
            
        run pi-acompanhar in h-acompanhar ( input thl-mensagem.codigo-mensagem ).             
                   
        create tt-thl-mensagem.
        buffer-copy thl-mensagem to tt-thl-mensagem
            assign tt-thl-mensagem.dispositivo        = thl-objeto.sentido-fluxo
                   tt-thl-mensagem.row-thl-mensagem   = rowid( thl-mensagem )
                   tt-thl-mensagem.aplicacao          = thl-objeto.aplicacao
                   tt-thl-mensagem.desc-integracao    = {thl\include\i03thl011.i 4 thl-objeto.modelo-integracao}
                   tt-thl-mensagem.desc-metodo        = {thl\include\i02thl011.i 4 tt-thl-mensagem.metodo}
                   tt-thl-mensagem.desc-requisicao    = {thl\include\i01thl011.i 4 tt-thl-mensagem.sit-requisicao}
                   tt-thl-mensagem.desc-processamento = {thl\include\i01thl011.i 4 tt-thl-mensagem.sit-processamento} 
                   tt-thl-mensagem.desc-retorno       = {thl\include\i01thl011.i 4 tt-thl-mensagem.sit-retorno }.

    end.

    run pi-finalizar in h-acompanhar.

    {&open-query-brIntegracao}

end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

