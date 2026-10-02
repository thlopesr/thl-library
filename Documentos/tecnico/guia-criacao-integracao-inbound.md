# Guia de criação de integração inbound

> Revisado em 2026-09-24 contra o código e o `thl.df` disponível.

A integração inbound permite que sistemas externos enviem dados para o ERP através de rotas REST configuráveis.  Este guia descreve como adicionar uma nova rota e sua respectiva lógica de processamento.

## 1. Planejamento e mapeamento

* **Defina o objeto de integração** – Determine a entidade de negócio a ser criada ou atualizada (ex.: Usuário, Pedido).  
* **Especifique o payload** – Descreva o formato JSON que o sistema externo enviará.  
* **Defina os verbos e operações** – Quais verbos HTTP serão aceitos (POST/PATCH/PUT/DELETE/GET)? Operações podem ocupar o último segmento da URL. Para cadastros pai/filhos, use uma Message por agregado e rotas próprias apontando para o objeto do pai; selecione o Service por `context:routePath`. Não use operação para distinguir filho com vários verbos: a chave de `thl-objeto-parametro` não inclui o método. Ver [ADR da API REST §6](../.claude/adr/api-rest-cadastros-thl.md#6-revisão-de-2026-10-02--uma-message-por-agregado).

## 2. Configurar tabelas

1. **thl-objeto** – Insira um registro com `sentido-fluxo` como `FALSE` (inbound) e informe em `classe-objeto` o **nome completo** da classe (ex.: `thl-lib.integration.messaging.inbound.message.UsuarioMessage`, ou `thl-extensions.integration.<sistema>.messaging.inbound.message.<Nome>Message`).  
2. **thl-objeto-parametro** – Para cada verbo/operação:
   * Defina o `metodo` conforme `MethodTypeEnum`: **1=POST, 2=PUT, 3=PATCH, 4=DELETE, 5=GET**.
   * Configure `forma-execucao` (`ExecutionMode`: **1=ONLINE, 2=SCHEDULE** — processado depois pelo RPW thl0221rp, 3=BATCH) e `operacao` (o código da operação, igual ao último segmento da URL quando houver).
   * Outros campos (`ind-gera-historico`, `tipo-log-requisicao`, `tipo-log-retorno`) conforme necessário.
3. **thl-inbound-rota** – Cadastre uma rota pública:
   * `cod-rota` – Identificador único da rota.
   * `rota-publica` – Endereço exposto (ex.: `/api/v1/usuario/criar`).
   * `objeto` – Código do objeto cadastrado.
   * `aplicacao` – Aplicação do objeto.
   * `ind-ativo` – Marque como ativo.

   Sem rota cadastrada, o resolvedor usa `objeto = rota sem "/"` e `aplicacao = 'TOTVS'`.

## 3. Desenvolver a classe de mensagem inbound

Padrão *thin-wrapper*: a **mensagem** cuida do contrato; a **regra de negócio** fica num `Service` (subclasse de `thl-lib.erp.core.Service`). Mensagens genéricas ficam em `thl-lib\integration\messaging\inbound\message\`; as de um sistema externo, em `thl-extensions\integration\<sistema>\messaging\inbound\message\`.

```abl
using thl-lib.erp.core.Service.
using thl-lib.integration.messaging.inbound.core.InboundMessage.
using thl-lib.integration.connectors.enum.MethodTypeEnum.

block-level on error undo, throw.

class thl-extensions.integration.<sistema>.messaging.inbound.message.ExemploMessage inherits InboundMessage.

    constructor public ExemploMessage ( objectName as character, applicationName as character, integrationOperation as character,
                                        methodType as integer, connectorType as integer, integrationDirection as logical, executionMode as integer ).
        super( objectName, applicationName, integrationOperation, methodType, connectorType, integrationDirection, executionMode ).
    end constructor.

    //Factory Method obrigatorio: o Service recebe acao, operacao e payload via execute()
    method protected override Service createService().
        return new ExemploService().
    end method.

    method protected override character getRequiredFields().
        if this-object:methodType = MethodTypeEnum:DELETE:GetValue() then return 'codigo'.
        return 'codigo,descricao'.
    end method.

end class.
```

* POST/PATCH(PUT)/DELETE já estão implementados em `InboundMessage` (`executeService` → `Service:execute`) — sobrescreva `methodPost()`/`methodPatch()`/`methodDelete()` só se precisar.
* Para consultas, sobrescreva `methodGet()` e use `context:getQueryParam(...)`/`createPagination(...)`.
* O `Service` implementa `create()`/`update()`/`delete()`, `loadReferenceCode()` e `getEntityName()`; use `JsonSetter` para mapear o payload e `ThlError` para erros.
* Modelos reais: `LpcoMessage` + `LpcoService` (automatizador) e `FreteMessage` + `FretePrevistoService` (dvv) — ver `.claude\extensions\`.

## 4. Testar a rota

1. O endpoint é `resourcen.p` (API TOTVS), publicado em `/api/thl/integration/v1/resourcen/<rota-publica>[/<operacao>]`.  
2. Use `curl` ou Postman. Exemplo:
   ```bash
   curl -X POST -H "Content-Type: application/json" -d '{"codigoUsuario":"joao"}' https://host:porta/api/thl/integration/v1/resourcen/usuario
   ```
3. Verifique a resposta: sucesso com HTTP 200 e o JSON do `Service` (`{success, action, code, referenceCode, message}`), ou erro no padrão TOTVS (`JsonAPIResponseBuilder:asError`) com as mensagens do `ThlError`.  
4. Confira no monitor **THL0120** se a mensagem inbound foi registrada e qual o conteúdo salvo.  Caso haja erros, consulte `thl-mensagem-historico`.

## 5. Boas práticas

* **Codificação ISO-8859-1** – A classe de mensagem e o `Service` devem ser gravados em ISO-8859-1 (padrão do projeto), com o pacote em minúsculas igual à pasta.  
* **Validação de payload** – Antes de executar operações, valide campos obrigatórios e formatos.  Em caso de erro, utilize `ErrorHandler` para gerar mensagens padronizadas.  
* **Reaproveitamento de lógica** – Caso a mesma operação seja utilizada por múltiplos objetos, extraia para serviços de domínio reutilizáveis.  
* **Segurança** – Implemente mecanismos de autenticação e autorização no servidor web (por exemplo, tokens JWT) antes de encaminhar a requisição para `resourcen.p`.  A THL‑Lib trata apenas a mensagem após a autenticação.  
* **Retornos claros** – Sempre devolva respostas JSON contendo código, descrição e possíveis chaves de registro criadas ou alteradas.  
* **Documentação** – Documente a rota, payload e regras de negócio para que sistemas externos saibam como consumir a integração.

Com essas etapas, a criação de integrações inbound na THL‑Lib torna‑se padronizada, garantindo manutenção e extensibilidade.
