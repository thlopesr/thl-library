/*------------------------------------------------------------------------
    File        : IMetricsService
    Purpose     : Service de consulta que tambem devolve metricas (totais do
                  periodo) alem da listagem.
    Author(s)   : Lopes
    Created     : 2026-10-08
    Notes       : A listagem e o consult() do Service; as metricas sao este
                  metodo. Quem escolhe entre os dois, pela operacao da URL
                  (<rota>/metricas), e o MetricsProcessor - o Service nao le
                  a operacao para se despachar.
                  Os filtros vem de queryParameters, como no consult().
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.

interface thl-extensions.erp.thl.interfaces.IMetricsService.

    method public JsonConstruct consultMetrics().

end interface.
