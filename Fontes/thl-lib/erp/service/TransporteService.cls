/*------------------------------------------------------------------------
    File        : TransporteService
    Purpose     : Servico de dominio para consulta de transportador na
                  tabela transporte do Datasul.
                  Sem logica de apresentacao ou serializacao JSON.
    Author(s)   : Lopes
    Created     : 2026-09-30
    Notes       : Servico de consulta puro - so GET (modelo EmitenteService).
                  Busca por cod-transp quando informado (> 0), pelo indice
                  codigo; senao por nome-abrev, pelo indice unico nome.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.

block-level on error undo, throw.

class thl-lib.erp.service.TransporteService inherits Service.

    define private buffer b-transporte for transporte.

    method public override character getEntityName().
        return 'Transporte'.
    end method.

    method public override character loadReferenceCode().
        if available b-transporte then
            return string( b-transporte.cod-transp ).
        return ''.
    end method.

    //GET pelo Processor: le os filtros da query e devolve o mesmo objeto do get()
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getInteger( 'codigo', 0  ),
                                queryParameters:getText   ( 'nome'  , '' ) ).
    end method.

    method public JsonObject get ( input cod-transp as integer   ,
                                   input nome-abrev as character ).

        define variable transporte as JsonObject no-undo.

        if ( cod-transp = ? or cod-transp = 0 ) and ( nome-abrev = ? or nome-abrev = '' ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'get',
                'Informe o codigo ou o nome abreviado do transportador' ).

        // codigo tem prioridade; cada busca usa o seu indice unico
        find first b-transporte no-lock
            where b-transporte.cod-transp = cod-transp 
               or b-transporte.nome-abrev = nome-abrev no-error.
        
        if not available b-transporte then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'get',
                substitute( 'Transportador nao localizado &1/&2', cod-transp, nome-abrev ) ).

        assign transporte = new JsonObject().

        transporte:Add( 'codigoTransportador', b-transporte.cod-transp       ).
        transporte:Add( 'nome'               , b-transporte.nome             ).
        transporte:Add( 'nomeAbreviado'      , b-transporte.nome-abrev       ).
        transporte:Add( 'cnpj'               , b-transporte.cgc              ).
        transporte:Add( 'inscricaoEstadual'  , b-transporte.ins-estadual     ).
        transporte:Add( 'inscricaoMunicipal' , b-transporte.ins-municipal    ).
        transporte:Add( 'endereco'           , b-transporte.endereco         ).
        transporte:Add( 'bairro'             , b-transporte.bairro           ).
        transporte:Add( 'cidade'             , b-transporte.cidade           ).
        transporte:Add( 'estado'             , b-transporte.estado           ).
        transporte:Add( 'cep'                , b-transporte.cep              ).
        transporte:Add( 'pais'               , b-transporte.pais             ).
        transporte:Add( 'telefone'           , b-transporte.telefone         ).
        transporte:Add( 'email'              , b-transporte.e-mail           ).
        transporte:Add( 'viaTransporte'      , b-transporte.via-transp       ).
        transporte:Add( 'codigoEmitente'     , b-transporte.cod-emitente     ).
        transporte:Add( 'situacao'           , b-transporte.ind-situacao     ).
        transporte:Add( 'referenceCode'      , this-object:loadReferenceCode() ).

        return transporte.

    end method.

end class.
