/*------------------------------------------------------------------------
    File        : DateTimeUtil
    Purpose     : Utilitarios estaticos de data e hora: soma de horas, dias,
                  meses e anos, sempre devolvendo datetime (sem fuso).
    Author(s)   : Lopes
    Created     : 2026-10-13
    Notes       : add-interval sobre now devolve datetime-tz e esse valor nao
                  pode ser passado direto onde se espera datetime. A conversao
                  (atribuicao a uma variavel datetime) fica aqui, num lugar so.
                  Quantidade negativa volta no tempo. Base desconhecida (?)
                  devolve ?.
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

class thl-lib.util.date.DateTimeUtil.

    //Data e hora atuais (now), ja como datetime.
    method public static final datetime currentDateTime().
        return now.
    end method.

    method public static final datetime addHours( input baseDateTime as datetime-tz ,
                                                  input hours        as integer     ).
        return addInterval( baseDateTime, hours, 'hours' ).
    end method.

    method public static final datetime addDays( input baseDateTime as datetime-tz ,
                                                 input days         as integer     ).
        return addInterval( baseDateTime, days, 'days' ).
    end method.

    method public static final datetime addMonths( input baseDateTime as datetime-tz ,
                                                   input months       as integer     ).
        return addInterval( baseDateTime, months, 'months' ).
    end method.

    method public static final datetime addYears( input baseDateTime as datetime-tz ,
                                                  input years        as integer     ).
        return addInterval( baseDateTime, years, 'years' ).
    end method.

    method private static datetime addInterval( input baseDateTime as datetime-tz ,
                                                input amount       as integer     ,
                                                input intervalUnit as character   ).

        define variable shifted as datetime no-undo.

        if baseDateTime = ? then
            return ?.

        assign shifted = add-interval( baseDateTime, amount, intervalUnit ).

        return shifted.

    end method.

end class.
