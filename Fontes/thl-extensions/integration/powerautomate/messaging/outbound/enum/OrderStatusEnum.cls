/*------------------------------------------------------------------------
    File        : OrderStatusEnum
    Purpose     : Situacao da ordem de compra (ordem-compra.situacao).
    Author(s)   : Lopes
    Created     : 2026-09-05
  ----------------------------------------------------------------------*/

enum thl-extensions.integration.powerautomate.messaging.outbound.enum.OrderStatusEnum.

    define enum NAO_CONFIRMADA = 1
                CONFIRMADA     = 2
                COTADA         = 3
                ELIMINADA      = 4
                EM_COTACAO     = 5
                RECEBIDA       = 6
                .

end enum.
