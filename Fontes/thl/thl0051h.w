&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME w-window
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS w-window 
/*:T *******************************************************************************
** Copyright TOTVS S.A. (2009)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da TOTVS, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
using thl-lib.util.schema.SchemaUtil.

{include/i-prgvrs.i thl0051h 12.00.00.000}

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

/* Parameters Definitions ---                                           */
define new global shared variable gr-thl-audit-tabela as rowid no-undo.

/* Local Variable Definitions ---                                       */
define temp-table ttFieldSchema no-undo
    field field-name    as character format 'x(30)'
    field data-type_    as character format 'x(30)'
    field field-format  as character format 'x(30)'
    field label_        as character format 'x(30)'
    field column-label_ as character format 'x(30)'
    field mandatory_    as logical
    field extent_       as integer   initial 0
    field initial-value as character format 'x(30)'
    field description_  as character format 'x(30)'
    field field-order   as integer   initial 0
    index ix-order is primary unique field-order.

define temp-table ttFieldSchemaAux no-undo like ttFieldSchema
    field ind-vinculado       as logical
    field nivel-sensibilidade like thl-audit-tabela-campo.nivel-sensibilidade.

define variable contador as integer     no-undo.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE JanelaDetalhe
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME F-Main
&Scoped-define BROWSE-NAME br-source-browse

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES ttFieldSchemaAux

/* Definitions for BROWSE br-source-browse                              */
&Scoped-define FIELDS-IN-QUERY-br-source-browse ttFieldSchemaAux.field-name ttFieldSchemaAux.label_   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-source-browse   
&Scoped-define SELF-NAME br-source-browse
&Scoped-define QUERY-STRING-br-source-browse FOR EACH ttFieldSchemaAux     WHERE NOT ttFieldSchemaAux.ind-vinculado
&Scoped-define OPEN-QUERY-br-source-browse OPEN QUERY {&SELF-NAME} FOR EACH ttFieldSchemaAux     WHERE NOT ttFieldSchemaAux.ind-vinculado.
&Scoped-define TABLES-IN-QUERY-br-source-browse ttFieldSchemaAux
&Scoped-define FIRST-TABLE-IN-QUERY-br-source-browse ttFieldSchemaAux


/* Definitions for BROWSE br-target-browse                              */
&Scoped-define FIELDS-IN-QUERY-br-target-browse ttFieldSchemaAux.field-name ttFieldSchemaAux.label_ ttFieldSchemaAux.nivel-sensibilidade   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-target-browse   
&Scoped-define SELF-NAME br-target-browse
&Scoped-define QUERY-STRING-br-target-browse FOR EACH ttFieldSchemaAux     WHERE ttFieldSchemaAux.ind-vinculado
&Scoped-define OPEN-QUERY-br-target-browse OPEN QUERY {&SELF-NAME} FOR EACH ttFieldSchemaAux     WHERE ttFieldSchemaAux.ind-vinculado.
&Scoped-define TABLES-IN-QUERY-br-target-browse ttFieldSchemaAux
&Scoped-define FIRST-TABLE-IN-QUERY-br-target-browse ttFieldSchemaAux


/* Definitions for FRAME F-Main                                         */
&Scoped-define OPEN-BROWSERS-IN-QUERY-F-Main ~
    ~{&OPEN-QUERY-br-source-browse}~
    ~{&OPEN-QUERY-br-target-browse}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS RECT-1 rt-source-browse rt-source-browse-2 ~
br-source-browse br-target-browse bt-add bt-del bt-Faixa bt-Faixa-2 bt-ok ~
bt-cancelar bt-ajuda 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR w-window AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-add 
     IMAGE-UP FILE "adeicon\next-au":U
     IMAGE-INSENSITIVE FILE "adeicon\next-ai":U
     LABEL "" 
     SIZE 7 BY 1.

DEFINE BUTTON bt-ajuda 
     LABEL "Ajuda" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-cancelar AUTO-END-KEY 
     LABEL "Cancelar" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-del 
     IMAGE-UP FILE "adeicon\prev-au":U
     IMAGE-INSENSITIVE FILE "adeicon\prev-ai":U
     LABEL "" 
     SIZE 7 BY 1.

DEFINE BUTTON bt-Faixa 
     IMAGE-UP FILE "image\im-ran":U
     IMAGE-INSENSITIVE FILE "image\ii-ran":U
     LABEL "Fai&xa" 
     SIZE 4 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-Faixa-2 
     IMAGE-UP FILE "image\im-ran":U
     IMAGE-INSENSITIVE FILE "image\ii-ran":U
     LABEL "Fai&xa" 
     SIZE 4 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "OK" 
     SIZE 10 BY 1.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 87.86 BY 1.38
     BGCOLOR 7 .

