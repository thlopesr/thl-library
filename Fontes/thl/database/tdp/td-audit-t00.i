/*------------------------------------------------------------------------
    File        : td-audit-t00.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Lopes
    Created     : Fri Apr 17 14:15:41 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/
using thl-lib.logging.audit.AuditLogService.

{include/i-prgvrs.i td-audit-t00 12.00.00.000}

//Definitions
define parameter buffer b-{1}   for {1}.

//Main Block

new AuditLogService():deleteRecord( buffer b-{1}:handle ).