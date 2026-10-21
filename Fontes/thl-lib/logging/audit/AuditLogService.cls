 /*------------------------------------------------------------------------
    File        : AuditLogService
    Purpose     : Servico de auditoria orientado a configuracao.
                  Verifica os campos monitorados em thl-audit-campo-tabela,
                  compara os dois buffers e grava snapshots completos em
                  thl-audit-registro + thl-audit-registro-detalhe.
    Author(s)   : Lopes
    Created     : Wed Sep 24 16:41:48 BRT 2025
    Notes       : b-thl-audit-tabela        - tabelas habilitadas
                  thl-audit-campo-tabela  - campos monitorados por tabela
                  thl-audit-registro      - cabecalho (id GUID, meta)
                  thl-audit-registro-detalhe - snapshots antes/depois
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.ObjectModelParser.
using thl-lib.core.context.ContextService.
using thl-lib.logging.audit.enum.*.
using thl-lib.util.json.JsonWriter.

class thl-lib.logging.audit.AuditLogService serializable.

    define private buffer b-thl-audit-registro         for thl-audit-registro.
    define private buffer b-thl-audit-registro-detalhe for thl-audit-registro-detalhe.
    define private buffer b-thl-audit-tabela         for thl-audit-tabela.

    method public final void writeChange( newRecord     as logical  ,
                                          changedFields as character,
                                          bufferNew     as handle   ,
                                          bufferOld     as handle   ).
                                          
        if changedFields = '' then
            return.                                           

        find first b-thl-audit-tabela no-lock
            where b-thl-audit-tabela.banco  = bufferNew:dbname
              and b-thl-audit-tabela.tabela = bufferNew:table 
            no-error.

        if not available b-thl-audit-tabela then 
            return.

        if b-thl-audit-tabela.ind-ativo-create and 
           newRecord                           then insertRecord( buildReference( bufferNew, b-thl-audit-tabela.pk ), bufferNew ).
           
        else do.

            if b-thl-audit-tabela.ind-ativo-update                                                            and
               hasChangedMonitoredField( b-thl-audit-tabela.banco, b-thl-audit-tabela.tabela, changedFields ) then
                updateRecord( buildReference( bufferNew, b-thl-audit-tabela.pk ), changedFields, bufferNew, bufferOld ).
                
        end.
        
    end method.

    method public final void deleteRecord( bufferDelete as handle ).

        find first b-thl-audit-tabela no-lock
            where b-thl-audit-tabela.banco  = bufferDelete:dbname
              and b-thl-audit-tabela.tabela = bufferDelete:table 
              and b-thl-audit-tabela.ind-ativo-delete 
            no-error.

        if not available b-thl-audit-tabela then return.

        //DELETE: snapshot do registro excluido
        do transaction.
            logRecordDetail( logRecord( buildReference( bufferDelete, b-thl-audit-tabela.pk ), bufferDelete:dbname, bufferDelete:table, AuditOperationEnum:Delecao ),
                             AuditSnapshotEnum:Atual,
                             bufferDelete ).
        end.

    end method.

    /* Extrai valores dos campos da chave primaria diretamente do buffer,
       concatenados por "|". keyFields e um JSON array: ["campo1","campo2"].
       Retorna '' em qualquer falha sem propagar excecao. */
    method private character buildReference( bufferRecord as handle  ,
                                             keyFields    as longchar ).

        define variable fieldIndex   as integer   no-undo.
        define variable fieldName    as character no-undo.
        define variable fieldHandle  as handle    no-undo.
        define variable reference    as character no-undo initial '':u.
        define variable jsonArray    as JsonArray no-undo.
        define variable keyFieldsFix as longchar  no-undo.

        do on error undo, return '':u:

            if not valid-handle( bufferRecord ) or
               keyFields = '':u or keyFields = ? then
                return '':u.
            
            assign fix-codepage(keyFieldsFix) = 'UTF-8'
                   keyFieldsFix               = keyFields
                   jsonArray                  = cast( new ObjectModelParser():Parse( keyFieldsFix ), JsonArray ).

            if not valid-object( jsonArray ) or jsonArray:Length = 0 then
                return '':u.

            do fieldIndex = 1 to jsonArray:Length:

                assign fieldName   = jsonArray:GetCharacter( fieldIndex )
                       fieldHandle = bufferRecord:buffer-field( fieldName ).

                if not valid-handle( fieldHandle ) then next.

                if reference = '':u then
                    assign reference = string( fieldHandle:buffer-value ).
                else
                    assign reference = reference + '|':u + string( fieldHandle:buffer-value ).

            end.

            return reference.

        end. /* do on error */

        finally.
            delete object jsonArray no-error.
        end finally.

    end method.

    method private void updateRecord( reference     as character,
                                      changedFields as character,
                                      bufferNew     as handle   ,
                                      bufferOld     as handle   ).

        define variable id as character no-undo.

        do transaction.
            assign id = logRecord( reference, bufferNew:dbname, bufferNew:table, changedFields, AuditOperationEnum:Atualizacao ).

            logRecordDetail( id, AuditSnapshotEnum:Atual   , bufferNew ).
            logRecordDetail( id, AuditSnapshotEnum:Anterior, bufferOld ).
        end.

    end method.

    method private void insertRecord( reference    as character,
                                      bufferRecord as handle   ).
        do transaction.
            logRecordDetail( logRecord( reference, bufferRecord:dbname, bufferRecord:table, AuditOperationEnum:Criacao ),
                             AuditSnapshotEnum:Atual,
                             bufferRecord ).
        end.
    end method.

    //Overload sem changedFields: usado em CREATE e DELETE (todos os campos relevantes)
    method private character logRecord( reference      as character        ,
                                        dataBaseName   as character        ,
                                        tableName      as character        ,
                                        operationType  as AuditOperationEnum ).
        return logRecord( reference, dataBaseName, tableName, 'Todos', operationType ).
    end method.

    method private character logRecord( reference      as character        ,
                                        databaseName   as character        ,
                                        tableName      as character        ,
                                        changedFields  as character        ,
                                        operationType  as AuditOperationEnum ).

        define variable id as character no-undo.

        assign id = guid( generate-uuid ).

        create b-thl-audit-registro.
        assign b-thl-audit-registro.id                 = id
               b-thl-audit-registro.tabela             = tableName
               b-thl-audit-registro.banco              = 'sh' + databaseName
               b-thl-audit-registro.referencia         = reference
               b-thl-audit-registro.tipo               = integer(operationType)
               b-thl-audit-registro.data-criacao       = now
               b-thl-audit-registro.campos             = changedFields
               b-thl-audit-registro.usuario            = ContextService:getErpUser()
               b-thl-audit-registro.usuario-so         = ContextService:getUser()
               b-thl-audit-registro.programa-executado = ContextService:getProgramsCaller().
        release b-thl-audit-registro.

        return id.

    end method.

    method private void logRecordDetail( id            as character       ,
                                         snapshotType  as AuditSnapshotEnum,
                                         bufferRecord  as handle          ).

        if not valid-handle(bufferRecord) then
            return.

        create b-thl-audit-registro-detalhe.
        assign b-thl-audit-registro-detalhe.id    = id
               b-thl-audit-registro-detalhe.tipo  = integer(snapshotType)
               b-thl-audit-registro-detalhe.valor = JsonWriter:toJsonFromBuffer(bufferRecord)
               .
        release b-thl-audit-registro-detalhe.

    end method.

    method private logical hasChangedMonitoredField( databaseName  as character ,
                                                     tableName     as character ,
                                                     changedFields as character ).
        return b-thl-audit-tabela.ind-audit-tabela or
               can-find( first thl-audit-tabela-campo no-lock
                            where thl-audit-tabela-campo.banco  = databaseName
                              and thl-audit-tabela-campo.tabela = tableName
                              and thl-audit-tabela-campo.ind-ativo
                              and changedFields matches( substitute( '*&1*', thl-audit-tabela-campo.campo ) ) ).
    end method.

end class.
