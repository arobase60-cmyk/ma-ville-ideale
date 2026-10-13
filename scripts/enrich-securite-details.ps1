$ErrorActionPreference = 'Stop'

# Lancer depuis la racine du projet ma-ville-ideale.
$csvFile = 'donnee-data.gouv-2025-geographie2026-produit-le2026-06-25.csv'
$outputDir = 'public\data\departements'
$targetYear = '2025'

if (-not (Test-Path -LiteralPath $csvFile -PathType Leaf)) { throw "CSV introuvable : $csvFile" }
if (-not (Test-Path -LiteralPath $outputDir -PathType Container)) { throw "Dossier introuvable : $outputDir" }

$files = @(Get-ChildItem -LiteralPath $outputDir -Filter '*.json' -File)
if ($files.Count -ne 96) { throw "96 fichiers departementaux attendus, $($files.Count) trouves. Aucun fichier modifie." }

# Charger les communes et conserver les tableaux departementaux.
$citiesByCode = @{}
$departments = @{}
foreach ($file in $files) {
    $cities = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
$cities = @($cities | ForEach-Object { $_ })
    if ($cities.Count -eq 0) { throw "Departement vide : $($file.Name)" }
    foreach ($city in $cities) {
        if ($null -eq $city -or -not $city.PSObject.Properties['code']) { throw "Commune sans code dans $($file.Name)" }
        $code = ([string]$city.code).Trim().PadLeft(5, '0')
        if ($citiesByCode.ContainsKey($code)) { throw "Code INSEE duplique : $code" }
        $citiesByCode[$code] = $city
    }
    $departments[$file.FullName] = $cities
}
Write-Host "Communes chargees : $($citiesByCode.Count)"

# Lecture ligne par ligne, sans charger le CSV de plusieurs centaines de Mo en memoire.
$reader = [System.IO.StreamReader]::new((Resolve-Path -LiteralPath $csvFile).Path, [System.Text.Encoding]::UTF8)
$matched = 0
$lineNumber = 0
try {
    $headerLine = $reader.ReadLine()
    $lineNumber++
    if ($null -eq $headerLine) { throw 'CSV vide' }
    $headers = @($headerLine.TrimStart([char]0xFEFF) -split ';' | ForEach-Object { $_.Trim('"') })
    $index = @{}
    for ($i = 0; $i -lt $headers.Count; $i++) { $index[$headers[$i]] = $i }
    foreach ($column in @('CODGEO_2026', 'annee', 'indicateur', 'nombre', 'taux_pour_mille', 'est_diffuse')) {
        if (-not $index.ContainsKey($column)) { throw "Colonne absente : $column" }
    }

    while (($line = $reader.ReadLine()) -ne $null) {
        $lineNumber++
        if ($lineNumber % 100000 -eq 0) {
    Write-Host "Progression : $lineNumber lignes lues"
}
        # Le CSV contient des champs avec et sans guillemets (ex. NA).
       $parts = @($line.Split(';') | ForEach-Object { $_.Trim('"') })
for ($j = 0; $j -lt $parts.Length; $j++) {
    $parts[$j] = $parts[$j].Trim('"')
}
        if ($parts.Count -ne $headers.Count) { throw "Ligne $lineNumber : $($parts.Count) colonnes, $($headers.Count) attendues. Aucun JSON modifie." }
        if ($parts[$index['annee']] -ne $targetYear) { continue }

        $code = $parts[$index['CODGEO_2026']].Trim().PadLeft(5, '0')
        if (-not $citiesByCode.ContainsKey($code)) { continue }
        $indicator = $parts[$index['indicateur']].Trim()
        if ([string]::IsNullOrWhiteSpace($indicator)) { throw "Indicateur vide ligne $lineNumber" }

        $diffusion = $parts[$index['est_diffuse']].Trim()
        $count = $null
        $rate = $null
        if ($diffusion -eq 'diff') {
            $numberText = $parts[$index['nombre']].Trim()
            $rateText = $parts[$index['taux_pour_mille']].Trim()
            $parsedCount = 0
            if ([int]::TryParse($numberText, [ref]$parsedCount)) { $count = $parsedCount }
            $parsedRate = 0.0
            if ([double]::TryParse($rateText.Replace(',', '.'),
                [Globalization.NumberStyles]::Float,
                [Globalization.CultureInfo]::InvariantCulture,
                [ref]$parsedRate)) { $rate = $parsedRate }
        }

        $city = $citiesByCode[$code]
        if ($null -eq $city.security) {
            $city | Add-Member -NotePropertyName security -NotePropertyValue ([PSCustomObject]@{}) -Force
        }
        if (-not $city.security.PSObject.Properties['details'] -or $null -eq $city.security.details) {
            $city.security | Add-Member -NotePropertyName details -NotePropertyValue ([PSCustomObject]@{}) -Force
        }
        $value = [PSCustomObject]@{
            indicator = $indicator
            year = 2025
            count = $count
            rate = $rate
            published = ($diffusion -eq 'diff')
        }
        $city.security.details | Add-Member -NotePropertyName $indicator -NotePropertyValue $value -Force
        $matched++
    }
}
finally { $reader.Close() }

Write-Host "Statistiques 2025 associees : $matched"
if ($matched -eq 0) { throw 'Aucune statistique associee. Aucun JSON modifie.' }

# Preparer et verifier TOUS les nouveaux fichiers avant de remplacer les originaux.
$staged = @{}
try {
    foreach ($file in $files) {
        $cities = $departments[$file.FullName]
        $json = ConvertTo-Json -InputObject $cities -Depth 30
        if (-not $json.TrimStart().StartsWith('[')) { throw "Format JSON inattendu : $($file.Name)" }
        $checked = ConvertFrom-Json -InputObject $json
        if ($checked.Count -ne $cities.Count) { throw "Nombre de communes modifie : $($file.Name)" }
        $temp = "$($file.FullName).securite.tmp"
        [System.IO.File]::WriteAllText($temp, $json, [System.Text.UTF8Encoding]::new($false))
        $staged[$file.FullName] = $temp
    }

    # Une sauvegarde datee par execution, jamais ecrasee.
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    foreach ($file in $files) {
        $backup = "$($file.FullName).avant-securite-$stamp.bak"
        Copy-Item -LiteralPath $file.FullName -Destination $backup -ErrorAction Stop
    }
    Write-Host 'Sauvegardes creees. Remplacement des fichiers...'
    foreach ($file in $files) {
        Move-Item -LiteralPath $staged[$file.FullName] -Destination $file.FullName -Force
    }
    Write-Host 'Termine : 96 fichiers mis a jour. Les sauvegardes datees sont conservees.'
}
finally {
    foreach ($temp in $staged.Values) {
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
    }
}
