&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI
&ANALYZE-RESUME
/* Connected Databases 
          espmulti         PROGRESS
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
{include/i-prgvrs.i thl1986c 12.00.00.000}

/* Chamada a include do gerenciador de licen‡as. Necessario alterar os parametros */
/*                                                                                */
/* <programa>:  Informar qual o nome do programa.                                 */
/* <m¢dulo>:  Informar qual o m¢dulo a qual o programa pertence.                  */

{include/i-license-manager.i thl1986c APB}

create widget-pool.

/* Preprocessors Definitions ---                                      */
&GLOBAL-DEFINE Program        thl1986
&GLOBAL-DEFINE Version        12.00.00.0000

&GLOBAL-DEFINE WindowType     Master/Detail

&GLOBAL-DEFINE Folder         NO
&GLOBAL-DEFINE InitialPage    0
&GLOBAL-DEFINE FolderLabels   

&GLOBAL-DEFINE page0Widgets   btQueryJoins btReportsJoins btExit btHelp
&GLOBAL-DEFINE page1Widgets   
&GLOBAL-DEFINE page2Widgets   

/* Parameters Definitions ---                                           */
define new global shared variable i-codigo-objeto
    as integer
    no-undo.

/* Local Variable Definitions ---                                       */

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE Window
&Scoped-define DB-AWARE no

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME fpage0
&Scoped-define BROWSE-NAME br-historico

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES thl-historico-mensagem

/* Definitions for BROWSE br-historico                                  */
&Scoped-define FIELDS-IN-QUERY-br-historico ~
thl-historico-mensagem.tentativa thl-historico-mensagem.data-criacao ~
thl-historico-mensagem.data-integracao ~
fn-descricao-log(thl-historico-mensagem.log-requisicao) ~
fn-descricao-log( thl-historico-mensagem.log-retorno ) ~
fn-descricao-log(thl-historico-mensagem.log-processamento) ~
thl-historico-mensagem.corpo-requisicao ~
thl-historico-mensagem.corpo-retorno 
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-historico 
&Scoped-define QUERY-STRING-br-historico FOR EACH thl-historico-mensagem ~
      WHERE thl-historico-mensagem.codigo = i-codigo-objeto NO-LOCK INDEXED-REPOSITION
&Scoped-define OPEN-QUERY-br-historico OPEN QUERY br-historico FOR EACH thl-historico-mensagem ~
      WHERE thl-historico-mensagem.codigo = i-codigo-objeto NO-LOCK INDEXED-REPOSITION.
&Scoped-define TABLES-IN-QUERY-br-historico thl-historico-mensagem
&Scoped-define FIRST-TABLE-IN-QUERY-br-historico thl-historico-mensagem


/* Definitions for FRAME fpage0                                         */
&Scoped-define OPEN-BROWSERS-IN-QUERY-fpage0 ~
    ~{&OPEN-QUERY-br-historico}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rtToolBar rtMain rtMain-2 rtMain-3 ~
btQueryJoins btReportsJoins btExit btHelp fi-codigo fi-chave-registro ~
fi-objeto fi-pacote fi-data-integracao br-historico 
&Scoped-Define DISPLAYED-OBJECTS fi-codigo fi-chave-registro fi-objeto ~
fi-pacote fi-data-criacao fi-data-integracao 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME


/* ************************  Function Prototypes ********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD fn-descricao-log wWindow 
FUNCTION fn-descricao-log RETURNS CHARACTER
  ( i-log AS INTEGER )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR wWindow AS WIDGET-HANDLE NO-UNDO.

/* Menu Definitions                                                     */
DEFINE SUB-MENU smFile 
       MENU-ITEM miQueryJoins   LABEL "&Consultas"    
       MENU-ITEM miReportsJoins LABEL "&Relat¢rios"   
       RULE
       MENU-ITEM miExit         LABEL "&Sair"          ACCELERATOR "CTRL-X".

DEFINE SUB-MENU smHelp 
       MENU-ITEM miContents     LABEL "&Conte£do"     
       MENU-ITEM miAbout        LABEL "&Sobre..."     .

DEFINE MENU mbMain MENUBAR
       SUB-MENU  smFile         LABEL "&Arquivo"      
       SUB-MENU  smHelp         LABEL "&Ajuda"        .


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

