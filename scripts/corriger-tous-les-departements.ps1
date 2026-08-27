$projectRoot = Split-Path $PSScriptRoot -Parent

$folder = Join-Path $projectRoot "public\data\departements"

$departments = @(
    "01","02","03","04","05","06","07","08","09",
    "10","11","12","13","14","15","16","17","18","19",
    "21","22","23","24","25","26","27","28","29",
    "2A","2B",
    "30","31","32","33","34","35","36","37","38","39",
    "40","41","42","43","44","45","46","47","48","49",
    "50","51","52","53","54","55","56","57","58","59",
    "60","61","62","63","64","65","66","67","68","69",
    "70","71","72","73","74","75","76","77","78","79",
    "80","81","82","83","84","85","86","87","88","89",
    "90","91","92","93","94","95"
)

Write-Host "====================================="
Write-Host "CORRECTION DES DEPARTEMENTS"
Write-Host "====================================="
Write-Host ""
Write-Host "Dossier :" $folder
Write-Host ""

$total = 0
$files = 0

foreach ($department in $departments) {

    $file = Join-Path $folder "$department.json"

    if (-not (Test-Path $file)) {
        Write-Host "$department : fichier absent"
        continue
    }

    Write-Host "Traitement du departement $department ..."

    try {

        $apiUrl = "https://geo.api.gouv.fr/departements/$department/communes?fields=nom,code,population,centre,codesPostaux&format=json"

        $apiCommunes = Invoke-RestMethod -Uri $apiUrl -TimeoutSec 30

        $apiByCode = @{}

        foreach ($commune in $apiCommunes) {
            $apiByCode[[string]$commune.code] = $commune
        }

        # Lecture du fichier existant
        $existing = Get-Content $file -Raw -Encoding UTF8 | ConvertFrom-Json

        $corrected = 0

        foreach ($city in $existing) {

            $code = [string]$city.code

            if ($apiByCode.ContainsKey($code)) {

                $apiCity = $apiByCode[$code]

                # On corrige uniquement ces informations
                $city.name = $apiCity.nom
                $city.population = $apiCity.population

                if ($null -ne $apiCity.centre) {
                    if ($null -ne $apiCity.centre.coordinates) {
                        $city.lng = $apiCity.centre.coordinates[0]
                        $city.lat = $apiCity.centre.coordinates[1]
                    }
                }

                

                $corrected++
            }
        }

        # Ecriture temporaire
        $tempFile = "$file.tmp"

        $json = $existing | ConvertTo-Json -Depth 20

        [System.IO.File]::WriteAllText(
            $tempFile,
            $json,
            [System.Text.UTF8Encoding]::new($false)
        )

        # Remplacement du fichier
        Move-Item $tempFile $file -Force

        Write-Host "  Communes corrigees :" $corrected

        $total += $corrected
        $files++

    }
    catch {

        Write-Host "  ERREUR :" $_.Exception.Message
    }
}

Write-Host ""
Write-Host "====================================="
Write-Host "CORRECTION TERMINEE"
Write-Host "====================================="
Write-Host "Fichiers traites :" $files
Write-Host "Communes corrigees :" $total
Write-Host ""