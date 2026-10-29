# Brief de codificação — criação de Medição de Contrato (regras extraídas das UPCs cn0302a)

Insumo para uma sessão de codificação. Origem: [regras-medicao.md](regras-medicao.md) (UPCs `escn0302a-u00` a `u06`, com referências `arquivo:linha`). Só constam regras **já existentes** nos programas. Siga `AGENTS.md` e a skill `thl-coding`.

## 0. Limites do que se sabe

- A tela/BO padrão que grava `medicao-contrat` e gera `num-seq-medicao` **não foi analisada**. O código novo deve chamar essa camada padrão (a definir pelo responsável) e aplicar apenas as regras abaixo, antes e depois dela.
- As regras originais leem widgets de tela e variáveis globais. **Reimplemente em classe própria**; não invoque as UPCs.
- DVV/DEX estão fora de escopo. Não implemente nada relacionado.
- Mensagens originais usam `utp/ut-msgs.p` código 17006 com texto livre. No endpoint, devolver erro estruturado (campo, código, mensagem) mantendo o texto original da coluna "Mensagem".

## 1. Entrada considerada pelas regras

| Dado | Uso nas regras |
|---|---|
| `nrContrato`, `numSeqItem`, `numeroOrdem`, `numSeqEvent` | Chave da medição e localização de `ordem-compra` |
| `numSeqMedicao` | Gerado pela camada padrão (fora do escopo); entra na chave das gravações |
| `datPrevMedicao` | Base do cálculo de vencimento |
| `valPrevisto`, `qtdPrevista` | Gravados em `rpa_nf_xml.valor-servico` e `integra_rpa_item.QTD_CONTADA` |
| `observacao` | `rpa_nf_xml.narrativa` |
| `responsavel` | Define as lotações permitidas (só no combo original; ver pendência P-3) |
| `codEmitente` (opcional) | Fornecedor da medição; se vazio/0, usa o do contrato |
| `nrNotaFis`, `dtVencto` | Regras V-05 a V-12 |
| `codLotacao` (opcional) | Gravado em `es_mla_lotacao_docto` |
| `codEstabel` | Derivado de `contrato-for.cod-estabel` (`c-cod-estabelec` da tela) |

## 2. Validações a implementar (nesta ordem)

Todas bloqueantes, exceto onde indicado. `C` = `contrato-for` do `nrContrato`; `F` = fornecedor da medição (`codEmitente`, ou `C.cod-emitente` se 0).

| # | Regra | Mensagem | Ref. original |
|---|---|---|---|
| V-01 | Se existe `es_fornec` com `cod_emitente = C.cod-emitente` e `inativo = 1`, rejeitar. Sem `es_fornec`, passa. | FORNECEDOR INATIVO !! / Não será possível incluir/ alterar o Contrato para este Fornecedor! | `u01:29-45` |
| V-09 | Buscar `PARAM_rpa_recebimento` por `cod_estabel = C.cod-estabel`. Se existir e `nf_servico = NO`, **pular V-02 a V-15 e não executar as gravações da seção 3.1** (`es_ext_medicao_contrat` e `integra_rpa_item`). Se não existir, aplicar tudo. | — | `u03:296-305` |
| V-04 | `F` obrigatório: se `codEmitente` = 0, assumir `C.cod-emitente`; se continuar 0/nulo, rejeitar. | Obrigatório informar Fornecedor para medição contratos | `u03:312-314,372-381` |
| V-02 | Se `F ≠ C.cod-emitente` e não existe `emitente` com `F`, rejeitar. | Fornecedor informado não encontrado. | `u03:344-349,361-369` |
| V-03 | Se `F ≠ C.cod-emitente`, `emitente(F).nome-matriz` deve ser igual a `emitente(C.cod-emitente).nome-matriz`. | Fornecedores deveram ser da memsa Matriz. | `u03:349-359` |
| V-05 | Se `C.natureza = 2`: NF nula ou 0 → rejeitar. | Obrigatório informar nota fiscal para contratos de serviços | `u03:384-395` |
| V-06 | Se `C.natureza = 2`: `dtVencto` vazia → rejeitar. | Obrigatório informar data de validade para contratos de serviços | `u03:397-405` |
| V-07 | Se `C.natureza <> 2`: NF preenchida (nula e 0 contam como vazio) → rejeitar. | Para contratos do tipo Compras, não preencher o campo Nr.Nota | `u03:407-416` |
| V-08 | Se `C.natureza <> 2`: `dtVencto` preenchida → rejeitar. | Para contratos do tipo Compras não preencher a Data Vencimento | `u03:417-425` |
| V-13 | **Só se** cidade de `emitente(F)` (em maiúsculas) ∈ {`SÃO PAULO`, `SAO PAULO`, `SANTOS`}: procurar `integra_rpa` com `cod_estabel = C.cod-estabel`, `cod_emitente = F`, `nro_docto` = NF (como informada; se não achar, com `TRIM(STRING(NF, ">>>>>>>>9999999"))`), sem filtro de série. Se achar, rejeitar informando a situação (tabela abaixo), nota, emitente e `tipo_nf`. Decisão pendente P-1. | Nota Fiscal informada já cadastrada no RPA para este Fornecedor, com situação <situação> | `u03c:56-87` |
| V-15 | **Só se** cidade SP/Santos: se existir `integra_rpa` por `cod_estabel`, `cod_emitente = C.cod-emitente`, série `'A'`, `nro_docto` = NF, com `situacao_nf = '1'` e `dtVencto < integra_rpa.data_vencto`, substituir `dtVencto` por `data_vencto` (ajuste, não erro). Executar antes de V-10 a V-12. | — | `u03b:66-71,86-104` |
| V-10 | `dtVencto < hoje` → rejeitar (vazia não dispara). | Data de vencimento informada menor que a data de hoje. | `u03b:114-119` |
| V-11 | `dtVencto <= hoje + 6` → rejeitar (mínimo aceito: hoje + 7). | Data de vencimento informada maior que o prazo de 6 dias. | `u03b:121-126` |
| V-12 | `dtVencto < C.dt-contrato + cond-pagto.prazos[1]` → rejeitar, com `cond-pagto` de `C.cod-cond-pag`. | Data de vencimento informada menor que a data Calculada no contrato (+ datas informada e calculada) | `u03b:38-44,128-135` |
| V-14 | **Só se** cidade SP/Santos **e** a NF existe em `integra_rpa` (`cod_estabel`, `nro_docto`, `cod_emitente = F`): saldo = Σ(`QTD_NF × PRECO_UNIT_NF`) dos `integra_rpa_item` (`cod_estabel`, `chave_nf`) − Σ(`medicao-contrat.val-medicao`) das medições ligadas por `es_ext_medicao_contrat` (`cod_estabel`, `cod_emitente`, `serie = integra_rpa.SERIE_DOCTO`, `nr_nota_fis = nro_docto`). Se `saldo < valPrevisto`, rejeitar. **Inalcançável no original**; ver P-2. | Valor previsto da medição maior do valor calculado da NF. (+ previsto e calculado) | `u03c:102-148` |

