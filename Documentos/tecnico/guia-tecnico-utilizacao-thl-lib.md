# Guia técnico de utilização da THL‑Lib

Este guia fornece orientações gerais para desenvolvedores que desejem utilizar a THL‑Lib em integrações com o ERP TOTVS Datasul.  Ele complementa a visão geral e descreve passos práticos para trabalhar com a biblioteca.

## Conhecendo os componentes

1. **Programas de cadastro** – Use os programas da faixa `thl0xxx` (`thl0001` a `thl0051`) para configurar ambientes, parâmetros, objetos, métodos, usuários, conexões e rotas.  Esses cadastros definem como as integrações irão funcionar.  
2. **Biblioteca de classes** – Importe as classes necessárias com a instrução `using` em seus programas `.p` ou `.w`.  No uso normal, o programa só referencia o **serviço**; a classe de mensagem é resolvida pela configuração (`thl-objeto.classe-objeto`) e não precisa de `using`.  Exemplo:
   ```abl
   using thl-lib.integration.messaging.outbound.service.OutboundMessageService.
   using thl-lib.integration.messaging.outbound.core.OutboundObjectContext.
   ```
   As mensagens específicas de cada sistema externo ficam em `thl-extensions` (ex.: `thl-extensions.integration.loogai.messaging.outbound.message.EntregaPedidoMessage`), não em `thl-lib`.
3. **Chaves de configuração** – Cada integração (objeto/método) é identificada por um código de objeto e um método/operação.  Estas chaves são usadas nas tabelas `thl-objeto` e `thl-objeto-parametro`.

## Criando uma integração outbound simples

1. **Cadastre o objeto** em `thl-objeto` com um código (ex.: `PEDIDO`), defina `sentido-fluxo` como `TRUE` (outbound) e informe em `classe-objeto` o **nome completo** da classe (ex.: `thl-extensions.integration.loogai.messaging.outbound.message.EntregaPedidoMessage`).  
2. **Cadastre o método** em `thl-objeto-parametro`: defina o `metodo` conforme `MethodTypeEnum` (**1=POST, 2=PUT, 3=PATCH, 4=DELETE, 5=GET**), a `forma-execucao` conforme `ExecutionMode` (**1=ONLINE, 2=SCHEDULE, 3=BATCH**), `cod-param-ambiente` e demais indicadores.  Preencha `operacao` com o **código da operação de integração** (ex.: `Atualizacao`) — é a chave de busca da configuração, não um nome de método.
3. **Cadastre a conexão REST** em `thl-conexao-rest` e os paths e autenticação correspondentes.  
4. **No programa ou trigger do ERP**, instancie `OutboundMessageService` com aplicação, objeto e operação, monte a mensagem e processe:
   ```abl
   define variable messageService as OutboundMessageService no-undo.

   assign messageService = new OutboundMessageService( 'MinhaAplicacao', 'PEDIDO', 'Atualizacao' ).

   messageService:beginBuild().
   messageService:addObject( new OutboundObjectContext( recid( ped-venda ) ) ).
   messageService:finishBuild().
   messageService:process().
   ```
   Detalhes e o esqueleto da classe de mensagem: `guia-criacao-integracao-outbound.md`.
5. **Consultar mensagens** – Utilize `THL0120` para verificar se a mensagem foi enviada e qual foi o retorno.

## Criando uma integração inbound

1. **Cadastre o objeto** em `thl-objeto` com `sentido-fluxo` igual a `FALSE` (inbound).  Informe em `classe-objeto` o **nome completo** da classe (ex.: `thl-lib.integration.messaging.inbound.message.UsuarioMessage`; para um sistema externo específico, `thl-extensions.integration.<sistema>.messaging.inbound.message.<Nome>Message`).  
2. **Configure métodos** em `thl-objeto-parametro` para cada verbo suportado, conforme `MethodTypeEnum` (**1=POST, 2=PUT, 3=PATCH, 4=DELETE, 5=GET**).  Indique `forma-execucao` e `operacao`.  
3. **Cadastre a rota** em `thl-inbound-rota` definindo `rota-publica` (ex.: `/api/v1/usuario/criar`), associando ao `objeto`/`aplicacao` e marcando `ind-ativo`.  
4. **Implemente a classe de mensagem**: herde de `InboundMessage` e siga o padrão *thin-wrapper* — a mensagem cuida do contrato e a regra de negócio fica num `Service` (`thl-lib.erp.core.Service`):
   * `createService()` (**obrigatório**) — devolve o `Service` de domínio (ex.: `new UsuarioService()`);
   * `getRequiredFields()` — campos obrigatórios do payload, por verbo;
   * POST/PATCH/DELETE já têm implementação padrão em `InboundMessage` (`executeService` → `Service:execute`); sobrescreva `methodPost()`/`methodPatch()`/`methodDelete()` só se precisar de lógica diferente, e `methodGet()` para consultas.
   Modelos no código: `LpcoMessage` + `LpcoService` (`thl-extensions\…\automatizador\`) e `FreteMessage` + `FretePrevistoService` (`thl-extensions\…\dvv\`).  
5. **Testar via REST** – Faça uma requisição HTTP para a rota cadastrada.  O endpoint `resourcen.p` direcionará a chamada para sua classe e retornará a resposta JSON.

## Utilizando utilitários de e‑mail

* Para enviar e‑mails técnicos, monte a mensagem com `EmailMessageFactory` (destinatários, assunto, corpo, anexo, `applyPlaceholder`) e envie com `new EmailService( emailMessageFactory ):sender()` (`thl-lib.communication.email`).  O `sender()` chama o serviço de e‑mail do Datasul e grava o retorno em `thl-email`.  Certifique‑se de que grupos e parâmetros estejam configurados em `THL0011`.  

## Boas práticas

* **Codificação ISO-8859-1** – Grave todos os fontes ABL (`.cls`, `.p`, `.w`, `.i`) sempre em **ISO-8859-1** — nunca UTF-8 nem com BOM.  Ao editar, preserve a codificação do arquivo.  
* **Não acesse diretamente tabelas da THL‑Lib** em seu código; use os repositórios e serviços quando disponíveis.  Isso mantém as regras de negócio centralizadas.  
* **Evite lógica de negócio complexa nos programas `.w`**; delegue para classes em `thl‑lib`.  
* **Utilize os enums** (`MethodTypeEnum`, `ExecutionMode`, etc.) ao invés de números mágicos.  
* **Verifique o retorno** das operações e trate erros com `ErrorHandler`.  
* **Documente** novas integrações, adicionando arquivos Markdown correspondentes para que outras equipes entendam seu funcionamento.

Seguindo essas orientações, o desenvolvimento de integrações usando a THL‑Lib será mais organizado, reutilizável e sustentável.
