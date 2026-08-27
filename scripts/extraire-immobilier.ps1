$jsonFile = "src\data\municipalities.json"
$outputFile = "src\data\immobilier.json"

Write-Host "Chargement de municipalities.json..."

$cities = Get-Content $jsonFile -Raw | ConvertFrom-Json

$immobilier = [ordered]@{}

foreach ($city in $cities) {

    $code = ([string]$city.code).Trim().ToUpper()

    if (-not $code) {
        continue
    }

    $immobilier[$code] = [ordered]@{
        housePriceM2 = $city.immobilier.housePriceM2
        houseSales   = $city.immobilier.houseSales
    }
}

Write-Host ""
Write-Host "Communes traitées :" $immobilier.Count

$immobilier |
    ConvertTo-Json -Depth 5 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "====================================="
Write-Host "EXTRACTION IMMOBILIER TERMINEE"
Write-Host "====================================="
Write-Host "Fichier créé :" $outputFile
Write-Host "Communes :" $immobilier.Count