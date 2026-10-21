<#
.SYNOPSIS
    Cadastra, pelos proprios endpoints REST, os objetos, parametros e rotas da
    API de cadastros THL (um objeto por agregado; filhos como operacao da URL).

.DESCRIPTION
    Equivalente ao Utils\scripts\carga-thl-api-cadastros.p, para ambiente em que
    a API ja esta no ar (endpoints aplicacao, objeto, objeto/parametro e
    objeto/rota respondendo; rodar antes o acerto-thl-operacao-service.p, que
    cria a linha da operacao rota). Ambiente novo, sem nenhuma rota, ou ambiente em
    que os objetos ainda estao sem a classe de service: rode a carga .p (ou o
    acerto-thl-objeto-classes.p) antes - sem o Service no cadastro do objeto, o
    proprio endpoint e recusado.

    O que faz:
      1. Garante a aplicacao THL, marcada como interna.
      2. Para cada cadastro pai ou independente: objeto com as tres classes
         (message, processor e service), parametros por metodo (GET, POST,
         PATCH, DELETE) e rota publica. Objeto ja cadastrado com classe
         diferente e alterado (PATCH).
      3. Para cada cadastro filho: desativa (PATCH indAtivo = false) a rota
         propria de carga anterior. O filho passa a ser operacao do pai:
         objeto/usuario, conexao-rest/header...
      4. Com -EliminarObsoletos: elimina os objetos proprios dos filhos
         (usuarios, parametros e o objeto), que ficaram sem uso.

    Roda em SIMULACAO por padrao: so consulta (GET) e mostra o que faria.
    Para gravar, informe -Executar.

    Antes de rodar com -Executar: os deltas de 2026-10-03 e 2026-10-04
    carregados e as classes novas compiladas e publicadas no PASOE
    (InboundMessage, Processor, os Processors de thl-extensions.integration.thl.messaging.inbound.process
    e os Services).

.PARAMETER BaseUrl
    Origem do servidor Datasul, sem barra no final. Ex.: https://servidor:porta

.PARAMETER Credential
    Usuario e senha do Datasul (Basic). Se omitido, o script pergunta.
    Nunca grave usuario ou senha neste arquivo.

.PARAMETER Executar
    Grava. Sem ele, o script so simula.

.PARAMETER EliminarObsoletos
    Elimina os objetos proprios dos filhos (so depois de a rota propria do
    filho estar desativada ou apontando para outro objeto).

.EXAMPLE
    .\cadastrar-thl-api-rotas.ps1 -BaseUrl https://servidor:porta

.EXAMPLE
    .\cadastrar-thl-api-rotas.ps1 -BaseUrl https://servidor:porta -Executar -EliminarObsoletos
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $BaseUrl,

    [System.Management.Automation.PSCredential] $Credential,

    [switch] $Executar,

    [switch] $EliminarObsoletos
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Aplicacao       = 'THL'
$PacoteMessage   = 'thl-extensions.integration.thl.messaging.inbound.message.'
$PacoteProcessor = 'thl-extensions.integration.thl.messaging.inbound.process.'
$PacoteService   = 'thl-extensions.erp.thl.service.'
$MessagePadrao   = 'thl-lib.integration.messaging.inbound.core.InboundMessage'
$ProcessorPadrao = 'thl-lib.integration.messaging.inbound.core.Processor'
$Endpoint        = $BaseUrl.TrimEnd('/') + '/api/thl/integration/v1/resourcen/'

# MethodTypeEnum: 1=POST 3=PATCH 4=DELETE 5=GET. Operacao em branco = linha do pai,
# obrigatoria: o InboundConfigLoader a usa para qualquer operacao da URL sem linha
# propria. As classes (message, processor e service) o servico copia do objeto.
$Metodos = @(
    @{ Operacao = ''    ; Metodo = 5 },
    @{ Operacao = ''    ; Metodo = 1 },
    @{ Operacao = ''    ; Metodo = 3 },
    @{ Operacao = ''    ; Metodo = 4 }
)

