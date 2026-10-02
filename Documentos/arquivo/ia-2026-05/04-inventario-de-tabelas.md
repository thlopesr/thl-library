# Inventário de tabelas

A THL‑Lib define **19 tabelas** no arquivo de definição (`.DF`) fornecido.  O objetivo desta seção é listar cada tabela, seus campos principais e relacionamentos aparentes.  Os tipos de dados foram extraídos do `.DF`.  Relações entre tabelas foram inferidas pelo nome dos campos; onde não for possível confirmar, isso é indicado.

## thl-ambiente

Tabela de ambientes de execução do ERP. Permite identificar diferentes servidores/instâncias.

* **cod-ambiente (character)** – Código identificador do ambiente. Chave primária.  
* **nome-ambiente (character)** – Nome amigável do ambiente.  
* **ip (character)** – Endereço IP ou host do ambiente.

## thl-ambiente-param

Tabela de parâmetros genéricos por ambiente.

* **cod-param-ambiente (character)** – Código do parâmetro. Chave.  
* **descr-param-ambiente (character)** – Descrição do parâmetro.

Relacionamento:  associa‑se a `thl-ambiente` via campos das tabelas filhas.

## thl-ambiente-param-prog

Define quais programas (`cod-prog-dtsul`) utilizam determinado parâmetro de ambiente.

* **cod-param-ambiente (character)** – Código do parâmetro (FK para `thl-ambiente-param`).  
* **cod-prog-dtsul (character)** – Código do programa Datasul.

## thl-ambiente-param-variavel

Armazena variáveis e respectivos valores por ambiente/parâmetro.

* **cod-variavel (character)** – Código da variável. Chave.  
* **cod-ambiente (character)** – Ambiente relacionado (FK para `thl-ambiente`).  
* **cod-param-ambiente (character)** – Parâmetro relacionado (FK para `thl-ambiente-param`).  
* **descr-variavel (character)** – Descrição da variável.  
* **valor-variavel (character)** – Valor configurado.

## thl-ambiente-param-grupo

Cadastra grupos de e‑mail utilizados para enviar notificações.

* **cod-grp-usuar (character)** – Código do grupo. Chave.  
* **descricao (character)** – Descrição do grupo.

## thl-ambiente-param-grupo-usuar

Associa usuários do ERP a grupos de e‑mail.

* **cod-grp-usuar (character)** – Grupo (FK para `thl-ambiente-param-grupo`).  
* **cod-usuario (character)** – Código do usuário do ERP.  
* **email-alternativo (character)** – E‑mail alternativo para envio de mensagens.

## thl-objeto

Define objetos de integração que representam entidades de negócio.

* **objeto (character)** – Código do objeto. Chave primária.  
* **programa-consulta (character)** – Programa Datasul de consulta associado (opcional).  
* **ind-inativo (logical)** – Indica se o objeto está inativo.  
* **ind-gera-historico (logical)** – Indica se a integração deve registrar histórico.  
* **sentido-fluxo (logical)** – `TRUE` para outbound, `FALSE` para inbound.  
* **aplicacao (character)** – Aplicação relacionada.  
* **modelo-integracao (integer)** – Modelo de integração (enum).  
* **classe-objeto (character)** – Nome da classe que implementa a integração (referência a classes do `thl-lib`).

## thl-objeto-parametro

Configura os métodos/operações permitidos para cada objeto.

