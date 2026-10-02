# Regras para futuras IAs que utilizarem a THL‑Lib

Esta seção estabelece diretrizes para agentes de IA ou sistemas automáticos que venham a utilizar ou modificar a Biblioteca THL.  O objetivo é preservar a arquitetura e garantir a consistência do produto.

1. **Não inventar componentes inexistentes** – Apenas use classes, tabelas e programas presentes na biblioteca ou documentados oficialmente.  Se precisar de novos elementos, crie extensões separadas seguindo os padrões de nomenclatura (por exemplo, `thl-newobjeto.w`, `NewObjectMessage.cls`).
2. **Manter separação `thl` vs. `thl‑lib`** – Programas `.w` devem permanecer no diretório `thl/` e classes reutilizáveis em `thl‑lib/`.  Não misture telas com classes.  
3. **Preservar padrões arquiteturais** – Ao criar novas integrações, utilize *repositories*, *services*, *factories*, *connectors* e *enums* conforme o modelo existente.  Evite acesso direto a tabelas fora dos repositórios.  
4. **Utilizar campos de relacionamento corretamente** – Chaves estrangeiras devem referenciar tabelas correspondentes.  Não adicione novos campos sem atualizar a documentação.  
5. **Registrar histórico e mensageria** – Toda integração inbound ou outbound deve gravar registros em `thl-mensagem` e tabelas derivadas.  Nunca exclua registros; utilize indicadores de inatividade se necessário.  
6. **Configuração via tabelas** – Parâmetros de ambiente, objetos, métodos e conexões devem ser configuráveis nas tabelas `thl-*`.  Não codifique valores fixos no código.  
7. **Evitar regras de negócio específicas na camada base** – Regras que atendem somente um cliente devem ser implementadas em camadas superiores ou programas fora de `thl-lib`.  A camada base deve permanecer genérica.  
8. **Linguagem de código** – Mantenha nomes de classes, métodos e campos em inglês.  A documentação e interface podem ser em português, mas o código deve seguir padrões técnicos internacionais.  
9. **Documentar alterações** – Cada nova classe, tabela ou campo deve ser documentado em arquivos `.md` semelhantes a estes, para que outras IAs possam compreender rapidamente.  
10. **Revisar dependências externas** – Ao adicionar novos conectores ou bibliotecas, verifique se são compatíveis com a stack do ERP TOTVS Datasul e com as práticas de segurança.

Seguindo essas regras, novas IAs poderão evoluir a biblioteca sem perder sua identidade corporativa e mantendo a compatibilidade com versões anteriores.
