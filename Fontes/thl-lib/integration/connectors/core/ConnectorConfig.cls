 
 /*------------------------------------------------------------------------
    File        : ConnectorService
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Tue Mar 10 16:56:15 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.core.environment.EnvironmentResource.

class thl-lib.integration.connectors.core.ConnectorConfig. 

    define public property baseUrl                as character no-undo get. set. //URL/base do serviço
    define public property path                   as character no-undo get. set. //Caminho complementar do endpoint
    define public property timeout                as integer   no-undo get. set. //Timeout da execução em segundos 
    define public property requiresTokenRequest   as logical   no-undo get. set. //E obrigatório/necessário existe uma requisição prévia para obter credencial/chave
    define public property pathToken              as character no-undo get. set. //Caminho complementar do endpoint 
    define public property contentType            as character no-undo get. set. //Tipo de conteúdo JSON / XML / TEXT 
    define public property authenticationType     as character no-undo get. set. //Tipo de autenticação NONE / BASIC / BEARER / TOKEN 
    define public property token                  as character no-undo get. set. //Token ou credencial resolvida 
    define public property headers                as character no-undo get. set. //Cabeçalhos dinâmicos 
    define public property parameters             as character no-undo get. set. //Parâmetros adicionais 
    define public property userName               as character no-undo get. set.  
    define public property password               as character no-undo get. set.
    define public property useServicePointManager as logical   no-undo get. set.
    
    constructor public ConnectorConfig ( parameterCode      as character ,
                                         routeParameterCode as character ).

        //EnvironmentResource:setParameters().
        
        initialize (          EnvironmentResource:getEnvironmentVariable( parameterCode     , 'baseUrl'              ) ,
                              EnvironmentResource:getEnvironmentVariable( routeParameterCode, 'path'                 ) ,
                              EnvironmentResource:getEnvironmentVariable( parameterCode     , 'pathToken'            ) ,
                              EnvironmentResource:getEnvironmentVariable( parameterCode     , 'requiresTokenRequest' ) = 'Sim', 
                              EnvironmentResource:getEnvironmentVariable( parameterCode     , 'authenticationType'   ) ,
                              EnvironmentResource:getEnvironmentVariable( parameterCode     , 'token'                ) ,
                     integer( EnvironmentResource:getEnvironmentVariable( parameterCode     , 'timeout'              )),
                              EnvironmentResource:getEnvironmentVariable( routeParameterCode, 'contentType'          ) ,
                              EnvironmentResource:getEnvironmentVariable( routeParameterCode, 'headers'              ) ,
                              EnvironmentResource:getEnvironmentVariable( routeParameterCode, 'parameters'           ) ,
                              EnvironmentResource:getEnvironmentVariable( parameterCode     , 'userName'             ) ,
                              EnvironmentResource:getEnvironmentVariable( parameterCode     , 'password'             ) ).
    end constructor.

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    method public void initialize( baseUrl              as character ,
                                   path                 as character ,
                                   pathToken            as character ,
                                   requiresTokenRequest as logical   ,
                                   authenticationType   as character ,
                                   token                as character ,
                                   timeout              as integer   ,
                                   contentType          as character ,
                                   headers              as character ,
                                   parameters           as character ,
                                   userName             as character ,
                                   password             as character ).
        
        assign this-object:baseUrl              = baseUrl              
               this-object:path                 = path                 
               this-object:pathToken            = pathToken 
               this-object:requiresTokenRequest = requiresTokenRequest 
               this-object:authenticationType   = authenticationType   
               this-object:token                = token                
               this-object:headers              = headers              
               this-object:parameters           = parameters
               this-object:timeout              = timeout              
               this-object:contentType          = contentType
               this-object:userName             = userName
               this-object:password             = password.

    end method.    

end class.
