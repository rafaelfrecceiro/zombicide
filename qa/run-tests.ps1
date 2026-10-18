[CmdletBinding()]
param([switch]$Render)
$ErrorActionPreference = 'Stop'
$zomEngine = (Get-Command 'Godot_v4.7.2-stable_win64_console.exe').Source
$zomProject = Split-Path -Parent $PSScriptRoot
$zomSource = Join-Path $zomProject 'src'
$zomRun = Join-Path $PSScriptRoot ('runs/' + [guid]::NewGuid().ToString('N').Substring(0,8))
New-Item -ItemType Directory -Path $zomRun -Force | Out-Null
foreach ($zomTest in @('rules','skills','ui')) {
    & $zomEngine --headless --path $zomSource --script "../qa/${zomTest}_test.gd" --log-file "$zomRun/$zomTest.log" -- "--report=$zomRun/$zomTest.json"
    if ($LASTEXITCODE -ne 0) { throw "Falha em $zomTest; veja $zomRun" }
}
$zomHost = Start-Process -FilePath $zomEngine -WindowStyle Hidden -ArgumentList @('--headless','--path',('"'+$zomSource+'"'),'--script','../qa/network_test.gd','--log-file',('"'+$zomRun+'/host.log"'),'--','--side=host',('"--report='+$zomRun+'/host.json"')) -PassThru
Start-Sleep -Milliseconds 600
$zomClient = Start-Process -FilePath $zomEngine -WindowStyle Hidden -ArgumentList @('--headless','--path',('"'+$zomSource+'"'),'--script','../qa/network_test.gd','--log-file',('"'+$zomRun+'/client.log"'),'--','--side=client',('"--report='+$zomRun+'/client.json"')) -PassThru
foreach ($zomProcess in @($zomHost,$zomClient)) {
    if (!$zomProcess.WaitForExit(24000)) {
        Stop-Process -Id $zomProcess.Id
        throw "Teste de rede excedeu o tempo; veja $zomRun"
    }
}
foreach ($zomSide in @('host','client')) {
    $zomResult = Get-Content -LiteralPath "$zomRun/$zomSide.json" -Raw | ConvertFrom-Json
    if (!$zomResult.ok) { throw "Falha de rede em $zomSide; veja $zomRun" }
}
if ($Render) {
    $zomGpu = Start-Process -FilePath $zomEngine -WindowStyle Hidden -ArgumentList @('--path',('"'+$zomSource+'"'),'--script','../qa/ui_test.gd','--position','16000,16000','--resolution','1440x900','--log-file',('"'+$zomRun+'/gpu.log"'),'--',('"--capture='+$zomRun+'/mesa.png"'),('"--report='+$zomRun+'/gpu.json"')) -PassThru
    if (!$zomGpu.WaitForExit(20000)) {
        Stop-Process -Id $zomGpu.Id
        throw 'Captura excedeu o tempo.'
    }
    $zomResult = Get-Content -LiteralPath "$zomRun/gpu.json" -Raw | ConvertFrom-Json
    if ($zomResult.failures.Count -ne 0) { throw "Falha de render; veja $zomRun" }
}
Write-Output "Testes concluídos. Evidências: $zomRun"
