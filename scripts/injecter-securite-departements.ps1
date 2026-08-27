$projectRoot = Split-Path $PSScriptRoot -Parent

$csvFile = Join-Path $projectRoot "donnee-data.gouv-2025-geographie2026-produit-le2026-06-25.csv"
$departementsFolder = Join-Path $projectRoot "public\data\departements"

Write-Host "====================================="
Write-Host "SECURITE - TOUS LES DEPARTEMENTS"
Write-Host "====================================="
Write-Host ""

if (-not (Test-Path $csvFile)) {
    Write-Host "ERREUR : fichier CSV introuvable"
    exit 1
}

if (-not (Test-Path $departementsFolder)) {
    Write-Host "ERREUR : dossier departements introuvable"
    exit 1
}

# ==================================================
# BAREME SECURITE
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
# LECTURE DU CSV
# ==================================================

Write-Host "Lecture du fichier SSMSI..."

$securityByCode = @{}

Get-Content $csvFile -Encoding UTF8 | ForEach-Object {

    $line = $_

    if ($line -match '^"\d{5}";"2025";"Cambriolages de logement";') {

        $parts = $line -split '";"'

        if ($parts.Count -lt 7) {
            return
        }

        $code = $parts[0].Trim('"')
        $nombreText = $parts[4].Trim('"')
        $tauxText = $parts[5].Trim('"')
        $diffusion = $parts[6].Trim('"')

        # Donnee non diffusee
        if ($diffusion -ne "diff") {
            return
        }

        # ------------------------------
        # TAUX
        # ------------------------------

        $rate = $null

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

        # ------------------------------
        # NOMBRE DE CAMBRIOLAGES
        # ------------------------------

        $count = $null

        if ($nombreText -ne "NA") {

            $countNumber = 0

            if ([int]::TryParse(
                $nombreText,
                [ref]$countNumber
            )) {
                $count = $countNumber
            }
        }

        # ------------------------------
        # ON CONSERVE UNIQUEMENT
        # LES TAUX DISPONIBLES
        # ------------------------------

        if ($null -ne $rate) {

            $securityByCode[$code] = [PSCustomObject]@{
                score = Get-BurglaryScore $rate
                burglaryRate = $rate
                burglaryCount = $count
            }
        }
    }
}

Write-Host ""
Write-Host "===== DONNEES DISPONIBLES ====="
Write-Host "Communes avec securite :" $securityByCode.Count
Write-Host ""

# ==================================================
# TRAITEMENT DES DEPARTEMENTS
# ==================================================

$totalFiles = 0
$totalCities = 0
$totalSecurity = 0

$files = Get-ChildItem "$departementsFolder\*.json"

foreach ($file in $files) {

    $department = $file.BaseName

    try {

        $cities = Get-Content $file.FullName -Raw -Encoding UTF8 |
            ConvertFrom-Json

        $departmentSecurity = 0

        foreach ($city in $cities) {

            $code = ([string]$city.code).Trim().PadLeft(5, "0")

            if ($securityByCode.ContainsKey($code)) {

                $data = $securityByCode[$code]

                $city.security = [PSCustomObject]@{
                    score = $data.score
                    burglaryRate = $data.burglaryRate
                    burglaryCount = $data.burglaryCount
                }

                $departmentSecurity++
                $totalSecurity++
            }
        }

        # Sauvegarde
        $backupFile = "$($file.FullName).bak"

        if (-not (Test-Path $backupFile)) {
            Copy-Item $file.FullName $backupFile
        }

        # Ecriture temporaire
        $tempFile = "$($file.FullName).tmp"

        $json = $cities | ConvertTo-Json -Depth 30

        [System.IO.File]::WriteAllText(
            $tempFile,
            $json,
            [System.Text.UTF8Encoding]::new($false)
        )

        Move-Item $tempFile $file.FullName -Force

        Write-Host "$department : $($cities.Count) communes - securite : $departmentSecurity"

        $totalFiles++
        $totalCities += $cities.Count

    }
    catch {

        Write-Host "$department : ERREUR :" $_.Exception.Message
    }
}

Write-Host ""
Write-Host "====================================="
Write-Host "SECURITE TERMINEE"
Write-Host "====================================="
Write-Host "Fichiers traites :" $totalFiles
Write-Host "Communes traitees :" $totalCities
Write-Host "Securites renseignees :" $totalSecurity
Write-Host "====================================="