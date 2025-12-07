chcp 65001 > $null

$Container = "7b84451c728d"
$Output = "users_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"

Write-Host "Exporting..." -ForegroundColor Cyan

"EXEC json_io.export_users_to_file('users_export.json');
EXIT;" | docker exec -i $Container sqlplus -S system/1111@FREEPDB1

docker cp "${Container}:/tmp/users_export.json" ".\$Output"

Write-Host "Done: $Output" -ForegroundColor Green
