---
programa: thl0032
titulo: Autenticação da conexão
grupo: thl003 Conexão REST
tabela: thl-conexao-rest-autenticacao
notion: https://www.notion.so/3f1d3a2b481581feb315d1c4f9f9dc36
atualizado: 2026-10-13
tags: [thl, cadastro, thl003]
---

# thl0032 — Autenticação da conexão

## Objetivo da tela

Define **como a biblioteca se autentica** numa conexão ([[thl0030 Conexões REST]]) marcada com *Requisita Autenticacao*: tipo de autenticação, usuário e senha, token já obtido e, quando o token precisa ser pedido, o serviço que o emite e a classe que lê a resposta. Uma única configuração por conexão.

Estrutura: `thl0032.w` + `thl0032-v01.w`, `-q01.w`, `-b01.w` (filtro por faixa de conexão), `-z01.w` e `-g01.w` **próprios** (os do thl0030 devolvem o ROWID de `thl-conexao-rest`, não desta tabela).

## Relacionamentos

| Relação | Detalhe |
|---|---|
| Pai | [[thl0030 Conexões REST]] — 1:1 por `cod-conexao` (mesmo valor). Zoom no campo: F5 / duplo clique → `thl/thl0030-z01.w`. |
| **Eliminação** | Sem `local-delete-record`: elimina direto, sem bloqueio. Eliminar a conexão (thl0030) elimina esta configuração junto. |
| Classe do parser | `classe-parser-token` guarda o nome completo de uma classe `ITokenProvider`, carregada por `dynamic-new` — **mover/renomear a classe exige atualizar este cadastro**. |

## Dicionário de campos

| Label na tela | Campo físico | Tipo / formato | Obrig. | Chave / único | Valores / origem | Validação e mensagem | O que faz |
|---|---|---|---|---|---|---|---|
| Conexao REST | `thl-conexao-rest-autenticacao.cod-conexao` | character `x(40)` | S | S — `pk-conexao-rest` (primário, único). Só na inclusão | Zoom do thl0030 (F5 / duplo clique) | Conexão inexistente → mensagem **2** (nome da tabela via `ut-table.i`) · já tem autenticação → **17006** "Autenticacao ja cadastrado para a conexao~~Cada conexao tem uma unica configuracao; altere a existente." | Liga a configuração à conexão; `AuthenticationConfig` a busca por este código. |
| URL Token | `.url-token` | character `x(300)` | N | N | URL do serviço de token | Nenhuma | Destino do POST que obtém o token (`RestConnector:executeTokenRequest`). Só vale com *Requer Token* = Sim. |
| Content-Type Token | `.content-type-token` | character `x(80)`, inicial `application/json` | N | N | Tipo MIME | Nenhuma | Content-Type da requisição de token (vazio assume `application/json`). |
| Accept Token | `.accept-token` | character `x(80)`, inicial `application/json` | N | N | Tipo MIME | Nenhuma | Accept da requisição de token. |
| Cabeçalhos Token | `.headers-token` | character `x(4000)` | N | N | JSON: `[{"key":"…","value":"…"}]` | Nenhuma | Cabeçalhos extras da requisição de token (`setHeader`). |
| Parâmetros Token | `.parameters-token` | character `x(4000)` | N | N | JSON (segundo o dicionário) | Nenhuma | ⚠ a confirmar: o valor chega ao `ConnectorConfig` do token, mas `executeTokenRequest` chama o serviço direto em `url-token` e `createHttpRequest` não lê `parameters` — pela leitura, **não tem efeito**. |
| Tipo Autenticacao | `.tipo-autenticacao` | character `x(20)`, inicial `NONE` | N | N | Texto livre (sem combo). O código trata `BASIC`, `BEARER`, `TOKEN`, `CUSTOM.BODY`; outro valor não faz nada | Nenhuma | Escolhe o ramo de `RestConnector:applyAuthentication`. A descrição do dicionário ("NONE, BASIC, BEARER, API_KEY, OAUTH2 ou CUSTOM") está **desatualizada** — vale o `case` do conector. |
| Requisita Token | `.ind-requisita-token` | logical `Sim/Não`, inicial não | N | N | Toggle | Nenhuma | **Sim** → antes de cada chamada, se o token estiver vazio, sem expiração ou vencido (`isTokenExpired`), chama o serviço de token e usa o token resultante. **Não** → usa o valor do campo Token como está. |
| Usuario | `.usuario` | character `x(80)` | N | N | Texto livre | Nenhuma | Tipo `BASIC`: `Authorization: Basic base64( usuario:senha )`. Não entra no corpo da requisição de token. |
| Senha | `.senha` | character `x(200)` | N | N | Texto livre | Nenhuma | Par do usuário no `BASIC`. ⚠ **Exibida em claro** na tela (o fill-in não é mascarado) e **gravada sem criptografia** (descrição do dicionário). |
| Token | `.token` | character `x(4000)` | N | N | Texto | Nenhuma (campo editável) | Token vigente. Sem *Requisita Token*, `BEARER`/`TOKEN` enviam `Authorization: <tipo> <token>`. Com *Requisita Token*, o token obtido vai no cabeçalho `KeyAuthentication`. O HELP diz "gravado automaticamente", mas ⚠ **nenhum código grava** neste campo (ver Regras). |
| Retorno Token | `.raw-token-data` | character `x(4000)` | N | N | Texto — em geral JSON de credenciais | Nenhuma | ⚠ Rótulo e HELP ("Retorno bruto do serviço de token / gravado automaticamente") **contradizem o uso**: o `RestConnector` envia este campo como **corpo (body) do POST de token**. |
| Expiracao Token | `.dt-expiracao-token` | datetime `99/99/9999 HH:MM:SS` | N | N | Data e hora | Nenhuma (campo editável) | Base de `isTokenExpired`: nulo conta como expirado; `<= agora` expira. |
| Classe Parser Token | `.classe-parser-token` | character `x(400)` | N na tela | N | Nome completo (pacote) de classe `ITokenProvider`, ex.: `thl-extensions.integration.mmcm.connectors.auth.TokenProvider` | Nenhuma na tela | Interpreta a resposta do serviço de token e chama `saveToken` (token e validade). Em branco com *Requisita Token* = Sim → erro de runtime "Classe do provider de token nao informada" (17005). |

