 
 /*------------------------------------------------------------------------
    File        : ConnectorService
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Tue Mar 10 16:56:15 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.


class thl-lib.integration.connectors.core.ConnectorResponse. 

    define public property successRequest  as logical   no-undo get. set. //Indica se a execução técnica foi realizada com sucesso
    define public property successResponse as logical   no-undo get. set. //Indica se a execução técnica foi realizada com sucesso
    define public property successProcess  as logical   no-undo get. set. //Indica se a execução técnica foi realizada com sucesso
    define public property statusCode      as integer   no-undo get. set. //Código de status técnico retornado pela integração
    define public property statusMessage   as character no-undo get. set. //Mensagem técnica resumida do processamento
    define public property content         as longchar  no-undo get. set. //Conteúdo retornado pela integração
    define public property destination     as character no-undo get. set.
    
end class.