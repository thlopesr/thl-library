/*------------------------------------------------------------------------
    File        : ClassVariableEnum
    Purpose     : Variaveis do parametro de ambiente thl.classe (thl0002) com as classes
                  padrao do objeto de integracao e da operacao.
    Author(s)   : Lopes
    Created     : 2026-10-15
    Notes       : O codigo da variavel no thl0002 e o nome do membro em minusculas, com
                  '_' virando '.': MENSAGEM_ENTRADA -> mensagem.entrada.
                  Leitura: new EnvironmentResource():getEnvironmentVariable( <membro> ); o parametro
                  (thl.classe) vem do programa que chama, vinculado na aba Programa do thl0002.
                  Processor e service so valem em objeto de entrada.
  ----------------------------------------------------------------------*/

enum thl-extensions.erp.thl.enum.ClassVariableEnum.

    define enum MENSAGEM_ENTRADA  = 1
                MENSAGEM_SAIDA    = 2
                PROCESSOR_ENTRADA = 3
                SERVICE_ENTRADA   = 4
                .

end enum.
