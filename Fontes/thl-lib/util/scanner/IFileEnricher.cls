/*------------------------------------------------------------------------
    File        : IFileEnricher
    Purpose     : Interface para enriquecimento de um ScannedFileSet.
                  Qualquer classe que processe ou adicione informacoes
                  aos arquivos varridos deve implementar esta interface.
    Author(s)   : Lopes
    Created     : 2026-09-16
    Notes       : Ponto de extensao: busca textual, classificacao,
                  contagem de linhas, etc.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

using thl-lib.util.scanner.ScannedFileSet.

interface thl-lib.util.scanner.IFileEnricher.

    method public void enrich( input fileSet as ScannedFileSet ).

end interface.
