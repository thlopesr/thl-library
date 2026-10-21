using thl-lib.logging.audit.AuditLogService.

/* ***************************  Definitions  ************************** */
define parameter buffer b-{1}-novo   for {1}.
define parameter buffer b-{1}-antigo for {1}.

define variable changedFields as character no-undo.

if not new b-{1}-novo then
    buffer-compare b-{1}-novo to b-{1}-antigo 
        save result in changedFields.

new AuditLogService():writeChange( new b-{1}-novo             ,
                                   changedFields              ,
                                   buffer b-{1}-novo:handle   ,
                                   buffer b-{1}-antigo:handle ).

run {2} ( buffer b-{1}-novo   , 
          buffer b-{1}-antigo ).
          
if return-value = 'NOK' then 
    return 'NOK'.