---
tipo: adr
modulo: mensageria
status: aceita
updated: 2026-10-03
camada: ambos
tags: [adr, mensageria]
---

# ADR — Métricas, situação geral da mensagem, gravação de conteúdo, aplicação interna e expurgo com dois prazos

> **Aceita em 2026-10-03** (decisões do responsável). As oito fases do backend estão escritas (§4). Fontes **não compilados nem testados**; as fases 4 a 8 só compilam com o delta do banco carregado.
>
> Contexto: [extensions/thl.md](../extensions/thl.md) · [integration/messaging-core.md](../integration/messaging-core.md) · [integration/messaging-inbound.md](../integration/messaging-inbound.md) · [data/schema.md](../data/schema.md) · [thl/camada-datasul.md](../thl/camada-datasul.md)

## 1. Contexto

O app de consulta vai ganhar telas de métricas (mensageria, e-mail, auditoria). Hoje os painéis somam a listagem paginada no navegador e os números saem incompletos. A discussão das métricas puxou quatro mudanças ligadas: situação geral da mensagem, opção de gravar conteúdo, marcação de aplicação interna e expurgo com dois prazos.

Nesta frente só entra o backend OpenEdge; o front fica para outra sessão.

## 2. Decisões

### 2.1 Rotas de métricas

- `mensageria/metricas`, `email/metricas` e `auditoria/metricas`, como **operação** da Message existente (só GET — cabe na chave de `thl-objeto-parametro`, como `mensageria/conteudo`). Sem rota nova em `thl-inbound-rota`.
- **Sem sumarização no backend**: a rota devolve os registros abertos e o front agrupa.
- **Menos atributos** que a listagem, **sem paginação e sem limite de registros**.
- Filtro **só pela faixa de data e hora**. Método novo no mesmo Service (`getMetrics`), ao lado do `get`; o `get` das consultas não muda.
- Mensageria filtra por `dt-criacao` (não por `dt-integracao`, vazio nas pendentes). Situações das três fases como texto; a situação geral não é enviada (o front deriva).
- Acesso: **nenhuma rota de métricas valida acesso de usuário** (decisão do responsável em 2026-10-03). A auditoria percorre `thl-audit-tabela` sem consultar `thl-audit-tabela-acesso`; e-mail e auditoria seguem o desenho agrupado da mensageria (objeto → lista), com situações em texto. A **mensageria não valida o usuário** nas métricas (revisto pelo responsável em 2026-10-03): percorre aplicação → objeto → mensagem, devolve array → objeto (`aplicacao`, `objeto`, `interna`) → `mensagens[]`; `interna` é `thl-aplicacao.ind-interna` e todas as aplicações entram.
- E-mail sai por programa + parâmetro de ambiente: o `thl-email` não guarda o parâmetro de e-mail nem o grupo.

### 2.2 Data e hora

- Só as rotas de métricas aceitam hora. `StringUtil:parseDateTime` (novo) lê somente `yyyy-MM-ddTHH:mm`, hora local, sem segundos e sem fuso; outro formato é erro.
- `StringUtil:parseDate` e as consultas atuais **não mudam** (continuam descartando a hora).

### 2.3 Situação geral da mensagem

- Campo novo `thl-mensagem.sit-mensagem`: 1 = Pendente, 2 = Erro, 3 = Sucesso.
- Regra: alguma fase em erro → 2; senão, alguma fase pendente → 1; todas em sucesso ou não aplicável → 3.
- **Outbound agendado aceito conta como pendente** até o RPW executar.
- **Outbound com falha** grava processamento como "não aplicável" quando o objeto não tem regra de processamento (hoje grava erro).
- Corrigir `MessageRepository.saveResultMessage`: a situação da requisição testa o parâmetro do retorno para decidir "não aplicável".
- Índice `idx-objeto-situacao` (aplicação, objeto, `sit-mensagem`, `dt-criacao`).
- Mensagens já gravadas: script de acerto, em simulação por padrão.

### 2.4 Gravação de conteúdo por operação

- Campo novo `thl-objeto-parametro.tipo-grava-conteudo`: 1 = Sempre (padrão, comportamento atual), 2 = Somente em erro, 3 = Nunca (fica só a `thl-mensagem`).
- Domínio em `thl\include\i05thl011.i` e enum para as classes.
- Inbound agendado e outbound gravam a requisição sempre (o RPW e o reenvio dependem dela).
- `tipo-log-requisicao` e `tipo-log-retorno` **não são usados**: ficam reservados para o reenvio de mensagens com problema.

### 2.5 Aplicação interna

