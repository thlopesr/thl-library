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

{include/i-prgvrs.i thl0110 12.00.00.000}

/* Chamada a include do gerenciador de licencas. Necessario alterar os parametros */
/*                                                                                */
/* <programa>:  Informar qual o nome do programa.                                 */
/* <modulo>:  Informar qual o modulo a qual o programa pertence.                  */

{include/i-license-manager.i thl0110 thl}

create widget-pool.

/* Preprocessors Definitions ---                                      */
&GLOBAL-DEFINE Program        thl0110
&GLOBAL-DEFINE Version        12.00.00.0000

&GLOBAL-DEFINE WindowType     Master/Detail

&GLOBAL-DEFINE Folder         NO
&GLOBAL-DEFINE InitialPage    0 
&GLOBAL-DEFINE FolderLabels   

&GLOBAL-DEFINE page0Widgets   brIntegracao btQueryJoins btReportsJoins btExit btHelp btSelecao
&GLOBAL-DEFINE page1Widgets   
&GLOBAL-DEFINE page2Widgets   

/* Parameters Definitions ---                                           */
define new global shared variable h-facelift as handle no-undo.

define new global shared variable i-codigo-objeto
    as integer
    no-undo.

/* Local Variable Definitions ---                                       */
define temp-table tt-thl-email no-undo like thl-email
    field situacao as character.

define new shared variable id-ini             like thl-email.id             no-undo.
define new shared variable id-fin             like thl-email.id             no-undo initial 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'.
define new shared variable data-envio-ini     like thl-email.data-envio     no-undo.
define new shared variable data-envio-fin     like thl-email.data-envio     no-undo.
define new shared variable cod-prog-dtsul-ini like thl-email.cod-prog-dtsul no-undo.
define new shared variable cod-prog-dtsul-fin like thl-email.cod-prog-dtsul no-undo initial 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'.

define new shared variable log_atualizar as logical no-undo.

define new global shared variable c-seg-usuario as character  format 'x(12)' no-undo.

define variable dWinXC        as decimal                  no-undo.
define variable dWinYC        as decimal                  no-undo.

DEFINE VARIABLE hConsulta AS HANDLE  NO-UNDO.

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
&Scoped-define INTERNAL-TABLES tt-thl-email

/* Definitions for BROWSE brIntegracao                                  */
&Scoped-define FIELDS-IN-QUERY-brIntegracao tt-thl-email.id tt-thl-email.data-envio tt-thl-email.cod-prog-dtsul tt-thl-email.remetente tt-thl-email.destino tt-thl-email.assunto tt-thl-email.arq-anexo tt-thl-email.log-envio tt-thl-email.situacao colmun-label 'Situacao' tt-thl-email.mensagem tt-thl-email.retorno   
&Scoped-define ENABLED-FIELDS-IN-QUERY-brIntegracao tt-thl-email.id   tt-thl-email.data-envio ~
tt-thl-email.cod-prog-dtsul   
&Scoped-define ENABLED-TABLES-IN-QUERY-brIntegracao tt-thl-email
&Scoped-define FIRST-ENABLED-TABLE-IN-QUERY-brIntegracao tt-thl-email
&Scoped-define SELF-NAME brIntegracao
&Scoped-define QUERY-STRING-brIntegracao FOR EACH tt-thl-email
&Scoped-define OPEN-QUERY-brIntegracao OPEN QUERY {&SELF-NAME} FOR EACH tt-thl-email.
&Scoped-define TABLES-IN-QUERY-brIntegracao tt-thl-email
&Scoped-define FIRST-TABLE-IN-QUERY-brIntegracao tt-thl-email


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
DEFINE VAR wWindow AS WIDGET-HANDLE NO-UNDO.

/* Menu Definitions                                                     */
DEFINE SUB-MENU smFile 
       MENU-ITEM miQueryJoins   LABEL "&Consultas"    
       MENU-ITEM miReportsJoins LABEL "&Relatorios"   
       RULE
       MENU-ITEM miExit         LABEL "&Sair"          ACCELERATOR "CTRL-X".

DEFINE SUB-MENU smHelp 
       MENU-ITEM miContents     LABEL "&Conteudo"     
       MENU-ITEM miAbout        LABEL "&Sobre..."     .

DEFINE MENU mbMain MENUBAR
       SUB-MENU  smFile         LABEL "&Arquivo"      
       SUB-MENU  smHelp         LABEL "&Ajuda"        .

DEFINE MENU POPUP-MENU-brIntegracao 
       MENU-ITEM m_Integrao     LABEL "Integrar"      
       RULE
       MENU-ITEM m_Consulta_Mensagem LABEL "Consultar Mensagem"
       MENU-ITEM m_Consulta_TOTVS LABEL "Consultar TOTVS"
       MENU-ITEM m_Consultar_Historico LABEL "Consultar Historico"
       RULE
       MENU-ITEM m_Gerar_Contedo_Integrao LABEL "Gerar Conteudo Integracao".


