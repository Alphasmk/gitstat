chcp 65001 > $null

$Container = "7b84451c728d"
$Output = "users_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"

Write-Host "Exporting..." -ForegroundColor Cyan

docker exec $Container bash -c "sqlplus -S system/1111@FREEPDB1 <<'EOF'
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
EXEC json_io.export_users_to_file('users_export.json');
EXIT;
EOF" 2>$null

Write-Host "Checking file size in container..." -ForegroundColor Yellow
docker exec $Container stat -c%s /tmp/users_export.json

docker cp "${Container}:/tmp/users_export.json" ".\$Output"

$Lines = (Get-Content $Output | Measure-Object -Line).Lines
Write-Host "Lines in local file: $Lines" -ForegroundColor Cyan

Write-Host "Done: $Output" -ForegroundColor Green
