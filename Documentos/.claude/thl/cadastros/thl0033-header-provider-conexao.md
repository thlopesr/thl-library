---
tipo: guia
camada: ambos
status: referencia
programa: thl0033
titulo: Header provider da conexão
grupo: thl003 Conexão REST
tabela: thl-conexao-rest-header
tags: [thl, cadastro, thl003]
updated: 2026-10-19
---

# thl0033 — Header provider da conexão

## Objetivo da tela

Informa a **classe que calcula cabeçalhos HTTP** de uma conexão ([thl0030 Conexões REST](thl0030-conexoes-rest.md)) marcada com *Requer Cabeçalho* — por exemplo, uma assinatura HMAC do corpo da requisição — e os parâmetros repassados a essa classe. Uma única configuração por conexão.

Estrutura: `thl0033.w` + `thl0033-v01.w`, `-q01.w`, `-b01.w` (filtro por faixa de conexão), `-z01.w` e `-g01.w` próprios (como no thl0032).

## Relacionamentos

| Relação | Detalhe |
|---|---|
| Pai | [thl0030 Conexões REST](thl0030-conexoes-rest.md) — 1:1 por `cod-conexao`. Zoom no campo: F5 / duplo clique → `thl/thl0030-z01.w`. |
| Irmão | [thl0032 Autenticação da conexão](thl0032-autenticacao-conexao.md): independentes entre si; a conexão pode ter uma, outra, as duas ou nenhuma. |
| **Eliminação** | Sem `local-delete-record`: elimina direto, sem bloqueio. Eliminar a conexão (thl0030) elimina este registro junto. |
| Classe | `classe-parser` é carregada por `dynamic-new` — **mover/renomear a classe exige atualizar este cadastro**. |

## Dicionário de campos

| Label na tela | Campo físico | Tipo / formato | Obrig. | Chave / único | Valores / origem | Validação e mensagem | O que faz |
|---|---|---|---|---|---|---|---|
| Conexao REST | `thl-conexao-rest-header.cod-conexao` | character `x(40)` | S | S — `pk-conexao-rest` (primário, único). Só na inclusão | Zoom do thl0030 (F5 / duplo clique) | Conexão inexistente → mensagem **2** (nome da tabela via `ut-table.i`) · já tem cabeçalho → **17006** "Cabecalho ja cadastrado para a conexao~~Cada conexao tem uma unica configuracao; altere a existente." | Liga a configuração à conexão; `ConnectorConfig` a busca por este código. |
| Parâmetros | `.parameters` | character `x(4000)` | N | N | Texto livre (o dicionário diz JSON; **não é validado**) | Nenhuma | Repassado como está ao segundo argumento de `IHeaderProvider:getHeaders( body, parameters )`. O significado depende da classe — no `HeaderProvider` do GestaoEPI é o **segredo HMAC**, e vazio gera erro. |
| Classe Cabeçalho (coluna do browse: "Classe Parser") | `.classe-parser` | character `x(400)` | S (validada na tela, não no dicionário) | N | Nome completo (pacote) de classe `IHeaderProvider`, ex.: `thl-extensions.integration.gestaoepi.connectors.headers.HeaderProvider` | Vazio → **17006** "Classe nao informada~~Informe o nome completo da classe que implementa IHeaderProvider." · a existência/implementação da classe **não** é conferida | Em cada requisição, `HeaderProviderFactory` instancia a classe por `dynamic-new`; os pares `key`/`value` devolvidos entram em `request:Headers`, depois dos cabeçalhos fixos do path e da autenticação. |

## Regras e mensagens

- Validações da tela: na **inclusão**, conexão existente (**2**) e ainda sem cabeçalho (**17006**); em **toda gravação**, classe preenchida (**17006**).
- Cabeçalho calculado só roda se `thl-conexao-rest.ind-requisita-header` = Sim no thl0030. O inverso falha: *Requer Cabeçalho* = Sim **sem** registro aqui → erro de runtime "Configuracao de header nao encontrada para conexao".
- Classe inexistente, que não implemente `IHeaderProvider` ou que não possa ser instanciada só falha em runtime ("Nao foi possivel instanciar o provider de header").
- ⚠ Comentários do código citam campos inexistentes (`thl-conexao-rest-header.valor-parametro`, em mensagem de erro e cabeçalho do `HeaderProvider`; `thl-conexao-rest.classe-header-provider`, em `HeaderProviderFactory`). O campo real é `parameters`.
- O bloco de comentário da `Pi-validate` desta tela cita "THL0031" e regras de path (texto copiado); não vale aqui.

## Uso em runtime

| Classe | Uso |
|---|---|
| `ConnectorConfig` | Lê `classe-parser` e `parameters` quando `ind-requisita-header` = Sim; marca `requiresHeaderProvider`. |
| `RestConnector:applyCalculatedHeaders` | Chama `HeaderProviderFactory:getProvider( classe )` e `provider:getHeaders( corpo, parâmetros )`. |
| `HeaderProviderFactory` / `IHeaderProvider` | Instanciação dinâmica e contrato. |
| `thl-extensions…gestaoepi.connectors.headers.HeaderProvider` | Implementação existente: assinatura HMAC-SHA256 (`X-Datasul-Timestamp`, `X-Datasul-Signature`). |
| `ConexaoRestHeaderService` (extensão thl) | API REST de manutenção. |
