---
tipo: adr
modulo: mensageria
status: aceita
updated: 2026-10-05
camada: ambos
tags: [adr, mensageria]
---

# ADR — Operação com ação na chave, classes por operação e extensão REST

> **Aceita em 2026-10-04** (respostas do responsável, ponto a ponto). Aplicada em `thl-lib`, no sistema `thl`, na tela `thl0022a` e nos scripts; **nada foi compilado nem testado**. Depende do delta `Database\delta-thl-2026-10-05.df`, carregado depois dos de 10-03 e 10-04.
>
> Complementa [inbound-message-processor-service.md](inbound-message-processor-service.md). Contexto: [data/schema.md](../data/schema.md) · [integration/messaging-core.md](../integration/messaging-core.md) · [integration/messaging-inbound.md](../integration/messaging-inbound.md) · [extensions/thl.md](../extensions/thl.md) · [thl/camada-datasul.md](../thl/camada-datasul.md)

## 1. Contexto

`thl-objeto-parametro` (a operação do objeto) misturava o que vale para qualquer integração com o que é só de REST (o verbo HTTP). Outros modelos estão previstos (SOAP, SQL, arquivo texto). Além disso, o que ainda mantinha Messages específicas no código era quase só contrato do payload: os campos obrigatórios (`getRequiredFields()`) e o campo da referência externa.

## 2. Decisão

| Onde | O que fica |
|---|---|
| **Objeto** (`thl-objeto`) | Modelo de integração (REST, SOAP…) e as três classes padrão: message, processor, service |
| **Operação** (`thl-objeto-parametro`) | O comum a todos os modelos: **ação neutra**, forma de execução, histórico, gravação de conteúdo, parâmetros de ambiente (conexão e destino continuam por eles) e as três classes como **sobreposição opcional** |
| **Extensão REST** (`thl-objeto-parametro-rest`, 1 para 1) | Verbo HTTP, campos obrigatórios do payload e campos da chave externa |

### 2.1 Ação neutra na chave

- `thl-objeto-parametro.acao`: 1 criar, 2 alterar, 3 eliminar, 4 consultar — os valores de `ActionEnum`. Domínio em `thl/include/i06thl011.i`.
- Chave primária: estabelecimento, aplicação, objeto, operação **e ação**.
- Conversão do verbo: POST/INSERT → criar; PUT, PATCH, UPDATE → alterar; DELETE → eliminar; GET/SELECT → consultar (`MessageConfigLoader:actionOf`).
- Na entrada, a ação vem do verbo da requisição. Linha da operação, nesta ordem (`InboundConfigLoader`): (1) operação da URL + ação; (2) operação em branco + ação; (3) operação com o nome do verbo + ação (cargas antigas); (4) primeira linha da ação. Cadastro ainda sem a ação (zero) é procurado pelo verbo gravado, na mesma ordem — a biblioteca funciona antes do acerto.

### 2.2 Classes: objeto como padrão, operação sobrepõe

`thl-objeto-parametro.classe-objeto`, `classe-processor` e `classe-service`, em branco por padrão. Preenchida, a classe da operação vale no lugar da do objeto (`MessageConfigLoader:resolveMessageClass/ProcessorClass/ServiceClass`). A validação "as três classes resolvidas" olha o resultado.

**Regra de uso:** agregado (pai + filhos) continua com o Processor do objeto; a sobreposição por operação é para exceção — uma operação que precisa de outro Service ou de uma Message de protocolo próprio. Usar as duas formas para o mesmo caso deixa o cadastro com dois caminhos.

### 2.3 Extensão REST

`thl-objeto-parametro-rest`, mesma chave da operação:

| Campo | Conteúdo |
|---|---|
| `metodo` | Verbo HTTP (`MethodTypeEnum`). É a fonte; `thl-objeto-parametro.metodo` fica como cópia de compatibilidade |
| `campos-obrigatorios` | Array JSON de texto com os campos obrigatórios do payload de entrada |
| `chave-externa` | Array JSON de texto com os campos que formam a referência externa, na ordem; os valores são unidos por `#`. `[]` desliga a referência; em branco vale o padrão da mensagem (`externalID`) |

- Criada junto com a operação quando o objeto é REST (`modelo-integracao` = 1): na tela (`thl0022a-v01`), na API (`ObjetoParametroService`) e pelo acerto.
- Operação e extensão são **um registro só** para a API: mesmo JSON, mesma transação. A extensão não é filho (não vira operação da URL).
- Sem extensão (operação antiga, objeto de outro modelo), vale o verbo da operação e não há contrato cadastrado.
- Entrada e saída usam a mesma extensão: campos obrigatórios e chave externa só fazem sentido na entrada.

