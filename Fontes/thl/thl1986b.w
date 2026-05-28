&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS w-livre 

using System.Diagnostics.*.
using thl-lib.integration.messaging.outbound.service.OutboundMessageService.

/*:T *******************************************************************************
** Copyright TOTVS S.A. (2009)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da TOTVS, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i thl1896b 12.00.00.000}

/* Chamada a include do gerenciador de licen�as. Necessario alterar os parametros */
/*                                                                                */
/* <programa>:  Informar qual o nome do programa.                                 */
/* <m�dulo>:  Informar qual o m�dulo a qual o programa pertence.                  */

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
    {include/i-license-manager.i <programa> <m�dulo>}
&ENDIF

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

create widget-pool.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */
define shared variable c-codigo-mensagem
    as character
    no-undo.
    
define temp-table tt-conteudo no-undo
    field tipo-conteudo like thl-mensagem-conteudo.tipo-conteudo
    field descr-tipo    as character
    field conteudo      like thl-mensagem-conteudo.conteudo.
    
define temp-table tt-item  no-undo
    field chave-registro     like thl-mensagem-item.chave-registro
    field chave-registro-ext like thl-mensagem-item.chave-registro-ext.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE SmartWindow
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-cad
&Scoped-define BROWSE-NAME br-conteudo

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-conteudo tt-item

/* Definitions for BROWSE br-conteudo                                   */
&Scoped-define FIELDS-IN-QUERY-br-conteudo tt-conteudo.descr-tipo tt-conteudo.descr-tipo   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-conteudo   
&Scoped-define SELF-NAME br-conteudo
&Scoped-define QUERY-STRING-br-conteudo FOR EACH tt-conteudo
&Scoped-define OPEN-QUERY-br-conteudo OPEN QUERY {&SELF-NAME} FOR EACH tt-conteudo.
&Scoped-define TABLES-IN-QUERY-br-conteudo tt-conteudo
&Scoped-define FIRST-TABLE-IN-QUERY-br-conteudo tt-conteudo


/* Definitions for BROWSE br-item                                       */
&Scoped-define FIELDS-IN-QUERY-br-item tt-item.chave-registro tt-item.chave-registro-ext   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-item   
&Scoped-define SELF-NAME br-item
&Scoped-define QUERY-STRING-br-item FOR EACH tt-item
&Scoped-define OPEN-QUERY-br-item OPEN QUERY {&SELF-NAME} FOR EACH tt-item.
&Scoped-define TABLES-IN-QUERY-br-item tt-item
&Scoped-define FIRST-TABLE-IN-QUERY-br-item tt-item


/* Definitions for FRAME f-cad                                          */
&Scoped-define OPEN-BROWSERS-IN-QUERY-f-cad ~
    ~{&OPEN-QUERY-br-conteudo}~
    ~{&OPEN-QUERY-br-item}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rt-button rtMain-3 rtMain rtMain-4 rtMain-2 ~
fi-codigo fi-objeto fi-data-criacao fi-operacao fi-data-integracao ~
fi-aplicacao fi-destino fi-cod-status fi-desc-retorno br-item br-conteudo ~
bt-detalhar bt-reenviar
&Scoped-Define DISPLAYED-OBJECTS fi-codigo fi-objeto fi-data-criacao ~
fi-operacao fi-data-integracao fi-aplicacao cb-metodo cb-dispositivo ~
cb-retorno cb-requisicao cb-processamento fi-destino fi-cod-status ~
fi-desc-retorno 

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
       MENU-ITEM mi-imprimir    LABEL "&Relat�rios"    ACCELERATOR "CTRL-P"
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

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-detalhar
     LABEL "Detalhar"
     SIZE 15 BY 1.13.

DEFINE BUTTON bt-reenviar
     LABEL "Reenviar"
     SIZE 15 BY 1.13.

DEFINE VARIABLE cb-dispositivo AS LOGICAL FORMAT "Sa�da/Entrada" INITIAL NO 
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
                     "N�o Cont�m",4
     DROP-DOWN-LIST
     SIZE 18 BY 1 NO-UNDO.

DEFINE VARIABLE cb-requisicao AS INTEGER FORMAT "9":U INITIAL 4 
     LABEL "Requisi��o" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Pendente",1,
                     "Erro",2,
                     "Sucesso",3,
                     "N�o Cont�m",4
     DROP-DOWN-LIST
     SIZE 18 BY 1 NO-UNDO.

