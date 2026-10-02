# P3-ACHADOS
# formato: SEV|Classe|Metodo|Dimensao|Problema-max-6-palavras
ALTA|NotaFiscalPorEmbarqueMessage|methodPost|B1|14-BOFs-RUN-erro-pode-ser-perdido
MEDIA|EmailService|sender|B1|RUN-utapi019-ERROR-STATUS-sem-AppError
MEDIA|SchedulingService|schedule|B1|RUN-thl1989z-falha-nao-propaga-AppError
MEDIA|ConnectorConfig|constructor|B1|FIND-sem-AVAILABLE-check-estado-indefinido
MEDIA|AuthenticationConfig|constructor|B1|FIND-sem-AVAILABLE-check-estado-indefinido
ALTA|Message|constructor|B2|MREP-ERRHD-payload-sem-DESTRUCTOR-14-subclasses
ALTA|InboundObjectContext|constructor|B2|3-JSON-objects-sem-DESTRUCTOR-leak-PASOE
ALTA|OutboundMessageService|(classe)|B2|3-objetos-retidos-sem-DESTRUCTOR-PASOE
MEDIA|MessageFactory|(classe)|B2|message_-Message-completa-sem-DESTRUCTOR
MEDIA|MessageStructureStrategy|(classe)|B2|outboundMessage-retido-sem-DESTRUCTOR
ALTA|RestConnector|execute|B3|authentication-null-sem-VALID-OBJECT-guard
MEDIA|MessageFactory|createStructureStrategy|B3|CAST-OutboundMessage-sem-TYPE-OF-verificacao
MEDIA|JsonSetter|SetValue|B3|GetXxx-sem-Has-campo-pode-ser-inexistente
ALTA|MessageRepository|createMessage|B4|3-CREATEs-sem-DO-TRANSACTION-sem-atomicidade
ALTA|LpcoMessage|methodPost|B4|CREATE-DELETE-nit-lpco-sem-TRANSACTION
ALTA|AuditLogService|createRecord|B4|CREATE-static-buffer-sem-TRANSACTION-rollback
MEDIA|EmbarqueMessage|methodPost|B4|CREATE-es_embarque-sem-TRANSACTION-explicita
MEDIA|EnvironmentRepository|findEnvironmentCodeByPropath|B4|FOR-EACH-sem-NO-LOCK-declarado
MEDIA|EmailMessageFactory|loadRecipients|B4|FOR-EACH-sem-NO-LOCK-no-construtor
ALTA|AuditLogService|b-audit-registro|B5|static-buffer-corrompido-sessoes-concorrentes
ALTA|EnvironmentUtil|environment|B5|static-cache-contamina-sessoes-PASOE
ALTA|EnvironmentContext|environmentParameter|B5|static-mutavel-publico-race-condition
ALTA|ContextService|getUser|B5|os-getenv-conta-servico-nao-usuario-HTTP
BAIXA|JsonWriter|metodos-estaticos|B5|estaticos-puros-sem-estado-seguros
BAIXA|FileUtil|metodos-estaticos|B5|file-info-sessao-estaticos-seguros
BAIXA|TokenProviderFactory|getProvider|B5|dynamic-new-sem-estado-estatico-seguro
# P3-RESUMO
ALTA:12|MEDIA:11|BAIXA:3|TOTAL:26
