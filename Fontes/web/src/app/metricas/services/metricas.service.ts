import { Injectable, inject } from '@angular/core';
import { Observable, forkJoin, map } from 'rxjs';
import { MetricasResumo } from '../models/metricas.model';
import { MetricasService as MetricasApi } from '../../shared/domain/metricas.service';
import { FaixaPeriodo } from '../../shared/domain/periodo';
import { MensageriaMetrica, MensageriaMetricaItem } from '../../mensageria/models/mensageria-metrica.model';
import { EmailMetrica } from '../../email/models/email-metrica.model';
import { AuditoriaMetrica } from '../../auditoria/models/auditoria-metrica.model';

// Resumo dos três assuntos. Consome as rotas `<assunto>/metricas`, as mesmas das
// telas de métricas de cada feature — antes somava as listagens, que vêm limitadas
// por página, e por isso mostrava números menores para o mesmo período.
@Injectable({ providedIn: 'root' })
export class MetricasService {
  private api = inject(MetricasApi);

  /** `incluirInternas` acompanha o botão de tráfego interno da tela, como na de mensageria. */
  getMetricas(faixa: FaixaPeriodo, incluirInternas = false): Observable<MetricasResumo> {
    return forkJoin([
      this.api.buscar<MensageriaMetrica>('mensageria', 'dtCriacao', faixa),
      this.api.buscar<EmailMetrica>('email', 'dtEnvio', faixa),
      this.api.buscar<AuditoriaMetrica>('auditoria', 'dtCriacao', faixa)
    ]).pipe(
      map(([mensageria, emails, auditoria]) => this.montar(mensageria, emails, auditoria, incluirInternas))
    );
  }

  private montar(
    mensageria: MensageriaMetrica[],
    emails: EmailMetrica[],
    auditoria: AuditoriaMetrica[],
    incluirInternas: boolean
  ): MetricasResumo {
    // Por padrão fora as internas (`thl-aplicacao.ind-interna`): o tráfego do próprio THL é
    // gerado pelo monitor — cada atualização de tela cria mensagens THL/Mensageria, THL/Email
    // e THL/Auditoria — e chegava a ser quase tudo o que o cartão contava. Mesmo padrão da
    // tela de métricas da mensageria; sem o filtro os dois números divergiam (124 aqui contra
    // 4 lá, no mesmo período). O botão de tráfego interno inverte a conta nas duas telas.
    // E-mail e auditoria não têm esse campo: `interna` só existe em `mensageria/metricas`.
    const linhasMensageria = incluirInternas ? mensageria : mensageria.filter(linha => !linha.interna);
    const mensagens = linhasMensageria.flatMap(linha => linha.mensagens);
    const itensEmail = emails.flatMap(linha => linha.emails);
    const registros = auditoria.flatMap(linha => linha.registros);

    // Uma mensagem é contada pelo pior estado entre as três fases, e não pelo
    // processamento sozinho: com o critério antigo o cartão dizia "Erro 0" enquanto o
    // aviso no topo da mesma tela dizia "5 mensagens com erro em alguma fase" — os erros
    // estavam na requisição e no retorno. É também o critério das telas de métricas e dos
    // chips dos monitores, então os números passam a bater de ponta a ponta.
    const fases = (m: MensageriaMetricaItem): string[] => [m.sitRequisicao, m.sitProcessamento, m.sitRetorno];
    const comErro = mensagens.filter(m => fases(m).includes('Erro'));
    const comPendente = mensagens.filter(m => !fases(m).includes('Erro') && fases(m).includes('Pendente'));

    return {
      mensagem: {
        total: mensagens.length,
        // Sem erro e sem pendência. `N/A` (retorno de mensagem de entrada) não impede
        // sucesso, senão toda mensagem inbound ficaria fora da conta.
        sucesso: mensagens.length - comErro.length - comPendente.length,
        erro: comErro.length,
        pendente: comPendente.length
      },
      email: {
        total: itensEmail.length,
        sucesso: itensEmail.filter(e => e.situacao === 'Sucesso').length,
        erro: itensEmail.filter(e => e.situacao === 'Erro').length
      },
      auditoria: {
        total: registros.length,
        criacao: registros.filter(r => r.tipo === 'Criacao').length,
        atualizacao: registros.filter(r => r.tipo === 'Atualizacao').length,
        delecao: registros.filter(r => r.tipo === 'Delecao').length
      },
      // Conta a faixa consultada, não uma janela fixa: o texto da tela promete o período escolhido.
      errosNoPeriodo: comErro.length
    };
  }
}
