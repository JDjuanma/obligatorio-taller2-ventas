#!/bin/bash

# ================================
# Script de Automatización Git
# Obligatorio 2 - Taller de Tecnologías 1
# Universidad ORT Uruguay
# ================================

# Configuración del repositorio
REPO_DIR="."
README_FILE="README.md"
LOG_FILE="git_automation.log"

# ================================
# Función: verificar_git
# Verifica si estamos en un repositorio git
# ================================
verificar_git() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: No estás en un repositorio git."
        echo "Ejecuta 'git init' para inicializar el repositorio."
        exit 1
    fi
}

# ================================
# Función: contar_cambios
# Cuenta las líneas modificadas desde el último commit
# ================================
contar_cambios() {
    local lineas_agregadas=$(git diff --cached --numstat 2>/dev/null | awk '{sum += $1} END {print sum+0}')
    local lineas_eliminadas=$(git diff --cached --numstat 2>/dev/null | awk '{sum += $2} END {print sum+0}')
    local total_modificado=$((lineas_agregadas + lineas_eliminadas))
    
    echo "$total_modificado"
}

# ================================
# Función: verificar_cambios
# Verifica si hay cambios para commitear
# ================================
verificar_cambios() {
    git add .
    if git diff --cached --quiet; then
        echo "ALERTA: No hay cambios para commitear."
        echo "El repositorio está actualizado."
        return 1
    fi
    return 0
}

# ================================
# Función: realizar_commit
# Realiza commit con mensaje automático
# ================================
realizar_commit() {
    local fecha=$(date '+%Y-%m-%d %H:%M:%S')
    local mensaje="Update automático - $fecha"
    
    echo "Realizando commit..."
    git commit -m "$mensaje"
    
    if [ $? -eq 0 ]; then
        echo "Commit realizado exitosamente."
        return 0
    else
        echo "Error al realizar commit."
        return 1
    fi
}

# ================================
# Función: push_a_remoto
# Envía cambios al repositorio remoto
# ================================
push_a_remoto() {
    local rama_actual=$(git branch --show-current)
    
    echo "Enviando cambios a GitHub..."
    echo "Rama actual: $rama_actual"
    
    git push origin "$rama_actual"
    
    if [ $? -eq 0 ]; then
        echo "Cambios enviados exitosamente a GitHub."
        return 0
    else
        echo "Error al enviar cambios a GitHub."
        echo "Verifica la configuración del repositorio remoto."
        return 1
    fi
}

# ================================
# Función: actualizar_readme
# Actualiza el archivo README.md con información del commit
# ================================
actualizar_readme() {
    local fecha=$(date '+%Y-%m-%d %H:%M:%S')
    local lineas_modificadas=$1
    local hash_commit=$(git rev-parse --short HEAD)
    
    # Crear README.md si no existe
    if [ ! -f "$README_FILE" ]; then
        cat > "$README_FILE" << EOF
# Sistema de Gestión de Ventas - Obligatorio 2
Taller de Tecnologías 1 - Universidad ORT

## Descripción
Sistema automatizado de ventas con automatización Git para upload semanal de código.

### Funcionalidades
- Autenticación: Registro e inicio de sesión de usuarios
- Alta de Productos: Gestión de productos con nombre, descripción, precio y stock
- Venta de Productos: Proceso de compra con control de inventario
- Automatización Git: Commits y push automáticos semanales

## Historial de Actualizaciones Automáticas
EOF
    fi
    
    # Agregar entrada al historial
    echo "### Update $fecha" >> "$README_FILE"
    echo "- **Commit:** $hash_commit" >> "$README_FILE"
    echo "- **Líneas modificadas:** $lineas_modificadas" >> "$README_FILE"
    echo "- **Rama:** $(git branch --show-current)" >> "$README_FILE"
    echo "" >> "$README_FILE"
    
    echo "README.md actualizado con información del commit."
}

# ================================
# Función: registro_log
# Registra la actividad en archivo de log
# ================================
registro_log() {
    local fecha=$(date '+%Y-%m-%d %H:%M:%S')
    local mensaje="$1"
    
    echo "[$fecha] $mensaje" >> "$LOG_FILE"
}

