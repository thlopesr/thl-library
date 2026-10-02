# CLAUDE.md — THL-Library

As regras compartilhadas ficam em `AGENTS.md`, importado abaixo. Mantenha neste arquivo apenas orientações específicas do Claude Code.

@AGENTS.md

## Específico do Claude Code

- **Skills do projeto:** use os guias de `.claude/skills/` indicados na tabela de tarefas do `AGENTS.md`. Se houver versões homônimas em plugins pessoais, priorize as do repositório.
- **Preview do front-end:** configurações em `.claude/launch.json` — `mensageria-dev` (`ng serve web`, porta 4200) e `cadastro-dev` (`ng serve cadastro`, porta 4201, com backend mock em memória). Use a ferramenta de preview quando disponível; se não estiver disponível, informe a limitação e use um servidor local compatível com a tarefa.
- **Configuração pessoal:** `.claude/settings.local.json`, ignorado pelo Git. Não transfira permissões ou configurações pessoais para as regras compartilhadas.
