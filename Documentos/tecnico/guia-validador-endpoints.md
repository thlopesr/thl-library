# Guia — validador de endpoints (Postman → tela HTML)

Script Python (só biblioteca padrão) em `Utils/scripts/validador-endpoints/` que lê a collection **Nitro** no Postman e executa os requests da pasta `TOTVS/Projeto/THL-Library/THL`, mostrando o resultado em uma tela local.

## Configuração

1. Copie `env.exemplo` para `.env` (ao lado do script; ignorado pelo Git) e preencha `POSTMAN_API_KEY`. Usuário e senha são opcionais: sem eles, vale a autenticação basic da própria collection.
2. Python 3.10+.

## Uso

```text
python Utils/scripts/validador-endpoints/validador_endpoints.py --ambiente PROJETO-INTERNO
```

Abre `http://127.0.0.1:8765/`. Na tela: escolha o ambiente, **Executar tudo**, **Executar só GET** ou **Executar** por recurso; filtre pelos contadores; clique numa linha para ver o request e a resposta (o `Authorization` aparece mascarado).

Opções: `--cli` (terminal, código de saída 1 se houver falha; `--json arquivo` grava o resultado), `--arquivo collection.json` (usa um export em vez da API), `--escopo`, `--porta`, `--sem-navegador`, `--so-get`.

## Regras

- **Pasta com os 4 métodos** (GET, POST, PATCH, DELETE): GET → pré-limpeza (DELETE) → POST → subpastas → PATCH → DELETE. O DELETE roda mesmo que o PATCH falhe. Os dados de teste são os dos próprios requests (ex.: `codAmbiente` `TSA`).
- **Pasta sem os 4 métodos**: só os GET; o restante fica `IGNORADO`. Subpastas seguem a mesma regra; se o POST do pai falhar, a escrita dos filhos é ignorada.
- **Produção**: ambiente cujo nome contém `PRODUCAO` executa só GET.
- **Critério de sucesso**: o dos testes do request no Postman (`status`, `success`, `items`/`hasNext`); sem teste, vale HTTP 2xx e JSON válido.

## Limites

- POST/PATCH/DELETE gravam dados de verdade: use em Projeto/homologação. Uma falha no meio do ciclo pode deixar o registro de teste; a próxima rodada o remove na pré-limpeza.
- Valida contrato e ciclo CRUD, não regra de negócio. Testado só contra um servidor simulado; a execução no Datasul real depende da rede e das credenciais do usuário.
