#!/bin/bash
# Build script para Flutter Web

echo "🚀 Iniciando build do Flutter Web..."

# Navigate to Flutter project
cd PDM_PINT-main/projeto_pint

# Enable web support (if not already enabled)
flutter config --enable-web

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for web with optimizations
flutter build web --release --web-renderer html --base-href /

echo "✅ Build concluído! Os arquivos estão em build/web/"
