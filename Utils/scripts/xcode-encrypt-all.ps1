# xcode-encrypt-all.ps1

$fontes   = "C:\Users\Lopes\Google\Workspace\THL-Library\Fontes\thl-lib"
$destino  = "C:\Users\Lopes\Google\Workspace\THL-Library\Xcode\thl-lib"
$xcodeExe = "$env:DLC\bin\xcode.exe"
$chave    = "THL2K99"

if (-not $env:DLC) {
    Write-Host "ERRO: variavel de ambiente DLC nao definida." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $xcodeExe)) {
    Write-Host "ERRO: xcode.exe nao encontrado em: $xcodeExe" -ForegroundColor Red
    exit 1
}

$arquivos = Get-ChildItem -Path $fontes -Recurse -Include "*.cls"
$total    = $arquivos.Count
$ok       = 0
$erros    = 0
$contador = 0

# Pre-cria toda a estrutura de diretorios no destino
foreach ($arquivo in $arquivos) {
    $relativo     = $arquivo.FullName.Substring($fontes.Length + 1)
    $pastaRel     = Split-Path $relativo -Parent
    $pastaDestino = Join-Path $destino $pastaRel
    if (-not (Test-Path $pastaDestino)) {
        New-Item -ItemType Directory -Path $pastaDestino -Force | Out-Null
    }
}

# Muda para a raiz de Fontes — xcode recebe path relativo
Push-Location $fontes

foreach ($arquivo in $arquivos) {
    $contador++
    $relativo = $arquivo.FullName.Substring($fontes.Length + 1)

    Write-Host "[$contador/$total] $relativo" -NoNewline

    & $xcodeExe -k $chave -d "$destino\" "$relativo" 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host " [OK]" -ForegroundColor Green
        $ok++
    } else {
        Write-Host " [ERRO: exit $LASTEXITCODE]" -ForegroundColor Red
        $erros++
    }
}

Pop-Location

Write-Host ""
Write-Host ("=" * 50)
Write-Host "RESUMO"
Write-Host "Total processados : $total"
Write-Host "Sucesso           : $ok"    -ForegroundColor Green
Write-Host "Erros             : $erros" -ForegroundColor Red
