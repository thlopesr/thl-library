
/*------------------------------------------------------------------------
    File        : resource.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Lopes
    Created     : Mon Mar 23 20:54:18 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */
{utp/ut-api.i}
{utp/ut-api-action.i piPrincipal POST /~*/~* }
{utp/ut-api-notfound.i}

//{method/dbotterr.i}

define new shared temp-table rowErrors no-undo
    field ErrorSequence    as integer
    field ErrorNumber      as integer
    field ErrorDescription as character
    field ErrorParameters  as character
    field ErrorType        as character
    field ErrorHelp        as character
    field ErrorSubType     as character.  

define variable clJsonObject as JsonObject no-undo.
define variable queryParams  as JsonObject no-undo.
define variable clJsonArray  as JsonArray  no-undo.

/* ***************************  Main Block  *************************** */

/* Procedures Internas */    
procedure piPrincipal.

    define input  parameter jsonInput  as JsonObject no-undo.
    define output parameter jsonOutput as JsonObject no-undo.

    define variable requestParser as JsonAPIRequestParser no-undo.
        
    define variable cPathParams   as character no-undo.
    define variable iContador     as integer   no-undo. 
    define variable cRowErrors    as character no-undo.
    
    assign requestParser = new JsonAPIRequestParser(jsonInput)
           queryParams   = requestParser:getQueryParams()
           clJsonObject  = new JsonObject()
           clJsonArray   = new JSONArray()
           cPathParams   = if jsonInput:GetJsonArray('pathParams'):Length <> 0 then jsonInput:GetJsonArray('pathParams'):GetCharacter(1)
                                                                               else ''.

    case cPathParams.
        when 'embarque'  then run thl\integration\api\v1\embarque.p  ( jsonInput:GetJsonObject('payload') ).
        when 'documento' then run thl\integration\api\v1\documento.p ( jsonInput:GetJsonObject('payload') ).
        otherwise 
            undo, throw new Progress.Lang.AppError( 'Objeto nao localizado' , 17006).  
    end. 
    
    clJsonArray:add( 'V01' + cPathParams + '_' + return-value ). 
        
    //Tramento de Erros
    catch erro-progress as Progress.Lang.Error.
              
        create RowErrors.
        assign RowErrors.ErrorDescription = 'v01 - Erro no processamento'
               RowErrors.ErrorSubType     = 'ERROR'. 
    
        do iContador = 1 to erro-progress:NumMessages.  
            create RowErrors.
            assign RowErrors.ErrorNumber      = erro-progress:GetMessageNum(iContador)
                   RowErrors.ErrorDescription = erro-progress:GetMessage(iContador)
                   RowErrors.ErrorSubType     = 'ERROR'.  
        end. 
        //temp-table RowErrors:read-json('longchar', cRowErrors, 'empty'). 
           
        return 'NOK':u.
    end catch.
    
    //Finalizacao do programa 
    finally.
        assign jsonOutput = if temp-table RowErrors:has-records then JsonAPIResponseBuilder:asError( temp-table RowErrors:handle )    
                                                                else JsonAPIResponseBuilder:ok( clJsonArray, false ).                
    end finally.
    
end procedure.
