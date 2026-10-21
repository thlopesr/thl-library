 
 /*------------------------------------------------------------------------
    File        : RestConnector
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Tue Mar 10 16:56:15 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/
using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using System.IO.*.
using System.Net.*.
using System.Text.*.
using System.Net.SecurityProtocolType.
using System.Net.ServicePointManager.

using thl-lib.integration.connectors.core.*.
using thl-lib.integration.connectors.types.IntegrationConnector.
using thl-lib.integration.connectors.enum.MethodTypeEnum.
using thl-lib.integration.connectors.auth.factory.TokenProviderFactory.
using thl-lib.integration.connectors.auth.interfaces.ITokenProvider.
using thl-lib.integration.connectors.auth.core.AuthenticationConfig.
using thl-lib.integration.connectors.headers.interfaces.IHeaderProvider.
using thl-lib.integration.connectors.headers.factory.HeaderProviderFactory.
using thl-lib.util.string.StringUtil.
using thl-lib.core.error.ThlError.

block-level on error undo, throw.

class thl-lib.integration.connectors.types.RestConnector inherits IntegrationConnector.

    method public override ConnectorResponse execute( input connectorRequest as ConnectorRequest).

        define variable connectorResponse as ConnectorResponse no-undo.
        define variable requestUrl        as character         no-undo.
        define variable authorizationKey  as character         no-undo.
        define variable responseContent   as longchar          no-undo.

        assign connectorResponse = new ConnectorResponse().

        this-object:validateExecutionInput(connectorRequest).

        assign requestUrl                    = buildRequestUrl(connectorRequest)
               connectorResponse:destination = requestUrl
               authorizationKey              = resolveAuthorizationKey(connectorRequest:connectorConfig)
               responseContent               = executeRequest( requestUrl       ,
                                                               connectorRequest ,
                                                               authorizationKey ,
                                                               connectorResponse)
               connectorResponse:successRequest  = true
               connectorResponse:successResponse = isTechnicalSuccess( connectorResponse:statusCode )
               connectorResponse:content         = responseContent.

        return connectorResponse.

        catch err as Progress.Lang.Error.
            assign connectorResponse:successRequest  = false
                   connectorResponse:successResponse = false
                   connectorResponse:statusCode      = if connectorResponse:statusCode <> 0 then connectorResponse:statusCode
                                                                                            else 17006
                   connectorResponse:statusMessage   = 'Technical error during REST execution: ' + err:GetMessage(1) 
                   .
            return connectorResponse.
        end catch.

    end method.

    method protected void validateExecutionInput(input connectorRequest as ConnectorRequest).

        if not valid-object(connectorRequest) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateExecutionInput', 'ConnectorRequest nao informado.' ).

        if not valid-object(connectorRequest:connectorConfig) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateExecutionInput', 'ConnectorConfig nao informado.' ).

        if connectorRequest:connectorConfig:requiresAuthentication        and
           not valid-object(connectorRequest:connectorConfig:authentication) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateExecutionInput', 'AuthenticationConfig nao informado para uma conexao que requer autenticacao.' ).

    end method.

    method protected character buildRequestUrl( input connectorRequest as ConnectorRequest).
        define variable resolvedPath as character no-undo.
    
        assign resolvedPath = this-object:resolvePathParameters( connectorRequest:connectorConfig:path,
                                                                 connectorRequest:pathParameters      ).
    
        if StringUtil:hasValue( connectorRequest:connectorConfig:parameters ) then
            return connectorRequest:connectorConfig:baseUrl
                 + resolvedPath
                 + connectorRequest:connectorConfig:parameters.
    
        return connectorRequest:connectorConfig:baseUrl
             + resolvedPath.
        
    end method.
    
    method protected character resolvePathParameters( input pathTemplate   as character ,
                                                      input pathParameters as JsonArray ).

        define variable count as integer no-undo.

        if valid-object (pathParameters) then do.
            do count = 1 to pathParameters:Length.
                assign pathTemplate = replace( pathTemplate                                             , 
                                               pathParameters:GetJsonObject(count):getcharacter('name') ,
                                               pathParameters:GetJsonObject(count):getcharacter('value')).
            end.
        end.
    
        return pathTemplate.
    
    end method.
    
    method protected character resolveAuthorizationKey ( connectorConfig as ConnectorConfig ).

        define variable authentication as AuthenticationConfig no-undo.

        assign authentication = connectorConfig:authentication.

        if not valid-object(authentication) then
            return ''.

        if authentication:requiresTokenRequest then do.
            if authentication:isTokenExpired() then
                executeTokenRequest(authentication).
            return authentication:token.
        end.

        return ''.

    end method.

    method protected void executeTokenRequest( authentication as AuthenticationConfig).

        define variable tokenRequest    as ConnectorRequest  no-undo.
        define variable tokenResponse   as ConnectorResponse no-undo.
        define variable responseContent as longchar          no-undo.
        define variable response        as JsonObject        no-undo.
        define variable tokenUrl        as character         no-undo.
 
        assign tokenRequest                  = new ConnectorRequest()
               tokenResponse                 = new ConnectorResponse()
               tokenUrl                      = authentication:tokenUrl
               tokenRequest:connectorConfig  = new ConnectorConfig( authentication )
               tokenRequest:methodType       = MethodTypeEnum:POST:getValue()
               tokenRequest:contentText      = authentication:rawTokenData
               responseContent               = executeRequest( tokenUrl      ,
                                                               tokenRequest  , 
                                                               ''            ,
                                                               tokenResponse ).

        if not isTechnicalSuccess( tokenResponse:statusCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'executeTokenRequest', 'Erro ao obter chave de autorizacao.' ).

        if responseContent = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'executeTokenRequest', 'Conteudo da resposta de erro e nulo.' ).

        assign response = cast( new ObjectModelParser():Parse(responseContent), JsonObject ).

        if not valid-object(response) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'executeTokenRequest', 'Erro ao parsear resposta do token.' ).
            
        TokenProviderFactory:getProvider( authentication:tokenParserClass ):parsingToken( authentication, response).
        

    end method.

    method protected longchar executeRequest( input        requestUrl        as character         ,
                                              input        connectorRequest  as ConnectorRequest  ,
                                              input        authorizationKey  as character         ,
                                              input-output connectorResponse as ConnectorResponse ).

        define variable request         as HttpWebRequest   no-undo.
        define variable response        as HttpWebResponse  no-undo.
        define variable responseContent as longchar         no-undo.

        assign request = createHttpRequest( requestUrl       ,
                                            connectorRequest ,
                                            authorizationKey ).

        this-object:writeRequestContent(request, connectorRequest).

        assign response        = cast(request:GetResponse(), HttpWebResponse)
               responseContent = readResponseContent(response)
               connectorResponse:statusCode    = response:StatusCode:value__
               connectorResponse:statusMessage = response:StatusDescription.

        return normalizeResponseContent(responseContent).

        catch webError as WebException.

            responseContent = readErrorResponse( webError, connectorResponse).
            return responseContent.

        end catch.

        finally:
            if valid-object(response) then
                response:Close().
        end finally.

    end method.

    method protected HttpWebRequest createHttpRequest( requestUrl       as character       ,
                                                       connectorRequest as ConnectorRequest,
                                                       authorizationKey as character       ).

        define variable request as HttpWebRequest no-undo.

        assign ServicePointManager:Expect100Continue = true       
               ServicePointManager:SecurityProtocol  = SecurityProtocolType:Tls12
               request                               = cast( WebRequest:Create(requestUrl), HttpWebRequest)
               request:KeepAlive                     = false
               request:Timeout                       = connectorRequest:connectorConfig:timeout
               request:Accept                        = connectorRequest:connectorConfig:accept
               request:Method                        = resolveHttpMethod( connectorRequest:methodType )
               request:ContentType                   = getContentType( connectorRequest:connectorConfig ).
            
        setHeader( request, connectorRequest:connectorConfig:headers ).

        applyAuthentication( request          ,
                             connectorRequest ,
                             authorizationKey ).

        applyCalculatedHeaders( request, connectorRequest ).

        return request.

    end method.
    
    method protected void setHeader ( input request         as HttpWebRequest,
                                      input headersParameter as character     ).

        define variable headers as JsonArray no-undo.
        define variable count   as integer   no-undo.
        
        if StringUtil:hasValue( headersParameter ) then do.
            
            assign headers = cast( new ObjectModelParser():Parse(headersParameter), JsonArray).

            do count = 1 to headers:Length.
                request:Headers:add( headers:GetJsonObject(count):GetCharacter('key')   ,
                                     headers:GetJsonObject(count):GetCharacter('value') ).
            end.
            
        end.
        
    end method.
    
    method protected void writeRequestContent( input request          as HttpWebRequest  ,
                                               input connectorRequest as ConnectorRequest).

        define variable requestBytes as 'System.Byte[]' no-undo.

        if connectorRequest:contentText = ''    or 
           request:Method               = 'GET' then return.

        assign requestBytes = Encoding:UTF8:GetBytes(connectorRequest:contentText).

        request:GetRequestStream():Write(requestBytes, 0, requestBytes:Length).

    end method.

    method protected longchar readResponseContent(input response as HttpWebResponse):

        define variable responseContent as longchar no-undo.

        assign fix-codepage(responseContent) = 'UTF-8'
               responseContent               = new StreamReader( response:GetResponseStream(), Encoding:UTF8 ):ReadToEnd().
        return responseContent.

    end method.

    method protected longchar readErrorResponse( input        webError          as WebException      ,
                                                 input-output connectorResponse as ConnectorResponse ).

        define variable response        as HttpWebResponse no-undo.
        define variable responseContent as longchar        no-undo.

        if valid-object(webError:Response) then do.
        
            assign response                        = cast(webError:Response, HttpWebResponse)
                   responseContent                 = readResponseContent( response )
                   connectorResponse:statusCode    = response:StatusCode:value__
                   connectorResponse:statusMessage = response:StatusDescription + ' - ' + if length( responseContent ) > 3000 then 'Logger error'
                                                                                                                              else responseContent
                   .
            return responseContent.
        end.

        assign connectorResponse:statusCode    = 500
               connectorResponse:statusMessage = webError:Message.

        return ''.

    end method.

    method protected longchar normalizeResponseContent(input responseContent as longchar).
        if responseContent = '' then
            return ''.

        cast( new ObjectModelParser():Parse(responseContent), JsonConstruct):write( input-output responseContent ).

        return responseContent.
    end method.

    method protected void applyCalculatedHeaders( input request          as HttpWebRequest  ,
                                                  input connectorRequest as ConnectorRequest ).

        define variable provider as IHeaderProvider no-undo.
        define variable headers  as JsonArray       no-undo.
        define variable count    as integer         no-undo.

        if not connectorRequest:connectorConfig:requiresHeaderProvider then
            return.

        assign provider = HeaderProviderFactory:getProvider( connectorRequest:connectorConfig:headerProviderClass )
               headers  = provider:getHeaders( connectorRequest:contentText                    ,
                                               connectorRequest:connectorConfig:headerParameter )
               .

        do count = 1 to headers:Length:
            request:Headers:Add( headers:GetJsonObject(count):GetCharacter('key')   ,
                                 headers:GetJsonObject(count):GetCharacter('value') ).
        end.

    end method.

    method protected void applyAuthentication( request          as HttpWebRequest  ,
                                               connectorRequest as ConnectorRequest,
                                               authorizationKey as character       ).
        
        define variable authentication as AuthenticationConfig no-undo.
        
        assign authentication = connectorRequest:connectorConfig:authentication.

        if not valid-object(authentication) then return.

        case authentication:authenticationType.

            when 'BASIC' then 
                request:Headers:Add('Authorization', 'Basic ' + ConvertBase64( authentication:userName + ':' + authentication:password ) ).
            
            when 'BEARER' or
            when 'TOKEN'  then do.
                if StringUtil:hasValue( authorizationKey ) then
                    request:Headers:Add('KeyAuthentication', authorizationKey).
                else
                    if StringUtil:hasValue( authentication:token ) then
                        request:Headers:Add('Authorization', substitute('&1 &2', authentication:authenticationType, authentication:token )).
            end.
            when 'CUSTOM.BODY' then do.
                if type-of(connectorRequest:content, JsonObject) then do.
                    cast( connectorRequest:content, JsonObject):set( 'token', authorizationKey  ).
                    assign connectorRequest:contentText = cast( connectorRequest:content, JsonObject):GetJsonText().
                end.             
            end.
            
        end case.

    end method.

    method protected character ConvertBase64( input textValue as longchar ).
    
        define variable rawdata as memptr no-undo.

        copy-lob from textValue to rawdata convert target codepage 'utf-8'.

        return string( base64-encode(rawdata) ).

    end method.

    method protected character resolveHttpMethod( input methodType as integer ).
        return string( MethodTypeEnum:GetEnum(methodType) ). 
    end method.

    method protected character getContentType( input connectorConfig as ConnectorConfig ).

        if StringUtil:hasValue( connectorConfig:contentType ) then
            return connectorConfig:contentType.

        return 'application/json'.

    end method.

    method protected logical isTechnicalSuccess( input statusCode as integer ).
        return statusCode >= 200 and statusCode < 300.
    end method.

end class.