/*------------------------------------------------------------------------
    File        : FretePrevistoService
    Purpose     : Servico de dominio para manutencao de frete previsto
                  (nit-frete-prev): criacao, atualizacao e cancelamento
                  logico. Orquestracao, negocio e persistencia — nenhuma
                  dependencia de infra de mensageria THL.
    Author(s)   : Lopes
    Created     : 2026-07-18
    Notes       : Movido de integration.messaging.inbound.service para
                  erp.service em 2026-07-24 (sessao 6).
                  Movido de thl-lib.erp.service para thl-extensions.erp.dvv
                  em 2026-09-24: nit-frete-prev e schema do cliente (sistema DVV).
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.

using thl-extensions.erp.dvv.enum.SituacaoFreteEnum.
using thl-lib.core.error.ThlError.
using thl-lib.erp.core.Service.
using thl-lib.logging.audit.AuditLogService.
using thl-lib.logging.LogUtil.

block-level on error undo, throw.

class thl-extensions.erp.dvv.service.FretePrevistoService inherits Service.

    define private buffer b-nit-frete-prev for nit-frete-prev.

    define private property estabelecimento as character no-undo get. private set.
    define private property serie           as character no-undo get. private set.
    define private property numeroNota      as character no-undo get. private set.
    define private property tipoFrete       as integer   no-undo get. private set.
    define private property valorFrete      as decimal   no-undo get. private set.
    define private property observacao      as character no-undo get. private set.

    method public override character getEntityName().
        return 'Frete previsto'.
    end method.

    method public override void initialize().

        //Este Service so atende a modalidade previsto (frete/previsto). O Service vem
        //do cadastro e a linha generica do metodo atende qualquer operacao da URL:
        //sem esta conferencia, frete/realizado seria gravado como frete previsto.
        if this-object:operation <> 'previsto' then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'initialize',
                substitute( 'Modalidade de frete nao suportada: &1. Use frete/previsto.', this-object:operation ) ).

        this-object:setValue().

    end method.
    
    
    /*--------------------------------------------------------------------------
      Cria um frete previsto ativo:
        1. Valida existencia da NF de origem
        2. Rejeita duplicidade de frete ativo para a mesma chave
        3. CREATE em transacao, com auditoria no mesmo escopo — registro e
           trilha de auditoria sao atomicos
    --------------------------------------------------------------------------*/
    method public override void create().
    
        this-object:validarNotaFiscal().

        if can-find( first b-nit-frete-prev
                     where b-nit-frete-prev.cod-estabel    = estabelecimento
                       and b-nit-frete-prev.serie          = serie
                       and b-nit-frete-prev.nr-nota-fis    = numeroNota
                       and b-nit-frete-prev.idi-tipo-frete = tipoFrete
                       and b-nit-frete-prev.idi-situacao   = SituacaoFreteEnum:GetEnum('Ativo'):GetValue( ) ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'create', 'Ja existe frete previsto ativo para a chave.' ).

        create b-nit-frete-prev.
        assign b-nit-frete-prev.cod-estabel    = estabelecimento
               b-nit-frete-prev.serie          = serie
               b-nit-frete-prev.nr-nota-fis    = numeroNota
               b-nit-frete-prev.idi-tipo-frete = tipoFrete
               b-nit-frete-prev.val-frete      = valorFrete
               b-nit-frete-prev.des-observacao = numeroNota
               b-nit-frete-prev.idi-situacao   = SituacaoFreteEnum:ATIVO:GetValue( ).

    end method.

    /*--------------------------------------------------------------------------
      Atualiza um frete previsto ativo. Somente os campos atualizaveis do
      contrato (valor e observacao) sao alterados — a chave e imutavel.
    --------------------------------------------------------------------------*/
    method public override void update().

        this-object:localizarFretePrevistoAtivo( 'update' ).

        assign b-nit-frete-prev.val-frete      = valorFrete
               b-nit-frete-prev.des-observacao = observacao.

    end method.

    /*--------------------------------------------------------------------------
      Cancelamento logico: idi-situacao = 2, nunca DELETE fisico — o
      historico do frete permanece consultavel. A auditoria usa deleteRecord
      porque a intencao de negocio e remocao, ainda que a operacao fisica
      seja um update de situacao.
    --------------------------------------------------------------------------*/
    method public override void delete().

        this-object:localizarFretePrevistoAtivo( 'delete' ).

        assign b-nit-frete-prev.idi-situacao = SituacaoFreteEnum:CANCELADO:GetValue( ).
        
    end method.

    //A NF de origem precisa existir antes de qualquer frete previsto ser
    //aceito — evita registros orfaos vindos de integracoes com dados errados.
    method private void validarNotaFiscal().

        if not can-find( first nota-fiscal
                            where nota-fiscal.cod-estabel = estabelecimento
                              and nota-fiscal.serie       = serie
                              and nota-fiscal.nr-nota-fis = numeroNota ) then
            undo, throw new ThlError( this-object:GetClass():TypeName, 'validarNotaFiscal',
                substitute( 'Nota fiscal &1/&2/&3 nao localizada.',
                            estabelecimento, serie, numeroNota ) ).

    end method.

    //Posiciona o buffer de classe no frete ativo com exclusive-lock — os
    //metodos de update/cancel dependem do buffer ficar disponivel no escopo
    //da transacao do chamador.
    method private void localizarFretePrevistoAtivo( input metodo  as character ).

        find first b-nit-frete-prev exclusive-lock
            where b-nit-frete-prev.cod-estabel    = estabelecimento
              and b-nit-frete-prev.serie          = serie
              and b-nit-frete-prev.nr-nota-fis    = numeroNota
              and b-nit-frete-prev.idi-tipo-frete = tipoFrete
              and b-nit-frete-prev.idi-situacao   = SituacaoFreteEnum:ATIVO:GetValue( )
            no-error.

        if not available b-nit-frete-prev then
            undo, throw new ThlError( this-object:GetClass():TypeName, metodo, 'Frete previsto nao encontrado ou ja cancelado' ).

    end method.
    
    method private void setValue().
        assign estabelecimento = getEstablishmentCode()
               serie           = inContext:GetCharacter( 'Serie'           )
               numeroNota      = inContext:GetCharacter( 'NrNota'          )
               tipoFrete       = inContext:GetInteger  ( 'TipoFrete'       )
               valorFrete      = if inContext:GetType( 'valorFrete' ) = 1 then 
                                    if inContext:GetCharacter( 'valorFrete' ) = '' then 0
                                                                                   else decimal( inContext:GetCharacter( 'valorFrete' ) )
                                                                          else inContext:GetDecimal( 'valorFrete' ) 
               observacao      = if inContext:has('Observacao' ) then inContext:GetCharacter( 'Observacao')
                                                                 else '' .
    end method.
    
    method private character getEstablishmentCode().
        find first estabelec no-lock
            where estabelec.cgc = inContext:GetCharacter( 'Estabelecimento' )
            no-error.
        if not available estabelec then    
            undo, throw new ThlError( this-object:GetClass():TypeName, 'establishment', 'Estabelecimentonao localizada.' ).             
        return estabelec.cod-estabel.
    end method.
    
    method public override character loadReferenceCode().
        if available b-nit-frete-prev then
            return substitute( '&1#&2#&3#&4'                   ,
                               b-nit-frete-prev.cod-estabel    ,
                               b-nit-frete-prev.serie          ,
                               b-nit-frete-prev.nr-nota-fis    ,
                               b-nit-frete-prev.idi-tipo-frete ).
        return ''.
    end method.

end class.
