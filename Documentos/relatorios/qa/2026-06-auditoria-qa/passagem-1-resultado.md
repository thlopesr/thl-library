# PASSAGEM 1 — DESCOBERTA | THL-Library | 2026-06-07
# FORMAT SEV: 0=info-only (discovery pass)

## TOTAIS
CLASSES=60 | thl-lib=52 | thl-extensions=8
ENUM=4 | INTERFACE=1 | ABSTRACT=5 | CONCRETE=50
DB_DIRETO=22 | STATIC_VARS=3 | DESTRUCTOR=0 | SEM_DESTRUCTOR_COM_REFS=18

## MAPA COMPRIMIDO DE CLASSES
# SIGLA|NomeCompleto|Tipo|Herda|Impl|DB|STATIC
CTSVC|thl-lib.core.context.ContextService|C|-|-|N|metodos
ECTX|thl-lib.core.environment.EnvironmentContext|C|-|-|N|environmentParameter,programName
ERES|thl-lib.core.environment.EnvironmentResource|C|-|-|N|metodos
EUTI|thl-lib.core.environment.EnvironmentUtil|C|-|-|N|environment
EREP|thl-lib.core.environment.repository.EnvironmentRepository|C|-|-|S|-
ERRHD|thl-lib.core.error.ErrorHandler|C|-|-|N|-
CCFG|thl-lib.integration.connectors.core.ConnectorConfig|C|-|-|S|-
CREQ|thl-lib.integration.connectors.core.ConnectorRequest|C|-|-|N|-
CRSP|thl-lib.integration.connectors.core.ConnectorResponse|C|-|-|N|-
CFAC|thl-lib.integration.connectors.factory.ConnectorFactory|C|-|-|N|-
CSVC|thl-lib.integration.connectors.service.ConnectorService|C|-|-|N|-
ICON|thl-lib.integration.connectors.types.IntegrationConnector|A|-|-|N|-
RCNN|thl-lib.integration.connectors.types.RestConnector|C|ICON|-|N|-
ACFG|thl-lib.integration.connectors.auth.core.AuthenticationConfig|C|-|-|S|-
TFAC|thl-lib.integration.connectors.auth.factory.TokenProviderFactory|C|-|-|N|metodos
AREP|thl-lib.integration.connectors.auth.repository.AuthenticationRepository|C|-|-|S|-
ITPV|thl-lib.integration.connectors.auth.interfaces.ITokenProvider|I|-|-|N|-
CTPE|thl-lib.integration.connectors.enum.ConnectorTypeEnum|E|-|-|N|-
MTPE|thl-lib.integration.connectors.enum.MethodTypeEnum|E|-|-|N|-
MCFG|thl-lib.integration.messaging.core.MessageConfig|C|-|-|N|-
MSGS|thl-lib.integration.messaging.core.Message|A|-|-|N|-
MFAC|thl-lib.integration.messaging.factory.MessageFactory|C|-|-|N|-
DIREN|thl-lib.integration.messaging.enum.DirectionEnum|E|-|-|N|-
EXMEN|thl-lib.integration.messaging.enum.ExecutionMode|E(FLAGS)|-|-|N|-
MLDR|thl-lib.integration.messaging.repository.MessageConfigLoader|C|-|-|S|-
MREP|thl-lib.integration.messaging.repository.MessageRepository|C|-|-|S|-
OMSG|thl-lib.integration.messaging.outbound.core.OutboundMessage|A|MSGS|-|N|-
OOBJ|thl-lib.integration.messaging.outbound.core.OutboundObjectContext|C|-|-|N|-
MSTR|thl-lib.integration.messaging.outbound.strategy.MessageStructureStrategy|A|-|-|N|-
MMST|thl-lib.integration.messaging.outbound.strategy.MultipleMessageStructure|C|MSTR|-|N|-
SMST|thl-lib.integration.messaging.outbound.strategy.SingleMessageStructure|C|MSTR|-|N|-
MEXS|thl-lib.integration.messaging.outbound.service.MessageExecutionService|C|-|-|N|-
OMSS|thl-lib.integration.messaging.outbound.service.OutboundMessageService|C|-|-|N|-
SSCH|thl-lib.integration.messaging.outbound.service.SchedulingService|C|-|-|N|-
IMSG|thl-lib.integration.messaging.inbound.core.InboundMessage|A|MSGS|-|N|-
IOBJ|thl-lib.integration.messaging.inbound.core.InboundObjectContext|C|-|-|N|-
IRRT|thl-lib.integration.messaging.inbound.route.InboundRouteResolver|C|-|-|S|-
ISVC|thl-lib.integration.messaging.inbound.service.InboundMessageService|C|-|-|N|-
DOCM|thl-lib.integration.messaging.inbound.message.DocumentoMessage|C|IMSG|-|S|-
EMBM|thl-lib.integration.messaging.inbound.message.EmbarqueMessage|C|IMSG|-|S|-
LPCI|thl-lib.integration.messaging.inbound.message.LpcoMessage|C|IMSG|-|S|-
NFEM|thl-lib.integration.messaging.inbound.message.NotaFiscalPorEmbarqueMessage|C|IMSG|-|S|-
USRM|thl-lib.integration.messaging.inbound.message.UsuarioMessage|C|IMSG|-|S|-
JSET|thl-lib.util.json.JsonSetter|C|-|-|N|-
JWRT|thl-lib.util.json.JsonWriter|C|-|-|N|metodos
FUTI|thl-lib.util.file.FileUtil|C|-|-|N|metodos
SUTI|thl-lib.util.string.StringUtil|C|-|-|N|metodos
LUTI|thl-lib.logging.LogUtil|C|-|-|N|metodos
AUDIT|thl-lib.logging.audit.AuditLogService|C|-|-|S|b-audit-registro(buffer)
ELOGG|thl-lib.communication.email.EmailLogger|C|-|-|S|-
EMFAC|thl-lib.communication.email.EmailMessageFactory|C|-|-|S|-
EMSVC|thl-lib.communication.email.EmailService|C|-|-|N|-
XTPV|thl-extensions.integration.mmcm.connectors.auth.TokenProvider|C|-|ITPV|N|-
XLPCO|thl-extensions.integration.automatizador.messaging.outbound.message.LpcoMessage|C|OMSG|-|S|-
XENTR|thl-extensions.integration.loogai.messaging.outbound.message.EntregaPedidoMessage|C|OMSG|-|S|-
XNFSC|thl-extensions.integration.loogai.messaging.outbound.message.NotaFiscalMessage|C|OMSG|-|S|-
XLDOC|thl-extensions.integration.loogai.messaging.inbound.message.LoogAiDocumentoMessage|C|DOCM|-|S|-
XPEDI|thl-extensions.integration.mmcm.messaging.outbound.message.PedidoMessage|C|OMSG|-|S|-
XPREP|thl-extensions.integration.mmcm.messaging.outbound.message.PrePedidoMessage|C|OMSG|-|S|-
XCHAM|thl-extensions.integration.ninahub.messaging.outbound.message.ChamadoMessage|C|OMSG|-|S|-

