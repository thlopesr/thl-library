
/*------------------------------------------------------------------------
    File        : IntegrationConnector
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Wed Mar 11 13:36:02 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.integration.connectors.core.*.

class thl-lib.integration.connectors.types.IntegrationConnector abstract.
    
    method public abstract ConnectorResponse execute ( connectorRequest as ConnectorRequest ).  
end class.