### 2.4 Contrato pelo cadastro na `InboundMessage`

- `getRequiredFields()` padrão devolve os campos do cadastro (`JsonUtil:nameListToCsv`).
- `loadExternalReference()` padrão: com chave externa cadastrada, monta a referência pelos campos (chave composta só vale inteira); em branco, mantém o gancho `getExternalReferenceField()`.
- Message específica que sobrescreve continua valendo.

### 2.5 Messages específicas revistas

Com o contrato no cadastro, saíram (`.cls.old`): `DocumentoMessage`, `EmbarqueMessage`, `RequisicaoMessage`, `UsuarioMessage` (`thl-lib`), `LpcoMessage`, `FreteMessage`, `LoogAiDocumentoMessage`, `LoogAiEmbarqueMessage`, `NinahubNotaFiscalMessage`. `LpcoService` ganhou `consult()`.

Ficaram três Messages de entrada:

| Message | Motivo |
|---|---|
| `NotaFiscalMessage` | Escolhe o Service pela **rota** (`notafiscal` × `notafiscal/embarque`), que o Processor não recebe. Sai se o cadastro passar a ter dois objetos |
| `ParametroAmbienteMessage`, `ConexaoRestMessage` | Máscara de segredo no conteúdo gravado |

O contrato que cada Message tinha no código está nas regras do `acerto-thl-objeto-classes.p`, que o grava na extensão REST das operações.

## 3. Alternativas descartadas

- **Verbo HTTP na operação, com opções pelo tipo:** GET/POST/PATCH/DELETE não descreve SQL nem arquivo texto.
- **Service só na operação:** exigiria uma linha por filho × ação e tiraria a função dos Processors de agregado.
- **Lista separada por vírgula ou tabela filha** para os campos: o array JSON é ordenado, distingue "em branco" de "vazio" e não cria cadastro novo.
- **Conexão e path direto na extensão:** continuam pelo parâmetro de ambiente (decisão do responsável).
- **Tipo de integração na operação:** continua no objeto.
- **Campos novos na operação, separar depois:** a extensão já nasce separada.

## 4. Consequências

**A favor:** recebimento novo é Service + cadastro, inclusive o contrato do payload; campos obrigatórios por ação; a tabela comum fica pronta para outros modelos.

**Contra / riscos:**

- **Troca de chave primária.** O delta cria o índice novo, torna-o primário, elimina o antigo e renomeia. As linhas existentes ficam com ação zero até o acerto — a chave nova continua única porque a antiga era.
- **`find` pela chave antiga** (4 campos) deixa de ser único: os pontos do repositório usam `find first`/`can-find( first …)`. Código fora do repositório precisa de revisão.
- **Dois lugares para o verbo** durante a transição (`thl-objeto-parametro.metodo` e a extensão). A extensão vale; a coluna antiga é mantida em sincronia pela tela e pela API.
- **Objetos que apontam para Message retirada não instanciam** até o acerto trocar a classe.
- **Contrato fora do código:** um campo obrigatório errado no cadastro não é pego pelo compilador.
- **Tela:** a aba REST grava a extensão pelo `Group-Assign`; se a aba não for aberta, a extensão nasce só com a chave (o `thl0022a-v01` cria) e o verbo vale o da operação.
- **Outros modelos:** campos obrigatórios e chave externa provavelmente se repetem na extensão de SOAP.

## 5. Implantação (ordem)

1. Deltas: `2026-10-03`, `2026-10-04`, `2026-10-05`.
2. Compilar `thl-lib`, `thl-extensions` e `thl`.
3. Cargas (`carga-thl-api-cadastros.p`, `carga-thl-api-metricas.p`, `carga-thl-transporte.p`), em simulação e depois gravando.
4. `acerto-thl-objeto-classes.p`: ação das operações, extensão REST, classes dos objetos de entrada e contrato das Messages retiradas. Conferir no log "sem ação", "sem regra" e "contrato não gravado".
5. Testes; depois app web e Postman.

## 6. A testar

