# P8-L1-SUGESTOES
# formato: SEV|Classe|Metodo|Categoria|Risco|Tipo|Resumo-max-8-palavras
ALTA|ConnectorFactory|createConnector|D4|MEDIO|CIRURGICA|substituir-CASE-por-registry-TEMP-TABLE-DYNAMIC-NEW
ALTA|RestConnector|execute|B3|BAIXO|CIRURGICA|VALID-OBJECT-authentication-validateExecutionInput-resolveAuth
MEDIA|ConnectorConfig|constructor|B1|MEDIO|CIRURGICA|guard-connectionCode-vazio-fixar-erro-17006-private-initialize
MEDIA|ConnectorConfig|constructor|D2|MEDIO|CIRURGICA|mover-new-AuthConfig-para-construtores-initialize-setter-puro
MEDIA|RestConnector|(classe)|D3|BAIXO|CIRURGICA|resolveAuthorizationKey-recebe-ConnectorConfig-nao-AuthConfig

# P8-L1-NOTAS
# Items 3 e 4 (ConnectorConfig B1+D2) devem ser aplicados em edicao coordenada unica
# Items 2 e 5 (RestConnector B3+D3) devem ser aplicados em edicao coordenada unica
# AuthenticationConfig.cls: adicionar block-level + fixar erro 0->17006 (fora deste lote)
# RestConnector D3: backlog estrutural residual = TokenRefreshService (separacao de HTTP+auth)

# P8-L1-RESUMO
CIRURGICA:5|ESTRUTURAL:0
RISCO-ALTO:0|RISCO-MEDIO:3|RISCO-BAIXO:2
TOTAL:5
