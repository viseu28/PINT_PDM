# Script para substituir todas as URLs localhost/IP por ApiConfig
$baseDir = "C:\Users\user\Desktop\pdm_pint_final\PDM_PINT-main\projeto_pint\lib"

# Padrões a substituir
$replacements = @{
    "http://192.168.1.68:3000/likes_forum" = "`${ApiConfig.likesForumUrl}"
    "http://192.168.1.68:3000/respostas" = "`${ApiConfig.respostasUrl}"
    "http://192.168.1.68:3000/denuncia" = "`${ApiConfig.denunciaUrl}"
    "http://192.168.1.68:3000/guardados" = "`${ApiConfig.guardadosUrl}"
    "http://192.168.1.68:3000/forum" = "`${ApiConfig.forumUrl}"
    "http://192.168.1.68:3000/projetos" = "`${ApiConfig.projetosUrl}"
    "http://192.168.1.68:3000/uploads" = "`${ApiConfig.uploadsUrl}"
    "http://192.168.1.70:3000/uploads" = "`${ApiConfig.uploadsUrl}"
    "http://192.168.1.68:3000" = "`${ApiConfig.baseUrl}"
    "http://127.0.0.1:3000" = "`${ApiConfig.baseUrl}"
}

# Buscar todos os ficheiros .dart
$dartFiles = Get-ChildItem -Path $baseDir -Recurse -Filter "*.dart"

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $modified = $false
    
    foreach ($pattern in $replacements.Keys) {
        if ($content -match [regex]::Escape($pattern)) {
            $content = $content -replace [regex]::Escape($pattern), $replacements[$pattern]
            $modified = $true
            Write-Host "Replaced in $($file.Name): $pattern"
        }
    }
    
    if ($modified) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "Updated: $($file.FullName)"
    }
}

Write-Host "Replacement completed!"
