&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI
&ANALYZE-RESUME
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
{include/i-prgvrs.i thl0120a 12.00.00.000}

/* Chamada a include do gerenciador de licencas. Necessario alterar os parametros */
/*                                                                                */
/* <programa>:  Informar qual o nome do programa.                                 */
/* <modulo>:  Informar qual o modulo a qual o programa pertence.                  */

{include/i-license-manager.i thl0120a thl}

create widget-pool.

/* Preprocessors Definitions ---                                      */
&GLOBAL-DEFINE Program        thl0120
&GLOBAL-DEFINE Version        12.00.00.0000

&GLOBAL-DEFINE WindowType     Master/Detail

&GLOBAL-DEFINE Folder         NO
&GLOBAL-DEFINE InitialPage    0
&GLOBAL-DEFINE FolderLabels   

&GLOBAL-DEFINE page0Widgets   btOK BtCancel btHelp2 
&GLOBAL-DEFINE page1Widgets   
&GLOBAL-DEFINE page2Widgets   

/* Parameters Definitions ---                                           */
define shared variable codigo-mensagem-ini    like thl-mensagem.codigo-mensagem no-undo.
define shared variable codigo-mensagem-fin    like thl-mensagem.codigo-mensagem no-undo.
define shared variable objeto-ini             like thl-mensagem.objeto          no-undo.
define shared variable objeto-fin             like thl-mensagem.objeto          no-undo.
define shared variable operacao-ini           like thl-mensagem.operacao        no-undo.
define shared variable operacao-fin           like thl-mensagem.operacao        no-undo.
define shared variable aplicacao-ini          like thl-objeto.aplicacao         no-undo.
define shared variable aplicacao-fin          like thl-objeto.aplicacao         no-undo.
define shared variable dt-criacao-ini         like thl-mensagem.dt-criacao      no-undo.
define shared variable dt-criacao-fin         like thl-mensagem.dt-criacao      no-undo.
define shared variable dt-integracao-ini      like thl-mensagem.dt-integracao   no-undo.
define shared variable dt-integracao-fin      like thl-mensagem.dt-integracao   no-undo.
define shared variable chave-registro-ini     like thl-mensagem-item.chave-registro no-undo.
define shared variable chave-registro-fin     like thl-mensagem-item.chave-registro no-undo.

define shared variable log-atualizar as logical no-undo.

define new global shared variable c-seg-usuario as character  format 'x(12)' no-undo.



/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE Window
&Scoped-define DB-AWARE no

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME fpage0

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rtToolBar IMAGE-1 IMAGE-2 IMAGE-3 IMAGE-4 ~
IMAGE-5 IMAGE-6 IMAGE-9 IMAGE-10 IMAGE-30 RECT-2 IMAGE-31 IMAGE-35 IMAGE-36 ~
IMAGE-37 IMAGE-38 fi-codigo-ini fi-codigo-fin fi-objeto-ini fi-objeto-fin ~
fi-operacao-ini fi-operacao-fin fi-aplicacao-ini fi-aplicacao-fin ~
fi-data-criacao-ini fi-data-criacao-fin fi-data-integracao-ini ~
fi-data-integracao-fin fi-chave-ini fi-chave-fin btOK btCancel btHelp2 
&Scoped-Define DISPLAYED-OBJECTS fi-codigo-ini fi-codigo-fin fi-objeto-ini ~
fi-objeto-fin fi-operacao-ini fi-operacao-fin fi-aplicacao-ini ~
fi-aplicacao-fin fi-data-criacao-ini fi-data-criacao-fin ~
fi-data-integracao-ini fi-data-integracao-fin fi-chave-ini fi-chave-fin 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR wWindow AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON btCancel 
     LABEL "Cancelar" 
     SIZE 10 BY 1.

DEFINE BUTTON btHelp2 
     LABEL "Ajuda" 
     SIZE 10 BY 1.

DEFINE BUTTON btOK 
     LABEL "OK" 
     SIZE 10 BY 1.

DEFINE VARIABLE fi-aplicacao-fin AS CHARACTER FORMAT "X(46)":U 
     VIEW-AS FILL-IN 
     SIZE 32 BY .88 NO-UNDO.

