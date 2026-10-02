# Guia de monitoramento técnico da THL‑Lib

> Revisado em 2026-09-24 contra o código e o `thl.df` disponível. Padrão do projeto: fontes ABL em **ISO-8859-1**.

Monitorar a THL‑Lib é essencial para garantir a saúde das integrações e agir rapidamente em caso de falhas.  Este guia apresenta as principais ferramentas e rotinas de monitoramento.

## Monitores e programas

### THL0120 – Consulta de mensagens

* Permite filtrar mensagens por data, objeto, operação, situação ou destino.  
* Use a opção **Consulta detalhada** (botão direito) para ver o conteúdo enviado/recebido, as chaves de registro (`thl-mensagem-item`) e o histórico de tentativas.  
* Situações:
  * **Pendente** – A mensagem ainda não foi enviada ou processada.  
  * **Sucesso** – A integração ocorreu sem erros.  
  * **Erro** – Houve falha; verifique o histórico para detalhes.  
  * **Não aplicável** – Situação não se aplica (ex.: consulta sem retorno).  

### THL0110 – Consulta de e‑mails

* Exibe registros de `thl-email` com filtros por remetente, destinatário, assunto e data.  
* Permite abrir cada e‑mail para ver o corpo, anexos e o retorno do servidor SMTP ou API de e‑mail.  

### Programas de cadastro (faixa `thl0xxx`: `thl0001` a `thl0051`)

* Embora não sejam monitores, os cadastros podem indicar problemas de configuração (ex.: conexões inativas, rotas desativadas, métodos inativos).  Verifique campos `ind-ativo` ou `ind-inativo`.  

### Rotinas de limpeza (RPW)

* `THL0222` (mensagens, `thl0222rp.p`), `THL0210` (e‑mails, `thl0210rp.p`) e `THL0250` (auditoria, `thl0250rp.p`) eliminam registros antigos; cada exclusão é uma transação curta. Agende-as fora do horário de pico e confira o relatório: o `THL0250` lista por tabela a retenção aplicada e a quantidade eliminada, e grava `dt-ultima-execucao` em `thl-audit-tabela-purge`.

## Indicadores importantes

* **Quantidade de mensagens com erro** – Acompanhe o número de mensagens com estado *Erro* em `thl-mensagem`.  Aumento repentino pode indicar falha generalizada.  
* **Tempo médio de integração** – Calcule a diferença entre `dt-criacao` e `dt-integracao`.  Tempos muito altos podem indicar lentidão na API externa.  
* **Tentativas** – `qtd-tentativas` em `thl-mensagem` (incrementado a cada gravação de resultado; cada tentativa gera um registro em `thl-mensagem-historico`) ajuda a identificar mensagens que exigem atenção manual.  
* **E-mails de alerta pendentes** – Mensagens que enviaram alertas via e‑mail devem ser monitoradas para assegurar que os destinatários tenham recebido e que as ações corretivas foram tomadas.

## Procedimentos de operação

1. **Verificar diariamente o monitor** – Consulte `THL0120` e filtre por mensagens com erro.  
2. **Analisar e registrar causa** – Abra a consulta detalhada, verifique a mensagem de retorno e classifique a causa (rede, autenticação, dados).  
3. **Corrigir e reprocessar** – Ajuste os dados ou a configuração e reprocessar conforme o guia de reprocessamento.  
4. **Acompanhar e‑mails** – Verifique `THL0110` para garantir que alertas foram enviados.  
5. **Atualizar cadastros** – Periodicamente, revise conexões, rotas e objetos inativos.  Desative cadastros que não são mais utilizados para evitar envios desnecessários.

## Ferramentas externas

* **Logs de aplicação** – Além das tabelas, verifique o log do agente (`LogUtil` escreve no log manager da sessão/PASOE). `AuditLogService` não gera arquivo: grava em `thl-audit-registro`/`-detalhe` (consulta em **THL0150**).  
* **Monitor web** – O app `Fontes\web` (mensageria, e-mail, auditoria e métricas) consome o mesmo endpoint REST.  
* **Monitor de performance** – Use ferramentas de monitoramento de servidor para acompanhar consumo de CPU, memória e tempo de resposta das APIs externas.  
* **Alertas automatizados** – Integre a THL‑Lib com sistemas de monitoramento (ex.: Zabbix, PagerDuty) enviando e‑mails ou eventos customizados quando falhas ocorrerem.

Com essas rotinas, a equipe técnica pode garantir que as integrações da THL‑Lib permaneçam confiáveis e tomar medidas proativas em caso de falhas.