* **objeto (character)** – Código do objeto (FK para `thl-objeto`).  
* **metodo (integer)** – Método HTTP ou operação (associado a `MethodTypeEnum`).  
* **cod-estabel (character)** – Código de estabelecimento (se aplicável).  
* **ind-persistente (logical)** – Indica se a mensagem deve ser persistente.  
* **frequencia-execucao (integer)** – Frequência em minutos para execuções agendadas.  
* **cod-servid-exec (character)** – Servidor executor.  
* **qtd-tentativas-persist (integer)** – Quantidade de tentativas ao persistir.  
* **qtd-dias-persist (integer)** – Dias para manter a persistência.  
* **tipo-log-requisicao (integer)** – Tipo de log de requisição.  
* **tipo-log-retorno (integer)** – Tipo de log de retorno.  
* **ind-gera-historico (logical)** – Se `TRUE`, grava histórico.  
* **ind-inativo (logical)** – Indica se o método está inativo.  
* **forma-execucao (integer)** – Modo de execução (`ExecutionMode`).  
* **ind-mensagem-simples (logical)** – Define se a mensagem deve ser simplificada.  
* **operacao (character)** – Nome da operação/rotina.  
* **cod-param-ambiente** e **cod-param-ambiente-destino** (character) – Parâmetros de ambiente de origem e destino (FK para `thl-ambiente-param`).

## thl-objeto-usuario

Tabela simples para registrar usuários autorizados a operar objetos de integração.

* **objeto (character)** – Código do objeto (FK para `thl-objeto`).  
* **cod-usuario (character)** – Usuário autorizado.

## thl-conexao-rest

Configurações básicas de conexões REST.

* **cod-conexao (character)** – Código da conexão. Chave.  
* **des-conexao (character)** – Descrição da conexão.  
* **url-base (character)** – URL base do servidor REST.  
* **ind-requisita-autenticacao (logical)** – Se `TRUE`, a conexão precisa de autenticação.

## thl-conexao-rest-path

Define os caminhos (endpoints) associados a cada conexão REST.

* **cod-path (character)** – Identificador do path. Chave.  
* **des-path (character)** – Descrição do path.  
* **path (character)** – Rota relativa à URL base.  
* **content-type (character)** – Content‑Type padrão.  
* **accept (character)** – Accept padrão.  
* **timeout (integer)** – Timeout em segundos.  
* **parameters (character)** – Parâmetros padrão (JSON ou query).  
* **headers (character)** – Cabeçalhos adicionais.

Relacionamento:  cada path deve referenciar uma `thl-conexao-rest` por chave estrangeira (campo não explícito no `.DF`; relação inferida pelo uso em programas).

## thl-conexao-rest-autenticacao

Parâmetros de autenticação para conexões REST.

* **cod-conexao (character)** – Código da conexão (FK para `thl-conexao-rest`).  
* **url-token (character)** – Endpoint para obter token.  
* **content-type-token** e **accept-token** (character) – Tipos padrão para a requisição de token.  
* **headers-token** e **parameters-token** (character) – Cabeçalhos e parâmetros adicionais para obtenção de token.  
* **tipo-autenticacao (character)** – Tipo (ex.: Bearer).  
* **ind-requisita-token (logical)** – Se a conexão precisa renovar token.  
* **usuario / senha (character)** – Credenciais para autenticação básica.  
* **token (character)** – Token armazenado.  
* **raw-token-data (character)** – Conteúdo bruto retornado pelo provedor de token.  
* **dt-expiracao-token (datetime)** – Data/hora de expiração.  
* **classe-parser-token (character)** – Nome da classe responsável por extrair o token do retorno.

## thl-inbound-rota

Define rotas públicas que o endpoint REST (`resourcen.p`) utiliza para direcionar a requisição ao objeto e operação corretos.

* **cod-rota (character)** – Código da rota. Chave.  
* **rota-publica (character)** – Rota acessível externamente (ex.: `/api/v1/<obj>/<op>`).  
* **objeto (character)** – Objeto vinculado (FK para `thl-objeto`).  
* **descricao (character)** – Descrição da rota.  
* **ind-ativo (logical)** – Indica se a rota está ativa.

## thl-mensagem

Registra cada execução de integração (inbound ou outbound).

