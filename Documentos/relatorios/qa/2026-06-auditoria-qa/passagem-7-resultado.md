# P7-ARBITRAGEM
# formato: SEV|Classe|Metodo|Categoria|Decisao|EscopoP8-max-8-palavras

# --- CONFIRMAR (5) → todos REJEITADOS ---
ALTA|ConnectorFactory|createConnector|D4|REJEITADO|IF-ELSE-factory-roadmap-novos-tipos-confirmado
ALTA|RestConnector|execute|B3|REJEITADO|null-auth-sem-VALID-OBJECT-sem-justificativa
ALTA|AuditLogService|b-audit-registro|B5|REJEITADO|buffer-STATIC-CREATE-PASOE-sem-resposta
MEDIA|ConnectorConfig|constructor|B1|REJEITADO|FIND-sem-AVAILABLE-sem-resposta
MEDIA|AuthenticationConfig|constructor|B1|REJEITADO|FIND-sem-AVAILABLE-sem-resposta

# --- QUESTIONAR ALTA → REJEITADOS ---
ALTA|EmailMessageFactory|(classe)|D2|REJEITADO|3-papeis-SRP-sem-justificativa-DDK
ALTA|AuthenticationConfig|(classe)|D2|REJEITADO|4-papeis-Active-Record-nao-confirmado
ALTA|NotaFiscalPorEmbarqueMessage|methodPost|D2|REJEITADO|SRP-obs-expande-responsabilidades-agrava
ALTA|OutboundMessageService|constructor|D3|REJEITADO|5-colaboradores-hardcoded-sem-resposta
ALTA|InboundMessage|getRequiredFields|D5|REJEITADO|default-vazio-validacao-silenciosa-sem-resposta
ALTA|NotaFiscalPorEmbarqueMessage|methodPost|B1|REJEITADO|14-BOFs-sem-tratamento-erro-sem-resposta
ALTA|MessageRepository|createMessage|B4|REJEITADO|justificativa-block-level-tecnicamente-incorreta
ALTA|AuditLogService|createRecord|B4|REJEITADO|requisito-auditoria-pos-rollback-sem-resposta
ALTA|EnvironmentContext|environmentParameter|B5|REJEITADO|PUBLIC-STATIC-mutavel-sem-confirmacao-init
ALTA|OutboundMessageService|(classe)|P2|REJEITADO|cadeia-HTTP-sem-log-servidor-sem-resposta
ALTA|MessageExecutionService|(classe)|P2|REJEITADO|cadeia-HTTP-sem-log-servidor-sem-resposta
ALTA|ConnectorService|(classe)|P2|REJEITADO|cadeia-HTTP-sem-log-servidor-sem-resposta
ALTA|ConnectorService|execute|F1|REJEITADO|AppError-CFAC-nao-convertida-sem-resposta
ALTA|InboundMessageService|receive|F1|REJEITADO|excecao-inbound-sem-JSON-erro-sem-resposta
ALTA|MessageExecutionService|executeOnline|F2|REJEITADO|HTTP-sem-log-servidor-sem-resposta
ALTA|OutboundMessageService|process|F3|REJEITADO|retry-inbound-ausente-sem-justificativa
ALTA|SchedulingService|schedule|F3|REJEITADO|RPW-bypass-cadeia-nao-confirmado

# --- QUESTIONAR ALTA → ACEITO-PARC ---
ALTA|Message|constructor|D3|ACEITO-PARC|documentar-invariancia-avaliar-substituicao-dev
ALTA|LpcoMessage|methodPost|B4|ACEITO-PARC|verificar-transacao-adicionar-DO-TRANSACTION

# --- QUESTIONAR ALTA → ACEITO ---
ALTA|LoogAiDocumentoMessage|(hierarquia)|D1|ACEITO|excluido
ALTA|Message|constructor|B2|ACEITO|excluido
ALTA|InboundObjectContext|constructor|B2|ACEITO|excluido
ALTA|OutboundMessageService|(classe)|B2|ACEITO|excluido
ALTA|EnvironmentUtil|environment|B5|ACEITO|excluido
ALTA|ContextService|getUser|B5|ACEITO|excluido

# --- QUESTIONAR MEDIA → REJEITADOS ---
MEDIA|ConnectorConfig|constructor|D2|REJEITADO|Active-Record-nao-confirmado-sem-resposta
MEDIA|RestConnector|(classe)|D3|REJEITADO|Lei-Demeter-sem-justificativa-sem-resposta
MEDIA|InboundMessageService|constructor|D3|REJEITADO|MLDR-MFAC-hardcoded-sem-resposta
MEDIA|OutboundMessageService|process|D4|REJEITADO|strategy-inline-FLAGS-sem-resposta
MEDIA|OutboundMessage|appendPayloadObject|D4|REJEITADO|dois-overloads-contratos-sem-resposta
MEDIA|InboundMessage|methodPost|D5|REJEITADO|verbos-nao-abstract-sem-resposta
MEDIA|SchedulingService|schedule|B1|REJEITADO|falha-RPW-nao-detectavel-sem-resposta
MEDIA|MessageFactory|createStructureStrategy|B3|REJEITADO|CAST-sem-TYPE-OF-sem-confirmacao-tela
MEDIA|EnvironmentRepository|findEnvironmentCodeByPropath|B4|REJEITADO|FOR-EACH-sem-NO-LOCK-sem-resposta
MEDIA|EmailMessageFactory|loadRecipients|B4|REJEITADO|FOR-EACH-sem-NO-LOCK-sem-resposta
MEDIA|LpcoMessage|methodPost|P2|REJEITADO|gap-auditoria-DELETE-confirmado-dev
MEDIA|MessageRepository|(classe)|P3|REJEITADO|magic-numbers-status-sem-resposta
MEDIA|SchedulingService|schedule|F1|REJEITADO|ConnectorResponse-inconsistente-sem-resposta
MEDIA|InboundMessageService|receive|F2|REJEITADO|inbound-sem-log-sem-resposta
MEDIA|RestConnector|execute|F3|REJEITADO|HTTPS-nao-enforçado-sem-resposta

# --- QUESTIONAR MEDIA → ACEITO-PARC ---
MEDIA|EmailService|sender|B1|ACEITO-PARC|verificar-ERROR-STATUS-captura-antes-EmailLogger
MEDIA|EmbarqueMessage|methodPost|B4|ACEITO-PARC|verificar-atomicidade-CREATE-appendMessageItem
MEDIA|(multiplas-classes)|(varios)|P3|ACEITO-PARC|adicionar-prefixo-programa-literal-aceito

# --- QUESTIONAR MEDIA → ACEITO ---
MEDIA|MessageFactory|(classe)|B2|ACEITO|excluido
MEDIA|MessageStructureStrategy|(classe)|B2|ACEITO|excluido
MEDIA|JsonSetter|SetValue|B3|ACEITO|excluido
MEDIA|EmbarqueMessage|methodPost|P2|ACEITO|excluido

# --- PROVAVEL-OK → ACEITO ---
MEDIA|MessageFactory|createStructureStrategy|D4|ACEITO|excluido
MEDIA|SchedulingService|schedule|P3|ACEITO|excluido

# P7-RESUMO
REJEITADO-ALTA:20|REJEITADO-MEDIA:15
ACEITO-PARC-ALTA:2|ACEITO-PARC-MEDIA:3
ACEITO-ALTA:6|ACEITO-MEDIA:6
TOTAL-PARA-P8:40
