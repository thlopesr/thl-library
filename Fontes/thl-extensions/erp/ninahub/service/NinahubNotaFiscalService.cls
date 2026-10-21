 /*------------------------------------------------------------------------
    File        : NinaNotaFiscalService
    Purpose     : Especializacao de NotaFiscalService para a integracao Nina.
                  Sobrescreve resolucao de natureza de operacao por tipo de
                  operacao Nina (nit-tipo-oper / nit-tipo-oper-natur).
    Author(s)   : Lopes
    Created     : 2026-08-11
    Notes       : Segue o mesmo padrao de LoogAiEmbarqueService/
                  LoogAiDocumentoService - herda do Service base e sobrescreve
                  apenas hooks com logica Nina-specific.
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-lib.core.error.ThlError.
using thl-lib.erp.service.NotaFiscalService.
using thl-lib.util.file.FileUtil.

block-level on error undo, throw.

class thl-extensions.erp.ninahub.service.NinahubNotaFiscalService inherits NotaFiscalService.

    define protected buffer b-nit-tipo-oper for nit-tipo-oper.
    define protected buffer b-estabelec     for estabelec.
    define protected buffer b-loc-entr      for loc-entr.
    
    method public override character getEntityName().
        return 'Nota Fiscal Ninahub'.
    end method.
    
    method protected override void printInvoiceWorker().
        super:printInvoiceWorker().
        
        if inPayload:has( 'arquivo' ) then
            outPayload:GetJsonObject(1):Add('arquivo-base64', FileUtil:loadFileAsBase64( inPayload:GetCharacter( 'arquivo' ) ) ).
        
    end method.
    
    method protected override void createInvoice().
        
        super:createInvoice().
        
        if not inPayload:has('ccusto')      or 
           not inPayload:has('responsavel') or 
           not inPayload:has('codigoEstabelecimento') or 
           not inPayload:has('seqWtDocto')            then return.
        
        find first es_nota_terceiros exclusive-lock
            where es_nota_terceiros.seq_wt_docto = inPayload:GetInteger  ('seqWtDocto')
              and es_nota_terceiros.cod_estabel  = inPayload:GetCharacter('codigoEstabelecimento')  no-error.
        
        if not available es_nota_terceiros then do.
            create es_nota_terceiros.
            assign es_nota_terceiros.seq_wt_docto = inPayload:GetInteger  ('seqWtDocto')
                   es_nota_terceiros.cod_estabel  = inPayload:GetCharacter('codigoEstabelecimento').
        end.
        
        assign es_nota_terceiros.ccusto      = inPayload:GetCharacter('ccusto')
               es_nota_terceiros.responsavel = inPayload:GetCharacter('responsavel').
        
    end method.

    method protected override character resolveNature ().

        find first b-nit-tipo-oper no-lock
            where b-nit-tipo-oper.cod-tipo-oper = inPayload:GetInteger('tipo-operacao').

        find first b-estabelec no-lock
            where b-estabelec.cod-estabel = inPayload:GetCharacter('cod-estabel').

        find first b-loc-entr no-lock
            where b-loc-entr.cod-entrega = inPayload:GetCharacter('cod-entrega')
              and b-loc-entr.nome-abrev  = inPayload:GetCharacter('nome-abrev').

        find first nit-tipo-oper-natur no-lock
            where nit-tipo-oper-natur.cod-tipo-oper     = b-nit-tipo-oper.cod-tipo-oper
              and nit-tipo-oper-natur.log-estadual      = ( b-loc-entr.estado = b-estabelec.estado )
              and nit-tipo-oper-natur.log-baixa-estoque = inPayload:GetLogical('baixa-estoque')
            .

        return nit-tipo-oper-natur.nat-operacao.

        catch e as Progress.Lang.Error.
            undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveNature',
                substitute( 'Erro ao resolver natureza de operacao - &1', e:GetMessage(1) ) ).
        end catch.

    end method.

    method protected override character resolveNatureItem ( item as JsonObject ).
        return this-object:resolveNature ().
        catch e as Progress.Lang.Error.
            undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveNatureItem',
                substitute( 'Erro ao resolver natureza de operacao do item - &1', e:GetMessage(1) ) ).
        end catch.
    end method.
    
    method protected override character resolveTransport ().
        
        return inPayload:GetCharacter('nome-abrev-transp').
        
        catch e as Progress.Lang.Error.
            undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveTransport',
                substitute( 'Erro ao resolver transportadora - &1', e:GetMessage(1) ) ).
        end catch.

    end method.
    
     method protected override integer resolveSalesChannel().
        
        find first emitente no-lock
            where emitente.nome-abre = inPayload:GetCharacter('nome-abrev').
        
        return emitente.cod-canal-venda.
        
        catch e as Progress.Lang.Error.
            undo, throw new ThlError( this-object:GetClass():TypeName, 'resolveSalesChannel',
                substitute( 'Erro ao resolver canal de venda - &1', e:GetMessage(1) ) ).
        end catch.
        
    end method.
    
    method protected override JsonObject getPrice( item as JsonObject).
        return item.
    end method.

end class.
