# AGENTS.md — THL-Library

Instruções para agentes de código (Codex, Claude Code e similares) que trabalham neste repositório. Responda e documente em **português do Brasil**; identificadores de código em inglês.

## O projeto

Framework corporativo em **OpenEdge ABL OO** para customizações e integrações no **TOTVS Datasul 12** (PASOE, Progress Developer Studio com Shared AVM). Oferece mensageria inbound/outbound, conectores REST, serviços ERP, e-mail, erros, log/auditoria e utilitários. Há também um front-end **Angular 21 + PO UI** (monitor de mensageria).

```text
Database/Definition/thl.df  definição do banco THL (ISO-8859-1); Database/Data/entrada = cargas .d
Fontes/thl/                  telas .w, RPWs e APIs Datasul (resourcen.p = endpoint REST)
Fontes/thl-lib/              framework genérico — core, ERP, integrações e utilitários
Fontes/thl-extensions/       um sistema externo por pasta: erp/<sistema>/ e integration/<sistema>/
Fontes/web/                  app Angular 21 + PO UI (standalone por feature)
Documentos/.claude/          base de conhecimento para agentes (vault do Obsidian)
Documentos/{tecnico,negocio} guias para pessoas
Utils/                       scripts de compilação/xcode, exemplos, testes
.claude/skills/<nome>/SKILL.md  guias de trabalho por tipo de tarefa
```

## Antes de mexer: leia a base de conhecimento

1. [`Documentos/.claude/convencoes.md`](Documentos/.claude/convencoes.md) — padrões **obrigatórios**.
2. [`Documentos/.claude/arquitetura.md`](Documentos/.claude/arquitetura.md) — camadas, hierarquias de classe, fluxos, onde estender.
3. [`Documentos/.claude/INDEX.md`](Documentos/.claude/INDEX.md) — mapa das notas por pacote; abra só as notas relevantes.
4. A skill da tarefa (são Markdown comuns; siga-as mesmo fora do Claude Code):

| Tarefa | Guia |
|---|---|
| Escrever/refatorar/revisar ABL (`.cls`, `.p`, `.w`) | [`.claude/skills/thl-coding/SKILL.md`](.claude/skills/thl-coding/SKILL.md) |
| Auditar, testar, checklist de regressão | [`.claude/skills/thl-qa/SKILL.md`](.claude/skills/thl-qa/SKILL.md) |
| Arquitetura, impacto de mudança, dúvidas OpenEdge/PASOE, divergência código × documentação (protocolo de sincronização) | [`.claude/skills/thl-architect/SKILL.md`](.claude/skills/thl-architect/SKILL.md) |
| Registrar/avaliar decisão de arquitetura (ADR) | [`.claude/skills/thl-adr/SKILL.md`](.claude/skills/thl-adr/SKILL.md) |
| Identificar e priorizar dívida técnica | [`.claude/skills/thl-tech-debt/SKILL.md`](.claude/skills/thl-tech-debt/SKILL.md) |
| Fechar tarefa: atualizar notas, INDEX, Notion, Postman e propor ajustes em skills | [`.claude/skills/thl-docs/SKILL.md`](.claude/skills/thl-docs/SKILL.md) |
| Especificar tela (UX) em PO UI | [`.claude/skills/thl-poui-design/SKILL.md`](.claude/skills/thl-poui-design/SKILL.md) |
| Código Angular/PO UI em `Fontes/web` | [`.claude/skills/thl-web-coding/SKILL.md`](.claude/skills/thl-web-coding/SKILL.md) |
| Testar/auditar tela web (PO UI + TOTVS) | [`.claude/skills/thl-web-qa/SKILL.md`](.claude/skills/thl-web-qa/SKILL.md) |

A documentação é atalho: quando precisar de precisão (assinatura, regra), confirme no código em `Fontes/`.

## Workflow e escopo