DEFINE VARIABLE cb-retorno AS INTEGER FORMAT "9":U INITIAL 4 
     LABEL "Retorno" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Pendente",1,
                     "Erro",2,
                     "Sucesso",3,
                     "N�o Cont�m",4
     DROP-DOWN-LIST
     SIZE 18 BY 1 NO-UNDO.

DEFINE VARIABLE fi-aplicacao AS CHARACTER FORMAT "x(80)" 
     LABEL "Aplica��o" 
     VIEW-AS FILL-IN 
     SIZE 27.57 BY .88.

DEFINE VARIABLE fi-cod-status AS INTEGER FORMAT ">>>>>9":U INITIAL 0 
     LABEL "C�d. Status" 
     VIEW-AS FILL-IN 
     SIZE 6.57 BY .88 NO-UNDO.

DEFINE VARIABLE fi-codigo AS CHARACTER FORMAT "X(64)" 
     LABEL "Codigo" 
     VIEW-AS FILL-IN 
     SIZE 40 BY .88.

DEFINE VARIABLE fi-data-criacao AS DATETIME FORMAT "99/99/9999 HH:MM:SS" 
     LABEL "Data Criacao" 
     VIEW-AS FILL-IN 
     SIZE 21 BY .88.

DEFINE VARIABLE fi-data-integracao AS DATETIME FORMAT "99/99/9999 HH:MM:SS" 
     LABEL "Data Integracao" 
     VIEW-AS FILL-IN 
     SIZE 21 BY .88.

DEFINE VARIABLE fi-desc-retorno AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 59.14 BY .88 NO-UNDO.

DEFINE VARIABLE fi-destino AS CHARACTER FORMAT "X(256)":U 
     LABEL "Destino" 
     VIEW-AS FILL-IN 
     SIZE 66 BY .88 NO-UNDO.

DEFINE VARIABLE fi-objeto AS CHARACTER FORMAT "x(80)" 
     LABEL "Objeto" 
     VIEW-AS FILL-IN 
     SIZE 20 BY .88.

DEFINE VARIABLE fi-operacao AS CHARACTER FORMAT "x(80)" 
     LABEL "Operacao" 
     VIEW-AS FILL-IN 
     SIZE 27.57 BY .88.

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 88.57 BY 1.46
     BGCOLOR 7 .

DEFINE RECTANGLE rtMain
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 1.25.

DEFINE RECTANGLE rtMain-2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 5.25.

DEFINE RECTANGLE rtMain-3
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 1.25.

DEFINE RECTANGLE rtMain-4
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 1.25.

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-conteudo FOR 
      tt-conteudo SCROLLING.

DEFINE QUERY br-item FOR 
      tt-item SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-conteudo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-conteudo w-livre _FREEFORM
  QUERY br-conteudo DISPLAY
        tt-conteudo.tipo-conteudo
        tt-conteudo.descr-tipo      column-label 'Descri��o' format 'x(15)'
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 84.14 BY 6.92
         FONT 4 FIT-LAST-COLUMN.

