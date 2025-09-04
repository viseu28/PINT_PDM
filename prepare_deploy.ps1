# Script PowerShell para Deploy no Render - PINT PDM
# Execute este script no diretório raiz do projeto

Write-Host "🚀 Iniciando preparação para deploy no Render..." -ForegroundColor Green

# Verificar se estamos no diretório correto
if (-not (Test-Path "PDM_PINT-main")) {
    Write-Host "❌ Erro: Execute este script no diretório raiz do projeto!" -ForegroundColor Red
    exit 1
}

Write-Host "📦 Verificando dependências Node.js..." -ForegroundColor Yellow
Set-Location "PDM_PINT-main/api-node"

# Verificar se package.json existe
if (-not (Test-Path "package.json")) {
    Write-Host "❌ Erro: package.json não encontrado!" -ForegroundColor Red
    exit 1
}

# Instalar dependências da API
Write-Host "📥 Instalando dependências da API..." -ForegroundColor Yellow
npm install

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao instalar dependências da API!" -ForegroundColor Red
    exit 1
}

# Voltar ao diretório raiz
Set-Location "../.."

Write-Host "📱 Verificando Flutter..." -ForegroundColor Yellow
Set-Location "PDM_PINT-main/projeto_pint"

# Verificar se Flutter está instalado
try {
    flutter --version | Out-Null
} catch {
    Write-Host "❌ Erro: Flutter não está instalado ou não está no PATH!" -ForegroundColor Red
    exit 1
}

# Ativar suporte web no Flutter
Write-Host "🌐 Ativando suporte web no Flutter..." -ForegroundColor Yellow
flutter config --enable-web

# Instalar dependências Flutter
Write-Host "📥 Instalando dependências Flutter..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao instalar dependências Flutter!" -ForegroundColor Red
    exit 1
}

# Voltar ao diretório raiz
Set-Location "../.."

Write-Host "✅ Preparação concluída com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Próximos passos:" -ForegroundColor Cyan
Write-Host "1. Fazer push das alterações para o GitHub" -ForegroundColor White
Write-Host "2. Criar conta no Render (render.com)" -ForegroundColor White
Write-Host "3. Seguir o guia em GUIA_DEPLOY_RENDER.md" -ForegroundColor White
Write-Host ""
Write-Host "📄 Arquivos criados/atualizados:" -ForegroundColor Cyan
Write-Host "- api-node/Dockerfile" -ForegroundColor White
Write-Host "- api-node/RENDER_DEPLOY.md" -ForegroundColor White
Write-Host "- api-node/.dockerignore" -ForegroundColor White
Write-Host "- render.yaml" -ForegroundColor White
Write-Host "- GUIA_DEPLOY_RENDER.md" -ForegroundColor White
Write-Host "- projeto_pint/lib/app/config/api_config.dart (atualizado)" -ForegroundColor White
