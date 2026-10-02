# Guia de configuração de conector REST

> Revisado em 2026-09-25 contra o código (`ConnectorConfig`, `MessageExecutionService`, `EnvironmentResource`, `EnvironmentRepository`) e o `thl.df`. Padrão do projeto: fontes ABL em **ISO-8859-1**.

Este guia explica como configurar conexões REST na THL‑Lib para consumo ou envio de dados a APIs externas.  As configurações são feitas totalmente via tabelas, permitindo mudanças sem recompilar programas.

## Visão geral

São quatro cadastros independentes e um vínculo por **variáveis de ambiente**:

| Cadastro | Programa | Chave | Ligação |
|---|---|---|---|
| Conexão (`thl-conexao-rest`) | **THL0030** | `cod-conexao` | — |
| Path (`thl-conexao-rest-path`) | **THL0031** | `cod-path` | **não pertence a uma conexão**: o mesmo path pode ser usado com qualquer conexão |
| Autenticação (`thl-conexao-rest-autenticacao`) | **THL0032** | `cod-conexao` | uma por conexão |
| Cabeçalho calculado (`thl-conexao-rest-header`) | **THL0033** | `cod-conexao` | uma por conexão |

Quem junta conexão e path para uma integração é o **parâmetro de ambiente** do objeto (seção 3). Diagrama dos vínculos: `.claude/data/er-diagrama.md`.

## 1. Cadastrar a conexão

1. Acesse o programa **THL0030** e clique em Incluir.  
2. Preencha os campos:
   * **Código** – Identificador da conexão (ex.: `APIERP`).
   * **Descrição** – Descrição amigável (ex.: `API do ERP Externo`).
   * **URL Base** – URL base da API (ex.: `https://api.exemplo.com`).
   * **Requisita autenticação** – Marque *Sim* se a API exigir obtenção de token (usa o cadastro do THL0032).
   * **Requer Cabeçalho** – Marque *Sim* se a API exigir cabeçalhos calculados (usa o cadastro do THL0033).
3. Salve o registro.

## 2. Cadastrar paths

1. No programa **THL0031**, clique em Incluir e informe o **código do path** (`cod-path`). O path **não é vinculado a uma conexão** neste cadastro — a combinação conexão + path é feita pelas variáveis de ambiente (seção 3).  
2. Preencha:
   * **Descrição** – Descrição do serviço (ex.: `Criar Pedido`).
   * **Path** – Rota relativa (ex.: `/pedidos`).
   * **Content‑Type** – Geralmente `application/json`.  
   * **Accept** – Tipos aceitos (ex.: `application/json`).  
   * **Timeout** – Tempo máximo de espera (segundos).  
   * **Parameters** – Parâmetros padrão (ex.: query string).  
   * **Headers** – Cabeçalhos adicionais (JSON no campo).  
3. Caso o serviço tenha vários endpoints, cadastre paths adicionais. Um path genérico (ex.: `/health`) pode ser reaproveitado por várias conexões.

## 3. Ligar conexão e path à integração (variáveis de ambiente)

Na execução, o `MessageExecutionService` cria o `ConnectorConfig` com três informações, e a conexão e o path saem de **valores de variáveis de ambiente**:

1. **Qual parâmetro de ambiente:** o programa é montado como `<aplicacao>.<objeto>` e procurado em `thl-ambiente-param-prog.cod-prog-dtsul` (aba *Programa* do **THL0002**). O registro encontrado dá o `cod-param-ambiente`.
2. **Qual variável tem a conexão:** o campo **Variável Conexão** (`thl-objeto-parametro.cod-param-ambiente`, cadastro **THL0022**) guarda o **código da variável** — não o código do parâmetro, apesar do nome técnico do campo.
3. **Qual variável tem o path:** o campo **Variável Destino** (`thl-objeto-parametro.cod-param-ambiente-destino`, THL0022) guarda o **código da variável** do path.
4. O **valor** de cada variável é lido em `thl-ambiente-param-variavel` (aba *Variável* do THL0002), primeiro para o ambiente corrente e, se não houver, para o ambiente `*`. Esse valor é o `cod-conexao` (THL0030) e o `cod-path` (THL0031).

**Exemplo** — objeto `PEDIDO` da aplicação `MMCM`:

| Onde | Cadastro | Valor |
|---|---|---|
| THL0002, aba Programa | parâmetro `MMCM`, programa `MMCM.PEDIDO` | liga o objeto ao parâmetro |
| THL0022 (operação do objeto) | Variável Conexão = `conexao` · Variável Destino = `path.pedido` | nomes das variáveis |
| THL0002, aba Variável | parâmetro `MMCM`, ambiente `*`: `conexao` = `MMCMAPI`; `path.pedido` = `PEDIDO-CRIAR` | valores |
| THL0030 / THL0031 | conexão `MMCMAPI`, path `PEDIDO-CRIAR` | URL base + rota |