## GRAFO DE DEPENDÊNCIAS (NEW/DYNAMIC-NEW)
MSGS->MREP,ERRHD
MFAC->SMST,MMST,dynamic-new(messageClass)
OMSS->MLDR,MFAC,OOBJ,MEXS,SSCH
ISVC->MLDR,MFAC
MEXS->CREQ,CSVC,CCFG
CSVC->CFAC
CFAC->RCNN
RCNN->CRSP,CREQ,CCFG,dynamic-new(tokenParserClass)
CCFG->ACFG
ACFG->AREP
TFAC->dynamic-new(className)
ECTX->EREP
ERES->ECTX,EUTI,EREP
EUTI->EREP
SSCH->CRSP
MLDR->MCFG
EMSVC->EMFAC,ELOGG
EMFAC->(ERES,SUTI)[static]
AUDIT->(JWRT,CTSVC)[static]
LPCI->JSET
USRM->JSET
XLPCO->(moeda)[DB-only,no-new]
XCHAM->dynamic-new(ObjectModelParser)[Progress-native]
XPEDI->(FUTI)[static]

## DB DIRETO POR CLASSE
EREP|thl-ambiente,thl-ambiente-param-prog,thl-ambiente-param-variavel|FOR EACH
AUDIT|audit-registro|CREATE(static-buffer)
ACFG|thl-conexao-rest-autenticacao|FIND
AREP|thl-conexao-rest-autenticacao|FIND-EXCL,ASSIGN
CCFG|thl-conexao-rest,thl-conexao-rest-path|FIND
IRRT|thl-inbound-rota|FIND
MLDR|thl-objeto,thl-objeto-parametro|FIND
MREP|thl-mensagem,thl-mensagem-historico,thl-mensagem-item,thl-mensagem-conteudo|CREATE/FIND/ASSIGN
ELOGG|thl-email|CREATE,ASSIGN
EMFAC|thl-email-param,param_email,thl-ambiente-param-grupo-usuar,usuar_mestre|FIND,FOR EACH
DOCM|docum-est,tt-docum-est(temp)|FIND,BOF(boin090/176/092/366)
EMBM|embarque,ped-venda,ped-ent,pre-fatur,es_embarque,estabelec|FIND,CREATE,FOR EACH
NFEM|embarque,nota-fiscal,estabelec|FIND,BOF(bodi162/317/176/317in/va/pr/sd/im1bra,ft4001a)
USRM|usuar_mestre|FIND,BOF(bofn017/027/030/168/169)
LPCI|nit-lpco|FIND-EXCL,CREATE,DELETE,FOR EACH
XLDOC|estabelec,emitente,nota-fiscal,it-nota-fisc,cond-pagto,mg.cidade,nit-loog-natur-oper|FIND
XENTR|ped-ent,ped-item,item,fam-comerc,ped-venda,canal-venda,estabelec,emitente,repres,es_ped_venda,es_ped_item,es_ped_ent,nit-loc-entr|FIND
XNFSC|nota-fiscal,emitente,estabelec|FIND
XPEDI|nota-fiscal|FIND
XPREP|pre-fatur,it-pre-fat,embarque,emitente|FIND,FOR EACH
XCHAM|embarque|FIND
XLPCO|nit-lpco,moeda|FIND