- Delta: carga do índice novo em base com dados.
- Entrada antes e depois do acerto (ação zero × ação preenchida).
- Operação com Service próprio sobrepondo o do objeto.
- Campo obrigatório ausente (17006) em cada objeto que perdeu a Message; ação sem campos cadastrados não valida nada.
- Chave externa: simples (`viagem`, `numeroLpco`), composta (Ninahub), desligada (`[]`, requisição) e padrão (`externalID`).
- GET do Lpco: mesma resposta de antes (`items`, `hasNext`) e paginação.
- Tela `thl0022a`: incluir operação (ação obrigatória), aba REST, classes na aba Servidor, eliminar operação (extensão sai junto).
- API `objeto/parametro`: POST sem `acao` (vem do método), PATCH/DELETE sem `acao` em operação com uma e com várias ações.
- Saída: verbo pela extensão e pela coluna antiga.

## 7. Nota fiscal: dois objetos (2026-10-05) — substituída pela §8

Decisão do responsável: nota fiscal **direta** e **por embarque** são objetos diferentes (características próprias), cada um com o seu Service — `NotaFiscalService` e `NotaFiscalPorEmbarqueService` —, Message e Processor padrão. A `NotaFiscalMessage`, que escolhia o Service pela rota, virou `.cls.old`; a chave externa (`codigoEstabelecimento`, `serie`, `numeroNotaFiscal`) foi para a extensão REST das operações. Sem rota cadastrada o roteador já separa os dois (`notafiscal` e `notafiscalembarque`). O `acerto-thl-objeto-classes.p` atribui o Service pela rota que atende cada objeto e, se as duas rotas apontarem para o mesmo, cria o objeto do embarque (`<objeto>Embarque`, com cópia de operações, extensões e usuários) e reaponta a rota. Com isso restam **duas** Messages de entrada, as de máscara de segredo (`ParametroAmbienteMessage`, `ConexaoRestMessage`); a tabela da §2.5 fica como histórico. **A testar:** `notafiscal/<etapa>` e `notafiscal/embarque/<etapa>` depois do acerto, a referência externa gravada e, se houve divisão, o objeto novo no `thl0021` e no monitor.

## 8. Início da operação na rota e nota fiscal em um objeto (2026-10-06) — substitui a §7

Decisão do responsável, revendo a §7: nota fiscal direta e por embarque têm a mesma natureza dos outros agregados (dois Services atrás de um objeto). O que impedia tratá-las assim era a URL de três níveis — `notafiscal/embarque/geracao` —, em que o roteador entregava só o último (`geracao`) e o filho (`embarque`) ficava preso na rota. O Processor **não lê rota**; a solução ficou no cadastro da rota.

**`thl-inbound-rota.inicio-operacao`** (delta `Database\delta-thl-2026-10-06.df`): segmento da URL em que começa a operação. Zero (padrão) = só o último segmento, como sempre foi. Com 2 na rota `notafiscal/embarque`, a URL `notafiscal/embarque/geracao` entrega a operação `embarque/geracao`.

| URL | Rota cadastrada | Início | Objeto | Operação | Service |
|---|---|---|---|---|---|
| `notafiscal/geracao` | `notafiscal` | 0 | `NotaFiscal` | `geracao` | `NotaFiscalService` |
| `notafiscal/embarque/geracao` | `notafiscal/embarque` | 2 | `NotaFiscal` | `embarque/geracao` | `NotaFiscalPorEmbarqueService` (recebe `geracao`) |

- `InboundRouteResolver`: depois de achar a rota, se o início for 2 ou mais, monta a operação do segmento informado até o último (`composeOperation`). Rota sem cadastro ou com zero não muda.
- `thl-lib.integration.messaging.inbound.process.NotaFiscalProcessor`: sobrescreve `execute` para separar o primeiro pedaço (`embarque`) da etapa e `resolveService` para devolver o Service por embarque; sem `embarque` vale o Service do cadastro. Os dois Services de nota fiscal não mudaram.
- Validação (tela `thl0040` e `InboundRotaService`): 0, ou entre 2 e a quantidade de segmentos da rota pública.
- Linha da operação: `embarque/geracao` + ação não precisa de cadastro próprio — sem linha, vale a em branco da ação.
- `NotaFiscalMessage` continua como `.cls.old`; a chave externa vem do cadastro.
- Acerto: objeto com a `NotaFiscalMessage` recebe `NotaFiscalProcessor` + `NotaFiscalService`, e a rota `notafiscal/embarque` que aponta para ele recebe o início 2. Cadastro que **já tem** um objeto só para o embarque (inclusive o padrão sem rota, `notafiscalembarque`) é respeitado: Processor padrão + Service por embarque. A divisão automática em dois objetos, da §7, foi retirada.