DEFINE BROWSE br-item
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-item w-livre _FREEFORM
  QUERY br-item DISPLAY
      tt-item.chave-registro
      tt-item.chave-registro-ext
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 84.14 BY 6.92
         FONT 4 FIT-LAST-COLUMN.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     fi-codigo AT ROW 2.92 COL 14 COLON-ALIGNED WIDGET-ID 88
     fi-objeto AT ROW 4.42 COL 14 COLON-ALIGNED WIDGET-ID 96
     fi-data-criacao AT ROW 4.42 COL 59 COLON-ALIGNED WIDGET-ID 90
     fi-operacao AT ROW 5.42 COL 14 COLON-ALIGNED WIDGET-ID 98
     fi-data-integracao AT ROW 5.42 COL 59 COLON-ALIGNED WIDGET-ID 92
     fi-aplicacao AT ROW 6.42 COL 14 COLON-ALIGNED WIDGET-ID 68
     cb-metodo AT ROW 6.42 COL 59 COLON-ALIGNED WIDGET-ID 78
     cb-dispositivo AT ROW 7.42 COL 14 COLON-ALIGNED HELP
          "Dispositivo" WIDGET-ID 76
     cb-retorno AT ROW 7.42 COL 58.86 COLON-ALIGNED WIDGET-ID 84
     cb-requisicao AT ROW 8.42 COL 14 COLON-ALIGNED WIDGET-ID 82
     cb-processamento AT ROW 8.42 COL 58.86 COLON-ALIGNED WIDGET-ID 80
     fi-destino AT ROW 10 COL 14 COLON-ALIGNED WIDGET-ID 94
     fi-cod-status AT ROW 11.46 COL 14 COLON-ALIGNED WIDGET-ID 86
     fi-desc-retorno AT ROW 11.46 COL 20.86 COLON-ALIGNED NO-LABEL WIDGET-ID 74
     br-item AT ROW 14.29 COL 4.57 WIDGET-ID 200
     br-conteudo AT ROW 14.29 COL 4.57 WIDGET-ID 300
     bt-detalhar AT ROW 21.25 COL 4.72  WIDGET-ID 104
     bt-reenviar AT ROW 21.25 COL 21.0 WIDGET-ID 106
     rt-button AT ROW 1.08 COL 1.86
     rtMain-3 AT ROW 9.79 COL 1.86 WIDGET-ID 70
     rtMain AT ROW 2.75 COL 1.86 WIDGET-ID 100
     rtMain-4 AT ROW 11.29 COL 1.86 WIDGET-ID 72
     rtMain-2 AT ROW 4.25 COL 1.86 WIDGET-ID 102
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 90 BY 21.79
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
         HEIGHT             = 21.79
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
/* BROWSE-TAB br-item fi-desc-retorno f-cad */
/* BROWSE-TAB br-conteudo br-item f-cad */
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
       fi-aplicacao:READ-ONLY IN FRAME f-cad        = TRUE.

ASSIGN 
       fi-cod-status:READ-ONLY IN FRAME f-cad        = TRUE.

ASSIGN 
       fi-codigo:READ-ONLY IN FRAME f-cad        = TRUE.

ASSIGN 
       fi-data-criacao:READ-ONLY IN FRAME f-cad        = TRUE.

ASSIGN 
       fi-data-integracao:READ-ONLY IN FRAME f-cad        = TRUE.

ASSIGN 
       fi-desc-retorno:READ-ONLY IN FRAME f-cad        = TRUE.

ASSIGN 
       fi-destino:READ-ONLY IN FRAME f-cad        = TRUE.

ASSIGN 
       fi-objeto:READ-ONLY IN FRAME f-cad        = TRUE.

ASSIGN 
       fi-operacao:READ-ONLY IN FRAME f-cad        = TRUE.

IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-livre)
THEN w-livre:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-conteudo
/* Query rebuild information for BROWSE br-conteudo
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH tt-conteudo.
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE br-conteudo */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-item
/* Query rebuild information for BROWSE br-item
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH tt-item.
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE br-item */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON end-error OF w-livre /* Template Livre <Insira complemento> */
or endkey of {&WINDOW-NAME} anywhere do:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  return no-apply.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON window-close OF w-livre /* Template Livre <Insira complemento> */
do:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  apply "CLOSE":U to this-procedure.
  return no-apply.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-reenviar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-reenviar w-livre
on choose of bt-reenviar in frame f-cad /* Reenviar */
do.

    define variable svc     as OutboundMessageService no-undo.
    define variable success as logical                no-undo.

    find first thl-mensagem no-lock
        where thl-mensagem.codigo-mensagem = c-codigo-mensagem no-error.

    if not available thl-mensagem then do:
        message 'Mensagem nao localizada.' view-as alert-box error title 'Reenviar Mensagem'.
        return.
    end.

    find first thl-objeto no-lock
        where thl-objeto.objeto = thl-mensagem.objeto no-error.

    /* Somente mensagens de saida (outbound) podem ser reenviadas */
    if available thl-objeto and not thl-objeto.sentido-fluxo then do:
        message 'Reenvio disponivel apenas para mensagens de saida (Dispositivo = Saida).'
            view-as alert-box warning title 'Reenviar Mensagem'.
        return.
    end.

    /* Confirmacao do usuario */
    run utp/ut-msgs.p ( input 'show':U,
                        input 27100,
                        input substitute( 'Confirma o reenvio da mensagem &1?',
                                          c-codigo-mensagem ) ).
    if return-value <> 'yes':U then return.

    do on error undo, leave:

        svc     = new OutboundMessageService( thl-mensagem.objeto,
                                              thl-mensagem.operacao ).
        success = svc:reprocess( c-codigo-mensagem ).

        if success then
            message 'Mensagem reenviada com sucesso.'
                view-as alert-box information title 'Reenviar Mensagem'.
        else
            message 'Reenvio finalizado com advertencia. Verifique o retorno da mensagem.'
                view-as alert-box warning title 'Reenviar Mensagem'.

        catch err as Progress.Lang.Error:
            message substitute( 'Erro no reenvio:~n&1', err:GetMessage(1) )
                view-as alert-box error title 'Reenviar Mensagem'.
        end catch.

    end.

    delete object svc no-error.

    /* Recarregar detalhe para refletir novo status */
    run local-initialize.