# Um objeto por agregado. Message e Processor em branco = classes padrao da
# biblioteca. O Service de cada filho (operacao da URL) fica na linha da operacao
# (classeService): depois deste script, rodar Utils\scripts\acerto-thl-operacao-service.p.
$Recursos = @(
    @{ Objeto = 'Ambiente'         ; Message = ''                        ; Processor = ''                        ; Service = 'AmbienteService'         ; Rota = 'ambiente'          ; Descricao = 'Cadastro de ambientes (thl0001)' },
    @{ Objeto = 'ParametroAmbiente'        ; Message = 'ParametroAmbienteMessage'; Processor = ''                        ; Service = 'ParametroAmbienteService'; Rota = 'parametro-ambiente'; Descricao = 'Parametros de ambiente (thl0002); operacoes variavel e programa' },
    @{ Objeto = 'Aplicacao'        ; Message = ''                        ; Processor = ''                        ; Service = 'AplicacaoService'        ; Rota = 'aplicacao'         ; Descricao = 'Cadastro de aplicacoes (thl0020)' },
    @{ Objeto = 'AuditoriaTabela'     ; Message = ''                        ; Processor = ''                        ; Service = 'AuditoriaTabelaService'  ; Rota = 'auditoria-tabela'  ; Descricao = 'Tabelas auditadas (thl0050); operacoes acesso, campo, notificacao e expurgo' },
    @{ Objeto = 'ConexaoRest'     ; Message = 'ConexaoRestMessage'      ; Processor = ''                        ; Service = 'ConexaoRestService'      ; Rota = 'conexao-rest'      ; Descricao = 'Conexoes REST (thl0030); operacoes autenticacao e header' },
    @{ Objeto = 'ConexaoRestPath'; Message = ''                        ; Processor = ''                        ; Service = 'ConexaoRestPathService'  ; Rota = 'conexao-rest-path' ; Descricao = 'Paths (endpoints) REST (thl0031)' },
    @{ Objeto = 'Objeto'           ; Message = ''                        ; Processor = ''                        ; Service = 'ObjetoService'           ; Rota = 'objeto'            ; Descricao = 'Objetos de integracao (thl0021); operacoes parametro e usuario' },
    @{ Objeto = 'EmailParametro'  ; Message = ''                        ; Processor = ''                        ; Service = 'EmailParametroService'   ; Rota = 'email-parametro'   ; Descricao = 'Parametros de e-mail (thl0010)' },
    @{ Objeto = 'GrupoEmail'      ; Message = ''                        ; Processor = ''                        ; Service = 'GrupoEmailService'       ; Rota = 'grupo-email'       ; Descricao = 'Grupos de e-mail (thl0011); operacao usuario' }
)

# Filhos: operacao da URL do pai. ObjetoAntigo e RotaAntiga = objeto e rota
# proprios de carga anterior (a rota e do objeto: chave aplicacao + objeto).
$Filhos = @(
    @{ NovaUrl = 'parametro-ambiente/variavel' ; ObjetoAntigo = 'PARAMETRO-VARIAVEL'       ; RotaAntiga = 'parametro-variavel' },
    @{ NovaUrl = 'parametro-ambiente/programa' ; ObjetoAntigo = 'PARAMETRO-PROGRAMA'       ; RotaAntiga = 'parametro-programa' },
    @{ NovaUrl = 'auditoria-tabela/acesso'     ; ObjetoAntigo = 'AUDIT-TABELA-ACESSO'      ; RotaAntiga = 'auditoria-tabela-acesso' },
    @{ NovaUrl = 'auditoria-tabela/campo'      ; ObjetoAntigo = 'AUDIT-TABELA-CAMPO'       ; RotaAntiga = 'auditoria-tabela-campo' },
    @{ NovaUrl = 'auditoria-tabela/notificacao'; ObjetoAntigo = 'AUDIT-TABELA-NOTIFICACAO' ; RotaAntiga = 'auditoria-tabela-notificacao' },
    @{ NovaUrl = 'auditoria-tabela/expurgo'    ; ObjetoAntigo = 'AUDIT-TABELA-EXPURGO'     ; RotaAntiga = 'auditoria-tabela-expurgo' },
    @{ NovaUrl = 'conexao-rest/autenticacao'   ; ObjetoAntigo = 'CONEXAO-REST-AUTENTICACAO'; RotaAntiga = 'conexao-rest-autenticacao' },
    @{ NovaUrl = 'conexao-rest/header'         ; ObjetoAntigo = 'CONEXAO-REST-HEADER'      ; RotaAntiga = 'conexao-rest-header' },
    @{ NovaUrl = 'objeto/parametro'            ; ObjetoAntigo = 'OBJETO-PARAMETRO'         ; RotaAntiga = 'objeto-parametro' },
    @{ NovaUrl = 'objeto/usuario'              ; ObjetoAntigo = 'OBJETO-USUARIO'           ; RotaAntiga = 'objeto-usuario' },
    @{ NovaUrl = 'objeto/rota'                 ; ObjetoAntigo = 'InboundRota'              ; RotaAntiga = 'inbound-rota' },
    @{ NovaUrl = 'grupo-email/usuario'         ; ObjetoAntigo = 'GRUPO-EMAIL-USUARIO'      ; RotaAntiga = 'grupo-email-usuario' }
)

