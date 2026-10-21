---
tipo: adr
modulo: cadastros
status: aceita
updated: 2026-10-02
camada: ambos
tags: [adr, cadastros]
---

# ADR — API REST dos cadastros THL (piloto: thl0001 Ambiente e thl0002 Parâmetro)

> ⚠️ **2026-10-04 — Message → Processor → Service.** A §6 (uma Message por agregado, filho com rota própria) foi substituída por [inbound-message-processor-service.md](inbound-message-processor-service.md): um objeto por agregado, filho como operação da URL (`pai/filho`), Message padrão e Processor por agregado. Contrato JSON, filtros e regras dos Services não mudaram.

> **Aceita e aplicada (piloto) em 2026-09-25** — fontes em [extensions/thl.md](../extensions/thl.md), ainda não compilados; o thl0001-v01 ganhou o bloqueio de eliminação (DECIDIR 3). Atualizada em 2026-09-25 com as decisões do responsável: THL como sistema em `thl-extensions`, códigos de erro 2/17006, mensagens sempre armazenadas, chave do `MessageConfigLoader`, **sem alterar o `InboundRouteResolver`** (rotas por cadastro), **padrão `LpcoMessage`/`LpcoService`** (sem classe-base) e **sem autorização por usuário**. Levantamento por leitura de `Fontes\thl\integration\api\v1\resourcen.p`, `thl-lib.integration.messaging.inbound.*`, `thl-lib.erp.core.Service`, `Database\thl.df`, das telas thl0001/thl0002 e dos exemplos do Automatizador.
>
> Contexto: [thl/camada-datasul.md](../thl/camada-datasul.md) · regras das telas: [convencoes.md §7](../convencoes.md) · camadas: [arquitetura.md](../arquitetura.md) · modelo: [extensions/automatizador.md](../extensions/automatizador.md) · renumeração: [renumeracao-cadastros-depara.md](renumeracao-cadastros-depara.md).

## 1. Contexto

Os cadastros THL só existem como telas ADM1 (`.w`). Para ter telas PO UI (skill `thl-poui-design`) e automação, eles precisam de API REST com GET, POST, PATCH e DELETE. O `resourcen.p` já recebe esses verbos e despacha para uma `InboundMessage` resolvida por `thl-inbound-rota` → `thl-objeto.classe-objeto` (`dynamic-new`).

## 2. Decisões

### 2.1 Localização — o THL tratado como sistema externo `thl`

A regra "um sistema externo por pasta" vale com o **sistema `thl`** (aplicação `THL` nos cadastros de objeto e rota).

```text
Fontes\thl-extensions\erp\thl\service\                            Services (regra + acesso aos dados)
Fontes\thl-extensions\integration\thl\messaging\inbound\message\   InboundMessages (contrato HTTP)
```

Pacotes em minúsculas, iguais à pasta: `thl-extensions.erp.thl.service.AmbienteService`, `thl-extensions.integration.thl.messaging.inbound.message.AmbienteMessage`.

### 2.2 Escopo do piloto

| Tela | Tabela | Recurso | Verbos |
|---|---|---|---|
| thl0001 | `thl-ambiente` | Ambiente | GET, POST, PATCH, DELETE |
| thl0002 | `thl-ambiente-param` | Parâmetro | GET, POST, PATCH, DELETE |
| thl0002b | `thl-ambiente-param-variavel` | Variável do parâmetro | GET, POST, PATCH, DELETE |
| thl0002c | `thl-ambiente-param-prog` | Programa do parâmetro | GET, POST, DELETE (registro só tem a chave; PATCH → erro 17006 "não suportado", como a tela) |

Depois do piloto: thl0020/thl0021 (Aplicação e Objeto), depois o resto.

### 2.3 Rotas — só por cadastro (`thl-inbound-rota`), sem mudar o roteador

> **Superado em parte (2026-10-06 a 08):** a tabela é hoje `thl-objeto-rota` (uma rota por objeto, chave aplicação + objeto), os filhos são operações da URL do pai e a própria rota virou a operação `rota` do objeto `Objeto`. O desenho abaixo é o histórico; o vigente está em [operacao-acao-extensao-rest.md](operacao-acao-extensao-rest.md) §§9 e 13.

**Decidido (2026-09-25):** o `InboundRouteResolver` **não** é alterado; cada recurso ganha um registro em `thl-inbound-rota` apontando para a aplicação `THL`.

