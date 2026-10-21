---
tipo: guia
camada: ambos
status: referencia
tags: [thl, cadastro, moc]
updated: 2026-10-19
---

# Cadastros THL

Dicionário de campos das telas de cadastro do THL (programas `.w` do Datasul). Fonte da verdade: o código em `Fontes/` e o dicionário `Database/Definition/thl.df`; onde o código não esclarece, a nota marca `⚠ a confirmar`.

| Grupo | Função | Situação |
|---|---|---|
| thl000 | Ambiente (thl0001, thl0002) | a gerar |
| thl001 | E-mail (thl0010, thl0011) | a gerar |
| thl002 | Integração (thl0020, thl0021, thl0022) | a gerar |
| [thl003 Conexão REST](thl003-conexao-rest.md) | Conexão REST (thl0030–thl0033) | **gerado** (aguardando revisão) |
| thl004 | Rotas (thl0040) | a gerar |
| thl005 | Auditoria (thl0050, thl0051) | a gerar |

Notas de fluxo no vault do repositório: [fluxo-saida](../../fluxos/fluxo-saida.md) · [fluxo-ambiente](../../fluxos/fluxo-ambiente.md) · [fluxo-entrada](../../fluxos/fluxo-entrada.md) · [fluxo-email](../../fluxos/fluxo-email.md).