Com isso, trocar de ambiente (produção × homologação) é só cadastrar variáveis com o `cod-ambiente` correspondente — a conexão e o path mudam sem alterar o THL0022.

**Erros comuns** (mensagens do `ConnectorConfig`):
* *"Parametro nao encontrado para o programa"* – falta `<aplicacao>.<objeto>` na aba Programa do THL0002.
* *"Codigo de conexao REST nao informado…"* / *"Codigo de path REST nao informado…"* – a variável indicada no THL0022 não existe ou está vazia no parâmetro.
* *"Codigo de conexao REST nao encontrada"* / *"Conexao REST PATH nao encontrada"* – o valor da variável não existe no THL0030 / THL0031.
* *"Configuracao de header nao encontrada para conexao"* – conexão com **Requer Cabeçalho** = *Sim* sem cadastro no THL0033.

## 4. Configurar autenticação (opcional)

Se a conexão exigir token ou outro tipo de autenticação (**Requisita autenticação** = *Sim* no THL0030):

1. Abra o programa **THL0032** e inclua a configuração **com o mesmo código da conexão** (uma por conexão):  
   * **URL Token** – Endpoint para solicitar token (ex.: `/oauth/token`).  
   * **Content‑Type Token / Accept Token** – Cabeçalhos específicos para a requisição de token.  
   * **Headers Token / Parameters Token** – Cabeçalhos e parâmetros adicionais (JSON).  
   * **Tipo Autenticação** – Descrição do tipo (ex.: `Bearer`).  
   * **Requisita Token** – Marque *Sim* se o token precisar ser renovado.  
   * **Usuário / Senha** – Credenciais para autenticação básica, se aplicável.  
   * **Classe Parser Token** (`classe-parser-token`) – **Nome completo** da classe que obtém/interpreta o token (ex.: `thl-extensions.integration.mmcm.connectors.auth.TokenProvider`).  Deve implementar `thl-lib.integration.connectors.auth.interfaces.ITokenProvider`; é instanciada por `TokenProviderFactory` via `dynamic-new`.  
2. A autenticação pode ser customizada criando novas classes que implementem `ITokenProvider` e registrando na configuração.

## 4.1 Headers calculados (opcional)

Se a API exigir cabeçalhos gerados em tempo de execução (ex.: assinatura HMAC), marque **Requer Cabeçalho** = *Sim* no THL0030 e cadastre em **THL0033** (`thl-conexao-rest-header`), **com o mesmo código da conexão**: `classe-parser` com o **nome completo** de uma classe que implemente `thl-lib.integration.connectors.headers.interfaces.IHeaderProvider` (`getHeaders( body, parameters ): JsonArray`) e `parameters` com o valor repassado a ela (ex.: o *secret*). Exemplo real: `thl-extensions.integration.gestaoepi.connectors.headers.HeaderProvider`.

## 5. Utilização no código

Nos fluxos de mensageria **não se chama o conector diretamente**: `OutboundMessageService` → `MessageExecutionService` → `ConnectorService:execute( ConnectorRequest )` → `ConnectorFactory:createConnector( connectorType )` → `RestConnector`. O conector combina `url-base` e `path`, aplica cabeçalhos, parâmetros, token (`ITokenProvider`) e headers calculados (`IHeaderProvider`). A conexão e o path são resolvidos como na seção 3 — detalhes em `.claude\integration\connectors.md`.

Para uma integração outbound nova, siga `guia-criacao-integracao-outbound.md`; o conector é configurado só por cadastro.

## 6. Boas práticas

* **Evite hard‑code** de URLs no código; utilize sempre os cadastros de conexão e path.  
* **Nomes de variáveis estáveis** – Use no THL0022 nomes de variável que descrevam o papel (`conexao`, `path.pedido`) e mude só os **valores** por ambiente.  
* **Versionamento** – Para APIs versionadas, crie paths distintos (ex.: `/v1/pedidos`, `/v2/pedidos`).  
* **Segurança** – Mantenha senhas e tokens protegidos.  Se possível, encripte ou utilize cofre de senhas (não abordado pela THL‑Lib).  
* **Monitoramento** – Acompanhe erros de autenticação e expiração de token no monitor de mensagens (THL0120).  Configure e‑mails de alerta.  
* **Classes de parser** – Sempre que o formato de retorno do token mudar, crie uma nova classe que implemente `ITokenProvider` para interpretar corretamente.

Seguindo este guia, as conexões REST serão configuradas de forma flexível e segura, favorecendo a manutenção das integrações.
