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
{include/i-prgvrs.i thl0150b 12.00.00.000}

/* Chamada a include do gerenciador de licencas. Necessario alterar os parametros */
/*                                                                                */
/* <programa>:  Informar qual o nome do programa.                                 */
/* <modulo>:  Informar qual o modulo a qual o programa pertence.                  */

{include/i-license-manager.i thl0150b thl}

create widget-pool.

/* Preprocessors Definitions ---                                      */
&GLOBAL-DEFINE Program        thl0150b
&GLOBAL-DEFINE Version        12.00.00.0000

&GLOBAL-DEFINE WindowType     Master/Detail

&GLOBAL-DEFINE Folder         NO
&GLOBAL-DEFINE InitialPage    0
&GLOBAL-DEFINE FolderLabels   

&GLOBAL-DEFINE page0Widgets   btOK BtCancel btHelp2 ~
fi-banco-ini fi-banco-fin fi-tabela-ini fi-tabela-fin fi-dat-criacao-ini fi-dat-criacao-fin fi-usuario-ini fi-usuario-fin
&GLOBAL-DEFINE page1Widgets   
&GLOBAL-DEFINE page2Widgets   

/* Parameters Definitions ---                                           */
define shared variable banco-ini        like thl-audit-registro.banco        no-undo.
define shared variable banco-fin        like thl-audit-registro.banco        no-undo.
define shared variable tabela-ini       like thl-audit-registro.tabela       no-undo.
define shared variable tabela-fin       like thl-audit-registro.tabela       no-undo.
define shared variable dat-criacao-ini  like thl-audit-registro.data-criacao no-undo.
define shared variable dat-criacao-fin  like thl-audit-registro.data-criacao no-undo.
define shared variable usuario-ini      like thl-audit-registro.usuario      no-undo.
define shared variable usuario-fin      like thl-audit-registro.usuario      no-undo.

define shared variable log_atualizar as logical no-undo.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE Window
&Scoped-define DB-AWARE no

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME fpage0

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rtToolBar IMAGE-1 IMAGE-2 IMAGE-5 IMAGE-6 ~
IMAGE-7 IMAGE-8 RECT-2 IMAGE-9 IMAGE-10 fi-banco-ini fi-banco-fin ~
fi-dat-criacao-ini fi-dat-criacao-fin btOK btCancel btHelp2 
&Scoped-Define DISPLAYED-OBJECTS fi-banco-ini fi-banco-fin fi-tabela-ini ~
fi-tabela-fin fi-dat-criacao-ini fi-dat-criacao-fin fi-usuario-ini ~
fi-usuario-fin 

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

DEFINE VARIABLE fi-banco-fin AS CHARACTER FORMAT "X(64)":U INITIAL "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ" 
     VIEW-AS FILL-IN 
     SIZE 32.57 BY .88 NO-UNDO.

DEFINE VARIABLE fi-banco-ini AS CHARACTER FORMAT "X(64)":U 
     LABEL "Banco" 
     VIEW-AS FILL-IN 
     SIZE 32.57 BY .88 NO-UNDO.

DEFINE VARIABLE fi-dat-criacao-fin AS DATETIME FORMAT "99/99/9999 HH:MM:SS":U 
     VIEW-AS FILL-IN 
     SIZE 21 BY .88 NO-UNDO.

DEFINE VARIABLE fi-dat-criacao-ini AS DATETIME FORMAT "99/99/9999 HH:MM:SS":U 
     LABEL "Data Criacao" 
     VIEW-AS FILL-IN 
     SIZE 21 BY .88 NO-UNDO.

DEFINE VARIABLE fi-tabela-fin AS CHARACTER FORMAT "X(100)":U INITIAL "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ" 
     VIEW-AS FILL-IN 
     SIZE 32.57 BY .88 NO-UNDO.

