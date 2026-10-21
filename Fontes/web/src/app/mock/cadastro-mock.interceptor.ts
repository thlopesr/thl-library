import { HttpErrorResponse, HttpInterceptorFn, HttpResponse } from '@angular/common/http';
import { delay, of, throwError } from 'rxjs';
import { cadastrosMock } from './cadastro-mock.data';

// Backend em memória para o ng serve (sem PASOE). Entra só no build development (fileReplacements no angular.json).

type Row = Record<string, any>;

const BASE = '/api/thl/integration/v1/resourcen/';
const MASK = '********';

const db: Record<string, { keys: string[]; rows: Row[] }> = {
  ...cadastrosMock,
  'ambiente': {
    keys: ['codAmbiente'],
    rows: [
      { codAmbiente: 'PRODUCAO', nomeAmbiente: 'Ambiente de Produção', ip: '192.0.2.10' },
      { codAmbiente: 'HOMOLOGACAO', nomeAmbiente: 'Ambiente de Homologação', ip: '192.0.2.20' },
      { codAmbiente: 'DESENV', nomeAmbiente: 'Ambiente de Desenvolvimento', ip: '192.0.2.30' }
    ]
  },
  'parametro-ambiente': {
    keys: ['codParametro'],
    rows: [
      { codParametro: 'EMAIL', descricao: 'Configurações de envio de e-mail (SMTP)' },
      { codParametro: 'AUTOMATIZADOR', descricao: 'Integração com o Automatizador (LPCO)' },
      { codParametro: 'MENSAGERIA', descricao: 'Parâmetros gerais da mensageria inbound/outbound' },
      { codParametro: 'PORTAL-FORNEC', descricao: 'Integração com o portal de fornecedores' }
    ]
  },
  'parametro-ambiente/variavel': {
    keys: ['codAmbiente', 'codParametro', 'codVariavel'],
    rows: [
      { codAmbiente: 'PRODUCAO', codParametro: 'EMAIL', codVariavel: 'SMTP-HOST', descricao: 'Servidor SMTP', valor: 'smtp.exemplo.com.br' },
      { codAmbiente: 'PRODUCAO', codParametro: 'EMAIL', codVariavel: 'SMTP-PORTA', descricao: 'Porta do servidor SMTP', valor: '587' },
      { codAmbiente: 'PRODUCAO', codParametro: 'EMAIL', codVariavel: 'SMTP-USUARIO', descricao: 'Usuário de autenticação', valor: 'notificacao@exemplo.com.br' },
      { codAmbiente: 'PRODUCAO', codParametro: 'EMAIL', codVariavel: 'SMTP-SENHA', descricao: 'Senha de autenticação', valor: 'segredo-mock' },
      { codAmbiente: 'PRODUCAO', codParametro: 'EMAIL', codVariavel: 'REMETENTE', descricao: 'Remetente padrão', valor: 'nao-responda@exemplo.com.br' },
      { codAmbiente: 'HOMOLOGACAO', codParametro: 'EMAIL', codVariavel: 'SMTP-HOST', descricao: 'Servidor SMTP', valor: 'smtp-hml.exemplo.com.br' },
      { codAmbiente: 'HOMOLOGACAO', codParametro: 'EMAIL', codVariavel: 'SMTP-PORTA', descricao: 'Porta do servidor SMTP', valor: '2525' },
      { codAmbiente: 'HOMOLOGACAO', codParametro: 'EMAIL', codVariavel: 'SMTP-SENHA', descricao: 'Senha de autenticação', valor: 'segredo-mock' },
      { codAmbiente: 'PRODUCAO', codParametro: 'AUTOMATIZADOR', codVariavel: 'URL-BASE', descricao: 'URL base da API', valor: 'https://api.exemplo.com.br/v1' },
      { codAmbiente: 'PRODUCAO', codParametro: 'AUTOMATIZADOR', codVariavel: 'TIMEOUT', descricao: 'Timeout da requisição (s)', valor: '30' },
      { codAmbiente: 'PRODUCAO', codParametro: 'AUTOMATIZADOR', codVariavel: 'CLIENT-SENHA', descricao: 'Client secret OAuth', valor: 'segredo-mock' },
      { codAmbiente: 'PRODUCAO', codParametro: 'MENSAGERIA', codVariavel: 'MAX-TENTATIVAS', descricao: 'Máximo de reenvios', valor: '3' },
      { codAmbiente: 'PRODUCAO', codParametro: 'MENSAGERIA', codVariavel: 'DIAS-EXPURGO', descricao: 'Dias para expurgo de mensagens', valor: '90' }
    ]
  },
  'parametro-ambiente/programa': {
    keys: ['codParametro', 'codPrograma'],
    rows: [
      { codParametro: 'EMAIL', codPrograma: 'thl0201' },
      { codParametro: 'EMAIL', codPrograma: 'thl1986' },
      { codParametro: 'EMAIL', codPrograma: 'esft0001' },
      { codParametro: 'AUTOMATIZADOR', codPrograma: 'thl0202' },
      { codParametro: 'MENSAGERIA', codPrograma: 'thl0200' },
      { codParametro: 'MENSAGERIA', codPrograma: 'thl1986' }
    ]
  }
};

