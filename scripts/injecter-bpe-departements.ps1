$projectRoot = Split-Path $PSScriptRoot -Parent

$csvFile = Join-Path $projectRoot "DS_BPE_2025_data.csv"
$departementsFolder = Join-Path $projectRoot "public\data\departements"

Write-Host "====================================="
Write-Host "INJECTION BPE - TOUS LES DEPARTEMENTS"
Write-Host "====================================="
Write-Host ""

# ==================================================
# CODES BPE
# ==================================================

$wanted = @{
    "B105" = "supermarkets"
    "B202" = "grocery"
    "B207" = "bakeries"
    "D265" = "doctors"
    "D277" = "dentists"
    "D307" = "pharmacies"
}

# ==================================================
# LECTURE BPE
# ==================================================

Write-Host "Lecture du fichier BPE..."

$servicesByCode = @{}

Import-Csv -Path $csvFile -Delimiter ";" -Encoding UTF8 |
ForEach-Object {

    if ($_.GEO_OBJECT -ne "COM") {
        return
    }

    if (-not $wanted.ContainsKey($_.FACILITY_TYPE)) {
        return
    }

    $code = ([string]$_.GEO).Trim().PadLeft(5, "0")
    $property = $wanted[$_.FACILITY_TYPE]

    $value = 0

    if (-not [int]::TryParse(
        ([string]$_.OBS_VALUE).Trim(),
        [ref]$value
    )) {
        return
    }

    if (-not $servicesByCode.ContainsKey($code)) {
        $servicesByCode[$code] = @{
            supermarkets = 0
            grocery = 0
            bakeries = 0
            doctors = 0
            dentists = 0
            pharmacies = 0
        }
    }

    $servicesByCode[$code][$property] += $value
}

Write-Host ""
Write-Host "Communes avec donnees BPE :" $servicesByCode.Count
Write-Host ""

# ==================================================
# INJECTION DEPARTEMENTS
# ==================================================

$totalFiles = 0
$totalCommunes = 0
$totalEnrichies = 0

foreach ($file in Get-ChildItem "$departementsFolder\*.json") {

    try {

        $cities = Get-Content $file.FullName -Raw -Encoding UTF8 |
            ConvertFrom-Json

        $departmentEnriched = 0

        foreach ($city in $cities) {

            $code = ([string]$city.code).Trim().PadLeft(5, "0")

            if (-not $servicesByCode.ContainsKey($code)) {
                continue
            }

            # Créer services si nécessaire
            if ($null -eq $city.services) {

                $city | Add-Member `
                    -MemberType NoteProperty `
                    -Name "services" `
                    -Value ([PSCustomObject]@{})
            }

            $data = $servicesByCode[$code]

            # ------------------------------
            # COMMERCES
            # ------------------------------

            $city.services.supermarkets = $data.supermarkets
            $city.services.grocery = $data.grocery
            $city.services.bakeries = $data.bakeries

            # ------------------------------
            # SANTE
            # ------------------------------

            $city.services.doctors = $data.doctors
            $city.services.dentists = $data.dentists
            $city.services.pharmacies = $data.pharmacies

            $departmentEnriched++
            $totalEnrichies++
        }

        # Sauvegarde
        $backup = "$($file.FullName).bak"

        if (-not (Test-Path $backup)) {
            Copy-Item $file.FullName $backup
        }

        $json = $cities | ConvertTo-Json -Depth 30

        [System.IO.File]::WriteAllText(
            $file.FullName,
            $json,
            [System.Text.UTF8Encoding]::new($false)
        )

        Write-Host "$($file.BaseName) : $($cities.Count) communes - BPE : $departmentEnriched"

        $totalFiles++
        $totalCommunes += $cities.Count

    }
    catch {

        Write-Host "$($file.BaseName) : ERREUR :" $_.Exception.Message
    }
}

Write-Host ""
Write-Host "====================================="
Write-Host "INJECTION BPE TERMINEE"
Write-Host "====================================="
Write-Host "Fichiers traites :" $totalFiles
Write-Host "Communes traitees :" $totalCommunes
Write-Host "Communes enrichies :" $totalEnrichies
Write-Host "====================================="