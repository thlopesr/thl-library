 /*------------------------------------------------------------------------
    File        : IHeaderProvider
    Purpose     : Contrato para provedores de headers HTTP calculados.
                  Implementacoes recebem o body da requisicao e retornam
                  um JsonArray de objetos {key, value} a injetar.
    Author(s)   : Lopes
    Created     : Sun Aug 24 00:00:00 BRT 2026
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*. 

interface thl-lib.integration.connectors.headers.interfaces.IHeaderProvider.

    method public JsonArray getHeaders ( body       as longchar  ,
                                         parameters as character ).

end interface.