if (-not $Credential) {
    $Credential = Get-Credential -Message 'Usuario e senha do Datasul'
}

$par     = '{0}:{1}' -f $Credential.UserName, $Credential.GetNetworkCredential().Password
$Headers = @{
    Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($par))
    Accept        = 'application/json'
}
Remove-Variable par

$Resumo = [ordered]@{ Criado = 0; Alterado = 0; Eliminado = 0; 'Ja cadastrado' = 0; Erro = 0 }

function Write-Linha {
    param([string] $Tabela, [string] $Chave, [string] $Acao)

    $cor = 'Gray'
    if ($Acao -like 'erro*')        { $cor = 'Red' }
    elseif ($Acao -ne 'ja cadastrado') { $cor = 'Green' }

    Write-Host ('{0,-22} {1,-48} {2}' -f $Tabela, $Chave, $Acao) -ForegroundColor $cor
}

function Add-Resultado {
    param([string] $Tipo, [string] $Tabela, [string] $Chave, [string] $Detalhe = '')

    $Resumo[$Tipo]++

    $acao = $Tipo.ToLower()
    if (-not $Executar -and $Tipo -in 'Criado', 'Alterado', 'Eliminado') { $acao = 'seria ' + $acao }
    if ($Detalhe) { $acao = $acao + ': ' + $Detalhe }

    Write-Linha $Tabela $Chave $acao
}

# Mensagem de erro devolvida pelo resourcen.p, quando houver
function Get-MensagemErro {
    param($Erro)

    $texto = $Erro.Exception.Message
    try {
        $resposta = $Erro.Exception.Response
        if ($resposta) {
            $leitor = New-Object IO.StreamReader($resposta.GetResponseStream())
            $corpo  = $leitor.ReadToEnd()
            if ($corpo) { $texto = $texto + ' - ' + $corpo }
        }
    } catch { }
    return $texto
}

function Invoke-Thl {
    param([string] $Metodo, [string] $Rota, [hashtable] $Query, [hashtable] $Corpo)

    $uri = $Endpoint + $Rota
    if ($Query) {
        $pares = foreach ($chave in $Query.Keys) { '{0}={1}' -f $chave, [Uri]::EscapeDataString([string] $Query[$chave]) }
        $uri   = $uri + '?' + ($pares -join '&')
    }

    $argumentos = @{ Method = $Metodo; Uri = $uri; Headers = $Headers }
    if ($Corpo) {
        $argumentos.ContentType = 'application/json; charset=utf-8'
        $argumentos.Body        = [Text.Encoding]::UTF8.GetBytes(($Corpo | ConvertTo-Json -Depth 5))
    }

    return Invoke-RestMethod @argumentos
}

