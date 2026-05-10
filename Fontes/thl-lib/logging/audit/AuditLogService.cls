 
 /*------------------------------------------------------------------------
    File        : logAudit
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Wed Sep 24 16:41:48 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

routine-level on error undo, throw.

using Utils.Objeto.ContextService.
using Utils.Objeto.JsonService.

class Utils.Objeto.AuditLogService serializable.
    
    define private static buffer b-audit-registro for audit-registro.

    method public static final void updateRecord( reference  as character, 
                                                  record     as handle   , 
                                                  tableName  as character).
        createRecord( reference, record, tableName, 2 ).       
    end method.
    
    method public static final void insertRecord( reference  as character, 
                                                  record     as handle   , 
                                                  tableName  as character).
        createRecord( reference, record, tableName, 1 ).       
    end method.
    
    method public static final void deleteRecord( reference  as character, 
                                                  record     as handle   , 
                                                  tableName  as character).
        createRecord( reference, record, tableName, 3 ).       
    end method.

    method public static final void createRecord( reference  as character, 
                                                  record     as handle   , 
                                                  tableName  as character,
                                                  typeLog    as integer  ).
        if isDuplicate(reference , tableName) then 
            return.             
        
        create b-audit-registro.
        assign b-audit-registro.data-criacao = now
               b-audit-registro.programa     = ContextService:getProgramCallers()
               b-audit-registro.tabela       = tableName
               b-audit-registro.referencia   = reference
               b-audit-registro.registro     = JsonService:buildRecordJson(record) 
               b-audit-registro.tipo         = typeLog
               b-audit-registro.usuario      = ContextService:getUser().
        release b-audit-registro no-error.
        
    end method.
    
    method public static final logical isDuplicate( reference  as character, 
                                                    tableName  as character).
        return can-find( first b-audit-registro no-lock
                            where b-audit-registro.tabela       = tableName 
                              and b-audit-registro.referencia   = reference
                              and b-audit-registro.data-criacao = now ).    
    end method.

end class.