Como o roteador atual lê o caminho (`thl-lib.integration.messaging.inbound.route.InboundRouteResolver`):

- **1 segmento** → é a rota (`rota-publica`);
- **2 ou mais** → o **último é a operação** (`thl-objeto-parametro.operacao`) e o resto é a rota;
- a rota é procurada em `thl-inbound-rota` (ativa); sem cadastro, o objeto vira o próprio caminho com aplicação `TOTVS`.

Consequência: a URL `…/resourcen/thl/ambiente` é lida como **rota `thl` + operação `ambiente`**, e uma rota liga a **um** objeto só. Sem mudar o roteador, a aplicação `THL` fica no cadastro da rota, não no caminho. Proposta:

| URL | `thl-inbound-rota.rota-publica` | Aplicação / Objeto | Classe (`thl-objeto.classe-objeto`) |
|---|---|---|---|
| `/resourcen/ambiente` | `ambiente` | THL / AMBIENTE | `thl-extensions.integration.thl.messaging.inbound.message.AmbienteMessage` |
| `/resourcen/parametro-ambiente` | `parametro-ambiente` | THL / PARAMETRO | `…message.ParametroAmbienteMessage` |
| `/resourcen/parametro-variavel` | `parametro-variavel` | THL / PARAMETRO-VARIAVEL | `…message.ParametroVariavelMessage` |
| `/resourcen/parametro-programa` | `parametro-programa` | THL / PARAMETRO-PROGRAMA | `…message.ParametroProgramaMessage` |

Base: `${window.location.origin}/api/thl/integration/v1/resourcen/<rota>` — mesmo formato das rotas do monitor (`mensageria`, `email`, `auditoria`). Um segundo segmento, quando houver, é a operação (`/resourcen/ambiente/<operação>`), como em `mensageria/conteudo`.

- **DECIDIR 1:** manter `thl` no caminho não é possível sem mudar o roteador (a única forma seria rota `thl` → um objeto `CADASTRO` com o recurso como operação, uma classe só para os quatro). Proposto: rotas de um segmento acima. Se houver risco de colisão de nome com rotas de outros sistemas, usar prefixo no nome (`thlAmbiente`, `thlParametro`, …).

**Chaves:** GET por query string (`?codAmbiente=PRD`, filtros e `page`/`pageSize` do `PaginationHelper`); POST/PATCH/DELETE pelo corpo JSON — o `dispatchInbound` exige payload também no DELETE.

### 2.4 Contrato das classes — padrão `LpcoMessage` / `LpcoService`

**Decidido (2026-09-25):** seguir o modelo canônico do Automatizador (`thl-extensions.integration.automatizador.messaging.inbound.message.LpcoMessage` e `thl-extensions.erp.automatizador.service.LpcoService`). **Sem classe-base de cadastro** — cada recurso tem seu Service. **Revisto em 2026-10-02 (§6):** a Message passa a ser uma por agregado (pai + filhos).

**Service** (`inherits thl-lib.erp.core.Service`, um buffer nomeado da tabela):

- `initialize()` → `positionRecord()`: `find first b-<tabela> exclusive-lock` pela chave do `inContext`, `no-error`;
- `create()`: erro se o registro já existe; validações; `do transaction` + `create` + chave + `mapFields( jsonSetter )`;
- `update()`: erro se não existe; `mapFields( jsonSetter )` — **nunca grava a chave** (paridade com "chave só na inclusão");
- `delete()`: erro se não existe; bloqueios por referência (outra tabela que usa o registro); filhos subordinados eliminados em cascata, na mesma `do transaction` do pai (desde 2026-10-08); `delete`;
- `get( pager, filtros… )` público: `for each … no-lock` com `pager:incrementPageCount()` / `shouldSkipEntry()` / `shouldStopPaging()`, monta `JsonArray` com `referenceCode`;
- `mapFields( jsonSetter )` privado: `jsonSetter:SetValue( input-output b-x.campo, input 'campoJson' )` só dos campos não-chave;
- `loadReferenceCode()`: lê do **buffer posicionado** (serve à escrita e ao GET); `getEntityName()`: nome do recurso.

**Message** (`inherits InboundMessage`, construtor padrão de 7 parâmetros):

