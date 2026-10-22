# Medição de Contrato (cn0302a) — validações e gravações existentes nas UPCs

> Fonte: `C:\Users\Lopes\Desktop\Nova pasta` (UPCs `escn0302a-u00` a `u06`). Leitura estática, nada executado. Referências em `arquivo:linha`.
> DVV/DEX ignorados (ver final). A pasta **não** contém a tela/BO padrão de `medicao-contrat`; só constam regras das UPCs.
> Todas as regras abaixo rodam em eventos de VIEWER (tela): nenhuma é garantida por BO.

## 1. Validações existentes

Mensagens via `utp/ut-msgs.p` código 17006 (texto livre), salvo indicação. Todas são customizadas.

| # | Entidade/Campo | Regra | Mensagem | Bloqueante | Ref. |
|---|---|---|---|---|---|
| V-01 | Fornecedor do contrato (`es_fornec.inativo`) | Acha `contrato-for` pelo nº do contrato e `es_fornec` por `cod_emitente = contrato-for.cod-emitente`. Se `inativo = 1`, rejeita. Se não achar `es_fornec`, passa. | `MESSAGE`: "FORNECEDOR INATIVO !! / Não será possível incluir/ alterar o Contrato para este Fornecedor!" | Sim (`RETURN "NOK"`) | `u01:29-45` |
| V-02 | Fornecedor informado existe | Se difere do fornecedor do contrato e não existe `emitente` com o código, rejeita. | "Fornecedor informado não encontrado." | Sim | `u03:344-349,361-369` |
| V-03 | Fornecedor — mesma matriz | Se difere do fornecedor do contrato, `emitente.nome-matriz` dos dois deve ser igual. | "Fornecedores deveram ser da memsa Matriz." | Sim | `u03:349-359` |
| V-04 | Fornecedor obrigatório | Código `= ?` ou `= 0` rejeita. Antes, `0` é trocado pelo fornecedor do contrato (`:312-314`). | "Obrigatório informar Fornecedor para medição contratos" | Sim | `u03:312-314,372-381` |
| V-05 | Nota Fiscal (contrato de serviço) | `contrato-for.natureza = 2` e NF `= ?` ou `= 0` rejeita. | "Obrigatório informar nota fiscal para contratos de serviços" | Sim | `u03:384-395` |
| V-06 | Dt. Vencimento (contrato de serviço) | `natureza = 2` e data vazia rejeita. | "Obrigatório informar data de validade para contratos de serviços" | Sim | `u03:397-405` |
| V-07 | Nota Fiscal (demais naturezas) | `natureza <> 2` e NF preenchida rejeita. | "Para contratos do tipo Compras, não preencher o campo Nr.Nota" | Sim | `u03:407-416` |
| V-08 | Dt. Vencimento (demais naturezas) | `natureza <> 2` e data preenchida rejeita. | "Para contratos do tipo Compras não preencher a Data Vencimento" | Sim | `u03:417-425` |
| V-09 | Chave por estabelecimento | Se existe `PARAM_rpa_recebimento` do estabelecimento do contrato com `nf_servico = NO`, o `VALIDATE` do `u03` sai (`LEAVE`) antes das regras V-02 a V-15 e não habilita a gravação do item 2.1. Sem o parâmetro, as regras valem. | sem mensagem | desvio | `u03:296-305` |
| V-10 | Dt. Vencimento ≥ hoje | `dt-vencto < TODAY` rejeita (data vazia não dispara). | "Data de vencimento informada menor que a data de hoje." | Sim | `u03b:114-119` |
| V-11 | Dt. Vencimento > hoje + 6 | `dt-vencto <= TODAY + 6` rejeita (mínimo aceito: hoje + 7). | "Data de vencimento informada maior que o prazo de 6 dias." | Sim | `u03b:121-126` |
| V-12 | Dt. Vencimento ≥ data do contrato | `dt-vencto < contrato-for.dt-contrato + cond-pagto.prazos[1]` rejeita (`cond-pagto` do contrato). | "Data de vencimento informada menor que a data Calculada no contrato" + datas informada e calculada | Sim | `u03b:38-44,128-135` |
| V-13 | Duplicidade de NF no RPA (emitente de cidade SÃO PAULO/SAO PAULO/SANTOS) | Procura `integra_rpa` por estabelecimento do contrato + fornecedor da tela + `nro_docto` = NF (como digitada; senão com máscara `>>>>>>>>9999999`), sem filtro de série. Se achar, exibe a situação e faz `RETURN "NOK"`. | "Nota Fiscal informada já cadastrada no RPA para este Fornecedor, com situação …" | **Pretendida: sim. Efetiva: não** — `u03c` não zera `l-cn0302a-gravar` e `u03` ignora o retorno (`u03:431,434-439`) | `u03c:56-87` |
| V-14 | Saldo da NF (mesmo caso de V-13) | Saldo = Σ(`QTD_NF × PRECO_UNIT_NF`) dos itens da NF − Σ(`val-medicao`) das medições já ligadas à NF (`es_ext_medicao_contrat`). Rejeita se `saldo < val-previsto`. | "Valor previsto da medição maior do valor calculado da NF." | Pretendida: sim. **Inalcançável**: só roda se a NF existe, mas então V-13 já encerrou a rotina (`u03c:86`) | `u03c:102-148` |
| V-15 | Ajuste do vencimento pela NF (mesmo caso de V-13) | NF achada em `integra_rpa` (fornecedor **do contrato**) com `situacao_nf = '1'` e `dt-vencto < integra_rpa.data_vencto`: substitui a data da tela. Não é erro. | sem mensagem | Não | `u03b:66-71,86-104` |

