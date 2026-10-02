# Guia de reprocessamento de mensagens

> Revisado em 2026-09-24 contra o código e o `thl.df` disponível. Padrão do projeto: fontes ABL em **ISO-8859-1**.

Este guia explica como reprocessar mensagens na THL‑Lib.  Reprocessar significa tentar novamente uma integração que falhou por motivos temporários (erro de conexão, indisponibilidade do serviço externo, etc.).

## Tabelas envolvidas

* **thl-mensagem** – Armazena o registro principal da mensagem, incluindo seu estado atual (`sit-requisicao`, `sit-retorno`, `sit-processamento`), número de tentativas (`qtd-tentativas`) e datas (`dt-criacao`, `dt-integracao`).  
* **thl-mensagem-historico** – Guarda o histórico de cada tentativa de envio/processamento.  Permite ver quantas vezes a mensagem foi reprocessada e os detalhes de cada tentativa.  
* **thl-mensagem-item** – Contém as chaves de registro da mensagem.  Não sofre alterações no reprocessamento.  
* **thl-mensagem-conteudo** – Armazena o payload enviado e recebido.  Um novo conteúdo é adicionado a cada tentativa.

## Cenários de reprocessamento

1. **Erro de transporte** – A requisição não chegou ao sistema externo devido a falha de rede ou time‑out.  
2. **Erro de autenticação** – O token expirou ou é inválido.  
3. **Erro de negócio** – O sistema externo retornou código de erro (4xx ou 5xx).  Dependendo da causa, pode ou não ser reprocessado.

## Como reprocessar

1. **Identificar a mensagem** – Use o programa **THL0120** para pesquisar mensagens com situação de requisição ou retorno igual a *Erro*.  Aplique filtros por data, objeto, operação ou código.  
2. **Ver detalhes** – Selecione a mensagem e utilize o botão direito para abrir a consulta detalhada.  Verifique o histórico, as tentativas e o motivo do erro.  
3. **Avaliar o erro** – Determine se é um erro temporário (rede, autenticação) ou permanente (dados inválidos).  Somente mensagens recuperáveis devem ser reprocessadas.  
4. **Executar reprocessamento**:
   * **Manual (tela)** – O monitor `THL0120` tem a opção de **reenvio**, disponível **só para mensagens de saída (outbound)**. Ela recria a mensagem a partir de `thl-mensagem.pacote` + objeto e reenvia pelo `OutboundMessageService`.  
   * **Manual (código)** – `new OutboundMessageService( aplicacao, objeto, operacao ):reprocess( codigo-mensagem )` — processa em modo ONLINE; lança erro se a mensagem estiver configurada como SCHEDULE.  
   * **Em lote (RPW)** – `thl0220rp.p` (tela **THL0220**) percorre `thl-mensagem` e chama `reprocess` para cada mensagem selecionada. É também o runner do agendamento outbound (`thl0220z.p`), que até 2026-09-25 apontava por engano para o expurgo.  
   * **Inbound agendado** – mensagens inbound com `forma-execucao = SCHEDULE` são processadas pelo RPW `thl0221rp.p` (`InboundMessageService:processScheduled`).  
   * ⚠️ **Não há reenvio automático por tentativas**: `thl-objeto-parametro` tem `qtd-tentativas-persist`/`qtd-dias-persist`/`ind-persistente` (cadastro em thl0022), mas esses campos **não são usados pela `thl-lib`** hoje.  
5. **Acompanhar resultado** – Após a tentativa, verifique novamente a situação.  Um novo registro em `thl-mensagem-historico` será criado.  Caso persista o erro, ajuste as configurações ou corrija os dados antes de tentar novamente.

## Boas práticas

* **Definir limites de tentativas** – O controle hoje é operacional (acompanhar `thl-mensagem.qtd-tentativas`); os campos de persistência de `thl-objeto-parametro` ainda não têm efeito no código.  
* **Enviar alertas** – Configure e‑mails automáticos quando uma mensagem atingir o número máximo de tentativas.  
* **Analisar causas raiz** – Não basta reprocessar; investigue a causa do erro para evitar repetição.  
* **Registrar todas as tentativas** – A THL‑Lib já grava o histórico automaticamente; não remova registros.  
* **Não reprocessar mensagens com erro de validação de dados** – Corrija os dados na origem antes de reprocessar.

Com este guia, equipes de suporte podem tratar falhas de integração de forma eficaz e com rastreabilidade completa.