- `createService()` → `new <Recurso>Service()`;
- POST/PATCH/DELETE pelos defaults de `InboundMessage` (`executeService`);
- `methodGet()`: `cast( createService(), <Recurso>Service ):get( createPagination( 100 ), filtros de context:getQueryParam… )` + `appendItems()` (um `appendItem()` por linha, com `referenceCode`);
- `getRequiredFields()` por método: PATCH/PUT/DELETE e POST → campos da chave;
- `getExternalReferenceField()` → `''` (não há referência externa).

**Erros** (§2.6): `ThlError` — construtor de 3 parâmetros já sai com **17006**; o de 4 parâmetros recebe o código (**2** para pai/relacionado inexistente).

### 2.5 Contrato JSON (camelCase, sem prefixo de tipo)

| Recurso | Campos (chave em **negrito**) |
|---|---|
| Ambiente | **`codAmbiente`**, `nomeAmbiente`, `ip` |
| Parâmetro | **`codParametro`**, `descricao` |
| Variável | **`codParametro`**, **`codAmbiente`** (`*` = todos), **`codVariavel`**, `descricao`, `valor` |
| Programa | **`codParametro`**, **`codPrograma`** |

GET devolve array (`JsonAPIResponseBuilder:ok( JsonArray, false )`), cada item com `referenceCode`; POST/PATCH/DELETE devolvem o `ServiceResponse:success( entidade, ação, referência )`.

### 2.6 Regras — paridade com as telas

**Decidido (2026-09-25): a API usa os mesmos códigos de mensagem das telas** — registro pai/relacionado inexistente → **2**; demais validações (obrigatório, duplicado, domínio, eliminação com vínculo, verbo não suportado) → **17006**. O código segue no erro devolvido pelo `resourcen.p` (`RowErrors.ErrorNumber`).

| Recurso | POST | PATCH | DELETE |
|---|---|---|---|
| Ambiente | `codAmbiente` obrigatório e único; `ip` único (`idx-ip`) | `ip` único | bloqueia se houver variável com o ambiente (**a tela thl0001 hoje não bloqueia** — DECIDIR 3) |
| Parâmetro | `codParametro` obrigatório e único | — | bloqueia se houver variáveis ou programas (igual ao `local-delete-record` do thl0002) |
| Variável | parâmetro existe (2); ambiente existe ou `*` (2); `codVariavel` obrigatório; chave única | — | — |
| Programa | parâmetro existe (2); `codPrograma` obrigatório; chave única | não suportado (17006) | — |

- **DECIDIR 3:** incluir o mesmo bloqueio de eliminação no thl0001-v01 (tela), para as duas pontas ficarem iguais.
- **DECIDIR 4:** onde fica a regra. Proposto: no Service. Em uma segunda etapa, o `Pi-validate` das telas pode chamar o mesmo Service (OE12 permite `new` em `.w`), eliminando a duplicação.

### 2.7 Segurança

`thl-ambiente-param-variavel.valor-variavel` guarda URL, usuário e **também senha, token e client secret**. O `ip` identifica servidores.

1. **Mascarar no GET** os valores sensíveis (`"********"`). Proposta para o piloto: por nome da variável (`SENHA`, `PASSWORD`, `SECRET`, `TOKEN`, `KEY`, `CHAVE`). Alternativa definitiva: campo `ind-sensivel` na tabela (mudança no `.df`, feita pelo responsável no Data Dictionary).
2. **PATCH aceita gravar** o valor sensível; se vier `"********"`, mantém o valor atual.
3. **Conteúdo gravado na mensageria:** o `InboundMessageService:accept` grava o **payload recebido** antes de processar. **Decidido: o THL sempre armazena as mensagens** (o `ind-persistente` não é para isso), então a `ParametroVariavelMessage` sobrescreve `saveContentByType( typeContent, content )` (público em `thl-lib.integration.messaging.core.Message`), troca o `valor` das variáveis sensíveis por `"********"` e chama `super`. Vale para entrada e saída. Sem mudança na `thl-lib`.
4. **Autorização:** fora do escopo (decisão do responsável) — vale a autenticação do PASOE/Datasul aplicada ao `resourcen.p`.
5. **Auditoria:** registrar as quatro tabelas em `thl-audit-tabela` (thl0050/thl0051) para ter o histórico de quem alterou.
6. Exemplos e documentação sem IP, host ou senha reais.

### 2.8 Volume na mensageria