Execução: `u01` e `u03` rodam no `VALIDATE`. Em `u03`, após V-02 a V-08, se o emitente é SP/Santos chama `u03a` e `u03c` (`u03:429-432`); depois, se a gravação segue habilitada, chama `u03b` (`:434-436`); `l-cn0302a-gravar = NO` gera `RETURN 'NOK'` (`:439`). `u03a` não valida nada (bloco comentado, `u03a:62-123`). `u03b` também roda no LEAVE do campo vencimento (`u03:137`).

Falhas por runtime (sem mensagem): `FIND contrato-for` sem `NO-ERROR` (`u03:316-317`, `u03a:40-41`, `u03b:38-39`, `u03c:47-48`), `FIND cond-pagto` sem `NO-ERROR` (`u03:318-319`, `u03a:43-44`, `u03b:41-42`), `FIND medicao-contrat` sem `NO-ERROR` (`u03:334-335`).

## 2. Gravações em tabelas existentes

Não há `DO TRANSACTION`/`UNDO` nas UPCs. A gravação padrão de `medicao-contrat` e o número `num-seq-medicao` não estão na pasta; as UPCs só leem esse número da tela.

### 2.1 `ASSIGN` do viewer (`u03` e `u04`)

| Tabela | Campo | Origem do valor | Obrigatório | Ref. |
|---|---|---|---|---|
| `es_ext_medicao_contrat` (busca por `cod_estabel` do contrato + 5 campos de chave; **cria se não existir**; só grava se V-09 não desviou) | `nr_contrato` | Tela `i-nr-contrato` | Sim (chave) | `u03:231-243` |
| | `num_seq_item` | Tela `i-num-seq-item` | Sim (chave) | `u03:244` |
| | `numero_ordem` | Tela `i-numero-ordem` | Sim (chave) | `u03:245` |
| | `num_seq_event` | Tela `num-seq-event` | Sim (chave) | `u03:246` |
| | `num_seq_medicao` | Tela `num-seq-medica(o)` | Sim (chave) | `u03:247` |
| | `nr_nota_fis` | Tela, NF (string do fill-in, máscara `>>>>>>>>9999999`) | V-05/V-07 | `u03:250,103-104` |
| | `dt_Vencto` | Tela, Dt. Vencto | V-06/V-08 | `u03:251` |
| | `cod_estabel` | `contrato-for.cod-estabel` | Derivado | `u03:252` |
| | `serie` | Constante `'A'` | Derivado | `u03:253` |
| | `cod_emitente` | Fornecedor da tela; se 0, `contrato-for.cod-emitente` | Sim | `u03:254,307,312-314` |
| `integra_rpa_item` (**só atualiza**, e só o 1º item, se achar `integra_rpa` por `cod_estabel` + `cod_emitente` + `nro_docto` = NF + `serie_docto = 'A'`; item por `cod_estabel` + `chave_nf`) | `QTD_CONTADA` | Tela `qtd-prevista` | Condicional | `u03:266-275` |
| | `NR_ORDEM_COMPR` | `ordem-compra.numero-ordem` (busca por contrato + estabelecimento + `num-seq-item`) | Condicional | `u03:261-264,276` |
| | `NR_PEDIDO` | `STRING(ordem-compra.num-pedido)` | Condicional | `u03:278` |
| | `NR_CONTRATO` | `ordem-compra.nr-contrato` | Condicional | `u03:279` |
| | `NUM_SEQ_ITEM` | Tela | Condicional | `u03:280` |
| | `NUM_SEQ_MEDICAO` | Tela | Condicional | `u03:281` |
| `es_mla_lotacao_docto` (**cria se não existir** e atualiza) | `ep_codigo` | `estabelec.ep-codigo` do `c-cod-estabelec` da tela | Sim (chave) | `u04:152-160` |
| | `cod_estabel` | Tela `c-cod-estabelec` | Sim (chave) | `u04:161,181` |
| | `chave_docto` | Contrato (pos. 1-8), item (10-14), ordem (15-22), evento (23-26), medição (27-30) | Sim (chave) | `u04:162,189-193` |
| | `cod_tip_doc` | Constante `14` | Derivado | `u04:163,194` |
| | `cod_lotacao` | Valor do combo Lotação (opção em branco = `"0"`) | Sem validação | `u04:172,208` |

