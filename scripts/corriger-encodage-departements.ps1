$folder = "C:\Users\mherv\OneDrive\Bureau\ma-ville-ideale\public\data\departements"

$encoding1252 = [System.Text.Encoding]::GetEncoding(1252)
$utf8 = [System.Text.Encoding]::UTF8

foreach ($file in Get-ChildItem "$folder\*.json") {

    $text = Get-Content $file.FullName -Raw -Encoding UTF8

    # On ne corrige que les fichiers contenant encore du mojibake
    if ($text -match "Ã") {

        $fixed = $utf8.GetString(
            $encoding1252.GetBytes($text)
        )

        [System.IO.File]::WriteAllText(
            $file.FullName,
            $fixed,
            [System.Text.UTF8Encoding]::new($false)
        )

        Write-Host "Corrige :" $file.Name
    }
    else {
        Write-Host "OK      :" $file.Name
    }
}

Write-Host ""
Write-Host "====================================="
Write-Host "CORRECTION ENCODAGE TERMINEE"
Write-Host "====================================="