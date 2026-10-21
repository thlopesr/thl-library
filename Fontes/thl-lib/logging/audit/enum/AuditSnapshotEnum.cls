
/*------------------------------------------------------------------------
    File        : AuditSnapshotEnum
    Purpose     : Identifica o snapshot em thl-audit-registro-detalhe.tipo:
                  Atual = estado apos a operacao (buffer new).
                  Anterior = estado antes da operacao (buffer old).
    Author(s)   : Lopes
    Created     : 2026-08-14
  ----------------------------------------------------------------------*/

enum thl-lib.logging.audit.enum.AuditSnapshotEnum.

    define enum Atual     = 1
                Anterior  = 2
                .

end enum.
