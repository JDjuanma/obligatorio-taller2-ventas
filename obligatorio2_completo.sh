#!/bin/bash

# ================================
# SISTEMA INTEGRADO DE VENTAS CON AUTOMATIZACIÓN GIT
# Obligatorio 2 - Taller de Tecnologías 1
# Universidad ORT Uruguay
# ================================

# Archivos de configuración
usuarios_file="usuarios.txt"
productos_file="productos.txt"
usuario_logueado=""

# ================================
# FUNCIONES DEL SISTEMA DE VENTAS
# ================================

registrar_usuario() {
  echo "=== Registro de nuevo usuario ==="
  read -p "Ingrese nombre de usuario: " usuario
  
  # Verificar que el usuario no exista
  if grep -q "^$usuario:" "$usuarios_file" 2>/dev/null; then
    echo "ERROR: El usuario '$usuario' ya existe."
    return
  fi
  
  read -sp "Ingrese contraseña: " contrasena
  echo
  hash=$(echo -n "$contrasena" | sha256sum | cut -d' ' -f1)
  echo "$usuario:$hash" >> "$usuarios_file"
  echo "Usuario registrado con éxito."
}

iniciar_sesion() {
  echo "=== Inicio de sesión ==="
  read -p "Nombre de usuario: " usuario
  read -sp "Contraseña: " contrasena
  echo
  hash_input=$(echo -n "$contrasena" | sha256sum | cut -d' ' -f1)
  if grep -q "^$usuario:$hash_input$" "$usuarios_file" 2>/dev/null; then
    echo "Inicio de sesión exitoso. ¡Bienvenido, $usuario!"
    usuario_logueado="$usuario"
  else
    echo "Credenciales inválidas. Inténtelo nuevamente."
  fi
}

alta_productos() {
  if [[ -z "$usuario_logueado" ]]; then
    echo "Debes iniciar sesión primero."
    return
  fi

  echo "=== Alta de Productos ==="
  read -p "Nombre del producto: " nombre
  
  # Verificar que el producto no exista
  if grep -q "^$nombre:" "$productos_file" 2>/dev/null; then
    echo "ERROR: El producto '$nombre' ya existe."
    return
  fi
  
  read -p "Descripción: " descripcion

  read -p "Precio (número): " precio
  while [[ ! "$precio" =~ ^[0-9]+([.][0-9]+)?$ ]]; do
    echo "Precio inválido. Inténtalo nuevamente."
    read -p "Precio (número): " precio
  done

  read -p "Stock inicial (número entero): " stock
  while [[ ! "$stock" =~ ^[0-9]+$ ]]; do
    echo "Stock inválido. Inténtalo nuevamente."
    read -p "Stock inicial (número entero): " stock
  done

  echo "$nombre:$descripcion:$precio:$stock" >> "$productos_file"
  echo "Producto '$nombre' agregado con éxito."
}

venta_productos() {
  if [[ -z "$usuario_logueado" ]]; then
    echo "Debes iniciar sesión primero."
    return
  fi

  echo "=== Productos disponibles ==="
  if [ -f "$productos_file" ] && [ -s "$productos_file" ]; then
    echo "Nombre | Descripción | Precio | Stock"
    echo "-------|-------------|--------|-------"
    while IFS=":" read -r nombre descripcion precio stock; do
      printf "%-10s | %-15s | $%-6s | %s\n" "$nombre" "$descripcion" "$precio" "$stock"
    done < "$productos_file"
  else
    echo "No hay productos disponibles."
    return
  fi
  
  echo ""
  read -p "Producto a comprar: " buscado
  if ! grep -q "^$buscado:" "$productos_file" 2>/dev/null; then
    echo "El producto '$buscado' no existe."
    return
  fi

  IFS=":" read -r nombre descripcion precio stock < <(grep "^$buscado:" "$productos_file")
  echo "Stock disponible: $stock"

  read -p "Cantidad a comprar: " cantidad
  while [[ ! "$cantidad" =~ ^[0-9]+$ ]] || (( cantidad < 1 )) || (( cantidad > stock )); do
    echo "Cantidad inválida o mayor al stock. Inténtalo nuevamente."
    read -p "Cantidad a comprar: " cantidad
  done

  nuevo_stock=$((stock - cantidad))
  sed -i "s|^$nombre:$descripcion:$precio:$stock\$|$nombre:$descripcion:$precio:$nuevo_stock|" "$productos_file"

  total=$(echo "$precio * $cantidad" | bc 2>/dev/null || echo $((precio * cantidad)))
  echo "Compra realizada: $cantidad x $nombre. Total: $total."
  
  # Registrar venta en log
  fecha=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$fecha] Venta: $usuario_logueado compró $cantidad x $nombre. Total: $total" >> ventas.log
}

