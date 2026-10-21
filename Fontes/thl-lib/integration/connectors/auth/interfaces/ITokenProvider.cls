 
 /*------------------------------------------------------------------------
    File        : ITokenProvider
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Tue Mar 10 16:56:15 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/
using Progress.Json.ObjectModel.*. 
using thl-lib.integration.connectors.auth.core.AuthenticationConfig.

interface thl-lib.integration.connectors.auth.interfaces.ITokenProvider.

    method public void parsingToken ( authentication as AuthenticationConfig, 
                                      response       as JsonObject          ).

end interface.