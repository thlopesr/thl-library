---
tipo: modulo
camada: core
status: vigente
tags: [thl-lib, rest, conectores]
updated: 2026-10-13
---

# Pacote: integration/connectors

| Classe | Responsabilidade | Padrão | Depende de | Usado por |
|---|---|---|---|---|
| ConnectorTypeEnum | Enum dos tipos de conector suportados (REST, SOAP, DATABASE, FILE) | — | — | ConnectorFactory, ConnectorRequest |
| MethodTypeEnum | Enum dos métodos HTTP (POST, PUT, PATCH, DELETE, GET) | — | — | RestConnector, InboundMessage |
| ConnectorConfig | DTO de configuração de uma conexão REST (URL, path, autenticação, header provider) | — | EnvironmentResource, AuthenticationConfig, ThlError | ConnectorRequest, RestConnector, MessageExecutionService |
| ConnectorRequest | DTO de requisição de conector (tipo, método, payload, configuração) | — | ConnectorConfig | ConnectorService, MessageExecutionService, RestConnector |
| ConnectorResponse | DTO de resposta de conector (success flags, status, conteúdo) | — | — | ConnectorService, MessageExecutionService, OutboundMessageService, SchedulingService |
| IntegrationConnector | Classe abstrata base para todos os conectores | Template Method | ConnectorRequest, ConnectorResponse | ConnectorFactory, RestConnector |
| RestConnector | Implementação HTTP/REST com suporte a autenticação (BASIC, BEARER, TOKEN, CUSTOM.BODY) e header providers calculados | Template Method | IntegrationConnector, MethodTypeEnum, TokenProviderFactory, ITokenProvider, AuthenticationConfig, IHeaderProvider, HeaderProviderFactory, StringUtil, ThlError | ConnectorFactory |
| ConnectorFactory | Cria a instância correta de conector por tipo | Factory | ConnectorTypeEnum, RestConnector, ThlError | ConnectorService |
| ConnectorService | Orquestra execução de conectores: valida, delega ao factory, loga falhas | Service | ConnectorFactory, LogUtil, ThlError | MessageExecutionService |
| ITokenProvider | Interface para parsers de token de autenticação | — | AuthenticationConfig | TokenProviderFactory, RestConnector |
| AuthenticationConfig | DTO de configuração de autenticação de uma conexão REST | — | AuthenticationRepository, StringUtil, ThlError | ConnectorConfig, RestConnector |
| AuthenticationRepository | Persiste token na tabela `thl-conexao-rest-autenticacao` | Repository | ThlError | RestConnector (via AuthenticationConfig) |
| TokenProviderFactory | Cria instância de `ITokenProvider` via `dynamic-new` | Factory | ITokenProvider, StringUtil, ThlError | RestConnector |

---

## ConnectorTypeEnum

**Caminho:** `thl-lib\integration\connectors\enum\ConnectorTypeEnum.cls`

**Namespace ABL:** `thl-lib.integration.connectors.enum.ConnectorTypeEnum`

**Responsabilidade:** Enum que define os tipos de conector suportados. Apenas REST está implementado; SOAP, DATABASE e FILE estão comentados em `ConnectorFactory`.

**Valores:** `REST = 1`, `SOAP = 2`, `DATABASE = 3`, `FILE = 4`

---

## MethodTypeEnum

**Caminho:** `thl-lib\integration\connectors\enum\MethodTypeEnum.cls`

**Namespace ABL:** `thl-lib.integration.connectors.enum.MethodTypeEnum`

**Responsabilidade:** Enum dos métodos HTTP.

**Valores:** `POST = 1`, `PUT = 2`, `PATCH = 3`, `DELETE = 4`, `GET = 5`

---

## ConnectorConfig

**Caminho:** `thl-lib\integration\connectors\core\ConnectorConfig.cls`

**Namespace ABL:** `thl-lib.integration.connectors.core.ConnectorConfig`

**Responsabilidade:** DTO de configuração de conector REST. O construtor principal lê `EnvironmentResource( programName )` — `programName` = `aplicacao.objeto`, localizado em `thl-ambiente-param-prog.cod-prog-dtsul` — e busca o **valor** das variáveis `parameterCode` (= `thl-objeto-parametro.cod-param-ambiente`) e `routeParameterCode` (= `cod-param-ambiente-destino`): esses valores são o `cod-conexao` e o `cod-path` (os dois campos de `thl-objeto-parametro` guardam **códigos de variável**, não de parâmetro). O path não pertence a uma conexão. Com esses códigos, consulta `thl-conexao-rest` e `thl-conexao-rest-path` para preencher todas as propriedades. Existe também um construtor secundário para requisição de token (recebe `AuthenticationConfig`).

