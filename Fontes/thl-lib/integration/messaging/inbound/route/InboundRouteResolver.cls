 
 /*------------------------------------------------------------------------
    File        : Message
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Lopes
    Created     : Thu Jul 01 08:25:57 BRT 2021
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using thl-lib.core.error.ThlError.
using Progress.Json.ObjectModel.*.

block-level on error undo, throw.

class thl-lib.integration.messaging.inbound.route.InboundRouteResolver.

    define private variable pathParameters as JsonArray no-undo.
    define private variable routePath      as character no-undo.
    define private variable operation      as character no-undo.
    define private variable objectCode     as character no-undo.
    define private variable application    as character no-undo.

    constructor public InboundRouteResolver(input pathParameters_ as JsonArray).

        assign this-object:pathParameters = pathParameters_.

        this-object:Resolve().

    end constructor.

    method private void Resolve().

        define variable count     as integer   no-undo.
        define variable routePart as character no-undo.

        if not valid-object(this-object:pathParameters) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'resolve', 'Rota inbound invalida.' ).
            
        if this-object:pathParameters:Length = 1 then
            assign this-object:routePath = this-object:pathParameters:GetCharacter( this-object:pathParameters:Length ).  
            
        else do.    
            assign this-object:operation = this-object:pathParameters:GetCharacter( this-object:pathParameters:Length ).
            
            do count = 1 to this-object:pathParameters:Length - 1.
                if routePart <> '' then
                    assign routePart = routePart + '/'.
                assign routePart = routePart + this-object:pathParameters:GetCharacter(count).
            end.
    
            assign this-object:routePath = routePart.
        end.
        this-object:ResolveObjectCode().

    end method.

    method private void ResolveObjectCode().

        //thl-objeto-rota: uma rota por objeto (chave aplicacao + objeto); a busca e pelo caminho publico
        find first thl-objeto-rota no-lock
            where thl-objeto-rota.rota-publica = this-object:routePath
              and thl-objeto-rota.ind-ativo    
            no-error.

        //uma rota por objeto: sem rota exata, vale a rota cadastrada mais longa que
        //inicia a URL, e o resto vira a operacao (notafiscal/embarque/geracao ->
        //rota notafiscal, operacao embarque/geracao)
        if not available thl-objeto-rota then
            this-object:findRouteByPrefix().
        
        if available thl-objeto-rota then     
            assign this-object:objectCode  = thl-objeto-rota.objeto
                   this-object:application = thl-objeto-rota.aplicacao.
        else
            assign this-object:objectCode  = replace( this-object:routePath, '/', '')
                   this-object:application = 'TOTVS'.    

        //rota com mais de um nivel de operacao (thl-objeto-rota.inicio-operacao):
        //a operacao vai do segmento informado ate o ultimo. Zero = so o ultimo segmento.
        if available thl-objeto-rota              and
           thl-objeto-rota.inicio-operacao >= 2   then
            this-object:composeOperation( thl-objeto-rota.inicio-operacao ).

    end method.
    
    //Procura a rota pelos primeiros segmentos da URL, do maior para o menor.
    //Achando, a rota e a encontrada e a operacao sao os segmentos seguintes.
    method private void findRouteByPrefix().

        define variable lastSegment as integer   no-undo.
        define variable count       as integer   no-undo.
        define variable routePart   as character no-undo.

        do lastSegment = this-object:pathParameters:Length - 2 to 1 by -1.

            assign routePart = ''.

            do count = 1 to lastSegment.
                assign routePart = routePart + ( if routePart = '' then '' else '/' )
                                 + this-object:pathParameters:GetCharacter( count ).
            end.

            find first thl-objeto-rota no-lock
                where thl-objeto-rota.rota-publica = routePart
                  and thl-objeto-rota.ind-ativo
                no-error.

            if available thl-objeto-rota then do.
                assign this-object:routePath = routePart.
                this-object:composeOperation( lastSegment + 1 ).
                return.
            end.

        end.

    end method.

    //Operacao composta: junta com / os segmentos da URL a partir do informado.
    //Ex.: notafiscal/embarque/geracao com inicio 2 -> embarque/geracao.
    method private void composeOperation( input firstSegment as integer ).

        define variable count    as integer   no-undo.
        define variable composed as character no-undo.

        if firstSegment > this-object:pathParameters:Length then
            return.

        do count = firstSegment to this-object:pathParameters:Length.
            assign composed = composed + ( if composed = '' then '' else '/' )
                            + this-object:pathParameters:GetCharacter( count ).
        end.

        assign this-object:operation = composed.

    end method.

    method public character GetApplication().
        return this-object:application.
    end method.

    method public character GetObjectCode().
        return this-object:objectCode.
    end method.

    method public character GetOperation().
        return this-object:operation.
    end method.

    method public character GetRoutePath().
        return this-object:routePath.
    end method.

end class.