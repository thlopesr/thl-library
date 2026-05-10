 
 /*------------------------------------------------------------------------
    File        : MessageRepository
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Sat Mar 07 08:34:45 BRT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.integration.messaging.core.MessageConfig.

block-level on error undo, throw.

class thl-lib.integration.messaging.repository.MessageConfigLoader.  

    method public MessageConfig load( establishmentCode    as character ,
                                      objectName           as character ,
                                      integrationOperation as character ).

        find first thl-objeto no-lock
            where thl-objeto.objeto    = objectName
            no-error.

        find first thl-objeto-param no-lock
            where thl-objeto-param.cod-estabel = establishmentCode
              and thl-objeto-param.objeto      = objectName 
              and thl-objeto-param.operacao    = integrationOperation 
            no-error.

        if not available thl-objeto-param then
            find first thl-objeto-param no-lock
                where thl-objeto-param.cod-estabel = '*'
                  and thl-objeto-param.objeto      = objectName 
                  and thl-objeto-param.operacao    = integrationOperation 
                no-error.
                        
        if not available thl-objeto       or
           not available thl-objeto-param then
            undo, throw new AppError( substitute( 'Configuration for object &1, operation &2 and establishment &3 was not found.', objectName, integrationOperation, establishmentCode), 17006 ).

        if thl-objeto.ind-inativo       or
           thl-objeto-param.ind-inativo then
            undo, throw new AppError( substitute( 'Object &1 and/or operation &2 for establishment &3 is inactive.', objectName, integrationOperation, establishmentCode ), 17006 ).
        
        return setMessageConfig().

    end method.
    
    method public MessageConfig load( objectName as character ,
                                      methodType as integer   ).

        find first thl-objeto no-lock
            where thl-objeto.objeto    = objectName
            no-error.

        find first thl-objeto-param no-lock
            where thl-objeto-param.objeto      = objectName 
              and thl-objeto-parametro.metodo  = methodType 
            no-error.
        
        if not available thl-objeto       or
           not available thl-objeto-param then
            undo, throw new AppError( substitute( 'Configuration for object &1 and connectorType &2 was not found.', objectName, methodType ), 17006 ).

        if thl-objeto.ind-inativo       or
           thl-objeto-param.ind-inativo then
            undo, throw new AppError( substitute( 'Object &1 and/or method &2 is inactive.', objectName, methodType ), 17006 ).
        
        return setMessageConfig().

    end method.
    
    method public MessageConfig setMessageConfig ().
        return new MessageConfig( thl-objeto.objeto                   ,
                                  thl-objeto-parametro.metodo         ,  
                                  thl-objeto.classe-objeto            ,
                                  thl-objeto.programa-consulta        ,
                                  thl-objeto.modelo-integracao        ,
                                  thl-objeto.ind-gera-historico or thl-objeto-param.ind-gera-historico,
                                  thl-objeto.sentido-fluxo            ,
                                  thl-objeto-param.forma-execucao     ,
                                  thl-objeto-param.ind-mensagem-simple,
                                  thl-objeto-param.cod-param-ambiente ,
                                  thl-objeto-param.cod-param-ambiente-destino ,
                                  thl-objeto-param.operacao           ).
    end method.    
    
end class.