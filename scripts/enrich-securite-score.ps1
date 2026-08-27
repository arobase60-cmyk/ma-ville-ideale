$csvFile = "donnee-data.gouv-2025-geographie2026-produit-le2026-06-25.csv"
$jsonFile = "src\data\municipalities.json"

Write-Host "Chargement de municipalities.json..."

$cities = Get-Content $jsonFile -Raw | ConvertFrom-Json

$cityByCode = @{}

foreach ($city in $cities) {
    $code = ([string]$city.code).Trim().PadLeft(5, "0")
    $cityByCode[$code] = $city
}

Write-Host "Communes :" $cityByCode.Count
Write-Host "Lecture du fichier SSMSI..."

# ==================================================
# TAUX DE CAMBRIOLAGES
# ==================================================

$burglaryRates = @{}

Get-Content $csvFile -Encoding UTF8 | ForEach-Object {

    $line = $_

    if ($line -match '^"\d{5}";"2025";') {

        $parts = $line -split '";"'

        if ($parts.Count -lt 7) {
            return
        }

        $code = $parts[0].Trim('"')
        $indicator = $parts[2].Trim('"')
        $rateText = $parts[5].Trim('"')
        $diffusion = $parts[6].Trim('"')

        # On ne garde que les cambriolages
        if ($indicator -ne "Cambriolages de logement") {
            return
        }

        if (-not $cityByCode.ContainsKey($code)) {
            return
        }

        # Donnée non diffusée
        if ($diffusion -ne "diff") {
            return
        }

        # Taux non disponible
        if ($rateText -eq "NA") {
            return
        }

        $rateText = $rateText.Replace(",", ".")

        $rate = 0

        if ([double]::TryParse(
            $rateText,
            [Globalization.NumberStyles]::Any,
            [Globalization.CultureInfo]::InvariantCulture,
            [ref]$rate
        )) {

            $burglaryRates[$code] = $rate
        }
    }
}

Write-Host ""
Write-Host "===== DONNEES DISPONIBLES ====="
Write-Host "Cambriolages :" $burglaryRates.Count "communes"

# ==================================================
# BAREME
# ==================================================

function Get-BurglaryScore {
    param(
        [double]$rate
    )

    if ($rate -eq 0) { return 8 }
    if ($rate -le 1) { return 7.5 }
    if ($rate -le 2) { return 7 }
    if ($rate -le 3) { return 6.5 }
    if ($rate -le 4) { return 6 }
    if ($rate -le 5) { return 5 }
    if ($rate -le 7) { return 4 }
    if ($rate -le 10) { return 2.5 }

    return 1
}

# ==================================================
# CALCUL DES SCORES
# ==================================================

Write-Host ""
Write-Host "Calcul des scores..."

$matched = 0

foreach ($city in $cities) {

    $code = ([string]$city.code).Trim().PadLeft(5, "0")

    # ----------------------------------------------
    # DONNEE DISPONIBLE
    # ----------------------------------------------

    if ($burglaryRates.ContainsKey($code)) {

        $burglaryRate = $burglaryRates[$code]

        $securityScore =
            Get-BurglaryScore $burglaryRate

    }
    else {

        # Aucune donnée disponible
        $burglaryRate = $null
        $securityScore = $null
    }

    # ----------------------------------------------
    # OBJET SECURITY
    # ----------------------------------------------

    $securityObject = [PSCustomObject]@{
        score = $securityScore
        burglaryRate = $burglaryRate
    }

    if ($city.PSObject.Properties["security"]) {

        $city.security = $securityObject
    }
    else {

        $city |
            Add-Member `
                -MemberType NoteProperty `
                -Name "security" `
                -Value $securityObject
    }

    $matched++
}

# ==================================================
# SAUVEGARDE
# ==================================================

Write-Host ""
Write-Host "Communes traitees :" $matched

Copy-Item $jsonFile "$jsonFile.bak" -Force

$cities |
    ConvertTo-Json -Depth 15 |
    Set-Content $jsonFile -Encoding UTF8

Write-Host ""
Write-Host "====================================="
Write-Host "SCORE SECURITE TERMINE"
Write-Host "====================================="
Write-Host "Communes :" $matched