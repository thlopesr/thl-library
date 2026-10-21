&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
          mg               ORACLE
          mgnitro          ORACLE
*/
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
{include/i-prgvrs.i thl0150 12.00.00.000}

/* Chamada a include do gerenciador de licencas. Necessario alterar os parametros */
/*                                                                                */
/* <programa>:  Informar qual o nome do programa.                                 */
/* <modulo>:  Informar qual o modulo a qual o programa pertence.                  */

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
    {include/i-license-manager.i <programa> <modulo>}
&ENDIF

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

create widget-pool.

/* ***************************  Definitions  ************************** */
define new global shared variable c-seg-usuario as character format 'x(12)' no-undo.

//Parameters Definitions
define new shared variable banco-ini        like thl-audit-registro.banco        no-undo.
define new shared variable banco-fin        like thl-audit-registro.banco        no-undo.
define new shared variable tabela-ini       like thl-audit-registro.tabela       no-undo.
define new shared variable tabela-fin       like thl-audit-registro.tabela       no-undo.
define new shared variable dat-criacao-ini  like thl-audit-registro.data-criacao no-undo.
define new shared variable dat-criacao-fin  like thl-audit-registro.data-criacao no-undo.
define new shared variable usuario-ini      like thl-audit-registro.usuario      no-undo.
define new shared variable usuario-fin      like thl-audit-registro.usuario      no-undo.

define new shared variable log_atualizar as logical no-undo.

//Local Variable Definitions
define variable hObjQry   as handle   no-undo.
define variable hBrowse   as handle   no-undo.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE w-livre
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-cad
&Scoped-define BROWSE-NAME brRegistro

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES thl-audit-tabela-acesso thl-audit-tabela ~
thl-audit-registro

/* Definitions for BROWSE brRegistro                                    */
&Scoped-define FIELDS-IN-QUERY-brRegistro thl-audit-registro.banco ~
thl-audit-registro.tabela thl-audit-registro.data-criacao ~
thl-audit-registro.usuario thl-audit-registro.tipo ~
thl-audit-registro.campos thl-audit-registro.referencia 
&Scoped-define ENABLED-FIELDS-IN-QUERY-brRegistro 
&Scoped-define QUERY-STRING-brRegistro FOR EACH thl-audit-tabela-acesso ~
      WHERE thl-audit-tabela-acesso.cod-usuario = c-seg-usuario ~
and thl-audit-tabela-acesso.ind-ativo ~
and thl-audit-tabela-acesso.banco >= banco-ini ~
and thl-audit-tabela-acesso.banco <= banco-fin ~
and thl-audit-tabela-acesso.tabela >= tabela-ini ~
and thl-audit-tabela-acesso.tabela <= tabela-fin NO-LOCK, ~
      FIRST thl-audit-tabela WHERE thl-audit-tabela.banco = thl-audit-tabela-acesso.banco ~
  AND thl-audit-tabela.tabela = thl-audit-tabela-acesso.tabela ~
  AND thl-audit-tabela.nivel-sensibilidade <= thl-audit-tabela-acesso.nivel-acesso NO-LOCK, ~
      EACH thl-audit-registro WHERE thl-audit-registro.banco = 'sh' + thl-audit-tabela.banco ~
  AND thl-audit-registro.tabela = thl-audit-tabela.tabela ~
      AND thl-audit-registro.data-criacao >= dat-criacao-ini and ~
mgnitro.thl-audit-registro.data-criacao <= dat-criacao-fin and ~
mgnitro.thl-audit-registro.usuario      >= usuario-ini and ~
mgnitro.thl-audit-registro.usuario      <= usuario-fin ~
 ~
 NO-LOCK INDEXED-REPOSITION
&Scoped-define OPEN-QUERY-brRegistro OPEN QUERY brRegistro FOR EACH thl-audit-tabela-acesso ~
      WHERE thl-audit-tabela-acesso.cod-usuario = c-seg-usuario ~
and thl-audit-tabela-acesso.ind-ativo ~
and thl-audit-tabela-acesso.banco >= banco-ini ~
and thl-audit-tabela-acesso.banco <= banco-fin ~
and thl-audit-tabela-acesso.tabela >= tabela-ini ~
and thl-audit-tabela-acesso.tabela <= tabela-fin NO-LOCK, ~
      FIRST thl-audit-tabela WHERE thl-audit-tabela.banco = thl-audit-tabela-acesso.banco ~
  AND thl-audit-tabela.tabela = thl-audit-tabela-acesso.tabela ~
  AND thl-audit-tabela.nivel-sensibilidade <= thl-audit-tabela-acesso.nivel-acesso NO-LOCK, ~
      EACH thl-audit-registro WHERE thl-audit-registro.banco = 'sh' + thl-audit-tabela.banco ~
  AND thl-audit-registro.tabela = thl-audit-tabela.tabela ~
      AND thl-audit-registro.data-criacao >= dat-criacao-ini and ~
