
/*------------------------------------------------------------------------
    File        : resource.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Lopes
    Created     : Mon Mar 23 20:54:18 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/
using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-lib.util.json.JsonSetter.
using thl-lib.integration.messaging.Inbound.service.InboundMessageService.
using thl-lib.integration.connectors.enum.MethodTypeEnum.

{utp/ut-api.i}
{utp/ut-api-action.i piPrincipal POST   /~*/~* }
{utp/ut-api-action.i piPrincipal PATCH  /~*/~* }
{utp/ut-api-action.i piPrincipal PUT    /~*/~* }
{utp/ut-api-action.i piPrincipal GET    /~*/~* }
{utp/ut-api-action.i piPrincipal DETELE /~*/~* }
{utp/ut-api-notfound.i}

{method/dbotterr.i}

//Procedures Internas   
procedure piPrincipal.

    define input  parameter request  as JsonObject no-undo.
    define output parameter response as JsonObject no-undo.

    define variable responsePayload as JsonConstruct         no-undo. 
    define variable queryParams     as JsonObject            no-undo.
           
    define variable method      as integer   no-undo. 
    define variable object      as character no-undo.
    
    assign queryParams    = new JsonAPIRequestParser(request):getQueryParams().
           
    if request:GetJsonArray('pathParams'):Length = 0 then
        undo, throw new AppError( 'Parametro nao localizado', 17006 ).
        
    assign method          = integer( MethodTypeEnum:GetEnum( request:GetCharacter('method')):GetValue() )
           object          = request:GetJsonArray('pathParams'):GetCharacter(1)
           responsePayload = new InboundMessageService( object, method ):receive( request:GetJsonObject('payload') ).
        
    //Tramento de Erros
    catch erro-progress as Progress.Lang.Error.
        
        define variable count as integer no-undo.
              
        create RowErrors.
        assign RowErrors.ErrorDescription = 'v01 - Erro no processamento'
               RowErrors.ErrorSubType     = 'ERROR'. 
    
        do count = 1 to erro-progress:NumMessages.  
            create RowErrors.
            assign RowErrors.ErrorNumber      = erro-progress:GetMessageNum(count)
                   RowErrors.ErrorDescription = erro-progress:GetMessage(count)
                   RowErrors.ErrorSubType     = 'ERROR'.  
        end. 
           
        return 'NOK':u.
    end catch.
    
    //Finalizacao do programa 
    finally.
        if temp-table RowErrors:has-records then 
            assign response = JsonAPIResponseBuilder:asError( temp-table RowErrors:handle ).
                
        else do.
            if valid-object( responsePayload ) then 
                assign response = if type-of( responsePayload, JsonArray ) then JsonAPIResponseBuilder:ok( cast( responsePayload, JsonArray  ), false )
                                                                           else JsonAPIResponseBuilder:ok( cast( responsePayload, JsonObject ), 201 ).
                        
        end.
                                                                            
    end finally.
    
end procedure.
