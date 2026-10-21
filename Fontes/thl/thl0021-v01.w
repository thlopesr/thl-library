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

{include/i-prgvrs.i thl0021-v01 12.00.00.000}

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
&Scoped-define EXTERNAL-TABLES thl-objeto
&Scoped-define FIRST-EXTERNAL-TABLE thl-objeto


/* Need to scope the external tables to this procedure                  */
DEFINE QUERY external_tables FOR thl-objeto.
/* Standard List Definitions                                            */
&Scoped-Define ENABLED-FIELDS thl-objeto.classe-objeto ~
thl-objeto.classe-processor thl-objeto.classe-service ~
thl-objeto.programa-consulta thl-objeto.ind-inativo ~
thl-objeto.ind-gera-historico thl-objeto.modelo-integracao ~
thl-objeto.sentido-fluxo thl-objeto.retencao-dias-sucesso ~
thl-objeto.retencao-dias-erro 
&Scoped-define ENABLED-TABLES thl-objeto
&Scoped-define FIRST-ENABLED-TABLE thl-objeto
&Scoped-Define ENABLED-OBJECTS rt-key rt-mold rt-mold-2 rt-mold-3 
&Scoped-Define DISPLAYED-FIELDS thl-objeto.objeto thl-objeto.aplicacao ~
thl-objeto.classe-objeto thl-objeto.classe-processor ~
thl-objeto.classe-service thl-objeto.programa-consulta ~
thl-objeto.ind-inativo thl-objeto.ind-gera-historico ~
thl-objeto.modelo-integracao thl-objeto.sentido-fluxo ~
thl-objeto.retencao-dias-sucesso thl-objeto.retencao-dias-erro 
&Scoped-define DISPLAYED-TABLES thl-objeto
&Scoped-define FIRST-DISPLAYED-TABLE thl-objeto


