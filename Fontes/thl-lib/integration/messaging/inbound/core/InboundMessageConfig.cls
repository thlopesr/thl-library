/*------------------------------------------------------------------------
    File        : InboundMessageConfig
    Purpose     : Configuracao de uma mensagem de entrada: a comum
                  (MessageConfig) mais o que so o inbound usa - as classes de
                  orquestracao e de service e o contrato do payload.
    Author(s)   : Lopes
    Created     : 2026-10-04
    Notes       : Montada pelo InboundConfigLoader. Classes: as da operacao
                  ou, em branco, as do objeto. Contrato: campos obrigatorios e
                  campos da chave externa da extensao REST da operacao
                  (thl-objeto-parametro-rest), em array JSON de texto.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

using thl-lib.integration.messaging.core.MessageConfig.

block-level on error undo, throw.

class thl-lib.integration.messaging.inbound.core.InboundMessageConfig inherits MessageConfig.

    define public property processorClass          as character no-undo get. protected set.
    define public property serviceClass            as character no-undo get. protected set.
    define public property requiredFields          as character no-undo get. protected set.
    define public property externalReferenceFields as character no-undo get. protected set.

    constructor public InboundMessageConfig( objectName           as character ,
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
                                             contentStorage       as integer   ,
                                             processorClass       as character ,
                                             serviceClass         as character ).

        super( objectName, applicationName, methodType, messageClass, connectorType, historyEnabled,
               integrationDirection, executionModeValue, isSingle, parameterCode, routeParameterCode,
               integrationOperation, contentStorage ).

        assign this-object:processorClass = processorClass
               this-object:serviceClass   = serviceClass.

    end constructor.

    //Contrato do payload cadastrado na operacao (arrays JSON de texto)
    method public void setContract( input requiredFields          as character ,
                                    input externalReferenceFields as character ).

        assign this-object:requiredFields          = requiredFields
               this-object:externalReferenceFields = externalReferenceFields.

    end method.

end class.
