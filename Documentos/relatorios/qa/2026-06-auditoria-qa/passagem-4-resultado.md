# P4-ACHADOS-PADRONIZACAO
# formato: SEV|Classe|Dimensao|Problema-max-6-palavras
BAIXA|EmailService|P1|metodo-sender()-deveria-ser-send()
BAIXA|SchedulingService|P1|nome-gerundio-inconsistente-outros-substantivos
BAIXA|MessageFactory|P1|propriedade-message_-underscore-nao-padrao
ALTA|OutboundMessageService|P2|sem-LogUtil-servico-central-sem-log
ALTA|MessageExecutionService|P2|sem-LogUtil-execucao-HTTP-sem-log
ALTA|ConnectorService|P2|sem-LogUtil-cadeia-inteira-sem-log
MEDIA|EmbarqueMessage|P2|CREATE-es_embarque-sem-AuditLogService
MEDIA|LpcoMessage|P2|CREATE-DELETE-nit-lpco-sem-AuditLogService
BAIXA|EmailMessageFactory|P2|acessa-thl-ambiente-param-grupo-diretamente
MEDIA|SchedulingService|P3|caminho-thl1989z.p-hardcoded-no-codigo
MEDIA|(multiplas-classes)|P3|erro-17006-magic-number-espalhado-globalmente
MEDIA|MessageRepository|P3|status-1-2-3-4-sem-constante-nomeada
BAIXA|InboundMessage|P3|HTTP-200-e-string-PT-hardcoded
BAIXA|InboundMessage|P4|dispatchInbound-publico-deveria-ser-protected
BAIXA|MessageRepository|P4|setters-messageCode-referenceCode-publicos

# P4-ACHADOS-FLUXO
# formato: SEV|Fluxo|Classe|Dimensao|Problema-max-6-palavras
ALTA|Outbound|ConnectorService|F1|AppError-CFAC-nao-convertida-ConnectorResponse
ALTA|Inbound|InboundMessageService|F1|excecao-processamento-sem-conversao-JSON-erro
MEDIA|Scheduling|SchedulingService|F1|falha-RUN-RPW-ConnectorResponse-inconsistente
ALTA|Outbound|MessageExecutionService|F2|cadeia-execucao-sem-nenhum-log-servidor
MEDIA|Inbound|InboundMessageService|F2|processamento-inbound-sem-log-servidor
ALTA|TODOS|OutboundMessageService|F3|retry-outbound-sem-equivalente-inbound
ALTA|Scheduling|SchedulingService|F3|RPW-pode-bypassar-cadeia-de-classes
MEDIA|Outbound|RestConnector|F3|HTTPS-nao-enforçado-URL-pode-ser-HTTP
BAIXA|Outbound|RestConnector|F3|auth-BASIC-APIKEY-sem-validacao-expiracao

# P4-RESUMO
PADRONIZACAO-ALTA:3|PADRONIZACAO-MEDIA:5|PADRONIZACAO-BAIXA:7
FLUXO-ALTA:5|FLUXO-MEDIA:3|FLUXO-BAIXA:1
TOTAL:24