/* Definitions of the field level widgets                               */
DEFINE BUTTON btExit 
     IMAGE-UP FILE "image\im-exi":U
     IMAGE-INSENSITIVE FILE "image\ii-exi":U
     LABEL "Exit" 
     SIZE 4 BY 1.25
     FONT 4.

DEFINE BUTTON btHelp 
     IMAGE-UP FILE "image\im-hel":U
     IMAGE-INSENSITIVE FILE "image\ii-hel":U
     LABEL "Help" 
     SIZE 4 BY 1.25
     FONT 4.

DEFINE BUTTON btQueryJoins 
     IMAGE-UP FILE "image\im-joi":U
     IMAGE-INSENSITIVE FILE "image\ii-joi":U
     LABEL "Query Joins" 
     SIZE 4 BY 1.25
     FONT 4.

DEFINE BUTTON btReportsJoins 
     IMAGE-UP FILE "image\im-pri":U
     IMAGE-INSENSITIVE FILE "image\ii-pri":U
     LABEL "Reports Joins" 
     SIZE 4 BY 1.25
     FONT 4.

DEFINE BUTTON btSelecao 
     IMAGE-UP FILE "image\im-ran":U
     IMAGE-INSENSITIVE FILE "image\ii-ran":U
     LABEL "Selecao" 
     SIZE 4 BY 1.25
     FONT 4.

DEFINE RECTANGLE rtMain
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 15.

DEFINE RECTANGLE rtToolBar
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 88.57 BY 1.5
     BGCOLOR 7 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY brIntegracao FOR 
      tt-thl-email SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE brIntegracao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS brIntegracao wWindow _FREEFORM
  QUERY brIntegracao DISPLAY
    tt-thl-email.id             
    tt-thl-email.data-envio     
    tt-thl-email.cod-prog-dtsul  format 'x(030)'
    tt-thl-email.remetente       format 'x(070)' 
    tt-thl-email.destino         format 'x(100)' 
    tt-thl-email.assunto         format 'x(100)'  
    tt-thl-email.arq-anexo       format 'x(075)' 
    //tt-thl-email.log-envio
    tt-thl-email.situacao        format 'x(012)'  column-label 'Situacao'    
    tt-thl-email.mensagem       
    tt-thl-email.retorno
    tt-thl-email.info-envio
    enable 
    tt-thl-email.id 
    tt-thl-email.data-envio  
    tt-thl-email.cod-prog-dtsul
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 86 BY 14
         FONT 1 ROW-HEIGHT-CHARS .46 FIT-LAST-COLUMN.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME fpage0
     btSelecao AT ROW 1.25 COL 2.72 HELP
          "Parametros de Selecao" WIDGET-ID 6
     btQueryJoins AT ROW 1.25 COL 73.57 HELP
          "Consultas relacionadas"
     btReportsJoins AT ROW 1.25 COL 77.57 HELP
          "Relatorios relacionados"
     btExit AT ROW 1.25 COL 81.57 HELP
          "Sair"
     btHelp AT ROW 1.25 COL 85.57 HELP
          "Ajuda"
     brIntegracao AT ROW 3.25 COL 3 WIDGET-ID 200
     rtToolBar AT ROW 1.08 COL 1.86
     rtMain AT ROW 2.75 COL 1.86 WIDGET-ID 2
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 90 BY 17.21
         FONT 1 WIDGET-ID 100.


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
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW wWindow ASSIGN
         HIDDEN             = YES
         TITLE              = ""
         HEIGHT             = 17
         WIDTH              = 90
         MAX-HEIGHT         = 40.5
         MAX-WIDTH          = 365.72
         VIRTUAL-HEIGHT     = 40.5
         VIRTUAL-WIDTH      = 365.72
         RESIZE             = no
         SCROLL-BARS        = no
         STATUS-AREA        = yes
         BGCOLOR            = ?
         FGCOLOR            = ?
         KEEP-FRAME-Z-ORDER = yes
         THREE-D            = yes
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.

ASSIGN {&WINDOW-NAME}:MENUBAR    = MENU mbMain:HANDLE.
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
ASSIGN 
       brIntegracao:POPUP-MENU IN FRAME fpage0             = MENU POPUP-MENU-brIntegracao:HANDLE.

IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(wWindow)
THEN wWindow:HIDDEN = no.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE brIntegracao
/* Query rebuild information for BROWSE brIntegracao
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH tt-thl-email.
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
ON end-error OF wWindow
or endkey of {&WINDOW-NAME} anywhere do:
        /* This case occurs when the user presses the "Esc" key.
           In a persistently run window, just ignore this.  If we did not, the
           application would exit. */
        if this-procedure:persistent then return no-apply.
    end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL wWindow wWindow
