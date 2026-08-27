$csvFile = "irradiation-par-commune-10-2025.csv"
$jsonFile = "src\data\municipalities.json"

Write-Host "Chargement de municipalities.json..."

$cities = Get-Content $jsonFile -Raw | ConvertFrom-Json

Write-Host "Communes dans la base :" $cities.Count
Write-Host "Lecture du fichier ensoleillement..."

$rows = Import-Csv -Path $csvFile -Delimiter ","

# =====================================
# CALCUL DES MOYENNES PAR DEPARTEMENT
# =====================================

$departmentValues = @{}

foreach ($row in $rows) {
    $department = ([string]$row.code_departement).Trim()

# Normalisation des codes départementaux
if ($department -match '^\d$') {
    $department = $department.PadLeft(2, "0")
}
    if ([string]::IsNullOrWhiteSpace($department)) {
        continue
    }

    $sunText = ([string]$row.ensoleillement_annuel).Trim()

    if ([string]::IsNullOrWhiteSpace($sunText)) {
        continue
    }

    $sunNumber = 0

    if ([double]::TryParse(
        $sunText,
        [Globalization.NumberStyles]::Any,
        [Globalization.CultureInfo]::InvariantCulture,
        [ref]$sunNumber
    )) {

        if (-not $departmentValues.ContainsKey($department)) {
            $departmentValues[$department] = @()
        }

        $departmentValues[$department] += $sunNumber
    }
}

Write-Host ""
Write-Host "Moyennes d'ensoleillement par departement :"
Write-Host ""

$departmentAverages = @{}

foreach ($department in $departmentValues.Keys) {

    $values = $departmentValues[$department]

    $average = [math]::Round(
        ($values | Measure-Object -Average).Average
    )

    $departmentAverages[$department] = $average

    Write-Host (
        "{0} : {1} h/an ({2} communes)" -f
        $department,
        $average,
        $values.Count
    )
}



# =====================================
# ENRICHISSEMENT DES COMMUNES
# =====================================

$matched = 0
$withoutDepartmentData = 0

foreach ($city in $cities) {

    $code = ([string]$city.code).Trim().PadLeft(5, "0")

    if ($code.Length -ne 5) {
        continue
    }

    $department = $code.Substring(0, 2)

    # Cas particulier Corse
    if ($code.StartsWith("2A")) {
        $department = "2A"
    }
    elseif ($code.StartsWith("2B")) {
        $department = "2B"
    }

    if ($departmentAverages.ContainsKey($department)) {

        $sunHours = $departmentAverages[$department]

        $city.sunHours = $sunHours

        $matched++
    }
    else {

        $city.sunHours = $null

        $withoutDepartmentData++
    }
}




# =====================================
# SAUVEGARDE
# =====================================

Write-Host ""
Write-Host "Communes enrichies :" $matched
Write-Host "Communes sans donnée départementale :" $withoutDepartmentData

Copy-Item $jsonFile "$jsonFile.bak" -Force

$cities |
    ConvertTo-Json -Depth 10 |
    Set-Content $jsonFile -Encoding UTF8

Write-Host ""
Write-Host "====================================="
Write-Host "ENSOLEILLEMENT TERMINE"
Write-Host "====================================="
Write-Host "Communes enrichies :" $matched
Write-Host "Communes sans donnée départementale :" $withoutDepartmentData