## Regras e mensagens

- Validações da tela, **só na inclusão**: a conexão precisa existir (**2**) e não ter autenticação (**17006**). Nada mais é validado: tipo, classe, JSON, URL e coerência com *Requisita Autenticacao* do thl0030 não são conferidos.
- O cabeçalho do bloco de comentários da `Pi-validate` cita "THL0031" e regras de path (texto copiado do thl0031); não vale para esta tela.
- **Token não persiste** (⚠ a confirmar): `AuthenticationConfig:saveToken` só atualiza o objeto em memória, e `AuthenticationRepository:persistToken` — que gravaria `token` e `dt-expiracao-token` — **não tem nenhum chamador** em `Fontes`. Como cada envio cria um `AuthenticationConfig` novo a partir deste cadastro, o token tende a ser pedido de novo a cada chamada, e a data de expiração mostrada aqui só muda se for digitada.
- O timeout da requisição de token é fixo em **30000** no código (`AuthenticationConfig`); não há campo.
- `SensitiveFields` da API (`ConexaoRestAutenticacaoService`): `headersToken`, `parametersToken`, `senha`, `token`, `rawTokenData` são mascarados na consulta REST.

## Uso em runtime

| Classe | Uso |
|---|---|
| `AuthenticationConfig` | Carrega todos os campos (`find first … where cod-conexao`); erro "Conexao autenticacao REST nao encontrada" se faltar. |
| `ConnectorConfig` | Só cria o `AuthenticationConfig` quando `thl-conexao-rest.ind-requisita-autenticacao` = Sim. |
| `RestConnector` | `resolveAuthorizationKey`, `executeTokenRequest`, `applyAuthentication`. |
| `TokenProviderFactory` / `ITokenProvider` | Instancia `classe-parser-token` por `dynamic-new`. |
| `ConexaoRestAutenticacaoService` (extensão thl) | API REST de manutenção. |
