# Visão geral da THL‑Lib

A **Biblioteca THL / THL‑Lib** é um framework corporativo desenvolvido em **OpenEdge ABL** para o **ERP TOTVS Datasul 12**.  
Ela tem como objetivo **padronizar integrações, mensageria e utilitários** de uso comum dentro do ERP e permitir a **reutilização de componentes** entre clientes sem acoplar regras de negócio específicas na camada base.  

A solução divide‑se em dois grandes componentes:

* **`thl`** – Conjunto de programas `.w` que expõem telas, cadastros e monitores no ERP. Esses programas permitem configurar ambientes, parâmetros, objetos de integração, conexões REST, rotas inbound, monitorar mensagens e e‑mails.  
* **`thl‑lib`** – Biblioteca de classes `.cls` que implementa a lógica técnica reutilizável: contexto de execução, acesso a tabelas, tratamento de erros, log, mensageria inbound/outbound, conectores REST, comunicação por e‑mail, utilitários de JSON, arquivos e texto.  

A THL‑Lib foi concebida como **produto reutilizável** e não como customização pontual.  O código técnico e os nomes das classes permanecem em inglês, enquanto as telas e documentação de uso podem estar em português.  

## Objetivos principais

* **Padronizar integrações** com sistemas externos (REST/JSON).  
* **Centralizar persistência** em *repositories* e orquestrar casos de uso via *services*.  
* **Gerenciar mensageria** com controle de ciclo de vida, histórico, conteúdo, status e reprocessamento.  
* **Isolar conectores** de transporte (REST) em classes especializadas, permitindo diferentes tipos de autenticação.  
* **Configurar ambientes e parâmetros** sem recompilar programas, facilitando implantação em múltiplos clientes.  
* **Registrar auditoria e log** de execução e comunicação (e‑mail).  
* **Permitir expansão** com novos objetos de integração, rotas inbound/outbound e conectores personalizados.  

A seguir são apresentados inventários de programas, classes e tabelas, além de guias técnicos e funcionais para utilização da biblioteca.
