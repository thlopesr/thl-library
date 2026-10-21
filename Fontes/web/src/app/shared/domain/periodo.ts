// Faixa de data e hora das consultas.
// Contrato do backend: `yyyy-MM-ddTHH:mm`, hora local, sem segundos e sem fuso
// (`StringUtil:parseDateTime`, que exige exatamente 16 caracteres e recusa o resto).
// Sem os parâmetros, o backend assume as últimas 24 horas.
// Desde 2026-10-13 as **listagens** também leem com `getDateTime`: mandar só a data
// deixou de funcionar em qualquer rota.

export type PeriodoAtalho = '1h' | '24h' | '7d' | '21d' | 'personalizado';

export interface FaixaPeriodo {
  ini: string;
  fin: string;
}

/** 21 dias é a retenção das mensagens com sucesso: acima disso o gráfico cai sem o dado ter sumido.
 *
 *  O `label` nunca some: vira o tooltip e o `aria-label` quando a opção tem glifo.
 *  Cronômetro conta horas, calendário conta dias — é o que separa "1h" de "24h",
 *  que no número sozinho seriam os dois um "1". */
export const ATALHOS_PERIODO:
  { value: PeriodoAtalho; label: string; tooltip?: string; glifo?: GlifoPeriodo; icone?: string }[] = [
  // `label` é curto porque também vira o subtítulo da página ("Erros por rota · 24h");
  // quem explica o desenho é o `tooltip`.
  { value: '1h', label: '1h', tooltip: 'Última 1 hora', glifo: { forma: 'timer', valor: '1' } },
  { value: '24h', label: '24h', tooltip: 'Últimas 24 horas (1 dia)', glifo: { forma: 'calendario', valor: '1' } },
  { value: '7d', label: '7 dias', tooltip: 'Últimos 7 dias', glifo: { forma: 'calendario', valor: '7' } },
  { value: '21d', label: '21 dias', tooltip: 'Últimos 21 dias — retenção dos sucessos', glifo: { forma: 'calendario', valor: '21' } },
  { value: 'personalizado', label: 'Personalizado', tooltip: 'Escolher data e hora', icone: 'an an-calendar-gear' }
];

/** Ícone desenhado em SVG com o número dentro. A fonte Animalia não serve aqui: o
 *  `an-calendar` tem "12" impresso no glifo e número de fonte não se troca. */
export interface GlifoPeriodo {
  forma: 'timer' | 'calendario';
  valor: string;
}

/** Atalhos dos **filtros avançados dos monitores**, em dias inteiros.
 *
 *  Não se confundem com os `ATALHOS_PERIODO` das métricas, que são em horas: lá a
 *  pergunta é "como está agora", aqui é "o que aconteceu naquele período". Por isso
 *  cada atalho vai de 00:00 a 23:59 do dia — "Hoje" clicado às 9h tem de incluir o
 *  que entrar às 9h30, senão o usuário filtra hoje e não vê o dia inteiro.
 */
export type AtalhoData = 'hoje' | 'ontem' | '7d' | 'mes' | 'mesAnterior' | 'personalizado';

/** Quatro atalhos, de propósito: eles ficam colados no campo de data e competem com ele
 *  por atenção. `ontem` e `personalizado` seguem no tipo — `personalizado` é o estado de
 *  quem digitou a data na mão —, mas não viram botão. */
export const ATALHOS_DATA: { value: AtalhoData; label: string }[] = [
  { value: 'hoje', label: 'Hoje' },
  { value: '7d', label: '7 dias' },
  { value: 'mes', label: 'Mês' },
  { value: 'mesAnterior', label: 'Mês anterior' }
];