DEFINE VARIABLE fi-aplicacao-ini AS CHARACTER FORMAT "X(46)":U 
     LABEL "Aplicacao" 
     VIEW-AS FILL-IN 
     SIZE 32 BY .88 NO-UNDO.

DEFINE VARIABLE fi-chave-fin AS CHARACTER FORMAT "X(30)":U 
     VIEW-AS FILL-IN 
     SIZE 32 BY .88 NO-UNDO.

DEFINE VARIABLE fi-chave-ini AS CHARACTER FORMAT "X(60)":U 
     LABEL "Chave" 
     VIEW-AS FILL-IN 
     SIZE 32 BY .88 NO-UNDO.

DEFINE VARIABLE fi-codigo-fin AS CHARACTER FORMAT "X(46)":U 
     VIEW-AS FILL-IN 
     SIZE 32 BY .88 NO-UNDO.

DEFINE VARIABLE fi-codigo-ini AS CHARACTER FORMAT "X(46)":U 
     LABEL "Codigo" 
     VIEW-AS FILL-IN 
     SIZE 32 BY .88 NO-UNDO.

DEFINE VARIABLE fi-data-criacao-fin AS DATETIME FORMAT "99/99/9999 HH:MM:SS":U 
     VIEW-AS FILL-IN 
     SIZE 21 BY .88 NO-UNDO.

DEFINE VARIABLE fi-data-criacao-ini AS DATETIME FORMAT "99/99/9999 HH:MM:SS":U 
     LABEL "Data Criacao" 
     VIEW-AS FILL-IN 
     SIZE 21 BY .88 NO-UNDO.

DEFINE VARIABLE fi-data-integracao-fin AS DATETIME FORMAT "99/99/9999 HH:MM:SS":U 
     VIEW-AS FILL-IN 
     SIZE 21 BY .88 NO-UNDO.

DEFINE VARIABLE fi-data-integracao-ini AS DATETIME FORMAT "99/99/9999 HH:MM:SS":U 
     LABEL "Data Integracao" 
     VIEW-AS FILL-IN 
     SIZE 21 BY .88 NO-UNDO.

DEFINE VARIABLE fi-objeto-fin AS CHARACTER FORMAT "X(46)":U 
     VIEW-AS FILL-IN 
     SIZE 32 BY .88 NO-UNDO.

DEFINE VARIABLE fi-objeto-ini AS CHARACTER FORMAT "X(46)":U 
     LABEL "Objeto" 
     VIEW-AS FILL-IN 
     SIZE 32 BY .88 NO-UNDO.

DEFINE VARIABLE fi-operacao-fin AS CHARACTER FORMAT "X(46)":U 
     VIEW-AS FILL-IN 
     SIZE 32 BY .88 NO-UNDO.

DEFINE VARIABLE fi-operacao-ini AS CHARACTER FORMAT "X(46)":U 
     LABEL "Operacao" 
     VIEW-AS FILL-IN 
     SIZE 32 BY .88 NO-UNDO.

DEFINE IMAGE IMAGE-1
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-10
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-2
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-3
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-30
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-31
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-35
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-36
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-37
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-38
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-4
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-5
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-6
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-9
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE RECTANGLE RECT-2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 7.25.