* **codigo-mensagem (character)** – Identificador da mensagem. Chave primária.  
* **objeto (character)** – Objeto de integração (FK para `thl-objeto`).  
* **metodo (integer)** – Método ou operação (FK para `MethodTypeEnum`).  
* **modelo-integracao, forma-execucao** (integer) – Modelo de integração e modo de execução.  
* **sit-requisicao / sit-retorno / sit-processamento (integer)** – Situações/estados da requisição, retorno e processamento.  
* **qtd-tentativas (integer)** – Número de tentativas.  
* **dt-criacao / dt-integracao (datetime)** – Datas de criação e envio/retorno.  
* **destino (character)** – URL de destino ou identificador.  
* **num-ped-exec (integer)** – Número de pedido de execução (uso interno).  
* **sentido-fluxo (logical)** – Direção: `TRUE` outbound, `FALSE` inbound.  
* **cod-status-retorno (integer)** – Código retornado pela API externa.  
* **descr-retorno (character)** – Descrição do retorno.  
* **operacao (character)** – Nome da operação executada.

## thl-mensagem-item

Armazena as chaves de registro que compõem a mensagem (ex.: números de pedido, notas fiscais, usuários).  Um código de mensagem pode ter vários itens.

* **codigo-mensagem (character)** – Código da mensagem (FK para `thl-mensagem`).  
* **chave-registro (character)** – Chave primária do registro no ERP.  
* **chave-registro-ext (character)** – Chave externa ou complementar.

## thl-mensagem-conteudo

Registra o conteúdo (payload) enviado ou recebido para cada mensagem.  Pode haver múltiplos conteúdos por mensagem (ex.: request/response).

* **codigo-mensagem (character)** – Código da mensagem (FK para `thl-mensagem`).  
* **tipo-conteudo (integer)** – Tipo de conteúdo (1=request, 2=response, etc.).  
* **conteudo (clob)** – Corpo em formato JSON ou texto.

## thl-mensagem-historico

Mantém histórico das tentativas de envio/processamento para cada mensagem.

* **codigo-mensagem (character)** – Código da mensagem (FK para `thl-mensagem`).  
* **tentativa (integer)** – Número da tentativa.  
* **sit-requisicao / sit-retorno / sit-processamento (integer)** – Situações durante a tentativa.  
* **dt-criacao / dt-integracao (datetime)** – Datas dessa tentativa.  
* **destino (character)** – Destino.  
* **cod-status-retorno (integer)** – Código retornado.  
* **descr-retorno (character)** – Descrição do retorno.

## thl-audit-registro

Tabela de auditoria genérica utilizada para gravar alterações em qualquer registro.

* **tabela (character)** – Nome da tabela auditada.  
* **data-criacao (datetime)** – Data/hora da auditoria.  
* **tipo (integer)** – Tipo de alteração (inclusão, alteração, exclusão).  
* **usuario (character)** – Usuário responsável.  
* **programas-executado (character)** – Programa que realizou a operação.  
* **referencia (character)** – Chave de referência do registro.  
* **registro (clob)** – Conteúdo anterior/posterior conforme a auditoria.

## thl-email

Registra e‑mails enviados pela THL‑Lib.

* **id (character)** – Identificador do e‑mail. Chave.  
* **data-envio (datetime)** – Data/hora de envio.  
* **cod-prog-dtsul (character)** – Programa que solicitou o envio.  
* **remetente (character)** – Remetente do e‑mail.  
* **destino (character)** – Destinatário(s).  
* **assunto (character)** – Assunto.  
* **arq-anexo (character)** – Nome do arquivo anexo, se houver.  
* **log-envio (integer)** – Indicador de log de envio.  
* **mensagem (character)** – Corpo do e‑mail.  
* **retorno (character)** – Retorno (ex.: status do servidor SMTP).  
* **info-envio (character)** – Informações adicionais de envio.  
* **cod-param-ambiente (character)** – Parâmetro de ambiente utilizado (FK para `thl-ambiente-param`).


Estas tabelas formam a base de dados da THL‑Lib.  Outras tabelas não identificadas no pacote devem ser documentadas quando forem criadas.
