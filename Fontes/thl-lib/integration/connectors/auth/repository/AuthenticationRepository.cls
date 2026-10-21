
 /*------------------------------------------------------------------------
    File        : AuthenticationRepository
    Purpose     :
    Syntax      :
    Description :
    Author(s)   : Lopes
    Created     : Wed May 28 00:00:00 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.core.error.ThlError.

block-level on error undo, throw.

class thl-lib.integration.connectors.auth.repository.AuthenticationRepository.

    define buffer b-thl-conexao-rest-autenticacao for thl-conexao-rest-autenticacao.

    method public void persistToken( connectionCode as character,
                                     accessToken    as longchar ,
                                     expirationDate as datetime ).

        find first b-thl-conexao-rest-autenticacao exclusive-lock
             where b-thl-conexao-rest-autenticacao.cod-conexao = connectionCode
             no-error.

        if not available b-thl-conexao-rest-autenticacao then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'persistToken', substitute( 'Conexao REST nao encontrada: &1', connectionCode ), 0 ).

        assign b-thl-conexao-rest-autenticacao.token              = accessToken
               b-thl-conexao-rest-autenticacao.dt-expiracao-token = expirationDate.

        release b-thl-conexao-rest-autenticacao no-error.

    end method.

end class.