Situação de `integra_rpa.situacao_nf` (texto da mensagem V-13): 1 Baixado, 2 Validado, 3 Em Andamento, 4 Em Atualização, 5 NF Atualizada, 6 Erro Validação, 7 Erro Atualização, 8 NF Atualizada Manual, 9 Em Devolução, 10 Devolvido, 11 NF Finalizada (`u03c:67-77`).

Tratar como erro de negócio (e não de runtime) os casos em que o original usa `FIND` sem `NO-ERROR`: contrato inexistente, condição de pagamento do contrato inexistente (`u03:316-319`, `u03b:38-42`).

## 3. Gravações a implementar

### 3.1 Após criar `medicao-contrat` (camada padrão) — pular se V-09 desviou

**`es_ext_medicao_contrat`**: buscar por `cod_estabel = C.cod-estabel` + `nr_contrato` + `num_seq_item` + `numero_ordem` + `num_seq_event` + `num_seq_medicao`; criar se não existir. Atribuir (`u03:231-255`):

| Campo | Valor |
|---|---|
| `nr_contrato`, `num_seq_item`, `numero_ordem`, `num_seq_event`, `num_seq_medicao` | Chave da medição |
| `nr_nota_fis` | NF informada |
| `dt_Vencto` | `dtVencto` (após V-15) |
| `cod_estabel` | `C.cod-estabel` |
| `serie` | `'A'` |
| `cod_emitente` | `F` |

**`integra_rpa_item`** (só atualização, `u03:261-283`): localizar `ordem-compra` por `nr-contrato`, `cod-estabel` de `C` e `num-seq-item`. Localizar `integra_rpa` por `cod_estabel = C.cod-estabel`, `cod_emitente = F`, `nro_docto` = NF, `serie_docto = 'A'`, e o **primeiro** `integra_rpa_item` por `cod_estabel` + `chave_nf`. Se achar, atribuir:

| Campo | Valor |
|---|---|
| `QTD_CONTADA` | `qtdPrevista` |
| `NR_ORDEM_COMPR` | `ordem-compra.numero-ordem` |
| `NR_PEDIDO` | `STRING(ordem-compra.num-pedido)` |
| `NR_CONTRATO` | `ordem-compra.nr-contrato` |
| `NUM_SEQ_ITEM` | `numSeqItem` |
| `NUM_SEQ_MEDICAO` | `numSeqMedicao` |

