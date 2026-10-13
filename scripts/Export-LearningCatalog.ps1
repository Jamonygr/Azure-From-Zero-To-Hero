[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$catalogPath = Join-Path $PSScriptRoot '..\curriculum\lessons.psd1'
$catalog = Import-PowerShellDataFile -Path $catalogPath
$catalog | ConvertTo-Json -Depth 10
