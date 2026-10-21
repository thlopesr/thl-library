using thl-lib.logging.audit.AuditLogService.

/* ***************************  Definitions  ************************** */
define parameter buffer b-embarque-novo   for embarque.
define parameter buffer b-embarque-antigo for embarque.

define variable changedFields as character no-undo.

if not new b-embarque-novo then
    buffer-compare b-embarque-novo to b-embarque-antigo 
        save result in changedFields.

new AuditLogService():writeChange( new b-embarque-novo             ,
                                   changedFields                   ,
                                   buffer b-embarque-novo:handle   ,
                                   buffer b-embarque-antigo:handle ).
