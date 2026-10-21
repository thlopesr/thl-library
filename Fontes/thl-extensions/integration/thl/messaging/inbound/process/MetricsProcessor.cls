/*------------------------------------------------------------------------
    File        : MetricsProcessor
    Purpose     : Orquestracao de consulta com metricas: a mesma acao (GET) tem
                  duas operacoes.
                  /resourcen/<rota>          -> consult()         (listagem)
                  /resourcen/<rota>/metricas -> consultMetrics()  (totais)
    Author(s)   : Lopes
    Created     : 2026-10-08
    Notes       : Filha de thl-lib.integration.messaging.inbound.core.Processor: sobrescreve
                  invokeQuery e chama o metodo do Service da operacao. O
                  Service precisa implementar
                  thl-lib.erp.interfaces.IMetricsService.
                  Registrada em thl-objeto.classe-processor pelo nome completo
                  (ou herdada pelo Processor do agregado, como o
                  MensageriaProcessor).
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-extensions.erp.thl.interfaces.IMetricsService.
using thl-lib.integration.messaging.inbound.core.Processor.

block-level on error undo, throw.

class thl-extensions.integration.thl.messaging.inbound.process.MetricsProcessor inherits Processor.

    method protected override JsonConstruct invokeQuery( input targetService as Service   ,
                                                         input operation     as character ).

        if operation <> 'metricas' then
            return super:invokeQuery( targetService, operation ).

        if not type-of( targetService, IMetricsService ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'invokeQuery',
                substitute( 'Service &1 nao tem metricas (IMetricsService).', targetService:GetClass():TypeName ) ).

        return cast( targetService, IMetricsService ):consultMetrics().

    end method.

end class.
