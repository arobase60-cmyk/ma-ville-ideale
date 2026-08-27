$csvFile = "donnee-data.gouv-2025-geographie2026-produit-le2026-06-25.csv"
$jsonFile = "src\data\municipalities.json"

Write-Host "Chargement de municipalities.json..."

$cities = Get-Content $jsonFile -Raw | ConvertFrom-Json

$cityByCode = @{}

foreach ($city in $cities) {
    $code = ([string]$city.code).Trim().PadLeft(5, "0")
    $cityByCode[$code] = $city
}

Write-Host "Communes dans la base :" $cityByCode.Count
Write-Host "Lecture du fichier sécurité..."

$matched = 0

Get-Content $csvFile | ForEach-Object {

    $line = $_

    if ($line -match  '^"\d{5}";"2025";"Cambriolages de logement";'){
        $parts = $line -split '";"'

        if ($parts.Count -lt 7) {
            return
        }

        $code = $parts[0].Trim('"')
        $nombreText = $parts[4].Trim('"')
        $tauxText = $parts[5].Trim('"')
        $diffusion = $parts[6].Trim('"')

        if (-not $cityByCode.ContainsKey($code)) {
            return
        }

        $city = $cityByCode[$code]

        $rate = $null
        $count = $null

        # On ne conserve les données que lorsqu'elles sont effectivement diffusées
        if ($diffusion -eq "diff") {

            if ($nombreText -ne "NA") {
                $countNumber = 0

                if ([int]::TryParse(
                    $nombreText,
                    [ref]$countNumber
                )) {
                    $count = $countNumber
                }
            }

            if ($tauxText -ne "NA") {

                $rateText = $tauxText.Replace(",", ".")
                $rateNumber = 0

                if ([double]::TryParse(
                    $rateText,
                    [Globalization.NumberStyles]::Any,
                    [Globalization.CultureInfo]::InvariantCulture,
                    [ref]$rateNumber
                )) {
                    $rate = $rateNumber
                }
            }
        }

        $securityObject = [PSCustomObject]@{
    score = if ($city.security) { $city.security.score } else { $null }
    burglaryRate = $rate
    burglaryCount = $count
}

$city.security = $securityObject

        $matched++
    }
}

Write-Host ""
Write-Host "Communes enrichies :" $matched

Copy-Item $jsonFile "$jsonFile.bak" -Force

$cities |
    ConvertTo-Json -Depth 10 |
    Set-Content $jsonFile -Encoding UTF8

Write-Host ""
Write-Host "====================================="
Write-Host "SECURITE TERMINE"
Write-Host "====================================="
Write-Host "Communes enrichies :" $matched