DEFINE VARIABLE fi-chave-registro AS CHARACTER FORMAT "x(60)" 
     VIEW-AS FILL-IN 
     SIZE 35 BY .88.

DEFINE VARIABLE fi-codigo AS INTEGER FORMAT ">>>>>>>9" INITIAL 0 
     LABEL "Codigo" 
     VIEW-AS FILL-IN 
     SIZE 6.86 BY .88.

DEFINE VARIABLE fi-data-criacao AS DATETIME FORMAT "99/99/9999 HH:MM:SS" 
     LABEL "Data Criacao" 
     VIEW-AS FILL-IN 
     SIZE 21 BY .88.

DEFINE VARIABLE fi-data-integracao AS DATETIME FORMAT "99/99/9999 HH:MM:SS" 
     LABEL "Data Integracao" 
     VIEW-AS FILL-IN 
     SIZE 21 BY .88.

DEFINE VARIABLE fi-objeto AS CHARACTER FORMAT "x(80)" 
     LABEL "Objeto" 
     VIEW-AS FILL-IN 
     SIZE 21 BY .88.

DEFINE VARIABLE fi-pacote AS CHARACTER FORMAT "x(80)" 
     LABEL "Pacote" 
     VIEW-AS FILL-IN 
     SIZE 21 BY .88.

DEFINE RECTANGLE rtMain
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 1.25.

DEFINE RECTANGLE rtMain-2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 2.25.

DEFINE RECTANGLE rtMain-3
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 12.25.

DEFINE RECTANGLE rtToolBar
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 88.57 BY 1.5
     BGCOLOR 7 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-historico FOR 
      thl-historico-mensagem SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-historico
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-historico wWindow _STRUCTURED
  QUERY br-historico NO-LOCK DISPLAY
      thl-historico-mensagem.tentativa FORMAT ">>>>>>9":U
      thl-historico-mensagem.data-criacao FORMAT "99/99/9999 HH:MM:SS.SSS":U
      thl-historico-mensagem.data-integracao FORMAT "99/99/9999 HH:MM:SS.SSS":U
      fn-descricao-log(thl-historico-mensagem.log-requisicao) COLUMN-LABEL "Log. Retorno" FORMAT "x(12)":U
      fn-descricao-log( thl-historico-mensagem.log-retorno ) COLUMN-LABEL "Log. Retorno" FORMAT "x(12)":U
      fn-descricao-log(thl-historico-mensagem.log-processamento) COLUMN-LABEL "Log. Proc." FORMAT "x(12)":U
            WIDTH 11.86
      thl-historico-mensagem.corpo-requisicao FORMAT "x(20000)":U
      thl-historico-mensagem.corpo-retorno FORMAT "x(20000)":U
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 86 BY 11.46
         FONT 1 FIT-LAST-COLUMN.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME fpage0
     btQueryJoins AT ROW 1.25 COL 73.57 HELP
          "Consultas relacionadas"
     btReportsJoins AT ROW 1.25 COL 77.57 HELP
          "Relat¢rios relacionados"
     btExit AT ROW 1.25 COL 81.57 HELP
          "Sair"
     btHelp AT ROW 1.25 COL 85.57 HELP
          "Ajuda"
     fi-codigo AT ROW 2.92 COL 14 COLON-ALIGNED WIDGET-ID 10
     fi-chave-registro AT ROW 2.92 COL 21.14 COLON-ALIGNED NO-LABEL WIDGET-ID 8
     fi-objeto AT ROW 4.42 COL 14 COLON-ALIGNED WIDGET-ID 36
     fi-pacote AT ROW 4.42 COL 62.72 COLON-ALIGNED WIDGET-ID 38
     fi-data-criacao AT ROW 5.42 COL 14 COLON-ALIGNED WIDGET-ID 14
     fi-data-integracao AT ROW 5.42 COL 62.72 COLON-ALIGNED WIDGET-ID 16
     br-historico AT ROW 7.04 COL 3 WIDGET-ID 200
     rtToolBar AT ROW 1.08 COL 1.86
     rtMain AT ROW 2.75 COL 1.86 WIDGET-ID 2
     rtMain-2 AT ROW 4.25 COL 1.86 WIDGET-ID 44
     rtMain-3 AT ROW 6.75 COL 1.86 WIDGET-ID 54
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 90 BY 19.83
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
         HEIGHT             = 18.25
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
/* BROWSE-TAB br-historico fi-data-integracao fpage0 */
/* SETTINGS FOR FILL-IN fi-data-criacao IN FRAME fpage0
   NO-ENABLE                                                            */