**Alternativas descartadas:** dois objetos (exceção ao desenho); nome do filho digitado na rota (repete texto da URL); operação `embarque/<etapa>` cadastrada com Service próprio (etapa esquecida cairia no Service errado sem erro); o Processor ler a rota.

**A testar:** as duas URLs de cada etapa; rota do embarque com início 0 (o Processor recebe só a etapa e usa o Service direto — por isso o acerto precisa gravar o 2); operação gravada na mensagem (`embarque/geracao`) no monitor; rotas existentes sem o campo continuam iguais.

## Delta de 2026-10-05 em dois arquivos (2026-10-06)

Pela regra de implantação de índice ([convencoes.md §6](../convencoes.md)), a troca da chave primária de `thl-objeto-parametro` ficou em arquivo próprio:

1. `delta-thl-2026-10-05.df` — campos novos, índice `pk-operacao` (único, com a ação) e a tabela `thl-objeto-parametro-rest`.
2. Ativar o índice se a carga foi online com dados (`proutil <db> -C idxactivate` ou `idxbuild`).
3. `delta-thl-2026-10-05-chave.df` — torna `pk-operacao` primário, elimina o `pk-objeto-parametro` antigo e renomeia o novo para `pk-objeto-parametro`.

Ordem completa: 10-03 → 10-04 → 10-05 → (ativação) → 10-05-chave → 10-06. Até o segundo arquivo, o código funciona com o índice sob o nome `pk-operacao`: nenhum fonte cita o nome do índice.

## 9. Rota do objeto: `thl-objeto-rota` (2026-10-06) — revê as §7 e §8

Decisão do responsável: **uma rota por objeto**. A tabela `thl-inbound-rota` dá lugar a `thl-objeto-rota` (nome em português e com o pai na frente, como `thl-objeto-parametro` e `thl-objeto-usuario`), com a chave **aplicação + objeto**.

| Campo | Papel |
|---|---|
| `aplicacao`, `objeto` | Chave (`pk-objeto-rota`), a mesma de `thl-objeto` |
| `rota-publica` | Único (`idx-rota-publica`); é por ele que o roteador procura |
| `ind-ativo` | Liga e desliga a rota sem inativar o objeto |
| `inicio-operacao` | Rota de três níveis; 0 no caso normal |

- Saíram o **código da rota** (era montado de objeto + aplicação) e a **descrição** (repetia o objeto e a aplicação).
- Definição: tabela `thl-objeto-rota` (dump-name `thl021`) no `Database\Definition\thl.df` (08/10/2026); o arquivo separado `thl-objeto-rota.df` deixou de existir. A migração dos dados de `thl-inbound-rota` fica com o responsável.
- Tela `thl0040` (viewer, browse, vá-para e query), `InboundRotaService`, `InboundRouteResolver`, cargas, PowerShell e acerto usam a tabela nova.
- **Consequência para a nota fiscal:** com uma rota por objeto, duas rotas no mesmo objeto deixam de existir. Nota fiscal direta e por embarque são objetos diferentes, cada um com o Processor padrão e o seu Service — o que a base do responsável já tinha (`NotaFiscalPorEmbarque`). O `NotaFiscalProcessor` (§8) ficou **sem uso**; o arquivo continua no projeto até decisão de retirá-lo. O campo `inicio-operacao` segue disponível para uma rota única de três níveis.
- API `inbound-rota`: a chave passou de `rota` para `aplicacao` + `objeto`; saíram `rota` e `descricao`; o GET filtra por `aplicacaoIni/Fin` e `objetoIni/Fin`; `referenceCode` = aplicação#objeto.

**A testar:** tela `thl0040` (incluir com a chave aplicação + objeto, objeto que já tem rota, rota pública repetida, vá-para com os dois campos, filtro do browse por aplicação); requisição por uma rota cadastrada e por uma sem cadastro; rota inativa.

## 10. Um campo só para o método (2026-10-07) — revê a §2.1

Decisão do responsável: a operação não tem "ação neutra" **e** método; tem um campo só, e a lista dele acompanha o tipo do objeto. PUT e PATCH são valores distintos.

