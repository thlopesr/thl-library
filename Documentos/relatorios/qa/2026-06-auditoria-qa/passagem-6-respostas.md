# THL-QA — Passagem 6 — Respostas do Desenvolvedor
Fonte: THL-QA-Passagem6-Validacao.xlsx
Total de achados: 52
Achados com resposta: 46
Achados SEM-RESPOSTA: 6
---
## ACHADO: ConnectorFactory.createConnector | ALTA | D4
**Veredicto P6:** CONFIRMAR
**Pergunta 1:** Há plano concreto e prazo para implementar conectores SOAP, DATABASE ou FILE?
**Resposta 1:** Sim
**Pergunta 2:** Existe restrição do DDK ou PASOE que impeça uso de DYNAMIC-NEW como alternativa ao IF/ELSE?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Será implemento futuramente outras tipos de integrações

---

## ACHADO: RestConnector.execute | ALTA | B3
**Veredicto P6:** CONFIRMAR
**Pergunta 1:** Existe algum registro em thl-conexao-rest com ind-requisita-autenticacao = false? Se sim, o crash em runtime já ocorreu.
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** O campo requiresAuthentication é opcional por design (uso futuro) ou todos os conectores sempre requerem autenticação?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: AuditLogService.b-audit-registro | ALTA | B5
**Veredicto P6:** CONFIRMAR
**Pergunta 1:** Qual é a configuração max-sessions-per-agent do PASOE em produção? Se > 1, a corrupção já pode estar ocorrendo.
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** O STATIC no buffer foi decisão deliberada de performance ou analogia equivocada com métodos estáticos sem estado (LogUtil, JsonWriter)?
**Resposta 2:** SEM-RESPOSTA

---

## ACHADO: ConnectorConfig.constructor | MÉDIA | B1
**Veredicto P6:** CONFIRMAR
**Pergunta 1:** Existe validação em ConnectorService ou MessageExecutionService que verifica existência do registro em thl-conexao-rest antes de instanciar ConnectorConfig?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** O que acontece em produção quando thl-objeto-parametro aponta para um código de conexão REST inexistente?
**Resposta 2:** SEM-RESPOSTA

---

## ACHADO: AuthenticationConfig.constructor | MÉDIA | B1
**Veredicto P6:** CONFIRMAR
**Pergunta 1:** Existe constraint de banco ou trigger que impede thl-conexao-rest com autenticacao=true sem registro correspondente em thl-conexao-rest-autenticacao?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** O que ocorre quando AuthenticationConfig é construído para uma conexão cuja autenticação não foi cadastrada?
**Resposta 2:** SEM-RESPOSTA

---

## ACHADO: LoogAiDocumentoMessage.(hierarquia) | ALTA | D1
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** DocumentoMessage é instanciada diretamente em algum fluxo, ou existe apenas como base de LoogAiDocumentoMessage?
**Resposta 1:** Teremos DocumentoMessage como classe para entrada padrão de documento no TOTVS, porem teremos cenerios com Loog.ai que terá exclusividade por sistemas, por isto teremos classse com a LoogAiDocumentoMessage
**Pergunta 2:** Existem ou estão planejadas outras subclasses de DocumentoMessage além de LoogAiDocumentoMessage?
**Resposta 2:** Sim
**Pergunta 3:** O comportamento de DocumentoMessage (boin*, docum-est) é necessário independentemente do LoogAI?
**Resposta 3:** Sim

---

## ACHADO: EmailMessageFactory.(classe) | ALTA | D2
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** O acesso a usuar_mestre e thl-ambiente-param-grupo-usuar em loadRecipients() depende do contexto de sessão Datasul (usuário logado)? Poderia ser extraído para repositório separado sem perder esse contexto?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Há razão técnica específica do DDK que impeça separar loadConfiguration() em um EmailConfigRepository dedicado?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: AuthenticationConfig.(classe) | ALTA | D2
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** A decisão de AuthenticationConfig incluir saveToken() e isTokenExpired() foi escolha consciente de Active Record, ou ocorreu por crescimento incremental da classe?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Existe cenário onde o token precisa ser atualizado sem ter um AuthenticationConfig carregado do banco (ex: via API externa)?
**Resposta 2:** SEM-RESPOSTA

---

