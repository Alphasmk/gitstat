param([string]$InputFile)

chcp 65001 > $null

if (-not $InputFile) {
    Get-ChildItem -Filter "users_backup_*.json" | Format-Table Name, Length, LastWriteTime
    Write-Host "Usage: .\import.ps1 filename.json" -ForegroundColor Yellow
    exit
}

if (-not (Test-Path $InputFile)) {
    Write-Host "File not found!" -ForegroundColor Red
    exit 1
}

Write-Host "Importing $InputFile..." -ForegroundColor Cyan

docker cp $InputFile "cp-database:/tmp/users_import.json"

"EXEC json_io.import_users_from_file('users_import.json');
EXIT;" | docker exec -i cp-database sqlplus -S system/1111@FREEPDB1

if ($LASTEXITCODE -eq 0) {
    Write-Host "Done!" -ForegroundColor Green
} else {
    Write-Host "Error!" -ForegroundColor Red
}