# O GET devolve { items, hasNext } ou o array direto
function Get-Itens {
    param([string] $Rota, [hashtable] $Query)

    $resposta = Invoke-Thl -Metodo 'Get' -Rota $Rota -Query $Query
    if ($null -eq $resposta) { return @() }
    if ($resposta.PSObject.Properties.Name -contains 'items') { return @($resposta.items) }
    return @($resposta)
}

function Invoke-Gravacao {
    param([string] $Tipo, [string] $Tabela, [string] $Chave, [string] $Metodo, [string] $Rota, [hashtable] $Corpo)

    try {
        if ($Executar) { Invoke-Thl -Metodo $Metodo -Rota $Rota -Corpo $Corpo | Out-Null }
        Add-Resultado $Tipo $Tabela $Chave
    } catch {
        Add-Resultado 'Erro' $Tabela $Chave (Get-MensagemErro $_)
    }
}

function Set-Aplicacao {
    try {
        $itens = Get-Itens 'aplicacao' @{ aplicacaoIni = $Aplicacao; aplicacaoFin = $Aplicacao }
        $atual = $itens | Where-Object { $_.aplicacao -eq $Aplicacao } | Select-Object -First 1
    } catch {
        Add-Resultado 'Erro' 'thl-aplicacao' $Aplicacao (Get-MensagemErro $_)
        return
    }

    if (-not $atual) {
        Invoke-Gravacao 'Criado' 'thl-aplicacao' $Aplicacao 'Post' 'aplicacao' @{
            aplicacao  = $Aplicacao
            descricao  = 'THL - cadastros do proprio framework'
            indInterna = $true
        }
        return
    }

    if ($atual.indInterna) {
        Add-Resultado 'Ja cadastrado' 'thl-aplicacao' $Aplicacao
        return
    }

    # aplicacao do proprio THL: marca como interna
    Invoke-Gravacao 'Alterado' 'thl-aplicacao' ($Aplicacao + ' -> interna') 'Patch' 'aplicacao' @{
        aplicacao  = $Aplicacao
        indInterna = $true
    }
}

function Set-Objeto {
    param([hashtable] $Recurso)

    $chave     = $Aplicacao + '/' + $Recurso.Objeto
    $message   = $MessagePadrao
    $processor = $ProcessorPadrao
    $service   = $PacoteService + $Recurso.Service

    if ($Recurso.Message)   { $message   = $PacoteMessage   + $Recurso.Message }
    if ($Recurso.Processor) { $processor = $PacoteProcessor + $Recurso.Processor }

    try {
        $itens = Get-Itens 'objeto' @{ aplicacaoIni = $Aplicacao; aplicacaoFin = $Aplicacao; objetoIni = $Recurso.Objeto; objetoFin = $Recurso.Objeto }
        $atual = $itens | Where-Object { $_.objeto -eq $Recurso.Objeto } | Select-Object -First 1
    } catch {
        Add-Resultado 'Erro' 'thl-objeto' $chave (Get-MensagemErro $_)
        return
    }

    if (-not $atual) {
        Invoke-Gravacao 'Criado' 'thl-objeto' $chave 'Post' 'objeto' @{
            aplicacao        = $Aplicacao
            objeto           = $Recurso.Objeto
            classeObjeto     = $message
            classeProcessor  = $processor
            classeService    = $service
            modeloIntegracao = 1          # REST
            sentidoFluxo     = $false     # Entrada
            indInativo       = $false
            indGeraHistorico = $false
        }
        return
    }

    if ($atual.classeObjeto -eq $message -and $atual.classeProcessor -eq $processor -and $atual.classeService -eq $service) {
        Add-Resultado 'Ja cadastrado' 'thl-objeto' $chave
        return
    }

    # objeto de carga anterior: acerta as tres classes
    Invoke-Gravacao 'Alterado' 'thl-objeto' ($chave + ' -> classes') 'Patch' 'objeto' @{
        aplicacao       = $Aplicacao
        objeto          = $Recurso.Objeto
        classeObjeto    = $message
        classeProcessor = $processor
        classeService   = $service
    }
}

