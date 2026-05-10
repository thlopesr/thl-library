&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
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

create widget-pool.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */
define new global shared variable c-codigo-objeto
    as character
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
&Scoped-define BROWSE-NAME br-item

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES <record-phrase>

/* Definitions for BROWSE br-item                                       */
&Scoped-define SELF-NAME br-item
&Scoped-define QUERY-STRING-br-item FOR EACH <record-phrase>
&Scoped-define OPEN-QUERY-br-item OPEN QUERY {&SELF-NAME} FOR EACH <record-phrase>.
&Scoped-define TABLES-IN-QUERY-br-item <record-phrase>
&Scoped-define FIRST-TABLE-IN-QUERY-br-item <record-phrase>


/* Definitions for FRAME f-cad                                          */
&Scoped-define OPEN-BROWSERS-IN-QUERY-f-cad ~
    ~{&OPEN-QUERY-br-item}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rt-button rtMain-3 rtMain rtMain-4 rtMain-2 ~
fi-codigo fi-objeto fi-data-criacao fi-operacao fi-data-integracao ~
fi-aplicacao fi-destino fi-cod-status fi-desc-retorno br-item 
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
define var w-livre as widget-handle no-undo.

/* Menu Definitions                                                     */
define sub-menu mi-programa 
       menu-item mi-consultas   label "Co&nsultas"     accelerator "CTRL-L"
       menu-item mi-imprimir    label "&Relat¢rios"    accelerator "CTRL-P"
       rule
       menu-item mi-sair        label "&Sair"          accelerator "CTRL-X".

define sub-menu m_Ajuda 
       menu-item mi-conteudo    label "&Conteudo"     
       menu-item mi-sobre       label "&Sobre..."     .

define menu m-livre menubar
       sub-menu  mi-programa    label "&Nome-do-Programa"
       sub-menu  m_Ajuda        label "&Ajuda"        .


/* Definitions of handles for SmartObjects                              */
define variable h_folder as handle no-undo.
define variable h_p-exihel as handle no-undo.

/* Definitions of the field level widgets                               */
define variable cb-dispositivo as logical format "Sa¡da/Entrada" initial no 
     label "Dispositivo" 
     view-as combo-box inner-lines 2
     list-items "Yes","No" 
     drop-down-list
     size 18 by 1 no-undo.

define variable cb-metodo as integer format "9":U initial 1 
     label "Metodo" 
     view-as combo-box inner-lines 5
     list-item-pairs "Post",1,
                     "Delete",2,
                     "Get",3,
                     "Update",4,
                     "Insert",5,
                     "Select",6
     drop-down-list
     size 18 by 1 no-undo.

define variable cb-processamento as integer format "9":U initial 4 
     label "Processamento" 
     view-as combo-box inner-lines 5
     list-item-pairs "Pendente",1,
                     "Erro",2,
                     "Sucesso",3,
                     "NÆo Cont‚m",4
     drop-down-list
     size 18 by 1 no-undo.

define variable cb-requisicao as integer format "9":U initial 4 
     label "Requisi‡Æo" 
     view-as combo-box inner-lines 5
     list-item-pairs "Pendente",1,
                     "Erro",2,
                     "Sucesso",3,
                     "NÆo Cont‚m",4
     drop-down-list
     size 18 by 1 no-undo.

define variable cb-retorno as integer format "9":U initial 4 
     label "Retorno" 
     view-as combo-box inner-lines 5
     list-item-pairs "Pendente",1,
                     "Erro",2,
                     "Sucesso",3,
                     "NÆo Cont‚m",4
     drop-down-list
     size 18 by 1 no-undo.

define variable fi-aplicacao as character format "x(80)" 
     label "Aplica‡Æo" 
     view-as fill-in 
     size 27.57 by .88.

define variable fi-cod-status as integer format ">>>9":U initial 0 
     label "C¢d. Status" 
     view-as fill-in 
     size 6.57 by .88 no-undo.

define variable fi-codigo as character format "X(64)" 
     label "Codigo" 
     view-as fill-in 
     size 40 by .88.

define variable fi-data-criacao as datetime format "99/99/9999 HH:MM:SS" 
     label "Data Criacao" 
     view-as fill-in 
     size 21 by .88.

define variable fi-data-integracao as datetime format "99/99/9999 HH:MM:SS" 
     label "Data Integracao" 
     view-as fill-in 
     size 21 by .88.

define variable fi-desc-retorno as character format "X(256)":U 
     view-as fill-in 
     size 59.14 by .88 no-undo.

define variable fi-destino as character format "X(256)":U 
     label "Destino" 
     view-as fill-in 
     size 66 by .88 no-undo.

define variable fi-objeto as character format "x(80)" 
     label "Objeto" 
     view-as fill-in 
     size 20 by .88.

define variable fi-operacao as character format "x(80)" 
     label "Operacao" 
     view-as fill-in 
     size 27.57 by .88.

define rectangle rt-button
     edge-pixels 2 graphic-edge    
     size 88.57 by 1.46
     bgcolor 7 .

define rectangle rtMain
     edge-pixels 2 graphic-edge  no-fill   
     size 88.57 by 1.25.

