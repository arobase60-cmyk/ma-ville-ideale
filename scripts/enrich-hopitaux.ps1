$csvFile = "DS_BPE_2025_data.csv"
$jsonFile = "src\data\municipalities.json"

Write-Host "Chargement de municipalities.json..."

$cities = Get-Content $jsonFile -Raw | ConvertFrom-Json

Write-Host "Communes dans la base :" $cities.Count
Write-Host "Recherche des établissements hospitaliers D101..."

# =====================================
# LECTURE DES HOPITAUX
# =====================================

$hospitalByCode = @{}

Import-Csv -Path $csvFile -Delimiter ";" | ForEach-Object {

    $code = ([string]$_.GEO).Trim().PadLeft(5, "0")
    $facilityType = ([string]$_.FACILITY_TYPE).Trim()
$geoObject = ([string]$_.GEO_OBJECT).Trim()

if (
    $facilityType -ne "D101" -or
    $geoObject -ne "COM"
) {
    return
}

    $value = 0

    if ([int]::TryParse(
        ([string]$_.OBS_VALUE).Trim(),
        [ref]$value
    )) {

        if ($value -gt 0) {
            $hospitalByCode[$code] = $value
        }
    }
}

Write-Host ""
Write-Host "Communes avec établissement D101 :" $hospitalByCode.Count

# =====================================
# ENRICHISSEMENT DES COMMUNES
# =====================================

$processed = 0
$withHospital = 0

foreach ($city in $cities) {

    $code = ([string]$city.code).Trim().PadLeft(5, "0")

    if ($null -eq $city.services) {

        $city | Add-Member `
            -MemberType NoteProperty `
            -Name "services" `
            -Value ([PSCustomObject]@{})
    }

    $hospitals = 0

    if ($hospitalByCode.ContainsKey($code)) {
        $hospitals = $hospitalByCode[$code]
        $withHospital++
    }

    if ($city.services.PSObject.Properties.Name -contains "hospitals") {

        $city.services.hospitals = $hospitals

    }
    else {

        $city.services | Add-Member `
            -MemberType NoteProperty `
            -Name "hospitals" `
            -Value $hospitals
    }

    $processed++
}

# =====================================
# SAUVEGARDE
# =====================================

Write-Host ""
Write-Host "Communes traitees :" $processed
Write-Host "Communes avec hopital :" $withHospital

Copy-Item $jsonFile "$jsonFile.bak" -Force

$cities |
    ConvertTo-Json -Depth 10 |
    Set-Content $jsonFile -Encoding UTF8

Write-Host ""
Write-Host "====================================="
Write-Host "HOPITAUX TERMINE"
Write-Host "====================================="
Write-Host "Communes traitees :" $processed
Write-Host "Communes avec hopital :" $withHospital