/*------------------------------------------------------------------------
    File        : AutomatizadorMedicaoContratoService
    Purpose     : Medicao de contrato do Automatizador: regras de validacao,
                  tabelas customizadas (RPA / lotacao) e arquivos em base64,
                  em volta da API padrao cnapi040 do MedicaoContratoService.
    Author(s)   : Lopes
    Created     : 2026-10-21
    Notes       : Regras extraidas das UPCs escn0302a-u00 a u06 (ver
                  Documentos/relatorios/regras-medicao-implementacao.md).
                  Ordem na transacao: validar, gravar es_ext_medicao_contrat,
                  es_mla_lotacao_docto e rpa_nf_xml, executar a API, atualizar
                  integra_rpa_item (usa a quantidade ja calculada) e gravar os
                  arquivos. Se algo falha, o banco desfaz e os arquivos ja
                  gravados sao apagados.
                  JSON: campos da medicao na raiz; matrizRateio[] (filha);
                  notaFiscal { codEmitente, chaveNf, tipoNf } (filha 1 para
                  0..1; o numero e o vencimento da NF vem de
                  integra_rpa.nro_docto e integra_rpa.data_vencto);
                  automatizador { codLotacao,
                  preenchimentoManual, arquivos[ { nome, extensao,
                  conteudoBase64 } ] }.
                  A NF do RPA (integra_rpa) e localizada uma vez pela chave
                  primaria (estabelecimento do contrato + chaveNf + tipoNf, com
                  tipoNf NFE, NFS, NFT ou NFR) e fica em b-integra-rpa para
                  V-13 e integra_rpa_item. chaveNf e tipoNf sao sempre
                  obrigatorios (exceto quando V-09 desvia as regras do RPA).
                  A pasta dos arquivos vem do thl0002 (variavel
                  medicao.pasta.arquivos do parametro vinculado a esta classe).
                  V-13 e V-15 geram avisos; V-14 nao foi implementada.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.environment.EnvironmentResource.
using thl-lib.core.error.ThlError.
using thl-lib.erp.service.MedicaoContratoService.
using thl-lib.util.file.Base64Files.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.

block-level on error undo, throw.

class thl-extensions.erp.automatizador.service.AutomatizadorMedicaoContratoService inherits MedicaoContratoService.

    define private buffer b-contrato-for for contrato-for.
    define private buffer b-emitente     for emitente.
    define private buffer b-emitente-ctr for emitente.
    define private buffer b-integra-rpa  for integra_rpa.

    define private variable invoiceData       as JsonObject no-undo.
    define private variable automatizadorData as JsonObject no-undo.
    define private variable establishmentCode as character  no-undo.
    define private variable supplierCode      as integer    no-undo.
    define private variable invoiceNumber     as character  no-undo.
    define private variable invoiceKey        as character  no-undo.
    define private variable invoiceType       as character  no-undo.
    define private variable dueDate           as date       no-undo.
    define private variable lotationCode      as character  no-undo initial '0'.
    define private variable manualFilling     as logical    no-undo initial false.
    define private variable skipRpaRules      as logical    no-undo initial false.
    define private variable attachedFiles     as Base64Files no-undo.

    method protected override void validateMedicao().

        define variable jsonSetter as JsonSetter no-undo.

        //nrContrato, numSeqItem, numeroOrdem, numSeqEvent e numSeqMedicao sao campos obrigatorios do
        //cadastro da operacao (thl0022a, aba REST): a InboundMessage os valida antes do Service.

        //nota fiscal (filha da medicao) e objeto automatizador (campos das tabelas customizadas)
        assign invoiceData       = if inContext:Has( 'notaFiscal' ) then inContext:GetJsonObject( 'notaFiscal' )
                                                                        else new JsonObject()
               automatizadorData = if inContext:Has( 'automatizador' ) then inContext:GetJsonObject( 'automatizador' )
                                                                            else new JsonObject()
               supplierCode  = 0
               dueDate       = ?
               manualFilling = false
               invoiceNumber = ''
               invoiceKey    = trim( JsonUtil:getText( invoiceData, 'chaveNf' ) )
               invoiceType   = caps( trim( JsonUtil:getText( invoiceData, 'tipoNf' ) ) )
               lotationCode  = trim( JsonUtil:getText( automatizadorData, 'codLotacao' ) ).

        if lotationCode = '' then
            assign lotationCode = '0'.

        assign jsonSetter = new JsonSetter( invoiceData ).

        jsonSetter:SetValue( input-output supplierCode, input 'codEmitente' ).

        assign jsonSetter = new JsonSetter( automatizadorData ).

        jsonSetter:SetValue( input-output manualFilling, input 'preenchimentoManual' ).

        find first tt-medicao no-lock no-error.

        //ordem das regras do documento regras-medicao-implementacao.md
        this-object:validateContract().
        this-object:validateSupplierActive().
        this-object:resolveRpaMode().

        if skipRpaRules then
            return.

        this-object:validateSupplierRequired().
        this-object:validateSupplierExists().
        this-object:validateSupplierMatrix().

        //NF do RPA pela chave primaria (uma busca; b-integra-rpa serve a V-13 e a integra_rpa_item);
        //o numero e o vencimento da NF vem do registro do RPA
        this-object:validateInvoiceKey().
        this-object:loadInvoiceInRpa().
        this-object:validateInvoiceOwner().

        this-object:validateInvoiceRequired().
        this-object:validateDueDateRequired().

        //V-13 so para fornecedor de Sao Paulo ou Santos (V-14 nao foi implementada; V-15 saiu: o vencimento ja vem do RPA)
        if this-object:isRpaCity() then
            this-object:checkInvoiceInRpa().

        //V-10 a V-12 vencimento do RPA (vazio nao dispara)
        if dueDate <> ? then do.
            this-object:validateDueDateNotPast().
            this-object:validateDueDateMinimum().
            this-object:validateDueDateByContract().
        end.

    end method.

    //Contrato da medicao: define o estabelecimento (tt-medicao.cod-estabel) e o fornecedor padrao
    method private void validateContract().

        find first b-contrato-for no-lock
            where b-contrato-for.nr-contrato = tt-medicao.nr-contrato no-error.

        if not available b-contrato-for then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateContract',
                'Contrato nao encontrado.' ).

        assign establishmentCode = b-contrato-for.cod-estabel.

        //o estabelecimento da medicao e sempre o do contrato (o codEstabel do JSON nao e usado)
        find first tt-medicao exclusive-lock no-error.

        assign tt-medicao.cod-estabel = establishmentCode.

        if supplierCode = ? or supplierCode = 0 then
            assign supplierCode = b-contrato-for.cod-emitente.

    end method.

    //V-01 fornecedor do contrato inativo
    method private void validateSupplierActive().

        if can-find( first es_fornec no-lock
                         where es_fornec.cod_emitente = b-contrato-for.cod-emitente
                           and es_fornec.inativo      = 1 ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateSupplierActive',
                'FORNECEDOR INATIVO !! Nao sera possivel incluir/alterar o Contrato para este Fornecedor!' ).

    end method.

    //V-09 estabelecimento que nao usa NF de servico no RPA: pula V-02 a V-15 e as gravacoes
    //es_ext_medicao_contrat e integra_rpa_item (define skipRpaRules; nao valida)
    method private void resolveRpaMode().

        find first PARAM_rpa_recebimento no-lock
            where PARAM_rpa_recebimento.cod_estabel = establishmentCode no-error.

        assign skipRpaRules = available PARAM_rpa_recebimento and not PARAM_rpa_recebimento.nf_servico.

    end method.

    //V-04 fornecedor obrigatorio
    method private void validateSupplierRequired().

        if supplierCode = 0 then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateSupplierRequired',
                'Obrigatorio informar Fornecedor para medicao contratos' ).

    end method.

    //V-02 fornecedor informado (diferente do contrato) existe
    method private void validateSupplierExists().

        if supplierCode = b-contrato-for.cod-emitente then
            return.

        if not can-find( first b-emitente no-lock
                             where b-emitente.cod-emitente = supplierCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateSupplierExists',
                'Fornecedor informado nao encontrado.' ).

    end method.

    //V-03 fornecedor informado (diferente do contrato) da mesma matriz do fornecedor do contrato
    method private void validateSupplierMatrix().

        if supplierCode = b-contrato-for.cod-emitente then
            return.

        find first b-emitente no-lock
            where b-emitente.cod-emitente = supplierCode no-error.

        find first b-emitente-ctr no-lock
            where b-emitente-ctr.cod-emitente = b-contrato-for.cod-emitente no-error.

        if not available b-emitente or not available b-emitente-ctr or b-emitente-ctr.nome-matriz <> b-emitente.nome-matriz then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateSupplierMatrix',
                'Fornecedores deveram ser da mesma Matriz.' ).

    end method.

    //V-05 contrato de servico exige nota fiscal
    method private void validateInvoiceRequired().

        if b-contrato-for.natureza = 2 and ( invoiceNumber = '' or invoiceNumber = '0' ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateInvoiceRequired',
                'Obrigatorio informar nota fiscal para contratos de servicos' ).

    end method.

    //V-06 contrato de servico exige data de vencimento (agora a do registro do RPA)
    method private void validateDueDateRequired().

        if b-contrato-for.natureza = 2 and dueDate = ? then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateDueDateRequired',
                'Registro RPA sem data de vencimento: obrigatoria para contratos de servicos.' ).

    end method.

    //Chave da NF do RPA: chaveNf e tipoNf sao obrigatorios; tipo NFE, NFS, NFT ou NFR
    method private void validateInvoiceKey().

        if invoiceKey = '' or invoiceType = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateInvoiceKey',
                'Informe a chave e o tipo da nota fiscal (notaFiscal.chaveNf e notaFiscal.tipoNf).' ).

        if lookup( invoiceType, 'NFE,NFS,NFT,NFR' ) = 0 then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateInvoiceKey',
                'Tipo da nota fiscal invalido. Informe NFE, NFS, NFT ou NFR.' ).

    end method.

    //integra_rpa pela chave primaria (estabelecimento do contrato + chave_nf + tipo_nf), uma vez.
    //A chave e obrigatoria (validateInvoiceKey): depois deste metodo b-integra-rpa esta sempre disponivel.
    //O numero e o vencimento da NF vem do registro do RPA.
    method private void loadInvoiceInRpa().

        find first b-integra-rpa no-lock
            where b-integra-rpa.cod_estabel = establishmentCode
              and b-integra-rpa.chave_nf    = invoiceKey
              and b-integra-rpa.tipo_nf     = invoiceType no-error.

        if not available b-integra-rpa then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'loadInvoiceInRpa',
                'Registro RPA nao localizado para a chave e o tipo da nota fiscal informados.' ).

        assign invoiceNumber = trim( b-integra-rpa.nro_docto )
               dueDate       = b-integra-rpa.data_vencto.

    end method.

    //A NF do RPA tem de ser do fornecedor informado
    method private void validateInvoiceOwner().

        if b-integra-rpa.cod_emitente <> supplierCode then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateInvoiceOwner',
                substitute( 'A nota fiscal do RPA pertence ao fornecedor &1, e foi informado o fornecedor &2.',
                            b-integra-rpa.cod_emitente, supplierCode ) ).

    end method.

    //Fornecedor da medicao em Sao Paulo ou Santos (V-13 e V-15)
    method private logical isRpaCity().

        find first b-emitente no-lock
            where b-emitente.cod-emitente = supplierCode no-error.

        if not available b-emitente then
            return false.

        return b-emitente.cidade = 'São Paulo' or 
               b-emitente.cidade = 'Santos'.

    end method.

    //V-13: situacao da NF no RPA (o registro vem de b-integra-rpa). Original nao bloqueia pela
    //situacao: aqui vira aviso.
    method private void checkInvoiceInRpa().

        define variable statusText as character no-undo.

        assign statusText = entry( integer( b-integra-rpa.situacao_nf ),
                                   'Baixado,Validado,Em Andamento,Em Atualizacao,NF Atualizada,Erro Validacao,Erro Atualizacao,NF Atualizada Manual,Em Devolucao,Devolvido,NF Finalizada' )
                            no-error.

        if statusText = ? or statusText = '' then
            assign statusText = string( b-integra-rpa.situacao_nf ).

        this-object:addWarning( substitute( 'Nota Fiscal vinculada no RPA para este Fornecedor, com situacao &1 (nota &2, emitente &3, tipo &4).',
                                            statusText, b-integra-rpa.nro_docto, b-integra-rpa.cod_emitente, b-integra-rpa.tipo_nf ) ).

    end method.

    //V-10 vencimento nao pode ser anterior a hoje
    method private void validateDueDateNotPast().

        if dueDate < today then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateDueDateNotPast',
                'Data de vencimento informada menor que a data de hoje.' ).

    end method.

    //V-11 vencimento a partir de hoje + 7 dias
    method private void validateDueDateMinimum().

        if dueDate <= today + 6 then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateDueDateMinimum',
                'Data de vencimento informada maior que o prazo de 6 dias.' ).

    end method.

    //V-12 vencimento nao pode ser menor que a data calculada pela condicao de pagamento do contrato
    method private void validateDueDateByContract().

        find first cond-pagto no-lock
            where cond-pagto.cod-cond-pag = b-contrato-for.cod-cond-pag no-error.

        if not available cond-pagto then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateDueDateByContract',
                'Condicao de pagamento do contrato nao encontrada.' ).

        if dueDate < b-contrato-for.dt-contrato + cond-pagto.prazos[1] then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateDueDateByContract',
                substitute( 'Data de vencimento informada menor que a data Calculada no contrato. Informada: &1. Calculada: &2.',
                            string( dueDate, '99/99/9999' ),
                            string( b-contrato-for.dt-contrato + cond-pagto.prazos[1], '99/99/9999' ) ) ).

    end method.

    //Gravacoes do cliente antes da API
    method protected override void beforeExecuteApi().

        this-object:saveMedicaoExtension().
        this-object:saveLotation().
        this-object:saveInvoiceXml().

    end method.

    //es_ext_medicao_contrat: cria se nao existir; so grava se V-09 nao desviou
    method private void saveMedicaoExtension().

        if skipRpaRules then
            return.

        find first tt-medicao no-lock no-error.

        find first es_ext_medicao_contrat exclusive-lock
            where es_ext_medicao_contrat.cod_estabel     = establishmentCode
              and es_ext_medicao_contrat.nr_contrato     = tt-medicao.nr-contrato
              and es_ext_medicao_contrat.num_seq_item    = tt-medicao.num-seq-item
              and es_ext_medicao_contrat.numero_ordem    = tt-medicao.numero-ordem
              and es_ext_medicao_contrat.num_seq_event   = tt-medicao.num-seq-event
              and es_ext_medicao_contrat.num_seq_medicao = tt-medicao.num-seq-medicao no-error.

        if not available es_ext_medicao_contrat then do.

            create es_ext_medicao_contrat.

            assign es_ext_medicao_contrat.nr_contrato     = tt-medicao.nr-contrato
                   es_ext_medicao_contrat.num_seq_item    = tt-medicao.num-seq-item
                   es_ext_medicao_contrat.numero_ordem    = tt-medicao.numero-ordem
                   es_ext_medicao_contrat.num_seq_event   = tt-medicao.num-seq-event
                   es_ext_medicao_contrat.num_seq_medicao = tt-medicao.num-seq-medicao.

        end.

        assign es_ext_medicao_contrat.nr_nota_fis  = invoiceNumber
               es_ext_medicao_contrat.dt_vencto    = dueDate
               es_ext_medicao_contrat.cod_estabel  = establishmentCode
               es_ext_medicao_contrat.serie        = 'A'
               es_ext_medicao_contrat.cod_emitente = supplierCode.

    end method.

    //es_mla_lotacao_docto: lotacao do documento (tipo 14). Lotacao so vale para responsavel com
    //aprovacao e destino de lotacao diferente de 2.
    method private void saveLotation().

        define variable documentKey as character no-undo.

        find first tt-medicao no-lock no-error.

        find first estabelec no-lock
            where estabelec.cod-estabel = establishmentCode no-error.

        if not available estabelec then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'saveLotation', 'Estabelecimento do contrato nao encontrado.' ).

        this-object:resolveLotation().

        assign documentKey                     = fill( ' ', 30 )
               substring( documentKey, 01, 08 ) = string( tt-medicao.nr-contrato )
               substring( documentKey, 10, 05 ) = string( tt-medicao.num-seq-item )
               substring( documentKey, 15, 08 ) = string( tt-medicao.numero-ordem )
               substring( documentKey, 23, 04 ) = string( tt-medicao.num-seq-event )
               substring( documentKey, 27, 04 ) = string( tt-medicao.num-seq-medicao ).

        find first es_mla_lotacao_docto exclusive-lock
            where es_mla_lotacao_docto.ep_codigo   = estabelec.ep-codigo
              and es_mla_lotacao_docto.cod_estabel = establishmentCode
              and es_mla_lotacao_docto.chave_docto = documentKey no-error.

        if not available es_mla_lotacao_docto then do.

            create es_mla_lotacao_docto.

            assign es_mla_lotacao_docto.ep_codigo   = estabelec.ep-codigo
                   es_mla_lotacao_docto.cod_estabel = establishmentCode
                   es_mla_lotacao_docto.chave_docto = documentKey
                   es_mla_lotacao_docto.cod_tip_doc = 14.

        end.

        assign es_mla_lotacao_docto.cod_lotacao = lotationCode.

    end method.

    //Lotacao informada: precisa estar entre as do responsavel. Sem aprovacao do responsavel ou com
    //destino de lotacao 2, a informada e ignorada (vale '0'), como o combo desabilitado da tela.
    method private void resolveLotation().

        define variable informedCode as character no-undo.

        assign informedCode = lotationCode
               lotationCode = '0'.

        if informedCode = '' or informedCode = '0' then
            return.

        find first mla-usuar-aprov no-lock
            where mla-usuar-aprov.cod-usuar = tt-medicao.responsavel no-error.

        if not available mla-usuar-aprov or mla-usuar-aprov.destino-lotacao = 2 then
            return.

        if not can-find( first es_mla_usuar_lotacao no-lock
                             where es_mla_usuar_lotacao.cod_usuar   = mla-usuar-aprov.cod-usuar
                               and es_mla_usuar_lotacao.cod_lotacao = informedCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveLotation',
                substitute( 'Lotacao &1 nao permitida para o responsavel &2.', informedCode, tt-medicao.responsavel ) ).

        assign lotationCode = informedCode.

    end method.

    //rpa_nf_xml: NF do RPA (cria ou atualiza), quando ha nota e o fornecedor existe.
    //O original grava sempre; aqui nota em branco nao gera registro vazio.
    method private void saveInvoiceXml().

        if invoiceNumber = '' then
            return.

        find first tt-medicao no-lock no-error.

        find first b-emitente no-lock
            where b-emitente.cod-emitente = supplierCode no-error.

        if not available b-emitente then
            return.

        find first rpa_nf_xml exclusive-lock
            where rpa_nf_xml.cod-estabel = establishmentCode
              and rpa_nf_xml.nro-docto   = invoiceNumber
              and rpa_nf_xml.dt-emissao  = tt-medicao.dat-prev-medicao
              and rpa_nf_xml.cgc         = b-emitente.cgc no-error.

        if not available rpa_nf_xml then do.

            create rpa_nf_xml.

            assign rpa_nf_xml.cod-estabel = establishmentCode
                   rpa_nf_xml.nro-docto   = invoiceNumber
                   rpa_nf_xml.dt-emissao  = tt-medicao.dat-prev-medicao
                   rpa_nf_xml.cgc         = b-emitente.cgc.

        end.

        assign rpa_nf_xml.valor-servico = tt-medicao.val-previsto
               rpa_nf_xml.narrativa     = tt-medicao.observacao
               rpa_nf_xml.utilizada     = yes
               rpa_nf_xml.preenchimento = if manualFilling then 2 else 1.

    end method.

    //Depois da API: integra_rpa_item e arquivos. Os arquivos em base64 ficam em
    //<medicao.pasta.arquivos do thl0002>/<nrContrato>; quem monta, grava e desfaz e o Base64Files.
    method protected override void afterExecuteApi().

        define variable folderPath as character no-undo.

        this-object:updateRpaItem().

        if not automatizadorData:Has( 'arquivos' ) then
            return.

        assign folderPath = new EnvironmentResource():getRequiredEnvironmentVariable( 'medicao.pasta.arquivos' ).

        assign attachedFiles = Base64Files:fromJson( automatizadorData:GetJsonArray( 'arquivos' ),
                                                     substitute('&1/&2', folderPath, outContext:getInteger('nrContrato') ) ).

        attachedFiles:save().

    end method.

    //integra_rpa_item: atualiza o item da NF do RPA com o codigo do item da medicao (it_codigo), com a
    //quantidade ja gravada na medicao; item nao encontrado vira aviso
    method private void updateRpaItem().

        define variable countedQuantity as decimal no-undo.

        if skipRpaRules then
            return.

        find first tt-medicao no-lock no-error.

        find first b-contrato-for no-lock
            where b-contrato-for.nr-contrato = tt-medicao.nr-contrato no-error.

        //o item da NF e o do codigo da medicao (a NF tem varios itens)
        find first integra_rpa_item exclusive-lock
            where integra_rpa_item.cod_estabel = b-integra-rpa.cod_estabel
              and integra_rpa_item.chave_nf    = b-integra-rpa.chave_nf
              and integra_rpa_item.it_codigo   = tt-medicao.it-codigo no-error.

        if not available integra_rpa_item then do.

            this-object:addWarning( substitute( 'Item &1 nao encontrado nos itens da nota fiscal no RPA; integra_rpa_item nao foi atualizado.',
                                                tt-medicao.it-codigo ) ).

            return.

        end.

        find first ordem-compra no-lock
            where ordem-compra.nr-contrato  = b-contrato-for.nr-contrato
              and ordem-compra.cod-estabel  = establishmentCode
              and ordem-compra.num-seq-item = tt-medicao.num-seq-item no-error.

        if not available ordem-compra then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'updateRpaItem',
                'Ordem de compra do item do contrato nao encontrada.' ).

        assign countedQuantity = tt-medicao.qtd-prevista.

        find first medicao-contrat no-lock
            where medicao-contrat.nr-contrato      = tt-medicao.nr-contrato
              and medicao-contrat.num-seq-item     = tt-medicao.num-seq-item
              and medicao-contrat.numero-ordem     = tt-medicao.numero-ordem
              and medicao-contrat.num-seq-event    = tt-medicao.num-seq-event
              and medicao-contrat.num-seq-medicao  = tt-medicao.num-seq-medicao no-error.

        if available medicao-contrat then
            assign countedQuantity = medicao-contrat.qtd-prevista.

        assign integra_rpa_item.qtd_contada     = countedQuantity
               integra_rpa_item.nr_ordem_compr  = ordem-compra.numero-ordem
               integra_rpa_item.nr_pedido       = string( ordem-compra.num-pedido )
               integra_rpa_item.nr_contrato     = ordem-compra.nr-contrato
               integra_rpa_item.num_seq_item    = tt-medicao.num-seq-item
               integra_rpa_item.num_seq_medicao = tt-medicao.num-seq-medicao.

    end method.

    //Falha na criacao: o banco ja foi desfeito; apaga os arquivos que foram gravados
    method protected override void onCreateFailed().

        if valid-object( attachedFiles ) then
            attachedFiles:rollback().

    end method.

end class.
