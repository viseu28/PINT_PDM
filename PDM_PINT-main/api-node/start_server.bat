@echo off
echo 🚀 Iniciando servidor Node.js da API...
echo.

cd /d "c:\Users\user\Desktop\projeto_pint\api-node"

echo 📁 Diretório atual: %CD%
echo.

echo 📦 Verificando se os módulos estão instalados...
if not exist "node_modules" (
    echo ❌ Módulos não encontrados! Instalando...
    npm install
) else (
    echo ✅ Módulos encontrados!
)

echo.
echo 🔥 Iniciando servidor...
echo 💡 O servidor será acessível em:
echo    - Local: http://localhost:3000
echo    - Rede:  http://192.168.1.688:3000
echo.
echo ⏹️  Para parar o servidor, pressione Ctrl+C
echo.

node index.js
pause