DEFINE RECTANGLE rt-source-browse
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 38.57 BY 14.63.

DEFINE RECTANGLE rt-source-browse-2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 38.57 BY 14.58.

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-source-browse FOR 
      ttFieldSchemaAux SCROLLING.

DEFINE QUERY br-target-browse FOR 
      ttFieldSchemaAux SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-source-browse
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-source-browse w-window _FREEFORM
  QUERY br-source-browse DISPLAY
      ttFieldSchemaAux.field-name
      ttFieldSchemaAux.label_
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 36.43 BY 12.71.

DEFINE BROWSE br-target-browse
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-target-browse w-window _FREEFORM
  QUERY br-target-browse DISPLAY
      ttFieldSchemaAux.field-name
      ttFieldSchemaAux.label_
      ttFieldSchemaAux.nivel-sensibilidade
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 36.43 BY 12.71.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME F-Main
     br-source-browse AT ROW 1.79 COL 2.86 WIDGET-ID 200
     br-target-browse AT ROW 1.88 COL 52 WIDGET-ID 300
     bt-add AT ROW 7.71 COL 42 WIDGET-ID 4
     bt-del AT ROW 9.33 COL 42 WIDGET-ID 6
     bt-Faixa AT ROW 14.71 COL 2.72 WIDGET-ID 12
     bt-Faixa-2 AT ROW 14.71 COL 52 WIDGET-ID 16
     bt-ok AT ROW 16.54 COL 3
     bt-cancelar AT ROW 16.54 COL 14
     bt-ajuda AT ROW 16.54 COL 78
     RECT-1 AT ROW 16.33 COL 2
     rt-source-browse AT ROW 1.38 COL 1.86 WIDGET-ID 8
     rt-source-browse-2 AT ROW 1.42 COL 51 WIDGET-ID 10
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 90 BY 17 WIDGET-ID 100.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: JanelaDetalhe
   Allow: Basic,Browse,DB-Fields,Smart,Window,Query
   Container Links: 
   Add Fields to: Neither
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW w-window ASSIGN
         HIDDEN             = YES
         TITLE              = "Campos da Tabela Auditada"
         HEIGHT             = 17
         WIDTH              = 89.86
         MAX-HEIGHT         = 21.13
         MAX-WIDTH          = 114.29
         VIRTUAL-HEIGHT     = 21.13
         VIRTUAL-WIDTH      = 114.29
         RESIZE             = no
         SCROLL-BARS        = no
         STATUS-AREA        = yes
         BGCOLOR            = ?
         FGCOLOR            = ?
         THREE-D            = yes
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB w-window 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/w-window.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW w-window
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME F-Main
   FRAME-NAME                                                           */