mgnitro.thl-audit-registro.data-criacao <= dat-criacao-fin and ~
mgnitro.thl-audit-registro.usuario      >= usuario-ini and ~
mgnitro.thl-audit-registro.usuario      <= usuario-fin ~
 ~
 NO-LOCK INDEXED-REPOSITION.
&Scoped-define TABLES-IN-QUERY-brRegistro thl-audit-tabela-acesso ~
thl-audit-tabela thl-audit-registro
&Scoped-define FIRST-TABLE-IN-QUERY-brRegistro thl-audit-tabela-acesso
&Scoped-define SECOND-TABLE-IN-QUERY-brRegistro thl-audit-tabela
&Scoped-define THIRD-TABLE-IN-QUERY-brRegistro thl-audit-registro


/* Definitions for FRAME f-cad                                          */
&Scoped-define OPEN-BROWSERS-IN-QUERY-f-cad ~
    ~{&OPEN-QUERY-brRegistro}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rt-button RECT-1 RECT-2 btSelecao brRegistro 

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
       MENU-ITEM mi-imprimir    LABEL "&Relatorios"    ACCELERATOR "CTRL-P"
       RULE
       MENU-ITEM mi-sair        LABEL "&Sair"          ACCELERATOR "CTRL-X".

DEFINE SUB-MENU m_Ajuda 
       MENU-ITEM mi-conteudo    LABEL "&Conteudo"     
       MENU-ITEM mi-sobre       LABEL "&Sobre..."     .

DEFINE MENU m-livre MENUBAR
       SUB-MENU  mi-programa    LABEL "&Nome-do-Programa"
       SUB-MENU  m_Ajuda        LABEL "&Ajuda"        .


/* Definitions of handles for SmartObjects                              */
DEFINE VARIABLE h_p-exihel AS HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON btSelecao 
     IMAGE-UP FILE "image\im-ran":U
     IMAGE-INSENSITIVE FILE "image\ii-ran":U
     LABEL "Selecao" 
     SIZE 4 BY 1.25
     FONT 4.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 13.

