&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
&Scoped-define WINDOW-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS w-livre 
/*:T *******************************************************************************
** Copyright TOTVS S.A. (2009)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da TOTVS, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i thl1896c 12.00.00.000}

/* Chamada a include do gerenciador de licen‡as. Necessario alterar os parametros */
/*                                                                                */
/* <programa>:  Informar qual o nome do programa.                                 */
/* <m¢dulo>:  Informar qual o m¢dulo a qual o programa pertence.                  */

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
    {include/i-license-manager.i <programa> <m¢dulo>}
&ENDIF

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */
define new global shared variable i-codigo-objeto
    as integer
    no-undo.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE SmartWindow
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-cad

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rt-button rtMain rtMain-2 fi-codigo ~
fi-chave-registro fi-objeto fi-pacote fi-codigo-fila fi-tentativa ~
fi-data-criacao fi-data-integracao fi-status-code fi-destino 
&Scoped-Define DISPLAYED-OBJECTS fi-codigo fi-chave-registro fi-objeto ~
fi-pacote fi-codigo-fila fi-tentativa fi-data-criacao fi-data-integracao ~
cb-metodo cb-retorno cb-requisicao cb-processamento cb-dispositivo ~
fi-status-code fi-destino 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR w-livre AS WIDGET-HANDLE NO-UNDO.

/* Menu Definitions                                                     */
DEFINE SUB-MENU mi-programa 
       MENU-ITEM mi-consultas   LABEL "Co&nsultas"     ACCELERATOR "CTRL-L"
       MENU-ITEM mi-imprimir    LABEL "&Relat¢rios"    ACCELERATOR "CTRL-P"
       RULE
       MENU-ITEM mi-sair        LABEL "&Sair"          ACCELERATOR "CTRL-X".

DEFINE SUB-MENU m_Ajuda 
       MENU-ITEM mi-conteudo    LABEL "&Conteudo"     
       MENU-ITEM mi-sobre       LABEL "&Sobre..."     .

DEFINE MENU m-livre MENUBAR
       SUB-MENU  mi-programa    LABEL "&Nome-do-Programa"
       SUB-MENU  m_Ajuda        LABEL "&Ajuda"        .


/* Definitions of handles for SmartObjects                              */
DEFINE VARIABLE h_folder AS HANDLE NO-UNDO.
DEFINE VARIABLE h_p-exihel AS HANDLE NO-UNDO.
DEFINE VARIABLE h_thl1986c-v01 AS HANDLE NO-UNDO.
DEFINE VARIABLE h_thl1986c-v02 AS HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE VARIABLE cb-dispositivo AS LOGICAL FORMAT "Sa¡da/Entrada" INITIAL NO 
     LABEL "Dispositivo" 
     VIEW-AS COMBO-BOX INNER-LINES 2
     LIST-ITEMS "Yes","No" 
     DROP-DOWN-LIST
     SIZE 18 BY 1 NO-UNDO.

DEFINE VARIABLE cb-metodo AS INTEGER FORMAT "9":U INITIAL 1 
     LABEL "Metodo" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Post",1,
                     "Delete",2,
                     "Get",3,
                     "Update",4,
                     "Insert",5,
                     "Select",6
     DROP-DOWN-LIST
     SIZE 18 BY 1 NO-UNDO.

DEFINE VARIABLE cb-processamento AS INTEGER FORMAT "9":U INITIAL 4 
     LABEL "Processamento" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Pendente",1,
                     "Erro",2,
                     "Sucesso",3,
                     "NÆo Cont‚m",4
     DROP-DOWN-LIST
     SIZE 18 BY 1 NO-UNDO.

DEFINE VARIABLE cb-requisicao AS INTEGER FORMAT "9":U INITIAL 4 
     LABEL "Requisi‡Æo" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Pendente",1,
                     "Erro",2,
                     "Sucesso",3,
                     "NÆo Cont‚m",4
     DROP-DOWN-LIST
     SIZE 18 BY 1 NO-UNDO.

DEFINE VARIABLE cb-retorno AS INTEGER FORMAT "9":U INITIAL 4 
     LABEL "Retorno" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Pendente",1,
                     "Erro",2,
                     "Sucesso",3,
                     "NÆo Cont‚m",4
     DROP-DOWN-LIST
     SIZE 18 BY 1 NO-UNDO.

DEFINE VARIABLE fi-chave-registro AS CHARACTER FORMAT "x(60)" 
     VIEW-AS FILL-IN 
     SIZE 45 BY .88.

