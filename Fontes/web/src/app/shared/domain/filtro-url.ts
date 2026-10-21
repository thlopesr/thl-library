// Filtro dos monitores na URL.
//
// Sem isto, aplicar um filtro, sair da tela e voltar devolve o monitor limpo: a rota
// é lazy e o componente nasce de novo. Na URL, o "voltar" do navegador restaura o que
// estava filtrado e o link pode ser passado adiante ("olha estas mensagens").
//
// As chaves são os próprios nomes do modelo de filtro (`aplicacaoIni`, `dtCriacaoInicial`…),
// não os nomes dos query params da API — quem traduz para a API continua sendo o service.

/** Só o que está preenchido vai para a URL: filtro vazio não deixa sujeira no endereço. */
export function filtroParaUrl(filtro: Record<string, unknown>): Record<string, string> {
  const params: Record<string, string> = {};

  for (const [chave, valor] of Object.entries(filtro)) {
    if (valor === undefined || valor === null || valor === '') continue;
    params[chave] = String(valor);
  }

  return params;
}

/** Monta o filtro a partir da URL. `numericos` lista as chaves que o modelo espera
 *  como número (`codStatusRetorno`); valor não numérico é descartado em vez de virar `NaN`. */
export function filtroDaUrl<T extends object>(
  params: Record<string, string>,
  chaves: readonly string[],
  numericos: readonly string[] = []
): T {
  const filtro: Record<string, unknown> = {};

  for (const chave of chaves) {
    const valor = params[chave];
    if (valor === undefined || valor === '') continue;

    if (numericos.includes(chave)) {
      const numero = Number(valor);
      if (!Number.isNaN(numero)) filtro[chave] = numero;
      continue;
    }

    filtro[chave] = valor;
  }

  return filtro as T;
}
