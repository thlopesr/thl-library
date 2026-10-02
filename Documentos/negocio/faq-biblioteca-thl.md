# FAQ – Perguntas frequentes sobre a Biblioteca THL

> Revisado em 2026-09-24 contra o código e as telas atuais.

## A biblioteca é um módulo oficial da TOTVS?

Não.  A THL‑Lib é uma biblioteca corporativa desenvolvida pela equipe interna para padronizar integrações no ERP TOTVS Datasul.  Embora siga padrões Datasul, não é um módulo oficial comercializado pela TOTVS.

## Posso usar a THL para qualquer tipo de integração?

A biblioteca está focada em integrações REST/JSON.  Ela pode ser estendida para outros protocolos, mas é recomendável avaliar cada caso para verificar se os componentes existentes atendem à necessidade.

## É possível registrar histórico das integrações?

Sim.  Os campos **ind-gera-historico** em `thl-objeto` e `thl-objeto-parametro` controlam se o histórico deve ser gravado.  O histórico fica nas tabelas `thl-mensagem-historico` e pode ser consultado pelo monitor `THL0120`.

## Como configurar variáveis diferentes para cada ambiente?

Utilize o **THL0002** na aba Variável para informar valores distintos por ambiente.  Assim, quando o código é executado em outro ambiente, ele lê o valor correspondente.

## Preciso de acesso técnico para cadastrar rotas inbound?

Não necessariamente.  Os cadastros podem ser feitos por usuários com permissão adequada.  Entretanto, a implementação da regra de negócio na classe correspondente (ex.: `UsuarioMessage.cls`) requer conhecimento técnico em OpenEdge ABL.

## Onde ficam gravados os logs?

Os logs de integração são gravados nas tabelas da THL‑Lib (mensagem, conteúdo, histórico — consulta no THL0120).  Mensagens técnicas vão para o log do servidor (`LogUtil`) e a auditoria de alterações fica nas tabelas `thl-audit-*` (consulta no THL0150).  Consulte a equipe técnica para detalhes de infraestrutura.

## É possível desativar temporariamente uma integração?

Sim.  Nos cadastros de objetos (`THL0021`), métodos (`THL0022`) e rotas (`THL0040`), existe o campo *Inativo* ou *Ativo*.  Desmarque para desativar o objeto, método ou rota sem excluí‑los.

## O que acontece se o token de autenticação expirar?

A THL‑Lib tenta renovar o token automaticamente usando as informações de `thl-conexao-rest-autenticacao`.  Se não conseguir, a mensagem ficará em erro.  Verifique a configuração ou solicite suporte.

## Como garantir que apenas usuários autorizados enviem integrações?

A aba **Usuário** do THL0022 define **quem enxerga** as mensagens de cada objeto nos monitores (THL0120 e demais) e no app web — ela **não bloqueia** o envio ou o recebimento de integrações.  O controle de quem pode chamar as APIs inbound fica na autenticação do servidor (PASOE/API TOTVS).

Se sua pergunta não estiver aqui, consulte os guias técnicos ou entre em contato com a equipe de TI.
