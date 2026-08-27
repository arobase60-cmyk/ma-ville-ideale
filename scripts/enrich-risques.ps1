$excelFile = "ONRN_Reco_INON_8224.xlsx"
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

# Ouverture d'Excel
Write-Host "Ouverture du fichier Géorisques..."

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

$wb = $excel.Workbooks.Open(
    (Resolve-Path $excelFile).Path
)

$ws = $wb.Worksheets.Item("Nb reco. Cat Nat")

Write-Host "Lecture des données..."

# Les données commencent à la ligne 3
$row = 3

$matched = 0

while ($true) {

    $code = ([string]$ws.Cells.Item($row, 1).Text).Trim()

    # Fin du tableau
    if ([string]::IsNullOrWhiteSpace($code)) {
        break
    }

    # Nombre de Cat Nat inondation
    $catnatText = $ws.Cells.Item($row, 3).Text

    $catnat = 0

    if (-not [int]::TryParse($catnatText, [ref]$catnat)) {
        $catnat = 0
    }

    if ($cityByCode.ContainsKey($code)) {

        $city = $cityByCode[$code]

        # Création de l'objet risks s'il n'existe pas
        if (-not $city.PSObject.Properties["risks"]) {
            $city | Add-Member -MemberType NoteProperty -Name "risks" -Value ([PSCustomObject]@{
                floodCatNat = 0
            })
        }

        $city.risks.floodCatNat = $catnat

        $matched++
    }

    $row++

    # Affichage de progression tous les 5000 lignes
    if (($row % 5000) -eq 0) {
        Write-Host "Lignes traitées :" $row
    }
}

Write-Host ""
Write-Host "Communes enrichies :" $matched

# Fermeture Excel
$wb.Close($false)
$excel.Quit()

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($ws) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($wb) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null

# Sauvegarde
Copy-Item $jsonFile "$jsonFile.bak" -Force

$cities | ConvertTo-Json -Depth 10 |
    Set-Content $jsonFile -Encoding UTF8

Write-Host ""
Write-Host "====================================="
Write-Host "RISQUES TERMINE"
Write-Host "====================================="
Write-Host "Communes enrichies :" $matched