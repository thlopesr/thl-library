 /*------------------------------------------------------------------------
    File        : HeaderProviderFactory
    Purpose     : Instancia dinamicamente uma implementacao de IHeaderProvider
                  a partir do nome da classe configurado em
                  thl-conexao-rest.classe-header-provider.
    Author(s)   : Lopes
    Created     : Sun Aug 24 00:00:00 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.integration.connectors.headers.interfaces.IHeaderProvider.
using thl-lib.util.string.StringUtil.
using thl-lib.core.error.ThlError.

block-level on error undo, throw.

class thl-lib.integration.connectors.headers.factory.HeaderProviderFactory.

    method public static IHeaderProvider getProvider ( className as character ).

        define variable provider as IHeaderProvider no-undo.

        if not StringUtil:hasValue( className ) then
            undo, throw new ThlError( 'HeaderProviderFactory', 'getProvider',
                'Classe do provider de header nao informada.' ).

        provider = dynamic-new className().

        if error-status:error         and
           not valid-object(provider) then
            undo, throw new ThlError( 'HeaderProviderFactory', 'getProvider',
                substitute( 'Nao foi possivel instanciar o provider de header: &1', className ) ).

        return provider.

    end method.

end class.
