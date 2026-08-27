$jsonFile = "src\data\municipalities.json"
$backupFile = "src\data\municipalities.json.bak-66"
$department = "66"

Write-Host "====================================="
Write-Host "CORRECTION DES COMMUNES DU 66"
Write-Host "====================================="
Write-Host ""

# =====================================
# CHARGEMENT
# =====================================

Write-Host "Chargement de municipalities.json..."

$cities = Get-Content $jsonFile -Raw -Encoding UTF8 | ConvertFrom-Json

Write-Host "Communes dans la base :" $cities.Count
Write-Host ""

# =====================================
# SAUVEGARDE
# =====================================

Copy-Item $jsonFile $backupFile -Force

Write-Host "Sauvegarde creee :" $backupFile
Write-Host ""

# =====================================
# API DU 66
# =====================================

Write-Host "Chargement des communes officielles du 66..."

$url = "https://geo.api.gouv.fr/departements/66/communes?fields=nom,code,population,centre&format=json"

$communes = Invoke-RestMethod -Uri $url

Write-Host "Communes API :" $communes.Count
Write-Host ""

# =====================================
# DICTIONNAIRE API
# =====================================

$apiByCode = @{}

foreach ($commune in $communes) {

    $code = ([string]$commune.code).Trim()

    $apiByCode[$code] = $commune
}

# =====================================
# CORRECTION
# =====================================

$corrected = 0

foreach ($city in $cities) {

    $code = ([string]$city.code).Trim()

    if (-not $code.StartsWith("66")) {
        continue
    }

    if (-not $apiByCode.ContainsKey($code)) {
        continue
    }

    $apiCity = $apiByCode[$code]

    # Nom officiel
    $city.name = $apiCity.nom

    # Population
    if ($null -ne $apiCity.population) {
        $city.population = $apiCity.population
    }

    # Coordonnees
    if ($apiCity.centre -and $apiCity.centre.coordinates) {

        $city.lng = $apiCity.centre.coordinates[0]
        $city.lat = $apiCity.centre.coordinates[1]
    }

    $corrected++
}

Write-Host "Communes corrigees :" $corrected
Write-Host ""

# =====================================
# SAUVEGARDE
# =====================================

$cities |
    ConvertTo-Json -Depth 20 |
    Set-Content $jsonFile -Encoding UTF8

Write-Host "municipalities.json sauvegarde."
Write-Host ""

# =====================================
# RECREATION DU 66
# =====================================

Write-Host "Recreation de public\data\departements\66.json..."

$departmentCities = @(
    $cities | Where-Object {
        ([string]$_.code).Trim().StartsWith("66")
    }
)

$departmentFile = "public\data\departements\66.json"

$departmentCities |
    ConvertTo-Json -Depth 20 |
    Set-Content $departmentFile -Encoding UTF8

Write-Host "Fichier 66 recree :" $departmentFile
Write-Host "Communes dans le 66 :" $departmentCities.Count
Write-Host ""

Write-Host "====================================="
Write-Host "CORRECTION DU 66 TERMINEE"
Write-Host "====================================="