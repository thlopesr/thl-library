/** Um destino de navegação: ícone, nome e uma linha dizendo para que serve. */
export interface NavCard {
  /** Classe do ícone AnimaliaDS — o mesmo do item no menu lateral. */
  icone: string;
  titulo: string;
  descricao: string;
  /** Rota interna do app (`routerLink`); o `withHashLocation()` cuida do `#/`. */
  rota: string;
}