ASSIGN 
       fi-data-criacao:READ-ONLY IN FRAME fpage0        = TRUE.

ASSIGN 
       fi-data-integracao:READ-ONLY IN FRAME fpage0        = TRUE.

IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(wWindow)
THEN wWindow:HIDDEN = no.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-historico
/* Query rebuild information for BROWSE br-historico
     _TblList          = "espmulti.thl-historico-mensagem"
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _Where[1]         = "espmulti.thl-historico-mensagem.codigo = i-codigo-objeto"
     _FldNameList[1]   = espmulti.thl-historico-mensagem.tentativa
     _FldNameList[2]   = espmulti.thl-historico-mensagem.data-criacao
     _FldNameList[3]   = espmulti.thl-historico-mensagem.data-integracao
     _FldNameList[4]   > "_<CALC>"
"fn-descricao-log(thl-historico-mensagem.log-requisicao)" "Log. Retorno" "x(12)" ? ? ? ? ? ? ? no ? no no ? yes no no "U" "" "" "" "" "" "" 0 no 0 no no
     _FldNameList[5]   > "_<CALC>"
"fn-descricao-log( thl-historico-mensagem.log-retorno )" "Log. Retorno" "x(12)" ? ? ? ? ? ? ? no ? no no ? yes no no "U" "" "" "" "" "" "" 0 no 0 no no
     _FldNameList[6]   > "_<CALC>"
"fn-descricao-log(thl-historico-mensagem.log-processamento)" "Log. Proc." "x(12)" ? ? ? ? ? ? ? no ? no no "11.86" yes no no "U" "" "" "" "" "" "" 0 no 0 no no
     _FldNameList[7]   = espmulti.thl-historico-mensagem.corpo-requisicao
     _FldNameList[8]   = espmulti.thl-historico-mensagem.corpo-retorno
     _Query            is OPENED
*/  /* BROWSE br-historico */
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
ON WINDOW-CLOSE OF wWindow
do:
    /* This event will close the window and terminate the procedure.  */
    apply "CLOSE":U to this-procedure.
    return no-apply.
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


&Scoped-define SELF-NAME miAbout
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL miAbout wWindow
ON choose OF MENU-ITEM miAbout /* Sobre... */
do:
        {include/sobre.i}
    end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-historico
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK wWindow 


/*:T--- L¢gica para inicializa‡Æo do programam ---*/
{window/mainblock.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize wWindow 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

    FIND FIRST thl-mensagem NO-LOCK
        WHERE thl-mensagem.codigo = i-codigo-objeto NO-ERROR.
        
    IF AVAILABLE thl-mensagem THEN
        ASSIGN fi-codigo:SCREEN-VALUE IN FRAME {&FRAME-NAME}            = string( thl-mensagem.codigo )
               fi-chave-registro:SCREEN-VALUE IN FRAME {&FRAME-NAME}    = thl-mensagem.chave-registro
               fi-objeto:SCREEN-VALUE IN FRAME {&FRAME-NAME}            = thl-mensagem.objeto
               fi-pacote:SCREEN-VALUE IN FRAME {&FRAME-NAME}            = thl-mensagem.pacote
               fi-data-criacao:SCREEN-VALUE IN FRAME {&FRAME-NAME}      = string( thl-mensagem.data-criacao )
               fi-data-integracao:SCREEN-VALUE IN FRAME {&FRAME-NAME}   = string( thl-mensagem.data-integracao )
               br-historico:SENSITIVE IN FRAME {&FRAME-NAME}   = YES.
               
    {&OPEN-QUERY-br-historico}    

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

/* ************************  Function Implementations ***************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION fn-descricao-log wWindow 
FUNCTION fn-descricao-log RETURNS CHARACTER
  ( i-log AS INTEGER ) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/

  RETURN {thl\i01es989.i 4 i-log}.   /* Function return value. */

END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

