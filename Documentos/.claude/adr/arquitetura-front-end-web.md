---
tipo: adr
modulo: web
status: aceita
updated: 2026-10-02
camada: ambos
tags: [adr, web]
---

# ADR — Arquitetura do front-end web (Angular + PO UI)

> **Aceita e aplicada.** Registra decisões tomadas entre 2026-09-24 e 2026-10-02 e já em uso em `Fontes\web`; nenhuma decisão nova é introduzida aqui. A [ADR da API REST dos cadastros](api-rest-cadastros-thl.md) colocou as telas PO UI explicitamente fora do escopo — este documento preenche essa lacuna.
>
> Estado atual do app: [web/app-web.md](../web/app-web.md) · contrato do motor: [web/motor-cadastro.md](../web/motor-cadastro.md) · comportamento do PO UI: [web/poui-licoes.md](../web/poui-licoes.md) · camadas: [arquitetura.md](../arquitetura.md).

## 1. Contexto

O THL ganhou um front-end Angular 21 + PO UI 21 (tema `@totvs/po-theme`) publicado como menu HTML do Datasul. Ele cobre duas naturezas de tela muito diferentes:

- **Consulta/monitor** — mensageria, e-mail, auditoria e métricas: muitos registros, filtro avançado por tela, contadores, gráficos, detalhe em abas.
- **Cadastro** — os 9 cadastros da API REST (`resourcen/<rota>`): CRUD com pai e filhos, formulários de até 16 campos, pouca variação entre telas.

As decisões abaixo tratam de estrutura e de como o código é organizado. Decisões de **interface** (cor, ícone, largura, texto) ficam em [motor-cadastro.md](../web/motor-cadastro.md), porque mudam com mais frequência e não valem o custo de uma ADR.

## 2. Decisões

### 2.1 Dois apps separados, não um app com rotas

