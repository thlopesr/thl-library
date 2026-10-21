/*------------------------------------------------------------------------
    File        : MessageConfigLoader
    Purpose     : Base dos carregadores de configuracao de mensagem: leitura
                  de thl-objeto, thl-objeto-parametro (operacao) e da extensao
                  do modelo de integracao (thl-objeto-parametro-rest).
    Author(s)   : Lopes
    Created     : 2026-10-04
    Notes       : Filhas: InboundConfigLoader (entrada) e OutboundConfigLoader
                  (saida). Cada uma posiciona a operacao do seu jeito; a base
                  resolve o que e comum:
                  - classes: so as da linha da operacao (copiadas de thl-objeto na criacao);
                  - verbo HTTP: o da extensao REST; sem extensao, o da
                    operacao (cadastro anterior a extensao);
                  - thl-objeto-parametro.metodo e o metodo da operacao (no
                    objeto REST, o verbo HTTP) e faz parte da chave, que a
                    extensao repete.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

using thl-lib.integration.messaging.core.MessageConfig.
using thl-lib.util.string.StringUtil.

block-level on error undo, throw.

class thl-lib.integration.messaging.repository.MessageConfigLoader abstract.

    define protected buffer b-thl-objeto                for thl-objeto.
    define protected buffer b-thl-objeto-parametro      for thl-objeto-parametro.
    define protected buffer b-thl-objeto-parametro-rest for thl-objeto-parametro-rest.

    //Posiciona b-thl-objeto (no-lock). Nao lanca erro: a filha decide a mensagem.
    method protected void findObject( input applicationName as character ,
                                      input objectName      as character ).

        find first b-thl-objeto no-lock
            where b-thl-objeto.aplicacao = applicationName
              and b-thl-objeto.objeto    = objectName
            no-error.

    end method.

    //Posiciona a extensao REST da operacao ja posicionada. Pode nao existir:
    //operacao criada antes da extensao ou objeto de outro modelo de integracao.
    method protected void findRestExtension().

        find first b-thl-objeto-parametro-rest no-lock
            where b-thl-objeto-parametro-rest.cod-estabel = b-thl-objeto-parametro.cod-estabel
              and b-thl-objeto-parametro-rest.aplicacao   = b-thl-objeto-parametro.aplicacao
              and b-thl-objeto-parametro-rest.objeto      = b-thl-objeto-parametro.objeto
              and b-thl-objeto-parametro-rest.operacao    = b-thl-objeto-parametro.operacao
              and b-thl-objeto-parametro-rest.metodo      = b-thl-objeto-parametro.metodo
            no-error.

    end method.

    //Metodo da operacao: campo da chave
    method protected integer resolveMethod().

        return b-thl-objeto-parametro.metodo.

    end method.

    //Classes: so as da linha da operacao (thl0022, aba Classe). Nascem copiadas de
    //thl-objeto na criacao da linha; a execucao nao le mais as classes do objeto.
    method protected character resolveMessageClass().
        return b-thl-objeto-parametro.classe-objeto.
    end method.

    method protected character resolveProcessorClass().
        return b-thl-objeto-parametro.classe-processor.
    end method.

    method protected character resolveServiceClass().
        return b-thl-objeto-parametro.classe-service.
    end method.

    //Configuracao comum, a partir do objeto e da operacao ja posicionados
    method protected MessageConfig buildConfig().

        this-object:findRestExtension().

        return new MessageConfig( b-thl-objeto.objeto                      ,
                                  b-thl-objeto.aplicacao                   ,
                                  this-object:resolveMethod()              ,
                                  this-object:resolveMessageClass()        ,
                                  b-thl-objeto.modelo-integracao           ,
                                  b-thl-objeto.ind-gera-historico or b-thl-objeto-parametro.ind-gera-historico,
                                  b-thl-objeto.sentido-fluxo               ,
                                  b-thl-objeto-parametro.forma-execucao    ,
                                  b-thl-objeto-parametro.ind-mensagem-simples,
                                  b-thl-objeto-parametro.cod-param-ambiente  ,
                                  b-thl-objeto-parametro.cod-param-ambiente-destino ,
                                  b-thl-objeto-parametro.operacao            ,
                                  b-thl-objeto-parametro.tipo-grava-conteudo ).

    end method.

end class.
