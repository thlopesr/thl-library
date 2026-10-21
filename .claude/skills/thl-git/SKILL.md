---
name: thl-git
description: "Cuidar do Git da THL-Library — status, escopo e mensagem de commit, push, merge entre feature, develop e main, apagar branches. Use em sessão dedicada a Git ou quando o usuário chamar /thl-git. Codificação ABL fica em thl-coding; fechamento documental em thl-docs."
---

# thl-git — controle de versão da THL-Library

Siga o `AGENTS.md` da raiz. Esta skill existe para uma **sessão dedicada a Git**, separada da sessão de codificação OpenEdge. Ela só mexe no repositório; não edita `.cls`, `.p`, `.w` ou `.i`, não escreve documentação e não compila nada. Código é do `thl-coding`; notas, Postman e Notion são do `thl-docs`.

## Fluxo de branches

```text
feature/<assunto>  →  develop  →  main
```

- `main`: só o que foi compilado e testado no PDSOE. É a "última versão boa".
- `develop`: linha de integração; recebe as features prontas e é onde se valida antes de promover.
- `feature/<assunto>`: sempre criada **a partir da `develop`**, uma por assunto (`feature/mmcm-project`, `feature/<tema>`); apagada depois do merge, local e remota.
- Merge **somente em avanço simples** (`git merge --ff-only`). Se não for possível avançar, pare e explique; não resolva com merge comum, rebase ou `--force`.
- Sem compilador no ambiente do agente, nada chega à `main` sem o usuário confirmar que compilou e testou.

## Regra de ouro: só age com pedido explícito

O `AGENTS.md` proíbe commit, push, merge, rebase, stash e checkout sem pedido do usuário. Nesta sessão o pedido continua sendo necessário **a cada passo**:

| Ação | Quando fazer |
|---|---|
| `git status`, `git log`, `git diff`, `git branch -a` | Sempre, para entender o estado |
| `git add` + `git commit` | Quando o usuário pedir o commit, com o escopo combinado |
| `git push` (inclusive `-u`) | Quando o usuário pedir o push daquela branch |
| `git checkout` / `switch` | Quando o usuário pedir ou quando o merge combinado exigir |
| `git merge --ff-only` | Quando o usuário pedir o merge entre as duas branches nomeadas |
| Apagar branch (`-d` local, `push --delete` remota) | Só depois de confirmar que está mesclada e com o usuário pedindo |
| `reset --hard`, `push --force`, `rebase`, `stash`, `clean -f`, `branch -D` | **Nunca**, a não ser que o usuário peça exatamente isso, nomeando o alvo |

Pergunta como "podemos fazer commit?" não é ordem: responda com o estado e as opções, e espere o pedido.

## Antes de commitar

1. `git status --short` (inclui não rastreados) e `git branch --show-current`. Confirme que está na branch certa; nunca commite direto na `main`.
2. Se o working tree tiver muita coisa misturada de várias tarefas, proponha a divisão por tema e deixe o usuário escolher: um commit só, commits por tema ou só o que pertence à tarefa.
3. Revise `git diff` e `git diff --cached`. Confira também os arquivos novos, que não aparecem no diff comum.
4. Procure o que **não pode** ser versionado, e não inclua no commit: credenciais, tokens, senhas, hosts ou IPs de cliente (ex.: `Fontes/web/proxy.conf.json`, que está no `.gitignore`); gerados (`*.r`, `*.pl`, `dist/`, `node_modules/`, `.angular/`, `Xcode/`, `*.zip`, logs); estado pessoal (`.claude/settings.local.json`, `.obsidian/workspace*.json`).
5. Fontes ABL são ISO-8859-1 com CRLF; web e `.md` são UTF-8 com LF (ver `.gitattributes`). Avisos de "CRLF will be replaced by LF" são esperados. Mas se um fonte ABL aparecer com diff do arquivo inteiro, suspeite de regravação em outra codificação ou fim de linha e avise o usuário antes de commitar.
6. Informe o que **não** foi validado (compilação no PDSOE, testes). A mensagem do commit deve dizer "não compilado" quando for o caso.

## Mensagem de commit

- Português do Brasil, no formato `tipo(escopo): resumo no imperativo` (ex.: `feat(monitor): adiciona reenvio de mensagens outbound`, `chore: ignora o proxy.conf.json local`). Tipos: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`.
- Linha de resumo curta; corpo com os pontos principais em lista, o "porquê" quando não for óbvio e as limitações (não compilado).
- Termine com a linha de coautoria que o ambiente indicar (hoje: `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`).
- Mensagem multilinha via here-doc (`git commit -F -`), nunca com `-m` cheio de aspas.
- Nunca use `--no-verify` nem pule assinatura; se um hook falhar, investigue.

## Push, merge e fim de uma feature

1. **Feature nova:** `git switch develop`, `git switch -c feature/<assunto>` (só com pedido). A branch começa a partir da `develop` atual.
2. **Enviar a feature:** `git push -u origin feature/<assunto>`.
3. **Feature → develop:** `git switch develop`; `git merge --ff-only feature/<assunto>`; `git push origin develop`. Se o avanço simples falhar, pare.
4. **develop → main:** só quando o usuário disser que compilou e testou. `git switch main`; `git merge --ff-only develop`; `git push origin main`; volte para a `develop`.
5. **Limpeza:** com a feature mesclada em `main` e `develop`, e com pedido explícito: `git branch -d feature/<assunto>` e `git push origin --delete feature/<assunto>`. Use `-d` (recusa se não estiver mesclada), nunca `-D`. Apague também branches locais sem uso de sessões antigas (ex.: `claude/…`) quando o usuário pedir.
6. No fim, deixe o usuário na `develop`, com a árvore limpa, e relate: branches envolvidas, commits (`git log --oneline`) e se `develop` e `main` ficaram iguais ao `origin`.

## Sessões em paralelo

Duas sessões na mesma pasta compartilham o working tree: uma que troca de branch ou commita no meio da edição da outra a atrapalha. Combine com o usuário:

- A sessão de Git só age quando a de código terminou um bloco e o usuário autorizou.
- Para trabalho realmente simultâneo, use um `git worktree` por feature (cada sessão numa pasta), criado só a pedido.

## Saída

Português do Brasil. Mostre os comandos executados e o resultado resumido (hash, branches, arquivos). Em qualquer bloqueio (conflito, avanço simples impossível, arquivo suspeito), pare e explique em vez de contornar.