define rectangle rtMain-2
     edge-pixels 2 graphic-edge  no-fill   
     size 88.57 by 5.25.

define rectangle rtMain-3
     edge-pixels 2 graphic-edge  no-fill   
     size 88.57 by 1.25.

define rectangle rtMain-4
     edge-pixels 2 graphic-edge  no-fill   
     size 88.57 by 1.25.

/* Query definitions                                                    */
&ANALYZE-SUSPEND
define query br-item for 
      <record-phrase> SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
define browse br-item
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-item w-livre _FREEFORM
  query br-item display
      
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 84.14 BY 6.92
         FONT 4 FIT-LAST-COLUMN.


/* ************************  Frame Definitions  *********************** */

define frame f-cad
     fi-codigo at row 2.92 col 14 colon-aligned widget-id 88
     fi-objeto at row 4.42 col 14 colon-aligned widget-id 96
     fi-data-criacao at row 4.42 col 59 colon-aligned widget-id 90
     fi-operacao at row 5.42 col 14 colon-aligned widget-id 98
     fi-data-integracao at row 5.42 col 59 colon-aligned widget-id 92
     fi-aplicacao at row 6.42 col 14 colon-aligned widget-id 68
     cb-metodo at row 6.42 col 59 colon-aligned widget-id 78
     cb-dispositivo at row 7.42 col 14 colon-aligned help
          "Dispositivo" widget-id 76
     cb-retorno at row 7.42 col 58.86 colon-aligned widget-id 84
     cb-requisicao at row 8.42 col 14 colon-aligned widget-id 82
     cb-processamento at row 8.42 col 58.86 colon-aligned widget-id 80
     fi-destino at row 10 col 14 colon-aligned widget-id 94
     fi-cod-status at row 11.46 col 14 colon-aligned widget-id 86
     fi-desc-retorno at row 11.46 col 20.86 colon-aligned no-label widget-id 74
     br-item at row 14.29 col 4.57 widget-id 200
     rt-button at row 1.08 col 1.86
     rtMain-3 at row 9.79 col 1.86 widget-id 70
     rtMain at row 2.75 col 1.86 widget-id 100
     rtMain-4 at row 11.29 col 1.86 widget-id 72
     rtMain-2 at row 4.25 col 1.86 widget-id 102
    with 1 down no-box keep-tab-order overlay 
         side-labels no-underline three-d 
         at col 1 row 1
         size 90 by 21.79
         font 4 widget-id 100.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: SmartWindow
   Allow: Basic,Browse,DB-Fields,Query,Smart,Window
   Design Page: 2
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
if session:display-type = "GUI":U then
  create window w-livre assign
         hidden             = yes
         title              = "Template Livre <Insira complemento>"
         height             = 21.79
         width              = 90
         max-height         = 24.29
         max-width          = 90
         virtual-height     = 24.29
         virtual-width      = 90
         resize             = yes
         scroll-bars        = no
         status-area        = yes
         bgcolor            = ?
         fgcolor            = ?
         three-d            = yes
         message-area       = no
         sensitive          = yes.
else {&WINDOW-NAME} = current-window.

assign {&WINDOW-NAME}:MENUBAR    = menu m-livre:HANDLE.
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
assign 
       fi-aplicacao:READ-ONLY in frame f-cad        = true.

assign 
       fi-cod-status:READ-ONLY in frame f-cad        = true.

assign 
       fi-codigo:READ-ONLY in frame f-cad        = true.

assign 
       fi-data-criacao:READ-ONLY in frame f-cad        = true.

assign 
       fi-data-integracao:READ-ONLY in frame f-cad        = true.

assign 
       fi-desc-retorno:READ-ONLY in frame f-cad        = true.

assign 
       fi-destino:READ-ONLY in frame f-cad        = true.

assign 
       fi-objeto:READ-ONLY in frame f-cad        = true.

assign 
       fi-operacao:READ-ONLY in frame f-cad        = true.

if session:display-type = "GUI":U and VALID-HANDLE(w-livre)
then w-livre:hidden = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-item
/* Query rebuild information for BROWSE br-item
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH <record-phrase>.
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE br-item */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
on end-error of w-livre /* Template Livre <Insira complemento> */
or endkey of {&WINDOW-NAME} anywhere do:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  return no-apply.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
on window-close of w-livre /* Template Livre <Insira complemento> */
do:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  apply "CLOSE":U to this-procedure.
  return no-apply.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-consultas
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-consultas w-livre
on choose of menu-item mi-consultas /* Consultas */
do:
  run pi-consulta in h_p-exihel.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-conteudo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-conteudo w-livre
on choose of menu-item mi-conteudo /* Conteudo */
or help of frame {&FRAME-NAME}
do:
  run pi-ajuda in h_p-exihel.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-imprimir
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-imprimir w-livre
on choose of menu-item mi-imprimir /* Relat¢rios */
do:
  run pi-imprimir in h_p-exihel.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-programa
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-programa w-livre
on menu-drop of menu mi-programa /* Nome-do-Programa */
do:
  run pi-disable-menu.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-sair
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-sair w-livre
on choose of menu-item mi-sair /* Sair */
do:
  run pi-sair in h_p-exihel.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-sobre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-sobre w-livre
