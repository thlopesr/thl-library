# P6-VALIDACAO
# formato: SEV|Classe|Metodo|Categoria|Veredicto|Motivo-max-6-palavras

# --- DESIGN OO (P2) ---
ALTA|LoogAiDocumentoMessage|(hierarquia)|D1|QUESTIONAR|DOCM-pode-ter-uso-proprio
ALTA|EmailMessageFactory|(classe)|D2|QUESTIONAR|DDK-pode-impor-acoplamento-contexto
ALTA|AuthenticationConfig|(classe)|D2|QUESTIONAR|Active-Record-e-padrao-valido
ALTA|NotaFiscalPorEmbarqueMessage|methodPost|D2|QUESTIONAR|BOFs-unica-interface-disponivel
ALTA|Message|constructor|D3|QUESTIONAR|ABL-sem-DI-colaboradores-invariantes
ALTA|OutboundMessageService|constructor|D3|QUESTIONAR|ABL-sem-DI-composition-root
ALTA|ConnectorFactory|createConnector|D4|CONFIRMAR|DYNAMIC-NEW-disponivel-IF-ELSE-indefensavel
ALTA|InboundMessage|getRequiredFields|D5|QUESTIONAR|GET-DELETE-sem-campos-obrigatorios
MEDIA|ConnectorConfig|constructor|D2|QUESTIONAR|Active-Record-pode-ser-consciente
MEDIA|RestConnector|(classe)|D3|QUESTIONAR|cadeia-dados-estruturais-sem-comportamento
MEDIA|InboundMessageService|constructor|D3|QUESTIONAR|ABL-sem-DI-colaboradores-invariantes
MEDIA|MessageFactory|createStructureStrategy|D4|PROVAVEL-OK|IF-binario-boolean-correto-YAGNI
MEDIA|OutboundMessageService|process|D4|QUESTIONAR|FLAGS-enum-condicional-pode-ser-claro
MEDIA|OutboundMessage|appendPayloadObject|D4|QUESTIONAR|dois-contratos-dominio-distintos
MEDIA|InboundMessage|methodPost|D5|QUESTIONAR|optional-interface-verbos-HTTP

# --- BUGS (P3) ---
ALTA|NotaFiscalPorEmbarqueMessage|methodPost|B1|QUESTIONAR|output-param-BOF-pode-existir
ALTA|Message|constructor|B2|QUESTIONAR|STATEFREE-PASOE-elimina-risco
ALTA|InboundObjectContext|constructor|B2|QUESTIONAR|STATEFREE-vida-curta-por-request
ALTA|OutboundMessageService|(classe)|B2|QUESTIONAR|STATEFREE-ou-DELETE-no-chamador
ALTA|RestConnector|execute|B3|CONFIRMAR|null-sem-VALID-OBJECT-indefensavel
ALTA|MessageRepository|createMessage|B4|QUESTIONAR|chamador-pode-ter-transacao
ALTA|LpcoMessage|methodPost|B4|QUESTIONAR|block-level-pode-cobrir-rollback
ALTA|AuditLogService|createRecord|B4|QUESTIONAR|auditoria-fora-transacao-pode-ser-correto
ALTA|AuditLogService|b-audit-registro|B5|CONFIRMAR|buffer-STATIC-CREATE-PASOE-indefensavel
ALTA|EnvironmentUtil|environment|B5|QUESTIONAR|agente-dedicado-por-ambiente
ALTA|EnvironmentContext|environmentParameter|B5|QUESTIONAR|setado-uma-vez-na-init
ALTA|ContextService|getUser|B5|QUESTIONAR|correto-fora-PASOE-REST
MEDIA|EmailService|sender|B1|QUESTIONAR|email-best-effort-pode-ser-intencional
MEDIA|SchedulingService|schedule|B1|QUESTIONAR|output-param-pode-existir
MEDIA|ConnectorConfig|constructor|B1|CONFIRMAR|FIND-AVAILABLE-erro-classico-ABL
MEDIA|AuthenticationConfig|constructor|B1|CONFIRMAR|FIND-AVAILABLE-erro-classico-ABL
MEDIA|MessageFactory|(classe)|B2|QUESTIONAR|STATEFREE-ou-referencia-curta
MEDIA|MessageStructureStrategy|(classe)|B2|QUESTIONAR|referencia-compartilhada-sem-double-free
MEDIA|MessageFactory|createStructureStrategy|B3|QUESTIONAR|contrato-configuracao-pode-garantir-tipo
MEDIA|JsonSetter|SetValue|B3|QUESTIONAR|SetValue-pode-ser-so-escrita
MEDIA|EmbarqueMessage|methodPost|B4|QUESTIONAR|transacao-chamador-pode-cobrir
MEDIA|EnvironmentRepository|findEnvironmentCodeByPropath|B4|QUESTIONAR|lock-default-ABL-pode-ser-assumido
MEDIA|EmailMessageFactory|loadRecipients|B4|QUESTIONAR|tabela-rara-update-risco-baixo

# --- PADRONIZACAO (P4) ---
ALTA|OutboundMessageService|(classe)|P2|QUESTIONAR|modelo-monitoramento-banco-pode-ser-ok
ALTA|MessageExecutionService|(classe)|P2|QUESTIONAR|modelo-monitoramento-banco-pode-ser-ok
ALTA|ConnectorService|(classe)|P2|QUESTIONAR|modelo-monitoramento-banco-pode-ser-ok
MEDIA|EmbarqueMessage|methodPost|P2|QUESTIONAR|thl-mensagem-item-pode-cobrir-auditoria
MEDIA|LpcoMessage|methodPost|P2|QUESTIONAR|thl-mensagem-item-pode-cobrir-auditoria
MEDIA|SchedulingService|schedule|P3|PROVAVEL-OK|thl1989z-programa-padrao-TOTVS-fixo
MEDIA|(multiplas-classes)|(varios)|P3|QUESTIONAR|17006-pode-ser-codigo-DDK-externo
MEDIA|MessageRepository|(classe)|P3|QUESTIONAR|status-pode-ser-contrato-produto-TOTVS

# --- FLUXOS (P4) ---
ALTA|ConnectorService|execute|F1|QUESTIONAR|fail-fast-config-pode-ser-intencional
ALTA|InboundMessageService|receive|F1|QUESTIONAR|handler-global-REST-pode-existir
ALTA|MessageExecutionService|executeOnline|F2|QUESTIONAR|banco-cobre-rastreio-log-pode-ser-ok
ALTA|OutboundMessageService|process|F3|QUESTIONAR|retry-by-producer-padrao-REST-valido
ALTA|SchedulingService|schedule|F3|QUESTIONAR|thl1989z-pode-instanciar-OMSS
MEDIA|SchedulingService|schedule|F1|QUESTIONAR|output-param-RPW-pode-existir
MEDIA|InboundMessageService|receive|F2|QUESTIONAR|http-log-PASOE-pode-cobrir
MEDIA|RestConnector|execute|F3|QUESTIONAR|HTTP-interno-TLS-termination-proxy

# P6-RESUMO
CONFIRMAR-ALTA:3|CONFIRMAR-MEDIA:2
QUESTIONAR-ALTA:25|QUESTIONAR-MEDIA:22
PROVAVEL-OK-ALTA:0|PROVAVEL-OK-MEDIA:2
TOTAL:54