DEFINE RECTANGLE RECT-2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 4.

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 88.57 BY 1.46
     BGCOLOR 7 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY brRegistro FOR 
      thl-audit-tabela-acesso
    FIELDS(), 
      thl-audit-tabela, 
      thl-audit-registro SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE brRegistro
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS brRegistro w-livre _STRUCTURED
  QUERY brRegistro NO-LOCK DISPLAY
      thl-audit-registro.banco COLUMN-LABEL "Banco" FORMAT "x(100)":U
            WIDTH 10
      thl-audit-registro.tabela FORMAT "x(100)":U WIDTH 12.57
      thl-audit-registro.data-criacao FORMAT "99/99/9999 HH:MM:SS":U
      thl-audit-registro.usuario FORMAT "x(100)":U WIDTH 15
      thl-audit-registro.tipo FORMAT "9":U
      thl-audit-registro.campos FORMAT "x(4000)":U WIDTH 20
      thl-audit-registro.referencia FORMAT "x(400)":U WIDTH 30
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 86 BY 12.13 ROW-HEIGHT-CHARS .5 FIT-LAST-COLUMN.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     btSelecao AT ROW 1.25 COL 2.72 HELP
          "Parametros de Selecao" WIDGET-ID 6
     brRegistro AT ROW 3.17 COL 3 WIDGET-ID 200
     rt-button AT ROW 1.08 COL 1.86
     RECT-1 AT ROW 2.79 COL 1.86 WIDGET-ID 2
     RECT-2 AT ROW 16 COL 1.86 WIDGET-ID 4
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 90 BY 19.38 WIDGET-ID 100.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: w-livre
   Allow: Basic,Browse,DB-Fields,Smart,Window,Query
   Container Links: 
   Add Fields to: Neither
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW w-livre ASSIGN
         HIDDEN             = YES
         TITLE              = "Consulta de Auditoria"
         HEIGHT             = 19.21
         WIDTH              = 90
         MAX-HEIGHT         = 40.5
         MAX-WIDTH          = 365.72
         VIRTUAL-HEIGHT     = 40.5
         VIRTUAL-WIDTH      = 365.72
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
/* BROWSE-TAB brRegistro btSelecao f-cad */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-livre)
THEN w-livre:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE brRegistro
/* Query rebuild information for BROWSE brRegistro
     _TblList          = "mgnitro.thl-audit-tabela-acesso,mgnitro.thl-audit-tabela WHERE mgnitro.thl-audit-tabela-acesso ...,mgnitro.thl-audit-registro WHERE mgnitro.thl-audit-tabela ..."
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _TblOptList       = "USED, FIRST,"
     _Where[1]         = "mgnitro.thl-audit-tabela-acesso.cod-usuario = c-seg-usuario
and mgnitro.thl-audit-tabela-acesso.ind-ativo
and mgnitro.thl-audit-tabela-acesso.banco >= banco-ini
and mgnitro.thl-audit-tabela-acesso.banco <= banco-fin
and mgnitro.thl-audit-tabela-acesso.tabela >= tabela-ini
and mgnitro.thl-audit-tabela-acesso.tabela <= tabela-fin"
     _JoinCode[2]      = "mgnitro.thl-audit-tabela.banco = mgnitro.thl-audit-tabela-acesso.banco
  AND mgnitro.thl-audit-tabela.tabela = mgnitro.thl-audit-tabela-acesso.tabela
  AND mgnitro.thl-audit-tabela.nivel-sensibilidade <= mgnitro.thl-audit-tabela-acesso.nivel-acesso"
     _JoinCode[3]      = "mgnitro.thl-audit-registro.banco = 'sh' + mgnitro.thl-audit-tabela.banco
  AND mgnitro.thl-audit-registro.tabela = mgnitro.thl-audit-tabela.tabela"
     _Where[3]         = "mgnitro.thl-audit-registro.data-criacao >= dat-criacao-ini and
mgnitro.thl-audit-registro.data-criacao <= dat-criacao-fin and
mgnitro.thl-audit-registro.usuario      >= usuario-ini and
mgnitro.thl-audit-registro.usuario      <= usuario-fin

"
     _FldNameList[1]   > mgnitro.thl-audit-registro.banco
"thl-audit-registro.banco" "Banco" ? "character" ? ? ? ? ? ? no ? no no "10" yes no no "U" "" "" "" "" "" "" 0 no 0 no no
     _FldNameList[2]   > mgnitro.thl-audit-registro.tabela
"thl-audit-registro.tabela" ? ? "character" ? ? ? ? ? ? no ? no no "12.57" yes no no "U" "" "" "" "" "" "" 0 no 0 no no
     _FldNameList[3]   > mgnitro.thl-audit-registro.data-criacao
"thl-audit-registro.data-criacao" ? "99/99/9999 HH:MM:SS" "datetime" ? ? ? ? ? ? no ? no no ? yes no no "U" "" "" "" "" "" "" 0 no 0 no no
     _FldNameList[4]   > mgnitro.thl-audit-registro.usuario
"thl-audit-registro.usuario" ? ? "character" ? ? ? ? ? ? no ? no no "15" yes no no "U" "" "" "" "" "" "" 0 no 0 no no
     _FldNameList[5]   = mgnitro.thl-audit-registro.tipo
     _FldNameList[6]   > mgnitro.thl-audit-registro.campos
"thl-audit-registro.campos" ? ? "character" ? ? ? ? ? ? no ? no no "20" yes no no "U" "" "" "" "" "" "" 0 no 0 no no
     _FldNameList[7]   > mgnitro.thl-audit-registro.referencia
"thl-audit-registro.referencia" ? ? "character" ? ? ? ? ? ? no ? no no "30" yes no no "U" "" "" "" "" "" "" 0 no 0 no no
     _Query            is OPENED
*/  /* BROWSE brRegistro */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON END-ERROR OF w-livre /* Consulta de Auditoria */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON WINDOW-CLOSE OF w-livre /* Consulta de Auditoria */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME brRegistro
&Scoped-define SELF-NAME brRegistro
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL brRegistro w-livre
ON VALUE-CHANGED OF brRegistro IN FRAME f-cad
DO:
    RUN pi-carregar-valor. 
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btSelecao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btSelecao w-livre
ON CHOOSE OF btSelecao IN FRAME f-cad /* Selecao */
do.
    run thl\thl0150b.w.
    
    if log_atualizar then
        {&open-query-brRegistro}
        
end.

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
ON CHOOSE OF MENU-ITEM mi-imprimir /* Relatorios */
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
       RUN set-position IN h_p-exihel ( 1.25 , 74.14 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 16.00 ) */

       /* Links to SmartPanel h_p-exihel. */
       RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , THIS-PROCEDURE ).

       /* Adjust the tab order of the smart objects. */
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-exihel ,
             btSelecao:HANDLE IN FRAME f-cad , 'AFTER':U ).
    END. /* Page 0 */

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
  ENABLE rt-button RECT-1 RECT-2 btSelecao brRegistro 
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

    assign banco-fin        = 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'
           tabela-fin       = 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'
           dat-criacao-ini  = add-interval( now, -24, 'hours' )
           dat-criacao-fin  = today + 1
           usuario-fin      = 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'.

    //Code placed here will execute PRIOR to standard behavior
    run pi-before-initialize.

    {include/win-size.i}

    {utp/ut9000.i "thl0150" "12.00.00.000"}

    //Dispatch standard ADM method
    run dispatch in this-procedure ( input 'initialize' ).

    //Code placed here will execute AFTER standard behavior
    run pi-after-initialize.
    
    create browse hBrowse assign
        frame                  = frame {&FRAME-NAME}:handle
        row                    = 16.25
        col                    = 3
        width                  = 86.00
        height                 = 3.40
        allow-column-searching = true
        column-movable         = false
        column-resizable       = true
        column-scrolling       = true
        fit-last-column        = false
        read-only              = true
        row-markers            = false
        separators             = true
        sensitive              = true.
        
