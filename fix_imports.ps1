# Script para corrigir imports do ApiConfig
$baseDir = "C:\Users\user\Desktop\pdm_pint_final\PDM_PINT-main\projeto_pint\lib"

# Buscar todos os ficheiros .dart que têm imports incorretos
$dartFiles = Get-ChildItem -Path $baseDir -Recurse -Filter "*.dart"

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    
    # Determinar o caminho correto baseado na localização do ficheiro
    $relativePath = $file.DirectoryName.Replace($baseDir, "").Replace("\", "/")
    $depth = ($relativePath.Split("/") | Where-Object { $_ -ne "" }).Count
    
    $correctPath = ""
    if ($depth -eq 1) { $correctPath = "../config/api_config.dart" }        # services/
    elseif ($depth -eq 2) { $correctPath = "../../config/api_config.dart" } # screens/home/
    elseif ($depth -eq 3) { $correctPath = "../../../config/api_config.dart" } # screens/courses/
    
    if ($correctPath -ne "") {
        # Substituir imports incorretos
        $patterns = @(
            "import '../../../config/api_config.dart';",
            "import '../../config/api_config.dart';",
            "import '../config/api_config.dart';"
        )
        
        $modified = $false
        foreach ($pattern in $patterns) {
            if ($content -match [regex]::Escape($pattern) -and $pattern -ne "import '$correctPath';") {
                $content = $content -replace [regex]::Escape($pattern), "import '$correctPath';"
                $modified = $true
                Write-Host "Fixed import in $($file.Name): $pattern -> import '$correctPath';"
            }
        }
        
        if ($modified) {
            Set-Content -Path $file.FullName -Value $content -NoNewline
            Write-Host "Updated: $($file.FullName)"
        }
    }
}

Write-Host "Import path correction completed!"
