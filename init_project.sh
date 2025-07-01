#!/bin/bash

# ================================
# Script de Inicialización del Proyecto
# Obligatorio 2 - Universidad ORT
# ================================

echo "Inicializando Proyecto - Sistema de Ventas con Git"
echo "=================================================="

# Obtener directorio actual
PROJECT_DIR="$(pwd)"
echo "Directorio del proyecto: $PROJECT_DIR"

# Lista de scripts del proyecto
SCRIPTS=("obligatorio2_completo.sh" "git_automation.sh" "setup_automation.sh")

echo ""
echo "Configurando permisos de ejecución..."

# Dar permisos de ejecución a todos los scripts
for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        echo "$script - Permisos configurados"
    else
        echo "$script - Archivo no encontrado"
    fi
done

echo ""
echo "Verificando dependencias..."

# Verificar Git
if command -v git &> /dev/null; then
    echo "Git está instalado: $(git --version)"
else
    echo "Git no está instalado. Por favor instala Git."
    echo "   Ubuntu/Debian: sudo apt install git"
    echo "   CentOS/RHEL: sudo yum install git"
    echo "   macOS: brew install git"
fi

# Verificar sha256sum
if command -v sha256sum &> /dev/null; then
    echo "sha256sum está disponible"
elif command -v shasum &> /dev/null; then
    echo "shasum está disponible (macOS)"
else
    echo "Función de hash SHA-256 no encontrada"
fi

# Verificar bc (para cálculos decimales)
if command -v bc &> /dev/null; then
    echo "bc está disponible para cálculos"
else
    echo "bc no está instalado (opcional para cálculos decimales)"
    echo "   Instalar: sudo apt install bc"
fi

echo ""
echo "Configuración inicial de Git..."

# Verificar si ya es un repositorio git
if [ -d ".git" ]; then
    echo "Ya es un repositorio Git"
    echo "Rama actual: $(git branch --show-current 2>/dev/null || echo 'No disponible')"
    
    # Verificar configuración de usuario
    if [ -z "$(git config user.name)" ] || [ -z "$(git config user.email)" ]; then
        echo "Configurando usuario Git..."
        read -p "Ingresa tu nombre: " git_name
        read -p "Ingresa tu email: " git_email
        git config user.name "$git_name"
        git config user.email "$git_email"
        echo "Usuario Git configurado"
    else
        echo "Usuario Git ya configurado: $(git config user.name) <$(git config user.email)>"
    fi
    
    # Verificar remoto
    if git remote get-url origin > /dev/null 2>&1; then
        echo "Repositorio remoto configurado: $(git remote get-url origin)"
    else
        echo "Sin repositorio remoto configurado"
        echo "Para configurar GitHub:"
        echo "   git remote add origin https://github.com/TU_USUARIO/TU_REPOSITORIO.git"
    fi
else
    echo "Inicializando repositorio Git..."
    git init
    
    echo "Configurando usuario Git..."
    read -p "Ingresa tu nombre: " git_name
    read -p "Ingresa tu email: " git_email
    git config user.name "$git_name"
    git config user.email "$git_email"
    
    echo "Repositorio Git inicializado y configurado"
    echo ""
    echo "Para conectar con GitHub:"
    echo "1. Crea un repositorio en GitHub"
    echo "2. Ejecuta: git remote add origin URL_DEL_REPOSITORIO"
    echo "3. Ejecuta: git push -u origin main"
fi

echo ""
echo "Creando archivos de configuración..."

# Crear .gitignore si no existe
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'EOF'
# Archivos temporales
*.tmp
*.log
*~

# Archivos de sistema
.DS_Store
Thumbs.db

# Archivos de backup
*.bak
*.backup

# Directorios de IDEs
.vscode/
.idea/

# Archivos de datos sensibles (opcional)
# usuarios.txt
# productos.txt
EOF
    echo ".gitignore creado"
else
    echo ".gitignore ya existe"
fi

echo ""
echo "Resumen de archivos del proyecto:"
echo "================================="
echo "Scripts principales:"
for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "   $script"
    else
        echo "   $script (faltante)"
    fi
done

echo ""
echo "Archivos de documentación:"
[ -f "README.md" ] && echo "   README.md" || echo "   README.md (faltante)"
[ -f ".gitignore" ] && echo "   .gitignore" || echo "   .gitignore (faltante)"

echo ""
echo "Archivos de datos (se crean automáticamente):"
echo "   usuarios.txt - Base de datos de usuarios"
echo "   productos.txt - Inventario de productos"  
echo "   ventas.log - Registro de ventas"
echo "   git_automation.log - Log de automatización"

echo ""
echo "¡Proyecto inicializado correctamente!"
echo "======================================="
echo ""
echo "Próximos pasos:"
echo "1. Ejecutar el sistema: bash obligatorio2_completo.sh"
echo "2. Registrar usuarios y productos"
echo "3. Configurar repositorio remoto (GitHub)"
echo "4. Configurar automatización: bash setup_automation.sh"
echo ""
echo "Para ayuda detallada, consulta el archivo README.md"