## ACHADO: NotaFiscalPorEmbarqueMessage.methodPost | ALTA | D2
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** Existe algum serviço ou façade de emissão de NF no Datasul DDK que encapsule esses 14 BOFs? Ou cada BOF representa um passo distinto que o framework de integração deve orquestrar explicitamente?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** A escolha de colocar toda a orquestração em methodPost() foi consciente (limitação de interfaces disponíveis) ou crescimento incremental sem revisão de design?
**Resposta 2:** SEM-RESPOSTA
**Pergunta 3:** Seria viável extrair a orquestração de BOFs para um NotaFiscalEmissaoService separado, mantendo methodPost() apenas como ponto de entrada?
**Resposta 3:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode de incluir nota fiscal autorizar imprimir e notificar da nota fiscal

---

## ACHADO: Message.constructor | ALTA | D3
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** Há cenário planejado onde alguma subclasse de Message precisaria de um MessageRepository diferente do concreto padrão (ex: multi-tenant, ambiente de homologação)?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** O ErrorHandler é sempre o mesmo concreto para todas as mensagens, ou existe variação por tipo de conexão ou ambiente?
**Resposta 2:** SEM-RESPOSTA
**Pergunta 3:** Foi considerado um padrão de Service Locator (ex: MessageRepository:getInstance()) como alternativa ao new direto?
**Resposta 3:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** 2) MessageRepository e ErrorHandler são colaboradores invariantes de Message — toda mensagem sempre precisa de ambos; acoplamento intencional.

---

## ACHADO: OutboundMessageService.constructor | ALTA | D3
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** Existe cenário onde OutboundMessageService deveria usar um MessageFactory ou SchedulingService diferente do concreto padrão (ex: integração com sistema legado específico de cliente)?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** O programa procedural Datasul que instancia OutboundMessageService poderia fornecer colaboradores como parâmetro se necessário?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: InboundMessage.getRequiredFields | ALTA | D5
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** Quantas subclasses concretas deliberadamente não sobrescrevem getRequiredFields — e o comportamento de aceitar qualquer payload é intencional para elas?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Uma subclasse que opera apenas com methodGet/methodDelete e não sobrescreve getRequiredFields está no design correto do framework?
**Resposta 2:** SEM-RESPOSTA
**Pergunta 3:** Foi considerado declarar getRequiredFields como abstract, usando return '' nas subclasses que genuinamente não têm campos obrigatórios?
**Resposta 3:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: NotaFiscalPorEmbarqueMessage.methodPost | ALTA | B1
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** Após cada RUN bodi162, RUN ft4001a etc., existe verificação explícita de output-parameter de erro (ex: if p-erro <> '' then undo, throw new AppError)?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** A sequência dos 14 BOFs está envolta em um único DO TRANSACTION: explícito em methodPost, garantindo rollback conjunto?
**Resposta 2:** SEM-RESPOSTA
**Pergunta 3:** Se bodi317va falhar após bodi162 ter executado com sucesso, qual é o estado esperado do banco — dados parciais ficam, ou há rollback automático?
**Resposta 3:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: Message.constructor | ALTA | B2
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** O PASOE está configurado em modo STATEFREE ou STATEFUL? (Resposta muda completamente a severidade deste achado.)
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Após OutboundMessageService.process() retornar, existem referências externas ao Message criado, ou ele é sempre objeto temporário de escopo local?
**Resposta 2:** SEM-RESPOSTA
**Pergunta 3:** Houve alguma análise de uso de memória em produção (monitoramento do agente PASOE) que mostre crescimento de heap entre requisições?
**Resposta 3:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** 1) PASOE STATEFREE: a cada requisição HTTP o contexto de sessão é criado e destruído automaticamente; DESTRUCTOR seria código morto.

---

## ACHADO: InboundObjectContext.constructor | ALTA | B2
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** O PASOE é STATEFREE ou STATEFUL? Se STATEFREE, o achado perde severidade.
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** O InboundObjectContext é retido por alguma referência após receive() retornar (ex: mantido em cache, log, ou propriedade de sessão)?
**Resposta 2:** SEM-RESPOSTA
**Pergunta 3:** O SetPayload() que substitui o JsonObject inicial no construtor: o objeto original substituído é explicitamente deletado antes da atribuição?
**Resposta 3:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** PASOE STATEFREE: sessão reiniciada a cada request; objetos liberados automaticamente; DESTRUCTOR seria código morto.

