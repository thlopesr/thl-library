
 /*------------------------------------------------------------------------
    File        : ThlError
    Purpose     : Subclasse de AppError que padroniza o formato de mensagem
                  de erro como [NomeClasse.nomeMetodo] descricao.
    Author(s)   : Lopes
    Created     : Sat Jun 13 2026
    Notes       : Quatro construtores:
                    - padrao: errorNumber = 17006 (Totvs)
                    - explicito: errorNumber informado pelo caller
                    - direto: mensagem ja formatada (usado pelo ErrorHandler)
                    - innerError: preserva stack da excecao original
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

class thl-lib.core.error.ThlError inherits Progress.Lang.AppError.

    constructor public ThlError( className   as character,
                                 methodName  as character,
                                 textMessage as character).
        super( substitute( '&3 [&1.&2]', className, methodName, textMessage ), 17006 ).
    end constructor.

    constructor public ThlError( errorMessage as character,
                                 errorNumber  as integer  ).
        super( errorMessage, errorNumber ).
    end constructor.

    constructor public ThlError( className   as character,
                                 methodName  as character,
                                 textMessage as character,
                                 errorNumber as integer   ).
        super( substitute( '&3 [&1.&2]', className, methodName, textMessage ), errorNumber ).
    end constructor.

    constructor public ThlError( className  as character        ,
                                 methodName as character        ,
                                 innerError as Progress.Lang.Error ).

        define variable i as integer no-undo.

        super( substitute( 'Erro em [&1.&2]', className, methodName ), 17006 ).

        do i = 1 to innerError:NumMessages.
            this-object:AddMessage( innerError:GetMessage(i), innerError:GetMessageNum(i) ).
        end.

    end constructor.

end class.
