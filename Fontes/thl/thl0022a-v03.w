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
using thl-extensions.erp.thl.enum.FieldDefaultEnum.

{include/i-prgvrs.i thl0022a-v03 12.00.00.000}

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

/* objeto (thl0021) da operacao: buffer proprio, para valer entre os procedimentos desta viewer */
define buffer b-objeto-sentido for thl-objeto.

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
&Scoped-Define ENABLED-FIELDS thl-objeto-parametro.ind-persistente ~
thl-objeto-parametro.frequencia-execucao ~
thl-objeto-parametro.qtd-dias-persist ~
thl-objeto-parametro.qtd-tentativas-persist ~
thl-objeto-parametro.tipo-log-requisicao ~
thl-objeto-parametro.tipo-log-retorno 
&Scoped-define ENABLED-TABLES thl-objeto-parametro
&Scoped-define FIRST-ENABLED-TABLE thl-objeto-parametro
&Scoped-Define ENABLED-OBJECTS rt-key rt-mold rt-mold-2 rt-mold-3 
&Scoped-Define DISPLAYED-FIELDS thl-objeto-parametro.ind-persistente ~
thl-objeto-parametro.frequencia-execucao ~
thl-objeto-parametro.qtd-dias-persist ~
thl-objeto-parametro.qtd-tentativas-persist ~
thl-objeto-parametro.tipo-log-requisicao ~
thl-objeto-parametro.tipo-log-retorno 
&Scoped-define DISPLAYED-TABLES thl-objeto-parametro
&Scoped-define FIRST-DISPLAYED-TABLE thl-objeto-parametro


/* Custom List Definitions                                              */
/* ADM-CREATE-FIELDS,ADM-ASSIGN-FIELDS,ADM-MODIFY-FIELDS,List-4,List-5,List-6 */

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
DEFINE RECTANGLE rt-key
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 77 BY 3.25.

DEFINE RECTANGLE rt-mold
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 77 BY 1.25.

DEFINE RECTANGLE rt-mold-2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 77 BY 1.25.

DEFINE RECTANGLE rt-mold-3
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 77 BY 1.25.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-main
     thl-objeto-parametro.ind-persistente AT ROW 1.17 COL 28.14 WIDGET-ID 46
          VIEW-AS TOGGLE-BOX
          SIZE 16 BY .88
     thl-objeto-parametro.frequencia-execucao AT ROW 2.67 COL 26.14 COLON-ALIGNED WIDGET-ID 6
          VIEW-AS FILL-IN 
          SIZE 11.14 BY .88
     thl-objeto-parametro.qtd-dias-persist AT ROW 3.67 COL 26.14 COLON-ALIGNED WIDGET-ID 10
          VIEW-AS FILL-IN 
          SIZE 3.14 BY .88
     thl-objeto-parametro.qtd-tentativas-persist AT ROW 4.67 COL 26.14 COLON-ALIGNED WIDGET-ID 12
          VIEW-AS FILL-IN 
          SIZE 3.14 BY .88
     thl-objeto-parametro.tipo-log-requisicao AT ROW 6.17 COL 11.72 NO-LABEL WIDGET-ID 34
          VIEW-AS RADIO-SET HORIZONTAL
          RADIO-BUTTONS 
                    "Pendente", 1,
"Erro", 2,
"Sucesso", 3,
"Nao Aplicavel", 4
          SIZE 64.29 BY .88
     thl-objeto-parametro.tipo-log-retorno AT ROW 7.67 COL 11.72 NO-LABEL WIDGET-ID 40
          VIEW-AS RADIO-SET HORIZONTAL
          RADIO-BUTTONS 
                    "Pendente", 1,
"Erro", 2,
"Sucesso", 3,
"Nao Aplicavel", 4
          SIZE 64.29 BY .88
     "Retorno" VIEW-AS TEXT
          SIZE 8 BY .54 AT ROW 7.25 COL 1.86 WIDGET-ID 30
     "Requisicao" VIEW-AS TEXT
          SIZE 8 BY .54 AT ROW 5.75 COL 1.86 WIDGET-ID 28
     rt-key AT ROW 2.5 COL 1
     rt-mold AT ROW 6 COL 1
     rt-mold-2 AT ROW 7.5 COL 1 WIDGET-ID 26
     rt-mold-3 AT ROW 1 COL 1 WIDGET-ID 32
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
         WIDTH              = 77.
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

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK FRAME f-main
/* Query rebuild information for FRAME f-main
     _Options          = "NO-LOCK"
     _Query            is NOT OPENED
*/  /* FRAME f-main */
&ANALYZE-RESUME

 


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK V-table-Win 


