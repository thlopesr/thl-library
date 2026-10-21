/*------------------------------------------------------------------------
    File        : UsuarioService
    Purpose     : Servico de dominio para criacao de usuario Datasul
                  completo (usuario mestre, extensao OS, grupos, empresas
                  e universo) via BOFs. Extraido de UsuarioMessage (SRP).
    Author(s)   : Lopes
    Created     : 2026-07-24
    Notes       : Herda BusinessObject (RowErrors para BOFs).
                  Movido de integration.messaging.inbound.service para
                  erp.service em 2026-07-24.
                  Decomposto em 2026-07-31 — o mapeamento JSON saiu de
                  create() para 5 hooks protected (mesma separacao de
                  DocumentoService: prepare* monta, execute* orquestra).
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-lib.core.error.*.
using thl-lib.erp.core.BusinessObject.
using thl-lib.util.json.JsonSetter.

block-level on error undo, throw.

class thl-lib.erp.service.UsuarioService inherits BusinessObject.

    define protected buffer b-usuar-mestre for usuar_mestre.

    define protected temp-table tt_usuar_mestre       no-undo like usuar_mestre
        field r-rowid as rowid.

    define protected temp-table tt_usuar_mestre_ext   no-undo like usuar_mestre_ext
        field r-rowid as rowid.

    define protected temp-table tt_usuar_grp_usuar    no-undo like usuar_grp_usuar
        field r-rowid as rowid.

    define protected temp-table tt_segur_empres_usuar no-undo like segur_empres_usuar
        field r-rowid as rowid.

    define protected temp-table tt_fnd_usuar_univ     no-undo like fnd_usuar_univ
        field r-rowid as rowid.

    method public override character getEntityName().
        return 'Usuario'.
    end method.

    /*--------------------------------------------------------------------------
      Orquestracao das 5 BOFs de usuario. O mapeamento de cada temp-table
      vive nos hooks mapUser* — aqui ficam apenas a sequencia de chamadas,
      o controle transacional e o tratamento de RowErrors.
    --------------------------------------------------------------------------*/
    method public override void create().

        define variable hBofn017 as handle no-undo.
        define variable hBofn027 as handle no-undo.
        define variable hBofn030 as handle no-undo.
        define variable hBofn168 as handle no-undo.
        define variable hBofn169 as handle no-undo.

        define variable groupsUser    as JsonArray no-undo.
        define variable companiesUser as JsonArray no-undo.

        define variable jsonSetter   as JsonSetter no-undo.
        define variable count        as integer   no-undo.
        define variable cod_domin_so as character no-undo.
        define variable cod_usuar_so as character no-undo.
        define variable createUser   as logical   no-undo.

        empty temp-table tt_usuar_mestre       no-error.
        empty temp-table tt_usuar_grp_usuar    no-error.
        empty temp-table tt_usuar_mestre_ext   no-error.
        empty temp-table tt_segur_empres_usuar no-error.
        empty temp-table tt_fnd_usuar_univ     no-error.

        assign jsonSetter = new JsonSetter( inContext ).

        this-object:mapUserMaster( jsonSetter ).

        do transaction.

            run fnbo/bofn017.p persistent set hBofn017.

            run openQueryStatic in hBofn017 (  input 'main':u ).
            run setRecord       in hBofn017 (  input table tt_usuar_mestre ).
            run createRecord    in hBofn017.
            run getRowErrors    in hBofn017 ( output table RowErrors       ).

            this-object:throwRowErrorsIfAny( 'bofn017' ).

            //sequencia exigida pela bofn017: o createRecord sobrescreve
            //dat_valid_senha, por isso o registro e relido e a validade
            //reaplicada em um updateRecord subsequente
            run openQueryStatic in hBofn017 (  input 'main':u ).
            run gotokey         in hBofn017 (  input tt_usuar_mestre.cod_usuario ).
            run getRecord       in hBofn017 ( output table tt_usuar_mestre ).

            find first tt_usuar_mestre no-error.

            jsonSetter:SetValue( input-output tt_usuar_mestre.dat_valid_senha , input 'dataValidadeSenha' ).

            run setRecord       in hBofn017 (  input table tt_usuar_mestre ).
            run updateRecord    in hBofn017.
            run getRowErrors    in hBofn017 ( output table RowErrors       ).

            this-object:throwRowErrorsIfAny( 'bofn017 updateRecord' ).

            jsonSetter:setPayload( inContext:GetJsonObject('usuarioMestreExterno') ).

            jsonSetter:SetValue( input-output cod_domin_so, input 'codigoDominioSistemaOperacional' ).
            jsonSetter:SetValue( input-output cod_usuar_so, input 'codigoUsuarioSistemaOperacional' ).

            run fnbo/bofn030.p persistent set hBofn030.

            run openQueryStatic in hBofn030 (  input 'Default' ).
            run gotokey         in hBofn030 (  input cod_domin_so,
                                               input cod_usuar_so).
            run getRecord       in hBofn030 ( output table tt_usuar_mestre_ext ).

            assign createUser = this-object:mapUserExtension( jsonSetter, cod_domin_so, cod_usuar_so ).

            run setRecord       in hBofn030 (  input table tt_usuar_mestre_ext ).

            if createUser then run createRecord in hBofn030.
                          else run updateRecord in hBofn030.

            run getRowErrors    in hBofn030 ( output table RowErrors           ).

            this-object:throwRowErrorsIfAny('hBofn030').

            assign groupsUser = inContext:GetJsonArray('gruposUsuario').

            run fnbo/Bofn027.p persistent set hBofn027.

            do  count = 1 to groupsUser:Length.

                jsonSetter:setPayload( groupsUser:GetJsonObject(count) ).

                this-object:mapUserGroup( jsonSetter ).

                run openQueryStatic in hBofn027 (  input 'Default':u ).
                run setRecord       in hBofn027 (  input table tt_usuar_grp_usuar ).
                run createRecord    in hBofn027.
                run getRowErrors    in hBofn027 ( output table RowErrors     ).

                this-object:throwRowErrorsIfAny('hBofn027').

            end.

            assign companiesUser = inContext:GetJsonArray('empresasUsuario').

            run fnbo/bofn168.p persistent set hBofn168.
            run fnbo/bofn169.p persistent set hBofn169.

            do  count = 1 to companiesUser:Length.

                jsonSetter:setPayload( companiesUser:GetJsonObject(count) ).

                this-object:mapUserCompany( jsonSetter ).

                run openQueryStatic in hBofn168 (  input 'Default' ).
                run setRecord       in hBofn168 (  input table tt_segur_empres_usuar ).
                run createRecord    in hBofn168.
                run getRowErrors    in hBofn168 ( output table RowErrors ).

                this-object:throwRowErrorsIfAny('bofn168').

            end.

            jsonSetter:setPayload( companiesUser:GetJsonObject(1) ).

            this-object:mapUserUniverse( jsonSetter ).

            run openQueryStatic in hBofn169 (  input 'Default' ).
            run setRecord       in hBofn169 (  input table tt_fnd_usuar_univ ).
            run createRecord    in hBofn169.
            run getRowErrors    in hBofn169 ( output table RowErrors ).

            this-object:throwRowErrorsIfAny('bofn169').

            find first b-usuar-mestre no-lock
                where b-usuar-mestre.cod_usuario = tt_usuar_mestre.cod_usuario.

        end.

        finally.
            delete procedure hBofn017 no-error.
            delete procedure hBofn027 no-error.
            delete procedure hBofn030 no-error.
            delete procedure hBofn168 no-error.
            delete procedure hBofn169 no-error.
        end finally.

    end method.

    //hook: monta tt_usuar_mestre a partir do payload raiz
    method protected void mapUserMaster( input jsonSetter as JsonSetter ).

        create tt_usuar_mestre.

        jsonSetter:SetValue( input-output tt_usuar_mestre.cod_usuario             , input 'codigoUsuario' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.nom_usuario             , input 'nomeUsuario' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.cod_senha               , input 'codigoSenha' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.cod_idiom_orig          , input 'codigoIdiomaOriginal' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.ind_tip_usuar           , input 'tipoUsuario' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.num_pessoa              , input 'numeroPessoa' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.nom_dir_spool           , input 'diretorioSpool' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.nom_subdir_spool        , input 'subdiretorioSpool' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.cod_servid_exec         , input 'codigoServidorExecucao' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.cod_e_mail_local        , input 'emailLocal' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.dat_ult_erro_tentat_aces, input 'dataUltimoErroTentativaAcesso' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.hra_ult_erro_tentat_aces, input 'horaUltimoErroTentativaAcesso' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.qtd_erro_tentat_aces    , input 'quantidadeErroTentativaAcesso' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.log_servid_exec_obrig   , input 'servidorExecucaoObrigatorio' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.dat_inic_valid          , input 'dataInicioValidade' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.dat_fim_valid           , input 'dataFimValidade' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.dat_valid_senha         , input 'dataValidadeSenha' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.num_dias_valid_senha    , input 'numeroDiasValidadeSenha' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.log_segur_uhr_atlzdo    , input 'segurancaUhrAtualizada' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.cod_livre_1             , input 'codigoLivre1' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.cod_livre_2             , input 'codigoLivre2' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.val_livre_1             , input 'valorLivre1' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.val_livre_2             , input 'valorLivre2' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.num_livre_1             , input 'numeroLivre1' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.num_livre_2             , input 'numeroLivre2' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.log_livre_1             , input 'logicoLivre1' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.log_livre_2             , input 'logicoLivre2' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.dat_livre_1             , input 'dataLivre1' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.dat_livre_2             , input 'dataLivre2' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.des_checksum            , input 'checksum' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.num_perf_usuar          , input 'numeroPerfilUsuario' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.des_cod_perf_usuar      , input 'codigoPerfilUsuario' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.log_mostra_framework    , input 'mostraFramework' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.nom_subdir_spool_rpw    , input 'subdiretorioSpoolRpw' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.cod_dialet              , input 'codigoDialeto' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.log_usuar_wap           , input 'usuarioWap' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.cod_e_mail_celular      , input 'emailCelular' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.log_usuar_atlzdo_ged    , input 'usuarioAtualizadoGed' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.log_ativ_multi_idiom    , input 'ativoMultiplosIdiomas' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.idi_tip_login           , input 'indicadorTipoLogin' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.idi_dtsul               , input 'indicadorDatasul' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.idi_dtsul_instan        , input 'indicadorDatasulInstancia' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.cod_senha_framework     , input 'codigoSenhaFramework' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.log_trace               , input 'trace' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.num_dia_cont_modul_dtsul, input 'numeroDiaContadorModuloDatasul' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.ind_tip_aces_usuar      , input 'tipoAcessoUsuario' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.log_full_determ         , input 'fullDeterminado' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.log_solic_impres        , input 'solicitanteImpressao' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre.des_login_inform        , input 'loginInformacoes' ).

    end method.

    /*--------------------------------------------------------------------------
      Hook: monta tt_usuar_mestre_ext com o jsonSetter ja posicionado em
      'usuarioMestreExterno'. Retorna true quando o registro nao existia no
      ERP — o create() usa esse retorno para escolher createRecord x
      updateRecord na bofn030.
    --------------------------------------------------------------------------*/
    method protected logical mapUserExtension( input jsonSetter   as JsonSetter,
                                               input domainCodeOs as character ,
                                               input userCodeOs   as character ).

        define variable isNewRecord as logical no-undo.

        find first tt_usuar_mestre_ext
            where tt_usuar_mestre_ext.cod_domin_so = domainCodeOs
              and tt_usuar_mestre_ext.cod_usuar_so = userCodeOs no-error.

        if not available tt_usuar_mestre_ext then do.

            empty temp-table tt_usuar_mestre_ext no-error.

            create tt_usuar_mestre_ext.
            assign tt_usuar_mestre_ext.cod_domin_so = domainCodeOs
                   tt_usuar_mestre_ext.cod_usuar_so = userCodeOs
                   tt_usuar_mestre_ext.cod_usuario  = tt_usuar_mestre.cod_usuario
                   isNewRecord                      = true.
        end.

        jsonSetter:SetValue( input-output tt_usuar_mestre_ext.idi_seq           , input 'sequencia'    ).
        jsonSetter:SetValue( input-output tt_usuar_mestre_ext.log_ativ          , input 'ativo'        ).
        jsonSetter:SetValue( input-output tt_usuar_mestre_ext.cod_livre_1       , input 'codigoLivre1' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre_ext.cod_livre_2       , input 'codigoLivre2' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre_ext.val_livre_1       , input 'valorLivre1'  ).
        jsonSetter:SetValue( input-output tt_usuar_mestre_ext.val_livre_2       , input 'valorLivre2'  ).
        jsonSetter:SetValue( input-output tt_usuar_mestre_ext.num_livre_1       , input 'numeroLivre1' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre_ext.num_livre_2       , input 'numeroLivre2' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre_ext.log_livre_1       , input 'logicoLivre1' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre_ext.log_livre_2       , input 'logicoLivre2' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre_ext.dat_livre_1       , input 'dataLivre1'   ).
        jsonSetter:SetValue( input-output tt_usuar_mestre_ext.dat_livre_2       , input 'dataLivre2'   ).
        jsonSetter:SetValue( input-output tt_usuar_mestre_ext.log_domin_default , input 'dominioDefault'   ).
        jsonSetter:SetValue( input-output tt_usuar_mestre_ext.cod_dns_inter     , input 'codigoDnsInterno' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre_ext.des_cod_perf_usuar, input 'codigoPerfilUsuario' ).
        jsonSetter:SetValue( input-output tt_usuar_mestre_ext.num_perf_usuar    , input 'numeroPerfilUsuario' ).

        return isNewRecord.

    end method.

    //hook: monta tt_usuar_grp_usuar para um item do array gruposUsuario
    //(jsonSetter ja posicionado no item pelo create())
    method protected void mapUserGroup( input jsonSetter as JsonSetter ).

        empty temp-table tt_usuar_grp_usuar no-error.
        create tt_usuar_grp_usuar.

        assign tt_usuar_grp_usuar.cod_usuario = tt_usuar_mestre.cod_usuario.

        jsonSetter:SetValue( input-output tt_usuar_grp_usuar.cod_grp_usuar, input 'codigoGrupoUsuario' ).
        jsonSetter:SetValue( input-output tt_usuar_grp_usuar.cod_livre_1  , input 'codigoLivre1' ).
        jsonSetter:SetValue( input-output tt_usuar_grp_usuar.cod_livre_2  , input 'codigoLivre2' ).
        jsonSetter:SetValue( input-output tt_usuar_grp_usuar.val_livre_1  , input 'valorLivre1'  ).
        jsonSetter:SetValue( input-output tt_usuar_grp_usuar.val_livre_2  , input 'valorLivre2'  ).
        jsonSetter:SetValue( input-output tt_usuar_grp_usuar.num_livre_1  , input 'numeroLivre1' ).
        jsonSetter:SetValue( input-output tt_usuar_grp_usuar.num_livre_2  , input 'numeroLivre2' ).
        jsonSetter:SetValue( input-output tt_usuar_grp_usuar.log_livre_1  , input 'logicoLivre1' ).
        jsonSetter:SetValue( input-output tt_usuar_grp_usuar.log_livre_2  , input 'logicoLivre2' ).
        jsonSetter:SetValue( input-output tt_usuar_grp_usuar.dat_livre_1  , input 'dataLivre1'   ).
        jsonSetter:SetValue( input-output tt_usuar_grp_usuar.dat_livre_2  , input 'dataLivre2'   ).
        jsonSetter:SetValue( input-output tt_usuar_grp_usuar.des_checksum , input 'checksum'     ).

    end method.

    //hook: monta tt_segur_empres_usuar para um item do array empresasUsuario
    //(jsonSetter ja posicionado no item pelo create())
    method protected void mapUserCompany( input jsonSetter as JsonSetter ).

        empty temp-table tt_segur_empres_usuar no-error.
        empty temp-table tt_fnd_usuar_univ     no-error.

        create tt_segur_empres_usuar.

        assign tt_segur_empres_usuar.cod_usuario = tt_usuar_mestre.cod_usuario.

        jsonSetter:SetValue( input-output tt_segur_empres_usuar.cod_empresa, input 'codigoEmpresa' ).

    end method.

    //hook: monta tt_fnd_usuar_univ (universo do usuario). Usa apenas a
    //primeira empresa do array — item 4.10 do backlog [DECIDIR]
    method protected void mapUserUniverse( input jsonSetter as JsonSetter ).

        create tt_fnd_usuar_univ.

        assign tt_fnd_usuar_univ.cod_usuario = tt_usuar_mestre.cod_usuario.

        jsonSetter:SetValue( input-output tt_fnd_usuar_univ.cod_empresa, input 'codigoEmpresa' ).

    end method.

    method public override character loadReferenceCode().
        if available b-usuar-mestre then
           return b-usuar-mestre.cod_usuario.
        return ''.
    end method.

end class.