**Padrão de projeto:** Nenhum (DTO com construtor de leitura de banco).

**INHERITS / IMPLEMENTS:** Nenhum.

**Dependências diretas THL:** `EnvironmentResource`, `AuthenticationConfig`, `ThlError`.

**Tabelas acessadas:** `thl-conexao-rest`, `thl-conexao-rest-path`.

**Propriedades públicas:**

| Nome | Tipo |
|---|---|
| `baseUrl` | `character` |
| `requiresAuthentication` | `logical` |
| `connectionCode` | `character` (get público, set **privado**) |
| `path` | `character` |
| `contentType` | `character` |
| `accept` | `character` |
| `headers` | `character` |
| `parameters` | `character` |
| `timeout` | `integer` |
| `requiresHeaderProvider` | `logical` |
| `headerProviderClass` | `character` (nome da classe que implementa `IHeaderProvider`) |
| `headerParameter` | `character` (parâmetro passado ao header provider) |
| `authentication` | `AuthenticationConfig` |

**Tabelas acessadas:** `thl-conexao-rest`, `thl-conexao-rest-path`, `thl-conexao-rest-header`. A configuração de header é única por conexão (`thl-conexao-rest-header.pk-conexao-rest`, único desde 2026-09-24); antes a tabela não tinha índice e o `find first` lia a tabela inteira.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `constructor public ConnectorConfig( programName as character, parameterCode as character, routeParameterCode as character )` | Resolve conexão e path via `EnvironmentResource`. Se `thl-conexao-rest.ind-requisita-header = true`, carrega também `thl-conexao-rest-header` e preenche `requiresHeaderProvider`, `headerProviderClass`, `headerParameter`. Lança `ThlError` se algum código não for encontrado. |
| `constructor public ConnectorConfig( authentication as AuthenticationConfig )` | Cria configuração para requisição de token usando dados de `AuthenticationConfig`. |

**Tratamento de erro:** Lança `ThlError` para código de conexão vazio, conexão não encontrada, path não encontrado, e header não encontrado quando `ind-requisita-header = true`.

---

## ConnectorRequest

**Caminho:** `thl-lib\integration\connectors\core\ConnectorRequest.cls`

**Namespace ABL:** `thl-lib.integration.connectors.core.ConnectorRequest`

**Responsabilidade:** DTO de requisição. Transporta tipo de conector, método HTTP, payload (`JsonConstruct` ou `longchar`), configuração técnica e parâmetros de path.

**Propriedades públicas:**

| Nome | Tipo |
|---|---|
| `connectorType` | `integer` |
| `methodType` | `integer` |
| `content` | `JsonConstruct` |
| `contentText` | `longchar` |
| `connectorConfig` | `ConnectorConfig` |
| `pathParameters` | `JsonArray` |

---

## ConnectorResponse

**Caminho:** `thl-lib\integration\connectors\core\ConnectorResponse.cls`

**Namespace ABL:** `thl-lib.integration.connectors.core.ConnectorResponse`

**Responsabilidade:** DTO de resposta. Possui três flags de sucesso separadas: `successRequest` (HTTP enviado sem erro técnico), `successResponse` (status HTTP 2xx), `successProcess` (lógica de negócio do response bem-sucedida).

**Propriedades públicas:**

| Nome | Tipo | Semântica |
|---|---|---|
| `successRequest` | `logical` | true = requisição HTTP foi executada sem exceção |
| `successResponse` | `logical` | true = status HTTP 2xx |
| `successProcess` | `logical` | true = regra de negócio do response aplicada com sucesso (pode ser `?`) |
| `statusCode` | `integer` | Código HTTP retornado |
| `statusMessage` | `character` | Descrição do status |
| `content` | `longchar` | Corpo da resposta |
| `destination` | `character` | URL ou destino (ex: `'RPW'`) |

---

## IntegrationConnector

**Caminho:** `thl-lib\integration\connectors\types\IntegrationConnector.cls`

**Namespace ABL:** `thl-lib.integration.connectors.types.IntegrationConnector`

**Responsabilidade:** Classe abstrata base para todos os conectores. Define o contrato único `execute(ConnectorRequest): ConnectorResponse`.

**Padrão de projeto:** Template Method (define o contrato; subclasses implementam `execute`).