- Campo novo `thl-aplicacao.ind-interna` (inicial Não); a aplicação `THL` é marcada como interna.
- Fica na aplicação, não em cada mensagem: a mensagem já carrega a aplicação.

### 2.6 Expurgo com dois prazos

- Campos novos em `thl-objeto`: `retencao-dias-sucesso` (inicial 21) e `retencao-dias-erro` (inicial 42); zero = não expurga.
- Sucesso (`sit-mensagem` = 3) usa o primeiro; erro e pendente usam o segundo.
- O `thl0222` deixa de pedir "Manter Dias" na tela.
- Consequência: o período máximo das telas de métricas é de **21 dias** (acima disso os sucessos já foram expurgados e a saúde aparece pior do que foi).

## 3. Banco

Delta gerado em `Database\delta-thl-2026-10-03.df` (cinco campos e um índice). O responsável carrega o delta e gera o `thl.df` completo pelo Data Dictionary; o agente não edita o `thl.df`.

⚠️ Com valor inicial, todos os objetos já cadastrados passam a valer 21/42 dias: revisar os objetos que precisam de histórico maior antes do primeiro expurgo.

## 4. Fases

| Fase | Entrega | Situação em 2026-10-03 |
|---|---|---|
| 1 | Este ADR | ✅ |
| 2 | Delta do banco, include de domínio e script de diagnóstico das situações | ✅ gerados; delta **não carregado** |
| 3 | `parseDateTime`, `getMetrics` nos três Services, operação `metricas` nas três Messages, carga | ✅ escrito, não compilado |
| 4 | `sit-mensagem` no `MessageRepository`, correção da requisição, agendado como pendente, falha de envio com processamento não aplicável, `sitMensagem` na mensageria, script de acerto | ✅ escrito em 2026-10-03, não compilado; **só compila com o delta carregado** |
| 5 | Gravação de conteúdo: `ContentStorageEnum`, `MessageConfigLoader` (campo e escolha determinística da linha), `MessageConfig`, `MessageFactory`, `Message`, `InboundMessage`, `ObjetoParametroService`, carga das métricas | ✅ escrito em 2026-10-03, não compilado; **só compila com o delta carregado** |
| 6 | Aplicação interna: `AplicacaoService` (`indInterna`), `interna` nas linhas de `mensageria/metricas`, carga marca `THL` | ✅ escrito em 2026-10-03, não compilado |
| 7 | Expurgo com dois prazos: `ObjetoService` (`retencaoDiasSucesso`, `retencaoDiasErro`), `thl0222rp.p` reescrito, `thl0222.w` esconde "Manter Dias" | ✅ escrito em 2026-10-03, não compilado |
| 8 | Telas `thl0020-v01.w` (Interna), `thl0021-v01.w` (dois prazos), `thl0022a-v03.w` (Grava Conteúdo) | ✅ escrito em 2026-10-03, não compilado; layout a conferir no AppBuilder |
| — | Front (campos de cadastro, filtro com hora, telas de métricas) | Outra sessão |

## 5. Alternativas descartadas

| Alternativa | Motivo |
|---|---|
| Agregar no backend (linha por unidade ou por combinação) | O responsável quer o registro aberto e o agrupamento no front |
| Teto de registros nas métricas | Decidido sem limite |
| Hora também nas consultas atuais | Decidido só para as métricas |
| Reaproveitar `tipo-log-requisicao`/`-retorno` para a gravação de conteúdo | Reservados para o reenvio |
| Tipo interno/externo em cada mensagem | Repete em toda mensagem o que a aplicação já diz |
| Um único prazo de expurgo | Erro precisa de mais tempo para diagnóstico e reenvio |
| Índice sobre as três situações existentes | Oito combinações para "sucesso"; o campo único deixa o índice curto e serve ao monitor |

## 6. Riscos conhecidos

- **Volume das métricas.** Sem paginação nem limite, um período com muito movimento gera resposta grande, montada inteira em memória no agente. A gravação dessa resposta no banco só deixa de acontecer depois da fase 5 (operação `metricas` com conteúdo "nunca" ou "somente em erro").
- **E-mail.** O índice de `thl-email` começa pelo programa: a faixa só por data lê a tabela.
- **Linha de parâmetro sem operação na URL.** O `MessageConfigLoader`, sem operação, pega o primeiro `thl-objeto-parametro` do método. Com a linha `metricas` (GET) ao lado da linha da consulta, a escolha depende da ordem do índice. Hoje é só rótulo; na fase 5 passa a decidir a gravação de conteúdo e precisa ficar determinística.
- **Cada chamada de métricas grava uma `thl-mensagem`** e entra na própria métrica da mensageria até existir o filtro de aplicação interna (fase 6).
