/*using thl-lib.logging.audit.AuditLogService.

/* ***************************  Definitions  ************************** */
define parameter buffer b-emitente   for emitente.

define variable reference     as character no-undo.

//Chave de negocio que identifica o registro na auditoria
assign reference = b-emitente.nome-abrev.

new AuditLogService():deleteRecord( reference                ,
                                    buffer b-emitente:handle ).*/

                                    