---

## ACHADO: OutboundMessageService.(classe) | ALTA | B2
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** O programa procedural Datasul que chama OutboundMessageService tem bloco FINALLY com DELETE OBJECT para liberar explicitamente o objeto?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** No modo de operação atual do PASOE, OutboundMessageService é instanciado uma vez por agente (singleton) ou uma vez por request?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: MessageRepository.createMessage | ALTA | B4
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** Em OutboundMessageService.process(), a sequência createMessage + createItemMessage + createMessageContent está dentro de um único DO TRANSACTION no serviço chamador?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Se createMessageContent falhar (ex: CLOB muito grande), o comportamento esperado é rollback de thl-mensagem e thl-mensagem-item também, ou o registro da mensagem deve persistir sem conteúdo?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** block-level on error undo,throw garante rollback dos CREATEs se exceção for lançada dentro do mesmo bloco.

---

## ACHADO: LpcoMessage.methodPost | ALTA | B4
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** InboundMessageService.receive() ou InboundMessage.processInbound() declara explicitamente DO TRANSACTION: antes de chamar dispatchInbound()?
**Resposta 1:** method são são com transaticon no OpenEdge, não sendo necessario explicitar
**Pergunta 2:** Se appendMessageItemByReference() falhar após CREATE b-nit-lpco, o comportamento esperado é rollback de ambos, ou manter o LPCO criado sem item de mensagem?
**Resposta 2:** SEM-RESPOSTA

---

## ACHADO: AuditLogService.createRecord | ALTA | B4
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** O requisito de auditoria do sistema é registrar tentativas (inclusive as que falham com rollback) ou apenas operações concluídas com sucesso?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** createRecord() é chamado antes ou depois do commit da transação de negócio? Se chamado dentro da transação, o rollback do negócio desfazendo a auditoria é o comportamento desejado?
**Resposta 2:** SEM-RESPOSTA
**Pergunta 3:** Foi considerado um DO TRANSACTION: isolado dentro de createRecord() para garantir que a auditoria commita independentemente do resultado da transação de negócio?
**Resposta 3:** SEM-RESPOSTA

---

## ACHADO: EnvironmentUtil.environment | ALTA | B5
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** Em produção, um agente PASOE atende requests de múltiplos ambientes (filiais com códigos de ambiente diferentes), ou cada agente é dedicado a um único ambiente?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Se a resposta for 'único ambiente por agente', a variável STATIC é efetivamente constante de processo — qual é a resposta? (Isso qualificaria o achado como Provável-OK.)
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** PASOE sempre estará mesmo ambiente e não deve ter reset,uma vez localizando o ambiente. Pois e imutabel

---

## ACHADO: EnvironmentContext.environmentParameter / programName | ALTA | B5
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** EnvironmentResource.initialize() (que chama setEnvironmentParameter()) é chamado uma única vez na inicialização do agente, ou é chamado a cada request para resolver parâmetros do request corrente?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Há logs ou evidência de que programName varia entre requests no mesmo agente (ex: diferentes programas Datasul chamando initialize() concorrentemente)?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: ContextService.getUser | ALTA | B5
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** ContextService.getUser() é chamado exclusivamente em fluxos REST/PASOE, ou também em fluxos de AppServer batch e programas da UI Datasul?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Para o contexto PASOE REST, existe algum mecanismo disponível no DDK Datasul 12 para obter o usuário HTTP autenticado (ex: variável de request, token de sessão) de dentro de uma classe ABL?
**Resposta 2:** SEM-RESPOSTA
**Pergunta 3:** A auditoria com campo usuario incorreto (conta de serviço em vez do usuário real) foi identificada e verificada em produção?
**Resposta 3:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode deixar usuario que esta executando PASOE - não tem problema

---