**INHERITS / IMPLEMENTS:** Nenhum. Declarado `abstract`.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public abstract ConnectorResponse execute( connectorRequest as ConnectorRequest )` | Contrato de execução. |

---

## RestConnector

**Caminho:** `thl-lib\integration\connectors\types\RestConnector.cls`

**Namespace ABL:** `thl-lib.integration.connectors.types.RestConnector`

**Responsabilidade:** Implementa requisições HTTP usando `System.Net.HttpWebRequest`. Suporta autenticação BASIC, BEARER, TOKEN e CUSTOM.BODY. Gerencia o ciclo de vida do token (verificação de expiração, requisição de token, parsing via `TokenProviderFactory`). Normaliza a resposta como JSON.

**Padrão de projeto:** Template Method — `execute` é o método público; os métodos `protected` formam os passos do template.

**INHERITS / IMPLEMENTS:** `inherits IntegrationConnector`

**Dependências diretas THL:** `IntegrationConnector`, `MethodTypeEnum`, `TokenProviderFactory`, `ITokenProvider`, `AuthenticationConfig`, `ConnectorConfig`, `ConnectorRequest`, `ConnectorResponse`, `StringUtil`, `ThlError`.

**Métodos públicos/protected relevantes:**

| Assinatura | Descrição |
|---|---|
| `method public override ConnectorResponse execute( input connectorRequest as ConnectorRequest )` | Ponto de entrada. Valida, resolve URL, obtém authorization key, executa HTTP, preenche response. CATCH captura exceções e retorna `successRequest = false`. |
| `method protected void validateExecutionInput( input connectorRequest as ConnectorRequest )` | Valida presença de request, config e autenticação. |
| `method protected character buildRequestUrl( input connectorRequest as ConnectorRequest )` | Monta a URL final aplicando path parameters e query parameters. |
| `method protected character resolvePathParameters( input pathTemplate as character, input pathParameters as JsonArray )` | Substitui placeholders no template de path. |
| `method protected character resolveAuthorizationKey( connectorConfig as ConnectorConfig )` | Verifica expiração e obtém token de autenticação quando necessário. |
| `method protected void executeTokenRequest( authentication as AuthenticationConfig )` | Executa POST para obter token; usa `TokenProviderFactory` para parsear resposta. |
| `method protected longchar executeRequest( input requestUrl as character, input connectorRequest as ConnectorRequest, input authorizationKey as character, input-output connectorResponse as ConnectorResponse )` | Cria `HttpWebRequest` via `createHttpRequest`, escreve body, lê response. CATCH de `WebException` captura erros HTTP via `readErrorResponse`. |
| `method protected HttpWebRequest createHttpRequest( requestUrl as character, connectorRequest as ConnectorRequest, authorizationKey as character )` | Monta `HttpWebRequest`: TLS 1.2, timeout, accept, method, content-type, headers estáticos (`setHeader`), autenticação (`applyAuthentication`), headers calculados (`applyCalculatedHeaders`). |
| `method protected void setHeader( input request as HttpWebRequest, input headersParameter as character )` | Parseia JSON array de `{key, value}` e injeta cabeçalhos no request. |
| `method protected void writeRequestContent( input request as HttpWebRequest, input connectorRequest as ConnectorRequest )` | Serializa `contentText` como bytes UTF-8 no stream do request. No-op para GET ou conteúdo vazio. |
| `method protected longchar readResponseContent( input response as HttpWebResponse )` | Lê `GetResponseStream()` como UTF-8 e retorna longchar. |
| `method protected longchar readErrorResponse( input webError as WebException, input-output connectorResponse as ConnectorResponse )` | Lê corpo do erro HTTP; preenche `statusCode`/`statusMessage` no response. |
| `method protected longchar normalizeResponseContent( input responseContent as longchar )` | Re-parseia e re-serializa JSON para normalizar formato. Lança exceção se não for JSON válido. |
| `method protected void applyCalculatedHeaders( input request as HttpWebRequest, input connectorRequest as ConnectorRequest )` | Se `requiresHeaderProvider = true`, instancia o provider via `HeaderProviderFactory` e injeta os headers calculados (`getHeaders(body, parameter)`) no request. |
| `method protected void applyAuthentication( request as HttpWebRequest, connectorRequest as ConnectorRequest, authorizationKey as character )` | Aplica cabeçalho de autorização conforme `authenticationType` (BASIC/BEARER/TOKEN/CUSTOM.BODY). |
| `method protected character resolveHttpMethod( input methodType as integer )` | Converte enum `MethodTypeEnum` em string HTTP (GET, POST, etc.). |
| `method protected character getContentType( input connectorConfig as ConnectorConfig )` | Retorna `connectorConfig:contentType` ou `'application/json'` como padrão. |
| `method protected character ConvertBase64( input textValue as longchar )` | Codifica para Base64 UTF-8 (usado em BASIC auth). |
| `method protected logical isTechnicalSuccess( input statusCode as integer )` | Retorna `true` para códigos 200–299. |

**Tratamento de erro:** CATCH em `execute` captura qualquer exceção e retorna `successRequest = false`. CATCH em `executeRequest` captura `WebException` e lê o corpo do erro HTTP.

**Observações:**
- Força `TLS 1.2` via `ServicePointManager:SecurityProtocol`.
- `normalizeResponseContent` lança exceção se a resposta não for JSON válido.
- `CUSTOM.BODY`: injeta o token diretamente no payload JSON do request via `JsonObject:Set`.
- `applyCalculatedHeaders` é o ponto de extensão para lógica de header dinâmico (assinaturas HMAC, tokens gerados, etc.) — implementado via `IHeaderProvider`.

---

## ConnectorFactory

**Caminho:** `thl-lib\integration\connectors\factory\ConnectorFactory.cls`

**Namespace ABL:** `thl-lib.integration.connectors.factory.ConnectorFactory`

**Responsabilidade:** Cria a instância correta de `IntegrationConnector` por tipo. Atualmente suporta apenas REST (SOAP, DATABASE e FILE estão comentados).

**Padrão de projeto:** Factory.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public IntegrationConnector createConnector( connectorType as integer )` | Retorna `new RestConnector()` para tipo REST. Lança `ThlError` para tipos não suportados. |