- **`thl-objeto-parametro.acao` guarda o método da operação.** Em objeto REST: 1 POST, 2 PUT, 3 PATCH, 4 DELETE, 5 GET (`MethodTypeEnum`). Para outros tipos, a lista própria (Banco: 6 Insert, 7 Update, 8 Select). Continua na chave: estabelecimento, aplicação, objeto, operação, ação.
- **Na tela o campo aparece como "Método"** (`thl0022a-v01.w`), com a lista montada pelo tipo do objeto. O rótulo do dicionário ainda é "Ação"; trocar rótulo ou nome do campo exige delta e fica para depois.
- **A extensão REST continua filha da operação, com a chave do pai**, e não tem mais escolha de método: a aba REST ficou com Mensagem Simples, campos obrigatórios e chave externa. O método só se altera na operação (é chave: só na inclusão).
- **Colunas `metodo`** (`thl-objeto-parametro` e `thl-objeto-parametro-rest`) viraram cópia do campo `acao`, mantidas pela tela e pela API para quem ainda as lê.
- Código: `InboundConfigLoader` procura a linha por `acao` = método da requisição (saiu a conversão para ação neutra, `actionOf`); `resolveMethod` devolve `acao` e, se zero, a coluna antiga. `ActionEnum` segue valendo só entre Message, Processor e Service.
- Acerto: `acao` recebe o método gravado (antes convertia para 1 a 4); o contrato das Messages retiradas vai para POST (criar), PUT e PATCH (alterar) e DELETE (eliminar).
- API `objeto/parametro`: `acao` e `metodo` são a mesma informação; aceita qualquer das duas.

⚠️ Base em que o acerto **já rodou com a versão anterior** tem `acao` de 1 a 4 no sentido antigo (2 = alterar, 3 = eliminar, 4 = consultar). Regravar a partir da coluna `metodo`: `acao = metodo` nas operações e na extensão.

## 11. Sai o campo `acao`: o método é o campo da chave (2026-10-08) — conclui a §10

Decisão do responsável: as tabelas não têm mais "ação", só **método**, e é o método que faz parte da chave.

| Tabela | Chave |
|---|---|
| `thl-objeto-parametro` | `cod-estabel`, `aplicacao`, `objeto`, `operacao`, **`metodo`** |
| `thl-objeto-parametro-rest` | a mesma do pai (filha 1 para 1) |

- **Delta `Database\delta-thl-2026-10-08.df`** (gerado, não carregado): nas duas tabelas, `DROP FIELD "metodo"` (a cópia) e `RENAME FIELD "acao" TO "metodo"`. Os índices `pk-objeto-parametro` e `pk-objeto-parametro-rest` acompanham o campo renomeado — não há índice novo nem troca de primário. O campo fica com rótulo "Método", formato `>9` e `VIEW-AS` radio-set com `thl\include\i02thl011.i`; em `thl-objeto-parametro` volta para a ordem 30, onde estava o método antigo. A descrição dos dois índices continua citando "ação" (só texto; acertar pelo Data Dictionary).
- **Antes do delta: `Utils\scripts\pre-delta-metodo-chave.p`.** O delta elimina a coluna `metodo` antiga; o que sobra é o valor do campo da chave. O programa deixa nele o método (`acao = metodo`), cobrindo a base em que o acerto antigo gravou a ação neutra (1 a 4) e a base em que ficou zero. Simulação por padrão; chave repetida impede a gravação. Depois do delta ele não compila e não é mais necessário.
- **Código:** `InboundConfigLoader` procura a linha por `metodo` = método da requisição, nos mesmos quatro passos (saiu a busca alternativa pela coluna antiga); `MessageConfigLoader:resolveMethod` devolve o campo; `ObjetoParametroService` usa só a propriedade `metodo` no JSON (saiu `acao`), que identifica a linha na alteração e na exclusão; `referenceCode` = estabelecimento#aplicação#objeto#operação#método.
- **Telas:** `thl0022a-v01.w` (campo da chave = `metodo`, sem a cópia) e `thl0022a-v05.w` (chave da extensão). O browse `thl0022-b01.w` já mostrava `metodo` e não mudou.
- **Scripts e cargas:** acerto sem o passo que preenchia a ação; cargas `.p` e `.d` com um campo só (`thl011.d` e `thl032.d` perderam uma coluna — só carregam depois do delta).
- **`ActionEnum` continua no código**, entre Message, Processor e Service (criar, alterar, eliminar, consultar): é o que o Service faz, não o que está cadastrado. Decisão do responsável (2026-10-08): **fica o `ActionEnum`** na assinatura do `Processor:execute`; a Message traduz o método em ação num lugar só (PUT e PATCH → alterar; Insert/Update/Select de banco caem nas mesmas ações).