on choose of menu-item mi-sobre /* Sobre... */
do:
  {include/sobre.i}
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-item
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-livre 


/* ***************************  Main Block  *************************** */

/* Include custom  Main Block code for SmartWindows. */
{src/adm/template/windowmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects w-livre  _ADM-CREATE-OBJECTS
procedure adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/
  define variable adm-current-page  as integer no-undo.

  run get-attribute in THIS-PROCEDURE ('Current-Page':U).
  assign adm-current-page = integer(return-value).

  case adm-current-page: 

    when 0 then do:
       run init-object in THIS-PROCEDURE (
             input  'panel/p-exihel.w':U ,
             input  frame f-cad:HANDLE ,
             input  'Edge-Pixels = 2,
                     SmartPanelType = NAV-ICON,
                     Right-to-Left = First-On-Left':U ,
             output h_p-exihel ).
       run set-position in h_p-exihel ( 1.21 , 73.57 ) no-error.
       /* Size in UIB:  ( 1.25 , 16.00 ) */

       run init-object in THIS-PROCEDURE (
             input  'adm/objects/folder.r':U ,
             input  frame f-cad:HANDLE ,
             input  'FOLDER-LABELS = ':U + 'Requisi‡Æo|Retorno' + ',
                     FOLDER-TAB-TYPE = 1':U ,
             output h_folder ).
       run set-position in h_folder ( 12.75 , 2.00 ) no-error.
       run set-size in h_folder ( 9.88 , 88.57 ) no-error.

       /* Links to SmartPanel h_p-exihel. */
       run add-link in adm-broker-hdl ( h_p-exihel , 'State':U , this-procedure ).

       /* Links to SmartFolder h_folder. */
       run add-link in adm-broker-hdl ( h_folder , 'Page':U , this-procedure ).

       /* Adjust the tab order of the smart objects. */
       run adjust-tab-order in adm-broker-hdl ( h_p-exihel ,
             fi-codigo:HANDLE in frame f-cad , 'BEFORE':U ).
       run adjust-tab-order in adm-broker-hdl ( h_folder ,
             fi-desc-retorno:HANDLE in frame f-cad , 'AFTER':U ).
    end. /* Page 0 */

  end case.

end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available w-livre  _ADM-ROW-AVAILABLE
procedure adm-row-available :
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

end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI w-livre  _DEFAULT-DISABLE
procedure disable_UI :
/*------------------------------------------------------------------------------
  Purpose:     DISABLE the User Interface
  Parameters:  <none>
  Notes:       Here we clean-up the user-interface by deleting
               dynamic widgets we have created and/or hide 
               frames.  This procedure is usually called when
               we are ready to "clean-up" after running.
------------------------------------------------------------------------------*/
  /* Delete the WINDOW we created */
  if session:display-type = "GUI":U and VALID-HANDLE(w-livre)
  then delete widget w-livre.
  if this-procedure:persistent then delete procedure this-procedure.
end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI w-livre  _DEFAULT-ENABLE
procedure enable_UI :
/*------------------------------------------------------------------------------
  Purpose:     ENABLE the User Interface
  Parameters:  <none>
  Notes:       Here we display/view/enable the widgets in the
               user-interface.  In addition, OPEN all queries
               associated with each FRAME and BROWSE.
               These statements here are based on the "Other 
               Settings" section of the widget Property Sheets.
------------------------------------------------------------------------------*/
  display fi-codigo fi-objeto fi-data-criacao fi-operacao fi-data-integracao 
          fi-aplicacao cb-metodo cb-dispositivo cb-retorno cb-requisicao 
          cb-processamento fi-destino fi-cod-status fi-desc-retorno 
      with frame f-cad in window w-livre.
  enable rt-button rtMain-3 rtMain rtMain-4 rtMain-2 fi-codigo fi-objeto 
         fi-data-criacao fi-operacao fi-data-integracao fi-aplicacao fi-destino 
         fi-cod-status fi-desc-retorno br-item 
      with frame f-cad in window w-livre.
  {&OPEN-BROWSERS-IN-QUERY-f-cad}
  view w-livre.
end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-change-page w-livre 
procedure local-change-page :
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
            assign br-item             :visible in frame f-cad = true.

        when '2' then 
            assign br-item            :visible in frame f-cad = false.
    end case.
    
end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-destroy w-livre 
procedure local-destroy :
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
procedure local-exit :
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
procedure local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

    /* Code placed here will execute PRIOR to standard behavior. */
    run pi-before-initialize.
    
    {include/win-size.i}
    
    {utp/ut9000.i "thl1986" "12.00.00.000"}
    
    /* Dispatch standard ADM method.                             */
    run dispatch in THIS-PROCEDURE ( input 'initialize':U ) .
    
    /* Code placed here will execute AFTER standard behavior.    */
    //run pi-after-initialize.
    
    /*FIND FIRST thl-mensagem NO-LOCK
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

    END.*/

end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records w-livre  _ADM-SEND-RECORDS
procedure send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "<record-phrase>"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed w-livre 
procedure state-changed :
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