DEFINE VARIABLE fi-codigo AS INTEGER FORMAT ">>>>>>>9" INITIAL 0 
     LABEL "Codigo" 
     VIEW-AS FILL-IN 
     SIZE 6.86 BY .88.

DEFINE VARIABLE fi-codigo-fila AS INT64 FORMAT ">>>>>>>>>>9" INITIAL 0 
     LABEL "ID Fila" 
     VIEW-AS FILL-IN 
     SIZE 9 BY .88.

DEFINE VARIABLE fi-data-criacao AS DATETIME FORMAT "99/99/9999 HH:MM:SS" 
     LABEL "Data Criacao" 
     VIEW-AS FILL-IN 
     SIZE 21 BY .88.

DEFINE VARIABLE fi-data-integracao AS DATETIME FORMAT "99/99/9999 HH:MM:SS" 
     LABEL "Data Integracao" 
     VIEW-AS FILL-IN 
     SIZE 21 BY .88.

DEFINE VARIABLE fi-destino AS CHARACTER FORMAT "X(256)":U 
     LABEL "Destino" 
     VIEW-AS FILL-IN 
     SIZE 50 BY .88 NO-UNDO.

DEFINE VARIABLE fi-objeto AS CHARACTER FORMAT "x(80)" 
     LABEL "Objeto" 
     VIEW-AS FILL-IN 
     SIZE 20 BY .88.

DEFINE VARIABLE fi-pacote AS CHARACTER FORMAT "x(80)" 
     LABEL "Pacote" 
     VIEW-AS FILL-IN 
     SIZE 20 BY .88.

DEFINE VARIABLE fi-status-code AS INTEGER FORMAT ">>>9":U INITIAL 0 
     LABEL "Status Code" 
     VIEW-AS FILL-IN 
     SIZE 6.57 BY .88 NO-UNDO.

DEFINE VARIABLE fi-tentativa AS INTEGER FORMAT ">>>>>>9" INITIAL 0 
     LABEL "Tentativa" 
     VIEW-AS FILL-IN 
     SIZE 6.14 BY .88.

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 88.57 BY 1.46
     BGCOLOR 7 .

DEFINE RECTANGLE rtMain
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 1.25.

DEFINE RECTANGLE rtMain-2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 7.25.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     fi-codigo AT ROW 2.92 COL 14 COLON-ALIGNED WIDGET-ID 10
     fi-chave-registro AT ROW 2.92 COL 21.14 COLON-ALIGNED NO-LABEL WIDGET-ID 8
     fi-objeto AT ROW 4.42 COL 14 COLON-ALIGNED WIDGET-ID 36
     fi-pacote AT ROW 4.42 COL 66 COLON-ALIGNED WIDGET-ID 38
     fi-codigo-fila AT ROW 5.42 COL 14 COLON-ALIGNED WIDGET-ID 12
     fi-tentativa AT ROW 5.42 COL 66 COLON-ALIGNED WIDGET-ID 40
     fi-data-criacao AT ROW 6.42 COL 14 COLON-ALIGNED WIDGET-ID 14
     fi-data-integracao AT ROW 6.42 COL 66 COLON-ALIGNED WIDGET-ID 16
     cb-metodo AT ROW 7.42 COL 14 COLON-ALIGNED WIDGET-ID 46
     cb-retorno AT ROW 7.42 COL 66 COLON-ALIGNED WIDGET-ID 50
     cb-requisicao AT ROW 8.42 COL 14 COLON-ALIGNED WIDGET-ID 48
     cb-processamento AT ROW 8.42 COL 66 COLON-ALIGNED WIDGET-ID 52
     cb-dispositivo AT ROW 9.42 COL 14 COLON-ALIGNED HELP
          "Dispositivo" WIDGET-ID 62
     fi-status-code AT ROW 9.42 COL 66 COLON-ALIGNED WIDGET-ID 66
     fi-destino AT ROW 10.42 COL 14 COLON-ALIGNED WIDGET-ID 64
     rt-button AT ROW 1.08 COL 1.86
     rtMain AT ROW 2.75 COL 1.86 WIDGET-ID 2
     rtMain-2 AT ROW 4.25 COL 1.86 WIDGET-ID 44
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 90 BY 20.42
         FONT 4 WIDGET-ID 100.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: SmartWindow
   Allow: Basic,Browse,DB-Fields,Query,Smart,Window
   Design Page: 1
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW w-livre ASSIGN
         HIDDEN             = YES
         TITLE              = "Template Livre <Insira complemento>"
         HEIGHT             = 20.42
         WIDTH              = 90
         MAX-HEIGHT         = 24.29
         MAX-WIDTH          = 90
         VIRTUAL-HEIGHT     = 24.29
         VIRTUAL-WIDTH      = 90
         RESIZE             = yes
         SCROLL-BARS        = no
         STATUS-AREA        = yes
         BGCOLOR            = ?
         FGCOLOR            = ?
         THREE-D            = yes
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.

