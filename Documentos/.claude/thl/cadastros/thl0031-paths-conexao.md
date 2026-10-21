---
tipo: guia
camada: ambos
status: referencia
programa: thl0031
titulo: Paths da conexão
grupo: thl003 Conexão REST
tabela: thl-conexao-rest-path
notion: https://www.notion.so/3f1d3a2b481581a2a22fd855e9cbac07
tags: [thl, cadastro, thl003]
updated: 2026-10-19
---

# thl0031 — Paths da conexão

## Objetivo da tela

Cadastra **endpoints reutilizáveis**: o caminho relativo à URL base, mais Content-Type, Accept, timeout, parâmetros e cabeçalhos fixos. Uma integração de saída escolhe o endpoint pelo **código do path** (`cod-path`), guardado numa variável de ambiente, e o combina com a conexão ([thl0030 Conexões REST](thl0030-conexoes-rest.md)).

Estrutura: `thl0031.w` + `thl0031-v01.w` (viewer), `-q01.w`, `-b01.w` (filtro por faixa de `cod-path`), `-z01.w`, `-g01.w`.

## Relacionamentos

| Relação | Detalhe |
|---|---|
| Conexão | **Nenhum vínculo no banco**: `thl-conexao-rest-path` não tem `cod-conexao`. O mesmo path serve a qualquer conexão; quem une os dois é o objeto de integração, por duas variáveis de ambiente (`cod-param-ambiente` → conexão, `cod-param-ambiente-destino` → path — thl0022a/thl0002b). |
| Quem aponta para cá | `thl-ambiente-param-variavel.valor-variavel` (vínculo de **valor**, sem integridade). |
| **Eliminação** | Não há `local-delete-record`: elimina direto, **sem bloqueio nem cascata**. Path ainda citado por variável de ambiente passa a falhar em runtime ("Conexao REST PATH nao encontrada"). ⚠ a confirmar se é o comportamento desejado. |

## Dicionário de campos

| Label na tela | Campo físico | Tipo / formato | Obrig. | Chave / único | Valores / origem | Validação e mensagem | O que faz |
|---|---|---|---|---|---|---|---|
| Código Endpoint | `thl-conexao-rest-path.cod-path` | character `x(40)` | S | S — `pk-path` (primário, único). Só editável na inclusão | Texto livre; é o **valor** da variável de ambiente de destino | Vazio → **17006** "Path nao informado~~Informe o codigo do path REST." · Já existe → **17006** "Path ja cadastrado~~Informe outro codigo." | Identifica o endpoint. `ConnectorConfig` busca o path por este código (`find first … where cod-path = pathCode`). |
| Descrição | `.des-path` | character `x(100)` | N (comentário prevê obrigatório; **não codificado**) | N | Texto livre | Nenhuma | Só informativo; não é lido pelo conector. |
| Path | `.path` | character `x(500)` | N (comentário prevê obrigatório; **não codificado**) | N | Caminho relativo (ex.: `/v1/pedidos/{id}`) | Nenhuma | Concatenado à `url-base` da conexão. Os marcadores são trocados pelos `pathParameters` da mensagem (`replace( path, nome, valor )` em `resolvePathParameters`). |
| Content-Type | `.content-type` | character `x(80)` | N | N | Tipo MIME; vazio assume `application/json` | Nenhuma | `request:ContentType` da chamada (`getContentType`). |
| Accept | `.accept` | character `x(80)` | N | N | Tipo MIME | Nenhuma | `request:Accept` da chamada. |
| Timeout (s) | `.timeout` | integer `>>>>>9`, inicial 0 | N | N | Número inteiro | Nenhuma (o comentário prevê ≥ 0; **não codificado**) | Atribuído direto a `HttpWebRequest:Timeout`. ⚠ a confirmar a unidade: o dicionário diz **segundos**, mas esse atributo do .NET é em **milissegundos**, e o código não converte; com 0 o comportamento de timeout imediato precisa ser testado. |
| Parâmetros | `.parameters` | character `x(4000)` | N | N | Texto anexado à URL | Nenhuma (JSON **não** é validado) | ⚠ Descrito no dicionário como "em JSON", mas `buildRequestUrl` **concatena o texto cru** à URL (`baseUrl + path + parameters`) — na prática é a query string (ex.: `?a=1&b=2`), com o `?` por conta de quem cadastra. |
| Cabeçalhos | `.headers` | character `x(4000)` | N | N | JSON: array `[{"key":"…","value":"…"}]` | Nenhuma — JSON inválido só falha em runtime | `setHeader` lê o array e adiciona cada par ao `request:Headers`. |

## Regras e mensagens

- Única validação codificada: **chave** (obrigatória e única), com **17006**, só em `adm-new-record`.
- O bloco de comentário da `Pi-validate` lista regras desejadas (descrição e path obrigatórios, timeout ≥ 0, JSON válido, coerência de content-type/accept) que **não foram implementadas** na tela.
- A mesma regra existe na API REST: `ConexaoRestPathService` (chave obrigatória e única; sem validar os demais campos).

## Uso em runtime

| Classe | Uso |
|---|---|
| `ConnectorConfig` (constructor) | Localiza o path pelo valor da variável de ambiente `routeParameterCode`; lê `path`, `content-type`, `accept`, `headers`, `parameters`, `timeout`. |
| `RestConnector` | `buildRequestUrl`, `resolvePathParameters`, `createHttpRequest`, `setHeader`. |
| `ConexaoRestPathService` (extensão thl) | API REST de manutenção. |
