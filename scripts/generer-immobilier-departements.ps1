$projectRoot = Split-Path $PSScriptRoot -Parent

$csvFile = Join-Path $projectRoot "stats_whole_period.csv"
$outputFolder = Join-Path $projectRoot "public\data\immobilier"
Write-Host "Source :" (Resolve-Path $csvFile)
Write-Host "Destination :" (Resolve-Path $outputFolder)



Write-Host "====================================="
Write-Host "GENERATION IMMOBILIER DEPARTEMENTS"
Write-Host "====================================="
Write-Host ""

if (-not (Test-Path $csvFile)) {
    Write-Host "ERREUR : stats_whole_period.csv introuvable"
    exit 1
}

if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
}

Write-Host "Lecture du fichier DVF..."

$rows = Import-Csv -Path $csvFile

# Dictionnaire des donnees par code INSEE
$immobilierByCode = @{}

foreach ($row in $rows) {

    if ($row.echelle_geo -ne "commune") {
        continue
    }

    $code = ([string]$row.code_geo).Trim().PadLeft(5, "0")

    if ($code.Length -ne 5) {
        continue
    }

    # Prix median maison / m2
    $price = $null
    $priceText = [string]$row.med_prix_m2_whole_maison

    if (-not [string]::IsNullOrWhiteSpace($priceText)) {

        $priceNumber = 0

        if ([double]::TryParse(
            $priceText,
            [Globalization.NumberStyles]::Any,
            [Globalization.CultureInfo]::InvariantCulture,
            [ref]$priceNumber
        )) {
            $price = [math]::Round($priceNumber)
        }
    }

    # Nombre de ventes
    $sales = 0
    $salesText = [string]$row.nb_ventes_whole_maison

    [int]::TryParse(
        $salesText,
        [Globalization.NumberStyles]::Any,
        [Globalization.CultureInfo]::InvariantCulture,
        [ref]$sales
    ) | Out-Null

    $immobilierByCode[$code] = [PSCustomObject]@{
        code = $code
        housePriceM2 = $price
        houseSales = $sales
    }
}

Write-Host "Communes DVF trouvees :" $immobilierByCode.Count
Write-Host ""

# Liste des departements
$departments = @(
    "01","02","03","04","05","06","07","08","09","10",
    "11","12","13","14","15","16","17","18","19",
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

$totalPrix = 0
$totalCommunes = 0

foreach ($department in $departments) {

    Write-Host "Traitement :" $department

    $departmentData = @()

    foreach ($item in $immobilierByCode.Values) {

        $code = $item.code

        $match = $false

        if ($department -eq "2A") {
            $match = $code.StartsWith("200") -or $code.StartsWith("201")
        }
        elseif ($department -eq "2B") {
            $match = $code.StartsWith("202")
        }
        else {
            $match = $code.StartsWith($department)
        }

        if ($match) {
            $departmentData += $item
        }
    }

    $file = Join-Path $outputFolder "$department.json"

    $json = $departmentData | ConvertTo-Json -Depth 10

    [System.IO.File]::WriteAllText(
        $file,
        $json,
        [System.Text.UTF8Encoding]::new($false)
    )

    $withPrice = @(
        $departmentData |
        Where-Object { $null -ne $_.housePriceM2 }
    ).Count

    Write-Host "  Communes DVF :" $departmentData.Count
    Write-Host "  Prix disponibles :" $withPrice

    $totalCommunes += $departmentData.Count
    $totalPrix += $withPrice
}

Write-Host ""
Write-Host "====================================="
Write-Host "GENERATION TERMINEE"
Write-Host "====================================="
Write-Host "Communes DVF :" $totalCommunes
Write-Host "Prix disponibles :" $totalPrix
Write-Host "====================================="