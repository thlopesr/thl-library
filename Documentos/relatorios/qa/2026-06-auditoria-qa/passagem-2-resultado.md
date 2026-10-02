# P2-ACHADOS
# formato: SEV|Classe|Metodo|Dimensao|Problema-max-6-palavras
ALTA|LoogAiDocumentoMessage|(hierarquia)|D1|cadeia-4-niveis-DOCM-concreto-base
BAIXA|ITokenProvider|(interface)|D1|unica-implementacao-no-codebase
ALTA|EmailMessageFactory|(classe)|D2|Factory-Repository-DTO-tres-papeis
ALTA|AuthenticationConfig|(classe)|D2|VO-Repository-load-save-negocio
ALTA|NotaFiscalPorEmbarqueMessage|methodPost|D2|orquestra-14-BOFs-viola-SRP
MEDIA|ConnectorConfig|constructor|D2|VO-realiza-DB-read-dois-papeis
BAIXA|MessageConfig|constructor|D2|13-parametros-sem-Builder
ALTA|Message|constructor|D3|new-MREP-ERRHD-hardcoded-14-subclasses
ALTA|OutboundMessageService|constructor|D3|5-colaboradores-instanciados-sem-DI
MEDIA|RestConnector|(classe)|D3|acessa-auth-3-niveis-viola-LoD
MEDIA|InboundMessageService|constructor|D3|MLDR-MFAC-instanciados-sem-DI
BAIXA|EmailService|constructor|D3|EMFAC-ELOGG-instanciados-direto
ALTA|ConnectorFactory|createConnector|D4|IF-ELSE-4-tipos-ENUM-fragil
MEDIA|MessageFactory|createStructureStrategy|D4|IF-binario-isSingle-fragil
MEDIA|OutboundMessageService|process|D4|strategy-selection-inline-service
MEDIA|OutboundMessage|appendPayloadObject|D4|dois-overloads-contratos-ambiguos
ALTA|InboundMessage|getRequiredFields|D5|default-vazio-desativa-validacao
MEDIA|InboundMessage|methodPost|D5|nao-abstrato-erro-so-runtime
# P2-RESUMO
ALTA:8|MEDIA:7|BAIXA:3|TOTAL:18
