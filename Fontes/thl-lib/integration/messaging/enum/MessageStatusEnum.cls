
/*------------------------------------------------------------------------
    File        : MessageStatusEnum
    Purpose     : Status de processamento de mensagem de integracao
    Description : Reflete os valores de sit-requisicao, sit-processamento
                  e sit-retorno em thl-mensagem.
                  Alinhado com i01thl011.i.
    Author(s)   : Lopes
  ----------------------------------------------------------------------*/

enum thl-lib.integration.messaging.enum.MessageStatusEnum.

    define enum PENDING        = 1
                ERROR          = 2
                SUCCESS        = 3
                NOT_APPLICABLE = 4.

end enum.
