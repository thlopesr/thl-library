# Guia operacional da Biblioteca THL

> Revisado em 2026-09-24 contra o código e as telas atuais.

A Biblioteca THL foi criada para padronizar integrações e mensageria no ERP TOTVS Datasul.  Este guia explica, de forma funcional, como utilizar os principais cadastros e monitores da biblioteca no dia a dia.

## O que a THL resolve?

* **Centraliza integrações** com sistemas externos (envio e recebimento de dados).  
* **Permite configurar parâmetros** sem alterar o código (ambientes, variáveis, conexões).  
* **Registra mensagens** e histórico de tentativas, oferecendo rastreabilidade completa.  
* **Facilita o envio de e‑mails** de alerta e comunicação.  

## Principais cadastros e suas finalidades

| Programa | Função | Quando utilizar |
|---------|-------|----------------|
| **THL0001 – Ambiente** | Cadastrar ou alterar ambientes de execução (servidores). | Ao implantar novo ambiente ou alterar IP/descrição. |
| **THL0002 – Parâmetros de ambiente** | Definir parâmetros e variáveis por programa. | Quando um programa precisa de valores configuráveis (URLs, caminhos, limites). |
| **THL0011 – Grupos de e‑mail** | Criar grupos de destinatários e associar usuários. | Para definir quem receberá alertas de integrações e e‑mails automáticos. |
| **THL0020 – Aplicações** | Cadastrar os sistemas externos integrados (código e descrição). | Antes de cadastrar objetos de uma nova aplicação; o THL0021 pesquisa a aplicação com F5. |
| **THL0021 – Objetos de integração** | Registrar entidades que serão integradas (ex.: Pedido, Usuário). | Antes de criar uma nova integração. |
| **THL0022 – Métodos do objeto** | Definir operações permitidas, parâmetros e usuários autorizados para cada objeto. | Ao configurar integrações (ex.: método POST de criação de pedido). |
| **THL0030 – Conexões REST** | Cadastrar servidores externos e URLs base. | Ao integrar com uma nova API externa. |
| **THL0031 – Paths REST** | Definir endpoints específicos de cada conexão. | Para cadastrar serviços (ex.: criar pedido, consultar nota). |
| **THL0032 – Autenticação REST** | Configurar como a conexão obtém e renova tokens. | Quando a API externa exigir autenticação. |
| **THL0040 – Rotas inbound** | Cadastrar rotas públicas que recebem dados do exterior. | Ao disponibilizar um serviço REST para parceiros enviarem dados. |
| **THL0010 – Parâmetros de e‑mail** | Remetente, cópia, assunto e texto dos e‑mails por grupo. | Ao configurar alertas por e‑mail. |
| **THL0033 – Headers REST** | Cabeçalhos calculados exigidos por algumas APIs. | Configurado pela TI. |
| **THL0050 / THL0051 – Auditoria** | Tabelas auditadas, expurgo e notificação. | Ao ligar a auditoria de uma tabela. |
| **THL0150 – Consulta de auditoria** | Ver quem alterou o quê. | Investigação de alterações. |

## Rotinas de execução (tarefas)

Telas de parâmetros que disparam um processamento em RPW (execução agendada no servidor) e geram relatório.

| Programa | Função | Quando utilizar |
|---------|-------|----------------|
| **THL0210 – Expurgo de e‑mails** | Elimina o log de e‑mails enviados, por faixa de programa, mantendo os últimos *N* dias (**Manter Dias**). | Rotina periódica de limpeza. |
| **THL0220 – Reprocessamento outbound** | Reenvia em lote as mensagens de saída ainda não integradas, por faixa de código e objeto. | Após corrigir uma falha que afetou várias mensagens. |
| **THL0221 – Processamento inbound agendado** | Processa as mensagens de entrada recebidas com forma de execução *Agendar*. | Normalmente agendado; manualmente para destravar a fila. |
| **THL0222 – Expurgo de mensagens** | Elimina mensagens integradas há mais de *N* dias (**Manter Dias**), por faixa de código e objeto (entrada e saída). | Rotina periódica de limpeza. |
| **THL0250 – Expurgo da auditoria** | Elimina registros de auditoria além da retenção cadastrada para cada tabela (THL0051); a tela só pede a faixa de banco e tabela. | Rotina periódica; confira antes os prazos legais de guarda. |

## Como cadastrar um novo objeto de integração

1. **Abra o THL0021** e clique em *Incluir*.  
2. Informe o código do objeto (sem espaços), a descrição e marque se gera histórico ou se é outbound/inbound.  
3. No **THL0022**, selecione o objeto cadastrado e inclua as operações disponíveis, indicando o método (GET, POST, etc.) e parâmetros.  
4. Se necessário, cadastre usuários autorizados na aba de usuários.  
5. Preencha também os cadastros de conexão e rotas conforme o tipo de integração.

## Como consultar mensagens e reprocessar

1. **THL0120** – A tela principal para consulta de mensagens.  Filtre por data, objeto ou situação.  
2. Clique com o botão direito para **consultar detalhes**.  Visualize os itens (chaves de registro) e o conteúdo enviado/recebido.  
3. Em caso de erro, corrija dados ou configurações e use o **reenvio**. O **THL0120** tem a opção de **reenvio** para mensagens de **saída (outbound)**: selecione a mensagem e confirme o reenvio. Mensagens de **entrada (inbound)** não são reenviadas pela tela — o sistema externo deve reenviar, ou a TI trata o caso. Reprocessamento em lote é feito pela TI via RPW (THL0220).

## Como consultar e‑mails enviados

1. **THL0110** – Utilize essa tela para localizar e‑mails automáticos enviados pela biblioteca.  
2. Filtre por data, remetente ou destinatário.  
3. Abra o registro para ver o assunto, corpo e status do envio.

## Perguntas frequentes (FAQ)

* **Por que minha integração não funcionou?**  Consulte o monitor `THL0120` e veja a situação e o retorno.  Verifique se as conexões e parâmetros estão corretos.
* **Posso cadastrar variáveis diferentes por ambiente?**  Sim, use o THL0002 na aba *Variável* para informar valores diferentes por ambiente.
* **Como sei se um objeto é inbound ou outbound?**  No cadastro do objeto (THL0021), o campo *Sentido Fluxo* indica a direção.  `Sim` para outbound, `Não` para inbound.
* **Preciso alterar o código para mudar a URL da API?**  Não.  Basta editar a URL base no THL0030 e os paths no THL0031.  As classes usarão a nova configuração automaticamente.
* **Quando devo acionar a equipe de TI?**  Se uma mensagem permanecer em erro mesmo após reprocessar, ou se houver falhas na obtenção de token/autenticação.  Envie os detalhes da mensagem e da configuração para análise.

Este guia resume o uso funcional da THL e deve ser compartilhado com analistas de negócio e usuários técnicos que interagem com o ERP.
