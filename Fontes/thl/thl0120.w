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
using System.Diagnostics.*.
using thl-lib.integration.messaging.outbound.service.OutboundMessageService.

{include/i-prgvrs.i thl0120 12.00.00.000}

/* Chamada a include do gerenciador de licencas. Necessario alterar os parametros */
/*                                                                                */
/* <programa>:  Informar qual o nome do programa.                                 */
/* <modulo>:  Informar qual o modulo a qual o programa pertence.                  */

{include/i-license-manager.i thl0120 THL}

create widget-pool.

/* Preprocessors Definitions ---                                      */
&GLOBAL-DEFINE Program        thl0120
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
    field row-thl-mensagem   as rowid
    field dispositivo        as logical
    field desc-integracao    as character 
    field desc-metodo        as character 
    field desc-requisicao    as character
    field desc-retorno       as character
    field desc-processamento as character
    index idx objeto 
              aplicacao
              operacao
              dt-criacao
              dt-integracao.

define variable dWinXC        as decimal                  no-undo.
define variable dWinYC        as decimal                  no-undo.

define variable hConsulta as handle  no-undo.

define new shared variable c-codigo-mensagem
    as character
    no-undo.

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
&Scoped-define FIELDS-IN-QUERY-brIntegracao tt-thl-mensagem.codigo tt-thl-mensagem.objeto tt-thl-mensagem.operacao tt-thl-mensagem.aplicacao tt-thl-mensagem.desc-integracao tt-thl-mensagem.desc-metodo tt-thl-mensagem.dispositivo tt-thl-mensagem.dt-integracao tt-thl-mensagem.dt-criacao tt-thl-mensagem.desc-requisicao tt-thl-mensagem.desc-retorno tt-thl-mensagem.desc-processamento tt-thl-mensagem.destino tt-thl-mensagem.cod-status-retorno tt-thl-mensagem.descr-retorno //enable //tt-thl-mensagem.dt-integracao //tt-thl-mensagem.objeto   
&Scoped-define ENABLED-FIELDS-IN-QUERY-brIntegracao   
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

DEFINE SUB-MENU m_visuar_conteudo 
       MENU-ITEM m_Saida        LABEL "Saida"         
       MENU-ITEM m_Entrada      LABEL "Entrada"       .

DEFINE MENU POPUP-MENU-brIntegracao 
       MENU-ITEM m_reintegrar   LABEL "Reintegrar"    
       RULE
       MENU-ITEM m_Consulta_Mensagem LABEL "Consultar Mensagem"
       MENU-ITEM m_Consulta_TOTVS LABEL "Consultar TOTVS"
       MENU-ITEM m_Consultar_Historico LABEL "Consultar Historico"
       RULE
       SUB-MENU  m_visuar_conteudo LABEL "Visuar Conteudo".


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
      tt-thl-mensagem SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE brIntegracao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS brIntegracao wWindow _FREEFORM
  QUERY brIntegracao DISPLAY
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
    tt-thl-mensagem.descr-retorno        width 10 format 'x(4000)'  
    //enable 
    //tt-thl-mensagem.dt-integracao  
    //tt-thl-mensagem.objeto
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
ON mouse-select-dblclick OF brIntegracao IN FRAME fpage0
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
ON start-search OF brIntegracao IN FRAME fpage0
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
ON choose OF btSelecao IN FRAME fpage0 /* Selecao */
do.
    run thl\thl0120a.w.
    if log-atualizar then
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


&Scoped-define SELF-NAME m_Consultar_Historico
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL m_Consultar_Historico wWindow
ON choose OF MENU-ITEM m_Consultar_Historico /* Consultar Historico */
do:
    /*if available tt-thl-mensagem then do.
        
        assign i-codigo-objeto = tt-thl-mensagem.codigo.

        RUN thl\thl0120h.w PERSISTENT SET hConsulta.

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
ON choose OF MENU-ITEM m_Consulta_Mensagem /* Consultar Mensagem */
do:

    if  available tt-thl-mensagem then do.
        
        assign c-codigo-mensagem = tt-thl-mensagem.codigo-mensagem.

        run thl\thl0120b.w persistent set hConsulta.

        run dispatch         in hConsulta ( input 'initialize':U  ).
        run local-initialize in hConsulta.

        wait-for close of hConsulta.

        delete object  hConsulta no-error.

    end.

end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME m_Consulta_TOTVS
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL m_Consulta_TOTVS wWindow
ON choose OF MENU-ITEM m_Consulta_TOTVS /* Consultar TOTVS */
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


