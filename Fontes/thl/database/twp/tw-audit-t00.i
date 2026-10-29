
/*------------------------------------------------------------------------
    File        : tw-audit-t00.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Lopes
    Created     : Fri Apr 17 14:15:41 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/
using thl-lib.logging.audit.AuditLogService.

{include/i-prgvrs.i tw-audit-t00 12.00.00.000}

//Definitions
define parameter buffer b-{1}-novo   for {1}.
define parameter buffer b-{1}-antigo for {1}.

define variable changedFields as character no-undo.

//Main Block

if not new b-{1}-novo then
    buffer-compare b-{1}-novo to b-{1}-antigo 
        save result in changedFields.

new AuditLogService():writeChange( new b-{1}-novo             ,
                                   changedFields              ,
                                   buffer b-{1}-novo:handle   ,
                                   buffer b-{1}-antigo:handle ).
