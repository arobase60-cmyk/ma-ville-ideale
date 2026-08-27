$csvFile = "DS_BPE_2025_data.csv"
$jsonFile = "src\data\municipalities.json"

Write-Host "Chargement de municipalities.json..."

$cities = Get-Content $jsonFile -Raw | ConvertFrom-Json

# On crée un dictionnaire avec les codes INSEE
$cityByCode = @{}

foreach ($city in $cities) {
    $code = ([string]$city.code).Trim()

    # On force le code à être une chaîne de 5 caractères
    $code = $code.PadLeft(5, "0")

    $cityByCode[$code] = $city
}

Write-Host "Communes dans la base :" $cityByCode.Count
Write-Host "Lecture du fichier BPE..."

# Codes BPE qui nous intéressent
$wanted = @{
    "B105" = "supermarkets"
    "B202" = "grocery"
    "B207" = "bakeries"
    "D265" = "doctors"
    "D277" = "dentists"
    "D307" = "pharmacies"
}

$services = @{}

# Lecture du CSV
$rows = Import-Csv -Path $csvFile -Delimiter ';'

Write-Host "Lignes BPE chargées :" $rows.Count

foreach ($row in $rows) {

    # Uniquement les communes
    if ($row.GEO_OBJECT -ne "COM") {
        continue
    }

    # Uniquement nos équipements
    if (-not $wanted.ContainsKey($row.FACILITY_TYPE)) {
        continue
    }

    $code = ([string]$row.GEO).Trim()

    if (-not $cityByCode.ContainsKey($code)) {
        continue
    }

    $property = $wanted[$row.FACILITY_TYPE]

    $value = 0
    [int]::TryParse(
        ([string]$row.OBS_VALUE),
        [ref]$value
    ) | Out-Null

    if (-not $services.ContainsKey($code)) {
        $services[$code] = @{
            supermarkets = 0
            grocery = 0
            bakeries = 0
            doctors = 0
            dentists = 0
            pharmacies = 0
        }
    }

    $services[$code][$property] += $value
}

Write-Host "Communes avec des données BPE :" $services.Count

# Mise à jour
foreach ($code in $services.Keys) {

    $city = $cityByCode[$code]

    $city.services.supermarkets = $services[$code].supermarkets
    $city.services.grocery = $services[$code].grocery
    $city.services.bakeries = $services[$code].bakeries
    $city.services.doctors = $services[$code].doctors
    $city.services.dentists = $services[$code].dentists
    $city.services.pharmacies = $services[$code].pharmacies
}

# Sauvegarde de sécurité
Copy-Item $jsonFile "$jsonFile.bak" -Force

# Réécriture du JSON
$cities | ConvertTo-Json -Depth 10 |
    Set-Content $jsonFile -Encoding UTF8

Write-Host ""
Write-Host "====================================="
Write-Host "ENRICHISSEMENT TERMINE"
Write-Host "====================================="
Write-Host "Communes :" $cityByCode.Count
Write-Host "Communes enrichies :" $services.Count