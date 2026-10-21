using Progress.Lang.*.
using Progress.Json.ObjectModel.*.
using thl-lib.util.string.StringUtil.
using thl-lib.core.error.ThlError.

block-level on error undo, throw.

class thl-lib.integration.messaging.outbound.core.OutboundObjectContext.

    define public property recordId       as recid      no-undo get. private set.
    define public property referenceCode  as character  no-undo get. set.
    define public property additionalData as JsonObject no-undo get. set.

    constructor public OutboundObjectContext( input recordId as recid ).
        assign this-object:recordId = recordId.
    end constructor.

    constructor public OutboundObjectContext(input referenceCode as character).
        assign this-object:referenceCode = referenceCode.
    end constructor.

    constructor public OutboundObjectContext(input additionalData as JsonObject).
        assign this-object:additionalData = if valid-object(additionalData) then additionalData
                                                                            else new JsonObject().
    end constructor.

    constructor public OutboundObjectContext(input recordId       as recid,
                                             input referenceCode  as character,
                                             input additionalData as JsonObject).

        assign this-object:recordId       = recordId
               this-object:referenceCode  = referenceCode
               this-object:additionalData = new JsonObject()
               this-object:additionalData = additionalData.

    end constructor.

    constructor public OutboundObjectContext(input recordId              as recid,
                                             input referenceCode         as character,
                                             input additionalDataContent as character).

        assign this-object:recordId      = recordId
               this-object:referenceCode = referenceCode.

        this-object:addAdditionalData('content', additionalDataContent).

    end constructor.

    method private JsonObject setAdditionalData().
        if not valid-object(this-object:additionalData) then
            assign this-object:additionalData = new JsonObject().

        return this-object:additionalData.
    end method.

    method public logical hasAdditionalData().
        return valid-object(additionalData).
    end method.
    
    method public character getAdditionalDataContent().
        if not this-object:additionalData:Has('content') then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'getAdditionalDataContent', 'Nome do campo de conteudo de dados adicionais nao informado.' ).
        return this-object:additionalData:GetCharacter('content').
    end method.

    method public void addAdditionalData( input fieldName  as character,
                                          input fieldValue as character).

        if not StringUtil:hasValue( fieldName ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'addAdditionalData', 'Nome do campo de dados adicionais nao informado.' ).

        this-object:setAdditionalData():Add(fieldName, fieldValue).

    end method.

end class.