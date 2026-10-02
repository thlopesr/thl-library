# P8-L11-APLICADO
# formato: SEV|Classe|Metodo|Categoria|Status|Observacao-max-6-palavras
MEDIA|EmailParamRepository|loadRecipients|B4|APLICADO|guard-groupCode-vazio-return-vazio
MEDIA|EmailService|saveReturn|B1|APLICADO|error-status-error-adicionado-success
MEDIA|EmailParamRepository|loadEmailParameters-loadConnectionParameters|P3|APLICADO|3-AppError-prefixo-EmailParamRepository
MEDIA|RestConnector|validateExecutionInput-executeTokenRequest|P3|APLICADO|6-AppError-prefixo-RestConnector
MEDIA|MessageFactory|createStructureStrategy|P3|APLICADO|2-AppError-prefixo-MessageFactory
MEDIA|MessageConfigLoader|load-loadForInbound|P3|APLICADO|4-AppError-prefixo-MessageConfigLoader
MEDIA|ConnectorFactory|createConnector|P3|APLICADO|1-AppError-prefixo-ConnectorFactory
MEDIA|ConnectorConfig|initialize|P3|APLICADO|4-AppError-prefixo-ConnectorConfig
MEDIA|AuthenticationConfig|initialize|P3|APLICADO|2-AppError-prefixo-AuthenticationConfig
MEDIA|OutboundMessage|appendPayloadObject-addPathParameter|P3|APLICADO|4-AppError-prefixo-OutboundMessage
MEDIA|OutboundObjectContext|getAdditionalDataContent-getAdditionalData|P3|APLICADO|2-AppError-prefixo-OutboundObjectContext
MEDIA|InboundMessage|validatePayload-appendPayloadObject-defaults|P3|APLICADO|8-AppError-prefixo-InboundMessage
MEDIA|TokenProvider|parsingToken|P3|APLICADO|5-AppError-prefixo-TokenProvider
MEDIA|JsonWriter|toJsonFromBuffer|P3|APLICADO|1-AppError-prefixo-JsonWriter
MEDIA|RestConnector|execute|F3|PULADO|HTTP-em-uso-breaking-change-inviavel
# P8-L11-RESUMO
APLICADO:14|NAO-APLICAR:0|PULADO:1|TOTAL:15
