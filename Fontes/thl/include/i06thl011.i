
/*------------------------------------------------------------------------
    File        : i06thl011.i
    Purpose     : Dominio de thl-objeto-parametro.metodo: o metodo da operacao.
                  A lista exibida acompanha o tipo do objeto (REST: 1 a 5).

    Syntax      :

    Description : REST alinhado com thl-lib.integration.connectors.enum.MethodTypeEnum.

    Author(s)   : Lopes
    Created     : 2026-10-05
    Notes       :
  ----------------------------------------------------------------------*/

{include/i-lgcode.i}

&global val1 POST
&global val2 PUT
&global val3 PATCH
&global val4 DELETE
&global val5 GET
&global val6 INSERT
&global val7 UPDATE
&global val8 SELECT

{include/ind01-10.i {1} {2}}