ASSIGN {&WINDOW-NAME}:MENUBAR    = MENU m-livre:HANDLE.
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB w-livre 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/w-livre.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW w-livre
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME f-cad
   FRAME-NAME L-To-R                                                    */
/* SETTINGS FOR COMBO-BOX cb-dispositivo IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR COMBO-BOX cb-metodo IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR COMBO-BOX cb-processamento IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR COMBO-BOX cb-requisicao IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR COMBO-BOX cb-retorno IN FRAME f-cad
   NO-ENABLE                                                            */
ASSIGN 
       fi-chave-registro:READ-ONLY IN FRAME f-cad        = TRUE.

ASSIGN 
       fi-codigo:READ-ONLY IN FRAME f-cad        = TRUE.

ASSIGN 
       fi-codigo-fila:READ-ONLY IN FRAME f-cad        = TRUE.

ASSIGN 
       fi-data-criacao:READ-ONLY IN FRAME f-cad        = TRUE.

ASSIGN 
       fi-data-integracao:READ-ONLY IN FRAME f-cad        = TRUE.

ASSIGN 
       fi-destino:READ-ONLY IN FRAME f-cad        = TRUE.

ASSIGN 
       fi-objeto:READ-ONLY IN FRAME f-cad        = TRUE.

ASSIGN 
       fi-pacote:READ-ONLY IN FRAME f-cad        = TRUE.

ASSIGN 
       fi-status-code:READ-ONLY IN FRAME f-cad        = TRUE.

ASSIGN 
       fi-tentativa:READ-ONLY IN FRAME f-cad        = TRUE.

IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-livre)
THEN w-livre:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON END-ERROR OF w-livre /* Template Livre <Insira complemento> */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON WINDOW-CLOSE OF w-livre /* Template Livre <Insira complemento> */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-consultas
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-consultas w-livre
ON CHOOSE OF MENU-ITEM mi-consultas /* Consultas */
DO:
  RUN pi-consulta IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-conteudo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-conteudo w-livre
ON CHOOSE OF MENU-ITEM mi-conteudo /* Conteudo */
OR HELP OF FRAME {&FRAME-NAME}
DO:
  RUN pi-ajuda IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-imprimir
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-imprimir w-livre
ON CHOOSE OF MENU-ITEM mi-imprimir /* Relat¢rios */
DO:
  RUN pi-imprimir IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-programa
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-programa w-livre
ON MENU-DROP OF MENU mi-programa /* Nome-do-Programa */
DO:
  run pi-disable-menu.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-sair
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-sair w-livre
ON CHOOSE OF MENU-ITEM mi-sair /* Sair */
DO:
  RUN pi-sair IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-sobre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-sobre w-livre
