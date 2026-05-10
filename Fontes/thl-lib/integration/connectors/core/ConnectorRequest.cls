 
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

using thl-lib.integration.connectors.core.ConnectorConfig.

class thl-lib.integration.connectors.core.ConnectorRequest.  

    define public property connectorType      as integer         no-undo get. set. //Tipo de conector: Rest / SOAP / Database / File
    define public property methodType         as integer         no-undo get. set.
    define public property content            as longchar        no-undo get. set. //Conteúdo da execução: payload, comando SQL ou conteúdo de arquivo
    define public property connectorConfig    as ConnectorConfig no-undo get. set. // Configuração técnica da conexão
      
end class.