Cada chamada — inclusive GET — gera `thl-mensagem` + conteúdo (**o THL sempre armazena**). Uma tela PO UI faz muitos GETs: incluir a aplicação `THL` na rotina de expurgo de mensagens (thl0222) com retenção curta e manter o `pageSize` padrão do GET moderado (100, como o LPCO).

### 2.9 Cadastros necessários (carga)

O próprio framework configura a API dele. Script de carga `Utils\scripts\carga-thl-api-cadastros.p` (simulação por padrão, como o `carga-thl-aplicacao.p`):

- `thl-aplicacao` `THL`;
- 4 `thl-objeto` (THL/AMBIENTE, PARAMETRO, PARAMETRO-VARIAVEL, PARAMETRO-PROGRAMA) com `classe-objeto` = nome completo da Message;
- `thl-objeto-parametro` de cada objeto — o `MessageConfigLoader:load( aplicação, objeto, método, operação )` localiza pela **chave primária dos objetos** (`thl-objeto`: `aplicacao` + `objeto`; `thl-objeto-parametro`: `cod-estabel` + `aplicacao` + `objeto` + `operacao`);
- 4 `thl-inbound-rota` com as rotas do §2.3, aplicação `THL`, ativas.

Mover ou renomear as classes exige atualizar `thl-objeto.classe-objeto`.

## 3. Arquivos previstos

```text
Fontes\thl-extensions\erp\thl\service\AmbienteService.cls
Fontes\thl-extensions\erp\thl\service\ParametroAmbienteService.cls
Fontes\thl-extensions\erp\thl\service\ParametroVariavelService.cls
Fontes\thl-extensions\erp\thl\service\ParametroProgramaService.cls
Fontes\thl-extensions\integration\thl\messaging\inbound\message\AmbienteMessage.cls
Fontes\thl-extensions\integration\thl\messaging\inbound\message\ParametroAmbienteMessage.cls
Fontes\thl-extensions\integration\thl\messaging\inbound\message\ParametroVariavelMessage.cls
Fontes\thl-extensions\integration\thl\messaging\inbound\message\ParametroProgramaMessage.cls
Utils\scripts\carga-thl-api-cadastros.p
Documentos\.claude\extensions\thl.md                (nota do sistema thl)
```

Todos em ISO-8859-1 com CRLF. Compilação no PDSOE (PROPATH do Shared AVM) ou `Utils\scripts\compilar-thl.p`. Nenhuma alteração em `thl-lib` nem no `resourcen.p`.

## 4. Consequências

- **A favor:** habilita telas PO UI e automação dos cadastros; reaproveita roteamento, tratamento de erro, paginação e o modelo já usado no Automatizador; fica isolado em `thl-extensions\…\thl`; `thl-lib` intacta.
- **Contra / riscos:** regra duplicada tela × API até o DECIDIR 4; código repetido entre os quatro Services (sem classe-base — aceito para seguir o modelo); exposição de segredos se §2.7 não for feito antes de publicar; configuração circular (um erro no cadastro do objeto derruba a própria API — a tela `.w` fica como caminho de recuperação); PATCH sem controle de concorrência ("último grava vence").
- **Fora do escopo:** telas PO UI (vêm depois, com `thl-poui-design`); autorização por usuário.

## 5. Pontos em aberto

| # | Tipo | Ponto | Proposta / decisão |
|---|---|---|---|
| 1 | ✅ Decidido | Nome das rotas (sem `thl/` no caminho, porque o roteador não muda) | `ambiente`, `parametro-ambiente`, `parametro-variavel`, `parametro-programa` — revisto em 2026-10-01 (antes `parametro`, `parametroVariavel`, `parametroPrograma`); onde a carga já rodou com os nomes antigos, ajustar `thl-inbound-rota.rota-publica` |
| 2 | ✅ Decidido | Classe-base | Não; padrão `LpcoMessage`/`LpcoService` |
| 3 | ✅ Decidido | Bloqueio de eliminação do ambiente também no thl0001 | Sim — aplicado no thl0001-v01 |
| 4 | ✅ Decidido | Regra única tela × API | Service agora; `.w` chamando o Service depois (2ª etapa) |
| 5 | ✅ Decidido | Payload com segredo na mensageria | THL sempre armazena → mascarar em `saveContentByType` |
| 6 | ✅ Removido | Autorização por usuário | Fora do escopo |
| 7 | ✅ Decidido | GET grava mensagem? | Sim, sempre |
| 8 | ✅ Decidido | Códigos de erro | 2 (pai/relacionado) e 17006 (demais) |
| 9 | ✅ Decidido | `InboundRouteResolver` | Não muda; rotas por cadastro em `thl-inbound-rota` |
| 10 | ✅ Confirmado | Chave do `MessageConfigLoader:load` | PK dos objetos (`thl-objeto`, `thl-objeto-parametro`) |
| 11 | ✅ Decidido (2026-10-02) | Granularidade da Message | Uma por agregado; Service por tabela; escolha pela rota — §6 |