# ================================
# FUNCIONES DE AUTOMATIZACIÓN GIT
# ================================

verificar_git() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "No estás en un repositorio git."
        echo "¿Deseas inicializar un repositorio git? (s/n)"
        read -p "Respuesta: " respuesta
        if [[ "$respuesta" =~ ^[sS]$ ]]; then
            git init
            echo "Repositorio git inicializado."
        else
            return 1
        fi
    fi
    return 0
}

automatizar_git() {
    echo "Iniciando automatización Git..."
    
    # Verificar repositorio git
    if ! verificar_git; then
        return 1
    fi
    
    # Agregar todos los archivos
    git add .
    
    # Verificar si hay cambios
    if git diff --cached --quiet; then
        echo "ALERTA: No hay cambios para commitear."
        echo "El repositorio está actualizado."
        return 0
    fi
    
    # Contar líneas modificadas
    local lineas_agregadas=$(git diff --cached --numstat 2>/dev/null | awk '{sum += $1} END {print sum+0}')
    local lineas_eliminadas=$(git diff --cached --numstat 2>/dev/null | awk '{sum += $2} END {print sum+0}')
    local total_modificado=$((lineas_agregadas + lineas_eliminadas))
    
    echo "Líneas modificadas: $total_modificado"
    
    # Realizar commit
    local fecha=$(date '+%Y-%m-%d %H:%M:%S')
    local mensaje="Update automático del sistema de ventas - $fecha"
    
    echo "Realizando commit..."
    if git commit -m "$mensaje"; then
        echo "Commit realizado exitosamente."
        
        # Actualizar README
        actualizar_readme_sistema "$total_modificado"
        
        # Commit del README
        git add README.md
        git commit -m "Update README.md con información de automatización"
        
        # Push si hay remoto configurado
        if git remote get-url origin > /dev/null 2>&1; then
            echo "Enviando cambios a GitHub..."
            if git push origin $(git branch --show-current); then
                echo "Cambios enviados exitosamente a GitHub."
            else
                echo "Error al enviar cambios. Verifica la configuración."
            fi
        else
            echo "No hay repositorio remoto configurado."
            echo "Para configurar GitHub: git remote add origin URL_DEL_REPO"
        fi
    else
        echo "Error al realizar commit."
    fi
}

actualizar_readme_sistema() {
    local lineas_modificadas=$1
    local fecha=$(date '+%Y-%m-%d %H:%M:%S')
    local hash_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "N/A")
    
    # Crear README.md si no existe
    if [ ! -f "README.md" ]; then
        cat > "README.md" << 'EOF'
# Sistema de Gestión de Ventas - Obligatorio 2
**Taller de Tecnologías 1 - Universidad ORT Uruguay**

## Descripción del Proyecto
Sistema automatizado de ventas desarrollado en Bash que incluye:

### Funcionalidades Principales
- **Autenticación de Usuarios**
  - Registro de nuevos usuarios
  - Inicio de sesión con contraseñas cifradas (SHA-256)
  
- **Gestión de Productos**
  - Alta de productos con validación de datos
  - Campos: Nombre, Descripción, Precio, Stock
  
- **Procesamiento de Ventas**
  - Compra de productos con control de inventario
  - Actualización automática de stock
  - Registro de transacciones

- **Automatización Git**
  - Commits automáticos programados
  - Sincronización con repositorio remoto
  - Seguimiento de cambios y estadísticas

### Archivos del Sistema
- `obligatorio2_completo.sh` - Sistema principal integrado
- `usuarios.txt` - Base de datos de usuarios
- `productos.txt` - Inventario de productos
- `ventas.log` - Registro de transacciones
- `README.md` - Documentación del proyecto

### Uso del Sistema
```bash
# Ejecutar el sistema
bash obligatorio2_completo.sh

# Opciones disponibles:
# 1. Registrarse
# 2. Iniciar sesión
# 3. Alta de productos
# 4. Venta de productos
# 5. Automatización Git
# 6. Salir
```

## Historial de Actualizaciones Automáticas

