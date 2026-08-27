$folders = @(
    "public\data\departements",
    "public\data\immobilier"
)

Write-Host "====================================="
Write-Host "CORRECTION DE L'ENCODAGE"
Write-Host "====================================="
Write-Host ""

foreach ($folder in $folders) {

    if (-not (Test-Path $folder)) {
        Write-Host "Dossier introuvable :" $folder
        continue
    }

    Write-Host "Traitement :" $folder

    $files = Get-ChildItem $folder -Filter "*.json"

    foreach ($file in $files) {

        $text = [System.IO.File]::ReadAllText(
            $file.FullName,
            [System.Text.Encoding]::UTF8
        )

        # On corrige uniquement les textes qui contiennent
        # les signes typiques d'un mauvais encodage UTF-8
        if ($text -match "Ã|Â|â€") {

            try {

                $bytes = [System.Text.Encoding]::GetEncoding(1252).GetBytes($text)

                $fixed = [System.Text.Encoding]::UTF8.GetString($bytes)

                if ($fixed -notmatch "�") {

                    [System.IO.File]::WriteAllText(
                        $file.FullName,
                        $fixed,
                        [System.Text.UTF8Encoding]::new($false)
                    )

                    Write-Host "  Corrige :" $file.Name
                }
                else {
                    Write-Host "  Non modifie :" $file.Name
                }

            }
            catch {
                Write-Host "  ERREUR :" $file.Name
            }
        }
    }
}

Write-Host ""
Write-Host "====================================="
Write-Host "CORRECTION TERMINEE"
Write-Host "====================================="