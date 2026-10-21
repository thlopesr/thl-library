/*------------------------------------------------------------------------
    File        : FieldDefaultEnum
    Purpose     : Variaveis do thl0002 com o valor padrao dos campos do objeto (thl0021) e da
                  operacao (thl0022a) na inclusao.
    Author(s)   : Lopes
    Created     : 2026-10-15
    Notes       : O codigo da variavel e o nome do membro em minusculas, com '_' virando '.':
                  OBJETO_RETENCAO_DIAS_SUCESSO -> objeto.retencao.dias.sucesso.
                  O parametro vem do programa que chama (aba Programa do thl0002).
                  Valor em branco ou variavel ausente: o campo fica com o valor inicial do
                  banco. Logico: yes ou no; combo e radio: o valor da lista (ex.: 1);
                  numerico: o numero. Classes ficam no ClassVariableEnum.
  ----------------------------------------------------------------------*/

enum thl-extensions.erp.thl.enum.FieldDefaultEnum.

    define enum OBJETO_IND_INATIVO               = 1
                OBJETO_IND_GERA_HISTORICO        = 2
                OBJETO_SENTIDO_FLUXO             = 3
                OBJETO_MODELO_INTEGRACAO         = 4
                OBJETO_RETENCAO_DIAS_SUCESSO     = 5
                OBJETO_RETENCAO_DIAS_ERRO        = 6
                OBJETO_PROGRAMA_CONSULTA         = 7
                OPERACAO_ESTABELECIMENTO         = 10
                OPERACAO_METODO                  = 11
                OPERACAO_IND_INATIVO             = 12
                OPERACAO_IND_GERA_HISTORICO      = 13
                OPERACAO_TIPO_GRAVA_CONTEUDO     = 14
                OPERACAO_FORMA_EXECUCAO          = 15
                OPERACAO_IND_PERSISTENTE         = 16
                OPERACAO_FREQUENCIA_EXECUCAO     = 17
                OPERACAO_DIAS_PERSIST            = 18
                OPERACAO_TENTATIVAS_PERSIST      = 19
                OPERACAO_TIPO_LOG_REQUISICAO     = 20
                OPERACAO_TIPO_LOG_RETORNO        = 21
                OPERACAO_IND_MENSAGEM_SIMPLES    = 22
                OPERACAO_PARAM_AMBIENTE          = 23
                OPERACAO_PARAM_AMB_DESTINO       = 24
                OPERACAO_SERVIDOR_EXECUCAO       = 25
                .

end enum.
