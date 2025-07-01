#!/bin/bash

# ================================
# Script de Configuración para Automatización Semanal
# Obligatorio 2 - Universidad ORT
# ================================

echo "Configurador de Automatización Semanal de Git"
echo "=============================================="

# Obtener la ruta absoluta del directorio actual
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_SCRIPT="$SCRIPT_DIR/git_automation.sh"

echo "Directorio del proyecto: $SCRIPT_DIR"
echo "Script de automatización: $AUTOMATION_SCRIPT"

# Verificar que el script de automatización existe
if [ ! -f "$AUTOMATION_SCRIPT" ]; then
    echo "Error: No se encuentra el script git_automation.sh"
    echo "Asegúrate de que esté en el mismo directorio."
    exit 1
fi

# Dar permisos de ejecución
chmod +x "$AUTOMATION_SCRIPT"
echo "Permisos de ejecución configurados."

echo ""
echo "Opciones de automatización:"
echo "1) Configurar ejecución semanal (domingos 23:00)"
echo "2) Configurar ejecución diaria (23:00)"
echo "3) Ver configuración actual de cron"
echo "4) Ejecutar prueba manual"
echo "5) Eliminar automatización"
echo "6) Salir"

read -p "Selecciona una opción: " opcion

case $opcion in
    1)
        echo "Configurando ejecución semanal..."
        # Agregar al crontab (domingos a las 23:00)
        (crontab -l 2>/dev/null; echo "0 23 * * 0 cd '$SCRIPT_DIR' && bash git_automation.sh --auto >> automation.log 2>&1") | crontab -
        echo "Automatización semanal configurada para domingos a las 23:00"
        echo "Los logs se guardarán en: $SCRIPT_DIR/automation.log"
        ;;
    2)
        echo "Configurando ejecución diaria..."
        # Agregar al crontab (todos los días a las 23:00)
        (crontab -l 2>/dev/null; echo "0 23 * * * cd '$SCRIPT_DIR' && bash git_automation.sh --auto >> automation.log 2>&1") | crontab -
        echo "Automatización diaria configurada para las 23:00"
        echo "Los logs se guardarán en: $SCRIPT_DIR/automation.log"
        ;;
    3)
        echo "Configuración actual de crontab:"
        crontab -l 2>/dev/null || echo "No hay tareas programadas."
        ;;
    4)
        echo "Ejecutando prueba manual de automatización..."
        cd "$SCRIPT_DIR"
        bash git_automation.sh --auto
        ;;
    5)
        echo "Eliminando automatización..."
        # Eliminar líneas que contengan git_automation.sh del crontab
        crontab -l 2>/dev/null | grep -v "git_automation.sh" | crontab -
        echo "Automatización eliminada del crontab."
        ;;
    6)
        echo "¡Hasta luego!"
        exit 0
        ;;
    *)
        echo "Opción inválida."
        ;;
esac

echo ""
echo "Consejos:"
echo "• Para ver los logs de automatización: tail -f $SCRIPT_DIR/automation.log"
echo "• Para editar manualmente el crontab: crontab -e"
echo "• Para listar tareas programadas: crontab -l"
echo "• Para verificar que cron esté ejecutándose: service cron status"
