[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$zomEngineCommand = Get-Command 'Godot_v4.7.2-stable_win64.exe' -ErrorAction SilentlyContinue
if (!$zomEngineCommand) { $zomEngineCommand = Get-Command 'godot' -ErrorAction SilentlyContinue }
if (!$zomEngineCommand) { throw 'Abra src/project.godot no Godot 4.7.2. Executável não encontrado no PATH.' }
Start-Process -FilePath $zomEngineCommand.Source -WindowStyle Hidden -ArgumentList @('--path', ('"' + (Join-Path $PSScriptRoot 'src') + '"'))