## 6. Revisão de 2026-10-02 — uma Message por agregado

**Decisão do responsável:** unificar a Message do cadastro pai com a dos filhos e manter um Service por tabela. Aplicado nos cinco agregados (Parâmetro, Objeto, Conexão REST, Auditoria, Grupo de e-mail); fontes **não compilados**. Detalhe em [extensions/thl.md](../extensions/thl.md).

**Por quê (OO):**
- No framework a Message representa o **objeto** (`thl-objeto`), não a tabela. Um filho que não existe sem o pai faz parte do mesmo objeto.
- `InboundMessage:createService()` é um Factory Method; com uma Message por tabela ele devolvia sempre o mesmo Service. `NotaFiscalMessage` (por rota) e `MensageriaMessage` (por operação) já o usavam para escolher.
- Cada camada na sua granularidade: a Message cuida do contrato HTTP do agregado; o Service, da regra e da gravação de uma tabela.
- Eliminava 11 classes quase idênticas (cerca de 30 linhas diferentes entre uma e outra).

**Como a Message escolhe o Service — pela rota, não pela operação:**
- Proposta inicial: URL `pai/filho`, com o filho como operação. **Descartada:** com operação na URL o `MessageConfigLoader` procura `thl-objeto-parametro` por método e operação, e a chave primária da tabela (`cod-estabel`, `aplicacao`, `objeto`, `operacao`) não inclui o método — caberia um verbo por filho.
- Adotado: cada filho mantém a **própria rota pública** (`parametro-variavel`, `objeto-usuario`, …), cadastrada em `thl-inbound-rota` apontando para o **objeto do pai**; a Message faz `case context:routePath`. É o mecanismo da `NotaFiscalMessage`.
- Consequência: URLs, contrato JSON, app web e coleção Postman **não mudam**; `thl-lib`, `.df` e `resourcen.p` também não.

**Regra para classificar:** vira rota da Message do pai o cadastro cuja chave começa pela chave do pai e que não existe sem ele. `ConexaoRestPath` (não pertence a uma conexão), Ambiente, Aplicação, Rota inbound e Parâmetro de e-mail seguem com Message própria.

**Custos aceitos:**
- Três `case` por rota em cada Message unificada (`createService`, `methodGet`, `getRequiredFields`) — seleção por rota em vez de polimorfismo; eliminar exigiria levar `get` e os campos obrigatórios para o contrato público de `Service`.
- Incluir um filho edita a Message do pai.
- O nome das rotas fica escrito na classe, além de em `thl-inbound-rota`.
- `thl-objeto-usuario` e o monitor de mensageria passam a enxergar o agregado, não cada filho.
- A Message depende dos Services dos filhos na compilação (`usuar_mestre`/`estabelec` em Objeto, Auditoria e Grupo de e-mail).

**Condições de qualidade:** rota desconhecida lança erro (nunca cai no Service do pai); a máscara de segredo não depende da rota, porque o conteúdo de entrada é gravado antes de o contexto existir; teste por rota × verbo antes de publicar.

**Implantação:** compilar e publicar as cinco Messages → apontar as rotas dos filhos para o objeto do pai (`carga-thl-api-cadastros.p` ou `cadastrar-thl-api-rotas.ps1`) → eliminar os objetos próprios dos filhos e os `.r` das 11 classes retiradas.

**Complemento de 2026-10-03 — chave validada só no Service:** as Messages de cadastro deixaram de sobrescrever `getRequiredFields()`; cada Service confere a presença dos campos da chave em `initialize()` (`JsonUtil:requireProperties`). Com isso, nas Messages de agregado restam dois `case` por rota (`createService` e `methodGet`). Substitui o item de §2.4 "`getRequiredFields()` por método: campos da chave".