## HIERARQUIA DE HERANÇA (comprimida)
MSGS>OMSG>XLPCO,XENTR,XNFSC,XPEDI,XPREP,XCHAM
MSGS>IMSG>DOCM>XLDOC
MSGS>IMSG>EMBM,LPCI,NFEM,USRM
ICON>RCNN
MSTR>MMST,SMST

## INTERFACE
ITPV<XTPV(IMPLEMENTS)

## TABELAS THL (20)
thl-ambiente|cod-ambiente(PK),ip(UK),nome-ambiente
thl-ambiente-param|cod-param-ambiente(PK),descr-param-ambiente
thl-ambiente-param-grupo|cod-grp-usuar(PK),descricao
thl-ambiente-param-grupo-usuar|cod-grp-usuar+cod-usuario+email-alternativo(UK)
thl-ambiente-param-prog|cod-param-ambiente+cod-prog-dtsul(PK)
thl-ambiente-param-variavel|cod-ambiente+cod-param-ambiente+cod-variavel(PK),valor-variavel
thl-audit-registro|tabela+referencia+data-criacao(UK),tipo,usuario,programas-executado,registro(CLOB)
thl-conexao-rest|cod-conexao(PK),url-base,ind-requisita-autenticacao
thl-conexao-rest-autenticacao|cod-conexao(PK-FK),url-token,tipo-autenticacao,usuario,senha,token,dt-expiracao-token,classe-parser-token
thl-conexao-rest-path|cod-path(PK),path,content-type,accept,timeout,parameters,headers
thl-email|id(PK-GUID),data-envio,cod-prog-dtsul,remetente,destino,assunto,log-envio,mensagem,retorno
thl-email-param|cod-email-param(PK),cod-grp-usuar,remetente,assunto,mensagem,importancia
thl-inbound-rota|cod-rota(PK),rota-publica(UK),objeto,aplicacao,ind-ativo
thl-mensagem|codigo-mensagem(PK-GUID),objeto,aplicacao,operacao,metodo,forma-execucao,sentido-fluxo,sit-requisicao,sit-retorno,sit-processamento,qtd-tentativas,destino,cod-status-retorno
thl-mensagem-conteudo|codigo-mensagem+tipo-conteudo(PK),conteudo(CLOB)
thl-mensagem-historico|codigo-mensagem+tentativa(PK)
thl-mensagem-item|codigo-mensagem+chave-registro+chave-registro-ext(PK)
thl-mensagem-ped-exec|codigo-mensagem(PK),data-agendamento,num-ped-exec
thl-objeto|aplicacao+objeto(PK),classe-objeto,modelo-integracao,sentido-fluxo
thl-objeto-parametro|cod-estabel+aplicacao+objeto+operacao(PK),metodo,forma-execucao,cod-param-ambiente,cod-param-ambiente-destino
thl-objeto-usuario|aplicacao+objeto+cod-usuario(PK)
SEQ:thl-seq-id-email|INITIAL=1,INCREMENT=1,CYCLE=yes,MAX=4

## STATIC VARS
EUTI|environment|character|private
ECTX|environmentParameter|character|public-static
ECTX|programName|character|public-static
AUDIT|b-audit-registro|buffer|private-static

## CLASSES SEM DESTRUCTOR COM REFERÊNCIAS DE OBJETO
MSGS|payload(JsonConstruct),repository(MREP),errorHandler(ERRHD)
OMSG|pathParameters(JsonArray)
MSTR|outboundMessage(OMSG)
MFAC|message_(MSGS)
OMSS|messageFactory(MFAC),structureStrategy(MSTR),connectorResponse(CRSP)
ISVC|inboundMessage(IMSG),configuration(MCFG)
IOBJ|payload(JsonObject),queryParameters(JsonObject),pathParameters(JsonArray)
OOBJ|additionalData(JsonObject)
JSET|payload(JsonObject)
ACFG|(sem refs de objeto THL — primitivos)
CCFG|authentication(ACFG)
CREQ|content(JsonConstruct),connectorConfig(CCFG),pathParameters(JsonArray)
IRRT|pathParameters(JsonArray)
EMSVC|emailMessageFactory(EMFAC)

## EXTERNAL PROGRAMS (RUN)
NFEM|bodi162,bodi317,bodi176,bodi317in,bodi317va,bodi317pr,bodi317sd,bodi317im1bra,ft4001a,bodi135na,bodi317ef,ut-acomp,esft1932i,esft1932a
USRM|bofn017,bofn027,bofn030,bofn168,bofn169
DOCM|boin090,boin176,boin092,boin366
EMBM|eqapi300
EMSVC|utapi019.p
SSCH|thl\thl1989z.p