ON CHOOSE OF MENU-ITEM mi-sobre /* Sobre... */
DO:
  {include/sobre.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-livre 


/* ***************************  Main Block  *************************** */

/* Include custom  Main Block code for SmartWindows. */
{src/adm/template/windowmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects w-livre  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/
  DEFINE VARIABLE adm-current-page  AS INTEGER NO-UNDO.

  RUN get-attribute IN THIS-PROCEDURE ('Current-Page':U).
  ASSIGN adm-current-page = INTEGER(RETURN-VALUE).

  CASE adm-current-page: 

    WHEN 0 THEN DO:
       RUN init-object IN THIS-PROCEDURE (
             INPUT  'panel/p-exihel.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'Edge-Pixels = 2,
                     SmartPanelType = NAV-ICON,
                     Right-to-Left = First-On-Left':U ,
             OUTPUT h_p-exihel ).
       RUN set-position IN h_p-exihel ( 1.21 , 73.57 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 16.00 ) */

       RUN init-object IN THIS-PROCEDURE (
             INPUT  'adm/objects/folder.r':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'FOLDER-LABELS = ':U + 'Requisi‡Æo|Retorno' + ',
                     FOLDER-TAB-TYPE = 1':U ,
             OUTPUT h_folder ).
       RUN set-position IN h_folder ( 11.75 , 2.00 ) NO-ERROR.
       RUN set-size IN h_folder ( 9.50 , 88.57 ) NO-ERROR.

       /* Links to SmartPanel h_p-exihel. */
       RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , THIS-PROCEDURE ).

       /* Links to SmartFolder h_folder. */
       RUN add-link IN adm-broker-hdl ( h_folder , 'Page':U , THIS-PROCEDURE ).

       /* Adjust the tab order of the smart objects. */
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-exihel ,
             fi-codigo:HANDLE IN FRAME f-cad , 'BEFORE':U ).
       RUN adjust-tab-order IN adm-broker-hdl ( h_folder ,
             fi-destino:HANDLE IN FRAME f-cad , 'AFTER':U ).
    END. /* Page 0 */
    WHEN 1 THEN DO:
       RUN init-object IN THIS-PROCEDURE (
             INPUT  'thl/thl1986c-v01.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  '':U ,
             OUTPUT h_thl1986c-v01 ).
       /* Position in AB:  ( 13.08 , 3.29 ) */
       /* Size in UIB:  ( 7.75 , 84.00 ) */

    END. /* Page 1 */
    WHEN 2 THEN DO:
       RUN init-object IN THIS-PROCEDURE (
             INPUT  'thl/thl1986c-v02.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  '':U ,
             OUTPUT h_thl1986c-v02 ).
       /* Position in AB:  ( 13.08 , 3.29 ) */
       /* Size in UIB:  ( 7.75 , 84.00 ) */

       /* Adjust the tab order of the smart objects. */
    END. /* Page 2 */

  END CASE.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available w-livre  _ADM-ROW-AVAILABLE
PROCEDURE adm-row-available :
/*------------------------------------------------------------------------------
  Purpose:     Dispatched to this procedure when the Record-
               Source has a new row available.  This procedure
               tries to get the new row (or foriegn keys) from
               the Record-Source and process it.
  Parameters:  <none>
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.             */
  {src/adm/template/row-head.i}

  /* Process the newly available records (i.e. display fields,
     open queries, and/or pass records on to any RECORD-TARGETS).    */
  {src/adm/template/row-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI w-livre  _DEFAULT-DISABLE
PROCEDURE disable_UI :
/*------------------------------------------------------------------------------
  Purpose:     DISABLE the User Interface
  Parameters:  <none>
  Notes:       Here we clean-up the user-interface by deleting
               dynamic widgets we have created and/or hide 
               frames.  This procedure is usually called when
               we are ready to "clean-up" after running.
------------------------------------------------------------------------------*/
  /* Delete the WINDOW we created */
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-livre)
  THEN DELETE WIDGET w-livre.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI w-livre  _DEFAULT-ENABLE
PROCEDURE enable_UI :
/*------------------------------------------------------------------------------
  Purpose:     ENABLE the User Interface
  Parameters:  <none>
  Notes:       Here we display/view/enable the widgets in the
               user-interface.  In addition, OPEN all queries
               associated with each FRAME and BROWSE.
               These statements here are based on the "Other 
               Settings" section of the widget Property Sheets.
------------------------------------------------------------------------------*/
  DISPLAY fi-codigo fi-chave-registro fi-objeto fi-pacote fi-codigo-fila 
          fi-tentativa fi-data-criacao fi-data-integracao cb-metodo cb-retorno 
          cb-requisicao cb-processamento cb-dispositivo fi-status-code 
          fi-destino 
      WITH FRAME f-cad IN WINDOW w-livre.
  ENABLE rt-button rtMain rtMain-2 fi-codigo fi-chave-registro fi-objeto 
         fi-pacote fi-codigo-fila fi-tentativa fi-data-criacao 
         fi-data-integracao fi-status-code fi-destino 
      WITH FRAME f-cad IN WINDOW w-livre.
  {&OPEN-BROWSERS-IN-QUERY-f-cad}
  VIEW w-livre.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-destroy w-livre 
PROCEDURE local-destroy :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'destroy':U ) .
  {include/i-logfin.i}

  /* Code placed here will execute AFTER standard behavior.    */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-exit w-livre 
