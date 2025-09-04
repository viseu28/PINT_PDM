# Script para adicionar imports ApiConfig onde necessário
$baseDir = "C:\Users\user\Desktop\pdm_pint_final\PDM_PINT-main\projeto_pint\lib"

# Buscar ficheiros que usam ApiConfig mas não têm o import
$dartFiles = Get-ChildItem -Path $baseDir -Recurse -Filter "*.dart" | Where-Object { $_.Name -ne "api_config.dart" }

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    
    # Verificar se usa ApiConfig mas não tem o import
    if ($content -match "ApiConfig" -and $content -notmatch "import.*api_config\.dart") {
        # Determinar o path relativo correto
        $relativePath = $file.DirectoryName.Replace($baseDir, "").Replace("\", "/")
        $depth = ($relativePath.Split("/") | Where-Object { $_ -ne "" }).Count
        
        if ($depth -eq 0) { $importPath = "./config/api_config.dart" }
        elseif ($depth -eq 1) { $importPath = "../config/api_config.dart" }
        elseif ($depth -eq 2) { $importPath = "../../config/api_config.dart" }
        elseif ($depth -eq 3) { $importPath = "../../../config/api_config.dart" }
        else { $importPath = "../../../../config/api_config.dart" }
        
        # Encontrar onde inserir o import
        $lines = $content -split "`n"
        $lastImportIndex = -1
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^import ") {
                $lastImportIndex = $i
            }
        }
        
        if ($lastImportIndex -ge 0) {
            # Inserir após o último import
            $newImport = "import '$importPath';"
            $lines = $lines[0..$lastImportIndex] + $newImport + $lines[($lastImportIndex + 1)..($lines.Count - 1)]
            $newContent = $lines -join "`n"
            
            Set-Content -Path $file.FullName -Value $newContent -NoNewline
            Write-Host "Added import to: $($file.Name)"
        }
    }
}

Write-Host "Import addition completed!"