/* BROWSE-TAB br-source-browse rt-source-browse-2 F-Main */
/* BROWSE-TAB br-target-browse br-source-browse F-Main */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-window)
THEN w-window:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-source-browse
/* Query rebuild information for BROWSE br-source-browse
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH ttFieldSchemaAux
    WHERE NOT ttFieldSchemaAux.ind-vinculado.
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE br-source-browse */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-target-browse
/* Query rebuild information for BROWSE br-target-browse
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH ttFieldSchemaAux
    WHERE ttFieldSchemaAux.ind-vinculado.
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE br-target-browse */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-window
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-window w-window
ON END-ERROR OF w-window /* Campos da Tabela Auditada */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  IF THIS-PROCEDURE:PERSISTENT THEN RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-window w-window
ON WINDOW-CLOSE OF w-window /* Campos da Tabela Auditada */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-source-browse
&Scoped-define SELF-NAME br-source-browse
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-source-browse w-window
ON VALUE-CHANGED OF br-source-browse IN FRAME F-Main
DO:
  {include/i-frm020.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-target-browse
&Scoped-define SELF-NAME br-target-browse
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-target-browse w-window
ON VALUE-CHANGED OF br-target-browse IN FRAME F-Main
DO:
  {include/i-frm010.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-add
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-add w-window
ON CHOOSE OF bt-add IN FRAME F-Main
DO:

    do contador = 1 to br-source-browse:num-selected-rows.
        if br-source-browse:fetch-selected-row(contador)then
            assign ttFieldSchemaAux.ind-vinculado = true.
    end.
    
    {&OPEN-QUERY-br-source-browse}  
    {&OPEN-QUERY-br-target-browse}
    
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ajuda
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ajuda w-window
ON CHOOSE OF bt-ajuda IN FRAME F-Main /* Ajuda */
OR HELP OF FRAME {&FRAME-NAME}
DO:
  {include/ajuda.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-cancelar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-cancelar w-window
ON CHOOSE OF bt-cancelar IN FRAME F-Main /* Cancelar */
DO:
  apply "close":U to this-procedure.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-del
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-del w-window
ON CHOOSE OF bt-del IN FRAME F-Main
DO:
    
    do contador = 1 to br-target-browse:num-selected-rows.
        if br-target-browse:fetch-selected-row(contador)then
            assign ttFieldSchemaAux.ind-vinculado = false.
    end.
    
    {&OPEN-QUERY-br-source-browse}  
    {&OPEN-QUERY-br-target-browse}
    
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ok
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ok w-window
ON CHOOSE OF bt-ok IN FRAME F-Main /* OK */
DO:
    
    for each ttFieldSchemaAux.
    
        find first thl-audit-tabela-campo no-lock
            where thl-audit-tabela-campo.banco  = thl-audit-tabela.banco
              and thl-audit-tabela-campo.tabela = thl-audit-tabela.tabela
              and thl-audit-tabela-campo.campo  = ttFieldSchemaAux.field-name
            no-error.
    
        if not ttFieldSchemaAux.ind-vinculado then do.
            if available thl-audit-tabela-campo then 
                delete thl-audit-tabela-campo.
        end.
        else do.
            if not available thl-audit-tabela-campo then do.
                create thl-audit-tabela-campo.
                assign thl-audit-tabela-campo.banco  = thl-audit-tabela.banco
                       thl-audit-tabela-campo.tabela = thl-audit-tabela.tabela
                       thl-audit-tabela-campo.campo  = ttFieldSchemaAux.field-name.
            end.
            assign thl-audit-tabela-campo.ind-ativo           = true
                   thl-audit-tabela-campo.nivel-sensibilidade = ttFieldSchemaAux.nivel-sensibilidade.
                
        end.
        
    end.    
    
    apply 'close' to this-procedure.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-source-browse
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-window 


/* ***************************  Main Block  *************************** */

/* Include custom  Main Block code for SmartWindows. */
{src/adm/template/windowmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects w-window  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available w-window  _ADM-ROW-AVAILABLE
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE carregar-infor w-window 
procedure carregar-infor.
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

    define input parameter nome-banco   as character   no-undo.
    define input parameter nome-tabela  as character   no-undo.

    SchemaUtil:getFieldSchema( 'sh' + nome-banco, nome-tabela, output table ttFieldSchema ).
    
    for each ttFieldSchema.
        create ttFieldSchemaAux.
        buffer-copy ttFieldSchema to ttFieldSchemaAux
            assign ttFieldSchemaAux.ind-vinculado = can-find( first thl-audit-tabela-campo no-lock
                                                                where thl-audit-tabela-campo.banco  = nome-banco
                                                                  and thl-audit-tabela-campo.tabela = nome-tabela
                                                                  and thl-audit-tabela-campo.campo  = ttFieldSchema.field-name  ).
    end.


end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI w-window  _DEFAULT-DISABLE
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
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-window)
  THEN DELETE WIDGET w-window.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI w-window  _DEFAULT-ENABLE
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
  ENABLE RECT-1 rt-source-browse rt-source-browse-2 br-source-browse 
         br-target-browse bt-add bt-del bt-Faixa bt-Faixa-2 bt-ok bt-cancelar 
         bt-ajuda 
      WITH FRAME F-Main IN WINDOW w-window.
  {&OPEN-BROWSERS-IN-QUERY-F-Main}
  VIEW w-window.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-destroy w-window 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-exit w-window 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize w-window 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

    //Code placed here will execute PRIOR to standard behavior. */
    {include/win-size.i}
  
    {utp/ut9000.i "thl0051h" "12.00.00.000"}

    //Dispatch standard ADM method.                             */
    RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

    //Code placed here will execute AFTER standard behavior.    */
    FIND FIRST thl-audit-tabela NO-LOCK
        WHERE ROWID(thl-audit-tabela) = gr-thl-audit-tabela NO-ERROR.
    
    RUN carregar-infor ( thl-audit-tabela.banco, thl-audit-tabela.tabela).
    
    {&OPEN-QUERY-br-source-browse}  
    {&OPEN-QUERY-br-target-browse}
    
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records w-window  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "ttFieldSchemaAux"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed w-window 
PROCEDURE state-changed :
/* -----------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
-------------------------------------------------------------*/
  DEFINE INPUT PARAMETER p-issuer-hdl AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER p-state AS CHARACTER NO-UNDO.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