DEFINE RECTANGLE rtToolBar
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 88.57 BY 1.42
     BGCOLOR 7 .


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME fpage0
     fi-codigo-ini AT ROW 1.33 COL 12.14 COLON-ALIGNED WIDGET-ID 4
     fi-codigo-fin AT ROW 1.33 COL 55 COLON-ALIGNED NO-LABEL WIDGET-ID 176
     fi-objeto-ini AT ROW 2.33 COL 12.14 COLON-ALIGNED WIDGET-ID 222
     fi-objeto-fin AT ROW 2.33 COL 55 COLON-ALIGNED NO-LABEL WIDGET-ID 220
     fi-operacao-ini AT ROW 3.33 COL 12.14 COLON-ALIGNED WIDGET-ID 226
     fi-operacao-fin AT ROW 3.33 COL 55 COLON-ALIGNED NO-LABEL WIDGET-ID 224
     fi-aplicacao-ini AT ROW 4.33 COL 12.14 COLON-ALIGNED WIDGET-ID 234
     fi-aplicacao-fin AT ROW 4.33 COL 55 COLON-ALIGNED NO-LABEL WIDGET-ID 232
     fi-data-criacao-ini AT ROW 5.33 COL 12.14 COLON-ALIGNED WIDGET-ID 16
     fi-data-criacao-fin AT ROW 5.33 COL 55 COLON-ALIGNED NO-LABEL WIDGET-ID 178
     fi-data-integracao-ini AT ROW 6.33 COL 12.14 COLON-ALIGNED WIDGET-ID 24
     fi-data-integracao-fin AT ROW 6.33 COL 55 COLON-ALIGNED NO-LABEL WIDGET-ID 180
     fi-chave-ini AT ROW 7.33 COL 12.14 COLON-ALIGNED WIDGET-ID 194
     fi-chave-fin AT ROW 7.33 COL 55 COLON-ALIGNED NO-LABEL WIDGET-ID 200
     btOK AT ROW 9.83 COL 3
     btCancel AT ROW 9.83 COL 14
     btHelp2 AT ROW 9.83 COL 79.43
     rtToolBar AT ROW 9.63 COL 1.72
     IMAGE-1 AT ROW 1.33 COL 46.72 WIDGET-ID 84
     IMAGE-2 AT ROW 1.33 COL 53.57 WIDGET-ID 86
     IMAGE-3 AT ROW 2.33 COL 46.72 WIDGET-ID 88
     IMAGE-4 AT ROW 2.33 COL 53.57 WIDGET-ID 90
     IMAGE-5 AT ROW 5.33 COL 46.72 WIDGET-ID 92
     IMAGE-6 AT ROW 5.33 COL 53.57 WIDGET-ID 94
     IMAGE-9 AT ROW 6.33 COL 46.72 WIDGET-ID 100
     IMAGE-10 AT ROW 6.33 COL 53.57 WIDGET-ID 102
     IMAGE-30 AT ROW 7.33 COL 53.57 WIDGET-ID 196
     RECT-2 AT ROW 1.17 COL 1.72 WIDGET-ID 210
     IMAGE-31 AT ROW 7.33 COL 46.72 WIDGET-ID 206
     IMAGE-35 AT ROW 3.33 COL 46.72 WIDGET-ID 228
     IMAGE-36 AT ROW 3.33 COL 53.57 WIDGET-ID 230
     IMAGE-37 AT ROW 4.33 COL 46.72 WIDGET-ID 236
     IMAGE-38 AT ROW 4.33 COL 53.57 WIDGET-ID 238
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 90 BY 10.33
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
         HEIGHT             = 10.42
         WIDTH              = 90
         MAX-HEIGHT         = 22.08
         MAX-WIDTH          = 90
         VIRTUAL-HEIGHT     = 22.08
         VIRTUAL-WIDTH      = 90
         RESIZE             = yes
         SCROLL-BARS        = no
         STATUS-AREA        = yes
         BGCOLOR            = ?
         FGCOLOR            = ?
         KEEP-FRAME-Z-ORDER = yes
         THREE-D            = yes
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.
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
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(wWindow)
THEN wWindow:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

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
or endkey of {&WINDOW-NAME} anywhere do.
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  if this-procedure:persistent then return no-apply.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL wWindow wWindow
ON window-close OF wWindow
do.
  /* This event will close the window and terminate the procedure.  */
  apply "CLOSE":U to this-procedure.
  return no-apply.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btCancel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btCancel wWindow
