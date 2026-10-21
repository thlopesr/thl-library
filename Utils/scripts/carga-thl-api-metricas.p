/*------------------------------------------------------------------------
    File        : carga-thl-api-metricas.p
    Purpose     : Cadastra a operacao "metricas" (metodo GET) nos objetos das
                  consultas de mensageria, e-mail e auditoria, para as rotas
                  .../resourcen/mensageria/metricas, .../email/metricas e
                  .../auditoria/metricas.
    Created     : 2026-10-03
    Notes       : - Com dois segmentos na URL, o InboundRouteResolver trata o
                    ultimo como operacao: nao ha rota nova em
                    thl-objeto-rota, so o thl-objeto-parametro da operacao.
                  - O objeto de cada rota e resolvido como no roteador: pela
                    thl-objeto-rota ativa; sem cadastro, aplicacao TOTVS e
                    objeto = rota.
                  - A operacao nasce com gravacao de conteudo "somente em erro"
                    (tipo-grava-conteudo = 2): a resposta aberta das metricas
                    nao e gravada em thl-mensagem-conteudo. Exige o delta
                    Database/delta-thl-2026-10-03.df carregado.
                  - Idempotente: parametro ja cadastrado nao e alterado.
                  - Roda em SIMULACAO por padrao (simulate = yes): so gera o
                    log. Para gravar, altere simulate para no e rode de novo.
                  - Log: <session:temp-directory>carga-thl-api-metricas.log
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

define variable simulate      as logical   no-undo initial yes.
define variable operationName as character no-undo initial "metricas".
define variable logFile       as character no-undo.
define variable created       as integer   no-undo.
define variable existing      as integer   no-undo.
define variable failed        as integer   no-undo.

define stream logStream.

/* ***************************  Main Block  *************************** */

logFile = session:temp-directory + "carga-thl-api-metricas.log".

output stream logStream to value( logFile ).
put stream logStream unformatted
    "Carga da operacao metricas em " string( now ) ( if simulate then " - SIMULACAO (nada gravado)" else "" ) skip
    "tabela;chave;acao" skip.

run loadMetricsParameter( "mensageria" ).
run loadMetricsParameter( "email"      ).
run loadMetricsParameter( "auditoria"  ).

put stream logStream unformatted skip
    ( if simulate then "Seriam criados: " else "Criados: " ) created skip
    "Ja cadastrados: " existing skip
    "Erros: " failed skip.
output stream logStream close.

message ( if simulate then "SIMULACAO - nada foi gravado." + chr(10) else "" )
        ( if simulate then "Seriam criados: " else "Criados: " ) created chr(10)
        "Ja cadastrados: " existing chr(10)
        "Erros: " failed chr(10)
        "Log: " logFile
    view-as alert-box information.

/* **********************  Internal Procedures  *********************** */

procedure loadMetricsParameter private:
    define input parameter routePath as character no-undo.

    define variable applicationName as character no-undo.
    define variable objectName      as character no-undo.
    define variable paramKey        as character no-undo.

    // mesma regra do InboundRouteResolver
    find first thl-objeto-rota no-lock
        where thl-objeto-rota.rota-publica = routePath
          and thl-objeto-rota.ind-ativo
        no-error.

    if available thl-objeto-rota then
        assign applicationName = thl-objeto-rota.aplicacao
               objectName      = thl-objeto-rota.objeto.
    else
        assign applicationName = "TOTVS"
               objectName      = routePath.

    assign paramKey = substitute( "*/&1/&2/&3", applicationName, objectName, operationName ).

    if not can-find( thl-objeto where thl-objeto.aplicacao = applicationName
                                  and thl-objeto.objeto    = objectName ) then do:
        run writeResult( "erro: objeto da rota " + routePath + " nao cadastrado em thl-objeto", paramKey ).
        assign failed = failed + 1.
        return.
    end.

    if can-find( thl-objeto-parametro where thl-objeto-parametro.cod-estabel = "*"
                                        and thl-objeto-parametro.aplicacao   = applicationName
                                        and thl-objeto-parametro.objeto      = objectName
                                        and thl-objeto-parametro.operacao    = operationName ) then do:
        run writeResult( "ja cadastrado", paramKey ).
        assign existing = existing + 1.
        return.
    end.

    // as classes da linha nascem copiadas do objeto
    find first thl-objeto no-lock
        where thl-objeto.aplicacao = applicationName
          and thl-objeto.objeto    = objectName
        no-error.


    if not simulate then do transaction:
        create thl-objeto-parametro.
        assign thl-objeto-parametro.cod-estabel          = "*"
               thl-objeto-parametro.aplicacao            = applicationName
               thl-objeto-parametro.objeto               = objectName
               thl-objeto-parametro.operacao             = operationName
               thl-objeto-parametro.metodo               = 5     // GET
               thl-objeto-parametro.classe-objeto        = thl-objeto.classe-objeto
               thl-objeto-parametro.classe-processor     = thl-objeto.classe-processor
               thl-objeto-parametro.classe-service       = thl-objeto.classe-service
               thl-objeto-parametro.forma-execucao       = 1     // Online
               thl-objeto-parametro.ind-inativo          = no
               thl-objeto-parametro.ind-mensagem-simples = no
               thl-objeto-parametro.ind-gera-historico   = no
               thl-objeto-parametro.tipo-grava-conteudo  = 2.    // Somente em erro: a resposta aberta nao vai para o banco
    end.

    run writeResult( if simulate then "seria criado" else "criado", paramKey ).
    assign created = created + 1.

    // erro num registro nao interrompe os demais; fica registrado no log
    catch loadError as Progress.Lang.Error:
        run writeResult( "erro: " + loadError:GetMessage( 1 ), paramKey ).
        assign failed = failed + 1.
    end catch.
end procedure.

procedure writeResult private:
    define input parameter action   as character no-undo.
    define input parameter keyValue as character no-undo.

    put stream logStream unformatted "thl-objeto-parametro;" keyValue ";" action skip.
end procedure.