## ACHADO: OutboundMessageService / MessageExecutionService / ConnectorService.(cadeia outbound) | ALTA | P2
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** Em incidentes de produção (timeout HTTP, falha de auth, DNS), qual é o primeiro ponto de diagnóstico: log do servidor PASOE ou tabela thl-mensagem?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** A ausência de LogUtil nessas classes foi uma decisão explicitamente tomada (e documentada) ou simplesmente não foi implementada?
**Resposta 2:** SEM-RESPOSTA
**Pergunta 3:** O LogUtil disponível no framework escreve em arquivo/console PASOE, ou em banco de dados? (Se escreve em banco, pode se sobrepor ao que thl-mensagem já cobre.)
**Resposta 3:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: ConnectorService.execute | ALTA | F1
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** O programa procedural Datasul que chama OutboundMessageService.process() tem CATCH para AppError? Se sim, como o erro de 'tipo de conector não suportado' é tratado?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Se process() lança AppError por tipo de conector inválido, o registro em thl-mensagem é criado com status de erro, ou a mensagem não é registrada?
**Resposta 2:** SEM-RESPOSTA
**Pergunta 3:** A propagação de AppError para o chamador foi uma decisão consciente de fail-fast para erros de configuração, ou foi ausência de tratamento?
**Resposta 3:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Não obs.

---

## ACHADO: InboundMessageService.receive | ALTA | F1
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** O endpoint REST que chama receive() tem CATCH que converte AppError em resposta JSON de erro com campo 'message'?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Se o sistema externo (cliente da API REST) receber HTTP 500 sem corpo JSON, consegue identificar o tipo de erro? Isso é aceitável pelo contrato de API?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: MessageExecutionService.executeOnline | ALTA | F2
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** Para uma falha de timeout HTTP em produção, qual informação está disponível para diagnóstico além do status em thl-mensagem?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** A ausência de log na cadeia de execução foi uma decisão consciente de design operacional ou simplesmente não foi implementada?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: OutboundMessageService.process / reprocess | ALTA | F3
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** Os sistemas externos que enviam mensagens inbound (Automatizador, LoogAI, NinaHub, MMCM) têm capacidade de reenvio automático em caso de falha HTTP do endpoint THL?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Existe requisito de produto ou contrato com cliente que exija que o THL faça retry de mensagens inbound sem depender do reenvio pelo sistema externo?
**Resposta 2:** SEM-RESPOSTA
**Pergunta 3:** A assimetria retry-outbound / sem-retry-inbound foi uma decisão consciente de arquitetura documentada, ou é lacuna de implementação?
**Resposta 3:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: SchedulingService.schedule | ALTA | F3
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** thl1989z.p é um programa INTERNO do THL criado pelo time (que instancia OutboundMessageService.reprocess()), ou é o programa padrão Datasul RPW que executa por outro caminho?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Quando o RPW executa uma integração agendada, o resultado é gravado em thl-mensagem-historico e thl-mensagem-conteudo da mesma forma que no fluxo online?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: ConnectorConfig.constructor | MÉDIA | D2
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** A escolha de ConnectorConfig fazer FIND no construtor foi decisão consciente de Active Record, ou ocorreu porque o padrão de AuthenticationConfig foi replicado sem questionamento?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Existe cenário onde ConnectorConfig precisa ser construído sem acesso ao banco (ex: testes, configuração manual programática)?
**Resposta 2:** SEM-RESPOSTA

---

## ACHADO: RestConnector.(classe) | MÉDIA | D3
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** Quantos campos distintos de AuthenticationConfig são acessados em RestConnector? Se mais de 3, um 'token bundle' intermediário seria adequado.
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** A violação da Lei de Demeter foi identificada e aceita como trade-off, ou é consequência não planejada da estrutura de dados?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: InboundMessageService.constructor | MÉDIA | D3
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** Existe cenário planejado onde InboundMessageService usaria um MessageConfigLoader diferente do concreto padrão (ex: loader que lê de arquivo para desenvolvimento)?
**Resposta 1:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: OutboundMessageService.process | MÉDIA | D4
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** O ExecutionMode.BATCH está planejado para implementação? Se sim, a condicional inline se tornará IF/ELSE de 3 branches — quando seria o momento de extrair para uma estratégia?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** O ExecutionMode é realmente FLAGS com combinações de bits (ex: SCHEDULED | RETRY)? Se sim, um objeto de estratégia simples seria insuficiente para combinações.
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: OutboundMessage.appendPayloadObject | MÉDIA | D4
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** O overload sem parâmetro e o overload com OutboundObjectContext representam dois contratos distintos de construção de payload (auto-gerado vs. injetado), ou um é caso degenerado do outro?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Existiria forma de unificar os dois overloads em um único método abstrato sem quebrar as subclasses existentes?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: InboundMessage.methodPost / Patch / Delete / Get | MÉDIA | D5
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** Existe alguma subclasse de InboundMessage que implementa apenas subconjunto dos verbos HTTP (ex: apenas POST)? Se sim, como é declarado que ela não suporta os demais?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** A exceção 'X is not implemented' foi introduzida como alternativa consciente ao abstract para preservar flexibilidade de verbo por verbo?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: EmailService.sender | MÉDIA | B1
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** O envio de e-mail é considerado operação crítica (falha deve abortar o processamento) ou não-crítica (best-effort, falha registrada mas não propaga)?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** O campo thl-email.retorno é preenchido com a mensagem de erro de utapi019.p quando o envio falha?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** 2) EmailLogger.save() registra o retorno de utapi019.p em thl-email.retorno independentemente do status — diagnóstico via banco.