end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-detalhar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-detalhar w-livre
on choose of bt-detalhar in frame f-cad /* Detalhar */
do.

    define variable process_ as Process   no-undo.
    define variable arquivo     as character no-undo.
    define variable arquivoJson as character no-undo.
    
    if available tt-conteudo then do.
        
        output to value( substitute( '&1&2', session:temp-directory, 'conteudo.txt' ) ).
        export tt-conteudo.conteudo.
        output close.
        
        input from value( substitute( '&1&2', session:temp-directory, 'conteudo.txt' ) ).
        import unformatted arquivo.
        input close.
        
        assign arquivo     = replace( arquivo, '"', '')
               arquivo     = substitute( '&1&2', session:temp-directory, arquivo )
               arquivoJson = replace( arquivo, 'blb', 'json').
               
        os-copy value(arquivo) value(arquivoJson).
        
        assign process_ = new Process()
               process_:StartInfo:FileName  = 'chrome.exe'
               process_:StartInfo:Arguments = substitute( '"&1"', arquivoJson).
        
        process_:Start().
        
    end.
    
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-consultas
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-consultas w-livre
ON choose OF MENU-ITEM mi-consultas /* Consultas */
do:
  run pi-consulta in h_p-exihel.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-conteudo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-conteudo w-livre
ON choose OF MENU-ITEM mi-conteudo /* Conteudo */
or help of frame {&FRAME-NAME}
do:
  run pi-ajuda in h_p-exihel.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-imprimir
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-imprimir w-livre
ON choose OF MENU-ITEM mi-imprimir /* Relat�rios */
do:
  run pi-imprimir in h_p-exihel.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-programa
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-programa w-livre
ON menu-drop OF MENU mi-programa /* Nome-do-Programa */
do:
  run pi-disable-menu.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-sair
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-sair w-livre
ON choose OF MENU-ITEM mi-sair /* Sair */
do:
  run pi-sair in h_p-exihel.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-sobre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-sobre w-livre
ON choose OF MENU-ITEM mi-sobre /* Sobre... */
do:
  {include/sobre.i}
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-conteudo
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
             INPUT  'FOLDER-LABELS = ':U + 'Itens|Conteudos' + ',
                     FOLDER-TAB-TYPE = 1':U ,
             OUTPUT h_folder ).
       RUN set-position IN h_folder ( 12.75 , 2.00 ) NO-ERROR.
       RUN set-size IN h_folder ( 9.88 , 88.57 ) NO-ERROR.

       /* Links to SmartPanel h_p-exihel. */
       RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , THIS-PROCEDURE ).

       /* Links to SmartFolder h_folder. */
       RUN add-link IN adm-broker-hdl ( h_folder , 'Page':U , THIS-PROCEDURE ).

       /* Adjust the tab order of the smart objects. */
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-exihel ,
             fi-codigo:HANDLE IN FRAME f-cad , 'BEFORE':U ).
       RUN adjust-tab-order IN adm-broker-hdl ( h_folder ,
             fi-desc-retorno:HANDLE IN FRAME f-cad , 'AFTER':U ).
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
  DISPLAY fi-codigo fi-objeto fi-data-criacao fi-operacao fi-data-integracao 
          fi-aplicacao cb-metodo cb-dispositivo cb-retorno cb-requisicao 
          cb-processamento fi-destino fi-cod-status fi-desc-retorno 
      WITH FRAME f-cad IN WINDOW w-livre.
  ENABLE rt-button rtMain-3 rtMain rtMain-4 rtMain-2 fi-codigo fi-objeto
         fi-data-criacao fi-operacao fi-data-integracao fi-aplicacao fi-destino
         fi-cod-status fi-desc-retorno br-item br-conteudo bt-detalhar bt-reenviar
      WITH FRAME f-cad IN WINDOW w-livre.
  {&OPEN-BROWSERS-IN-QUERY-f-cad}
  VIEW w-livre.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-change-page w-livre 