/** Faixa do atalho. `personalizado` não tem faixa: quem digita é o usuário. */
export function faixaDoAtalhoData(atalho: AtalhoData, agora = new Date()): FaixaPeriodo | null {
  const dia = (d: Date, limite: 'inicio' | 'fim'): string => {
    const hh = limite === 'inicio' ? 0 : 23;
    const mm = limite === 'inicio' ? 0 : 59;
    return formatarDataHora(new Date(d.getFullYear(), d.getMonth(), d.getDate(), hh, mm));
  };

  switch (atalho) {
    case 'hoje':
      return { ini: dia(agora, 'inicio'), fin: dia(agora, 'fim') };
    case 'ontem': {
      const ontem = new Date(agora.getFullYear(), agora.getMonth(), agora.getDate() - 1);
      return { ini: dia(ontem, 'inicio'), fin: dia(ontem, 'fim') };
    }
    case '7d': {
      // Sete dias **inteiros contando hoje**, não 7×24h: o usuário pensa em dias de calendário.
      const inicio = new Date(agora.getFullYear(), agora.getMonth(), agora.getDate() - 6);
      return { ini: dia(inicio, 'inicio'), fin: dia(agora, 'fim') };
    }
    case 'mes': {
      const primeiro = new Date(agora.getFullYear(), agora.getMonth(), 1);
      return { ini: dia(primeiro, 'inicio'), fin: dia(agora, 'fim') };
    }
    case 'mesAnterior': {
      const primeiro = new Date(agora.getFullYear(), agora.getMonth() - 1, 1);
      // Dia 0 do mês atual = último dia do mês anterior; resolve 28, 29, 30 e 31 sozinho.
      const ultimo = new Date(agora.getFullYear(), agora.getMonth(), 0);
      return { ini: dia(primeiro, 'inicio'), fin: dia(ultimo, 'fim') };
    }
    default:
      return null;
  }
}

/** Mesma data e hora, ignorando o fuso que o `po-datetimepicker` acrescenta ao modelo
 *  (ele devolve `2026-09-01T00:00-03:00` para o `2026-09-01T00:00` que recebeu). */
export function mesmaDataHora(a: unknown, b: unknown): boolean {
  const norm = (v: unknown) => String(v ?? '').slice(0, 16);
  return norm(a) !== '' && norm(a) === norm(b);
}

/** Quantos dias atrás está a data informada (ISO `yyyy-MM-dd...`). `null` se não der para ler. */
export function diasAtras(valor: string, agora = new Date()): number | null {
  const casa = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(valor).trim());
  if (!casa) return null;
  const [, ano, mes, dia] = casa;
  const data = new Date(Number(ano), Number(mes) - 1, Number(dia));
  const hoje = new Date(agora.getFullYear(), agora.getMonth(), agora.getDate());
  return Math.round((hoje.getTime() - data.getTime()) / (24 * 60 * 60 * 1000));
}

const HORA = 60 * 60 * 1000;

