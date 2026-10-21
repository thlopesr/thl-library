/**
 * Ordena do mais recente para o mais antigo pelo campo de data informado.
 *
 * As datas chegam da API em ISO (`2026-10-15T09:30:00`), formato em que a ordem
 * alfabética **é** a ordem cronológica — por isso a comparação é de texto, sem
 * `new Date()` por item. Se um dia a API passar a mandar `dd/MM/yyyy`, isto quebra
 * em silêncio: a ordem fica por dia do mês. Vazio vai para o fim.
 */
export function maisRecentePrimeiro<T>(itens: T[], campo: keyof T): T[] {
  return [...itens].sort((a, b) => {
    const va = String(a[campo] ?? '');
    const vb = String(b[campo] ?? '');
    if (va === vb) return 0;
    if (!va) return 1;
    if (!vb) return -1;
    return vb.localeCompare(va);
  });
}
