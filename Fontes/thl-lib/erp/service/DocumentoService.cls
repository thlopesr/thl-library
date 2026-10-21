/*------------------------------------------------------------------------
    File        : DocumentoService
    Purpose     : Servico de dominio para criacao de documento de estoque
                  (docum-est) via BOFs (boin090/176/092/366). Extraido de
                  DocumentoMessage (SRP) - o hook de montagem dos dados
                  (prepareDocumentos) migrou junto, para que extensoes por
                  cliente (ex: LoogAiDocumentoService) continuem
                  especializando apenas o mapeamento de dados, sem repetir
                  a orquestracao de BOFs.
    Author(s)   : Lopes
    Created     : 2026-07-24
    Notes       : Herda BusinessObject (RowErrors para BOFs). O hook
                  prepareDocumentos e protected para que extensoes por
                  cliente especializem o mapeamento sem repetir a
                  orquestracao de BOFs. Movido de
                  integration.messaging.inbound.service para erp.service
                  em 2026-07-24.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

using thl-lib.core.error.*.
using thl-lib.erp.core.BusinessObject.

block-level on error undo, throw.

class thl-lib.erp.service.DocumentoService inherits BusinessObject.

    define protected temp-table tt-docum-est    no-undo serialize-name 'docum-est'    like docum-est
        field r-rowid  as rowid.

    define protected temp-table tt-item-doc-est no-undo serialize-name 'item-doc-est' like item-doc-est
        field r-rowid  as rowid.

    //registro unico enviado a boin176 (setRecord considera so o primeiro)
    define protected temp-table tt-item-doc-est-aux no-undo like tt-item-doc-est.

    define protected temp-table tt-rat-docum    no-undo serialize-name 'rat-docum'    like rat-docum
        field r-rowid  as rowid.

    define protected temp-table tt-dupli-apagar no-undo serialize-name 'dupli-apagar' like dupli-apagar
        field r-rowid  as rowid.

    define protected buffer b-docum-est for docum-est.

    method public override character getEntityName().
        return 'Documento'.
    end method.

    method public override void create().

        empty temp-table tt-docum-est    no-error.
        empty temp-table tt-item-doc-est no-error.
        empty temp-table tt-dupli-apagar no-error.
        empty temp-table tt-rat-docum    no-error.

        this-object:prepareDocumentData( inContext ).

        this-object:executeBOFs().
        
        find first tt-docum-est                no-lock no-error.
        find first b-docum-est of tt-docum-est no-lock no-error.

        if not available b-docum-est then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'execute',
                'Documento de estoque nao localizado apos criacao.' ).

    end method.
    
    method public override character loadReferenceCode().
        if available b-docum-est then
            return ( substitute( '&1#&2#&3#&4'            ,
                                 b-docum-est.serie-docto  ,
                                 b-docum-est.nro-docto    ,
                                 b-docum-est.cod-emitente ,
                                 b-docum-est.nat-operacao ) ).
        return ''.
    end method.

    method protected void prepareDocumentData( input inContext as JsonObject ).

        define variable count      as integer    no-undo.

        create tt-docum-est.
        assign tt-docum-est.dt-trans = today.

        temp-table tt-docum-est:read-json( 'JsonObject', inContext, 'APPEND').

        if inContext:Has('item-doc-est') then do.

            do count = 1 to inContext:GetJsonArray('item-doc-est'):Length.

                create tt-item-doc-est.
                assign tt-item-doc-est.serie-docto  = tt-docum-est.serie-docto
                       tt-item-doc-est.nro-docto    = tt-docum-est.nro-docto
                       tt-item-doc-est.cod-emitente = tt-docum-est.cod-emitente
                       tt-item-doc-est.nat-operacao = tt-docum-est.nat-operacao
                       .

                temp-table tt-item-doc-est:read-json( 'JsonObject',  inContext:GetJsonArray('item-doc-est'):GetJsonObject(count), 'APPEND').

            end.

        end.

        if inContext:Has('dupli-apagar') then do.

            do count = 1 to inContext:GetJsonArray('dupli-apagar'):Length.

                create tt-dupli-apagar.
                assign tt-dupli-apagar.serie-docto  = tt-docum-est.serie-docto
                       tt-dupli-apagar.nro-docto    = tt-docum-est.nro-docto
                       tt-dupli-apagar.cod-emitente = tt-docum-est.cod-emitente
                       tt-dupli-apagar.nat-operacao = tt-docum-est.nat-operacao.

                temp-table tt-dupli-apagar:read-json( 'JsonObject',  inContext:GetJsonArray('dupli-apagar'):GetJsonObject(count), 'APPEND').

            end.

        end.

        if inContext:Has('rat-docum') then do.

            do count = 1 to inContext:GetJsonArray('rat-docum'):Length.

                create tt-rat-docum.
                assign tt-rat-docum.serie-docto  = tt-docum-est.serie-docto
                       tt-rat-docum.nro-docto    = tt-docum-est.nro-docto
                       tt-rat-docum.cod-emitente = tt-docum-est.cod-emitente
                       tt-rat-docum.nat-operacao = tt-docum-est.nat-operacao.

                temp-table tt-rat-docum:read-json( 'JsonObject',  inContext:GetJsonArray('rat-docum'):GetJsonObject(count), 'APPEND').

            end.

        end.

    end method.

    method private void executeBOFs().

        define variable boin090 as handle no-undo.
        define variable boin176 as handle no-undo.
        define variable boin092 as handle no-undo.
        define variable boin366 as handle no-undo.

        run inbo/boin090.p persistent set boin090.
        run inbo/boin176.p persistent set boin176.
        run inbo/boin092.p persistent set boin092.
        run inbo/boin366.p persistent set boin366.

        run emptyRowErrors in boin090.
        run emptyRowErrors in boin176.
        run emptyRowErrors in boin092.
        run emptyRowErrors in boin366.
        
        do transaction.

            run openQueryStatic in boin090 (  input 'Main' ).
            run setRecord       in boin090 (  input table tt-docum-est ).
            run createRecord    in boin090.
            run getRowErrors    in boin090 ( output table RowErrors ).
            
            this-object:throwRowErrorsIfAny( 'createRecord', 'boin090' ).

            if can-find( first tt-item-doc-est ) then do.
                
                run openQueryStatic in boin176 ( input 'Main' ).

                for each tt-item-doc-est no-lock.

                    empty temp-table tt-item-doc-est-aux no-error.
                    
                    create tt-item-doc-est-aux.
                    buffer-copy tt-item-doc-est to tt-item-doc-est-aux.
                               
                    run emptyRowErrors in boin176.
                    run setRecord      in boin176 ( input table tt-item-doc-est-aux ).
                    run createRecord   in boin176.
                    run getRowErrors   in boin176 ( output table RowErrors ).
                    
                    this-object:throwRowErrorsIfAny( 'createRecord', 'boin176' ).
                    
                end.
                
            end.
            
            run setHandleDocumEst       in boin176 ( input boin090 ).
            run transferTotalItensNota  in boin176 ( input tt-docum-est.cod-emitente ,
                                                     input tt-docum-est.serie-docto  ,
                                                     input tt-docum-est.nro-docto    ,
                                                     input tt-docum-est.nat-operacao ).
            
            if can-find( first tt-dupli-apagar ) then do.
                
                run openQueryStatic in boin092 (  input 'Main' ).
                run setRecord       in boin092 (  input table tt-dupli-apagar ).
                run createRecord    in boin092.
                run getRowErrors    in boin092 ( output table RowErrors ).
                
                this-object:throwRowErrorsIfAny( 'createRecord', 'boin092' ).
                
            end.

            if can-find( first tt-rat-docum ) then do.
                
                run openQueryStatic in boin366 (  input 'Main' ).
                run setRecord       in boin366 (  input table tt-rat-docum ).
                run createRecord    in boin366.
                run getRowErrors    in boin366 ( output table RowErrors ).
                
                this-object:throwRowErrorsIfAny( 'createRecord', 'boin366' ).
                
            end.

        end.

        finally.
            
            empty temp-table tt-item-doc-est-aux no-error.
            
            if valid-handle( boin090 ) then run destroy in boin090.
            if valid-handle( boin176 ) then run destroy in boin176.
            if valid-handle( boin092 ) then run destroy in boin092.
            if valid-handle( boin366 ) then run destroy in boin366.
            
        end finally.

    end method.

end class.
