$jsonFile = "src\data\municipalities.json"
$outputDir = "public\data\departements"

Write-Host "====================================="
Write-Host "DECOUPAGE DES COMMUNES PAR DEPARTEMENT"
Write-Host "====================================="
Write-Host ""

# =====================================
# CHARGEMENT
# =====================================

Write-Host "Chargement de municipalities.json..."

$cities = Get-Content $jsonFile -Raw | ConvertFrom-Json

Write-Host "Communes chargees :" $cities.Count
Write-Host ""

# =====================================
# CREATION DU DOSSIER
# =====================================

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# =====================================
# GROUPEMENT PAR DEPARTEMENT
# =====================================

$departments = @{}

foreach ($city in $cities) {

    $code = ([string]$city.code).Trim()

    if ([string]::IsNullOrWhiteSpace($code)) {
        continue
    }

    # Corse
    if ($code.StartsWith("2A")) {
        $department = "2A"
    }
    elseif ($code.StartsWith("2B")) {
        $department = "2B"
    }
    else {
        if ($code.Length -lt 2) {
            continue
        }

        $department = $code.Substring(0, 2)
    }

    if (-not $departments.ContainsKey($department)) {
        $departments[$department] = @()
    }

    $departments[$department] += $city
}

# =====================================
# CREATION DES FICHIERS
# =====================================

$created = 0
$totalExported = 0

foreach ($department in ($departments.Keys | Sort-Object)) {

    $departmentCities = $departments[$department]

    $outputFile = Join-Path $outputDir "$department.json"

    $departmentCities |
        ConvertTo-Json -Depth 10 |
        Set-Content $outputFile -Encoding UTF8

    Write-Host (
        "{0} : {1} communes" -f
        $department,
        $departmentCities.Count
    )

    $created++
    $totalExported += $departmentCities.Count
}

# =====================================
# CONTROLE
# =====================================

Write-Host ""
Write-Host "====================================="
Write-Host "DECOUPAGE TERMINE"
Write-Host "====================================="
Write-Host "Fichiers crees :" $created
Write-Host "Communes exportees :" $totalExported
Write-Host "Communes source :" $cities.Count
Write-Host ""
Write-Host "Dossier :" $outputDir