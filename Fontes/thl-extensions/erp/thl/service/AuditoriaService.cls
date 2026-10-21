/*------------------------------------------------------------------------
    File        : AuditoriaService
    Purpose     : Servico de dominio para consulta de registros de
                  auditoria (thl-audit-registro). Somente leitura - busca
                  por ranges de banco, tabela, data-criacao e usuario
                  com paginacao. Snapshots incluidos no JSON de cada registro.
    Author(s)   : Lopes
    Created     : Mon Sep 15 2026
    Notes       : Segue padrao canonico MensageriaService - herda Service,
                  paginacao via PaginationHelper (composicao).
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-lib.core.context.ContextService.
using thl-lib.erp.core.Service.
using thl-lib.logging.LogUtil.
using thl-extensions.erp.thl.interfaces.IMetricsService.
using thl-lib.logging.audit.enum.AuditOperationEnum.
using thl-lib.util.date.DateTimeUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.AuditoriaService inherits Service implements IMetricsService.

    define private buffer b-audit         for thl-audit-registro.
    define private buffer b-audit-detalhe for thl-audit-registro-detalhe.
    define private buffer b-tabela        for thl-audit-tabela.
    define private buffer b-acesso        for thl-audit-tabela-acesso.
    define private buffer b-campo         for thl-audit-tabela-campo.
    
    define private property user_ as character no-undo get. set.

    //snapshot ilegivel (JSON invalido) no registro em montagem: o item sai com snapshotInvalido
    define private variable invalidSnapshot as logical no-undo.

    method public override character getEntityName().
        return 'Auditoria'.
    end method.

    method public override character loadReferenceCode().
        if available b-audit then
            return b-audit.id.
        return ''.
    end method.

    //Metricas do periodo (IMetricsService): padrao, as ultimas 24 horas.
    //Chamado pelo MetricsProcessor na operacao metricas.
    method public JsonConstruct consultMetrics().
        return this-object:getMetrics( queryParameters:getDateTime( 'dtCriacaoIni', DateTimeUtil:addHours( now, -24 ) ),
                                       queryParameters:getDateTime( 'dtCriacaoFin', DateTimeUtil:currentDateTime()    ) ).
    end method.

    //Consulta: a listagem
    method public override JsonConstruct consult().

        return this-object:get( queryParameters:getPager( 1000 ),
                                queryParameters:getText( 'bancoIni' , ''               ),
                                queryParameters:getText( 'bancoFin' , fill( 'z', 100 ) ),
                                queryParameters:getText( 'tabelaIni', ''               ),
                                queryParameters:getText( 'tabelaFin', fill( 'z', 100 ) ),
                                queryParameters:getDateTime( 'dtCriacaoIni', DateTimeUtil:addHours( now, -24 ) ),
                                queryParameters:getDateTime( 'dtCriacaoFin', DateTimeUtil:currentDateTime()    ),
                                queryParameters:getText( 'usuarioIni', ''              ),
                                queryParameters:getText( 'usuarioFin', fill( 'z', 40 ) ) ).

    end method.

    method public JsonArray get ( pager        as PaginationHelper ,
                                  bancoIni     as character        ,
                                  bancoFin     as character        ,
                                  tabelaIni    as character        ,
                                  tabelaFin    as character        ,
                                  dtCriacaoIni as datetime         ,
                                  dtCriacaoFin as datetime         ,
                                  usuarioIni   as character        ,
                                  usuarioFin   as character        ).

        define variable registros as JsonArray no-undo.
        define variable database_ as character no-undo.

        assign user_     = ContextService:getErpUser()
               registros = new JsonArray().               

        for each b-acesso no-lock
            where b-acesso.cod-usuario  = user_
              and b-acesso.ind-ativo
              and b-acesso.banco       >= bancoIni
              and b-acesso.banco       <= bancoFin
              and b-acesso.tabela      >= tabelaIni
              and b-acesso.tabela      <= tabelaFin.
              
            assign database_ = 'sh' + b-acesso.banco.
                          
            for each b-audit no-lock
                where b-audit.banco         = database_
                  and b-audit.tabela        = b-acesso.tabela
                  and b-audit.data-criacao >= dtCriacaoIni
                  and b-audit.data-criacao <= dtCriacaoFin
                  and b-audit.usuario      >= usuarioIni
                  and b-audit.usuario      <= usuarioFin.
            
                pager:incrementPageCount().
                if pager:shouldSkipEntry()  then next.
                if pager:shouldStopPaging() then leave.

                registros:Add( buildAuditJson() ).
            
            end.
            
        end.

        return registros.

    end method.

    //Telas de metricas (rota auditoria/metricas):
    //array -> objeto (banco, tabela, nivelSensibilidade) -> array "registros" -> objeto (atributos).
    //So a faixa de criacao, sem paginacao e sem snapshots.
    //Nao valida o acesso do usuario (thl-audit-tabela-acesso): percorre as
    //tabelas auditadas do cadastro; tabela sem evento no periodo nao entra.
    //banco = nome do cadastro (sem o prefixo sh); tipo como texto (Criacao,
    //Atualizacao, Delecao), como na listagem.
    method public JsonArray getMetrics ( dtCriacaoIni as datetime ,
                                         dtCriacaoFin as datetime ).

        define variable tables       as JsonArray  no-undo.
        define variable tableItem    as JsonObject no-undo.
        define variable tableRecords as JsonArray  no-undo.
        define variable registro     as JsonObject no-undo.
        define variable database_    as character  no-undo.

        assign tables = new JsonArray().

        for each b-tabela no-lock.

            //o registro grava o banco com o prefixo sh; o cadastro, sem
            assign database_    = 'sh' + b-tabela.banco
                   tableRecords = new JsonArray().

            for each b-audit no-lock
                where b-audit.banco         = database_
                  and b-audit.tabela        = b-tabela.tabela
                  and b-audit.data-criacao >= dtCriacaoIni
                  and b-audit.data-criacao <= dtCriacaoFin.

                assign registro = new JsonObject().

                registro:Add( 'tipo'     , getOperationLabel( AuditOperationEnum:GetEnum( b-audit.tipo ) ) ).
                registro:Add( 'usuario'  , b-audit.usuario      ).
                registro:Add( 'dtCriacao', b-audit.data-criacao ).

                tableRecords:Add( registro ).

            end.

            if tableRecords:Length = 0 then
                next.

            assign tableItem = new JsonObject().

            tableItem:Add( 'banco'             , b-tabela.banco               ).
            tableItem:Add( 'tabela'            , b-tabela.tabela              ).
            tableItem:Add( 'nivelSensibilidade', b-tabela.nivel-sensibilidade ).
            tableItem:Add( 'registros'         , tableRecords                 ).

            tables:Add( tableItem ).

        end.

        return tables.

    end method.

    method private JsonObject buildAuditJson().

        define variable reg as JsonObject no-undo.

        assign reg             = new JsonObject()
               invalidSnapshot = false.

        reg:Add( 'id',                b-audit.id                 ).
        reg:Add( 'banco',             b-audit.banco              ).
        reg:Add( 'tabela',            b-audit.tabela             ).
        reg:Add( 'referencia',        b-audit.referencia         ).
        reg:Add( 'operacao',          getOperationLabel( AuditOperationEnum:GetEnum(b-audit.tipo) ) ).
        reg:Add( 'dtCriacao',         if b-audit.data-criacao <> ? then iso-date( b-audit.data-criacao ) else '' ).
        reg:Add( 'campos',            b-audit.campos             ).
        reg:Add( 'usuario',           b-audit.usuario            ).
        reg:Add( 'usuarioSO',         b-audit.usuario-so         ).
        reg:Add( 'programaExecutado', b-audit.programa-executado ).

        if b-audit.tipo = integer( AuditOperationEnum:Atualizacao ) then do.
            reg:Add( 'snapshotAtual',    filterSnapshot( b-audit.id, 1, b-audit.campos ) ).
            reg:Add( 'snapshotAnterior', filterSnapshot( b-audit.id, 2, b-audit.campos ) ).
        end.
        else
            reg:Add( 'snapshotAtual', filterSnapshotByAccess( b-audit.id, 1 ) ).

        //um snapshot com JSON invalido nao derruba a listagem: o item avisa
        if invalidSnapshot then
            reg:Add( 'snapshotInvalido', true ).

        return reg.

    end method.

    method private JsonObject filterSnapshot( id            as character ,
                                              snapshotType  as integer   ,
                                              changedFields as character ).

        define variable snapshot   as JsonObject no-undo.
        define variable tableName  as character  extent no-undo.
        define variable records    as JsonArray  no-undo.
        define variable record     as JsonObject no-undo.
        define variable allNames   as character  extent no-undo.
        define variable nameIndex  as integer    no-undo.
        define variable recIndex   as integer    no-undo.

        assign snapshot = parseSnapshot( id, snapshotType ).

        if not valid-object( snapshot ) then
            return new JsonObject().

        assign tableName = snapshot:GetNames().

        if extent( tableName ) = ? or 
           extent( tableName ) = 0 then
            return snapshot.

        assign records = snapshot:GetJsonArray( tableName[1] ).

        do recIndex = 1 to records:Length.

            assign record   = records:GetJsonObject( recIndex )
                   allNames = record:GetNames().

            do nameIndex = 1 to extent( allNames ).
                if lookup( allNames[nameIndex], changedFields ) = 0                        or
                   isFieldRestricted( b-audit.banco, b-audit.tabela, allNames[nameIndex] ) then
                    record:Remove( allNames[nameIndex] ).
            end.

        end.

        return snapshot.

    end method.

    method private JsonObject parseSnapshot( id as character, snapshotType as integer ).

        define variable detailValue as longchar no-undo.
        define variable fixedValue  as longchar no-undo.

        find first b-audit-detalhe no-lock
            where b-audit-detalhe.id   = id
              and b-audit-detalhe.tipo = snapshotType
            no-error.

        if not available b-audit-detalhe then
            return new JsonObject().

        assign fix-codepage(fixedValue) = 'UTF-8'
               fixedValue               = b-audit-detalhe.valor.
               
        if fixedValue = '' then
            return new JsonObject().

        return cast( new ObjectModelParser():Parse( fixedValue ), JsonObject ).

        //JSON invalido gravado no detalhe: registra o evento e devolve vazio, em vez de
        //derrubar a listagem inteira por causa de um registro
        catch parseError as Progress.Lang.Error:
            assign invalidSnapshot = true.
            LogUtil:write( substitute( 'AuditoriaService.parseSnapshot: snapshot invalido id=&1 tipo=&2 tamanho=&3 erro=&4',
                                       id, snapshotType, length( fixedValue ), parseError:GetMessage( 1 ) ),
                           'AuditoriaService' ).
            return new JsonObject().
        end catch.

    end method.

    method private logical isFieldRestricted( banco     as character ,
                                              tabela    as character ,
                                              fieldName as character ).

        if not available b-acesso then
            return false.

        return can-find( first b-campo no-lock
                            where b-campo.banco                = banco
                              and b-campo.tabela               = tabela
                              and b-campo.campo                = fieldName
                              and b-campo.nivel-sensibilidade  > b-acesso.nivel-acesso ).

    end method.

    method private JsonObject filterSnapshotByAccess( id           as character ,
                                                      snapshotType as integer   ).

        define variable snapshot  as JsonObject no-undo.
        define variable tableName as character  extent no-undo.
        define variable records   as JsonArray  no-undo.
        define variable record    as JsonObject no-undo.
        define variable allNames  as character  extent no-undo.
        define variable nameIndex as integer    no-undo.
        define variable recIndex  as integer    no-undo.

        assign snapshot = parseSnapshot( id, snapshotType ).

        if not valid-object( snapshot ) then
            return new JsonObject().

        assign tableName = snapshot:GetNames().

        if extent( tableName ) = ? or extent( tableName ) = 0 then
            return snapshot.

        assign records = snapshot:GetJsonArray( tableName[1] ).

        do recIndex = 1 to records:Length:

            assign record   = records:GetJsonObject( recIndex )
                   allNames = record:GetNames().

            do nameIndex = 1 to extent( allNames ):
                if isFieldRestricted( b-audit.banco, b-audit.tabela, allNames[nameIndex] ) then
                    record:Remove( allNames[nameIndex] ).
            end.

        end.

        return snapshot.

    end method.

    method private character getOperationLabel( operationType as AuditOperationEnum ).

        case operationType.
            when AuditOperationEnum:Criacao      then return 'Criacao'.
            when AuditOperationEnum:Atualizacao  then return 'Atualizacao'.
            when AuditOperationEnum:Delecao      then return 'Delecao'.
            otherwise return ''.
        end case.

    end method.

end class.
