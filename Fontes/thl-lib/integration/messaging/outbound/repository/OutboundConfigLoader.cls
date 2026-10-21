
/*------------------------------------------------------------------------
    File        : OutboundConfigLoader
    Purpose     : Configuracao de uma mensagem de saida: busca o parametro
                  do objeto por estabelecimento + operacao (o estabelecimento
                  informado e, sem ele, o generico *).
    Author(s)   : Lopes
    Created     : 2026-10-04
    Notes       : Mesma busca e mesmas mensagens de erro que estavam no
                  MessageConfigLoader:load( estabelecimento, aplicacao,
                  objeto, operacao ) ate 2026-10-03.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.integration.messaging.core.MessageConfig.
using thl-lib.integration.messaging.repository.MessageConfigLoader.
using thl-lib.util.string.StringUtil.

block-level on error undo, throw.

class thl-lib.integration.messaging.outbound.repository.OutboundConfigLoader inherits MessageConfigLoader.

    method public MessageConfig load( establishmentCode    as character ,
                                      applicationName      as character ,
                                      objectName           as character ,
                                      integrationOperation as character ).

        this-object:findObject( applicationName, objectName ).

        find first b-thl-objeto-parametro no-lock
            where b-thl-objeto-parametro.aplicacao   = applicationName
              and b-thl-objeto-parametro.cod-estabel = establishmentCode
              and b-thl-objeto-parametro.objeto      = objectName
              and b-thl-objeto-parametro.operacao    = integrationOperation
            no-error.

        if not available b-thl-objeto-parametro then
            find first b-thl-objeto-parametro no-lock
                where b-thl-objeto-parametro.aplicacao   = applicationName
                  and b-thl-objeto-parametro.cod-estabel = '*'
                  and b-thl-objeto-parametro.objeto      = objectName
                  and b-thl-objeto-parametro.operacao    = integrationOperation
                no-error.

        if not available b-thl-objeto           or
           not available b-thl-objeto-parametro then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'load', substitute( 'Configuracao para objeto &1, operacao &2 e estabelecimento &3 nao encontrada.', objectName, integrationOperation, establishmentCode ) ).

        if b-thl-objeto.ind-inativo           or
           b-thl-objeto-parametro.ind-inativo then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'load', substitute( 'Objeto &1 e/ou operacao &2 para o estabelecimento &3 esta inativo.', objectName, integrationOperation, establishmentCode ) ).

        //a classe da mensagem vem so da linha da operacao (copiada de thl-objeto na criacao)
        if not StringUtil:hasValue( this-object:resolveMessageClass() ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'load', substitute( 'Operacao &1/&2/&3 sem classe da mensagem no cadastro (thl0022, aba Classe).', applicationName, objectName, integrationOperation ) ).

        return this-object:buildConfig().

    end method.

end class.
