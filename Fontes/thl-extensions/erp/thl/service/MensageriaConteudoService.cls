/*------------------------------------------------------------------------
    File        : MensageriaService
    Purpose     : Servico de dominio para consulta de mensagens de
                  integracao (thl-mensagem). Somente leitura - busca por
                  ranges (padrao thl0120), detalhe por codigo.
    Author(s)   : Lopes
    Created     : Wed Sep 10 2026
    Notes       : Segue padrao canonico LpcoService - herda Service,
                  paginacao via PaginationHelper (composicao).
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.integration.messaging.enum.DirectionEnum.
using thl-lib.integration.messaging.enum.MessageStatusEnum.
using thl-lib.integration.connectors.enum.MethodTypeEnum.
using thl-lib.integration.connectors.enum.ConnectorTypeEnum.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.MensageriaConteudoService inherits Service.

    define private buffer b-mensagem-conteudo    for thl-mensagem-conteudo.
    
    method public override character getEntityName().
        return 'MensageriaConteudo'.
    end method.

    method public override character loadReferenceCode().
        if available b-mensagem-conteudo then
            return substitute( '&1#&2'                            , 
                               b-mensagem-conteudo.codigo-mensagem,
                               b-mensagem-conteudo.tipo-conteudo  ).
        return ''.
    end method.

    //Consulta (rota mensageria/conteudo): detalhe de uma mensagem
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getText   ( 'id'  , '' ),
                                queryParameters:getInteger( 'tipo', 0  ) ).
    end method.

    method public JsonObject get ( messageCode as character,
                                   messageType as integer  ).

        define variable contem as JsonObject no-undo.

        assign contem = new JsonObject().

        for each b-mensagem-conteudo no-lock
            where b-mensagem-conteudo.codigo-mensagem = messageCode
              and b-mensagem-conteudo.tipo-conteudo   = messageType.
            contem:add( 'payload'      , getDetilValue()    ).
            contem:add( 'referenceCode', loadReferenceCode()).
        end.

        return contem.

    end method.
    
    method private longchar getDetilValue().
    
        define variable detailValue as longchar no-undo.
    
        if available b-mensagem-conteudo then
            assign detailValue = b-mensagem-conteudo.conteudo.
    
        return detailValue.
    
    end method.

end class.
