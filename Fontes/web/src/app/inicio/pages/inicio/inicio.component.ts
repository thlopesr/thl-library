import { ChangeDetectionStrategy, Component } from '@angular/core';
import { PoModule } from '@po-ui/ng-components';
import { NavCard, ThlNavCardComponent } from '../../../shared/components/thl-nav-card';
import { ThlPageHeaderComponent } from '../../../shared/components/thl-page-header';
import {
  ambienteDef, aplicacaoDef, auditoriaDef, conexaoDef, emailDef, grupoEmailDef, objetoDef, parametroDef, pathDef
} from '../../../cadastros/cadastros.defs';

interface GrupoInicio {
  titulo: string;
  descricao: string;
  /** Só o primeiro grupo tem: ordem de dependência é informação, não decoração. */
  nota?: string;
  cards: NavCard[];
}

// Página inicial do app de cadastro. Orienta quem não sabe em qual dos nove itens do
// menu mexer: cada grupo diz para que serve e leva ao cadastro certo. Não mede nada —
// não há contagem, logo não há requisição, carregando nem erro.
//
// Os títulos vêm das definições do motor (renomear um cadastro atualiza a home sozinha);
// as descrições ficam aqui, porque o `subtitle` da definição é cabeçalho do browse e
// carrega nome de programa (`thl0020`), que não serve de texto de orientação.
@Component({
  selector: 'app-inicio',
  standalone: true,
  imports: [PoModule, ThlPageHeaderComponent, ThlNavCardComponent],
  templateUrl: './inicio.component.html',
  styleUrls: ['./inicio.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class InicioComponent {
  grupos: GrupoInicio[] = [
    {
      titulo: 'Base do ambiente',
      descricao: 'O que muda de um ambiente para outro: endereço, usuário, limite, caminho.',
      nota: 'Comece por aqui: os demais cadastros apontam para ambiente e parâmetro.',
      cards: [
        {
          icone: 'an an-globe-simple',
          titulo: ambienteDef.title,
          descricao: 'Produção, homologação e teste, com o IP de cada um.',
          rota: '/ambiente'
        },
        {
          icone: 'an an-gear-six',
          titulo: parametroDef.title,
          descricao: 'Valores que mudam por ambiente, agrupados por assunto.',
          rota: '/parametro'
        }
      ]
    },
    {
      titulo: 'Integração',
      descricao: 'Quem troca mensagens com o THL e por onde cada chamada sai.',
      cards: [
        {
          icone: 'an an-squares-four',
          titulo: aplicacaoDef.title,
          descricao: 'Sistemas externos que conversam com o THL.',
          rota: '/aplicacao'
        },
        {
          icone: 'an an-cube',
          titulo: objetoDef.title,
          descricao: 'O que cada aplicação envia ou recebe, com rotas e usuários.',
          rota: '/objeto'
        },
        {
          icone: 'an an-plugs',
          titulo: conexaoDef.title,
          descricao: 'Endereço, autenticação e header dos serviços REST chamados.',
          rota: '/conexao'
        },
        {
          icone: 'an an-path',
          titulo: pathDef.title,
          descricao: 'Endpoints reutilizáveis entre conexões.',
          rota: '/path'
        }
      ]
    },
    {
      titulo: 'Notificação e auditoria',
      descricao: 'Quem é avisado e o que fica registrado.',
      cards: [
        {
          icone: 'an an-users-three',
          titulo: grupoEmailDef.title,
          descricao: 'Listas de destinatários usadas nos avisos.',
          rota: '/grupo-email'
        },
        {
          icone: 'an an-envelope-simple',
          titulo: emailDef.title,
          descricao: 'Remetente, assunto e corpo padrão dos envios.',
          rota: '/email'
        },
        {
          icone: 'an an-clipboard-text',
          titulo: auditoriaDef.title,
          descricao: 'Tabelas acompanhadas, campos, acessos e expurgo.',
          rota: '/auditoria'
        }
      ]
    }
  ];
}
