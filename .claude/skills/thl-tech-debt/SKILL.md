---
name: "thl-tech-debt"
description: "Identificar, categorizar e priorizar dívida técnica na THL-Library (thl-lib e thl-extensions), usando o histórico do projeto e a KB em Documentos\\.claude\\."
---

# THL Tech Debt

Auditoria e priorização de dívida técnica da THL-Library (TOTVS Datasul 12 / OpenEdge 12 OOABL / PASOE / Oracle), ancorada no histórico real do projeto.

## Passo 0 — Contexto obrigatório (index-first)
1. Ler `Documentos\.claude\INDEX.md` antes de qualquer conclusão.
2. Ler `Documentos\.claude\adr\` (decisões já tomadas — dívida que contraria um ADR aceito é prioridade maior; dívida que um ADR aceitou conscientemente NÃO é reaberta sem motivo novo).
3. Ler `Documentos\.claude\tech-debt\REGISTRO.md` se existir (itens já catalogados, status, data).
4. Só depois ler fontes em `Fontes\`.

## Histórico THL a considerar
- **Separação core × cliente**: thl-lib (core) não pode depender de thl-extensions. Qualquer referência inversa é dívida de arquitetura nível 5 de risco.
- **Mensageria** (`thl-lib\integration\messaging`): subpacotes `inbound\` e `outbound\`, nomenclatura `<Domínio><Padrão>.cls`. Já passou por QA estática via /thl-qa; verificar se correções pendentes daquela rodada foram aplicadas. Em thl-extensions, sufixo `Message` redundante foi abolido (ex.: prefixo Ninahub mantido, sufixo removido) — nomes antigos remanescentes são dívida de código.
- **Auditoria**: `AuditLogService.cls` NUNCA pode propagar exceção dentro de trigger; notificação é assíncrona via RPW. Qualquer chamada síncrona de notificação ou CATCH ausente em caminho de trigger = risco 5.
- **Níveis espaçados (1/5/9)** em sensibilidade/acesso: valores fora do espaçamento ou comparações por igualdade rígida em vez de faixa são dívida.
- **Handles × buffers**: ABL não faz cast de HANDLE para BUFFER tipado; padrão correto é BUFFER-FIELD/BUFFER-VALUE/DATA-TYPE. Código que contorna isso com hacks é dívida.
- **Ciclo de vida de handles**: bug histórico em thl1992.w (FINALLY destruindo hTabelaTemp antes da query ler). Procurar o mesmo padrão: DELETE OBJECT em FINALLY de objetos ainda referenciados fora do bloco.
- **Serialização JSON**: serialização direta de buffer físico falhou no histórico; iteração manual com `Progress.Json.ObjectModel.JsonObject` é o padrão.
- **Encoding**: fontes entregues em ISO-8859-1 / CRLF. Arquivos UTF-8 ou LF são dívida de infraestrutura (quebram acentuação no AppBuilder/compilação).
- **Numeração de programas**: cadastros reorganizados por dezena (Ambiente+Parâmetro; Email+Grupo Email Usuário; Aplicação+Objeto+Parâmetro Objeto; URI+Path+Autenticação+Cabeçalho; Rota; Tabela Auditoria+Parâmetros). Programas fora do esquema = dívida de documentação/organização.
- **Telas**: padrão de cadastro baseado em thl0005 (w-cadsim, SmartQuery, SmartViewer, SmartBrowser, SmartVaPara, zoom). Telas fora do padrão, ou candidatas à migração PO-UI, devem ser marcadas.
- **Testes e exemplos**: `Utils\test\` e `Utils\example\`. Classe pública sem teste ou exemplo = dívida de teste.
- **Procedures internas**: nomes em português, granulares (ex.: pi-carregar-json-auditoria, pi-preparar-query-browse). pi monolíticas = dívida de código.

## Categorias (adaptadas ao ecossistema)
| Tipo | Exemplos THL | Risco |
|---|---|---|
| Código | pi monolíticas, nomes legados, lógica duplicada entre Services, magic numbers fora de constantes | Bugs, manutenção lenta |
| Arquitetura | dependência core→extensions, Service acessando tabela de outro domínio, lógica de negócio em .w | Acoplamento, quebra de clientes |
| Runtime PASOE | estado em variável estática/singleton entre requests, handles vazando por agente, transação longa | Vazamento de memória, lock Oracle |
| Trigger/Transação | exceção propagada em trigger, trabalho síncrono pesado em trigger | Rollback de transação do ERP |
| Teste | sem .p em Utils\test\, sem smoke test de integração | Regressão em cliente |
| Documentação | .md da KB divergente do código, DUMP-NAME não verificado, ADR ausente | Decisões refeitas, onboarding |
| Infraestrutura | encoding errado, sem padrão de build/deploy PASOE, segredos fora de variáveis de ambiente THL | Incidente, retrabalho |

## Priorização
Pontuar cada item:
- **Impacto** (1-5): quanto atrasa desenvolvimento ou afeta clientes
- **Risco** (1-5): consequência de não corrigir (5 = derruba transação do ERP, vaza dado, quebra cliente)
- **Esforço** (1-5)
- **Raio de impacto**: core (afeta todos os clientes) × extensão (um cliente) — core multiplica por 1,5

Prioridade = (Impacto + Risco) × (6 − Esforço) × fator de raio

## Saída
1. Tabela priorizada: ID (TD-NNN), categoria, local (arquivo/classe), descrição, pontuação, esforço estimado, justificativa ligada ao histórico.
2. Plano em fases que conviva com feature work (ex.: corrigir ao tocar no arquivo; sprint de limpeza por pacote).
3. Para cada item, indicar a skill que executa a correção: /thl-coding (implementa), /thl-qa (gera teste/valida), /thl-adr (se a correção exige decisão).
4. Atualizar (ou propor criação de) `Documentos\.claude\tech-debt\REGISTRO.md` com os itens novos e o status dos antigos — o registro é o histórico vivo da dívida.