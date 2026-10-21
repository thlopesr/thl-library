 
 /*------------------------------------------------------------------------
    File        : MessageConfig
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Sat Mar 07 08:34:45 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.integration.messaging.enum.ExecutionMode.

block-level on error undo, throw.

class thl-lib.integration.messaging.core.MessageConfig. 
    
    define public property objectName           as character     no-undo get. protected set.
    define public property applicationName      as character     no-undo get. protected set.
    define public property methodType           as integer       no-undo get. protected set.
    define public property messageClass         as character     no-undo get. protected set.
    define public property connectorType        as integer       no-undo get. protected set.
    define public property historyEnabled       as logical       no-undo get. protected set.
    define public property integrationDirection as logical       no-undo get. protected set.
    define public property executionModeValue   as ExecutionMode no-undo get. protected set.
    define public property isSingle             as logical       no-undo get. protected set.
    define public property parameterCode        as character     no-undo get. protected set.
    define public property routeParameterCode   as character     no-undo get. protected set.
    define public property integrationOperation as character     no-undo get. protected set.
    define public property contentStorage       as integer       no-undo get. protected set.
    
    constructor public MessageConfig( objectName           as character ,
                                      applicationName      as character ,
                                      methodType           as integer   ,
                                      messageClass         as character ,
                                      connectorType        as integer   ,
                                      historyEnabled       as logical   ,
                                      integrationDirection as logical   ,
                                      executionModeValue   as int64     ,
                                      isSingle             as logical   ,
                                      parameterCode        as character ,
                                      routeParameterCode   as character ,
                                      integrationOperation as character ,
                                      contentStorage       as integer   ).

        assign this-object:objectName           = objectName
               this-object:applicationName      = applicationName
               this-object:methodType           = methodType
               this-object:messageClass         = messageClass
               this-object:connectorType        = connectorType
               this-object:historyEnabled       = historyEnabled
               this-object:integrationDirection = integrationDirection
               this-object:executionModeValue   = ExecutionMode:GetEnum(executionModeValue)
               this-object:isSingle             = isSingle
               this-object:parameterCode        = parameterCode
               this-object:routeParameterCode   = routeParameterCode
               this-object:integrationOperation = integrationOperation
               this-object:contentStorage       = contentStorage
               .

    end constructor.
                      
end class.