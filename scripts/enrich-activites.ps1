$csvFile = "DS_BPE_2025_data.csv"
$jsonFile = "src\data\municipalities.json"

Write-Host "Chargement de municipalities.json..."

$cities = Get-Content $jsonFile -Raw | ConvertFrom-Json

Write-Host "Communes dans la base :" $cities.Count
Write-Host "Lecture des équipements sportifs et culturels..."

# =====================================
# CODES BPE
# =====================================

$activityCodes = @{
    swimmingPool = "F101"
    stadium      = "F113"
    tennis       = "F103"
    gymnasium    = "F121"
    golf         = "F108"

    theatre      = "F315"
    cinema       = "F303"
    cultural     = "F312"
    library      = "F307"
    conservatory = "F305"
}

# =====================================
# LECTURE DE LA BPE
# =====================================

$activitiesByCode = @{}

Import-Csv -Path $csvFile -Delimiter ";" | ForEach-Object {

    $code = ([string]$_.GEO).Trim().PadLeft(5, "0")
    $facilityType = ([string]$_.FACILITY_TYPE).Trim()

    
$geoObject = ([string]$_.GEO_OBJECT).Trim()

if (
    $activityCodes.Values -notcontains $facilityType -or
    $geoObject -ne "COM"
) {
    return
}
    $value = 0

    if ([int]::TryParse(
        ([string]$_.OBS_VALUE).Trim(),
        [ref]$value
    )) {

        if (-not $activitiesByCode.ContainsKey($code)) {
            $activitiesByCode[$code] = @{}
        }

        $propertyName = ($activityCodes.GetEnumerator() |
            Where-Object { $_.Value -eq $facilityType } |
            Select-Object -First 1).Key

        $activitiesByCode[$code][$propertyName] = $value
    }
}

Write-Host ""
Write-Host "Communes avec activités :" $activitiesByCode.Count

# =====================================
# ENRICHISSEMENT
# =====================================

$processed = 0
$withActivities = 0

foreach ($city in $cities) {

    $code = ([string]$city.code).Trim().PadLeft(5, "0")

    $activities = [ordered]@{
        swimmingPool = 0
        stadium      = 0
        tennis       = 0
        gymnasium    = 0
        golf         = 0

        theatre      = 0
        cinema       = 0
        cultural     = 0
        library      = 0
        conservatory = 0
    }

    if ($activitiesByCode.ContainsKey($code)) {

        foreach ($property in $activitiesByCode[$code].Keys) {
            $activities[$property] =
                $activitiesByCode[$code][$property]
        }

        $withActivities++
    }

    if ($null -eq $city.services) {

        $city | Add-Member `
            -MemberType NoteProperty `
            -Name "services" `
            -Value ([PSCustomObject]@{})
    }

    if ($city.services.PSObject.Properties.Name -contains "activities") {

        $city.services.activities = [PSCustomObject]$activities

    } else {

        $city.services | Add-Member `
            -MemberType NoteProperty `
            -Name "activities" `
            -Value ([PSCustomObject]$activities)
    }

    $processed++
}

# =====================================
# SAUVEGARDE
# =====================================

Write-Host ""
Write-Host "Communes traitees :" $processed
Write-Host "Communes avec activites :" $withActivities

Copy-Item $jsonFile "$jsonFile.bak" -Force

$cities |
    ConvertTo-Json -Depth 10 |
    Set-Content $jsonFile -Encoding UTF8

Write-Host ""
Write-Host "====================================="
Write-Host "ACTIVITES TERMINE"
Write-Host "====================================="
Write-Host "Communes traitees :" $processed
Write-Host "Communes avec activites :" $withActivities