// Mesma regra do ParametroVariavelService:isSensitive (thl-extensions).
const isSensivel = (row: Row): boolean => /SENHA|PASSWORD|SECRET|TOKEN|KEY|CHAVE/i.test(row['codVariavel'] ?? '');
// Autenticação da conexão REST: estes campos voltam mascarados quando têm valor.
const MASCARADOS = ['senha', 'headersToken', 'parametersToken'];
const mascarar = (row: Row): Row => {
  const copia: Row = isSensivel(row) ? { ...row, valor: MASK } : { ...row };
  for (const campo of MASCARADOS) {
    if (copia[campo]) copia[campo] = MASK;
  }
  return copia;
};
const mesmaChave = (keys: string[], a: Row, b: Row): boolean => keys.every(k => a[k] === b[k]);

// Prefixo do filtro <prefixo>Ini/Fin -> campo. Sem entrada aqui, o prefixo é o próprio nome do campo.
const FAIXAS: Record<string, string> = { ambiente: 'codAmbiente', parametro: 'codParametro' };
const PAIS: Record<string, string> = { 'ambiente': 'codAmbiente', 'parametro-ambiente': 'codParametro' };

const ok = (body: unknown, status = 200) => of(new HttpResponse({ status, body })).pipe(delay(300));
const erro = (status: number, message: string) =>
  throwError(() => new HttpErrorResponse({ status, error: { message } }));

export const cadastroMockInterceptor: HttpInterceptorFn = (req, next) => {
  const pos = req.url.indexOf(BASE);
  if (pos < 0) return next(req);

  const recurso = req.url.substring(pos + BASE.length).split('?')[0];
  const tabela = db[recurso];
  if (!tabela) return next(req);

  const prefixos = new Set(req.params.keys().filter(k => /(Ini|Fin)$/.test(k)).map(k => k.slice(0, -3)));
  const naFaixa = (row: Row) =>
    [...prefixos].every(prefixo => {
      const ini = req.params.get(`${prefixo}Ini`);
      const fin = req.params.get(`${prefixo}Fin`);
      const valor = row[FAIXAS[prefixo] ?? prefixo];
      if (valor === undefined) return true;
      const texto = String(valor);
      return (!ini || texto >= ini) && (!fin || texto <= fin);
    });

  switch (req.method) {
    case 'GET':
      return ok(tabela.rows.filter(naFaixa).map(mascarar));
    case 'POST': {
      const novo = req.body as Row;
      if (tabela.rows.some(r => mesmaChave(tabela.keys, r, novo))) {
        return erro(409, 'Registro já existe.');
      }
      tabela.rows.push({ ...novo });
      return ok(mascarar(novo), 201);
    }
    case 'PATCH': {
      const alterado = req.body as Row;
      const atual = tabela.rows.find(r => mesmaChave(tabela.keys, r, alterado));
      if (!atual) return erro(404, 'Registro não encontrado.');
      const mantidos: Row = {};
      for (const campo of ['valor', ...MASCARADOS]) {
        if (alterado[campo] === MASK) mantidos[campo] = atual[campo];
      }
      Object.assign(atual, alterado, mantidos);
      return ok(mascarar(atual));
    }
    case 'DELETE': {
      const chave = req.body as Row;
      const campoPai = PAIS[recurso];
      const temFilhos = !!campoPai && ['parametro-ambiente/variavel', 'parametro-ambiente/programa'].some(filho =>
        db[filho].rows.some(r => r[campoPai] !== undefined && r[campoPai] === chave[campoPai]));
      if (temFilhos) return erro(409, 'Registro possui vínculos e não pode ser eliminado.');
      const antes = tabela.rows.length;
      tabela.rows = tabela.rows.filter(r => !mesmaChave(tabela.keys, r, chave));
      return antes === tabela.rows.length ? erro(404, 'Registro não encontrado.') : ok(null, 204);
    }
    default:
      return next(req);
  }
};