Se `integra_rpa` não existir, não grava nada (sem erro). Se `ordem-compra` não existir, o original dá erro de runtime: tratar como erro de negócio.

### 3.2 `es_mla_lotacao_docto` (`u04:145-177,179-198`)

1. `ep_codigo` = `estabelec.ep-codigo` do `codEstabel`.
2. `chave_docto` = texto com `contrato` nas posições 1-8, `item` em 10-14, `ordem` em 15-22, `evento` em 23-26, `medição` em 27-30 (cada valor via `STRING`; posição 9 em branco).
3. Se não existir registro por (`ep_codigo`, `cod_estabel`, `chave_docto`), criar com `cod_tip_doc = 14`.
4. Atribuir `cod_lotacao` = `codLotacao` (no original, a opção em branco do combo vale `"0"`).

### 3.3 `rpa_nf_xml` (`u06:150-190`) — depois da medição gravada

1. Se o fornecedor `F` existe em `emitente`: buscar `rpa_nf_xml` por `cod-estabel` = `codEstabel`, `nro-docto` = NF, `dt-emissao` = data prevista, `cgc` = `emitente(F).cgc`.
2. Se achar, atualizar; senão criar com essa chave. Em ambos: `valor-servico` = `valPrevisto`, `narrativa` = `observacao`, `utilizada = YES`, `preenchimento` = `2` se preenchimento manual, senão `1`.
3. Se `F` não existe em `emitente`, não grava.

### 3.4 Valor de `dtVencto` quando não informado (origem na tela, `u05:65-83,170-362`)

Aplicar só se o fornecedor **não** é representante (`representante.cod_id_feder = emitente(F).cgc` não encontrado) e `C.natureza <> 1`; senão `dtVencto` é a informada.

1. Partida = `datPrevMedicao`. Condição de pagamento: `pedido-compr` (por `ordem-compra.num-pedido`) → `cond-pagto`; se não houver `cond-pagto`, usar `cond-especif.data-pagto[]` (1ª parcela preenchida) ou hoje; se também não houver, hoje.
2. Com `cond-pagto`: aplicar a mesma lógica de `cod-vencto` 5-8, `dia-mes-base`, `dia-sem-base`, `prazos[1]`, `dia-mes-venc`, `dia-sem-venc` do original (`u05:211-274`); usar só a 1ª parcela.
3. Ajuste: se resultado `< hoje`, reprogramar a partir de hoje + 1 e, se ainda `<= hoje + 6`, a partir de resultado + 1; se `<= hoje + 6`, reprogramar a partir do próprio resultado (`u05:281-303`).
4. Reprogramar: `es-vencimentos-param` com `ep_codigo` = empresa do usuário, `dia-vencto-ini <= dia <= dia-vencto-fin` e `dia_pagamento > 0`; nova data = `dia_pagamento` no mesmo mês (fevereiro: 28 se `dia_pagamento > 15`). Se `hoje + 6 >= data`, somar 2 dias e repetir a busca (`u05:307-362`).

## 4. Decisões e pendências para o responsável (não codificar sem resposta)

| # | Pendência |
|---|---|
| P-1 | V-13: o original mostra a mensagem mas **não bloqueia** (retorno ignorado em `u03:431`). Bloquear (intenção do texto) ou apenas avisar? |
| P-2 | V-14 é inalcançável no original. Implementar ou omitir? Na alteração, a soma inclui a própria medição se já vinculada. |
| P-3 | Origem de usuário e empresa no endpoint (`c-seg-usuario`, `v_cod_empres_usuar`), necessários para `responsavel`, lotações e `es-vencimentos-param`. |
| P-4 | Programa/BO padrão que cria `medicao-contrat` e gera `num-seq-medicao`; momento do `ASSIGN` frente à criação. |
| P-5 | `upc/upc-cn0302a.p` (fora da pasta) pode conter outras regras. |
| P-6 | Domínio de `contrato-for.natureza` além de 1 e 2; V-08 recusa data quando `natureza` ∉ {2} enquanto o cálculo (3.4) preenche quando `natureza <> 1`. |
| P-7 | Formato de `nr_nota_fis` (com ou sem zeros à esquerda) frente a `integra_rpa.nro_docto`. |
| P-8 | Transação: sugerido gravar tudo em uma única transação; confirmar. |

## 5. Observações para a sessão de codificação

- Pacotes/camadas: lógica genérica em `thl-lib/`; regras específicas desta customização em `thl-extensions/` (ver `AGENTS.md` e `convencoes.md`). Tabelas `es_*` de cliente não vão em `thl-lib`.
- ABL em ISO-8859-1 com CRLF; mensagens com acento em Latin-1.
- Não há compilador no ambiente do agente: informar que precisa compilar no PDSOE.
- Ao concluir, atualizar a nota do pacote em `Documentos/.claude/` e o `INDEX.md`.