EOF
    fi
    
    # Agregar entrada al historial
    {
        echo "### Update $fecha"
        echo "- **Commit:** $hash_commit"
        echo "- **Líneas modificadas:** $lineas_modificadas"
        echo "- **Rama:** $(git branch --show-current 2>/dev/null || echo 'main')"
        echo "- **Usuario:** ${usuario_logueado:-'Sistema'}"
        echo ""
    } >> "README.md"
    
    echo "README.md actualizado con información del commit."
}

configurar_git() {
    echo "Configuración de Git y GitHub..."
    
    # Verificar configuración de usuario
    if [ -z "$(git config user.name)" ] || [ -z "$(git config user.email)" ]; then
        echo "Configurando usuario git..."
        read -p "Ingresa tu nombre: " nombre
        read -p "Ingresa tu email: " email
        git config user.name "$nombre"
        git config user.email "$email"
        echo "Usuario configurado."
    fi
    
    # Verificar remoto
    if ! git remote get-url origin > /dev/null 2>&1; then
        echo ""
        echo "Configuración de repositorio remoto (GitHub):"
        echo "1. Crea un repositorio en GitHub"
        echo "2. Copia la URL del repositorio"
        read -p "Ingresa la URL del repositorio (o presiona Enter para omitir): " repo_url
        
        if [ -n "$repo_url" ]; then
            git remote add origin "$repo_url"
            echo "Repositorio remoto configurado."
        fi
    else
        echo "Repositorio remoto ya configurado: $(git remote get-url origin)"
    fi
}

# ================================
# MENÚ PRINCIPAL INTEGRADO
# ================================
mostrar_menu_principal() {
    echo ""
    echo "================================================"
    echo "    SISTEMA DE VENTAS + AUTOMATIZACIÓN GIT"
    echo "    Obligatorio 2 - Universidad ORT"
    echo "================================================"
    
    if [ -n "$usuario_logueado" ]; then
        echo "Usuario: $usuario_logueado"
    else
        echo "Usuario: No logueado"
    fi
    
    echo ""
    echo "OPCIONES DISPONIBLES:"
    echo "1) Registrarse"
    echo "2) Iniciar sesión"
    echo "3) Alta de productos"
    echo "4) Venta de productos"
    echo "5) Automatización Git"
    echo "6) Configurar Git/GitHub"
    echo "7) Ver estadísticas"
    echo "8) Salir"
    echo ""
    read -p "Seleccione una opción: " opcion
    
    case $opcion in
        1) registrar_usuario ;;
        2) iniciar_sesion ;;
        3) alta_productos ;;
        4) venta_productos ;;
        5) automatizar_git ;;
        6) configurar_git ;;
        7) mostrar_estadisticas ;;
        8) 
            echo "¡Gracias por usar el sistema!"
            exit 0 
            ;;
        *) echo "Opción inválida. Intente nuevamente." ;;
    esac
}

mostrar_estadisticas() {
    echo "ESTADÍSTICAS DEL SISTEMA"
    echo "========================"
    
    # Estadísticas de usuarios
    if [ -f "$usuarios_file" ]; then
        echo "Usuarios registrados: $(wc -l < "$usuarios_file" 2>/dev/null || echo 0)"
    else
        echo "Usuarios registrados: 0"
    fi
    
    # Estadísticas de productos
    if [ -f "$productos_file" ]; then
        echo "Productos registrados: $(wc -l < "$productos_file" 2>/dev/null || echo 0)"
    else
        echo "Productos registrados: 0"
    fi
    
    # Estadísticas de ventas
    if [ -f "ventas.log" ]; then
        echo "Ventas realizadas: $(grep -c "Venta:" ventas.log 2>/dev/null || echo 0)"
    else
        echo "Ventas realizadas: 0"
    fi
    
    # Estado de Git
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Repositorio Git: Inicializado"
        echo "Rama actual: $(git branch --show-current 2>/dev/null || echo 'N/A')"
        if git remote get-url origin > /dev/null 2>&1; then
            echo "Remoto configurado: $(git remote get-url origin)"
        else
            echo "Remoto configurado: No configurado"
        fi
    else
        echo "Repositorio Git: No inicializado"
    fi
}

# ================================
# EJECUCIÓN PRINCIPAL
# ================================
echo "Iniciando Sistema de Ventas con Automatización Git..."

# Verificar dependencias básicas
if ! command -v git &> /dev/null; then
    echo "Git no está instalado. Por favor instala Git para usar la automatización."
fi

# Bucle principal del programa
while true; do
    mostrar_menu_principal
done
