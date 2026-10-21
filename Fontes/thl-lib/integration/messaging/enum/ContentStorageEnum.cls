
/*------------------------------------------------------------------------
    File        : ContentStorageEnum
    Purpose     : Gravacao do conteudo (requisicao e retorno) da mensagem em
                  thl-mensagem-conteudo, por operacao do objeto.
    Description : Reflete thl-objeto-parametro.tipo-grava-conteudo.
                  Alinhado com thl/include/i05thl011.i.
                  ALWAYS     - sempre grava (padrao).
                  ERROR_ONLY - grava somente quando a mensagem falha.
                  NEVER      - nunca grava; fica so a thl-mensagem.
                  Requisicao do outbound e do inbound agendado e gravada
                  sempre, qualquer que seja a opcao (reenvio e RPW).
    Author(s)   : Lopes
    Created     : 2026-10-03
  ----------------------------------------------------------------------*/

enum thl-lib.integration.messaging.enum.ContentStorageEnum.

    define enum ALWAYS     = 1
                ERROR_ONLY = 2
                NEVER      = 3.

end enum.
