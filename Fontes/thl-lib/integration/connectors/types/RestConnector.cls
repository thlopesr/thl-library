 
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

routine-level on error undo, throw.

class thl-lib.integration.connectors.types.RestConnector inherits IntegrationConnector:

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
            undo, throw new AppError('ConnectorRequest was not informed.', 17006).

        if not valid-object(connectorRequest:connectorConfig) then
            undo, throw new AppError('ConnectorConfig was not informed.' , 17006).

    end method.

    method protected character buildRequestUrl( input connectorRequest as ConnectorRequest).
        if connectorRequest:connectorConfig:parameters <> '' then
            return connectorRequest:connectorConfig:baseUrl + connectorRequest:connectorConfig:path + connectorRequest:connectorConfig:parameters.
        return connectorRequest:connectorConfig:baseUrl + connectorRequest:connectorConfig:path.
    end method.

    method protected character resolveAuthorizationKey(input connectorConfig as ConnectorConfig):
        if connectorConfig:requiresTokenRequest then
            return executeTokenRequest(connectorConfig).
        return ''.
    end method.

    method protected character executeTokenRequest(input connectorConfig as ConnectorConfig):

        define variable tokenRequest    as ConnectorRequest  no-undo.
        define variable tokenResponse   as ConnectorResponse no-undo.
        define variable responseContent as longchar         no-undo.
        define variable responseJson    as JsonObject        no-undo.
        define variable tokenUrl        as character         no-undo.

        assign tokenRequest                  = new ConnectorRequest()
               tokenResponse                 = new ConnectorResponse()
               tokenUrl                      = connectorConfig:baseUrl + connectorConfig:pathToken
               tokenRequest:connectorConfig  = connectorConfig
               tokenRequest:methodType       = MethodTypeEnum:POST:getValue()
               tokenRequest:content          = connectorConfig:token
               responseContent               = executeRequest( tokenUrl      ,
                                                               tokenRequest  , 
                                                               ''            ,
                                                               tokenResponse ).

        if tokenResponse:statusCode <> 200 then
            undo, throw new AppError('Error obtaining authorization key.', 17006).

        if responseContent = '' then
            undo, throw new AppError('Error response content is null', 17006).
            
        assign responseJson = cast(new ObjectModelParser():Parse(responseContent), JsonObject).
        
        if not valid-object(responseJson) or
           not responseJson:Has('value')  then
            undo, throw new AppError('Error response', 17006). 
        
        return responseJson:GetCharacter('value').

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

    method protected HttpWebRequest createHttpRequest( input  requestUrl       as character       ,
                                                       input  connectorRequest as ConnectorRequest,
                                                       input  authorizationKey as character       ).

        define variable request as HttpWebRequest no-undo.

        assign ServicePointManager:Expect100Continue = true       
               ServicePointManager:SecurityProtocol  = SecurityProtocolType:Tls12
               request                               = cast( WebRequest:Create(requestUrl), HttpWebRequest)
               request:KeepAlive                     = false
               request:Accept                        = 'application/json'
               request:Method                        = resolveHttpMethod( connectorRequest:methodType )
               request:ContentType                   = getContentType( connectorRequest:connectorConfig ).
            
        setHeader( request, connectorRequest:connectorConfig:headers ).
        
        applyAuthentication( request                         ,
                             connectorRequest:connectorConfig,
                             authorizationKey                ).

        return request.

    end method.
    
    method protected void setHeader ( input request         as HttpWebRequest,
                                      input headersParamter as character     ).

        define variable headers as JsonArray no-undo.
        define variable count   as integer   no-undo.
        
        if headersParamter <> '' then do.
            
            assign headers = cast( new ObjectModelParser():Parse(headersParamter), JsonArray).

            do count = 1 to headers:Length.
                request:Headers:add( headers:GetJsonObject(count):GetCharacter('key')   ,
                                     headers:GetJsonObject(count):GetCharacter('value') ).
            end.
            
        end.
        
    end method.
    
    method protected void writeRequestContent( input request          as HttpWebRequest  ,
                                               input connectorRequest as ConnectorRequest).

        define variable requestBytes as 'System.Byte[]' no-undo.

        if connectorRequest:content = ''    or 
           request:Method           = 'GET' then return.

        assign requestBytes = Encoding:UTF8:GetBytes(connectorRequest:content).

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
                   connectorResponse:statusMessage = substitute( '&1 - &2', response:StatusDescription, responseContent )
                   .
            return normalizeResponseContent( responseContent ).
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

    method protected void applyAuthentication( input request          as HttpWebRequest ,
                                               input connectorConfig  as ConnectorConfig,
                                               input authorizationKey as character      ).
        
        case connectorConfig:authenticationType.

            when 'BASIC' then 
                request:Headers:Add('Authorization', 'Basic ' + ConvertBase64( connectorConfig:userName + ':' + connectorConfig:password ) ).
            
            when 'BEARER' or
            when 'TOKEN'  then do.
                if authorizationKey <> '' then
                    request:Headers:Add('KeyAuthentication', authorizationKey).
                else 
                    if connectorConfig:token <> '' then
                        request:Headers:Add('Authorization', substitute('&1 &2', connectorConfig:authenticationType, connectorConfig:token )).
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

        if connectorConfig:contentType <> '' then
            return connectorConfig:contentType.

        return 'application/json'.

    end method.

    method protected logical isTechnicalSuccess( input statusCode as integer ).
        return statusCode >= 200 and statusCode < 300.
    end method.

end class.