ON window-close OF wWindow
do:
        /* This event will close the window and terminate the procedure.  */
        apply "CLOSE":U to this-procedure.
        return no-apply.
    end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL wWindow wWindow
ON window-maximized OF wWindow
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
ON window-restored OF wWindow
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
ON start-search OF brIntegracao IN FRAME fpage0
do:
    
    define variable columnHandle as handle no-undo.
        
    assign columnHandle = {&BROWSE-NAME}:CURRENT-COLUMN.
    apply 'END-SEARCH' to {&BROWSE-NAME}.

    case columnHandle:name:
        when 'id' then
            open query {&BROWSE-NAME}
                 for each tt-thl-email no-lock by tt-thl-email.id.
        when 'data-envio ' then
            open query {&BROWSE-NAME}
                 for each tt-thl-email no-lock by tt-thl-email.data-envio.
        when 'cod-prog-dtsul' then
            open query {&BROWSE-NAME}
                 for each tt-thl-email no-lock by tt-thl-email.cod-prog-dtsul.
    end case. 

end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btExit
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btExit wWindow
ON choose OF btExit IN FRAME fpage0 /* Exit */
or choose of menu-item miExit in menu mbMain do:
    apply "CLOSE":U to this-procedure.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btHelp
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btHelp wWindow
ON choose OF btHelp IN FRAME fpage0 /* Help */
or choose of menu-item miContents in menu mbMain do:
    {include/ajuda.i}
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btQueryJoins
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btQueryJoins wWindow
ON choose OF btQueryJoins IN FRAME fpage0 /* Query Joins */
or choose of menu-item miQueryJoins in menu mbMain do:
    run showQueryJoins in this-procedure.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btReportsJoins
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btReportsJoins wWindow
ON choose OF btReportsJoins IN FRAME fpage0 /* Reports Joins */
or choose of menu-item miReportsJoins in menu mbMain do:
    run showReportsJoins in this-procedure.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btSelecao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btSelecao wWindow
ON CHOOSE OF btSelecao IN FRAME fpage0 /* Selecao */
do.
    run thl\thl0110a.w.
    if log_atualizar then
        run piObterInegracao.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME miAbout
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL miAbout wWindow
ON choose OF MENU-ITEM miAbout /* Sobre... */
do:
    {include/sobre.i}
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME m_Integrao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL m_Integrao wWindow
ON CHOOSE OF MENU-ITEM m_Integrao /* Integrar */
DO:
    apply 'mouse-select-dblclick' to brIntegracao IN FRAME {&FRAME-NAME}.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK wWindow 


{window/mainblock.i}

//padrao do filtro: ultimas 24 horas; o fim vai ate amanha, para nao perder registro gravado
//com horario a frente do desta sessao (servidor PASOE)
assign data-envio-ini    = add-interval( now, -24, 'hours' )
       data-envio-fin    = today + 1
       dWinXC = wWindow:width-chars
       dWinYC = wWindow:height-chars.

apply "CHOOSE" to btSelecao.


assign tt-thl-email.id            :READ-ONLY in browse {&BROWSE-NAME} = true
       tt-thl-email.data-envio    :READ-ONLY in browse {&BROWSE-NAME} = true
       tt-thl-email.cod-prog-dtsul:READ-ONLY in browse {&BROWSE-NAME} = true.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE piObterInegracao wWindow 
PROCEDURE piObterInegracao :
/*------------------------------------------------------------------------------
      Purpose:     
      Parameters:  <none>
      Notes:       
    ------------------------------------------------------------------------------*/

    define variable h-acompanhar as handle   no-undo.

    run utp/ut-acomp.p persistent set h-acompanhar.
    run pi-inicializar in h-acompanhar (input 'Lendo Integracoes').
    
    empty temp-table tt-thl-email no-error.    

    for each thl-email no-lock
            where thl-email.id              >= id-ini               
              and thl-email.id              <= id-fin       
              and thl-email.data-envio      >= data-envio-ini         
              and thl-email.data-envio      <= data-envio-fin
              and thl-email.cod-prog-dtsul  >= cod-prog-dtsul-ini 
              and thl-email.cod-prog-dtsul  <= cod-prog-dtsul-fin.
            
        run pi-acompanhar in h-acompanhar ( input thl-email.cod-prog-dtsul ).             
                   
        create tt-thl-email.
        buffer-copy thl-email to tt-thl-email
            assign tt-thl-email.situacao = if tt-thl-email.log-envio = 2 then 'Sucesso'
                                                                         else 'Erro'.
            

    end.

    run pi-finalizar in h-acompanhar.

    {&open-query-brIntegracao}

end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