O workspace tem dois projetos: **`web`** (consulta — `main.ts`, `app.routes.ts`) e **`cadastro`** (`main-cadastro.ts`, `cadastro.routes.ts`). `shared\` é comum aos dois.

**Alternativa descartada:** app único com as duas áreas em rotas diferentes.

**Por quê:** o Datasul publica cada menu HTML como uma aplicação própria, e as seções de consulta e de cadastro são cadastradas separadamente no menu. Com um app só, publicar uma correção de cadastro republicaria o monitor, e o usuário baixaria o bundle das duas áreas para usar uma.

**Consequências:**
- Todo comando precisa do nome do projeto: `npx ng build web` e `npx ng build cadastro` (sem o nome o CLI falha com "Cannot determine project").
- Dois pacotes de deploy: `dist\thl-html-consulta` e `dist\thl-html-cadastro`, gerados por `build-deploy.ps1` e `build-deploy-cadastro.ps1`.
- O que é comum vive em `shared\` e **precisa servir aos dois** — foi o caso dos rótulos de situação (`shared\domain\status-labels.ts`) e do `thl-row-actions`.
- Tela de cadastro nunca entra nas rotas da consulta, e vice-versa.

### 2.2 Cadastro é definição, não componente

Nenhum cadastro tem componente próprio. Cada um é um `CrudResource` em `cadastros\cadastros.defs.ts`, e a rota entrega a definição ao `ThlCrudPageComponent` em `data: { def }`. O motor (`shared\crud\`) desenha browse, coluna "Ação", formulário, Detalhar, abas de filhos, estados e validação.

**Alternativa descartada:** um componente por cadastro, que foi o estado inicial — Ambiente e Parâmetro nasceram assim e foram migrados em 2026-10-01, com as pastas `ambiente\` e `parametro\` removidas.

**Por quê:** os nove cadastros diferem em campos, não em comportamento. Na forma anterior, cada um custava cerca de seis arquivos quase idênticos (~50 no total), e toda correção de comportamento precisava ser repetida em todos — na prática, não era.

**Consequências:**
- Cadastro novo = definição + rota + item de menu + dados de exemplo no mock. Nenhum componente.
- Melhoria no motor aparece nos nove de uma vez. O inverso também vale: defeito no motor atinge os nove.
- O preço é a indireção: para entender uma tela, lê-se a definição **e** o motor.
- **Limite aceito:** tela que fuja do padrão (filtro avançado próprio, gráfico, fluxo em etapas) volta a ser componente próprio. Os monitores de consulta são exatamente esse caso e **não** foram migrados para o motor.

### 2.3 Standalone por feature, sem `NgModule`

Componentes standalone com `imports` próprios; rota da feature em `<feature>-routing.ts` carregada por `loadChildren`. A pasta `modules\` foi migrada e removida em 2026-09-24.

**Alternativa descartada:** `NgModule` por feature.

**Por quê:** é o caminho padrão do Angular desde a v15, reduz boilerplate e deixa explícito o que cada componente usa. O app `cadastro` nem tem pastas de feature, por causa de 2.2.

### 2.4 Backend de desenvolvimento em memória, trocado no build

O app `cadastro` tem um interceptor de mock (`mock\cadastro-mock.interceptor.ts`) com CRUD completo em memória, que entra **apenas** no build `development`, por `fileReplacements` (`mock-interceptors.ts` → `mock-interceptors.dev.ts`). O interceptor nunca é importado direto.

**Alternativas descartadas:** servidor de mock separado, MSW, ou depender sempre do PASOE via proxy.

**Por quê:** permite desenvolver e demonstrar as telas sem PASOE, sem subir processo adicional, e com garantia de que o mock não vai para produção — a troca é feita pelo build, não por `if`.

**Consequências e risco confirmado:**
- O mock **não é o backend**. Ele devolve a coleção inteira, então o aviso de lista truncada (`hasNext`/`total`) nunca acende no desenvolvimento; só vai ser exercitado contra o PASOE.
- Dado de exemplo é dado de produto: precisa ser plausível e sem informação real de cliente. Valores sensíveis são mascarados no mock como no backend.
- Ao verificar um estado de falha injetando erro no mock, o arquivo tem de ser revertido em seguida.

## 3. Consequências gerais

**A favor:** publicação independente das duas áreas; cadastro novo em minutos; comportamento uniforme nas nove telas; desenvolvimento sem backend.

**Contra:** dois builds e dois pacotes para manter; indireção do motor; `shared\` com dois consumidores, onde mudança descuidada quebra o outro app.

**Não muda:** a API. O front consome `resourcen/<rota>` como qualquer outro cliente, com URL relativa a `window.location.origin`.

## 4. Pontos em aberto

| # | Situação | Item |
|---|---|---|
| 1 | ⚠️ Em aberto | **Sem suíte de testes executável:** existem `.spec.ts`, mas não há alvo `test` no `angular.json` nem biblioteca instalada. A verificação hoje é build + navegador + leitura — ver a skill `thl-web-qa`. |
| 2 | ⚠️ Em aberto | **Nada validado contra o PASOE.** Toda a verificação foi com mock (cadastro) ou dados injetados no componente (consulta). Falta confirmar grafia dos domínios, `hasNext`/`total` e os nomes dos query params na resposta real. |
| 3 | ⚠️ Em aberto | **Paginação:** os GET usam `pageSize` 100 e `hasNext` sempre falso; acima de 100 registros a lista de cadastro corta. A tela já avisa quando o backend informar. |
| 4 | 📝 Decidido, não aplicado | Zoom dos campos sem endpoint de consulta (usuário Datasul, estabelecimento) fica para a v2 — hoje texto livre validado pelo backend. |
| 5 | 📝 Observação | `.claude\launch.json` na raiz e em `Fontes\web\` duplicam a configuração do dev server. |
| 6 | 📝 Observação | `src\app\dashboard\` e `mensageria\pages\dashboard-mensageria\` não estão em nenhuma rota. |

## 5. Como esta decisão foi verificada

Builds dos dois projetos passando; telas exercitadas no preview (`cadastro-dev` 4201 com mock, `mensageria-dev` 4200 sem backend); pacotes de deploy regerados em 2026-10-02. Nenhuma afirmação deste documento depende de teste automatizado, porque não há.
