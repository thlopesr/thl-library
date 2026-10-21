
/*------------------------------------------------------------------------
    File        : ActionEnum
    Purpose     : Acoes de negocio do contrato IService.
    Author(s)   : Lopes
    Created     : 2026-07-26
    Notes       : Usado como parametro de execute() em IService e
                  executeAndRegister() em InboundMessage.
  ----------------------------------------------------------------------*/

enum thl-lib.erp.enum.ActionEnum.

    define enum Criado     = 1
                Atualizado = 2
                Deletado   = 3
                Consultado = 4
                .

end enum.
