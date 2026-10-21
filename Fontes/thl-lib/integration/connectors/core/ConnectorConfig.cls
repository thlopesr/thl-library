 /*------------------------------------------------------------------------
    File        : ConnectorConfig
    Purpose     :
    Syntax      :
    Description :
    Author(s)   : Lopes
    Created     : Tue Mar 10 16:56:15 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.core.environment.EnvironmentResource.
using thl-lib.integration.connectors.auth.core.AuthenticationConfig.
using thl-lib.core.error.ThlError.

block-level on error undo, throw.

class thl-lib.integration.connectors.core.ConnectorConfig.

    define public  property baseUrl                as character            no-undo get. set.
    define public  property requiresAuthentication as logical              no-undo get. set.
    define private property connectionCode         as character            no-undo get. private set.
    define public  property path                   as character            no-undo get. set.
    define public  property contentType            as character            no-undo get. set.
    define public  property accept                 as character            no-undo get. set.
    define public  property headers                as character            no-undo get. set.
    define public  property parameters             as character            no-undo get. set.
    define public  property timeout                as integer              no-undo get. set.
    define public  property requiresHeaderProvider as logical              no-undo get. set.
    define public  property headerProviderClass    as character            no-undo get. set.
    define public  property headerParameter        as character            no-undo get. set.
    define public  property authentication         as AuthenticationConfig no-undo get. set.

    define buffer b-thl-conexao-rest        for thl-conexao-rest.
    define buffer b-thl-conexao-rest-path   for thl-conexao-rest-path.
    define buffer b-thl-conexao-rest-header for thl-conexao-rest-header.

    constructor public ConnectorConfig ( programName        as character ,
                                         parameterCode      as character ,
                                         routeParameterCode as character ).

        define variable pathCode            as character           no-undo.
        define variable environmentResource as EnvironmentResource no-undo.

        assign environmentResource        = new EnvironmentResource( programName )
               this-object:connectionCode = environmentResource:getEnvironmentVariable( parameterCode      )
               pathCode                   = environmentResource:getEnvironmentVariable( routeParameterCode ).

        if this-object:connectionCode = '' or this-object:connectionCode = ? then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor',
                substitute( 'Codigo de conexao REST nao informado para o parametro de ambiente: &1 - &2',
                            programName, parameterCode ) ).

        if pathCode = '' or pathCode = ? then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor',
                substitute( 'Codigo de path REST nao informado para o parametro de ambiente: &1 - &2',
                            programName, routeParameterCode ) ).

        find first b-thl-conexao-rest no-lock
            where b-thl-conexao-rest.cod-conexao = this-object:connectionCode no-error.

        if not available b-thl-conexao-rest then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor',
                substitute( 'Codigo de conexao REST nao encontrada: &1 - &2 - &3',
                            programName, parameterCode, this-object:connectionCode ) ).

        find first b-thl-conexao-rest-path no-lock
            where b-thl-conexao-rest-path.cod-path = pathCode no-error.

        if not available b-thl-conexao-rest-path then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor',
                substitute( 'Conexao REST PATH nao encontrada: &1 - &2', pathCode, this-object:connectionCode ) ).

        this-object:initialize( b-thl-conexao-rest.url-base                  ,
                                b-thl-conexao-rest.ind-requisita-autenticacao ,
                                b-thl-conexao-rest-path.path                  ,
                                b-thl-conexao-rest-path.content-type          ,
                                b-thl-conexao-rest-path.accept                ,
                                b-thl-conexao-rest-path.headers               ,
                                b-thl-conexao-rest-path.parameters            ,
                                b-thl-conexao-rest-path.timeout               ).

        assign this-object:authentication = if this-object:requiresAuthentication
                                            then new AuthenticationConfig( this-object:connectionCode )
                                            else new AuthenticationConfig().

        if b-thl-conexao-rest.ind-requisita-header then do:

            find first b-thl-conexao-rest-header no-lock
                where b-thl-conexao-rest-header.cod-conexao = this-object:connectionCode no-error.

            if not available b-thl-conexao-rest-header then
                undo, throw new ThlError( this-object:GetClass():TypeName, 'constructor',
                    substitute( 'Configuracao de header nao encontrada para conexao: &1',
                                this-object:connectionCode ) ).

            assign this-object:requiresHeaderProvider = true
                   this-object:headerProviderClass    = b-thl-conexao-rest-header.classe-parser
                   this-object:headerParameter        = b-thl-conexao-rest-header.parameters.

        end.

    end constructor.

    constructor public ConnectorConfig ( authentication as AuthenticationConfig ).

        this-object:initialize( authentication:tokenUrl         ,
                                false                           ,
                                ''                              ,
                                authentication:tokenContentType ,
                                authentication:tokenAccept      ,
                                authentication:tokenHeaders     ,
                                authentication:tokenParameters  ,
                                authentication:tokenTimeout     ).

        assign this-object:authentication = new AuthenticationConfig().

    end constructor.

    method private void initialize( baseUrl                as character ,
                                    requiresAuthentication as logical   ,
                                    path                   as character ,
                                    contentType            as character ,
                                    accept                 as character ,
                                    headers                as longchar  ,
                                    parameters             as longchar  ,
                                    timeout                as integer   ).

        assign this-object:baseUrl                = baseUrl
               this-object:requiresAuthentication = requiresAuthentication
               this-object:path                   = path
               this-object:contentType            = contentType
               this-object:accept                 = accept
               this-object:headers                = headers
               this-object:parameters             = parameters
               this-object:timeout                = timeout
               .

    end method.

end class.
