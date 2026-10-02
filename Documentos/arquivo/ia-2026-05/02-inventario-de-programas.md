# Inventário de programas `.w`

A seguir estão listados os principais programas da biblioteca `thl`, agrupados por funcionalidade.  Os programas possuem variantes (b01, g01, v01, z01, q01), utilizadas internamente pelo framework Datasul para diferentes abas de cadastro ou consulta; os nomes base (`thl0002.w`, por exemplo) representam a entrada principal.

| Programa | Finalidade resumida | Tabelas associadas |
|---------|--------------------|-------------------|
| **THL0002 – Cadastro de ambiente** | Permite cadastrar ou atualizar ambientes de execução do ERP (servidor, nome e código). | `thl-ambiente` |
| **THL0003 – Parâmetros por ambiente/programa** | Gerencia parâmetros de ambiente e variáveis por programa. Possui abas para: variáveis (`thl-ambiente-param-variavel`), programas (`thl-ambiente-param-prog`) e parâmetros gerais (`thl-ambiente-param`). | `thl-ambiente-param`, `thl-ambiente-param-prog`, `thl-ambiente-param-variavel` |
| **THL0004 – Grupos de e‑mail** | Cadastra grupos de e‑mail e usuários do ERP associados a cada grupo. | `thl-ambiente-param-grupo`, `thl-ambiente-param-grupo-usuar` |
| **THL0005 – Cadastro de objeto** | Registra “objetos de integração”, que representam entidades de negócio (ex.: Nota Fiscal, Usuário). Define se o objeto é inbound/outbound, se gera histórico e qual aplicação está relacionada. | `thl-objeto` |
| **THL0006 – Métodos e usuários do objeto** | Configura os métodos/operações disponíveis para cada objeto e associa usuários autorizados a executá‑los. Inclui parâmetros de persistência e execução. | `thl-objeto`, `thl-objeto-parametro`, `thl-objeto-usuario` |
| **THL0007 – Conexão REST** | Cadastra conexões de WebService REST (servidores). Define URL base, descrição e se exige autenticação. | `thl-conexao-rest` |
| **THL0008 – Paths da conexão REST** | Define os caminhos de destino (paths) de cada conexão REST. Inclui timeout, cabeçalhos e parâmetros padrão. | `thl-conexao-rest-path` |
| **THL0009 – Autenticação REST** | Configura autenticação para conexões REST: URL de token, content‑type, usuário, senha, token e classe de parsing. | `thl-conexao-rest-autenticacao` |
| **THL0010 – Rotas inbound** | Cadastra rotas de entrada (endpoint público) que apontam para objetos e operações. Indica se a rota está ativa. | `thl-inbound-rota` |
| **THL1986 – Consulta de mensagens** | Permite pesquisar mensagens enviadas/recebidas e ver detalhes: itens (identificadores de registro) e conteúdo. Inclui histórico e status de processamento. | `thl-mensagem`, `thl-mensagem-item`, `thl-mensagem-conteudo`, `thl-mensagem-historico` |
| **THL2000 – Consulta de e‑mails** | Lista registros de e‑mails enviados via THL‑Lib, exibindo remetente, destinatário, assunto, anexo e retorno. | `thl-email` |

Outros programas auxiliares (`thl0003a`, `thl0003b`, `thl0006a`, etc.) suportam variações de telas ou abas específicas e compartilham as mesmas tabelas listadas acima.