PROCEDURE local-change-page :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    run dispatch      in this-procedure ( input 'change-page'  ).
    run get-attribute in this-procedure ( input 'current-page' ).

    case return-value.
        when '1' or
        when '0' then 
            assign br-item    :visible in frame f-cad = true
                   br-conteudo:visible in frame f-cad = false
                   bt-detalhar:visible in frame f-cad = false
                   .

        when '2' then 
            assign br-item    :visible in frame f-cad = false
                   br-conteudo:visible in frame f-cad = true
                   bt-detalhar:visible in frame f-cad = true
                   .
                   
    end case.
    
end procedure.

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
  run dispatch in THIS-PROCEDURE ( input 'destroy':U ) .
  {include/i-logfin.i}

  /* Code placed here will execute AFTER standard behavior.    */

end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-exit w-livre 
PROCEDURE local-exit :
/* -----------------------------------------------------------
  Purpose:  Starts an "exit" by APPLYing CLOSE event, which starts "destroy".
  Parameters:  <none>
  Notes:    If activated, should APPLY CLOSE, *not* dispatch adm-exit.   
-------------------------------------------------------------*/
  apply "CLOSE":U to this-procedure.
  
  return.
end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize w-livre 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

    //Code placed here will execute PRIOR to standard behavior
    run pi-before-initialize.
    
    {include/win-size.i}
    
    {utp/ut9000.i "thl1986b" "12.00.00.000"}
    
    //Dispatch standard ADM method.
    run dispatch in THIS-PROCEDURE ( input 'initialize':U ) .
    
    //Code placed here will execute AFTER standard behavior
    run pi-after-initialize.
    run local-change-page.
    
    empty temp-table tt-conteudo no-error.
    empty temp-table tt-item     no-error.
    
    find first thl-mensagem no-lock
        where thl-mensagem.codigo-mensagem = c-codigo-mensagem no-error.

    find first thl-objeto no-lock
        where thl-objeto.objeto = thl-mensagem.objeto no-error.
        
    if available thl-mensagem then do.
        
        assign fi-aplicacao      :screen-value in frame f-cad = thl-objeto.aplicacao
               fi-cod-status     :screen-value in frame f-cad = string ( thl-mensagem.cod-status-retorno )
               fi-codigo         :screen-value in frame f-cad = thl-mensagem.codigo-mensagem
               fi-data-criacao   :screen-value in frame f-cad = string( thl-mensagem.dt-criacao )
               fi-data-integracao:screen-value in frame f-cad = string( thl-mensagem.dt-integracao )
               fi-destino        :screen-value in frame f-cad = thl-mensagem.destino
               fi-objeto         :screen-value in frame f-cad = thl-mensagem.objeto
               fi-operacao       :screen-value in frame f-cad = thl-mensagem.operacao
               fi-desc-retorno   :screen-value in frame f-cad = thl-mensagem.descr-retorno
               cb-dispositivo    :screen-value in frame f-cad = string( thl-objeto.sentido-fluxo )
               cb-metodo         :screen-value in frame f-cad = string( thl-mensagem.metodo )
               cb-processamento  :screen-value in frame f-cad = string( thl-mensagem.sit-processamento )
               cb-requisicao     :screen-value in frame f-cad = string( thl-mensagem.sit-requisicao )
               cb-retorno        :screen-value in frame f-cad = string( thl-mensagem.sit-retorno    ). 
               
        for each thl-mensagem-conteudo of thl-mensagem.
            create tt-conteudo.
            buffer-copy thl-mensagem-conteudo to tt-conteudo
                assign tt-conteudo.descr-tipo = if thl-mensagem-conteudo.tipo-conteudo = 1 then 'Saida' else 'Entrada'. 
        end. 
        
        for each thl-mensagem-item of thl-mensagem.
            create tt-item.
            buffer-copy thl-mensagem-item to tt-item.
        end. 
        
        {&open-query-br-item}
        {&open-query-br-conteudo}        
        
    end.

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
  {src/adm/template/snd-list.i "tt-item"}
  {src/adm/template/snd-list.i "tt-conteudo"}

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
  define input parameter p-issuer-hdl as handle no-undo.
  define input parameter p-state as character no-undo.

  run pi-trata-state (p-issuer-hdl, p-state).
end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

