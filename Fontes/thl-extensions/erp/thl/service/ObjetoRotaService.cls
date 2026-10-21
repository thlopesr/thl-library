/*------------------------------------------------------------------------
    File        : ObjetoRotaService
    Purpose     : Servico de dominio do cadastro da rota do objeto (caminho publico -> objeto)
                  (thl-objeto-rota, tela thl0040): criacao, atualizacao, exclusao e
                  listagem paginada.
    Author(s)   : Lopes
    Created     : 2026-10-01
    Notes       : Padrao AmbienteService (thl-extensions.erp.thl.service).
                  Regras do Pi-validate da tela thl0040:
                  17006 para validacao, 2 para registro relacionado inexistente.
                  2026-10-06: a tabela passou de thl-inbound-rota para
                  thl-objeto-rota, com a chave aplicacao + objeto - uma rota por
                  objeto. Sairam o codigo da rota e a descricao.
                  Chave (aplicacao, objeto) so e gravada na criacao.
                  2026-10-13: a chave passou a aplicacao + objeto + rota-publica:
                  o objeto pode ter varias rotas. O caminho publico continua unico
                  no banco todo (idx-rota-publica) e, como faz parte da chave, nao
                  muda depois de criado (trocar = eliminar e criar de novo).
                  2026-10-08: renomeada de InboundRotaService. A rota e filha de
                  objeto: URL /resourcen/objeto/rota (operacao rota do objeto
                  Objeto, com este Service na linha da operacao).
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.util.json.JsonSetter.
using thl-lib.util.json.JsonUtil.
using thl-lib.util.pagination.PaginationHelper.

block-level on error undo, throw.

class thl-extensions.erp.thl.service.ObjetoRotaService inherits Service.

    define private buffer b-thl-objeto-rota for thl-objeto-rota.

    method public override character getEntityName().
        return 'Rota do Objeto'.
    end method.

    method public override void initialize().

        //a chave e validada aqui, e nao na Message: quem monta a chave sabe o que precisa
        JsonUtil:requireProperties( inContext, 'aplicacao,objeto,rotaPublica', this-object:GetClass():TypeName ).

        this-object:positionRecord().

    end method.

    method public override void create().

        define variable applicationCode as character no-undo.
        define variable objectCode      as character no-undo.
        define variable publicRoute     as character no-undo.

        assign applicationCode = inContext:GetCharacter( 'aplicacao'   )
               objectCode      = inContext:GetCharacter( 'objeto'      )
               publicRoute     = inContext:GetCharacter( 'rotaPublica' ).

        if not can-find( thl-aplicacao
                         where thl-aplicacao.aplicacao = applicationCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Aplicacao nao cadastrada.', 2 ).

        if objectCode = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Objeto nao informado. Informe o objeto de integracao da rota.' ).

        if not can-find( thl-objeto
                         where thl-objeto.aplicacao = applicationCode
                           and thl-objeto.objeto    = objectCode ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Objeto nao cadastrado.', 2 ).

        if publicRoute = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Rota publica nao informada. Informe o caminho publico chamado pelo sistema externo.' ).

        //a chave e aplicacao + objeto + rota publica
        if available b-thl-objeto-rota then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Rota ja cadastrada. O objeto ja tem esta rota.' ).

        do transaction.

            create b-thl-objeto-rota.
            assign b-thl-objeto-rota.aplicacao    = applicationCode
                   b-thl-objeto-rota.objeto       = objectCode
                   b-thl-objeto-rota.rota-publica = publicRoute.

            this-object:mapFields( new JsonSetter( inContext ) ).
            this-object:validateRecord().

        end.

    end method.

    method public override void update().

        if not available b-thl-objeto-rota then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'update', 'Rota nao localizada.' ).

        this-object:mapFields( new JsonSetter( inContext ) ).
        this-object:validateRecord().

    end method.

    method public override void delete().

        if not available b-thl-objeto-rota then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'delete', 'Rota nao localizada.' ).

        delete b-thl-objeto-rota.

    end method.

    //Consulta (GET pelo execute): le os proprios filtros da query
    method public override JsonConstruct consult().
        return this-object:get( queryParameters:getPager( 100 ),
                                queryParameters:getText( 'aplicacaoIni', '' ),
                                queryParameters:getText( 'aplicacaoFin', fill( 'z', 100 ) ),
                                queryParameters:getText( 'objetoIni', '' ),
                                queryParameters:getText( 'objetoFin', fill( 'z', 60 ) ),
                                queryParameters:getText( 'rotaPublicaIni', '' ),
                                queryParameters:getText( 'rotaPublicaFin', fill( 'z', 120 ) ) ).
    end method.

    method public JsonArray get ( pager                as PaginationHelper ,
                                  applicationCodeStart as character        ,
                                  applicationCodeEnd   as character        ,
                                  objectCodeStart      as character        ,
                                  objectCodeEnd        as character        ,
                                  routeStart           as character        ,
                                  routeEnd             as character        ).

        define variable recordItem as JsonObject no-undo.
        define variable recordList as JsonArray  no-undo.

        assign recordList = new JsonArray().

        for each b-thl-objeto-rota no-lock
            where b-thl-objeto-rota.aplicacao >= applicationCodeStart
              and b-thl-objeto-rota.aplicacao <= applicationCodeEnd
              and b-thl-objeto-rota.objeto    >= objectCodeStart
              and b-thl-objeto-rota.objeto    <= objectCodeEnd
              and b-thl-objeto-rota.rota-publica >= routeStart
              and b-thl-objeto-rota.rota-publica <= routeEnd.

            pager:incrementPageCount().
            if pager:shouldSkipEntry()  then next.
            if pager:shouldStopPaging() then leave.

            assign recordItem = new JsonObject().

            recordItem:Add( 'aplicacao'     , b-thl-objeto-rota.aplicacao ).
            recordItem:Add( 'objeto'        , b-thl-objeto-rota.objeto ).
            recordItem:Add( 'rotaPublica'   , b-thl-objeto-rota.rota-publica ).
            recordItem:Add( 'indAtivo'      , b-thl-objeto-rota.ind-ativo ).
            recordItem:Add( 'inicioOperacao', b-thl-objeto-rota.inicio-operacao ).
            recordItem:Add( 'referenceCode' , this-object:loadReferenceCode() ).

            recordList:Add( recordItem ).

        end.

        return recordList.

    end method.

    //so os campos fora da chave: a chave (aplicacao, objeto, rotaPublica) nao muda depois de criada
    method private void mapFields( input jsonSetter as JsonSetter ).
        jsonSetter:SetValue( input-output b-thl-objeto-rota.ind-ativo      , input 'indAtivo'       ).
        jsonSetter:SetValue( input-output b-thl-objeto-rota.inicio-operacao, input 'inicioOperacao' ).
    end method.

    //regras do Pi-validate que valem na criacao e na alteracao; valida antes do commit
    method private void validateRecord().

        define buffer b-outra-rota for thl-objeto-rota.

        if b-thl-objeto-rota.rota-publica = '' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord', 'Rota publica nao informada. Informe o caminho publico chamado pelo sistema externo.' ).

        //o caminho publico resolve a rota (idx-rota-publica): nao pode repetir
        if can-find( first b-outra-rota
                     where b-outra-rota.rota-publica = b-thl-objeto-rota.rota-publica
                       and rowid( b-outra-rota )    <> rowid( b-thl-objeto-rota ) ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord', 'Rota publica ja usada. Ja existe outra rota com este caminho publico.' ).

        //inicio da operacao: 0 (so o ultimo segmento da URL) ou um segmento da propria
        //rota, do 2 em diante - o primeiro e o objeto
        if b-thl-objeto-rota.inicio-operacao <> 0 and
           ( b-thl-objeto-rota.inicio-operacao < 2 or
             b-thl-objeto-rota.inicio-operacao > num-entries( b-thl-objeto-rota.rota-publica, '/' ) ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validateRecord',
                'Inicio da operacao invalido. Informe 0 ou um segmento da rota publica, do 2 em diante.' ).

    end method.

    //le do buffer posicionado, para servir a escrita e a listagem do get()
    method public override character loadReferenceCode().
        if available b-thl-objeto-rota then
            return substitute( '&1#&2#&3', b-thl-objeto-rota.aplicacao, b-thl-objeto-rota.objeto, b-thl-objeto-rota.rota-publica ).
        return ''.
    end method.

    method private void positionRecord().
        find first b-thl-objeto-rota exclusive-lock
            where b-thl-objeto-rota.aplicacao    = inContext:GetCharacter( 'aplicacao'   )
              and b-thl-objeto-rota.objeto       = inContext:GetCharacter( 'objeto'      )
              and b-thl-objeto-rota.rota-publica = inContext:GetCharacter( 'rotaPublica' )
            no-error.
    end method.

end class.