---

## ACHADO: SchedulingService.schedule | MÉDIA | B1
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** Se thl1989z.p falhar ao criar a entrada na fila RPW, o registro em thl-mensagem-ped-exec é criado mesmo assim? Ou a mensagem fica em estado 'agendada' sem entrada na fila?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** thl1989z.p retorna algum output-parameter que indica sucesso/falha do agendamento? Se sim, esse retorno é verificado antes de criar o ConnectorResponse?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: MessageFactory.(classe) | MÉDIA | B2
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** createMessage() pode ser chamado mais de uma vez na vida de uma instância de MessageFactory? Se sim, a referência message_ anterior é explicitamente deletada antes de ser substituída?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Qual é o modo PASOE (STATEFREE/STATEFUL) e a política de ciclo de vida das instâncias de MessageFactory — uma vez por agente ou uma vez por request?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: MessageStructureStrategy.(classe) | MÉDIA | B2
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** MessageStructureStrategy.outboundMessage é a mesma referência que MessageFactory.message_ (dois ponteiros, mesmo objeto) ou uma cópia independente?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Qual é o contrato de 'quem é responsável por deletar o OutboundMessage ao final' — MessageFactory ou MessageStructureStrategy?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: MessageFactory.createStructureStrategy | MÉDIA | B3
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** A tela de cadastro de thl-objeto valida que classe-objeto é subclasse de OutboundMessage antes de permitir o salvamento?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Já ocorreu em produção o caso de thl-objeto.classe-objeto apontar para uma classe de tipo incorreto? Como foi diagnosticado?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: JsonSetter.SetValue | MÉDIA | B3
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** JsonSetter.SetValue executa alguma operação de leitura (GetCharacter, GetInteger etc.) no payload, ou apenas operações de escrita (SetCharacter, Add etc.)?
**Resposta 1:** Sim
**Pergunta 2:** Se executa leitura, o campo lido é sempre garantido como presente pelo fluxo de chamada (ex: verificado em getRequiredFields antes)?
**Resposta 2:** Sim
**Obs. do Desenvolvedor:** Todos tem if payload:Has(trim(nameField)) then has antes - não entendi

---

## ACHADO: EmbarqueMessage.methodPost | MÉDIA | B4
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** InboundMessageService.processInbound() ou o bloco que chama dispatchInbound() declara DO TRANSACTION: explicitamente?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Se eqapi300 falhar após CREATE es_embarque, o embarque criado é desfeito (rollback automático)? Ou persiste em estado incompleto?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** block-level on error undo,throw garante rollback do CREATE se eqapi300 lançar exceção dentro do método.

---

## ACHADO: EnvironmentRepository.findEnvironmentCodeByPropath | MÉDIA | B4
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** Foi verificado qual lock level o OE 12 aplica por default em FOR EACH dentro de uma classe OOABL? (Pode diferir do comportamento em programas procedurais.)
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** A leitura de thl-ambiente precisa ser consistente (não aceita dirty read), ou NO-LOCK é aceitável para essa tabela de configuração de ambiente?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: EmailMessageFactory.loadRecipients | MÉDIA | B4
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** O EmailMessageFactory é instanciado dentro de uma transação de negócio ativa? Se sim, o FOR EACH pode herdar o contexto de lock da transação externa.
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Em produção, há queixas de lentidão no envio de e-mail ou deadlocks envolvendo thl-ambiente-param-grupo-usuar?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: EmbarqueMessage.methodPost | MÉDIA | P2
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** A rastreabilidade via thl-mensagem-item.chave-registro é considerada auditoria suficiente para operações de criação de embarque, sem precisar de AuditLogService?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** A tabela es_embarque tem trigger de auditoria Datasul que registra CREATE automaticamente?
**Resposta 2:** SEM-RESPOSTA
**Pergunta 3:** A ausência de AuditLogService.insertRecord foi decisão consciente (auditoria via item de mensagem é suficiente) ou não foi implementado?
**Resposta 3:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Modulo de auditoria não esta configurando não sera uando por hora

