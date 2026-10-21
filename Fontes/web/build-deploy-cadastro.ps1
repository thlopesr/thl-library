# Build do cadastro e montagem de dist/thl-html-cadastro no formato padrao TOTVS
# (pasta para o webapps do Tomcat do Datasul)
#
# Uso: .\build-deploy-cadastro.ps1
# Parametro opcional:
#   -DeployPath : caminho do webapps; copia a pasta thl-html-cadastro para la

param(
    [string]$DeployPath = ""
)

$ErrorActionPreference = "Stop"

$project  = "cadastro"
$appName  = "thl-html-cadastro"
$folders  = @("html.cadastro", "html.menu")
$buildOut = ".\dist\$project"
$buildDir = "$buildOut\browser"
$appDir   = ".\dist\$appName"

Write-Host "=== Build de producao ($project) ===" -ForegroundColor Cyan
npx ng build $project --configuration production
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro no build Angular ($project)." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $buildDir)) {
    Write-Host "Diretorio de build nao encontrado: $buildDir" -ForegroundColor Red
    exit 1
}

foreach ($folder in $folders) {
    $dest = Join-Path $appDir $folder
    if (Test-Path $dest) {
        Remove-Item $dest -Recurse -Force
    }
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    Copy-Item -Path "$buildDir\*" -Destination $dest -Recurse -Force
    Write-Host "  -> $dest" -ForegroundColor Gray
}

# A saida bruta do ng build so serve para montar a pasta acima
Remove-Item $buildOut -Recurse -Force

Write-Host ""
Write-Host "=== Pacote pronto ===" -ForegroundColor Green
Write-Host "  $((Resolve-Path $appDir).Path)"
foreach ($folder in $folders) {
    Write-Host "    $folder/"
}


if ($DeployPath -and (Test-Path $DeployPath)) {

    $destino = Join-Path $DeployPath $appName
    $marca   = Get-Date -Format "yyyyMMdd-HHmmss"

    New-Item -ItemType Directory -Path $destino -Force | Out-Null

    # Publicacao segura, em duas fases. Fase 1 copia cada pasta para <pasta>.novo ao
    # lado da que esta no ar e confere; fase 2 troca tudo por rename. Nada e apagado
    # antes de todas as copias estarem completas, e uma troca que falhe desfaz as
    # anteriores - o modo antigo (apagar e depois copiar) deixava o contexto sem a
    # pasta quando a copia morria no meio, que e o 404 classico.

    # Fase 1: copiar e conferir
    foreach ($folder in $folders) {

        $origem = Join-Path $appDir  $folder
        $novo   = Join-Path $destino "$folder.novo"

        if (Test-Path $novo) {
            Remove-Item $novo -Recurse -Force
        }
        New-Item -ItemType Directory -Path $novo -Force | Out-Null

        try {
            Copy-Item -Path "$origem\*" -Destination $novo -Recurse -Force -ErrorAction Stop
        }
        catch {
            Write-Host "Falha ao copiar $folder : $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Nada foi alterado em $destino." -ForegroundColor Red
            foreach ($limpar in $folders) {
                Remove-Item (Join-Path $destino "$limpar.novo") -Recurse -Force -ErrorAction SilentlyContinue
            }
            exit 1
        }

        $esperado = @(Get-ChildItem $origem -Recurse -File).Count
        $copiado  = @(Get-ChildItem $novo   -Recurse -File).Count

        if (-not (Test-Path (Join-Path $novo "index.html")) -or $copiado -ne $esperado) {
            Write-Host "Copia incompleta de $folder ($copiado de $esperado arquivos)." -ForegroundColor Red
            Write-Host "Nada foi alterado em $destino." -ForegroundColor Red
            foreach ($limpar in $folders) {
                Remove-Item (Join-Path $destino "$limpar.novo") -Recurse -Force -ErrorAction SilentlyContinue
            }
            exit 1
        }

        Write-Host "  copiado: $folder ($copiado arquivos)" -ForegroundColor Gray
    }

    # Fase 2: trocar; se uma troca falhar, desfaz as ja feitas
    $trocadas = @()

    foreach ($folder in $folders) {

        $atual  = Join-Path $destino $folder
        $novo   = Join-Path $destino "$folder.novo"
        $falhou = ''

        if (Test-Path $atual) {
            try {
                Rename-Item -Path $atual -NewName "$folder.old-$marca" -ErrorAction Stop
            }
            catch {
                $falhou = "Nao foi possivel liberar $atual (contexto no ar?)."
            }
        }

        if ($falhou -eq '') {
            try {
                Rename-Item -Path $novo -NewName $folder -ErrorAction Stop
                $trocadas += $folder
            }
            catch {
                $falhou = "Falha ao publicar $folder : $($_.Exception.Message)"
                if (Test-Path (Join-Path $destino "$folder.old-$marca")) {
                    Rename-Item -Path (Join-Path $destino "$folder.old-$marca") -NewName $folder -ErrorAction SilentlyContinue
                }
            }
        }

        if ($falhou -ne '') {

            Write-Host $falhou -ForegroundColor Red

            # desfaz as trocas ja feitas nesta execucao
            foreach ($desfazer in $trocadas) {
                $publicada = Join-Path $destino $desfazer
                $anterior  = Join-Path $destino "$desfazer.old-$marca"
                if (Test-Path $anterior) {
                    Remove-Item $publicada -Recurse -Force -ErrorAction SilentlyContinue
                    Rename-Item -Path $anterior -NewName $desfazer -ErrorAction SilentlyContinue
                }
            }

            foreach ($limpar in $folders) {
                Remove-Item (Join-Path $destino "$limpar.novo") -Recurse -Force -ErrorAction SilentlyContinue
            }

            Write-Host "Pare o contexto no Tomcat e repita. Versao anterior mantida em $destino." -ForegroundColor Red
            exit 1
        }

        Write-Host "  -> $atual" -ForegroundColor Gray
    }

    # Versoes anteriores: so depois de tudo publicado
    foreach ($folder in $folders) {
        $anterior = Join-Path $destino "$folder.old-$marca"
        if (Test-Path $anterior) {
            Remove-Item $anterior -Recurse -Force -ErrorAction SilentlyContinue
            if (Test-Path $anterior) {
                Write-Host "  Versao anterior mantida em $anterior (arquivo em uso); pode apagar depois." -ForegroundColor Yellow
            }
        }
    }

    # So declara sucesso depois de ver o index.html de cada pasta no destino
    $faltando = @()
    foreach ($folder in $folders) {
        if (-not (Test-Path (Join-Path $destino "$folder\index.html"))) {
            $faltando += $folder
        }
    }

    if ($faltando.Count -gt 0) {
        Write-Host ""
        Write-Host "Publicacao incompleta: sem index.html em $($faltando -join ', ')." -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "=== Deploy publicado e conferido ===" -ForegroundColor Green
    Write-Host "  $destino"
    foreach ($folder in $folders) {
        Write-Host "    $folder\index.html  OK"
    }
    Write-Host "  Reinicie o contexto no Tomcat se necessario."

} elseif ($DeployPath) {
    Write-Host ""
    Write-Host "Caminho de deploy nao acessivel: $DeployPath" -ForegroundColor Yellow
    exit 1
}
