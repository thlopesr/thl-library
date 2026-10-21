 
 /*------------------------------------------------------------------------
    File        : TokenProviderFactory
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Tue Mar 10 16:56:15 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

using thl-lib.integration.connectors.auth.interfaces.ITokenProvider.
using thl-lib.util.string.StringUtil.
using thl-lib.core.error.ThlError.

block-level on error undo, throw.

class thl-lib.integration.connectors.auth.factory.TokenProviderFactory.

    method public static ITokenProvider getProvider ( className as character ).

        define variable provider as ITokenProvider no-undo.

        if not StringUtil:hasValue( className ) then
            undo, throw new ThlError( 'TokenProviderFactory', 'getProvider', 'Classe do provider de token nao informada.', 17005 ).

        provider = dynamic-new className().

        if error-status:error         and
           not valid-object(provider) then 
            undo, throw new ThlError( 'TokenProviderFactory', 'getProvider', substitute( 'Nao foi possivel instanciar o provider de token: &1', className ) ).

        return provider.

    end method.

end class.