/** `yyyy-MM-ddTHH:mm` na hora local — `toISOString()` converteria para UTC e deslocaria a faixa. */
export function formatarDataHora(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

/** Normaliza o valor do filtro para o `yyyy-MM-ddTHH:mm` que o backend exige.
 *
 *  A hora informada pelo usuário manda. Quando o valor não traz hora — um campo
 *  só de data, ou texto `yyyy-MM-dd` —, o dia vira a faixa inteira: 00:00 no
 *  início e 23:59 no fim, senão um registro da tarde ficaria de fora do próprio
 *  dia escolhido.
 *
 *  Aceita o que o `po-datetimepicker` e o `po-datepicker` entregam: `Date` ou
 *  texto ISO, com ou sem fuso. */
export function paraFaixa(valor: unknown, limite: 'inicio' | 'fim'): string {
  if (!valor) return '';

  const pad = (n: number) => String(n).padStart(2, '0');
  const horaLimite = limite === 'inicio' ? '00:00' : '23:59';

  if (valor instanceof Date) {
    // Data local: `toISOString()` converte para UTC e pode trocar o dia.
    const dia = `${valor.getFullYear()}-${pad(valor.getMonth() + 1)}-${pad(valor.getDate())}`;
    const temHora = valor.getHours() !== 0 || valor.getMinutes() !== 0;
    return `${dia}T${temHora ? `${pad(valor.getHours())}:${pad(valor.getMinutes())}` : horaLimite}`;
  }

  // Precisa ser ISO de verdade: o `po-datetimepicker` grava a string
  // "Data/hora inválida" no modelo quando o campo está incompleto, e ela não pode
  // virar um filtro. Qualquer coisa fora do formato devolve vazio.
  const casa = /^(\d{4}-\d{2}-\d{2})(?:T(\d{2}):(\d{2}))?/.exec(String(valor).trim());
  if (!casa) return '';

  const [, dia, hh, mm] = casa;
  return `${dia}T${hh && mm ? `${hh}:${mm}` : horaLimite}`;
}

/** O que o usuário digitou no campo (`dd/mm/aaaa` ou `dd/mm/aaaa hh:mm`) → `yyyy-MM-ddTHH:mm`.
 *
 *  Existe porque o `po-datetimepicker` só preenche o modelo quando data **e** hora estão
 *  completas, e não marca o campo como inválido enquanto isso: sem este resgate, quem digita
 *  só a data e clica em Filtrar teria o período ignorado em silêncio. Data sozinha vale o dia
 *  inteiro. Texto que não for data reconhecível devolve vazio — melhor ignorar do que inventar. */
export function textoDigitadoParaFaixa(texto: string, limite: 'inicio' | 'fim'): string {
  const casa = /^(\d{2})\/(\d{2})\/(\d{4})(?:[ T](\d{2}):(\d{2}))?$/.exec((texto ?? '').trim());
  if (!casa) return '';

  const [, dia, mes, ano, hh, mm] = casa;
  const hora = hh && mm ? `${hh}:${mm}` : limite === 'inicio' ? '00:00' : '23:59';
  return `${ano}-${mes}-${dia}T${hora}`;
}

/** Texto do filtro ativo. O usuário escolheu um dia, então 00:00 e 23:59 são ruído
 *  do contrato e não aparecem; hora escolhida de propósito continua visível. */
export function rotuloDeDataHora(valor: string): string {
  if (!valor) return '';
  const [data, hora] = valor.split('T');
  const [ano, mes, dia] = data.split('-');
  const legivel = `${dia}/${mes}/${ano}`;
  return !hora || hora === '00:00' || hora === '23:59' ? legivel : `${legivel} ${hora}`;
}

/** Período na URL: sem isto, sair da tela e voltar perde o que estava escolhido,
 *  porque a rota é lazy e o componente nasce de novo com o padrão. Na URL, o
 *  "voltar" do navegador restaura e o link fica compartilhável.
 *  `ini`/`fin` só aparecem no período personalizado — nos atalhos, a faixa é
 *  recalculada na hora, senão o link mostraria dados velhos. */
export function periodoParaUrl(atalho: PeriodoAtalho, faixa: FaixaPeriodo): Record<string, string> {
  return atalho === 'personalizado'
    ? { atalho, ini: faixa.ini, fin: faixa.fin }
    : { atalho };
}

/** Lê o período da URL. Devolve `null` quando não há nada utilizável, e aí vale o padrão da tela. */
export function periodoDaUrl(params: Record<string, string>): { atalho: PeriodoAtalho; faixa: FaixaPeriodo } | null {
  const atalho = params['atalho'] as PeriodoAtalho;
  if (!ATALHOS_PERIODO.some(a => a.value === atalho)) return null;

  if (atalho === 'personalizado') {
    const { ini, fin } = params;
    // Faixa personalizada sem as duas pontas não reconstrói: cai no padrão.
    return ini && fin ? { atalho, faixa: { ini, fin } } : null;
  }

  return { atalho, faixa: faixaDoAtalho(atalho) };
}

export function faixaDoAtalho(atalho: PeriodoAtalho, agora = new Date()): FaixaPeriodo {
  const inicio = new Date(agora);
  switch (atalho) {
    case '1h': inicio.setTime(agora.getTime() - HORA); break;
    case '24h': inicio.setTime(agora.getTime() - 24 * HORA); break;
    case '7d': inicio.setTime(agora.getTime() - 7 * 24 * HORA); break;
    case '21d': inicio.setTime(agora.getTime() - 21 * 24 * HORA); break;
    default: inicio.setTime(agora.getTime() - 24 * HORA); break;
  }
  return { ini: formatarDataHora(inicio), fin: formatarDataHora(agora) };
}

/** Retenção das mensagens com sucesso. Acima disso o começo do período vem incompleto
 *  por expurgo — o gráfico cai sem o tráfego ter caído. */
export const RETENCAO_DIAS = 21;

export function diasDaFaixa(faixa: FaixaPeriodo): number {
  const ini = new Date(faixa.ini).getTime();
  const fin = new Date(faixa.fin).getTime();
  return Math.max(0, Math.round((fin - ini) / (24 * HORA)));
}

export function excedeRetencao(faixa: FaixaPeriodo): boolean {
  return diasDaFaixa(faixa) > RETENCAO_DIAS;
}

export function rotuloDoPeriodo(atalho: PeriodoAtalho, faixa: FaixaPeriodo): string {
  const legivel = (v: string) => `${v.substring(8, 10)}/${v.substring(5, 7)} ${v.substring(11)}`;
  if (atalho === 'personalizado') return `${legivel(faixa.ini)} até ${legivel(faixa.fin)}`;
  return ATALHOS_PERIODO.find(a => a.value === atalho)?.label ?? '';
}
