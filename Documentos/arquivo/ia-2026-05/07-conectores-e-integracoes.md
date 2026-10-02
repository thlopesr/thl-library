# Conectores e integrações REST

A integração com sistemas externos na THL‑Lib é realizada através de **conectores** configuráveis.  Esta seção descreve como os conectores funcionam e como são configurados nas tabelas.

## Estrutura de configuração

1. **thl-conexao-rest** – Define a conexão com um servidor REST.  Contém um código, descrição, URL base e indicador de autenticação.  Ex.: `CONN_API_EXTERNA` com URL base `https://api.externa.com`.  
2. **thl-conexao-rest-path** – Lista os paths (endpoints) associados a cada conexão.  Cada registro indica o `cod-path`, a descrição, o `path` relativo à URL base (ex.: `/pedidos`), content‑type, accept, timeout, parâmetros padrão e cabeçalhos adicionais.  
3. **thl-conexao-rest-autenticacao** – Armazena as informações de autenticação para uma conexão: endpoint de token, content‑type/accept do token, cabeçalhos, parâmetros, usuário, senha, token atual, data de expiração e a classe que faz o parsing do token.  Se `ind-requisita-autenticacao` for verdadeiro em `thl-conexao-rest`, uma configuração de autenticação deve existir.

## Classes relacionadas

* **RestConnector** – Executa chamadas HTTP com base na configuração.  Monta a URL final combinando `url-base` e `path`, aplica cabeçalhos, parâmetros e timeout.  Se o método exigir autenticação, obtém ou renova o token usando `AuthenticationConfig` e `TokenProviderFactory`.
* **ConnectorRequest / ConnectorResponse** – Estruturas que encapsulam dados de requisição e resposta (status code, body, headers).  Assim o serviço pode operar sem depender diretamente da biblioteca HTTP subjacente.
* **ConnectorFactory** – Recebe o tipo de conector (`REST` no momento) e retorna uma instância apropriada.  Permite extensões para outros protocolos (ex.: SOAP, gRPC) no futuro.
* **AuthenticationConfig** – Representa a configuração de autenticação lida de `thl-conexao-rest-autenticacao`.
* **ITokenProvider** – Interface que abstrai a obtenção de tokens.  Implementações podem chamar um endpoint HTTP, ler de arquivo ou de um serviço externo.  `TokenProviderFactory` instância a implementação correta.

## Passos para configurar uma integração REST outbound

1. **Criar um registro em `thl-conexao-rest`** para o servidor externo, definindo URL base e marcando se requer autenticação.  
2. **Cadastrar path(s) em `thl-conexao-rest-path`** para cada recurso/serviço do servidor: incluir rota relativa, timeout, content‑type, accept e parâmetros padrão.  
3. **Definir autenticação (se necessário)** em `thl-conexao-rest-autenticacao`: informar URL para buscar token, credenciais e a classe que extrai o token do retorno.  Definir `ind-requisita-token` e `tipo-autenticacao`.  
4. **Configurar o objeto de integração em `thl-objeto`** com `classe-objeto` igual ao nome da classe que implementa a regra de negócio (por exemplo, `EntregaPedidoMessage`).  Marcar `sentido-fluxo` como outbound.  
5. **Configurar o método/operação em `thl-objeto-parametro`**, indicando o `metodo` HTTP, o `cod-param-ambiente` relevante e as opções de log e persistência.  O campo `operacao` deve corresponder à operação executada na classe de mensagem.  
6. **Associar usuários autorizados** (opcional) em `thl-objeto-usuario`.  
7. **Chamar a integração** a partir de programas do ERP ou triggers: instanciar a classe de mensagem, preencher `OutboundObjectContext` e invocar `OutboundMessageService`.  O serviço cuidará de buscar a configuração, montar o conector, enviar a requisição e gravar o retorno.

Seguindo essas etapas, novas integrações podem ser adicionadas sem necessidade de alterar o código existente.
