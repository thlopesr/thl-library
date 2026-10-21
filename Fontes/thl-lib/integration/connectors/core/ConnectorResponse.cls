 
 /*------------------------------------------------------------------------
    File        : ConnectorResponse
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Tue Mar 10 16:56:15 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.


class thl-lib.integration.connectors.core.ConnectorResponse. 

    define public property successRequest  as logical   no-undo get. set. 
    define public property successResponse as logical   no-undo get. set. 
    define public property successProcess  as logical   no-undo get. set. 
    define public property statusCode      as integer   no-undo get. set. 
    define public property statusMessage   as character no-undo get. set. 
    define public property content         as longchar  no-undo get. set. 
    define public property destination     as character no-undo get. set.
    
end class.