PROCEDURE local-exit :
/* -----------------------------------------------------------
  Purpose:  Starts an "exit" by APPLYing CLOSE event, which starts "destroy".
  Parameters:  <none>
  Notes:    If activated, should APPLY CLOSE, *not* dispatch adm-exit.   
-------------------------------------------------------------*/
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  
  RETURN.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize w-livre 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

    /* Code placed here will execute PRIOR to standard behavior. */
    run pi-before-initialize.
    
    {include/win-size.i}
    
    {utp/ut9000.i "thl1986" "12.00.00.000"}
    
    /* Dispatch standard ADM method.                             */
    RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .
    
    /* Code placed here will execute AFTER standard behavior.    */
    //run pi-after-initialize.
    
    FIND FIRST thl-mensagem NO-LOCK
        WHERE thl-mensagem.codigo = i-codigo-objeto NO-ERROR.

    FIND FIRST thl-objeto no-lock
        WHERE thl-objeto.objeto = thl-mensagem.objeto NO-ERROR.
        
    IF AVAILABLE thl-mensagem THEN
        ASSIGN fi-codigo:SCREEN-VALUE IN FRAME {&FRAME-NAME}            = string( thl-mensagem.codigo )
               fi-chave-registro:SCREEN-VALUE IN FRAME {&FRAME-NAME}    = thl-mensagem.chave-registro
               fi-objeto:SCREEN-VALUE IN FRAME {&FRAME-NAME}            = thl-mensagem.objeto
               fi-pacote:SCREEN-VALUE IN FRAME {&FRAME-NAME}            = thl-mensagem.pacote
               fi-data-criacao:SCREEN-VALUE IN FRAME {&FRAME-NAME}      = string( thl-mensagem.data-criacao )
               cb-metodo:SCREEN-VALUE IN FRAME {&FRAME-NAME}            = string( thl-mensagem.metodo )
               cb-retorno:SCREEN-VALUE IN FRAME {&FRAME-NAME}           = string( '1' )
               cb-requisicao:SCREEN-VALUE IN FRAME {&FRAME-NAME}        = string( '1' )
               cb-processamento:SCREEN-VALUE IN FRAME {&FRAME-NAME}     = string( '4' )
               cb-dispositivo:SCREEN-VALUE IN FRAME {&FRAME-NAME}       = string( thl-objeto.dispositivo )
               fi-chave-registro:SENSITIVE     IN FRAME {&FRAME-NAME}   = YES
               fi-chave-registro:read-only   IN FRAME {&FRAME-NAME}     = YES.
               
    find first thl-historico-mensagem of thl-mensagem no-lock no-error.   
    
    if available  thl-historico-mensagem then DO.
        ASSIGN //ed-corpo-requisicao:screen-value in frame {&FRAME-NAME}  = thl-historico-mensagem.corpo-requisicao
               //ed-corpo-retorno:screen-value in frame {&FRAME-NAME}     = thl-historico-mensagem.corpo-retorno 
               fi-tentativa:SCREEN-VALUE IN FRAME {&FRAME-NAME}         = string( thl-historico-mensagem.tentativa )
               fi-codigo-fila:SCREEN-VALUE IN FRAME {&FRAME-NAME}       = string( thl-historico-mensagem.codigo-fila )
               fi-data-integracao:SCREEN-VALUE IN FRAME {&FRAME-NAME}   = string( thl-historico-mensagem.data-integracao )
               fi-destino:SCREEN-VALUE IN FRAME {&FRAME-NAME}           =         thl-historico-mensagem.destino
               fi-status-code:SCREEN-VALUE IN FRAME {&FRAME-NAME}       = STRING( thl-historico-mensagem.status-code )
               cb-retorno:SCREEN-VALUE IN FRAME {&FRAME-NAME}           = string( thl-historico-mensagem.log-retorno )
               cb-requisicao:SCREEN-VALUE IN FRAME {&FRAME-NAME}        = string( thl-historico-mensagem.log-requisicao )
               cb-processamento:SCREEN-VALUE IN FRAME {&FRAME-NAME}     = string( thl-historico-mensagem.log-processamento ).   
        
        publish 'definir-valor' ( INPUT ROWID(thl-historico-mensagem) ).

    END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records w-livre  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* SEND-RECORDS does nothing because there are no External
     Tables specified for this SmartWindow, and there are no
     tables specified in any contained Browse, Query, or Frame. */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed w-livre 
PROCEDURE state-changed :
/*:T -----------------------------------------------------------
  Purpose:     Manuseia trocas de estado dos SmartObjects
  Parameters:  <none>
  Notes:       
-------------------------------------------------------------*/
  DEFINE INPUT PARAMETER p-issuer-hdl AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER p-state AS CHARACTER NO-UNDO.

  run pi-trata-state (p-issuer-hdl, p-state).
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