1. Antes de editar, consulte `git status` e identifique alterações locais, inclusive arquivos não rastreados. Preserve o trabalho existente e não sobrescreva mudanças fora da tarefa.
2. Solicitação de análise, revisão ou diagnóstico não autoriza alterações: registre achados e propostas. Implemente apenas o escopo solicitado ou autorizado; apresente um plano curto antes das mudanças.
3. Consulte a base e a skill pertinente; confirme contratos e comportamento no código. Separe implementação atual, decisão aceita, proposta e histórico.
4. Faça mudanças pequenas e dirigidas. Não modernize legado nem acrescente refatorações sem relação com a tarefa.
5. Execute as validações disponíveis e pertinentes. Diferencie leitura estática, compilação/build, teste funcional e medição; informe o que não foi executado.
6. Ao concluir, revise `git diff` e confira também arquivos novos, que não aparecem no diff comum. Verifique escopo, referências e alterações acidentais; informe resultado e limitações.

## Regras obrigatórias

### Codificação e fim de linha
- **Fontes ABL (`.cls .p .w .i .df`) são ISO-8859-1, sempre.** Nunca regravar em UTF-8 nem com BOM. Edite preservando os bytes fora do trecho alterado; evite ferramentas que reescrevem o arquivo inteiro em outra codificação. Acentos em comentários/strings só em Latin-1.
- Front-end web (`.ts .html .scss .json`) e `.md` são **UTF-8**.
- Fim de linha no disco (ver `.gitattributes`): ABL, config do PDSOE e scripts Windows em **CRLF**; web e `.md` em **LF**.
- Para editar ABL, use leitura/gravação explícita em Latin-1 e preserve os bytes e fins de linha existentes fora do trecho alterado; confira a codificação e o diff depois com ferramentas disponíveis no ambiente.
- Em scripts Python com caminhos Windows, use raw strings ou barras `/`. Ao gerar texto por script, cuidado com escapes: `\a`, `\t`, `\b` em caminhos Windows dentro de strings Python/sed viram caracteres de controle.

### Pacotes e camadas
- Pacote ABL = caminho a partir de `Fontes/`, **em minúsculas** (kebab-case): `Fontes/thl-lib/integration/messaging/inbound/core/InboundMessage.cls` → `thl-lib.integration.messaging.inbound.core.InboundMessage`. Vale para `USING`, `INHERITS`, `NEW`, `CAST`.
- Genérico → `thl-lib/`. Específico de sistema externo → `thl-extensions/erp/<sistema>/` (services, enums) ou `thl-extensions/integration/<sistema>/` (mensagens, conectores). **Nunca** tabelas de cliente (`nit-*`, `es_*`) em `thl-lib`.
- Classes carregadas por `dynamic-new` são referenciadas pelo nome completo gravado no banco (`thl-objeto.classe-objeto`, `thl-conexao-rest-autenticacao.classe-parser-token`, `thl-conexao-rest-header.classe-parser`). **Mover ou renomear uma classe exige atualizar esses cadastros** — avise o usuário.
- Preserve contratos públicos (`Message`, `InboundMessage`, `OutboundMessage`, `Service`, `ITokenProvider`, `IHeaderProvider`…): não mude assinaturas sem pedido explícito.
- Programas Datasul (`Fontes/thl`): `thl00NN` cadastro, `thl01NN` consulta, `thl02NN` tarefa (tela + RPW), com o mesmo `NN` do assunto; cabeçalhos (`i-prgvrs.i`, `ut9000.i`, `c-programa`) com o nome do próprio arquivo. Detalhes em `convencoes.md` §7.

### Estilo ABL
- `block-level on error undo, throw.`; erros via `ThlError`/`ErrorHandler` (`thl-lib.core.error`); nunca `catch` silencioso.
- Métodos e variáveis em inglês camelCase, **sem prefixo de tipo**; classes PascalCase; nomes de domínio Datasul em português (`NotaFiscalMessage`); interfaces com `I`; enums novos com sufixo `Enum` (preserve exceções legadas, como `ExecutionMode`); temp-tables no padrão TOTVS com hífen. Comentários em português.
- Caminhos em `run`/`{include}` sempre com `/`.
- JSON com `JsonSetter`/`JsonWriter` (`thl-lib.util.json`).

