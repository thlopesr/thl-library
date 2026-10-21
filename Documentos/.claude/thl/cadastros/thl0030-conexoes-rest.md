---
tipo: guia
camada: ambos
status: referencia
programa: thl0030
titulo: Conexões REST
grupo: thl003 Conexão REST
tabela: thl-conexao-rest
tags: [thl, cadastro, thl003]
updated: 2026-10-19
---

# thl0030 — Conexões REST

## Objetivo da tela

Cadastra a **conexão com uma API externa**: o código que as integrações de saída usam para achar o servidor, a **URL base** e dois indicadores que ligam as configurações complementares de autenticação ([thl0032 Autenticação da conexão](thl0032-autenticacao-conexao.md)) e de cabeçalho calculado ([thl0033 Header provider da conexão](thl0033-header-provider-conexao.md)). O caminho do endpoint **não** fica aqui: é o cadastro [thl0031 Paths da conexão](thl0031-paths-conexao.md).

Estrutura: `thl0030.w` (SmartWindow `w-cadsim`) + `thl0030-v01.w` (viewer), `-q01.w` (query), `-b01.w` (browse, filtro por faixa de `cod-conexao`), `-z01.w` (zoom) e `-g01.w` (Vá para).

## Relacionamentos

| Relação | Detalhe |
|---|---|
| Filhos 1:1 | [thl0032 Autenticação da conexão](thl0032-autenticacao-conexao.md) e [thl0033 Header provider da conexão](thl0033-header-provider-conexao.md), ambos com `cod-conexao` como chave primária (mesmo valor do pai). O vínculo é só por código — não há `fk-*` no `.df`. |
| Independente | [thl0031 Paths da conexão](thl0031-paths-conexao.md) **não** é filho da conexão: `thl-conexao-rest-path` não tem `cod-conexao`. O par conexão + path é montado em runtime pelas variáveis de ambiente. |
| Quem aponta para cá | `thl-ambiente-param-variavel.valor-variavel` (thl0002b), cujo nome da variável vem de `thl-objeto-parametro.cod-param-ambiente` (thl0022a). É um vínculo de **valor**, sem integridade no banco. |
| Zoom de entrada | `thl0030-z01.w` é o zoom usado por `cod-conexao` no thl0032 e no thl0033 (F5 / duplo clique). |
| **Eliminação** | `local-delete-record` elimina junto a autenticação e o cabeçalho da conexão, na mesma transação (erro em qualquer passo desfaz tudo). **Nada bloqueia** a eliminação de uma conexão ainda referenciada por variável de ambiente — ⚠ a confirmar se isso é aceito (não há `can-find` na tela). |

## Dicionário de campos

Código `thl0030-v01.w` + dicionário `thl.df`. Rótulo = o que a tela exibe (a viewer usa o rótulo do dicionário, exceto onde o frame define o próprio).

| Label na tela | Campo físico | Tipo / formato | Obrig. | Chave / único | Valores / origem | Validação e mensagem | O que faz |
|---|---|---|---|---|---|---|---|
| Conexão REST | `thl-conexao-rest.cod-conexao` | character `x(40)` | S | S — `pk-conexao-rest` (primário, único). Só editável na **inclusão** | Texto livre. É o **valor** gravado na variável de ambiente (thl0002b) | Vazio → **17006** "Conexao nao informada~~Informe o codigo da conexao REST." · Já existe → **17006** "Conexao ja cadastrada~~Informe outro codigo." | Identifica a conexão. `ConnectorConfig` obtém o código pela variável de ambiente do objeto e busca a conexão por ele; o mesmo código é a chave da autenticação e do cabeçalho. Conexão inexistente → erro "Codigo de conexao REST nao encontrada". |
| Descrição | `.des-conexao` | character `x(100)` | N (o comentário da tela prevê obrigatória, mas **não está codificado**) | N | Texto livre | Nenhuma | Só informativo: nenhuma classe do pipeline de conexão (`ConnectorConfig`, `RestConnector`) lê este campo. |
| URL Base | `.url-base` | character `x(500)` | S | N | URL da API (ex.: `https://api.exemplo.com`) | Vazio → **17006** "URL base nao informada~~Informe a URL base da API (ex.: https://api.exemplo.com)." O comentário prevê exigir `http://`/`https://`, mas **não está codificado** | Prefixo da URL chamada. URL final = `url-base` + `path` do thl0031 (com os marcadores substituídos pelos `pathParameters` da mensagem) + `parameters` do path (`RestConnector:buildRequestUrl`). |
| Requisita Autenticacao | `.ind-requisita-autenticacao` | logical `Sim/Nao`, inicial **Nao** | N | N | Toggle (o rótulo é fixado no frame, sem acento) | Nenhuma — a tela **não confere** se existe registro no thl0032 | `ConnectorConfig`: **Sim** → cria `AuthenticationConfig(cod-conexao)`, que **lança erro** se não houver registro no thl0032 ("Conexao autenticacao REST nao encontrada"); **Não** → conexão sem autenticação (`'No Auth'`). |
| Requer Cabeçalho | `.ind-requisita-header` | logical `Sim/Nao`, inicial **Nao** | N | N | Toggle (rótulo do dicionário) | Nenhuma — a tela **não confere** se existe registro no thl0033 | `ConnectorConfig`: **Sim** → lê o thl0033 e **lança erro** se não existir ("Configuracao de header nao encontrada para conexao"); guarda classe e parâmetros para calcular cabeçalhos a cada requisição. |

## Regras e mensagens

- **Inclusão**: `Pi-validate` roda em `local-assign-record`; valida a chave só com `adm-new-record`. Validação de dicionário (`i-vldfrm.i`) não tem efeito aqui: **nenhum campo é `MANDATORY` no `.df`**.
- **17006** = validação própria (texto no formato "Título~~Ajuda"). Não há uso da mensagem **2** nesta tela (não há campo que aponte para outra tabela).
- **Eliminação** em cascata (autenticação + cabeçalho): ver Relacionamentos.
- **Mesmas regras na API REST** dos cadastros: `ConexaoRestService` (`create`/`update`/`delete`), que cita o `Pi-validate` e o `local-delete-record` desta tela como origem.
- ⚠ a confirmar: a tela não impede ligar `Requisita Autenticacao`/`Requer Cabeçalho` sem cadastrar o complemento; o erro só aparece em **runtime**, na primeira chamada que usar a conexão.

## Uso em runtime

| Classe | Uso |
|---|---|
| `thl-lib.integration.connectors.core.ConnectorConfig` | Lê `url-base`, `ind-requisita-autenticacao`, `ind-requisita-header` pelo `cod-conexao` obtido da variável de ambiente (`EnvironmentResource:getEnvironmentVariable( parameterCode )`). |
| `thl-lib.integration.messaging.outbound.service.MessageExecutionService` | Cria o `ConnectorConfig('APLICACAO.OBJETO', parameterCode, routeParameterCode)` em cada envio online. |
| `thl-lib.integration.connectors.types.RestConnector` | Monta a URL (`url-base` + path) e executa. |
| `thl-extensions.erp.thl.service.ConexaoRestService` / `ConexaoRestMessage` | API REST de manutenção do cadastro (web e Postman). |

Fluxo completo: [fluxo-saida](../../fluxos/fluxo-saida.md) e [fluxo-ambiente](../../fluxos/fluxo-ambiente.md).