### 2.2 `AFTER-END-UPDATE` do viewer (`u06`)

| Tabela | Campo | Origem do valor | Obrigatório | Ref. |
|---|---|---|---|---|
| `rpa_nf_xml` (busca por `cod-estabel` + `nro-docto` + `dt-emissao` + `cgc`; **atualiza se existir, senão cria**) | `cod-estabel` | Tela `c-cod-estabelec` | Chave | `u06:164,178` |
| | `nro-docto` | Tela, NF | Chave (sem teste de vazio) | `u06:165,179` |
| | `dt-emissao` | Tela, "Data Previsão" | Chave | `u06:166,180` |
| | `cgc` | `emitente.cgc` do fornecedor da tela | Chave | `u06:167,181` |
| | `valor-servico` | Tela `val-previsto` | — | `u06:169,182` |
| | `narrativa` | Tela `observacao` | — | `u06:170,183` |
| | `utilizada` | Constante `YES` | Derivado | `u06:171,184` |
| | `preenchimento` | `2` se `g-preenchimento-manual = YES`, senão `1` | Derivado | `u06:172,185` |

Se o fornecedor da tela não existe em `emitente`, nada é gravado em `rpa_nf_xml` (`u06:162`).

### 2.3 Origem do valor de `dt_Vencto` (calculado antes, na tela)

Fornecedor que **não** é representante (`representante.cod_id_feder = emitente.cgc`) e `natureza <> 1`: `u05` calcula o vencimento a partir da data prevista, da condição de pagamento do pedido da ordem (`pedido-compr` → `cond-pagto`; senão `cond-especif`) e de `es-vencimentos-param` (`ep_codigo = v_cod_empres_usuar`, faixa de dias → `dia_pagamento`), garantindo data acima de hoje + 6 (`u05:65-83,170-362`). Representante: campo vazio e informado pelo usuário (`u05:80-83`).

## 3. Dependências excluídas (DVV/DEX)

Apenas registradas, sem análise:

- `escn0302a-u00.p:25-35`: chamada de `escn0302a-u02.p`, executada entre `u01` e `u03`.
- `escn0302a-u02.p` (inteiro): eventos `ASSIGN` (`:166-396`) e `AFTER-ASSIGN-RECORD` (`:399-433`) na mesma cadeia; podem devolver `"NOK"` (`:196,213`).
- `escn0302a-u02a.p` (inteiro), `escn0302a-u02-btok.p` e `escn0302a-u02-btsave.p` (inteiros): botões OK/Salvar substitutos; copiam a data falsa de `u06` para `dat-prev-medicao` (`btok:37`, `btsave:33`).

## 4. Pontos a confirmar (apenas os que afetam as regras acima)

1. Programa padrão (tela/BO) que cria `medicao-contrat` e gera `num-seq-medicao`: fora da pasta.
2. `upc/upc-cn0302a.p` (`u00:47`): UPC fora da pasta, executada entre `u03` e `u04`.
3. `u00` não testa o `RETURN-VALUE` dos `RUN` (`u00:18-77`): o efeito de bloqueio dos `"NOK"` depende de como a tela lê o retorno.
4. V-13: o código mostra a mensagem mas não bloqueia; confirmar a intenção. V-14 é inalcançável.
5. `LEAVE` em `u03:301` (V-09) fora de loop: confirmar que encerra a rotina.
6. Momento do evento `ASSIGN` em relação à criação de `medicao-contrat` e valor de `num-seq-medicao` na tela em inclusão.
7. Domínio de `contrato-for.natureza` (só 1 e 2 aparecem) e escopo da transação das gravações.
