# Guia de monitoramento de mensageria

> Revisado em 2026-09-24 contra o código e as telas atuais. Só aparecem no monitor as mensagens de objetos em que o usuário está cadastrado (THL0022, aba Usuário).

Esta seção, voltada para analistas de negócio, mostra como acompanhar e controlar o fluxo de mensagens processadas pela THL‑Lib.

## Acessando o monitor

1. Abra o programa **THL0120 – Consulta de mensagens**.  
2. Utilize os filtros disponíveis:
   * **Data de criação** ou **Data de integração** – Limite o período das mensagens.  
   * **Objeto** – Selecione a entidade (ex.: `PEDIDO`).  
   * **Situação** – Escolha Pendente, Sucesso, Erro ou Todos.  
   * **Destino** – Filtre por URL ou código do destinatário.  
3. Clique em **Pesquisar** para listar as mensagens.

## Visualizando detalhes

1. Selecione uma mensagem na lista.  
2. Clique com o botão direito e escolha **Consulta detalhada**.  
3. A tela mostrará:
   * **Itens** – Chaves de registro que compõem a mensagem (tabela `thl-mensagem-item`).  
   * **Conteúdo** – Payload enviado e recebido (`thl-mensagem-conteudo`).  
   * **Histórico** – Tentativas realizadas com datas, situação de requisição, retorno e descrição (`thl-mensagem-historico`).

## O que fazer em caso de erro

1. **Verificar a descrição do erro** – O campo *descr-retorno* indica a causa (ex.: *Token expirado*, *Campos obrigatórios ausentes*).  
2. **Corrigir a causa** – Se for problema de configuração (URL incorreta, falta de token), ajuste os cadastros.  Se for problema de dados (campos inválidos), corrija o registro no ERP.  
3. **Reprocessar** – Após corrigir, reenvie a mensagem. O **THL0120** tem a opção de **reenvio** para mensagens de **saída (outbound)**: selecione a mensagem e confirme o reenvio. Mensagens de **entrada (inbound)** não são reenviadas pela tela — o sistema externo deve reenviar, ou a TI trata o caso. Reprocessamento em lote é feito pela TI via RPW (THL0220).  
4. **Monitorar** – Verifique se a mensagem muda para *Sucesso*.  Se continuar em erro, acione suporte técnico.

## Interpretando situações

* **Pendente** – A mensagem está aguardando envio ou processamento.  Pode ocorrer em integrações assíncronas ou com agendamento.  
* **Sucesso** – A mensagem foi processada com êxito e o retorno foi positivo.  
* **Erro** – Houve falha durante o envio ou processamento.  Verifique o histórico e a descrição do retorno.  
* **Não aplicável** – Situação que não se aplica à mensagem (ex.: consultas que não geram retorno).  

## Dicas para melhor utilização

* **Use filtros inteligentes** – Em ambientes com grande volume, filtre por objeto e data para encontrar rapidamente mensagens relacionadas a um processo específico.  
* **Exportar relatórios** – Alguns monitores permitem exportar dados para análise em planilhas; utilize para acompanhar indicadores de desempenho.  
* **Documentar ocorrências** – Registre em chamados as mensagens que necessitaram reprocessamento ou ajustes, informando código da mensagem e data/hora.  
* **Trabalhar em conjunto com TI** – Analistas e equipe técnica devem alinhar as causas de erros para que correções sejam efetivas.

Com este guia, os analistas de negócio podem monitorar integrações de forma eficiente, identificar problemas e colaborar com a equipe técnica na resolução.
