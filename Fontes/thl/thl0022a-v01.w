&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
          mg               ORACLE
          mgnitro          ORACLE
*/
&Scoped-define WINDOW-NAME CURRENT-WINDOW
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS V-table-Win 
/*:T *******************************************************************************
** Copyright TOTVS S.A. (2009)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da TOTVS, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
using thl-lib.core.environment.EnvironmentResource.
using thl-extensions.erp.thl.enum.ClassVariableEnum.
using thl-extensions.erp.thl.enum.FieldDefaultEnum.

{include/i-prgvrs.i thl0022a-v01 12.00.00.000}

/* Chamada a include do gerenciador de licencas. Necessario alterar os parametros */
/*                                                                                */
/* <programa>:  Informar qual o nome do programa.                                 */
/* <modulo>:  Informar qual o modulo a qual o programa pertence.                  */
/*                                                                                */
/* OBS: Para os smartobjects o parametro modulo devera ser MUT                    */

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
    {include/i-license-manager.i <programa> MUT}
&ENDIF

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */
&Scop adm-attribute-dlg support/viewerd.w

/* global variable definitions */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */
def var v-row-parent as rowid no-undo.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE SmartViewer
&Scoped-define DB-AWARE no

&Scoped-define ADM-SUPPORTED-LINKS Record-Source,Record-Target,TableIO-Target

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-main

/* External Tables                                                      */
&Scoped-define EXTERNAL-TABLES thl-objeto-parametro
&Scoped-define FIRST-EXTERNAL-TABLE thl-objeto-parametro


/* Need to scope the external tables to this procedure                  */
DEFINE QUERY external_tables FOR thl-objeto-parametro.
/* Standard List Definitions                                            */
&Scoped-Define ENABLED-FIELDS thl-objeto-parametro.ind-inativo ~
thl-objeto-parametro.ind-gera-historico ~
thl-objeto-parametro.tipo-grava-conteudo ~
thl-objeto-parametro.forma-execucao 
&Scoped-define ENABLED-TABLES thl-objeto-parametro
&Scoped-define FIRST-ENABLED-TABLE thl-objeto-parametro
&Scoped-Define ENABLED-OBJECTS rt-key rt-key-2 rt-key-3 rt-key-4 
&Scoped-Define DISPLAYED-FIELDS thl-objeto-parametro.cod-estabel ~
thl-objeto-parametro.operacao thl-objeto-parametro.metodo ~
thl-objeto-parametro.ind-inativo thl-objeto-parametro.ind-gera-historico ~
thl-objeto-parametro.tipo-grava-conteudo ~
thl-objeto-parametro.forma-execucao 
&Scoped-define DISPLAYED-TABLES thl-objeto-parametro
&Scoped-define FIRST-DISPLAYED-TABLE thl-objeto-parametro
&Scoped-Define DISPLAYED-OBJECTS fi-nome-estab 

