/*------------------------------------------------------------------------
    File        : centroCusto
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Thu Jul 01 08:41:22 BRT 2021
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-lib.integration.messaging.core.Message.
using thl-lib.integration.messaging.Inbound.core.InboundMessage.
using thl-lib.util.json.JsonSetter.

block-level on error undo, throw.

class thl-lib.integration.messaging.Inbound.message.UsuarioMessage inherits InboundMessage.
    
    define private buffer b-usuar-mestre for usuar_mestre.

    define temp-table tt_usuar_mestre       no-undo like usuar_mestre
        field r-rowid as rowid.
    
    define temp-table tt_usuar_mestre_ext   no-undo like usuar_mestre_ext
        field r-rowid as rowid.

    define temp-table tt_usuar_grp_usuar    no-undo like usuar_grp_usuar
        field r-rowid as rowid.
        
    define temp-table tt_segur_empres_usuar no-undo like segur_empres_usuar
        field r-rowid as rowid.   
             
    define temp-table tt_fnd_usuar_univ     no-undo like fnd_usuar_univ
        field r-rowid as rowid.           

    constructor public UsuarioMessage ( objectName           as character ,
                                        integrationOperation as character ,
                                        methodType           as integer   ,
                                        connectorType        as integer   ,
                                        integrationDirection as logical   ,
                                        executionMode        as integer   ).
        super( objectName, integrationOperation, methodType, connectorType, integrationDirection, executionMode).
    end constructor. 
    
    method protected override void methodPost( userSystem as JsonObject ).

        define variable hBofn017 as handle no-undo.
        define variable hBofn027 as handle no-undo. 
        define variable hBofn030 as handle no-undo.  
        define variable hBofn168 as handle no-undo. 
        define variable hBofn169 as handle no-undo. 
        
        define variable groupsUser    as JsonArray no-undo. 
        define variable companiesUser as JsonArray no-undo. 
        
        define variable count        as integer   no-undo.    
        define variable cod_domin_so as character no-undo.
        define variable cod_usuar_so as character no-undo. 
        define variable createUser   as logical   no-undo.   
        
        empty temp-table tt_usuar_mestre       no-error.
        empty temp-table tt_usuar_grp_usuar    no-error.
        empty temp-table tt_usuar_mestre_ext   no-error. 
        empty temp-table tt_segur_empres_usuar no-error.
        empty temp-table tt_fnd_usuar_univ     no-error.
        
        create tt_usuar_mestre.
        
        assign JsonSetter:payload = userSystem.
        
        JsonSetter:SetValue( input-output tt_usuar_mestre.cod_usuario             , input 'codigoUsuario' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.nom_usuario             , input 'nomeUsuario' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.cod_senha               , input 'codigoSenha' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.cod_idiom_orig          , input 'codigoIdiomaOriginal' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.ind_tip_usuar           , input 'tipoUsuario' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.num_pessoa              , input 'numeroPessoa' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.nom_dir_spool           , input 'diretorioSpool' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.nom_subdir_spool        , input 'subdiretorioSpool' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.cod_servid_exec         , input 'codigoServidorExecucao' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.cod_e_mail_local        , input 'emailLocal' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.dat_ult_erro_tentat_aces, input 'dataUltimoErroTentativaAcesso' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.hra_ult_erro_tentat_aces, input 'horaUltimoErroTentativaAcesso' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.qtd_erro_tentat_aces    , input 'quantidadeErroTentativaAcesso' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.log_servid_exec_obrig   , input 'servidorExecucaoObrigatorio' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.dat_inic_valid          , input 'dataInicioValidade' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.dat_fim_valid           , input 'dataFimValidade' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.dat_valid_senha         , input 'dataValidadeSenha' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.num_dias_valid_senha    , input 'numeroDiasValidadeSenha' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.log_segur_uhr_atlzdo    , input 'segurancaUhrAtualizada' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.cod_livre_1             , input 'codigoLivre1' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.cod_livre_2             , input 'codigoLivre2' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.val_livre_1             , input 'valorLivre1' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.val_livre_2             , input 'valorLivre2' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.num_livre_1             , input 'numeroLivre1' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.num_livre_2             , input 'numeroLivre2' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.log_livre_1             , input 'logicoLivre1' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.log_livre_2             , input 'logicoLivre2' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.dat_livre_1             , input 'dataLivre1' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.dat_livre_2             , input 'dataLivre2' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.des_checksum            , input 'checksum' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.num_perf_usuar          , input 'numeroPerfilUsuario' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.des_cod_perf_usuar      , input 'codigoPerfilUsuario' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.log_mostra_framework    , input 'mostraFramework' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.nom_subdir_spool_rpw    , input 'subdiretorioSpoolRpw' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.cod_dialet              , input 'codigoDialeto' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.log_usuar_wap           , input 'usuarioWap' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.cod_e_mail_celular      , input 'emailCelular' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.log_usuar_atlzdo_ged    , input 'usuarioAtualizadoGed' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.log_ativ_multi_idiom    , input 'ativoMultiplosIdiomas' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.idi_tip_login           , input 'indicadorTipoLogin' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.idi_dtsul               , input 'indicadorDatasul' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.idi_dtsul_instan        , input 'indicadorDatasulInstancia' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.cod_senha_framework     , input 'codigoSenhaFramework' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.log_trace               , input 'trace' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.num_dia_cont_modul_dtsul, input 'numeroDiaContadorModuloDatasul' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.ind_tip_aces_usuar      , input 'tipoAcessoUsuario' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.log_full_determ         , input 'fullDeterminado' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.log_solic_impres        , input 'solicitanteImpressao' ).
        JsonSetter:SetValue( input-output tt_usuar_mestre.des_login_inform        , input 'loginInformacoes' ).
    
        do transaction.
        
            run fnbo/bofn017.p persistent set hBofn017.
            
            run openQueryStatic in hBofn017 (  input 'main':u ).
            run setRecord       in hBofn017 (  input table tt_usuar_mestre ).
            run createRecord    in hBofn017.
            run getRowErrors    in hBofn017 ( output table rowErrors       ).
            
            this-object:throwRowErrorsIfAny( 'bofn017' ).
            
            run openQueryStatic in hBofn017 (  input 'main':u ).
            run gotokey         in hBofn017 (  input tt_usuar_mestre.cod_usuario ).
            run getRecord       in hBofn017 ( output table tt_usuar_mestre ).
            
            find first tt_usuar_mestre no-error.
            
            JsonSetter:SetValue( input-output tt_usuar_mestre.dat_valid_senha , input 'dataValidadeSenha' ).
            
            run setRecord       in hBofn017 (  input table tt_usuar_mestre ).
            run updateRecord    in hBofn017.
            run getRowErrors    in hBofn017 ( output table rowErrors       ).
            
            this-object:throwRowErrorsIfAny( 'bofn017 updateRecord' ).
            
            assign JsonSetter:payload = userSystem:GetJsonObject('usuarioMestreExterno').
                               
            JsonSetter:SetValue( input-output cod_domin_so, input 'codigoDominioSistemaOperacional' ).
            JsonSetter:SetValue( input-output cod_usuar_so, input 'codigoUsuarioSistemaOperacional' ).

            run fnbo/bofn030.p persistent set hBofn030.
                
            run openQueryStatic in hBofn030 (  input 'Default' ).
            run gotokey         in hBofn030 (  input cod_domin_so,
                                               input cod_usuar_so).
            run getRecord       in hBofn030 ( output table tt_usuar_mestre_ext ).
            
            find first tt_usuar_mestre_ext no-error.
            
            if not available tt_usuar_mestre_ext then do.
                create tt_usuar_mestre_ext.
                assign tt_usuar_mestre_ext.cod_domin_so = cod_domin_so
                       tt_usuar_mestre_ext.cod_usuar_so = cod_usuar_so
                       createUser = true.
            end.
            
            JsonSetter:SetValue( input-output tt_usuar_mestre_ext.idi_seq           , input 'sequencia'    ).
            JsonSetter:SetValue( input-output tt_usuar_mestre_ext.log_ativ          , input 'ativo'        ).
            JsonSetter:SetValue( input-output tt_usuar_mestre_ext.cod_livre_1       , input 'codigoLivre1' ).
            JsonSetter:SetValue( input-output tt_usuar_mestre_ext.cod_livre_2       , input 'codigoLivre2' ).
            JsonSetter:SetValue( input-output tt_usuar_mestre_ext.val_livre_1       , input 'valorLivre1'  ).
            JsonSetter:SetValue( input-output tt_usuar_mestre_ext.val_livre_2       , input 'valorLivre2'  ).
            JsonSetter:SetValue( input-output tt_usuar_mestre_ext.num_livre_1       , input 'numeroLivre1' ).
            JsonSetter:SetValue( input-output tt_usuar_mestre_ext.num_livre_2       , input 'numeroLivre2' ).
            JsonSetter:SetValue( input-output tt_usuar_mestre_ext.log_livre_1       , input 'logicoLivre1' ).
            JsonSetter:SetValue( input-output tt_usuar_mestre_ext.log_livre_2       , input 'logicoLivre2' ).
            JsonSetter:SetValue( input-output tt_usuar_mestre_ext.dat_livre_1       , input 'dataLivre1'   ).
            JsonSetter:SetValue( input-output tt_usuar_mestre_ext.dat_livre_2       , input 'dataLivre2'   ).
            JsonSetter:SetValue( input-output tt_usuar_mestre_ext.log_domin_default , input 'dominioDefault'   ).
            JsonSetter:SetValue( input-output tt_usuar_mestre_ext.cod_dns_inter     , input 'codigoDnsInterno' ).
            JsonSetter:SetValue( input-output tt_usuar_mestre_ext.des_cod_perf_usuar, input 'codigoPerfilUsuario' ).
            JsonSetter:SetValue( input-output tt_usuar_mestre_ext.num_perf_usuar    , input 'numeroPerfilUsuario' ).
            
            run setRecord       in hBofn030 (  input table tt_usuar_mestre_ext ).
            
            if createUser then run createRecord in hBofn030.
                          else run updateRecord in hBofn030.  
            
            run getRowErrors    in hBofn030 ( output table rowErrors           ).
        
            this-object:throwRowErrorsIfAny('hBofn030').
            
            assign groupsUser = userSystem:GetJsonArray('gruposUsuario').
            
            run fnbo/Bofn027.p persistent set hBofn027.
            
            do  count = 1 to groupsUser:Length.       
            
                empty temp-table tt_usuar_grp_usuar no-error.
                create tt_usuar_grp_usuar.
                        
                assign JsonSetter:payload             = groupsUser:GetJsonObject(count)
                       tt_usuar_grp_usuar.cod_usuario = tt_usuar_mestre.cod_usuario.
                
                JsonSetter:SetValue( input-output tt_usuar_grp_usuar.cod_grp_usuar, input 'codigoGrupoUsuario' ).
                JsonSetter:SetValue( input-output tt_usuar_grp_usuar.cod_livre_1  , input 'codigoLivre1' ).
                JsonSetter:SetValue( input-output tt_usuar_grp_usuar.cod_livre_2  , input 'codigoLivre2' ).
                JsonSetter:SetValue( input-output tt_usuar_grp_usuar.val_livre_1  , input 'valorLivre1'  ).
                JsonSetter:SetValue( input-output tt_usuar_grp_usuar.val_livre_2  , input 'valorLivre2'  ).
                JsonSetter:SetValue( input-output tt_usuar_grp_usuar.num_livre_1  , input 'numeroLivre1' ).
                JsonSetter:SetValue( input-output tt_usuar_grp_usuar.num_livre_2  , input 'numeroLivre2' ).
                JsonSetter:SetValue( input-output tt_usuar_grp_usuar.log_livre_1  , input 'logicoLivre1' ).
                JsonSetter:SetValue( input-output tt_usuar_grp_usuar.log_livre_2  , input 'logicoLivre2' ).
                JsonSetter:SetValue( input-output tt_usuar_grp_usuar.dat_livre_1  , input 'dataLivre1'   ).
                JsonSetter:SetValue( input-output tt_usuar_grp_usuar.dat_livre_2  , input 'dataLivre2'   ).
                JsonSetter:SetValue( input-output tt_usuar_grp_usuar.des_checksum , input 'checksum'     ).
                
                run openQueryStatic in hBofn027 (  input 'Default':u ).
                run setRecord       in hBofn027 (  input table tt_usuar_grp_usuar ).
                run createRecord    in hBofn027.
                run getRowErrors    in hBofn027 ( output table rowErrors     ).
                     
                this-object:throwRowErrorsIfAny('hBofn027').

            end.
            
            assign companiesUser = userSystem:GetJsonArray('empresasUsuario').
            
            run fnbo/bofn168.p persistent set hBofn168.
            run fnbo/bofn169.p persistent set hBofn169.
            
            do  count = 1 to companiesUser:Length.       
            
                empty temp-table tt_segur_empres_usuar no-error.
                empty temp-table tt_fnd_usuar_univ     no-error.
                
                create tt_segur_empres_usuar.
                        
                assign JsonSetter:payload                = companiesUser:GetJsonObject(count)
                       tt_segur_empres_usuar.cod_usuario = tt_usuar_mestre.cod_usuario.
                
                JsonSetter:SetValue( input-output tt_segur_empres_usuar.cod_empresa, input 'codigoEmpresa' ).
                
                run openQueryStatic in hBofn168 (  input 'Default' ).
                run setRecord       in hBofn168 (  input table tt_segur_empres_usuar ).
                run createRecord    in hBofn168.
                run getRowErrors    in hBofn168 ( output table rowErrors ).
                     
                this-object:throwRowErrorsIfAny('bofn168').

            end.
            
            create tt_fnd_usuar_univ.
            assign tt_fnd_usuar_univ.cod_usuario = tt_usuar_mestre.cod_usuario
                   JsonSetter:payload            = companiesUser:GetJsonObject(1). 
                       
            JsonSetter:SetValue( input-output tt_fnd_usuar_univ.cod_empresa    , input 'codigoEmpresa' ).
                                                                             
            run openQueryStatic in hBofn169 (  input 'Default' ).
            run setRecord       in hBofn169 (  input table tt_fnd_usuar_univ ).
            run createRecord    in hBofn169.
            run getRowErrors    in hBofn169 ( output table rowErrors ).
                     
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

    method public override character onLoadData( input register as recid ).
        return ( b-usuar-mestre.cod_usuario ).
    end method.
    
    method protected override character getRequiredFields().
        return 'codigoUsuario'.
    end method.

end class.