end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-carregar-valor w-livre 
PROCEDURE pi-carregar-valor :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    define variable hObjtt    as handle    no-undo.
    define variable iCount    as integer   no-undo.
    define variable fldHandle as handle    no-undo.
    define variable hFile     as handle    no-undo.
    define variable hField    as handle    no-undo.
    define variable value_    as longchar  no-undo.

    create temp-table hObjtt.

    for each thl-audit-registro-detalhe no-lock
        where thl-audit-registro-detalhe.id-registro = thl-audit-registro.id-registro.
        assign value_ = thl-audit-registro-detalhe.valor.
        hObjtt:read-json('LONGCHAR', value_, 'APPEND').
    end.

    if valid-handle(hObjQry)then
        delete object hObjQry  no-error.  
    
    create query hObjQry.
    hObjQry:set-buffers(hObjtt:default-buffer-handle).
    hObjQry:query-prepare( substitute('FOR EACH &1', hObjtt:default-buffer-handle:name ) ).
    hObjQry:query-open().
    
    assign hBrowse:query  = hObjQry.

    //Busca _File no banco correto
    create buffer hFile for table substitute('&1._File', thl-audit-registro.banco) no-error.

    hFile:find-first(
        substitute('WHERE _File._File-name = "&1"', thl-audit-registro.tabela),
        no-lock) no-error.

    if not hFile:available then 
        return.

    do iCount = 1 to hObjtt:default-buffer-handle:num-fields.

        assign fldHandle = hObjtt:default-buffer-handle:buffer-field(iCount).

        if thl-audit-registro.campo <> 'Todos'  and
           thl-audit-registro.campo <> ''       and 
           not thl-audit-registro.campo matches substitute('*&1*', fldHandle:name) then next.
           
        if can-find( first thl-audit-tabela-campo no-lock
                        where thl-audit-tabela-campo.banco  = thl-audit-tabela-acesso.banco
                          and thl-audit-tabela-campo.tabela = thl-audit-tabela-acesso.tabela
                          and thl-audit-tabela-campo.campo  = fldHandle:name
                          and thl-audit-tabela-campo.nivel-sensibilidade > thl-audit-tabela-acesso.nivel-acesso ) then next.    

        create buffer hField for table substitute('&1._Field', thl-audit-registro.banco).

        if valid-handle(hField) then do.
            
            hField:find-first(
                substitute('WHERE _Field._File-recid = &1 AND _Field._Field-name = "&2"',
                    hFile:recid,
                    fldHandle:name),
                no-lock).

            if hField:available then
                assign fldHandle:label  = if hField:buffer-field('_Label'):BUFFER-VALUE <> ? then hField:buffer-field('_Label'):BUFFER-VALUE
                                                                                             else fldHandle:label
                       fldHandle:format = hField:buffer-field('_Format'):BUFFER-VALUE.
            else do.
                case fldHandle:data-type.
                    when 'INTEGER'  then fldHandle:format = '->>,>>>,>>>,>>9'.
                    when 'INT64'    then fldHandle:format = '->>>,>>>,>>>,>>>,>>9'.
                    when 'DECIMAL'  then fldHandle:format = '->>,>>>,>>>,>>9.999999'.
                    when 'DATE'     then fldHandle:format = '99/99/9999'.
                    when 'DATETIME' then fldHandle:format = '99/99/9999 HH:MM:SS'.
                    when 'LOGICAL'  then fldHandle:format = 'Sim/Nao'.
                    otherwise            fldHandle:format = 'x(200)'.
                end case.
            end.

            delete object hField no-error.
        end.

        hBrowse:add-like-column(fldHandle) no-error.

    end.
    
    hBrowse:refresh() no-error.

    finally.
        delete object hFile  no-error.
        delete object hField no-error.
    end finally.
    
end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records w-livre  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "thl-audit-tabela-acesso"}
  {src/adm/template/snd-list.i "thl-audit-tabela"}
  {src/adm/template/snd-list.i "thl-audit-registro"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

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