---

## ConnectorService

**Caminho:** `thl-lib\integration\connectors\service\ConnectorService.cls`

**Namespace ABL:** `thl-lib.integration.connectors.service.ConnectorService`

**Responsabilidade:** Ponto de entrada público para execução de conectores. Valida o request, instancia o conector via factory, executa e loga falhas técnicas.

**Padrão de projeto:** Service.

**Dependências diretas THL:** `ConnectorFactory`, `IntegrationConnector`, `ConnectorRequest`, `ConnectorResponse`, `LogUtil`, `ThlError`.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public ConnectorResponse execute( input request as ConnectorRequest )` | Valida request, cria conector via factory, executa. Loga falhas de response (HTTP não 2xx) via `LogUtil`. CATCH relança a exceção após log. |

**Tratamento de erro:** Lança `ThlError` para request nulo ou conector nulo. CATCH geral loga e relança a exceção original.

---

## ITokenProvider

**Caminho:** `thl-lib\integration\connectors\auth\interfaces\ITokenProvider.cls`

**Namespace ABL:** `thl-lib.integration.connectors.auth.interfaces.ITokenProvider`

**Responsabilidade:** Interface contratual para classes que sabem parsear a resposta de autenticação de uma API específica e persistir o token em `AuthenticationConfig`.

**Métodos:**

| Assinatura | Descrição |
|---|---|
| `method public void parsingToken( authentication as AuthenticationConfig, response as JsonObject )` | Extrai o token da resposta e chama `authentication:saveToken(...)`. |

---

## AuthenticationConfig

**Caminho:** `thl-lib\integration\connectors\auth\core\AuthenticationConfig.cls`

**Namespace ABL:** `thl-lib.integration.connectors.auth.core.AuthenticationConfig`

**Responsabilidade:** DTO de configuração de autenticação. O construtor com `connectionCode` lê `thl-conexao-rest-autenticacao` para preencher todas as propriedades. O construtor vazio cria configuração nula (tipo `'No Auth'`). Inclui lógica de verificação de expiração de token (`isTokenExpired`) e atualização em memória (`saveToken`).

**Tabelas acessadas:** `thl-conexao-rest-autenticacao`.

**Propriedades públicas:**

| Nome | Tipo |
|---|---|
| `tokenUrl` | `character` |
| `tokenMethod` | `character` |
| `tokenContentType` | `character` |
| `tokenAccept` | `character` |
| `tokenHeaders` | `longchar` |
| `tokenParameters` | `longchar` |
| `tokenTimeout` | `integer` |
| `authenticationType` | `character` (BASIC / BEARER / TOKEN / CUSTOM.BODY / No Auth) |
| `requiresTokenRequest` | `logical` |
| `userName` | `character` |
| `password` | `character` |
| `token` | `character` |
| `rawTokenData` | `longchar` |
| `tokenExpiration` | `datetime` |
| `tokenParserClass` | `character` |
| `connectionCode` | `character` |

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public logical isTokenExpired()` | Retorna `true` se token vazio ou `tokenExpiration <= now`. |
| `method public void saveToken( accessToken as longchar, expirationDate as datetime )` | Atualiza token e expiração em memória. A persistência em banco é responsabilidade do chamador (RestConnector → AuthenticationRepository). |

