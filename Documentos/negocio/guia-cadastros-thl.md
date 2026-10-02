# Guia de cadastros da THL

> Revisado em 2026-09-24 contra o código e as telas atuais.

Este guia detalha como utilizar cada cadastro da biblioteca THL para configurar integrações e serviços.  Os passos estão descritos de forma prática para usuários de negócio.

## THL0001 – Cadastro de ambientes

1. Acesse o programa `THL0001`.  
2. Clique em **Incluir** para adicionar um novo ambiente.  
3. Preencha:
   * **Código** – Sigla do ambiente (ex.: `PROD`, `HOMO`).  
   * **Nome** – Nome descritivo (ex.: `Produção`, `Homologação`).  
   * **IP Ambiente** – Endereço IP ou host do servidor.  
4. Salve e repita para todos os ambientes em uso.

## THL0002 – Parâmetros e variáveis

1. Entre no programa `THL0002`.  
2. Na **Aba Variável**, clique em *Incluir* para cadastrar variáveis específicas de um parâmetro e ambiente.
   * Escolha o **Código do ambiente** e o **Código do parâmetro** (já cadastrado).  
   * Informe o **Código da variável**, **Descrição** e **Valor** (pode ser um texto ou número).  
3. Na **Aba Programa**, clique em *Incluir* para associar um parâmetro a um programa Datasul.  
   * Selecione o **Código do parâmetro** e o **Código do programa**.  
4. Use a **aba principal** para cadastrar os parâmetros de ambiente em `thl-ambiente-param`.

## THL0011 – Grupo de e‑mail

1. No `THL0011`, clique em *Incluir* e crie um grupo.  Informe o **Código do grupo** e a **Descrição**.  
2. Selecione o grupo criado e vá para a **Aba Usuário** (programa `thl-ambiente-param-grupo-usuar`).  Clique em *Incluir* e informe:
   * **Código do usuário** do ERP.
   * **E‑mail alternativo**, se diferente do cadastrado no usuário.

## THL0020 – Aplicação

1. Acesse `THL0020` e clique em *Incluir*.
2. Informe o **Código** da aplicação (o sistema externo, ex.: Loog.ai, Ninahub) e a **Descrição**. O código não pode ser alterado depois de gravado.
3. No cadastro do objeto (`THL0021`), o campo *Aplicação* tem pesquisa (**F5** ou duplo clique) nesta lista e mostra a descrição ao lado.

## THL0021 – Objeto de integração

1. Acesse `THL0021`.  
2. Clique em *Incluir*.  Preencha:
   * **Objeto** – Código do objeto (ex.: `PEDIDO`).
   * **Programa Consulta** – Programa do ERP para consultar o objeto (opcional).  
   * **Sentido Fluxo** – Marque *Sim* para outbound, *Não* para inbound.  
   * **Aplicaçao** – Nome da aplicação (ex.: `Vendas`).  
   * **Classe Objeto** – Classe na THL‑Lib que implementa a integração.  
   * **Gera Histórico** – Marque se deseja gravar histórico de todas as execuções.  
3. Salve.

## THL0022 – Métodos e usuários

1. Selecione o objeto cadastrado no THL0021 e acesse `THL0022`.  
2. Na **Aba Método** (programa `thl-objeto-parametro`), clique em *Incluir* para adicionar operações:
   * **Método** – Código: **1=POST, 2=PUT, 3=PATCH, 4=DELETE, 5=GET**.  
   * **Forma de Execução** – **1=Online** (na hora), **2=Agendar** (processado depois por RPW), **3=Batch**.  
   * **Código Param. Ambiente** – Parâmetro utilizado.  
   * **Frequência Execução** e campos de persistência/tentativas – existem no cadastro, mas **hoje não geram reenvio automático** (a biblioteca não os utiliza).  
   * Demais campos conforme necessidade (histórico, log de requisição, mensagem simples).  
3. Na **Aba Usuário**, cadastre os usuários que podem **acompanhar** as mensagens do objeto: os monitores (THL0120, THL0220, THL0221, THL0222) e o app web só mostram mensagens de objetos em que o usuário está cadastrado.

## THL0030 – Conexão REST

1. Entre no `THL0030` e clique em *Incluir*.  
2. Informe **Código**, **Descrição**, **URL Base** e marque se a conexão exige autenticação.  

## THL0031 – Path da conexão

1. No `THL0031`, clique em *Incluir*.  
2. Escolha a **Conexão** cadastrada no THL0030.  
3. Preencha **Código do path**, **Descrição**, **Path** relativo, **Content‑Type**, **Accept**, **Timeout**, **Parameters** e **Headers**.  

## THL0032 – Autenticação REST

1. Se a conexão do THL0030 requer autenticação, cadastre as informações em `THL0032`.  
2. Selecione a **Conexão** e preencha:
   * **URL Token** – Endpoint que retorna o token.
   * **Headers/Parameters Token** – JSON com campos exigidos.  
   * **Tipo Autenticação** – (ex.: Bearer).  
   * **Usuário/Senha** – Credenciais básicas.  
   * **Ind Requisita Token** – Marque *Sim* para renovar automaticamente.  
   * **Classe Parser Token** – (opcional) classe que extrai o token do retorno.

## THL0040 – Rotas inbound

1. No `THL0040`, clique em *Incluir*.  
2. Preencha **Código da rota**, **Rota Pública** (ex.: `usuario`), selecione o **Objeto**/**Aplicação** e marque *Ativo* se a rota deve aceitar requisições. O endereço final fica `…/api/thl/integration/v1/resourcen/<rota-publica>`.  

## Outros cadastros

* **THL0010 – Parâmetros de e‑mail**: remetente, cópia, assunto e mensagem por grupo de e‑mail.  
* **THL0033 – Headers calculados da conexão REST**: classe e parâmetro para APIs que exigem cabeçalhos gerados (ex.: assinatura) — preenchido pela TI.  
* **THL0050 / THL0051 – Auditoria**: tabelas auditadas, acesso, campos, notificação e **retenção** (dias que o histórico é mantido). A consulta dos registros de auditoria é feita no **THL0150** e a limpeza pela retenção no **THL0250**.

Com estes cadastros preenchidos corretamente, a THL‑Lib estará apta a processar integrações de maneira controlada.  Para suporte, consulte o monitor de mensagens e o guia de operação.
