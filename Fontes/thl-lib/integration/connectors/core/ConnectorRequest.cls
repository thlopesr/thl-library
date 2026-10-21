 
 /*------------------------------------------------------------------------
    File        : ConnectorRequest
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Tue Mar 10 16:56:15 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

using thl-lib.integration.connectors.core.ConnectorConfig.
using Progress.Json.ObjectModel.*.

class thl-lib.integration.connectors.core.ConnectorRequest.  

    define public property connectorType      as integer         no-undo get. set. 
    define public property methodType         as integer         no-undo get. set.
    define public property content            as JsonConstruct   no-undo get. set. 
    define public property contentText        as longchar        no-undo get. set.
    define public property connectorConfig    as ConnectorConfig no-undo get. set. 
    define public property pathParameters     as JsonArray       no-undo get. set.  
    
end class.