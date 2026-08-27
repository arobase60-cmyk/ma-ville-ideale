$jsonFile = ".\src\data\municipalities.json"
$outputFolder = ".\public\data\departements"

Write-Host "Source :" (Resolve-Path $jsonFile)
Write-Host "Destination :" (Resolve-Path $outputFolder)
Write-Host "====================================="
Write-Host "INITIALISATION DES DEPARTEMENTS"
Write-Host "====================================="
Write-Host ""

# Vérification
if (-not (Test-Path $jsonFile)) {
    Write-Host "ERREUR : municipalities.json introuvable"
    exit 1
}

if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
}

# Chargement de la base complète
Write-Host "Chargement de municipalities.json..."

$cities = Get-Content $jsonFile -Raw -Encoding UTF8 |
    ConvertFrom-Json

Write-Host "Communes source :" $cities.Count
Write-Host ""

# Regroupement par département
$groups = @{}

foreach ($city in $cities) {

    $code = ([string]$city.code).Trim().PadLeft(5, "0")

    if ($code.Length -lt 5) {
        continue
    }

    $department = $code.Substring(0, 2)

    # Corse
    if ($code.StartsWith("200")) {
        $department = "2A"
    }
    elseif ($code.StartsWith("201")) {
        $department = "2B"
    }

    if (-not $groups.ContainsKey($department)) {
        $groups[$department] = @()
    }

    $groups[$department] += $city
}

# Écriture des fichiers
$total = 0
$files = 0

foreach ($department in ($groups.Keys | Sort-Object)) {

    $file = Join-Path (Resolve-Path ".\public\data\departements").Path "$department.json"

    $json = $groups[$department] |
        ConvertTo-Json -Depth 30

    [System.IO.File]::WriteAllText(
        $file,
        $json,
        [System.Text.UTF8Encoding]::new($false)
    )

    $count = $groups[$department].Count

    Write-Host "$department : $count communes"

    $total += $count
    $files++
}

Write-Host ""
Write-Host "====================================="
Write-Host "INITIALISATION TERMINEE"
Write-Host "====================================="
Write-Host "Fichiers :" $files
Write-Host "Communes exportees :" $total
Write-Host "====================================="