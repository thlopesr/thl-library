/*------------------------------------------------------------------------
    File        : ConexaoRestMessage
    Purpose     : Message do objeto CONEXAO-REST (agregado Conexao REST). Existe so
                  para mascarar segredo no conteudo gravado da mensagem; o
                  restante e o da InboundMessage padrao.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : O Service vem do cadastro (o do objeto ou, no filho, o da
                  linha da operacao); esta classe nao cria Service.
                  saveContentByType roda antes de o contexto existir
                  (InboundMessageService:accept), por isso a mascara nao
                  depende da operacao: age sobre qualquer item que traga os
                  campos sensiveis (ADR api-rest-cadastros-thl, secao 2.7).
                  Registrada em thl-objeto.classe-objeto pelo nome completo.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-extensions.erp.thl.service.ConexaoRestAutenticacaoService.
using thl-lib.integration.messaging.inbound.core.*.

block-level on error undo, throw.

class thl-extensions.integration.thl.messaging.inbound.message.ConexaoRestMessage inherits InboundMessage.

    constructor public ConexaoRestMessage ( objectName           as character ,
                                            applicationName      as character ,
                                            integrationOperation as character ,
                                            methodType           as integer   ,
                                            connectorType        as integer   ,
                                            integrationDirection as logical   ,
                                            executionMode        as integer   ).
        super( objectName, applicationName, integrationOperation, methodType, connectorType, integrationDirection, executionMode ).
    end constructor.

    //mascara no conteudo gravado, na entrada e na saida
    method public override void saveContentByType( input typeContent as int64    ,
                                                   input content     as longchar ).
        super:saveContentByType( typeContent, this-object:maskContent( content ) ).
    end method.

    method private longchar maskContent( input content as longchar ).

        define variable parsedContent as JsonConstruct     no-undo.
        define variable parser        as ObjectModelParser no-undo.
        define variable maskService   as ConexaoRestAutenticacaoService no-undo.

        assign parser        = new ObjectModelParser()
               parsedContent = parser:Parse( content )
               maskService   = new ConexaoRestAutenticacaoService().

        if type-of( parsedContent, JsonArray ) then do.
            this-object:maskArray( cast( parsedContent, JsonArray ), maskService ).
            return cast( parsedContent, JsonArray ):GetJsonText().
        end.

        if type-of( parsedContent, JsonObject ) then do.
            this-object:maskObject( cast( parsedContent, JsonObject ), maskService ).
            return cast( parsedContent, JsonObject ):GetJsonText().
        end.

        return content.

        //conteudo que nao e JSON (ex.: texto de erro) nao tem campo sensivel
        catch parseError as Progress.Lang.Error.
            return content.
        end catch.

    end method.

    //o resultado da consulta vem como { items: [...] }: mascara tambem os itens
    method private void maskArray( input itemList    as JsonArray ,
                                   input maskService as ConexaoRestAutenticacaoService ).

        define variable count as integer no-undo.

        do count = 1 to itemList:Length.
            if itemList:GetType( count ) = JsonDataType:OBJECT then
                this-object:maskObject( itemList:GetJsonObject( count ), maskService ).
        end.

    end method.

    method private void maskObject( input jsonItem    as JsonObject ,
                                    input maskService as ConexaoRestAutenticacaoService ).

        define variable fieldIndex as integer   no-undo.
        define variable fieldName  as character no-undo.

        do fieldIndex = 1 to num-entries( maskService:SensitiveFields ).

            assign fieldName = entry( fieldIndex, maskService:SensitiveFields ).

            if jsonItem:Has( fieldName ) and
               jsonItem:GetType( fieldName ) = JsonDataType:STRING and
               jsonItem:GetCharacter( fieldName ) <> '' then
                jsonItem:Set( fieldName, maskService:MaskedValue ).

        end.

        if jsonItem:Has( 'items' ) and jsonItem:GetType( 'items' ) = JsonDataType:ARRAY then
            this-object:maskArray( jsonItem:GetJsonArray( 'items' ), maskService ).

    end method.

    //cadastro interno: nao ha referencia de sistema externo
    method protected override character getExternalReferenceField().
        return ''.
    end method.

end class.
