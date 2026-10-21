import { Directive, ElementRef, HostListener, inject } from '@angular/core';

/**
 * Fecha o tooltip que o `po-menu` recolhido deixa preso na tela.
 *
 * Defeito do PO UI, reproduzido em 15/10/2026 numa página recém-carregada: passar o mouse
 * por um item cria o tooltip, tirar o mouse **não o remove** — o elemento fica em `<body>`
 * com `visibility: visible`, e vão se acumulando um por item visitado. Sobrevive até à troca
 * de rota, porque mora fora da árvore do componente.
 *
 * O conserto tem duas partes, porque avisar não basta:
 *
 * 1. **Avisa o item que o ponteiro saiu** — um `mouseleave` disparado no item faz a própria
 *    diretiva do PO UI remover o tooltip, que é o caminho limpo.
 * 2. **Varre o que sobrou** — saindo *pelo lado*, o ponteiro entra no próprio tooltip
 *    (`mouseout` com `relatedTarget` = `po-tooltip-content`) e a diretiva fica com
 *    `tooltipContent: undefined` **sem ter removido o nó**: medido, o elemento continua no
 *    `body` e nenhuma diretiva o referencia mais. Como a biblioteca já o esqueceu, removê-lo
 *    não briga com ela — e o `removeChild` do Angular é `oldChild.remove()`, que não reclama
 *    de nó já solto.
 *
 * A varredura **captura a lista no instante do evento** e só apaga esses nós. Isso é o que
 * protege o tooltip novo: ao andar de um item para outro, o `mouseover` chega **antes** de o
 * PO UI criar o próximo, então o que nasce depois não está na lista. Casar por texto não
 * serviria — o tooltip usa o `shortLabel` do item, não o `aria-label`.
 */
@Directive({
  selector: '[thlMenuTooltipFix]',
  standalone: true
})
export class ThlMenuTooltipFixDirective {
  private host: ElementRef<HTMLElement> = inject(ElementRef);

  /** Último item sob o ponteiro: `mouseover` repete dentro do mesmo item (ícone, texto),
   *  e varrer nessas repetições apagaria o tooltip que está sendo mostrado. */
  private ultimoItem: Element | null = null;

  /** Ponteiro saiu do menu inteiro: nenhum item pode continuar com tooltip. */
  @HostListener('mouseleave')
  aoSairDoMenu(): void {
    this.ultimoItem = null;
    this.fechar();
    this.varrer();
  }

  /** Andando de um item para outro, o anterior também precisa fechar — senão sobram dois. */
  @HostListener('mouseover', ['$event'])
  aoAndarNoMenu(evento: MouseEvent): void {
    const atual = (evento.target as HTMLElement | null)?.closest('.po-menu-item') ?? null;
    if (atual === this.ultimoItem) return;

    this.ultimoItem = atual;
    this.fechar(atual);
    this.varrer();
  }

  private fechar(exceto?: Element | null): void {
    const itens = this.host.nativeElement.querySelectorAll<HTMLElement>('.po-menu-item');
    itens.forEach((item: HTMLElement) => {
      if (item !== exceto) item.dispatchEvent(new MouseEvent('mouseleave'));
    });
  }

  /** O `setTimeout` deixa o PO UI tentar a remoção dele primeiro (ele também usa um). */
  private varrer(): void {
    const existentes = Array.from(document.querySelectorAll<HTMLElement>('body > .po-tooltip'));
    setTimeout(() => existentes.forEach((no: HTMLElement) => no.remove()));
  }
}
