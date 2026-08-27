$jsonFile = "src\data\municipalities.json"

Write-Host "Chargement de municipalities.json..."

$cities = Get-Content $jsonFile -Raw | ConvertFrom-Json

# Codes déjà présents
$existingCodes = @{}

foreach ($city in $cities) {
    $code = ([string]$city.code).Trim().PadLeft(5, "0")
    $existingCodes[$code] = $true
}

Write-Host "Communes existantes :" $cities.Count

# Récupération des communes 

Write-Host "Chargement des communes .."

$url = "https://geo.api.gouv.fr/departements/78/communes?fields=nom,code,population,centre&format=json"

$communes = Invoke-RestMethod -Uri $url

Write-Host "Communes trouvées  :" $communes.Count

$added = 0

foreach ($commune in $communes) {

    $code = ([string]$commune.code).Trim().PadLeft(5, "0")

    # Ne pas toucher à une commune déjà présente
    if ($existingCodes.ContainsKey($code)) {
        continue
    }

    $lat = $null
    $lng = $null

    if ($commune.centre -and $commune.centre.coordinates) {
        $lng = $commune.centre.coordinates[0]
        $lat = $commune.centre.coordinates[1]
    }

    $newCity = [PSCustomObject]@{
        id = $code
        code = $code
        slug = $code

        name = $commune.nom

        region = "yvelines, France"
        regionCode = ""
        departmentCode = "78"

        population = if ($commune.population) {
            $commune.population
        } else {
            0
        }

        lat = $lat
        lng = $lng

        immobilier = [PSCustomObject]@{
            housePriceM2 = $null
            houseSales = 0
        }

        priceSqm = $null

        sunHours = $null

        distanceSeaKm = $null

        services = [PSCustomObject]@{
            supermarkets = $null
            grocery = $null
            bakeries = $null
            doctors = $null
            dentists = $null
            pharmacies = $null
        }

        scores = [PSCustomObject]@{}

        risks = [PSCustomObject]@{
            floodCatNat = $null
            floodCatNat10Years = $null
            lastFloodCatNat = $null
        }

        security = [PSCustomObject]@{
            score = $null
            burglaryRate = $null
        }
    }

    $cities += $newCity
    $existingCodes[$code] = $true
    $added++
}

Write-Host ""
Write-Host "Communes ajoutées :" $added
Write-Host "Total communes :" $cities.Count

# Sauvegarde de sécurité
Copy-Item $jsonFile "$jsonFile.bak" -Force

$cities |
    ConvertTo-Json -Depth 10 |
    Set-Content $jsonFile -Encoding UTF8

Write-Host ""
Write-Host "====================================="
Write-Host "AJOUT  TERMINE"
Write-Host "====================================="
Write-Host "Communes ajoutées :" $added
Write-Host "Total :" $cities.Count