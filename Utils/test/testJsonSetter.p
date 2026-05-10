
/*------------------------------------------------------------------------
    File        : testJsonSetter.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Lopes
    Created     : Wed Apr 29 12:44:45 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

using Progress.Json.ObjectModel.JsonObject from propath.
using thl-lib.util.json.JsonSetter.

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
    define variable LPCO  as JsonObject no-undo.

    assign LPCO = new JsonObject().
    
    LPCO:add('codigoEmitente', 13126).
    LPCO:add('numeroInternoLpco', 1).       
    LPCO:add('situacao', 4). 

    find first nit-lpco exclusive-lock
        where nit-lpco.cod-emitente     = LPCO:GetInteger('codigoEmitente') 
          and nit-lpco.num-interno-lpco = LPCO:GetInteger('numeroInternoLpco') no-error.
               
    assign JsonSetter:payload = LPCO.
    
    message nit-lpco.situacao
    view-as alert-box.
    
    JsonSetter:SetValue( input-output nit-lpco.situacao        , input 'situacao'  ).
    
    message nit-lpco.situacao
    view-as alert-box.