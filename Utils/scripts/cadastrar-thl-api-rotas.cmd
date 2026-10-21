@echo off
rem Cadastra, pelos endpoints REST, os objetos (com as classes de message,
rem processor e service), parametros e rotas da API de cadastros THL, e
rem desativa as rotas proprias dos filhos (o filho e operacao: objeto/usuario).
rem Repassa os argumentos para o cadastrar-thl-api-rotas.ps1.
rem
rem   cadastrar-thl-api-rotas.cmd -BaseUrl https://servidor:porta
rem   cadastrar-thl-api-rotas.cmd -BaseUrl https://servidor:porta -Executar
rem   cadastrar-thl-api-rotas.cmd -BaseUrl https://servidor:porta -Executar -EliminarObsoletos
rem
rem Sem -Executar o script so simula. Usuario e senha sao pedidos na hora.

if "%~1"=="" (
    echo Uso: %~nx0 -BaseUrl https://servidor:porta [-Executar] [-EliminarObsoletos]
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0cadastrar-thl-api-rotas.ps1" %*
exit /b %ERRORLEVEL%
