**Assunto:** Biblioteca THL (Technical Helper Library) — programas disponíveis no menu Datasul e suas funções

Prezados,

Segue a relação dos programas da Biblioteca THL (Technical Helper Library) disponíveis no Datasul, agrupados por finalidade. A THL é uma biblioteca de apoio ao desenvolvimento de customizações para o ERP TOTVS, com funcionalidades de integração, variáveis de ambiente, e-mail (monitorado) e auditoria.

**1. Cadastros**

| Programa | Nome | Função |
|---|---|---|
| thl0001 | Manutenção Ambiente | Cadastra os ambientes onde a biblioteca roda (por exemplo, produção e homologação). Ao eliminar um ambiente, as variáveis de parâmetro dele também são eliminadas. |
| thl0002 | Manutenção Parâmetro de Ambiente | Define, para cada ambiente, as variáveis de configuração e os programas que passam a usar esse ambiente. |
| thl0010 | Manutenção Parâmetro de E-mail | Configura como os e-mails da biblioteca são enviados: quem recebe e por qual programa. |
| thl0011 | Manutenção Grupo de E-mail | Agrupa usuários em listas de destinatários, usadas nos envios de e-mail e nos avisos da auditoria. |
| thl0020 | Manutenção Aplicação | Cadastra os sistemas externos que se integram ao Datasul. |
| thl0021 | Manutenção Objeto de Integração | Cadastra o que cada sistema externo troca com o Datasul (por exemplo, uma nota fiscal), ligado à sua aplicação. |
| thl0022 | Manutenção Parâmetros do Objeto | Ajusta o comportamento de cada objeto por operação e estabelecimento e define quais usuários podem usá-lo. |
| thl0030 | Manutenção Conexão REST | Cadastra o endereço (URI) dos sistemas externos que o Datasul chama. |
| thl0031 | Manutenção Path REST | Cadastra os caminhos (endpoints) disponíveis em cada conexão. |
| thl0032 | Manutenção Autenticação REST | Define como o Datasul se identifica no sistema externo (obtenção do token de acesso). |
| thl0033 | Manutenção Cabeçalho REST | Define os cabeçalhos adicionais enviados em cada chamada à conexão. |
| thl0040 | Manutenção Rota Inbound | Define o endereço público pelo qual um sistema externo envia dados ao Datasul para um objeto. |
| thl0050 | Manutenção Tabela Auditada | Cadastra as tabelas do banco cujas alterações devem ser registradas. |
| thl0051 | Manutenção Parâmetros da Auditoria | Define, para cada tabela auditada, quais campos são acompanhados, quem pode consultar, quem é avisado das alterações e por quantos dias o histórico é mantido. |

**2. Monitores e consultas**

| Programa | Nome | Função |
|---|---|---|
| thl0110 | Monitor de E-mail | Acompanha os e-mails enviados pela biblioteca e o resultado de cada envio. |
| thl0120 | Monitor de Mensageria | Acompanha as mensagens trocadas com os sistemas externos: filtra, mostra o conteúdo e permite reenviar. |
| thl0150 | Consulta de Auditoria | Mostra quem alterou o quê, quando e com quais valores nas tabelas auditadas. |

**3. Tarefas (execução por RPW)**

| Programa | Nome | Função |
|---|---|---|
| thl0210 | Expurgo de E-mails | Limpeza programada: elimina o histórico de e-mails mais antigo que o número de dias informado. |
| thl0220 | Reprocessamento de Mensagens Outbound | Tarefa que tenta novamente enviar ao sistema externo as mensagens de saída que não foram concluídas. |
| thl0221 | Processamento Inbound Agendado | Tarefa que processa as mensagens recebidas dos sistemas externos que ficaram agendadas. |
| thl0222 | Expurgo de Mensagens | Limpeza programada: elimina o histórico de mensagens de integração e dos dados ligados a elas. |
| thl0250 | Expurgo da Auditoria | Limpeza programada: elimina os registros de auditoria mais antigos que os dias de retenção definidos para cada tabela. |

Em caso de dúvida, falar com a equipe responsável pela Biblioteca THL.

Atenciosamente,
Thiago Lopes
