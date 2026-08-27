$jsonFile = "src\data\immobilier.json"
$outputDir = "public\data\immobilier"

Write-Host "====================================="
Write-Host "DECOUPAGE IMMOBILIER"
Write-Host "====================================="
Write-Host ""

Write-Host "Chargement de immobilier.json..."

$immobilier = Get-Content $jsonFile -Raw | ConvertFrom-Json
$properties = $immobilier.PSObject.Properties

Write-Host "Donnees source :" $properties.Count
Write-Host ""

# Création du dossier
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Groupes par département
$departments = @{}

foreach ($property in $properties) {

    $code = $property.Name.Trim()

    if ($code.Length -lt 2) {
        continue
    }

    # Département
    if ($code.StartsWith("2A")) {
        $department = "2A"
    }
    elseif ($code.StartsWith("2B")) {
        $department = "2B"
    }
    else {
        $department = $code.Substring(0, 2)
    }

    if (-not $departments.ContainsKey($department)) {
        $departments[$department] = @()
    }

    $departments[$department] += [PSCustomObject]@{
        code = $code
        housePriceM2 = $property.Value.housePriceM2
        houseSales = $property.Value.houseSales
    }
}

# Création des fichiers
$created = 0
$total = 0

foreach ($department in ($departments.Keys | Sort-Object)) {

    $data = $departments[$department]

    $file = Join-Path $outputDir "$department.json"

    $data |
        ConvertTo-Json -Depth 10 |
        Set-Content $file -Encoding UTF8

    Write-Host "$department : $($data.Count) communes"

    $created++
    $total += $data.Count
}

Write-Host ""
Write-Host "====================================="
Write-Host "DECOUPAGE IMMOBILIER TERMINE"
Write-Host "====================================="
Write-Host "Fichiers crees :" $created
Write-Host "Donnees exportees :" $total
Write-Host "Donnees source :" $properties.Count
Write-Host ""
Write-Host "Dossier :" $outputDir