function Set-Parametros {
    param([hashtable] $Recurso)

    try {
        $itens = Get-Itens 'objeto/parametro' @{ aplicacaoIni = $Aplicacao; aplicacaoFin = $Aplicacao; objetoIni = $Recurso.Objeto; objetoFin = $Recurso.Objeto }
    } catch {
        Add-Resultado 'Erro' 'thl-objeto-parametro' ($Aplicacao + '/' + $Recurso.Objeto) (Get-MensagemErro $_)
        return
    }

    foreach ($metodo in $Metodos) {
        $chave = '*/{0}/{1}/(branco)/{2}' -f $Aplicacao, $Recurso.Objeto, $metodo.Metodo

        if ($itens | Where-Object { $_.objeto -eq $Recurso.Objeto -and $_.estabelecimento -eq '*' -and $_.operacao -eq $metodo.Operacao -and $_.metodo -eq $metodo.Metodo }) {
            Add-Resultado 'Ja cadastrado' 'thl-objeto-parametro' $chave
            continue
        }

        Invoke-Gravacao 'Criado' 'thl-objeto-parametro' $chave 'Post' 'objeto/parametro' @{
            estabelecimento    = '*'
            aplicacao          = $Aplicacao
            objeto             = $Recurso.Objeto
            operacao           = $metodo.Operacao
            metodo             = $metodo.Metodo
            formaExecucao      = 1        # Online
            indInativo         = $false
            indMensagemSimples = $false
            indGeraHistorico   = $false
        }
    }
}

# Rotas do objeto: a chave e aplicacao + objeto + rota publica (o objeto pode ter varias).
# Sem $RotaPublica devolve todas as rotas do objeto; com ela, so a rota pedida.
function Get-Rota {
    param([string] $Objeto, [string] $RotaPublica = '')

    $filtro = @{ aplicacaoIni = $Aplicacao; aplicacaoFin = $Aplicacao; objetoIni = $Objeto; objetoFin = $Objeto }
    if ($RotaPublica) {
        $filtro.rotaPublicaIni = $RotaPublica
        $filtro.rotaPublicaFin = $RotaPublica
    }

    $itens = Get-Itens 'objeto/rota' $filtro
    return $itens | Where-Object {
        $_.aplicacao -eq $Aplicacao -and $_.objeto -eq $Objeto -and
        (-not $RotaPublica -or $_.rotaPublica -eq $RotaPublica)
    }
}

function Set-Rota {
    param([string] $RotaPublica, [string] $Objeto)

    $chave = '{0} -> {1}/{2}' -f $RotaPublica, $Aplicacao, $Objeto

    try {
        $rota = @(Get-Rota $Objeto $RotaPublica) | Select-Object -First 1
    } catch {
        Add-Resultado 'Erro' 'thl-objeto-rota' $chave (Get-MensagemErro $_)
        return
    }

    if (-not $rota) {
        Invoke-Gravacao 'Criado' 'thl-objeto-rota' $chave 'Post' 'objeto/rota' @{
            aplicacao   = $Aplicacao
            objeto      = $Objeto
            rotaPublica = $RotaPublica
            indAtivo    = $true
        }
        return
    }

    if ($rota.indAtivo) {
        Add-Resultado 'Ja cadastrado' 'thl-objeto-rota' $RotaPublica
        return
    }

    Invoke-Gravacao 'Alterado' 'thl-objeto-rota' $chave 'Patch' 'objeto/rota' @{
        aplicacao   = $Aplicacao
        objeto      = $Objeto
        rotaPublica = $RotaPublica
        indAtivo    = $true
    }
}

# Rota propria de filho (carga anterior): desativa. O filho e operacao da URL do pai.
function Disable-RotaAntiga {
    param([hashtable] $Filho)

    try {
        $rota = @(Get-Rota $Filho.ObjetoAntigo $Filho.RotaAntiga) | Select-Object -First 1
    } catch {
        Add-Resultado 'Erro' 'thl-objeto-rota' $Filho.RotaAntiga (Get-MensagemErro $_)
        return
    }

    if (-not $rota -or -not $rota.indAtivo) { return }

    Invoke-Gravacao 'Alterado' 'thl-objeto-rota' ('{0} -> desativada (nova URL: {1})' -f $Filho.RotaAntiga, $Filho.NovaUrl) 'Patch' 'objeto/rota' @{
        aplicacao   = $Aplicacao
        objeto      = $Filho.ObjetoAntigo
        rotaPublica = $Filho.RotaAntiga
        indAtivo    = $false
    }
}

