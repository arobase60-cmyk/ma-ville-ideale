$departementsFolder = ".\public\data\departements"
$immobilierFolder = ".\public\data\immobilier"

Write-Host "====================================="
Write-Host "INJECTION DES DONNEES IMMOBILIER"
Write-Host "====================================="
Write-Host ""

$totalCommunes = 0
$totalPrix = 0
$totalSansPrix = 0
$totalFichiers = 0

$files = Get-ChildItem "$departementsFolder\*.json"

foreach ($file in $files) {

    $department = $file.BaseName
    $immobilierFile = Join-Path $immobilierFolder "$department.json"

    Write-Host "Traitement :" $department

    if (-not (Test-Path $immobilierFile)) {
        Write-Host "  Fichier immobilier absent"
        continue
    }

    try {

        # Chargement des communes
        $cities = Get-Content $file.FullName -Raw -Encoding UTF8 |
            ConvertFrom-Json

        # Chargement immobilier
        $immobilier = Get-Content $immobilierFile -Raw -Encoding UTF8 |
            ConvertFrom-Json

        # Index par code INSEE
        $immobilierByCode = @{}

        foreach ($item in $immobilier) {

            $code = ([string]$item.code).Trim().PadLeft(5, "0")

            $immobilierByCode[$code] = $item
        }

        $prixCount = 0

        foreach ($city in $cities) {

            $code = ([string]$city.code).Trim().PadLeft(5, "0")

            if ($immobilierByCode.ContainsKey($code)) {

                $data = $immobilierByCode[$code]

                # Création de l'objet immobilier s'il n'existe pas
                if ($null -eq $city.immobilier) {
                    $city.immobilier = [PSCustomObject]@{
                        housePriceM2 = $null
                        houseSales = 0
                    }
                }

                # Injection des données
                $city.immobilier.housePriceM2 = $data.housePriceM2
                $city.immobilier.houseSales = $data.houseSales

                # Le site utilise également priceSqm
                $city.priceSqm = $data.housePriceM2

                if ($null -ne $data.housePriceM2) {
                    $prixCount++
                    $totalPrix++
                }
            }
            else {
                $totalSansPrix++
            }

            $totalCommunes++
        }

        # Sauvegarde avant modification
        $backupFile = "$($file.FullName).bak"

        if (-not (Test-Path $backupFile)) {
            Copy-Item $file.FullName $backupFile
        }

        # Écriture temporaire
        $tempFile = "$($file.FullName).tmp"

        $json = $cities | ConvertTo-Json -Depth 30

        [System.IO.File]::WriteAllText(
            $tempFile,
            $json,
            [System.Text.UTF8Encoding]::new($false)
        )

        # Remplacement
        Move-Item $tempFile $file.FullName -Force

        Write-Host "  Communes :" $cities.Count
        Write-Host "  Prix renseignes :" $prixCount

        $totalFichiers++

    }
    catch {

        Write-Host "  ERREUR :" $_.Exception.Message
    }
}

Write-Host ""
Write-Host "====================================="
Write-Host "INJECTION TERMINEE"
Write-Host "====================================="
Write-Host "Fichiers traites :" $totalFichiers
Write-Host "Communes traitees :" $totalCommunes
Write-Host "Prix renseignes :" $totalPrix
Write-Host "Communes sans correspondance :" $totalSansPrix
Write-Host "====================================="