**Ordem de implantação:** 1) `pre-delta-metodo-chave.p` em simulação, conferir o log, gravar; 2) carregar o delta; 3) compilar tudo; 4) acerto, se ainda não rodou.

⚠️ Contrato da API `objeto/parametro`: saiu a propriedade `acao` (entrada e saída). PATCH/DELETE que mandavam `acao` passam a mandar `metodo`. Quem mandava `metodo` no PATCH só como dado agora o tem como chave.

## 12. Nota fiscal em um objeto só; rota pelo prefixo da URL (2026-10-08) — revê as §8 e §9

Decisão do responsável: **só o objeto `NotaFiscal`**, por causa da rota. Com uma rota por objeto (§9) não cabem as duas rotas da §8 (`notafiscal` e `notafiscal/embarque`) no mesmo objeto, e o objeto separado `NotaFiscalPorEmbarque` deixa de existir no cadastro padrão.

- **`InboundRouteResolver`:** sem rota exata, procura a rota cadastrada mais longa que inicia a URL (`findRouteByPrefix`); o que sobra vira a operação. A busca exata continua primeiro, e URL sem nenhuma rota cadastrada segue como antes (objeto = rota sem a barra, aplicação `TOTVS`).

| URL | Rota achada | Objeto | Operação | Service |
|---|---|---|---|---|
| `notafiscal/geracao` | `notafiscal` (exata) | `NotaFiscal` | `geracao` | `NotaFiscalService` |
| `notafiscal/embarque/geracao` | `notafiscal` (prefixo) | `NotaFiscal` | `embarque/geracao` | `NotaFiscalPorEmbarqueService` (recebe `geracao`) |