---

## ACHADO: LpcoMessage.methodPost / methodDelete | MÉDIA | P2
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** A rastreabilidade via thl-mensagem-item cobre a auditoria de CREATE e DELETE em nit-lpco (incluindo o conteúdo antes e depois da deleção)?
**Resposta 1:** Não, somente registra para sabe o que esta sendo executado na epoca
**Pergunta 2:** A tabela nit-lpco tem trigger de auditoria Datasul que registra DELETE automaticamente?
**Resposta 2:** Não, somente registra para sabe o que esta sendo executado na epoca

---

## ACHADO: (múltiplas classes).(vários métodos) | MÉDIA | P3
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** 17006 é um código de erro do DDK Datasul (definido externamente pelo produto TOTVS) ou código criado pelo próprio THL para um erro específico de domínio?
**Resposta 1:** Este codigo é codigo disponibilizado pela TOTVS para customizaçãoe é codigo para erro 17006, o que podemos fazer e colocar antes de cada mensagem nome do programa
**Pergunta 2:** Existe documentação ou constante no DDK que define este código formalmente (ex: cdcDefine.i ou similar arquivo de definições)?
**Resposta 2:** SEM-RESPOSTA

---

## ACHADO: MessageRepository.(classe) | MÉDIA | P3
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** Os valores 1/2/3/4 de sit-processamento são definidos pelo produto TOTVS (visíveis na tela de monitor Datasul) ou são específicos do THL?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Se são específicos do THL, foi considerado um ProcessingStatusEnum com valores nomeados (PENDENTE=1, ERRO=2, SUCESSO=3)?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: SchedulingService.schedule | MÉDIA | F1
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** thl1989z.p tem algum output-parameter que indica sucesso/falha? Se sim, como SchedulingService usa esse valor para preencher o ConnectorResponse?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** O ConnectorResponse retornado por schedule() é inspecionado pelo chamador (OutboundMessageService) para detectar falha de agendamento?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: InboundMessageService.receive | MÉDIA | F2
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** O http.log do PASOE registra requests para os endpoints inbound (timestamp, HTTP method, response code)?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Para diagnóstico de falha inbound (payload malformado, classe de mensagem não encontrada), qual informação está disponível nos registros de banco que seria insuficiente para o diagnóstico sem log de servidor?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: RestConnector.execute | MÉDIA | F3
**Veredicto P6:** QUESTIONAR
**Pergunta 1:** Existem registros em thl-conexao-rest com URL iniciando com http:// (sem TLS)?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Para integrações externas (sistemas fora da rede corporativa), todas as URLs estão configuradas com https://?
**Resposta 2:** SEM-RESPOSTA
**Pergunta 3:** A decisão de não enforçar HTTPS foi consciente (permitir HTTP para integrações internas) ou simplesmente não foi implementada a validação?
**Resposta 3:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: MessageFactory.createStructureStrategy | MÉDIA | D4
**Veredicto P6:** PROVÁVEL-OK
**Pergunta 1:** Existe plano concreto de adicionar terceiro tipo de estrutura de mensagem além de 'simples' e 'múltipla'? (Se sim, reclassificar para QUESTIONAR.)
**Resposta 1:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Pode fazer sugestão

---

## ACHADO: SchedulingService.schedule | MÉDIA | P3
**Veredicto P6:** PROVÁVEL-OK
**Pergunta 1:** thl1989z.p é um programa CRIADO PELO TIME THL (poderia ser renomeado) ou é o programa padrão do RPW do produto TOTVS com nome fixado pelo fornecedor?
**Resposta 1:** SEM-RESPOSTA
**Pergunta 2:** Em alguma instalação Datasul 12 esse programa existe com nome ou localização diferente de 'thl\thl1989z.p'?
**Resposta 2:** SEM-RESPOSTA
**Obs. do Desenvolvedor:** Este é programa para gera a genda e como tem variavel new global shared não foi colocado na classse