/* Custom List Definitions                                              */
/* ADM-CREATE-FIELDS,ADM-ASSIGN-FIELDS,ADM-MODIFY-FIELDS,List-4,List-5,List-6 */
&Scoped-define ADM-CREATE-FIELDS thl-objeto-parametro.cod-estabel ~
thl-objeto-parametro.operacao thl-objeto-parametro.metodo 
&Scoped-define ADM-ASSIGN-FIELDS thl-objeto-parametro.cod-estabel ~
thl-objeto-parametro.operacao thl-objeto-parametro.metodo 

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _XFTR "Foreign Keys" V-table-Win _INLINE
/* Actions: ? adm/support/keyedit.w ? ? ? */
/* STRUCTURED-DATA
<KEY-OBJECT>
THIS-PROCEDURE
</KEY-OBJECT>
<FOREIGN-KEYS>
cod-estabel|y|y|mgnitro.thl-objeto-parametro.cod-estabel
cod-param-ambiente||y|mgnitro.thl-objeto-parametro.cod-param-ambiente
objeto||y|mgnitro.thl-objeto-parametro.objeto
</FOREIGN-KEYS> 
<EXECUTING-CODE>
**************************
* Set attributes related to FOREIGN KEYS
*/
RUN set-attribute-list (
    'Keys-Accepted = "cod-estabel",
     Keys-Supplied = "cod-estabel,cod-param-ambiente,objeto"':U).
/**************************
</EXECUTING-CODE> */
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* ***********************  Control Definitions  ********************** */


/* Definitions of the field level widgets                               */
DEFINE VARIABLE fi-nome-estab AS CHARACTER FORMAT "X(40)":U 
     VIEW-AS FILL-IN 
     SIZE 37.57 BY .88 NO-UNDO.

DEFINE RECTANGLE rt-key
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 76.72 BY 3.25.

DEFINE RECTANGLE rt-key-2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 76.72 BY 1.25.

DEFINE RECTANGLE rt-key-3
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 76.72 BY 1.25.

DEFINE RECTANGLE rt-key-4
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 76.72 BY 1.25.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-main
     thl-objeto-parametro.cod-estabel AT ROW 1.17 COL 21 COLON-ALIGNED WIDGET-ID 2
          VIEW-AS FILL-IN 
          SIZE 9.14 BY .88
     fi-nome-estab AT ROW 1.17 COL 30.43 COLON-ALIGNED NO-LABEL WIDGET-ID 90
     thl-objeto-parametro.operacao AT ROW 2.17 COL 21 COLON-ALIGNED WIDGET-ID 12
          VIEW-AS FILL-IN 
          SIZE 47 BY .88
     thl-objeto-parametro.metodo AT ROW 3.17 COL 21 COLON-ALIGNED WIDGET-ID 30
          VIEW-AS COMBO-BOX INNER-LINES 6
          LIST-ITEM-PAIRS "Nao Informado",0,
                     "Post",1,
                     "Put",2,
                     "Patch",3,
                     "Delete",4,
                     "Get",5
          DROP-DOWN-LIST
          SIZE 20 BY 1
     thl-objeto-parametro.ind-inativo AT ROW 4.67 COL 23.14 WIDGET-ID 18
          VIEW-AS TOGGLE-BOX
          SIZE 12 BY .88
     thl-objeto-parametro.ind-gera-historico AT ROW 4.67 COL 53.14 WIDGET-ID 22
          VIEW-AS TOGGLE-BOX
          SIZE 19 BY .88
     thl-objeto-parametro.tipo-grava-conteudo AT ROW 6.17 COL 17.43 NO-LABEL WIDGET-ID 98
          VIEW-AS RADIO-SET HORIZONTAL
          RADIO-BUTTONS 
                    "Sempre", 1,
"Somente em Erro", 2,
"Nunca", 3
          SIZE 54.57 BY .88
     thl-objeto-parametro.forma-execucao AT ROW 7.67 COL 17.57 NO-LABEL WIDGET-ID 24
          VIEW-AS RADIO-SET HORIZONTAL
          RADIO-BUTTONS 
                    "Online", 1,
"Batch", 2,
"Agendar", 3
          SIZE 55.43 BY .88
     "Gravar Conteudo" VIEW-AS TEXT
          SIZE 12 BY .54 AT ROW 5.75 COL 2 WIDGET-ID 102
     "Forma Execucao" VIEW-AS TEXT
          SIZE 12 BY .54 AT ROW 7.29 COL 2 WIDGET-ID 28
     rt-key AT ROW 1 COL 1
     rt-key-2 AT ROW 4.5 COL 1 WIDGET-ID 14
     rt-key-3 AT ROW 7.5 COL 1 WIDGET-ID 16
     rt-key-4 AT ROW 6 COL 1 WIDGET-ID 92
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1 SCROLLABLE 
         FONT 4 WIDGET-ID 100.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: SmartViewer
   External Tables: mgnitro.thl-objeto-parametro
   Allow: Basic,DB-Fields
   Frames: 1
   Add Fields to: EXTERNAL-TABLES
   Other Settings: PERSISTENT-ONLY COMPILE
 */

/* This procedure should always be RUN PERSISTENT.  Report the error,  */
/* then cleanup and return.                                            */
IF NOT THIS-PROCEDURE:PERSISTENT THEN DO:
  MESSAGE "{&FILE-NAME} should only be RUN PERSISTENT.":U
          VIEW-AS ALERT-BOX ERROR BUTTONS OK.
  RETURN.
END.

&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
/* DESIGN Window definition (used by the UIB) 
  CREATE WINDOW V-table-Win ASSIGN
         HEIGHT             = 7.75
         WIDTH              = 76.72.
/* END WINDOW DEFINITION */
                                                                        */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB V-table-Win 
/* ************************* Included-Libraries *********************** */

{src/adm/method/viewer.i}
{include/c-viewer.i}
{utp/ut-glob.i}
{include/i_dbtype.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW V-table-Win
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME f-main
   NOT-VISIBLE FRAME-NAME Size-to-Fit                                   */
ASSIGN 
       FRAME f-main:SCROLLABLE       = FALSE
       FRAME f-main:HIDDEN           = TRUE.

/* SETTINGS FOR FILL-IN thl-objeto-parametro.cod-estabel IN FRAME f-main
   NO-ENABLE 1 2                                                        */
/* SETTINGS FOR FILL-IN fi-nome-estab IN FRAME f-main
   NO-ENABLE                                                            */
/* SETTINGS FOR COMBO-BOX thl-objeto-parametro.metodo IN FRAME f-main
   NO-ENABLE 1 2                                                        */
/* SETTINGS FOR FILL-IN thl-objeto-parametro.operacao IN FRAME f-main
   NO-ENABLE 1 2                                                        */
/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK FRAME f-main
/* Query rebuild information for FRAME f-main
     _Options          = "NO-LOCK"
     _Query            is NOT OPENED
*/  /* FRAME f-main */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME thl-objeto-parametro.cod-estabel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL thl-objeto-parametro.cod-estabel V-table-Win
ON F5 OF thl-objeto-parametro.cod-estabel IN FRAME f-main /* Estabelecimento */
DO:
    {include/zoomvar.i &prog-zoom="adzoom/z01ad107.w"
                       &campo=thl-objeto-parametro.cod-estabel
                       &campozoom=cod-estabel
                       &campo2=fi-nome-estab
                       &campozoom2=nome}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL thl-objeto-parametro.cod-estabel V-table-Win
ON LEAVE OF thl-objeto-parametro.cod-estabel IN FRAME f-main /* Estabelecimento */
DO:
    run pi-nome-estab ( input input frame {&frame-name} thl-objeto-parametro.cod-estabel ).
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL thl-objeto-parametro.cod-estabel V-table-Win
ON MOUSE-SELECT-DBLCLICK OF thl-objeto-parametro.cod-estabel IN FRAME f-main /* Estabelecimento */
DO:
    APPLY 'F5' TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME thl-objeto-parametro.forma-execucao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL thl-objeto-parametro.forma-execucao V-table-Win
ON VALUE-CHANGED OF thl-objeto-parametro.forma-execucao IN FRAME f-main
DO:
    /* a aba Servidor (thl0022a-v04) habilita o servidor conforme a forma de execucao */
    run pi-notifica-forma.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK V-table-Win 


/* ***************************  Main Block  *************************** */

  &IF DEFINED(UIB_IS_RUNNING) <> 0 &THEN          
    RUN dispatch IN THIS-PROCEDURE ('initialize':U).        
  &ENDIF         
  
  /************************ INTERNAL PROCEDURES ********************/

    thl-objeto-parametro.cod-estabel:load-mouse-pointer ("image/lupa.cur") IN FRAME {&FRAME-NAME}.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-find-using-key V-table-Win  adm/support/_key-fnd.p
PROCEDURE adm-find-using-key :
/*------------------------------------------------------------------------------
  Purpose:     Finds the current record using the contents of
               the 'Key-Name' and 'Key-Value' attributes.
  Parameters:  <none>
------------------------------------------------------------------------------*/
  DEF VAR key-value AS CHAR NO-UNDO.
  DEF VAR row-avail-enabled AS LOGICAL NO-UNDO.

  /* LOCK status on the find depends on FIELDS-ENABLED. */
  RUN get-attribute ('FIELDS-ENABLED':U).
  row-avail-enabled = (RETURN-VALUE eq 'yes':U).
  /* Look up the current key-value. */
  RUN get-attribute ('Key-Value':U).
  key-value = RETURN-VALUE.

  /* Find the current record using the current Key-Name. */
  RUN get-attribute ('Key-Name':U).
  CASE RETURN-VALUE:
    WHEN 'cod-estabel':U THEN
       {src/adm/template/find-tbl.i
           &TABLE = thl-objeto-parametro
           &WHERE = "WHERE thl-objeto-parametro.cod-estabel eq key-value"
       }
  END CASE.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available V-table-Win  _ADM-ROW-AVAILABLE
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

  /* Create a list of all the tables that we need to get.            */
  {src/adm/template/row-list.i "thl-objeto-parametro"}

  /* Get the record ROWID's from the RECORD-SOURCE.                  */
  {src/adm/template/row-get.i}

  /* FIND each record specified by the RECORD-SOURCE.                */
  {src/adm/template/row-find.i "thl-objeto-parametro"}

  /* Process the newly available records (i.e. display fields,
     open queries, and/or pass records on to any RECORD-TARGETS).    */
  {src/adm/template/row-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI V-table-Win  _DEFAULT-DISABLE
PROCEDURE disable_UI :
/*------------------------------------------------------------------------------
  Purpose:     DISABLE the User Interface
  Parameters:  <none>
  Notes:       Here we clean-up the user-interface by deleting
               dynamic widgets we have created and/or hide 
               frames.  This procedure is usually called when
               we are ready to "clean-up" after running.
------------------------------------------------------------------------------*/
  /* Hide all frames. */
  HIDE FRAME f-main.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-assign-record V-table-Win 
PROCEDURE local-assign-record :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:
------------------------------------------------------------------------------*/
    define variable v-var-mensagem as ClassVariableEnum no-undo.

    /* Code placed here will execute PRIOR to standard behavior. */
    run pi-validate.
    if return-value = 'ADM-ERROR':U then
        return 'ADM-ERROR':U.
    
    /*:T Ponha na pi-validate todas as validacoes */
    /*:T Nao gravar nada no registro antes do dispatch do assign-record e 
       nem na PI-validate. */
    
    /* Dispatch standard ADM method.                             */
    RUN dispatch IN THIS-PROCEDURE ( INPUT 'assign-record':U ) .
    if RETURN-VALUE = 'ADM-ERROR':U then 
        return 'ADM-ERROR':U.
    
    /*:T Todos os assign's nao feitos pelo assign-record devem ser feitos aqui */  
    /* Code placed here will execute AFTER standard behavior.    */

    /* classes da operacao: nascem copiadas do objeto (thl-objeto) e depois so se alteram na aba
       Classe; em branco, grava as do objeto. A execucao le so a linha da operacao. */
    if available thl-objeto-parametro then do:
        find current thl-objeto-parametro exclusive-lock no-error.
        find first thl-objeto no-lock
            where thl-objeto.aplicacao = thl-objeto-parametro.aplicacao
              and thl-objeto.objeto    = thl-objeto-parametro.objeto no-error.
        if available thl-objeto-parametro and available thl-objeto then do:
            if thl-objeto-parametro.classe-objeto = "" then
                assign thl-objeto-parametro.classe-objeto = thl-objeto.classe-objeto.
            if thl-objeto-parametro.classe-processor = "" then
                assign thl-objeto-parametro.classe-processor = thl-objeto.classe-processor.
            if thl-objeto-parametro.classe-service = "" then
                assign thl-objeto-parametro.classe-service = thl-objeto.classe-service.

            /* ainda em branco (o objeto nao tem a classe): padrao do thl0002, como a API; processor e service so na entrada */
            if thl-objeto-parametro.classe-objeto = "" then do:
                if thl-objeto.sentido-fluxo then
                    assign v-var-mensagem = ClassVariableEnum:MENSAGEM_SAIDA.
                else
                    assign v-var-mensagem = ClassVariableEnum:MENSAGEM_ENTRADA.
                assign thl-objeto-parametro.classe-objeto = new EnvironmentResource():getEnvironmentVariable( v-var-mensagem ) no-error.
            end.
            if not thl-objeto.sentido-fluxo then do:
                if thl-objeto-parametro.classe-processor = "" then
                    assign thl-objeto-parametro.classe-processor = new EnvironmentResource():getEnvironmentVariable( ClassVariableEnum:PROCESSOR_ENTRADA ) no-error.
                if thl-objeto-parametro.classe-service = "" then
                    assign thl-objeto-parametro.classe-service = new EnvironmentResource():getEnvironmentVariable( ClassVariableEnum:SERVICE_ENTRADA ) no-error.
            end.
        end.
    end.


    /* extensao REST: nasce junto com a operacao quando o objeto e REST.
       Os campos dela sao gravados pela aba REST (thl0022a-v05). */
    if available thl-objeto-parametro
       and can-find(thl-objeto where thl-objeto.aplicacao         = thl-objeto-parametro.aplicacao
                                 and thl-objeto.objeto            = thl-objeto-parametro.objeto
                                 and thl-objeto.modelo-integracao = 1)
       and not can-find(thl-objeto-parametro-rest
                        where thl-objeto-parametro-rest.cod-estabel = thl-objeto-parametro.cod-estabel
                          and thl-objeto-parametro-rest.aplicacao   = thl-objeto-parametro.aplicacao
                          and thl-objeto-parametro-rest.objeto      = thl-objeto-parametro.objeto
                          and thl-objeto-parametro-rest.operacao    = thl-objeto-parametro.operacao
                          and thl-objeto-parametro-rest.metodo      = thl-objeto-parametro.metodo) then do:
        create thl-objeto-parametro-rest.
        assign thl-objeto-parametro-rest.cod-estabel = thl-objeto-parametro.cod-estabel
               thl-objeto-parametro-rest.aplicacao   = thl-objeto-parametro.aplicacao
               thl-objeto-parametro-rest.objeto      = thl-objeto-parametro.objeto
               thl-objeto-parametro-rest.operacao    = thl-objeto-parametro.operacao
               thl-objeto-parametro-rest.metodo      = thl-objeto-parametro.metodo.
        release thl-objeto-parametro-rest.
    end.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-create-record V-table-Win 
PROCEDURE local-create-record :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

    RUN dispatch IN THIS-PROCEDURE ( INPUT 'create-record':U ) .
    
    /* Code placed here will execute AFTER standard behavior.    */
    FIND FIRST thl-objeto  no-lock
        where rowid(thl-objeto) = v-row-parent no-error.
            
    if available thl-objeto  THEN
        assign thl-objeto-parametro.objeto    = thl-objeto.objeto 
               thl-objeto-parametro.aplicacao = thl-objeto.aplicacao.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-delete-record V-table-Win 
PROCEDURE local-delete-record :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       A extensao REST da operacao sai junto com ela
------------------------------------------------------------------------------*/

    /* Code placed here will execute PRIOR to standard behavior. */
    if available thl-objeto-parametro then do:
        find thl-objeto-parametro-rest exclusive-lock
            where thl-objeto-parametro-rest.cod-estabel = thl-objeto-parametro.cod-estabel
              and thl-objeto-parametro-rest.aplicacao   = thl-objeto-parametro.aplicacao
              and thl-objeto-parametro-rest.objeto      = thl-objeto-parametro.objeto
              and thl-objeto-parametro-rest.operacao    = thl-objeto-parametro.operacao
              and thl-objeto-parametro-rest.metodo      = thl-objeto-parametro.metodo no-error.
        if available thl-objeto-parametro-rest then
            delete thl-objeto-parametro-rest.
    end.

    /* Dispatch standard ADM method.                             */
    RUN dispatch IN THIS-PROCEDURE ( INPUT 'delete-record':U ) .

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-disable-fields V-table-Win 
PROCEDURE local-disable-fields :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/
    
    /* Code placed here will execute PRIOR to standard behavior. */
    
    /* Dispatch standard ADM method.                             */
    RUN dispatch IN THIS-PROCEDURE ( INPUT 'disable-fields':U ) .
    
    /* Code placed here will execute AFTER standard behavior.    */
    &if  defined(ADM-MODIFY-FIELDS) &then
    disable {&ADM-MODIFY-FIELDS} with frame {&frame-name}.
    &endif
    
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-display-fields V-table-Win 
PROCEDURE local-display-fields :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       Atualiza o nome do estabelecimento a cada registro exibido
------------------------------------------------------------------------------*/

    /* Dispatch standard ADM method.                             */
    RUN dispatch IN THIS-PROCEDURE ( INPUT 'display-fields':U ) .

    run pi-nome-estab ( input if available thl-objeto-parametro
                              then thl-objeto-parametro.cod-estabel else "" ).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-add-record V-table-Win
PROCEDURE local-add-record :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       Inclusao: depois do add-record padrao (adm-new-record = yes, campos habilitados),
               mostra os padroes do thl0002.
------------------------------------------------------------------------------*/

    /* Dispatch standard ADM method.                             */
    RUN dispatch IN THIS-PROCEDURE ( INPUT 'add-record':U ) .
    if RETURN-VALUE = 'ADM-ERROR':U then
        return 'ADM-ERROR':U.

    /* Code placed here will execute AFTER standard behavior.    */
    run pi-padroes-campos.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-enable-fields V-table-Win 
PROCEDURE local-enable-fields :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/
    
    /* Code placed here will execute PRIOR to standard behavior. */
    
    /* Dispatch standard ADM method.                             */
    RUN dispatch IN THIS-PROCEDURE ( INPUT 'enable-fields':U ) .
    
    /* Code placed here will execute AFTER standard behavior.    */
    &if  defined(ADM-MODIFY-FIELDS) &then
    if adm-new-record = yes then
        enable {&ADM-MODIFY-FIELDS} with frame {&frame-name}.
    &endif

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-devolve-forma V-table-Win
PROCEDURE pi-devolve-forma :
/*------------------------------------------------------------------------------
  Purpose:     Devolve a forma de execucao mostrada na tela (1 Online, 2 Batch, 3 Agendar), mesmo
               antes de gravar, para a aba Servidor (thl0022a-v04).
  Parameters:  output forma de execucao (? se nao der para ler)
------------------------------------------------------------------------------*/
    define output parameter i-forma as integer no-undo.

    assign i-forma = integer( thl-objeto-parametro.forma-execucao:screen-value in frame {&frame-name} ) no-error.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-notifica-forma V-table-Win
PROCEDURE pi-notifica-forma :
/*------------------------------------------------------------------------------
  Purpose:     Avisa as abas ligadas por Group-Assign que a forma de execucao mudou.
  Notes:       So a aba Servidor tem pi-habilita-servidor; nas demais o no-error ignora.
------------------------------------------------------------------------------*/
    define variable c-handle as character no-undo.
    define variable h-alvo   as handle    no-undo.
    define variable i-alvo   as integer   no-undo.

    run get-link-handle in adm-broker-hdl ( input this-procedure,
                                            input 'GROUP-ASSIGN-TARGET':U,
                                            output c-handle ) no-error.

    if c-handle = "" or c-handle = ? then
        return.

    do i-alvo = 1 to num-entries( c-handle ):
        assign h-alvo = widget-handle( entry( i-alvo, c-handle ) ) no-error.

        if valid-handle( h-alvo ) then
            run pi-habilita-servidor in h-alvo no-error.
    end.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-devolve-parent V-table-Win
PROCEDURE pi-devolve-parent :
/*------------------------------------------------------------------------------
  Purpose:     Devolve o rowid do objeto (thl0021) desta janela, para a aba Classe (thl0022a-v06)
               mostrar as classes do objeto na inclusao, mesmo sem operacao cadastrada ainda.
  Parameters:  output rowid do thl-objeto
------------------------------------------------------------------------------*/
    define output parameter v-row-parent-saida as rowid no-undo.

    assign v-row-parent-saida = v-row-parent.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-padroes-campos V-table-Win 
PROCEDURE pi-padroes-campos :
/*------------------------------------------------------------------------------
  Purpose:     Inclusao: mostra os padroes do thl0002 (campos da aba Principal da operacao).
  Notes:       Campo sem padrao cadastrado fica com o valor inicial do banco.
------------------------------------------------------------------------------*/
    run pi-padrao-campo ( input thl-objeto-parametro.cod-estabel:handle in frame {&frame-name},
                          input FieldDefaultEnum:OPERACAO_ESTABELECIMENTO ).
    run pi-nome-estab ( input input frame {&frame-name} thl-objeto-parametro.cod-estabel ).
    run pi-padrao-campo ( input thl-objeto-parametro.metodo:handle in frame {&frame-name},
                          input FieldDefaultEnum:OPERACAO_METODO ).
    run pi-padrao-campo ( input thl-objeto-parametro.ind-inativo:handle in frame {&frame-name},
                          input FieldDefaultEnum:OPERACAO_IND_INATIVO ).
    run pi-padrao-campo ( input thl-objeto-parametro.ind-gera-historico:handle in frame {&frame-name},
                          input FieldDefaultEnum:OPERACAO_IND_GERA_HISTORICO ).
    run pi-padrao-campo ( input thl-objeto-parametro.tipo-grava-conteudo:handle in frame {&frame-name},
                          input FieldDefaultEnum:OPERACAO_TIPO_GRAVA_CONTEUDO ).
    run pi-padrao-campo ( input thl-objeto-parametro.forma-execucao:handle in frame {&frame-name},
                          input FieldDefaultEnum:OPERACAO_FORMA_EXECUCAO ).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

{thl/include/i01thl002.i}

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-atualiza-parent V-table-Win 
PROCEDURE pi-atualiza-parent :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    define input parameter v-row-parent-externo as rowid no-undo.
    
    assign v-row-parent = v-row-parent-externo.

    /* a lista do metodo acompanha o tipo do objeto (thl-objeto.modelo-integracao):
       REST = verbos HTTP; Banco = Insert, Update, Select */
    find first thl-objeto no-lock
        where rowid(thl-objeto) = v-row-parent no-error.

    if available thl-objeto and thl-objeto.modelo-integracao = 3 then
        assign thl-objeto-parametro.metodo:list-item-pairs in frame {&frame-name} =
                   "Nao Informado,0,Insert,6,Update,7,Select,8" no-error.
    else
        assign thl-objeto-parametro.metodo:list-item-pairs in frame {&frame-name} =
                   "Nao Informado,0,Post,1,Put,2,Patch,3,Delete,4,Get,5" no-error.
    
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-nome-estab V-table-Win 
PROCEDURE pi-nome-estab :
/*------------------------------------------------------------------------------
  Purpose:     Exibe o nome do estabelecimento (Datasul)
  Notes:       '*' vale para todos os estabelecimentos; a existencia e
               validada no Pi-validate (mensagem 2)
------------------------------------------------------------------------------*/
    define input parameter establishmentCode as character no-undo.

    if establishmentCode = "*" then
        assign fi-nome-estab:screen-value in frame {&frame-name} = "Todos os estabelecimentos".
    else do:
        find estabelec no-lock
            where estabelec.cod-estabel = establishmentCode no-error.
        assign fi-nome-estab:screen-value in frame {&frame-name} =
                   if available estabelec then estabelec.nome else "".
    end.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Pi-validate V-table-Win 
PROCEDURE Pi-validate :
/*:T------------------------------------------------------------------------------
  Purpose:Validar a viewer     
  Parameters:  <none>
  Notes: Nao fazer assign aqui. Nesta procedure
  devem ser colocadas apenas validacoes, pois neste ponto do programa o registro 
  ainda nao foi criado.       
------------------------------------------------------------------------------*/
    {include/i-vldfrm.i} /*:T Validacao de dicionario */
    

    if adm-new-record then do:
        if input frame {&frame-name} thl-objeto-parametro.cod-estabel = "" then do:
            {include/i-vldprg.i}
            run utp/ut-msgs.p (input "show":U, input 17006,
                               input "Estabelecimento nao informado~~Informe o estabelecimento ou * para todos.").
            apply "entry":U to thl-objeto-parametro.cod-estabel in frame {&frame-name}.
            return "ADM-ERROR":U.
        end.
        /* estabelecimento deve existir no Datasul; '*' vale para todos */
        if input frame {&frame-name} thl-objeto-parametro.cod-estabel <> "*"
           and not can-find(estabelec
                            where estabelec.cod-estabel = input frame {&frame-name} thl-objeto-parametro.cod-estabel) then do:
            {include/i-vldprg.i}
            {utp/ut-table.i mgadm estabelec 1}
            run utp/ut-msgs.p (input "show":U, input 2, input return-value).
            apply "entry":U to thl-objeto-parametro.cod-estabel in frame {&frame-name}.
            return "ADM-ERROR":U.
        end.
        /* o metodo faz parte da chave; a lista acompanha o tipo do objeto */
        if input frame {&frame-name} thl-objeto-parametro.metodo < 1 then do:
            {include/i-vldprg.i}
            run utp/ut-msgs.p (input "show":U, input 17006,
                               input "Metodo nao informado~~Informe o metodo da operacao.").
            apply "entry":U to thl-objeto-parametro.metodo in frame {&frame-name}.
            return "ADM-ERROR":U.
        end.
        find first thl-objeto no-lock
            where rowid(thl-objeto) = v-row-parent no-error.
        if available thl-objeto
           and can-find(thl-objeto-parametro where thl-objeto-parametro.cod-estabel = input frame {&frame-name} thl-objeto-parametro.cod-estabel
                             and thl-objeto-parametro.aplicacao   = thl-objeto.aplicacao
                             and thl-objeto-parametro.objeto      = thl-objeto.objeto
                             and thl-objeto-parametro.operacao    = input frame {&frame-name} thl-objeto-parametro.operacao
                             and thl-objeto-parametro.metodo      = input frame {&frame-name} thl-objeto-parametro.metodo) then do:
            {include/i-vldprg.i}
            run utp/ut-msgs.p (input "show":U, input 17006,
                               input "Operacao ja cadastrada~~Ja existe esta operacao para o estabelecimento neste objeto.").
            apply "entry":U to thl-objeto-parametro.operacao in frame {&frame-name}.
            return "ADM-ERROR":U.
        end.
    end.

/*:T    Segue um exemplo de validacao de programa */
/*       find tabela where tabela.campo1 = c-variavel and               */
/*                         tabela.campo2 > i-variavel no-lock no-error. */
      
      /*:T Este include deve ser colocado sempre antes do ut-msgs.p */
/*       {include/i-vldprg.i}                                             */
/*       run utp/ut-msgs.p (input "show":U, input 7, input return-value). */
/*       return 'ADM-ERROR':U.                                            */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-key V-table-Win  adm/support/_key-snd.p
PROCEDURE send-key :
/*------------------------------------------------------------------------------
  Purpose:     Sends a requested KEY value back to the calling
               SmartObject.
  Parameters:  <see adm/template/sndkytop.i>
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.             */
  {src/adm/template/sndkytop.i}

  /* Return the key value associated with each key case.             */
  {src/adm/template/sndkycas.i "cod-estabel" "thl-objeto-parametro" "cod-estabel"}
  {src/adm/template/sndkycas.i "cod-param-ambiente" "thl-objeto-parametro" "cod-param-ambiente"}
  {src/adm/template/sndkycas.i "objeto" "thl-objeto-parametro" "objeto"}

  /* Close the CASE statement and end the procedure.                 */
  {src/adm/template/sndkyend.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records V-table-Win  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "thl-objeto-parametro"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed V-table-Win 
PROCEDURE state-changed :
/* -----------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
-------------------------------------------------------------*/
  DEFINE INPUT PARAMETER p-issuer-hdl AS HANDLE    NO-UNDO.
  DEFINE INPUT PARAMETER p-state      AS CHARACTER NO-UNDO.

  CASE p-state:
      /* Object instance CASEs can go here to replace standard behavior
         or add new cases. */
      {src/adm/template/vstates.i}
  END CASE.
  run pi-trata-state (p-issuer-hdl, p-state).
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