&Scoped-define SELF-NAME m_Entrada
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL m_Entrada wWindow
ON CHOOSE OF MENU-ITEM m_Entrada /* Entrada */
DO:
    run piAbrirConteudo ( 2 ).
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME m_reintegrar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL m_reintegrar wWindow
ON choose OF MENU-ITEM m_reintegrar /* Reintegrar */
do:

    if not available tt-thl-mensagem then return.

    /* Somente mensagens de saida (outbound) podem ser reenviadas */
    if not tt-thl-mensagem.dispositivo then do.
        run utp/ut-msgs.p ( input 'show':U,
                            input 17242,
                            input 'Reenvio disponivel apenas para mensagens de saida (Dispositivo = Saida).' ).
        return.
    end.

    /* Confirmacao do usuario */
    run utp/ut-msgs.p ( input 'show':U,
                        input 27100,
                        input substitute( 'Confirma o reenvio da mensagem &1?',
                                          tt-thl-mensagem.codigo-mensagem ) ).
    if return-value <> 'yes':U then return.

    do on error undo, leave:

        if  new OutboundMessageService( tt-thl-mensagem.aplicacao, tt-thl-mensagem.objeto, tt-thl-mensagem.operacao ):reprocess( tt-thl-mensagem.codigo-mensagem ) then
            run utp/ut-msgs.p ( input 'show':U,
                                input 27979,
                                input 'Mensagem reenviada com sucesso.' ).
        else
            run utp/ut-msgs.p ( input 'show':U,
                                input 27979,
                                input 'Reenvio finalizado com advertencia. Verifique o retorno da mensagem.' ).

    end.
    run piObterInegracao.
    
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME m_Saida
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL m_Saida wWindow
ON CHOOSE OF MENU-ITEM m_Saida /* Saida */
DO:
    run piAbrirConteudo ( 1 ).
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME m_visuar_conteudo
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
       dt-criacao-ini      = add-interval( now, -24, 'hours' )
       dt-criacao-fin      = today + 1
       dt-integracao-ini   = add-interval( now, -24, 'hours' )
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE piAbrirConteudo wWindow 
PROCEDURE piAbrirConteudo :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    
    define input  parameter  tipo-conteudo as integer no-undo.
    
    define variable process_    as Process   no-undo.
    define variable arquivo     as character no-undo.
    define variable arquivoJson as character no-undo.
    
    if not available tt-thl-mensagem then return.
    
    find first thl-mensagem-conteudo no-lock
        where thl-mensagem-conteudo.codigo-mensagem = tt-thl-mensagem.codigo-mensagem
          and thl-mensagem-conteudo.tipo-conteudo   = tipo-conteudo 
        no-error. //1 saida

    if available thl-mensagem-conteudo then do.
        
        output to value( substitute( '&1&2', session:temp-directory, 'conteudo.txt' ) ).
        export thl-mensagem-conteudo.conteudo.
        output close.
        
        input from value( substitute( '&1&2', session:temp-directory, 'conteudo.txt' ) ).
        import unformatted arquivo.
        input close.
        
        assign arquivo     = substitute( '&1&2', session:temp-directory, replace( arquivo, '"', '' ) )
               arquivoJson = replace( arquivo, 'blb', 'json').
               
        os-copy value(arquivo) value(arquivoJson).
        
        assign process_ = new Process()
               process_:StartInfo:FileName  = 'chrome.exe'
               process_:StartInfo:Arguments = substitute( '"&1"', arquivoJson).
        
        process_:Start().
        
    end.
    release thl-mensagem-conteudo no-error.
    
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE piObterInegracao wWindow 
PROCEDURE piObterInegracao :
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
                            where thl-objeto-usuario.aplicacao   = thl-objeto.aplicacao
                              and thl-objeto-usuario.objeto      = thl-objeto.objeto
                              and thl-objeto-usuario.cod-usuario = c-seg-usuario ),
        each thl-mensagem no-lock
            where thl-mensagem.objeto           = thl-objeto.objeto
              and thl-mensagem.aplicacao        = thl-objeto.aplicacao 
              and thl-mensagem.operacao        >= operacao-ini
              and thl-mensagem.operacao        <= operacao-fin
              and thl-mensagem.dt-criacao      >= dt-criacao-ini
              and thl-mensagem.dt-criacao      <= dt-criacao-fin
              and thl-mensagem.dt-integracao   >= dt-integracao-ini
              and thl-mensagem.dt-integracao   <= dt-integracao-fin
              and thl-mensagem.codigo-mensagem >= codigo-mensagem-ini
              and thl-mensagem.codigo-mensagem <= codigo-mensagem-fin
              and ( not can-find( first thl-mensagem-item no-lock
                                    where thl-mensagem-item.codigo-mensagem  = thl-mensagem.codigo-mensagem )
               or       can-find( first thl-mensagem-item no-lock
                                    where thl-mensagem-item.codigo-mensagem  = thl-mensagem.codigo-mensagem
                                      and thl-mensagem-item.chave-registro  >= chave-registro-ini
                                      and thl-mensagem-item.chave-registro  <= chave-registro-fin ) 
                  )
              .
            
        run pi-acompanhar in h-acompanhar ( input thl-mensagem.codigo-mensagem ).   
                   
        create tt-thl-mensagem.
        buffer-copy thl-mensagem to tt-thl-mensagem
            assign tt-thl-mensagem.aplicacao          = thl-objeto.aplicacao
                   tt-thl-mensagem.dispositivo        = thl-objeto.sentido-fluxo
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

