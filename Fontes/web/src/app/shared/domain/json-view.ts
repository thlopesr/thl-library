/**
 * JSON legível para as abas de Retorno e Parâmetro.
 *
 * Duas coisas além do `JSON.stringify(..., 2)`:
 *
 * 1. **Desembrulha JSON gravado dentro de string.** O ABL às vezes grava o JSON escapado
 *    (`"{\"codigo\":500}"`); nesse caso o `parse` devolve uma string e o `stringify` a
 *    imprime numa linha só, com as barras — parecendo não formatado.
 * 2. **Realça por tipo**, porque indentação sozinha não separa chave de valor quando o
 *    bloco tem dezenas de linhas.
 *
 * O que não for JSON volta como texto, escapado: o retorno do ABL nem sempre é JSON
 * (já vi mensagem de erro do parser do TOTVS aí dentro).
 */

/** `&`, `<` e `>` viram entidade: o conteúdo vai para `[innerHTML]`. */
function escapar(texto: string): string {
  return texto.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

/** Até três voltas: mais que isso é dado malformado, não JSON aninhado. */
function desembrulhar(texto: string): unknown {
  let atual: unknown = JSON.parse(texto);
  for (let i = 0; i < 3 && typeof atual === 'string'; i++) {
    try {
      atual = JSON.parse(atual);
    } catch {
      return atual;
    }
  }
  return atual;
}

export function formatarJson(texto: string | undefined | null): string {
  if (!texto) return '';
  try {
    return JSON.stringify(desembrulhar(texto), null, 2);
  } catch {
    return texto;
  }
}

/** HTML com as classes de realce. Use com `[innerHTML]` — e lembre do `::ng-deep`. */
export function realcarJson(texto: string | undefined | null): string {
  const formatado = formatarJson(texto);
  if (!formatado) return '';

  return escapar(formatado).replace(
    /("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+-]?\d+)?)/g,
    (trecho) => {
      let classe = 'thl-json__numero';
      if (trecho.startsWith('"')) {
        classe = trecho.endsWith(':') ? 'thl-json__chave' : 'thl-json__texto';
      } else if (/true|false/.test(trecho)) {
        classe = 'thl-json__booleano';
      } else if (/null/.test(trecho)) {
        classe = 'thl-json__nulo';
      }
      return `<span class="${classe}">${trecho}</span>`;
    }
  );
}