---

## AuthenticationRepository

**Caminho:** `thl-lib\integration\connectors\auth\repository\AuthenticationRepository.cls`

**Namespace ABL:** `thl-lib.integration.connectors.auth.repository.AuthenticationRepository`

**Responsabilidade:** Persiste o token obtido na tabela `thl-conexao-rest-autenticacao` (exclusive-lock). Único método de escrita de banco no pacote de conectores.

**Padrão de projeto:** Repository.

**Tabelas acessadas:** `thl-conexao-rest-autenticacao` (exclusive-lock).

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public void persistToken( connectionCode as character, accessToken as longchar, expirationDate as datetime )` | Atualiza `token` e `dt-expiracao-token` na tabela. Lança `ThlError` com errorNumber `0` se conexão não encontrada. |

**Observações:** `errorNumber = 0` no `ThlError` pode causar comportamento inesperado no `getErrorStatusCode` do `ErrorHandler` (retornará `500`, pois `GetMessageNum(1) = 0`).

---

## TokenProviderFactory

**Caminho:** `thl-lib\integration\connectors\auth\factory\TokenProviderFactory.cls`

**Namespace ABL:** `thl-lib.integration.connectors.auth.factory.TokenProviderFactory`

**Responsabilidade:** Instancia dinamicamente uma implementação de `ITokenProvider` via `dynamic-new` a partir do nome da classe (configurado em `thl-conexao-rest-autenticacao.classe-parser-token`).

**Padrão de projeto:** Factory.

**Dependências diretas THL:** `ITokenProvider`, `StringUtil`, `ThlError`.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public static ITokenProvider getProvider( className as character )` | Instancia `dynamic-new className()`. Lança `ThlError` (código `17005`) se `className` vazio; lança `ThlError` se instanciação falhar. |

**Observações:** Usa `error-status:error` para detectar falha no `dynamic-new`, que é padrão ABL para instanciação dinâmica.

---

## IHeaderProvider

**Caminho:** `thl-lib\integration\connectors\headers\interfaces\IHeaderProvider.cls`

**Namespace ABL:** `thl-lib.integration.connectors.headers.interfaces.IHeaderProvider`

**Responsabilidade:** Interface contratual para classes que geram headers HTTP calculados dinamicamente (ex: assinaturas HMAC, tokens de requisição, etc.). Implementações recebem o body da requisição e um parâmetro de configuração, e retornam um `JsonArray` de objetos `{key, value}` para injetar no request.

**Métodos:**

| Assinatura | Descrição |
|---|---|
| `method public JsonArray getHeaders( body as longchar, parameters as character )` | Retorna array de `{key, value}` para injetar como headers HTTP. `body` é o conteúdo da requisição; `parameters` vem de `thl-conexao-rest-header.valor-parametro`. |

**Observações:** Criada em 2026-08-24. Configurada via `thl-conexao-rest.ind-requisita-header` e `thl-conexao-rest-header.classe-parser`. A instância é criada dinamicamente pelo `HeaderProviderFactory`.

---

## HeaderProviderFactory

**Caminho:** `thl-lib\integration\connectors\headers\factory\HeaderProviderFactory.cls`

**Namespace ABL:** `thl-lib.integration.connectors.headers.factory.HeaderProviderFactory`

**Responsabilidade:** Instancia dinamicamente uma implementação de `IHeaderProvider` via `dynamic-new` a partir do nome da classe configurado em `thl-conexao-rest-header.classe-parser`.

**Padrão de projeto:** Factory.

**Dependências diretas THL:** `IHeaderProvider`, `StringUtil`, `ThlError`.

**Métodos públicos:**

| Assinatura | Descrição |
|---|---|
| `method public static IHeaderProvider getProvider( className as character )` | Instancia `dynamic-new className()`. Lança `ThlError` se `className` vazio ou se instanciação falhar. |

**Observações:** Usa `error-status:error` para detectar falha no `dynamic-new`. Padrão idêntico ao `TokenProviderFactory`.
