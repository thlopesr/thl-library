 /*------------------------------------------------------------------------
    File        : AuthenticationConfig
    Purpose     :
    Syntax      :
    Description :
    Author(s)   : Lopes
    Created     : Tue Mar 10 16:56:15 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

using thl-lib.util.string.StringUtil.
using thl-lib.core.error.ThlError.

block-level on error undo, throw.

class thl-lib.integration.connectors.auth.core.AuthenticationConfig.

    define public property tokenUrl             as character   no-undo get. set.
    define public property tokenContentType     as character   no-undo get. set.
    define public property tokenAccept          as character   no-undo get. set.
    define public property tokenHeaders         as longchar    no-undo get. set.
    define public property tokenParameters      as longchar    no-undo get. set.
    define public property tokenTimeout         as integer     no-undo get. set.

    define public property authenticationType   as character   no-undo get. set.
    define public property requiresTokenRequest as logical     no-undo get. set.

    define public property userName             as character   no-undo get. set.
    define public property password             as character   no-undo get. set.

    define public property token                as character   no-undo get. set.
    define public property rawTokenData         as longchar    no-undo get. set.
    define public property tokenExpiration      as datetime    no-undo get. set.

    define public property tokenParserClass     as character   no-undo get. set.
    define private property connectionCode      as character   no-undo get. private set.

    define private buffer b-thl-conexao-rest-autenticacao for thl-conexao-rest-autenticacao.

    constructor public AuthenticationConfig ().

        this-object:initialize( '',
                                '',
                                '',
                                '',
                                '',
                                0 ,
                                'No Auth',
                                false,
                                '',
                                '',
                                '',
                                '',
                                ? ,
                                ''
                            ).
    end constructor.

    constructor public AuthenticationConfig ( connectionCode as character ).

        assign this-object:connectionCode = connectionCode.

        // Guarda: connectionCode vazio gera mensagem clara antes de FIND invalido
        if trim( this-object:connectionCode ) = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor', 'Codigo de conexao de autenticacao nao informado.' ).

        find first b-thl-conexao-rest-autenticacao no-lock
            where b-thl-conexao-rest-autenticacao.cod-conexao = this-object:connectionCode no-error.

        if not available b-thl-conexao-rest-autenticacao then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor',
                substitute( 'Conexao autenticacao REST nao encontrada: &1', this-object:connectionCode ) ).

        this-object:initialize( b-thl-conexao-rest-autenticacao.url-token              ,
                                b-thl-conexao-rest-autenticacao.content-type-token     ,
                                b-thl-conexao-rest-autenticacao.accept-token           ,
                                b-thl-conexao-rest-autenticacao.headers-token          ,
                                b-thl-conexao-rest-autenticacao.parameters-token       ,
                                30000                                                   ,
                                b-thl-conexao-rest-autenticacao.tipo-autenticacao      ,
                                b-thl-conexao-rest-autenticacao.ind-requisita-token    ,
                                b-thl-conexao-rest-autenticacao.usuario                ,
                                b-thl-conexao-rest-autenticacao.senha                  ,
                                b-thl-conexao-rest-autenticacao.token                  ,
                                b-thl-conexao-rest-autenticacao.raw-token-data         ,
                                b-thl-conexao-rest-autenticacao.dt-expiracao-token     ,
                                b-thl-conexao-rest-autenticacao.classe-parser-token    ).

    end constructor.

    /*
     * Setter puro: apenas atribui valores. Sem acesso a DB, sem criação de objetos.
     * Privado: estado interno controlado apenas pelos construtores.
     */
    method private void initialize( tokenUrl             as character,
                                    tokenContentType     as character,
                                    tokenAccept          as character,
                                    tokenHeaders         as longchar ,
                                    tokenParameters      as longchar ,
                                    tokenTimeout         as integer  ,
                                    authenticationType   as character,
                                    requiresTokenRequest as logical  ,
                                    userName             as character,
                                    password             as character,
                                    token                as longchar ,
                                    rawTokenData         as longchar ,
                                    tokenExpiration      as datetime ,
                                    tokenParserClass     as character
                                  ).

        assign this-object:tokenUrl             = tokenUrl
               this-object:tokenContentType     = tokenContentType
               this-object:tokenAccept          = tokenAccept
               this-object:tokenHeaders         = tokenHeaders
               this-object:tokenParameters      = tokenParameters
               this-object:tokenTimeout         = tokenTimeout
               this-object:authenticationType   = authenticationType
               this-object:requiresTokenRequest = requiresTokenRequest
               this-object:userName             = userName
               this-object:password             = password
               this-object:token                = token
               this-object:rawTokenData         = rawTokenData
               this-object:tokenExpiration      = tokenExpiration
               this-object:tokenParserClass     = tokenParserClass
               .
        // connectionCode nao e parametro de initialize() - gerenciado pelos construtores.

    end method.

    method public logical isTokenExpired().

        if not StringUtil:hasValue( this-object:token ) then return yes.
        if this-object:tokenExpiration = ? then return yes.

        return this-object:tokenExpiration <= now.

    end method.

    /*
     * Atualiza estado em memoria apenas.
     * Persistencia em thl-conexao-rest-autenticacao e responsabilidade do chamador
     * (RestConnector.executeTokenRequest via AuthenticationRepository).
     */
    method public void saveToken ( accessToken    as longchar ,
                                   expirationDate as datetime ).

        assign this-object:token           = accessToken
               this-object:tokenExpiration = expirationDate.

    end method.

end class.