# ================================
# Función: mostrar_estado
# Muestra el estado actual del repositorio
# ================================
mostrar_estado() {
    echo "======================================"
    echo "   ESTADO DEL REPOSITORIO GIT"
    echo "======================================"
    echo "Directorio: $(pwd)"
    echo "Rama actual: $(git branch --show-current 2>/dev/null || echo 'No disponible')"
    echo "Archivos modificados:"
    git status --porcelain 2>/dev/null || echo "   No hay cambios"
    echo ""
}

# ================================
# Función principal: automatizar_git
# Ejecuta el proceso completo de automatización
# ================================
automatizar_git() {
    echo "Iniciando automatización de Git..."
    echo "======================================"
    
    # Verificar que estamos en un repositorio git
    verificar_git
    
    # Mostrar estado actual
    mostrar_estado
    
    # Verificar si hay cambios
    if ! verificar_cambios; then
        registro_log "No hay cambios para commitear"
        return 0
    fi
    
    # Contar líneas modificadas
    local lineas_modificadas=$(contar_cambios)
    echo "Líneas modificadas: $lineas_modificadas"
    
    # Realizar commit
    if realizar_commit; then
        registro_log "Commit realizado - $lineas_modificadas líneas modificadas"
        
        # Actualizar README
        actualizar_readme "$lineas_modificadas"
        
        # Commit del README actualizado
        git add "$README_FILE"
        git commit -m "Update README.md con información de automatización"
        
        # Push a remoto
        if push_a_remoto; then
            registro_log "Push exitoso a repositorio remoto"
            echo "Proceso de automatización completado exitosamente."
        else
            registro_log "Error en push a repositorio remoto"
        fi
    else
        registro_log "Error al realizar commit"
    fi
    
    echo "======================================"
    echo "Automatización finalizada."
}

# ================================
# Función: configurar_repositorio
# Ayuda a configurar el repositorio git inicial
# ================================
configurar_repositorio() {
    echo "Configuración inicial del repositorio..."
    
    # Inicializar git si no existe
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Inicializando repositorio git..."
        git init
    fi
    
    # Verificar configuración de usuario
    if [ -z "$(git config user.name)" ] || [ -z "$(git config user.email)" ]; then
        echo "Configurando usuario git..."
        read -p "Ingresa tu nombre: " nombre
        read -p "Ingresa tu email: " email
        git config user.name "$nombre"
        git config user.email "$email"
    fi
    
    # Verificar si hay remoto configurado
    if ! git remote get-url origin > /dev/null 2>&1; then
        echo "No hay repositorio remoto configurado."
        echo "Para configurar GitHub como remoto, ejecuta:"
        echo "git remote add origin https://github.com/TU_USUARIO/TU_REPOSITORIO.git"
    fi
    
    echo "Configuración completada."
}

# ================================
# Menú principal
# ================================
mostrar_menu() {
    echo ""
    echo "===== AUTOMATIZACIÓN GIT ====="
    echo "1) Ejecutar automatización completa"
    echo "2) Verificar estado del repositorio"
    echo "3) Configurar repositorio"
    echo "4) Ver log de actividad"
    echo "5) Salir"
    read -p "Seleccione una opción: " opcion
    
    case $opcion in
        1) automatizar_git ;;
        2) mostrar_estado ;;
        3) configurar_repositorio ;;
        4) 
            if [ -f "$LOG_FILE" ]; then
                echo "Log de actividad:"
                cat "$LOG_FILE"
            else
                echo "No hay log de actividad disponible."
            fi
            ;;
        5) echo "¡Hasta luego!"; exit 0 ;;
        *) echo "Opción inválida." ;;
    esac
}

# ================================
# Ejecución principal
# ================================
if [ "$1" = "--auto" ]; then
    # Modo automático (para cron o ejecución programada)
    automatizar_git
else
    # Modo interactivo
    while true; do
        mostrar_menu
    done
fi