DEFINE VARIABLE fi-tabela-ini AS CHARACTER FORMAT "X(100)":U 
     LABEL "Tabela" 
     VIEW-AS FILL-IN 
     SIZE 32.57 BY .88 NO-UNDO.

DEFINE VARIABLE fi-usuario-fin AS CHARACTER FORMAT "X(100)":U INITIAL "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ" 
     VIEW-AS FILL-IN 
     SIZE 32.57 BY .88 NO-UNDO.

DEFINE VARIABLE fi-usuario-ini AS CHARACTER FORMAT "X(100)":U 
     LABEL "Usuario" 
     VIEW-AS FILL-IN 
     SIZE 32.57 BY .88 NO-UNDO.

DEFINE IMAGE IMAGE-1
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-10
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-2
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-5
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-6
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-7
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-8
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-9
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE RECTANGLE RECT-2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88.57 BY 4.25.

DEFINE RECTANGLE rtToolBar
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 88.57 BY 1.42
     BGCOLOR 7 .


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME fpage0
     fi-banco-ini AT ROW 1.33 COL 9.86 COLON-ALIGNED WIDGET-ID 4
     fi-banco-fin AT ROW 1.33 COL 51.29 COLON-ALIGNED NO-LABEL WIDGET-ID 176
     fi-tabela-ini AT ROW 2.33 COL 9.86 COLON-ALIGNED WIDGET-ID 20
     fi-tabela-fin AT ROW 2.33 COL 51.29 COLON-ALIGNED NO-LABEL WIDGET-ID 184
     fi-dat-criacao-ini AT ROW 3.33 COL 9.86 COLON-ALIGNED WIDGET-ID 16
     fi-dat-criacao-fin AT ROW 3.33 COL 51.29 COLON-ALIGNED NO-LABEL WIDGET-ID 178
     fi-usuario-ini AT ROW 4.33 COL 9.86 COLON-ALIGNED WIDGET-ID 214
     fi-usuario-fin AT ROW 4.33 COL 51.29 COLON-ALIGNED NO-LABEL WIDGET-ID 212
     btOK AT ROW 5.83 COL 3
     btCancel AT ROW 5.83 COL 14
     btHelp2 AT ROW 5.83 COL 79.43
     rtToolBar AT ROW 5.63 COL 1.72
     IMAGE-1 AT ROW 1.33 COL 45.57 WIDGET-ID 84
     IMAGE-2 AT ROW 1.33 COL 50 WIDGET-ID 86
     IMAGE-5 AT ROW 2.33 COL 45.57 WIDGET-ID 92
     IMAGE-6 AT ROW 2.33 COL 50 WIDGET-ID 94
     IMAGE-7 AT ROW 3.33 COL 45.57 WIDGET-ID 96
     IMAGE-8 AT ROW 3.33 COL 50 WIDGET-ID 98
     RECT-2 AT ROW 1.17 COL 1.72 WIDGET-ID 210
     IMAGE-9 AT ROW 4.33 COL 45.57 WIDGET-ID 216
     IMAGE-10 AT ROW 4.33 COL 50 WIDGET-ID 218
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 90 BY 6.33
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
         HEIGHT             = 6.33
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
/* SETTINGS FOR FILL-IN fi-tabela-fin IN FRAME fpage0
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tabela-ini IN FRAME fpage0
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-usuario-fin IN FRAME fpage0
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-usuario-ini IN FRAME fpage0
   NO-ENABLE                                                            */
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
ON CHOOSE OF btOK IN FRAME fpage0 /* OK */
do.
    
    assign log_atualizar = yes
           banco-ini       = fi-banco-ini      :input-value in frame {&frame-name} 
           banco-fin       = fi-banco-fin      :input-value in frame {&frame-name} 
           tabela-ini      = fi-tabela-ini     :input-value in frame {&frame-name} 
           tabela-fin      = fi-tabela-fin     :input-value in frame {&frame-name} 
           dat-criacao-ini = fi-dat-criacao-ini:input-value in frame {&frame-name} 
           dat-criacao-fin = fi-dat-criacao-fin:input-value in frame {&frame-name}
           usuario-ini     = fi-usuario-ini    :input-value in frame {&frame-name}
           usuario-fin     = fi-usuario-fin    :input-value in frame {&frame-name}.
           
    apply 'CLOSE':U to this-procedure.

