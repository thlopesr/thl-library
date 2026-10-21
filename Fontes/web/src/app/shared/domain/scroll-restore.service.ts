import { Injectable, inject } from '@angular/core';
import { NavigationEnd, NavigationStart, Router } from '@angular/router';
import { filter } from 'rxjs';

/**
 * Devolve a rolagem ao voltar para uma tela.
 *
 * O `withInMemoryScrolling` do Angular **não serve aqui**: ele rola a janela, e nestas
 * telas quem rola é o `.po-page-content` do template PO UI — medido em 16/10/2026 na
 * mensageria com 80 linhas, o documento tinha a altura da janela (não rolava) enquanto
 * o `.po-page-content` tinha 728px de altura para 2358px de conteúdo.
 *
 * Duas regras deliberadas:
 *
 * - **Nunca força o topo.** Só mexe na rolagem quando tem uma posição guardada para a
 *   URL de destino. Assim uma navegação comum (ou o `replaceUrl` que as telas usam para
 *   gravar filtro) não dá o pulo para o topo que o modo `enabled` do Angular daria.
 * - **Espera a lista chegar.** O conteúdo vem por HTTP depois da navegação; no primeiro
 *   quadro ele ainda é curto e o `scrollTop` seria truncado. Por isso tenta por até 10s —
 *   uma janela de 1s não bastou no teste, com o backend lento. A espera é cancelada assim
 *   que o usuário mexe na tela (roda, toca ou usa o teclado): quem já está lendo não pode
 *   ser arrastado para outro ponto.
 */
@Injectable({ providedIn: 'root' })
export class ThlScrollRestoreService {
  private router = inject(Router);

  /** Posição por URL **sem** query string: filtro e página já vivem na própria URL,
   *  e guardar por URL completa faria cada troca de filtro perder a posição. */
  private posicoes = new Map<string, number>();
  private iniciado = false;

  iniciar(): void {
    if (this.iniciado) return;
    this.iniciado = true;

    this.router.events
      .pipe(filter((e): e is NavigationStart => e instanceof NavigationStart))
      .subscribe(() => this.guardar(this.chave(this.router.url)));

    this.router.events
      .pipe(filter((e): e is NavigationEnd => e instanceof NavigationEnd))
      .subscribe(evento => this.restaurar(this.chave(evento.urlAfterRedirects)));
  }

  private chave(url: string): string {
    return url.split('?')[0];
  }

  private area(): HTMLElement | null {
    return document.querySelector<HTMLElement>('.po-page-content');
  }

  private guardar(chave: string): void {
    const area = this.area();
    if (!area) return;
    if (area.scrollTop > 0) this.posicoes.set(chave, area.scrollTop);
    else this.posicoes.delete(chave);
  }

  /** Cancela a espera em andamento, se houver. */
  private pararEspera?: () => void;

  private restaurar(chave: string): void {
    this.pararEspera?.();

    const alvo = this.posicoes.get(chave);
    if (alvo === undefined) return;

    let tentativa = 0;
    const limite = 100; // 100 × 100ms = 10s

    const tentar = () => {
      const area = this.area();
      if (area && area.scrollHeight - area.clientHeight >= alvo) {
        area.scrollTop = alvo;
        encerrar();
        return;
      }
      if (++tentativa >= limite) encerrar();
    };

    const temporizador = setInterval(tentar, 100);
    const encerrar = () => {
      clearInterval(temporizador);
      eventos.forEach(e => window.removeEventListener(e, encerrar, true));
      this.pararEspera = undefined;
    };

    // Mexeu na tela, a espera acabou: restaurar depois disso seria arrastar quem já está lendo.
    const eventos = ['wheel', 'touchstart', 'keydown'];
    eventos.forEach(e => window.addEventListener(e, encerrar, true));
    this.pararEspera = encerrar;

    tentar();
  }
}