/* Custom List Definitions                                              */
/* ADM-CREATE-FIELDS,ADM-ASSIGN-FIELDS,ADM-MODIFY-FIELDS,List-4,List-5,List-6 */
&Scoped-define ADM-CREATE-FIELDS thl-objeto.objeto thl-objeto.aplicacao 
&Scoped-define ADM-ASSIGN-FIELDS thl-objeto.objeto thl-objeto.aplicacao 

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _XFTR "Foreign Keys" V-table-Win _INLINE
/* Actions: ? adm/support/keyedit.w ? ? ? */
/* STRUCTURED-DATA
<KEY-OBJECT>
THIS-PROCEDURE
</KEY-OBJECT>
<FOREIGN-KEYS>
</FOREIGN-KEYS> 
<EXECUTING-CODE>
**************************
* Set attributes related to FOREIGN KEYS
*/
RUN set-attribute-list (
    'Keys-Accepted = "",
     Keys-Supplied = ""':U).
/**************************
</EXECUTING-CODE> */   

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* ***********************  Control Definitions  ********************** */


/* Definitions of the field level widgets                               */
DEFINE RECTANGLE rt-key
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 2.25.

DEFINE RECTANGLE rt-mold
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 4.25.

DEFINE RECTANGLE rt-mold-2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 2.25.

DEFINE RECTANGLE rt-mold-3
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 1.25.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-main
     thl-objeto.objeto AT ROW 1.17 COL 20.14 COLON-ALIGNED WIDGET-ID 8
          VIEW-AS FILL-IN 
          SIZE 45.29 BY .88
     thl-objeto.aplicacao AT ROW 2.17 COL 14.57 WIDGET-ID 2
          LABEL "Aplicacao"
          VIEW-AS FILL-IN 
          SIZE 45.29 BY .88
     thl-objeto.classe-objeto AT ROW 3.67 COL 16.57 WIDGET-ID 4
          VIEW-AS FILL-IN 
          SIZE 65 BY .88
     thl-objeto.classe-processor AT ROW 4.67 COL 19.86 COLON-ALIGNED WIDGET-ID 32
          LABEL "Processor"
          VIEW-AS FILL-IN 
          SIZE 65 BY .88
     thl-objeto.classe-service AT ROW 5.67 COL 19.86 COLON-ALIGNED WIDGET-ID 34
          LABEL "Service"
          VIEW-AS FILL-IN 
          SIZE 65 BY .88
     thl-objeto.programa-consulta AT ROW 6.67 COL 8.29 WIDGET-ID 10
          VIEW-AS FILL-IN 
          SIZE 65 BY .88
     thl-objeto.ind-inativo AT ROW 8.17 COL 22 WIDGET-ID 24
          VIEW-AS TOGGLE-BOX
          SIZE 12 BY .88
     thl-objeto.ind-gera-historico AT ROW 8.17 COL 67.57 WIDGET-ID 26
          LABEL "Gerar Historico"
          VIEW-AS TOGGLE-BOX
          SIZE 20 BY .88
     thl-objeto.modelo-integracao AT ROW 9.17 COL 20 COLON-ALIGNED WIDGET-ID 6
          VIEW-AS COMBO-BOX 
          LIST-ITEM-PAIRS "Rest",1,
                     "Saop",2,
                     "File",3
          DROP-DOWN-LIST
          SIZE 16 BY 1
     thl-objeto.sentido-fluxo AT ROW 9.17 COL 65.57 COLON-ALIGNED WIDGET-ID 22
          VIEW-AS COMBO-BOX INNER-LINES 5
          LIST-ITEM-PAIRS "Saida",yes,
                     "Entrada",no
          DROP-DOWN-LIST
          SIZE 19.14 BY .88
     thl-objeto.retencao-dias-sucesso AT ROW 10.67 COL 65.57 COLON-ALIGNED WIDGET-ID 28
          LABEL "Ret. Sucesso"
          VIEW-AS FILL-IN 
          SIZE 6 BY .88
     thl-objeto.retencao-dias-erro AT ROW 10.75 COL 19.72 COLON-ALIGNED WIDGET-ID 30
          LABEL "Ret. Erro"
          VIEW-AS FILL-IN 
          SIZE 6 BY .88
     "T. Reten‡Æo Msg" VIEW-AS TEXT
          SIZE 12 BY .54 AT ROW 10.25 COL 1.43 WIDGET-ID 38
     rt-key AT ROW 1 COL 1
     rt-mold AT ROW 3.5 COL 1
     rt-mold-2 AT ROW 8 COL 1 WIDGET-ID 16
     rt-mold-3 AT ROW 10.5 COL 1 WIDGET-ID 36
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1 SCROLLABLE 
         FONT 4 WIDGET-ID 100.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: SmartViewer
   External Tables: mgnitro.thl-objeto
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
         HEIGHT             = 10.75
         WIDTH              = 88.57.
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

/* SETTINGS FOR FILL-IN thl-objeto.aplicacao IN FRAME f-main
   NO-ENABLE ALIGN-L 1 2 EXP-LABEL                                      */
/* SETTINGS FOR FILL-IN thl-objeto.classe-objeto IN FRAME f-main
   ALIGN-L                                                              */
/* SETTINGS FOR FILL-IN thl-objeto.classe-processor IN FRAME f-main
   EXP-LABEL                                                            */
/* SETTINGS FOR FILL-IN thl-objeto.classe-service IN FRAME f-main
   EXP-LABEL                                                            */
/* SETTINGS FOR TOGGLE-BOX thl-objeto.ind-gera-historico IN FRAME f-main
   EXP-LABEL                                                            */
/* SETTINGS FOR FILL-IN thl-objeto.objeto IN FRAME f-main
   NO-ENABLE 1 2                                                        */
/* SETTINGS FOR FILL-IN thl-objeto.programa-consulta IN FRAME f-main
   ALIGN-L                                                              */
/* SETTINGS FOR FILL-IN thl-objeto.retencao-dias-erro IN FRAME f-main
   EXP-LABEL                                                            */
/* SETTINGS FOR FILL-IN thl-objeto.retencao-dias-sucesso IN FRAME f-main
   EXP-LABEL                                                            */
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

&Scoped-define SELF-NAME thl-objeto.aplicacao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL thl-objeto.aplicacao V-table-Win
ON F5 OF thl-objeto.aplicacao IN FRAME f-main /* Aplicacao */
DO:
    {include/zoomvar.i &prog-zoom="thl/thl0020-z01.w"
                       &campo=thl-objeto.aplicacao
                       &campozoom=aplicacao}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL thl-objeto.aplicacao V-table-Win
ON MOUSE-SELECT-DBLCLICK OF thl-objeto.aplicacao IN FRAME f-main /* Aplicacao */
DO:
    APPLY 'F5' TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME thl-objeto.sentido-fluxo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL thl-objeto.sentido-fluxo V-table-Win
ON VALUE-CHANGED OF thl-objeto.sentido-fluxo IN FRAME f-main /* Sentido */
DO:
    /* saida: so a classe da mensagem; entrada: as tres */
    run pi-habilita-classes.
    if adm-new-record then
        run pi-padroes-classes.
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

    thl-objeto.aplicacao:load-mouse-pointer ("image/lupa.cur") IN FRAME {&FRAME-NAME}.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

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
  {src/adm/template/row-list.i "thl-objeto"}

  /* Get the record ROWID's from the RECORD-SOURCE.                  */
  {src/adm/template/row-get.i}

  /* FIND each record specified by the RECORD-SOURCE.                */
  {src/adm/template/row-find.i "thl-objeto"}

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

    define variable c-ant-objeto    as character no-undo.
    define variable c-ant-processor as character no-undo.
    define variable c-ant-service   as character no-undo.
    define variable l-novo          as logical   no-undo.

    /* Code placed here will execute PRIOR to standard behavior. */
    run pi-validate.
    if return-value = 'ADM-ERROR':U then
        return 'ADM-ERROR':U.
    
    /*:T Ponha na pi-validate todas as validacoes */
    /*:T Nao gravar nada no registro antes do dispatch do assign-record e 
       nem na PI-validate. */
    
    /* classes antes da alteracao: as linhas de thl-objeto-parametro que ainda as tem acompanham a mudanca */
    assign l-novo = adm-new-record.
    if not l-novo and available thl-objeto then
        assign c-ant-objeto    = thl-objeto.classe-objeto
               c-ant-processor = thl-objeto.classe-processor
               c-ant-service   = thl-objeto.classe-service.

    /* Dispatch standard ADM method.                             */
    RUN dispatch IN THIS-PROCEDURE ( INPUT 'assign-record':U ) .
    if RETURN-VALUE = 'ADM-ERROR':U then 
        return 'ADM-ERROR':U.
    
    if not l-novo and available thl-objeto then
        run pi-propaga-classes ( input c-ant-objeto, input c-ant-processor, input c-ant-service ).

    /*:T Todos os assign's nao feitos pelo assign-record devem ser feitos aqui */  
    /* Code placed here will execute AFTER standard behavior.    */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-delete-record V-table-Win 
PROCEDURE local-delete-record :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       Eliminar o objeto elimina tambem as operacoes (thl0022 e a extensao
               REST), os usuarios e a rota (thl0040) dele, na mesma transacao.
               As mensagens ja gravadas (thl-mensagem) nao sao tocadas.
------------------------------------------------------------------------------*/
    define variable c-aplicacao as character no-undo.
    define variable c-objeto    as character no-undo.

    /* Code placed here will execute PRIOR to standard behavior. */
    if available thl-objeto then
        assign c-aplicacao = thl-objeto.aplicacao
               c-objeto    = thl-objeto.objeto.

    do transaction on error undo, return 'ADM-ERROR':U:

        /* Dispatch standard ADM method.                             */
        RUN dispatch IN THIS-PROCEDURE ( INPUT 'delete-record':U ) .
        if RETURN-VALUE = 'ADM-ERROR':U then
            undo, return 'ADM-ERROR':U.

        /* filhos do objeto eliminado */
        if c-objeto <> "" then do:
            for each thl-objeto-parametro-rest exclusive-lock
                where thl-objeto-parametro-rest.aplicacao = c-aplicacao and thl-objeto-parametro-rest.objeto = c-objeto:
                delete thl-objeto-parametro-rest.
            end.

            for each thl-objeto-parametro exclusive-lock
                where thl-objeto-parametro.aplicacao = c-aplicacao and thl-objeto-parametro.objeto = c-objeto:
                delete thl-objeto-parametro.
            end.

            for each thl-objeto-usuario exclusive-lock
                where thl-objeto-usuario.aplicacao = c-aplicacao and thl-objeto-usuario.objeto = c-objeto:
                delete thl-objeto-usuario.
            end.

            for each thl-objeto-rota exclusive-lock
                where thl-objeto-rota.aplicacao = c-aplicacao and thl-objeto-rota.objeto = c-objeto:
                delete thl-objeto-rota.
            end.
        end.

    end.

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
    run pi-padroes-classes.
    run pi-habilita-classes.

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

    run pi-habilita-classes.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-habilita-classes V-table-Win
PROCEDURE pi-habilita-classes :
/*------------------------------------------------------------------------------
  Purpose:     Saida: so a classe da mensagem habilitada; processor e service ficam desabilitados e
               em branco. Entrada: mensagem, processor e service.
  Notes:       So mexe nos campos com a viewer em edicao (classe da mensagem habilitada).
               Em saida o processor e o service sao limpos: nao devem ter valor.
------------------------------------------------------------------------------*/
    define variable l-entrada as logical no-undo.

    if not thl-objeto.classe-objeto:sensitive in frame {&frame-name} then
        return.

    assign l-entrada = not input frame {&frame-name} thl-objeto.sentido-fluxo.

    assign thl-objeto.classe-processor:sensitive in frame {&frame-name} = l-entrada
           thl-objeto.classe-service  :sensitive in frame {&frame-name} = l-entrada.

    if not l-entrada then
        assign thl-objeto.classe-processor:screen-value in frame {&frame-name} = ""
               thl-objeto.classe-service  :screen-value in frame {&frame-name} = "".

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-padroes-classes V-table-Win
PROCEDURE pi-padroes-classes :
/*------------------------------------------------------------------------------
  Purpose:     Inclusao: mostra as classes padrao do thl0002 (parametro thl.classe, ambiente *),
               lidas por EnvironmentResource com o enum ClassVariableEnum (o mesmo dos Services da API).
  Notes:       Campo ja preenchido pelo usuario nao e trocado; a mensagem so e trocada quando
               esta em branco ou com o padrao do outro sentido. Sem parametro, fica em branco.
------------------------------------------------------------------------------*/
    define variable l-entrada      as logical   no-undo.
    define variable c-msg-entrada  as character no-undo.
    define variable c-msg-saida    as character no-undo.
    define variable c-processor    as character no-undo.
    define variable c-service      as character no-undo.

    assign l-entrada = not input frame {&frame-name} thl-objeto.sentido-fluxo.

    /* o parametro thl.classe vem do programa (aba Programa do thl0002: thl0021-v01); sem ele fica em branco */
    assign c-msg-entrada = new EnvironmentResource():getEnvironmentVariable( ClassVariableEnum:MENSAGEM_ENTRADA ) no-error.
    assign c-msg-saida   = new EnvironmentResource():getEnvironmentVariable( ClassVariableEnum:MENSAGEM_SAIDA ) no-error.
    assign c-processor   = new EnvironmentResource():getEnvironmentVariable( ClassVariableEnum:PROCESSOR_ENTRADA ) no-error.
    assign c-service     = new EnvironmentResource():getEnvironmentVariable( ClassVariableEnum:SERVICE_ENTRADA ) no-error.

    if input frame {&frame-name} thl-objeto.classe-objeto = ""
       or input frame {&frame-name} thl-objeto.classe-objeto = ( if l-entrada then c-msg-saida else c-msg-entrada ) then
        assign thl-objeto.classe-objeto:screen-value in frame {&frame-name} = ( if l-entrada then c-msg-entrada else c-msg-saida ).

    if l-entrada then do:
        if input frame {&frame-name} thl-objeto.classe-processor = "" then
            assign thl-objeto.classe-processor:screen-value in frame {&frame-name} = c-processor.
        if input frame {&frame-name} thl-objeto.classe-service = "" then
            assign thl-objeto.classe-service:screen-value in frame {&frame-name} = c-service.
    end.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-padroes-campos V-table-Win 
PROCEDURE pi-padroes-campos :
/*------------------------------------------------------------------------------
  Purpose:     Inclusao: mostra os padroes do thl0002 (campos do objeto).
  Notes:       Campo sem padrao cadastrado fica com o valor inicial do banco.
------------------------------------------------------------------------------*/
    run pi-padrao-campo ( input thl-objeto.ind-inativo:handle in frame {&frame-name},
                          input FieldDefaultEnum:OBJETO_IND_INATIVO ).
    run pi-padrao-campo ( input thl-objeto.ind-gera-historico:handle in frame {&frame-name},
                          input FieldDefaultEnum:OBJETO_IND_GERA_HISTORICO ).
    run pi-padrao-campo ( input thl-objeto.sentido-fluxo:handle in frame {&frame-name},
                          input FieldDefaultEnum:OBJETO_SENTIDO_FLUXO ).
    run pi-padrao-campo ( input thl-objeto.modelo-integracao:handle in frame {&frame-name},
                          input FieldDefaultEnum:OBJETO_MODELO_INTEGRACAO ).
    run pi-padrao-campo ( input thl-objeto.retencao-dias-sucesso:handle in frame {&frame-name},
                          input FieldDefaultEnum:OBJETO_RETENCAO_DIAS_SUCESSO ).
    run pi-padrao-campo ( input thl-objeto.retencao-dias-erro:handle in frame {&frame-name},
                          input FieldDefaultEnum:OBJETO_RETENCAO_DIAS_ERRO ).
    run pi-padrao-campo ( input thl-objeto.programa-consulta:handle in frame {&frame-name},
                          input FieldDefaultEnum:OBJETO_PROGRAMA_CONSULTA ).

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
    
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-propaga-classes V-table-Win 
PROCEDURE pi-propaga-classes :
/*------------------------------------------------------------------------------
  Purpose:     Leva para as linhas de thl-objeto-parametro a mudanca de classe do objeto
  Notes:       So as linhas que ainda tem a classe antiga (ou em branco); a linha
               personalizada na operacao (thl0022, aba Classe) nao e alterada.
------------------------------------------------------------------------------*/
    define input parameter c-ant-objeto    as character no-undo.
    define input parameter c-ant-processor as character no-undo.
    define input parameter c-ant-service   as character no-undo.

    define buffer b-linha for thl-objeto-parametro.

    if thl-objeto.classe-objeto    = c-ant-objeto    and
       thl-objeto.classe-processor = c-ant-processor and
       thl-objeto.classe-service   = c-ant-service   then
        return.

    do transaction:
        for each b-linha exclusive-lock
            where b-linha.aplicacao = thl-objeto.aplicacao
              and b-linha.objeto    = thl-objeto.objeto:
            if b-linha.classe-objeto = c-ant-objeto or b-linha.classe-objeto = "" then
                assign b-linha.classe-objeto = thl-objeto.classe-objeto.
            if b-linha.classe-processor = c-ant-processor or b-linha.classe-processor = "" then
                assign b-linha.classe-processor = thl-objeto.classe-processor.
            if b-linha.classe-service = c-ant-service or b-linha.classe-service = "" then
                assign b-linha.classe-service = thl-objeto.classe-service.
        end.
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

    /* aplicacao deve existir no cadastro de aplicacoes (thl0020) */
    if not can-find( thl-aplicacao
                     where thl-aplicacao.aplicacao = input frame {&frame-name} thl-objeto.aplicacao ) then do:
        {include/i-vldprg.i}
        {utp/ut-table.i mgnitro thl-aplicacao 1}
        run utp/ut-msgs.p (input "show":U, input 2, input return-value).
        apply "entry":U to thl-objeto.aplicacao in frame {&frame-name}.
        return "ADM-ERROR":U.
    end.
    

    if adm-new-record then do:
        if input frame {&frame-name} thl-objeto.objeto = "" then do:
            {include/i-vldprg.i}
            run utp/ut-msgs.p (input "show":U, input 17006,
                               input "Objeto nao informado~~Informe o codigo do objeto de integracao.").
            apply "entry":U to thl-objeto.objeto in frame {&frame-name}.
            return "ADM-ERROR":U.
        end.
        if can-find(thl-objeto where thl-objeto.aplicacao = input frame {&frame-name} thl-objeto.aplicacao
                            and thl-objeto.objeto    = input frame {&frame-name} thl-objeto.objeto) then do:
            {include/i-vldprg.i}
            run utp/ut-msgs.p (input "show":U, input 17006,
                               input "Objeto ja cadastrado~~Ja existe este objeto para a aplicacao.").
            apply "entry":U to thl-objeto.objeto in frame {&frame-name}.
            return "ADM-ERROR":U.
        end.
    end.
    if input frame {&frame-name} thl-objeto.classe-objeto = "" then do:
        {include/i-vldprg.i}
        run utp/ut-msgs.p (input "show":U, input 17006,
                           input "Classe nao informada~~Informe o nome completo da classe da mensagem (ex.: thl-extensions.integration.<sistema>...).").
        apply "entry":U to thl-objeto.classe-objeto in frame {&frame-name}.
        return "ADM-ERROR":U.
    end.

    /* entrada: mensagem, processor e service obrigatorios; saida: so a classe da mensagem */
    if not input frame {&frame-name} thl-objeto.sentido-fluxo then do:

        if input frame {&frame-name} thl-objeto.classe-processor = "" then do:
            {include/i-vldprg.i}
            run utp/ut-msgs.p (input "show":U, input 17006,
                               input "Classe processor nao informada~~Objeto de entrada: informe o nome completo da classe de orquestracao (padrao: thl-lib.integration.messaging.inbound.core.Processor).").
            apply "entry":U to thl-objeto.classe-processor in frame {&frame-name}.
            return "ADM-ERROR":U.
        end.

        if input frame {&frame-name} thl-objeto.classe-service = "" then do:
            {include/i-vldprg.i}
            run utp/ut-msgs.p (input "show":U, input 17006,
                               input "Classe service nao informada~~Objeto de entrada: informe o nome completo da classe do Service (ex.: thl-extensions.erp.<sistema>.service...).").
            apply "entry":U to thl-objeto.classe-service in frame {&frame-name}.
            return "ADM-ERROR":U.
        end.

    end.

    /* retencao do expurgo (thl0222): zero = nao expurga */
    if input frame {&frame-name} thl-objeto.retencao-dias-sucesso < 0 or
       input frame {&frame-name} thl-objeto.retencao-dias-erro    < 0 then do:
        {include/i-vldprg.i}
        run utp/ut-msgs.p (input "show":U, input 17006,
                           input "Retencao invalida~~Informe 0 (nao expurga) ou a quantidade de dias a manter.").
        apply "entry":U to thl-objeto.retencao-dias-sucesso in frame {&frame-name}.
        return "ADM-ERROR":U.
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
  {src/adm/template/snd-list.i "thl-objeto"}

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