### Legado ABL, contratos e transações
- Em `.w`, preserve estrutura AppBuilder/ADM, triggers, widgets e blocos gerados; altere apenas os trechos necessários. Consulte a skill `thl-coding` e `convencoes.md` §7.
- Antes de alterar parâmetros INPUT/OUTPUT/INPUT-OUTPUT de `.p` ou assinaturas OOABL, procure callers e confirme compatibilidade, inclusive chamadas dinâmicas e cadastros.
- Não altere locking ou escopo de transação sem entender o fluxo completo e seus chamadores; avalie concorrência, tratamento de erros e ciclo de vida dos objetos envolvidos.

### Banco de dados (`Database/Definition/thl.df`)
- Nomes de índice: `pk-*` chave primária (única, uma por tabela), `fk-<tabela-pai>` chave estrangeira, `idx-*` busca (chave alternativa única = `idx-` + `UNIQUE`). Detalhes e regras de implantação em `convencoes.md` §6; inventário em `Documentos/.claude/data/schema.md`.
- O `.df` é ISO-8859-1 com CRLF e trailer com deslocamento em bytes — não editar à mão; o responsável gera pelo Data Dictionary.

### Front-end (`Fontes/web`)
- Componentes **standalone por feature** (`src/app/<feature>/{pages,components,models,services}` + `<feature>-routing.ts`); não criar `NgModule`.
- URLs relativas: `${window.location.origin}/api/thl/integration/v1/resourcen/<rota>`.

## Build e validação

- **ABL:** não há compilador OpenEdge no ambiente do agente. Não afirme que o código compila — diga que precisa ser compilado no PDSOE (PROPATH do Shared AVM) ou com `Utils/scripts/compilar-thl.p`. Verifique ao menos pacote × pasta, `USING` e assinaturas por leitura.
- **Web** (em `Fontes/web`): workspace com **dois projetos** — `web` (consulta/monitor) e `cadastro` (telas de cadastro); sempre informe o projeto: `npm ci`, `npx ng build web` e `npx ng build cadastro`. `ng test` **não funciona** (sem alvo de teste nem biblioteca instalada). Pacotes para o Datasul: `./build-deploy.ps1` (gera a pasta `dist/thl-html-consulta`) e `./build-deploy-cadastro.ps1` (gera a pasta `dist/thl-html-cadastro`); o `dist` fica só com essas duas pastas (sem zip nem saída intermediária). Consulta e cadastro ficam em apps separados, como as seções do menu Datasul — não misturar.
- Não há suíte de testes ABL ativa (`Utils/test/` está vazio).

## Documentação (manter sincronizada)

- Ao alterar código, atualize a nota de pacote correspondente em `Documentos/.claude/` e registre uma linha de changelog no topo de `INDEX.md`. Classe-base nova ou filha nova → atualizar também `arquitetura.md` / `arquitetura/<Classe>.md`.
- `Documentos/.claude/` é vault do Obsidian: use **links Markdown relativos** (`[texto](../erp/erp-services.md)`), nunca `[[wikilinks]]`. Não edite `.obsidian/workspace*.json`.
- Não crie relatórios soltos na raiz: relatórios vão para `Documentos/relatorios/`, material antigo para `Documentos/arquivo/`.

## Git e segurança

- **Não faça commit, push, merge, rebase, stash nem checkout** sem pedido explícito do usuário.
- Não versione gerados: `*.r`, `*.pl`, `dist/`, `node_modules/`, `.angular/`, `Xcode/`, `*.zip`, logs (ver `.gitignore`).
- Não grave credenciais, tokens, hosts/IPs de clientes ou senhas em código, exemplos ou documentação — configuração fica em `thl-ambiente-param` / cadastros de conexão.
- Não apague nem mova arquivos fora do escopo pedido; em dúvida, pergunte.