end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-dat-criacao-fin
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-dat-criacao-fin wWindow
ON F5 OF fi-dat-criacao-fin IN FRAME fpage0
do.
  
    //run piBuscarFornecedor.

    //assign self:screen-value in frame {&FRAME-NAME} = return-value.

end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-dat-criacao-fin wWindow
ON mouse-select-dblclick OF fi-dat-criacao-fin IN FRAME fpage0
do.
    apply 'F5' to self.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-dat-criacao-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-dat-criacao-ini wWindow
ON F5 OF fi-dat-criacao-ini IN FRAME fpage0 /* Data Criacao */
do.
  
    //run piBuscarFornecedor.

    //assign self:screen-value in frame {&FRAME-NAME} = return-value.

end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-dat-criacao-ini wWindow
ON mouse-select-dblclick OF fi-dat-criacao-ini IN FRAME fpage0 /* Data Criacao */
do.
    apply 'F5' to self.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-tabela-fin
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-tabela-fin wWindow
ON F5 OF fi-tabela-fin IN FRAME fpage0
do.
  
    //run piBuscarFornecedor.

    //assign self:screen-value in frame {&FRAME-NAME} = return-value.

end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-tabela-fin wWindow
ON mouse-select-dblclick OF fi-tabela-fin IN FRAME fpage0
do.
    apply 'F5' to self.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-tabela-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-tabela-ini wWindow
ON F5 OF fi-tabela-ini IN FRAME fpage0 /* Tabela */
do.
  
    //run piBuscarFornecedor.

    //assign self:screen-value in frame {&FRAME-NAME} = return-value.

end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-tabela-ini wWindow
ON mouse-select-dblclick OF fi-tabela-ini IN FRAME fpage0 /* Tabela */
do.
    apply 'F5' to self.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-usuario-fin
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-usuario-fin wWindow
ON F5 OF fi-usuario-fin IN FRAME fpage0
do.
  
    //run piBuscarFornecedor.

    //assign self:screen-value in frame {&FRAME-NAME} = return-value.

end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-usuario-fin wWindow
ON mouse-select-dblclick OF fi-usuario-fin IN FRAME fpage0
do.
    apply 'F5' to self.
end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-usuario-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-usuario-ini wWindow
ON F5 OF fi-usuario-ini IN FRAME fpage0 /* Usuario */
do.
  
    //run piBuscarFornecedor.

    //assign self:screen-value in frame {&FRAME-NAME} = return-value.

end.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-usuario-ini wWindow
ON mouse-select-dblclick OF fi-usuario-ini IN FRAME fpage0 /* Usuario */
do.
    apply 'F5' to self.
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
    
    assign log_atualizar = no
           fi-banco-ini      :screen-value in frame {&frame-name} = banco-ini       
           fi-banco-fin      :screen-value in frame {&frame-name} = banco-fin       
           fi-tabela-ini     :screen-value in frame {&frame-name} = tabela-ini      
           fi-tabela-fin     :screen-value in frame {&frame-name} = tabela-fin      
           fi-dat-criacao-ini:screen-value in frame {&frame-name} = string( dat-criacao-ini, "99/99/9999 HH:MM:SS" )
           fi-dat-criacao-fin:screen-value in frame {&frame-name} = string( dat-criacao-fin, "99/99/9999 HH:MM:SS" )
           fi-usuario-ini    :screen-value in frame {&frame-name} = usuario-ini     
           fi-usuario-fin    :screen-value in frame {&frame-name} = usuario-fin.

end procedure.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

