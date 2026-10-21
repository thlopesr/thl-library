# Funcionalidade E-mail — envio padronizado e monitorado

A THL envia e-mails a partir dos programas do ERP, com **texto, remetente e destinatários cadastrados** em vez de escritos no código. Quem envia informa só o código do e-mail e os valores variáveis; o resto vem do cadastro e pode mudar sem alterar programa. Cada envio pode ficar registrado e ser consultado no monitor de e-mail.

Este guia explica a funcionalidade e os cadastros em linguagem de negócio. O detalhe campo a campo está em [guia-telas-web.md](guia-telas-web.md); o fluxo técnico, em [fluxo-email](../.claude/fluxos/fluxo-email.md).

> Verificado por leitura do código e das notas do projeto. Nada foi executado contra o Datasul para escrever este guia.

## Como funciona

1. O programa do ERP pede o envio de um e-mail.
2. A THL descobre **qual parâmetro de e-mail usar** lendo a variável de ambiente `codigo.email` do programa. Como é variável de ambiente, o mesmo programa pode enviar e-mails diferentes por ambiente: em homologação, por exemplo, o parâmetro pode apontar para um grupo só com a equipe interna. Veja [funcionalidade-variavel-ambiente.md](funcionalidade-variavel-ambiente.md).
3. Com o parâmetro, a THL monta o e-mail: assunto, corpo, remetente, cópia e **destinatários** (os usuários do grupo de e-mail).
4. O programa pode preencher **marcadores** (`#1#`, `#2#`…) no assunto e no corpo.
5. O envio usa o serviço de e-mail do Datasul. O servidor e a porta vêm da configuração de e-mail **do próprio Datasul**, não da THL.
6. Se o parâmetro estiver com **Gera log**, o envio é registrado e passa a aparecer no monitor e nas métricas de e-mail.

## Destinatários

O grupo de e-mail lista usuários do Datasul. Para cada usuário, o e-mail sai para:

- o endereço cadastrado no **usuário do ERP**; e
- o **e-mail alternativo** informado no grupo, se houver.

O alternativo **soma**, não substitui: quem tem os dois recebe nos dois endereços. A lista de cópia do parâmetro usa vírgula como separador.

## Marcadores

Escreva `#1#`, `#2#` e assim por diante no assunto ou na mensagem. O programa que dispara substitui cada marcador pelo valor correspondente, na ordem. Quais valores existem depende do programa. **Marcador que o programa não substituir chega literal ao destinatário.**

## Cadastros

| Cadastro | Programa Datasul | Para que serve |
|---|---|---|
| **Grupo de e-mail** | thl0011 | Lista reutilizável de destinatários. Tem a aba **Destinatários**, com usuário e e-mail alternativo. Os parâmetros de e-mail e as notificações de auditoria apontam para o grupo, em vez de repetir endereços |
| **Parâmetro de e-mail** | thl0010 | Define cada e-mail: código, grupo, assunto, remetente, cópia, importância, se gera log e a mensagem (editor com HTML) |

Campos do parâmetro de e-mail:

| Campo | O que faz |
|---|---|
| **Código** | Identifica o parâmetro. O programa chega a ele pela variável `codigo.email` |
| **Grupo de e-mail** | Quem recebe |
| **Assunto** | Assunto do e-mail, com marcadores |
| **Remetente** | Quem envia. Em branco, usa o padrão do ambiente |
| **Cópia** | Endereços em cópia, separados por vírgula |
| **Gera log** | Sim registra cada envio. **Sem isso o envio não deixa rastro** e não aparece no monitor |
| **Mensagem** | Corpo, em HTML |

Pontos de atenção:

- O campo **Importância** ainda não tem os valores definidos; confirme antes de usar.
- **Eliminar** um grupo de e-mail só é possível se ele não estiver em uso por um parâmetro de e-mail ou por uma notificação de auditoria.
- Falha geral de envio costuma ser configuração de e-mail do Datasul ou rede, não cadastro da THL.

## Como configurar um novo e-mail

1. Cadastre o **Grupo de e-mail** com os usuários que recebem.
2. Cadastre o **Parâmetro de e-mail**: assunto, mensagem, remetente, cópia e **Gera log**.
3. Cadastre a variável `codigo.email` no parâmetro de ambiente do programa, com o código do parâmetro de e-mail como valor.
4. Peça à TI que o programa envie o e-mail (ele informa os valores dos marcadores).
5. Confirme no monitor de e-mail.

## Acompanhamento

| Para… | Use |
|---|---|
| Ver se um e-mail saiu, para quem e com qual resultado | Monitor de e-mail (thl0110, ou tela web) |
| Ver envios, entregas e falhas por programa | Métricas de e-mail (web) |
| Limpar envios antigos | Tarefa thl0210, que elimina os e-mails mais antigos que os dias informados |

O monitor só mostra envios de parâmetros com **Gera log** marcado. Passo a passo de uso: [guia-monitoramento-comunicacao.md](guia-monitoramento-comunicacao.md).

## Limitações a conhecer

- O monitor agrupa por **programa**, não por parâmetro de e-mail, porque o registro de envio não guarda o parâmetro.
- O destino dos envios não aparece nas métricas, porque a rota devolve endereços sem validação de acesso.
- Sem **Gera log**, não há como saber depois se o e-mail foi enviado.
