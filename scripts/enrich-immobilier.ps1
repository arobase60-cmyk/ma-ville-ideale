$csvFile = "stats_whole_period.csv"
$jsonFile = "src\data\municipalities.json"

Write-Host "Chargement de municipalities.json..."

$cities = Get-Content $jsonFile -Raw | ConvertFrom-Json

# Dictionnaire des communes
$cityByCode = @{}

foreach ($city in $cities) {
    $code = ([string]$city.code).Trim().PadLeft(5, "0")
    $cityByCode[$code] = $city
}

Write-Host "Communes dans la base :" $cityByCode.Count
Write-Host "Lecture du fichier DVF..."

$rows = Import-Csv -Path $csvFile

$matched = 0

foreach ($row in $rows) {

    # On garde uniquement les communes
    if ($row.echelle_geo -ne "commune") {
        continue
    }

    $code = ([string]$row.code_geo).Trim()

   # Départements à traiter
$departementsCibles = @("57", "67", "68", "2A", "2B")

if (-not ($departementsCibles | Where-Object { $code.StartsWith($_) })) {
    continue
}


    if (-not $cityByCode.ContainsKey($code)) {
        continue
    }

    $city = $cityByCode[$code]

    # Nombre de ventes de maisons
    $salesText = $row.nb_ventes_whole_maison

    $sales = 0

    if (-not [int]::TryParse($salesText, [ref]$sales)) {
        $sales = 0
    }

    # Prix médian maison / m²
    $priceText = $row.med_prix_m2_whole_maison

    $price = $null

    if (-not [string]::IsNullOrWhiteSpace($priceText)) {

        $priceNumber = 0

        if ([double]::TryParse(
            $priceText,
            [Globalization.NumberStyles]::Any,
            [Globalization.CultureInfo]::InvariantCulture,
            [ref]$priceNumber
        )) {
            $price = [math]::Round($priceNumber)
        }
    }

    # Créer l'objet immobilier s'il n'existe pas
    if (-not $city.PSObject.Properties["immobilier"]) {

        $city | Add-Member `
            -MemberType NoteProperty `
            -Name "immobilier" `
            -Value ([PSCustomObject]@{
                housePriceM2 = $null
                houseSales = 0
            })
    }

    $city.immobilier.housePriceM2 = $price
    $city.immobilier.houseSales = $sales

    $matched++
}

Write-Host ""
Write-Host "Communes enrichies :" $matched

# Sauvegarde
Copy-Item $jsonFile "$jsonFile.bak" -Force

$cities |
    ConvertTo-Json -Depth 10 |
    Set-Content $jsonFile -Encoding UTF8

Write-Host ""
Write-Host "====================================="
Write-Host "IMMOBILIER TERMINE"
Write-Host "====================================="
Write-Host "Communes enrichies :" $matched