ON choose OF btCancel IN FRAME fpage0 /* Cancelar */
do.
    apply "CLOSE":U to this-procedure.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btHelp2
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btHelp2 wWindow
ON choose OF btHelp2 IN FRAME fpage0 /* Ajuda */
do.
    {include/ajuda.i}
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btOK
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btOK wWindow
ON choose OF btOK IN FRAME fpage0 /* OK */
do.
    
    assign log-atualizar       = yes
           codigo-mensagem-ini = fi-codigo-ini         :input-value in frame {&frame-name}
           codigo-mensagem-fin = fi-codigo-fin         :input-value in frame {&frame-name}
           objeto-ini          = fi-objeto-ini         :input-value in frame {&frame-name}
           objeto-fin          = fi-objeto-fin         :input-value in frame {&frame-name}
           operacao-ini        = fi-operacao-ini       :input-value in frame {&frame-name} 
           operacao-fin        = fi-operacao-fin       :input-value in frame {&frame-name}
           aplicacao-ini       = fi-aplicacao-ini      :input-value in frame {&frame-name}
           aplicacao-fin       = fi-aplicacao-fin      :input-value in frame {&frame-name}
           dt-criacao-ini      = fi-data-criacao-ini   :input-value in frame {&frame-name}
           dt-criacao-fin      = fi-data-criacao-fin   :input-value in frame {&frame-name}
           dt-integracao-ini   = fi-data-integracao-ini:input-value in frame {&frame-name}
           dt-integracao-fin   = fi-data-integracao-fin:input-value in frame {&frame-name}
           chave-registro-ini  = fi-chave-ini          :input-value in frame {&frame-name} 
           chave-registro-fin  = fi-chave-fin          :input-value in frame {&frame-name}.
           
    apply 'CLOSE':U to this-procedure.

end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK wWindow 


/*:T--- Logica para inicializacao do programam ---*/
{window/mainblock.i}




/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE afterInitializeInterface wWindow 
PROCEDURE afterInitializeInterface :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    
    assign log-atualizar = yes
           fi-codigo-ini         :screen-value in frame {&frame-name} = codigo-mensagem-ini
           fi-codigo-fin         :screen-value in frame {&frame-name} = codigo-mensagem-fin
           fi-objeto-ini         :screen-value in frame {&frame-name} = objeto-ini         
           fi-objeto-fin         :screen-value in frame {&frame-name} = objeto-fin         
           fi-operacao-ini       :screen-value in frame {&frame-name} = operacao-ini       
           fi-operacao-fin       :screen-value in frame {&frame-name} = operacao-fin       
           fi-aplicacao-ini      :screen-value in frame {&frame-name} = aplicacao-ini      
           fi-aplicacao-fin      :screen-value in frame {&frame-name} = aplicacao-fin      
           fi-data-criacao-ini   :screen-value in frame {&frame-name} = string( dt-criacao-ini, "99/99/9999 HH:MM:SS" )
           fi-data-criacao-fin   :screen-value in frame {&frame-name} = string( dt-criacao-fin, "99/99/9999 HH:MM:SS" )
           fi-data-integracao-ini:screen-value in frame {&frame-name} = string( dt-integracao-ini, "99/99/9999 HH:MM:SS" )
           fi-data-integracao-fin:screen-value in frame {&frame-name} = string( dt-integracao-fin, "99/99/9999 HH:MM:SS" )
           fi-chave-ini          :screen-value in frame {&frame-name} = chave-registro-ini 
           fi-chave-fin          :screen-value in frame {&frame-name} = chave-registro-fin
           //
           fi-codigo-ini         :sensitive in frame {&frame-name} = true
           fi-codigo-fin         :sensitive in frame {&frame-name} = true
           fi-objeto-ini         :sensitive in frame {&frame-name} = true         
           fi-objeto-fin         :sensitive in frame {&frame-name} = true         
           fi-operacao-ini       :sensitive in frame {&frame-name} = true       
           fi-operacao-fin       :sensitive in frame {&frame-name} = true       
           fi-aplicacao-ini      :sensitive in frame {&frame-name} = true      
           fi-aplicacao-fin      :sensitive in frame {&frame-name} = true      
           fi-data-criacao-ini   :sensitive in frame {&frame-name} = true 
           fi-data-criacao-fin   :sensitive in frame {&frame-name} = true 
           fi-data-integracao-ini:sensitive in frame {&frame-name} = true
           fi-data-integracao-fin:sensitive in frame {&frame-name} = true 
           fi-chave-ini          :sensitive in frame {&frame-name} = true 
           fi-chave-fin          :sensitive in frame {&frame-name} = true
    .

end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