/* ***************************  Main Block  *************************** */

  &IF DEFINED(UIB_IS_RUNNING) <> 0 &THEN          
    RUN dispatch IN THIS-PROCEDURE ('initialize':U).        
  &ENDIF         
  
  /************************ INTERNAL PROCEDURES ********************/

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
    run pi-habilita-persistencia.

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

    /* persistencia (reenvio) so na saida */
    run pi-habilita-persistencia.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-acha-objeto V-table-Win 
PROCEDURE pi-acha-objeto :
/*------------------------------------------------------------------------------
  Purpose:     Posiciona o objeto (thl0021) para a operacao desta aba.
  Notes:       Pela linha corrente; sem ela (primeira operacao do objeto), pela viewer principal
               (thl0022a-v01), ligada por Group-Assign, que guarda o rowid do objeto.
------------------------------------------------------------------------------*/
    define variable c-handle as character no-undo.
    define variable h-fonte  as handle    no-undo.
    define variable r-objeto as rowid     no-undo.

    release b-objeto-sentido.

    if available thl-objeto-parametro then
        find first b-objeto-sentido no-lock
            where b-objeto-sentido.aplicacao = thl-objeto-parametro.aplicacao
              and b-objeto-sentido.objeto    = thl-objeto-parametro.objeto no-error.

    if available b-objeto-sentido then
        return.

    run get-link-handle in adm-broker-hdl ( input this-procedure,
                                            input 'GROUP-ASSIGN-SOURCE':U,
                                            output c-handle ) no-error.

    if c-handle = "" or c-handle = ? then
        return.

    assign h-fonte = widget-handle( entry( 1, c-handle ) ) no-error.

    if not valid-handle( h-fonte ) then
        return.

    run pi-devolve-parent in h-fonte ( output r-objeto ) no-error.

    if r-objeto <> ? then
        find first b-objeto-sentido no-lock
            where rowid( b-objeto-sentido ) = r-objeto no-error.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-habilita-persistencia V-table-Win 
PROCEDURE pi-habilita-persistencia :
/*------------------------------------------------------------------------------
  Purpose:     Persistencia (persistente, frequencia, dias e tentativas) so em operacao de saida.
               Entrada: esses quatro campos ficam desabilitados.
  Notes:       Log da requisicao, log do retorno e Grava Conteudo valem nos dois sentidos.
               So mexe nos campos com a viewer em edicao. Sem objeto localizado, habilita.
               Nao apaga o valor dos campos desabilitados.
------------------------------------------------------------------------------*/
    define variable l-saida as logical no-undo.

    if not thl-objeto-parametro.tipo-log-requisicao:sensitive in frame {&frame-name} then
        return.

    run pi-acha-objeto.

    assign l-saida = not available b-objeto-sentido or b-objeto-sentido.sentido-fluxo.

    assign thl-objeto-parametro.ind-persistente      :sensitive in frame {&frame-name} = l-saida
           thl-objeto-parametro.frequencia-execucao  :sensitive in frame {&frame-name} = l-saida
           thl-objeto-parametro.qtd-dias-persist     :sensitive in frame {&frame-name} = l-saida
           thl-objeto-parametro.qtd-tentativas-persist:sensitive in frame {&frame-name} = l-saida.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-padroes-campos V-table-Win 
PROCEDURE pi-padroes-campos :
/*------------------------------------------------------------------------------
  Purpose:     Inclusao: mostra os padroes do thl0002 (campos da aba Persistencia).
  Notes:       Campo sem padrao cadastrado fica com o valor inicial do banco.
------------------------------------------------------------------------------*/
    run pi-padrao-campo ( input thl-objeto-parametro.ind-persistente:handle in frame {&frame-name},
                          input FieldDefaultEnum:OPERACAO_IND_PERSISTENTE ).
    run pi-padrao-campo ( input thl-objeto-parametro.frequencia-execucao:handle in frame {&frame-name},
                          input FieldDefaultEnum:OPERACAO_FREQUENCIA_EXECUCAO ).
    run pi-padrao-campo ( input thl-objeto-parametro.qtd-dias-persist:handle in frame {&frame-name},
                          input FieldDefaultEnum:OPERACAO_DIAS_PERSIST ).
    run pi-padrao-campo ( input thl-objeto-parametro.qtd-tentativas-persist:handle in frame {&frame-name},
                          input FieldDefaultEnum:OPERACAO_TENTATIVAS_PERSIST ).
    run pi-padrao-campo ( input thl-objeto-parametro.tipo-log-requisicao:handle in frame {&frame-name},
                          input FieldDefaultEnum:OPERACAO_TIPO_LOG_REQUISICAO ).
    run pi-padrao-campo ( input thl-objeto-parametro.tipo-log-retorno:handle in frame {&frame-name},
                          input FieldDefaultEnum:OPERACAO_TIPO_LOG_RETORNO ).

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