- **`NotaFiscalProcessor` volta a ser usado** (`thl-objeto.classe-processor` do objeto `NotaFiscal`): separa `embarque/<etapa>` e escolhe o Service; não mudou.
- **`inicio-operacao`** não é necessário neste caso (fica 0); o campo continua valendo para rota exata de vários níveis.
- Acerto: a `NotaFiscalMessage` passa a receber `NotaFiscalProcessor` + `NotaFiscalService`; objeto próprio do embarque que já exista na base é respeitado (Processor padrão + Service por embarque).
- Cargas `.d` (`Database\Data\entrada\`; pasta vazia em 08/10/2026, ver CHANGELOG): um objeto `NotaFiscal` na aplicação TOTVS, rota `notafiscal`.

⚠️ Efeito do prefixo em outras rotas: URL de três ou mais segmentos cujo início seja uma rota cadastrada passa a cair nessa rota, com a operação composta (ex.: `item/Saldo/x` → objeto `Item`, operação `Saldo/x`). Antes virava um objeto inexistente e dava erro de cadastro.

**A testar (não compilado):** as duas URLs de cada etapa; `ninahub/NotaFiscal/<etapa>` (rota exata, sem mudança); URL sem rota cadastrada; operação gravada na mensagem (`embarque/geracao`) no monitor.

## 13. A rota é filha de objeto: `/resourcen/objeto/rota` (2026-10-08) — revê a §9 no nome da API

Decisão do responsável: a rota deixa de ser um objeto próprio (`InboundRota`, URL `inbound-rota`) e passa a ser **operação do objeto `Objeto`**, como `objeto/parametro` e `objeto/usuario`.

- `InboundRotaService` → **`ObjetoRotaService`** (`thl-extensions.erp.thl.service`; `getEntityName` = "Rota do Objeto"). Chave, propriedades e validações não mudaram.
- **Cadastro:** sai o objeto `THL/InboundRota` (e a rota pública `inbound-rota`); entram as linhas da operação `rota` do objeto `Objeto`, uma por método, com `classe-service` = `ObjetoRotaService`. O roteador não muda: `objeto/rota` → rota `objeto`, operação `rota`.
- **Scripts:** `acerto-thl-operacao-service.p` cria as linhas da operação `rota` (cópia da linha genérica do `Objeto`); `acerto-thl-objeto-classes.p` marca o objeto `InboundRotaMessage` como sem uso; `carga-thl-api-cadastros.p` e `cadastrar-thl-api-rotas.ps1` deixam de cadastrar `InboundRota` e desativam a rota `inbound-rota`, avisando do objeto sem uso (`-EliminarObsoletos` elimina). Os endpoints do PowerShell passam a `objeto/rota`. Cargas `.d` de entrada: 26 objetos, 118 operações, 26 rotas.
- ⚠️ **Contrato:** a URL `inbound-rota` deixa de existir. Postman (pasta `Objeto > Rota`) atualizado; o app web (`cadastros.defs.ts`, `cadastro-mock.data.ts`) ainda aponta para `inbound-rota` — e já estava desatualizado (chave `rota`, `descricao`).
- ⚠️ **Ordem:** rodar o acerto das operações **antes** de usar a URL nova (sem a linha `rota`, `objeto/rota` cai na linha em branco e usa o `ObjetoService`, sem erro). A API de rotas altera a configuração da própria API: erro aqui derruba as URLs.

**A testar (não compilado):** `objeto/rota` com GET, POST, PATCH e DELETE; `inbound-rota` já sem resposta útil; `objeto` e `objeto/usuario` sem mudança.

## 14. Classes só na linha da operação; cadastro obrigatório só do pai (2026-10-08)

Decisão do responsável, em duas partes.

**1. Classes só na linha.** A execução nunca lê as classes de `thl-objeto`. Elas são o **padrão na criação** da linha de `thl-objeto-parametro`, que passa a trazer message, processor e service preenchidos; para mudar, altera-se a linha.

- `MessageConfigLoader`: `resolveMessageClass/ProcessorClass/ServiceClass` devolvem só o campo da linha (saiu o `b-thl-objeto`). `InboundConfigLoader:ensureClasses` confere as três na linha; `OutboundConfigLoader` confere a da mensagem.
- **Criação preenchida:** `ObjetoParametroService` (API) copia do objeto o que vier em branco, na criação e na alteração; THL0022a (`v01` e aba Classe `v06`) grava as do objeto quando em branco; `carga-thl-api-cadastros.p`, `carga-thl-transporte.p`, `carga-thl-api-metricas.p` e os `.d` gravam as classes. A aba Classe de um registro **novo** aparece em branco até salvar (a cópia é feita no gravar).
- **Desalinhamento:** mudar a classe do objeto no THL0021 ou na API `objeto` leva a mudança às linhas que ainda têm a classe antiga (ou em branco); linha personalizada fica. `acerto-thl-objeto-classes.p` faz o mesmo.
- Os campos de `thl-objeto` continuam, agora como padrão para linhas novas; a validação que os exige no objeto de entrada também. `Database\delta-thl-2026-10-09.df` ajusta só descrição e ajuda dos seis campos.

**2. Cadastro obrigatório só do pai.** O `InboundConfigLoader` procura (1) operação da URL + método e (2) operação em branco + método; sem nenhuma das duas, erro. Saíram a busca pelo nome do verbo e a da primeira linha do método. A linha do pai (operação em branco, uma por método) passa a declarar os métodos do objeto; etapas, modalidades e filhos sem linha própria continuam usando a do pai. Operação inventada em escrita ainda cai no pai sem erro — risco aceito.

**Migração (rodar antes de publicar os loaders):** `Utils\scripts\acerto-thl-operacao-classes.p` — (1) operação com o nome do verbo vira branco (a extensão REST vai junto; duplicata vai para o log), (2) classes em branco recebem as do objeto. Simulação por padrão. `cadastrar-thl-api-rotas.ps1`, as cargas `.p` e o example do Postman passaram a usar operação em branco.

⚠️ **Ordem:** acerto das classes do objeto → acerto das operações (filhos) → `acerto-thl-operacao-classes.p` → publicar os loaders. Linha de saída (outbound) sem `classe-objeto` falha com "sem classe da mensagem"; o acerto preenche.

**A testar (não compilado):** GET e POST sem linha do pai (erro esperado), com linha em branco; filho com linha própria (`objeto/usuario`); operação sem linha própria usando a do pai (nota fiscal, frete, `mensageria/metricas`); criar operação no THL0022a e pela API sem informar classes; trocar a classe no THL0021 e ver as linhas; saída (outbound) com a classe só da linha.

## 15. Nota fiscal: etapa é a última parte; Service vem da linha (2026-10-13) — revê a §12 no ponto do Service

Decisão do responsável: o `NotaFiscalProcessor` pega **sempre a última parte** da operação como etapa, e o Service vem da classe cadastrada na linha da operação (thl0022), não de `new NotaFiscalPorEmbarqueService()` no código.

| URL | Linha cadastrada no thl0022 (objeto `TOTVS/NotaFiscal`, POST) | Service da linha | Etapa |
|---|---|---|---|
| `notafiscal/geracao` | `geracao` | `NotaFiscalService` | `geracao` |
| `notafiscal/embarque/geracao` | `embarque/geracao` | `NotaFiscalPorEmbarqueService` | `geracao` |
| `notafiscal/ninahub/geracao` | `ninahub/geracao` | `NinahubNotaFiscalService` | `geracao` |

- **Código:** `execute` tira a última parte com `entry( num-entries( operation, '/' ), operation, '/' )`; saíram o `byShipment` e o `resolveService` que instanciava o Service do embarque. `processamento` passa a ser recusado pelo **tipo do Service** (`NotaFiscalPorEmbarqueService`), não pelo texto da operação.
- **Cadastro:** uma linha por etapa e por variante (`geracao`, `geracao-xml`, `autorizacao-sefaz`, `impressao`, `notificacao`; `processamento` só na direta e nas variantes que o aceitem), cada uma com o Service e a extensão REST (obrigatórios e chave externa) próprios. O cadastro é feito no thl0022; nenhum `.d` ou acerto cria essas linhas.
- ⚠️ **Operação composta sem linha:** o carregador cai na linha em branco do objeto (a do `NotaFiscalService`). `embarque/<etapa>` ou `ninahub/<etapa>` não cadastrada, ou com erro de digitação, roda com o Service da nota direta, sem erro. Proposta ainda **não aplicada**: operação com `/` só vale com linha exata (`InboundConfigLoader.findParameter`).
- ⚠️ **Ninahub:** o objeto `Ninahub/NotaFiscal` (rota `ninahub/NotaFiscal`) segue como está; mover o Ninahub para `notafiscal/ninahub/<etapa>` muda o contrato com eles e fica para decisão do responsável.

**A testar (não compilado):** as três URLs com `geracao`; `embarque/processamento` (erro esperado); operação composta sem linha.

## 16. Rota: chave aplicação + objeto + rota pública (2026-10-13) — revê a §9 no ponto "uma rota por objeto"

Decisão do responsável: `thl-objeto-rota` passa a ter chave primária **`aplicacao` + `objeto` + `rota-publica`**; `idx-rota-publica` **continua único** no banco todo.

- **Por quê único:** a URL só traz a rota, e o `InboundRouteResolver` precisa chegar a um objeto só. A resolução não muda (busca por `rota-publica`); só ganha a possibilidade de o mesmo objeto ter várias rotas.
- **Banco:** `Database/Definition/delta-thl-2026-10-13.df` (gerado, não carregado): índice novo com os três campos, `UPDATE PRIMARY INDEX`, `DROP INDEX` do antigo e `RENAME INDEX` para `pk-objeto-rota`. Sem migração de dados: as linhas existentes já cabem na chave nova. `fk-objeto` não é preciso (aplicação + objeto são prefixo da PK).
- **Código:** `ObjetoRotaService` (chave tripla em `initialize`/`create`/`positionRecord`; sai "uma rota por objeto"; `rotaPublica` fora de `mapFields`; GET com `rotaPublicaIni/Fin`; `referenceCode` = `aplicacao#objeto#rotaPublica`); `thl0040-v01.w` (rota pública na chave, só na inclusão) e `thl0040-g01.w` (`FIND FIRST`); `carga-thl-api-cadastros.p` e `cadastrar-thl-api-rotas.ps1` procuram a rota pela chave inteira (a carga deixa de **trocar** a rota do objeto: cria outra).
- **Contrato da API `objeto/rota`:** `rotaPublica` obrigatória em POST, PATCH e DELETE; PATCH não renomeia (eliminar e criar); GET aceita `rotaPublicaIni/Fin`. Postman e app web (`cadastros.defs.ts`, `cadastro-mock.data.ts`: `rotaPublica` com `key: true`, saiu `single`) acompanham.
- **A rota antiga que a carga trocava:** em base onde a carga/PowerShell anteriores **alteraram** a rota de um objeto, nada muda; nas próximas execuções, rota nova vira **segunda rota** do objeto (a antiga fica ativa até alguém desativar).

**A testar (não compilado):** incluir segunda rota no mesmo objeto; mesma rota no mesmo objeto (erro); rota já usada por outro objeto (erro); PATCH sem `rotaPublica` (erro de chave); GET com `rotaPublicaIni/Fin`; vá-para da `thl0040`; eliminar objeto com duas rotas; resolução de URL pelas duas rotas.
