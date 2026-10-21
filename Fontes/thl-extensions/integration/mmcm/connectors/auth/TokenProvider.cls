 
 /*------------------------------------------------------------------------
    File        : TokenProvider
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Tue Mar 10 16:56:15 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.integration.connectors.auth.core.AuthenticationConfig.
using thl-lib.integration.connectors.auth.interfaces.ITokenProvider.

class thl-extensions.integration.mmcm.connectors.auth.TokenProvider implements ITokenProvider.

    method public void parsingToken ( authentication as AuthenticationConfig,
                                      response       as JsonObject          ). 
    
        define variable responseData as JsonObject no-undo.
        define variable tokenData    as JsonObject no-undo.
    
        if not response:Has('data') then
            undo, throw new ThlError(
                this-object:GetClass():TypeName,
                'parsingToken',
                'Resposta de autenticacao nao contem o node data.'
            ).
    
        responseData = response:GetJsonObject('data').
    
        if not valid-object(responseData) then
            undo, throw new ThlError(
                this-object:GetClass():TypeName,
                'parsingToken',
                'Node data da autenticacao e invalido.'
            ).
    
        if not responseData:Has('data') then
            undo, throw new ThlError(
                this-object:GetClass():TypeName,
                'parsingToken',
                'Node do token de autenticacao nao encontrado.'
            ).
    
        tokenData = responseData:GetJsonObject('data').
    
        if not valid-object(tokenData) then
            undo, throw new ThlError(
                this-object:GetClass():TypeName,
                'parsingToken',
                'Dados do token de autenticacao sao invalidos.'
            ).
    
        if not tokenData:Has('token') then
            undo, throw new ThlError(
                this-object:GetClass():TypeName,
                'parsingToken',
                'Token de autenticacao nao foi retornado.'
            ).
    
        authentication:saveToken(
            tokenData:GetCharacter('token'),
            tokenData:GetDatetime('validade')
        ).
    
    end method.

end class.