function Remove-ObjetoObsoleto {
    param([string] $Objeto)

    $filtro = @{ aplicacaoIni = $Aplicacao; aplicacaoFin = $Aplicacao; objetoIni = $Objeto; objetoFin = $Objeto }
    $chave  = $Aplicacao + '/' + $Objeto

    try {
        $objetos    = @(Get-Itens 'objeto' $filtro           | Where-Object { $_.objeto -eq $Objeto })
        if (-not $objetos) { return }

        # nao elimina objeto que ainda tem rota ativa apontando para ele
        $rotas = @(Get-Rota $Objeto | Where-Object { $_ -and $_.indAtivo })
        if ($rotas -and $Executar) {
            Add-Resultado 'Erro' 'thl-objeto' $chave 'ainda ha rota ativa apontando para o objeto; nao eliminado'
            return
        }

        $usuarios   = @(Get-Itens 'objeto/usuario'   $filtro | Where-Object { $_.objeto -eq $Objeto })
        $parametros = @(Get-Itens 'objeto/parametro' $filtro | Where-Object { $_.objeto -eq $Objeto })
    } catch {
        Add-Resultado 'Erro' 'thl-objeto' $chave (Get-MensagemErro $_)
        return
    }

    foreach ($usuario in $usuarios) {
        Invoke-Gravacao 'Eliminado' 'thl-objeto-usuario' ($chave + '/' + $usuario.usuario) 'Delete' 'objeto/usuario' @{
            aplicacao = $Aplicacao; objeto = $Objeto; usuario = $usuario.usuario
        }
    }

    foreach ($parametro in $parametros) {
        Invoke-Gravacao 'Eliminado' 'thl-objeto-parametro' ('{0}/{1}/{2}' -f $parametro.estabelecimento, $chave, $parametro.operacao) 'Delete' 'objeto/parametro' @{
            estabelecimento = $parametro.estabelecimento; aplicacao = $Aplicacao; objeto = $Objeto; operacao = $parametro.operacao; metodo = $parametro.metodo
        }
    }

    Invoke-Gravacao 'Eliminado' 'thl-objeto' $chave 'Delete' 'objeto' @{ aplicacao = $Aplicacao; objeto = $Objeto }
}

# ------------------------------------------------------------------ principal

Write-Host ''
if ($Executar) { Write-Host 'GRAVANDO em' $Endpoint -ForegroundColor Yellow }
else           { Write-Host 'SIMULACAO (nada sera gravado) em' $Endpoint -ForegroundColor Yellow }
Write-Host ''

Set-Aplicacao

foreach ($recurso in $Recursos) {
    Set-Objeto     $recurso
    Set-Parametros $recurso
    Set-Rota $recurso.Rota $recurso.Objeto
}

Write-Host ''
Write-Host 'Rotas proprias dos filhos (carga anterior):' -ForegroundColor Yellow
foreach ($filho in $Filhos) {
    Disable-RotaAntiga $filho
}

if ($EliminarObsoletos) {
    Write-Host ''
    Write-Host 'Objetos proprios dos filhos (sem uso: o filho virou operacao do pai):' -ForegroundColor Yellow
    foreach ($filho in $Filhos) {
        Remove-ObjetoObsoleto $filho.ObjetoAntigo
    }
}

Write-Host ''
Write-Host 'Resumo' -ForegroundColor Yellow
foreach ($tipo in $Resumo.Keys) {
    $rotulo = $tipo
    if (-not $Executar -and $tipo -in 'Criado', 'Alterado', 'Eliminado') { $rotulo = 'Seria ' + $tipo.ToLower() }
    Write-Host ('  {0,-18} {1}' -f $rotulo, $Resumo[$tipo])
}

if ($Resumo.Erro -gt 0) { exit 1 }
