#!/bin/bash

################################################################################
# Script de Despliegue de Documentación
# Hosting Management Platform Documentation Deployment Script
#
# Uso: ./desplegar-documentacion.sh [opciones]
#
# Opciones:
#   -e, --environment ENV    Entorno: production, staging (default: staging)
#   -b, --branch BRANCH      Rama a desplegar (default: main)
#   -d, --directory DIR      Directorio de instalación (default: /var/www/docs)
#   -u, --url URL            URL del repositorio Git
#   -w, --web-server SERVER  Servidor web: apache, nginx, none (default: apache)
#   -p, --port PORT          Puerto para el servidor web (default: 8080)
#   -h, --help               Mostrar ayuda
#
# Ejemplos:
#   ./desplegar-documentacion.sh -e production -b main
#   ./desplegar-documentacion.sh -e staging -b develop -d /var/www/docs-staging
#   ./desplegar-documentacion.sh -e production -w nginx -p 8090
#
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

################################################################################
# Variables de Configuración
################################################################################

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables por defecto
ENVIRONMENT="staging"
BRANCH="main"
INSTALL_DIR="/var/www/docs"
GIT_REPO="https://github.com/juliobrasa/documentation.git"
WEB_SERVER="apache"
WEB_PORT="8080"
LOG_FILE="/var/log/deploy-docs.log"
BACKUP_DIR="/var/backups/docs"
USER="www-data"
GROUP="www-data"

# Fecha para backups
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

################################################################################
# Funciones
################################################################################

# Función para imprimir mensajes
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Función para mostrar ayuda
show_help() {
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Script de Despliegue de Documentación
  Hosting Management Platform Documentation Deployment
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

USAGE:
    $0 [opciones]

OPTIONS:
    -e, --environment ENV    Entorno: production, staging (default: staging)
    -b, --branch BRANCH      Rama a desplegar (default: main)
    -d, --directory DIR      Directorio de instalación (default: /var/www/docs)
    -u, --url URL            URL del repositorio Git
    -w, --web-server SERVER  Servidor web: apache, nginx, none (default: apache)
    -p, --port PORT          Puerto del servidor web (default: 8080)
    -h, --help               Mostrar esta ayuda

EXAMPLES:
    # Desplegar en producción
    $0 -e production -b main

    # Desplegar en staging con rama develop
    $0 -e staging -b develop -d /var/www/docs-staging

    # Desplegar con Nginx en puerto 8090
    $0 -e production -w nginx -p 8090

    # Desplegar sin configurar servidor web
    $0 -e production -w none

EOF
}

# Función para verificar requisitos
check_requirements() {
    log "Verificando requisitos del sistema..."

    # Verificar que se ejecuta como root
    if [[ $EUID -ne 0 ]]; then
        error "Este script debe ejecutarse como root o con sudo"
    fi

    # Verificar Git
    if ! command -v git &> /dev/null; then
        error "Git no está instalado. Instálalo con: yum install -y git"
    fi

    # Verificar servidor web si se requiere
    if [[ "$WEB_SERVER" == "apache" ]]; then
        if ! command -v httpd &> /dev/null && ! command -v apache2 &> /dev/null; then
            warn "Apache no está instalado. Se instalará automáticamente."
        fi
    elif [[ "$WEB_SERVER" == "nginx" ]]; then
        if ! command -v nginx &> /dev/null; then
            warn "Nginx no está instalado. Se instalará automáticamente."
        fi
    fi

    log "✓ Requisitos verificados"
}

# Función para crear backup
create_backup() {
    if [[ -d "$INSTALL_DIR" ]]; then
        log "Creando backup de la documentación actual..."

        mkdir -p "$BACKUP_DIR"

        BACKUP_FILE="$BACKUP_DIR/docs_backup_${TIMESTAMP}.tar.gz"
        tar -czf "$BACKUP_FILE" -C "$(dirname "$INSTALL_DIR")" "$(basename "$INSTALL_DIR")" 2>/dev/null || true

        if [[ -f "$BACKUP_FILE" ]]; then
            log "✓ Backup creado: $BACKUP_FILE"
        else
            warn "No se pudo crear el backup (el directorio puede estar vacío)"
        fi

        # Limpiar backups antiguos (mantener últimos 5)
        ls -t "$BACKUP_DIR"/docs_backup_*.tar.gz 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
    fi
}

# Función para clonar o actualizar repositorio
deploy_documentation() {
    log "Desplegando documentación..."

    if [[ -d "$INSTALL_DIR/.git" ]]; then
        info "Actualizando repositorio existente..."
        cd "$INSTALL_DIR"

        # Guardar cambios locales si existen
        git stash save "Auto-stash before deployment ${TIMESTAMP}" 2>/dev/null || true

        # Actualizar repositorio
        git fetch origin
        git checkout "$BRANCH"
        git pull origin "$BRANCH"

        log "✓ Repositorio actualizado"
    else
        info "Clonando repositorio..."

        # Crear directorio padre si no existe
        mkdir -p "$(dirname "$INSTALL_DIR")"

        # Clonar repositorio
        git clone -b "$BRANCH" "$GIT_REPO" "$INSTALL_DIR"

        log "✓ Repositorio clonado"
    fi

    cd "$INSTALL_DIR"

    # Mostrar información del deployment
    info "Rama desplegada: $(git branch --show-current)"
    info "Último commit: $(git log -1 --pretty=format:'%h - %s (%an, %ar)')"
}

# Función para configurar permisos
set_permissions() {
    log "Configurando permisos..."

    # Crear usuario si no existe
    if ! id -u "$USER" &>/dev/null; then
        warn "Usuario $USER no existe, usando usuario actual"
        USER=$(whoami)
    fi

    # Establecer propietario
    chown -R "$USER:$GROUP" "$INSTALL_DIR"

    # Establecer permisos
    find "$INSTALL_DIR" -type d -exec chmod 755 {} \;
    find "$INSTALL_DIR" -type f -exec chmod 644 {} \;

    # Si hay scripts, hacerlos ejecutables
    if [[ -d "$INSTALL_DIR/scripts" ]]; then
        chmod +x "$INSTALL_DIR"/scripts/*.sh 2>/dev/null || true
    fi

    log "✓ Permisos configurados"
}

# Función para instalar servidor web
install_web_server() {
    if [[ "$WEB_SERVER" == "apache" ]]; then
        if ! command -v httpd &> /dev/null && ! command -v apache2 &> /dev/null; then
            log "Instalando Apache..."

            if [[ -f /etc/redhat-release ]]; then
                yum install -y httpd mod_ssl
                systemctl enable httpd
            elif [[ -f /etc/debian_version ]]; then
                apt-get update
                apt-get install -y apache2
                systemctl enable apache2
            fi

            log "✓ Apache instalado"
        fi
    elif [[ "$WEB_SERVER" == "nginx" ]]; then
        if ! command -v nginx &> /dev/null; then
            log "Instalando Nginx..."

            if [[ -f /etc/redhat-release ]]; then
                yum install -y nginx
                systemctl enable nginx
            elif [[ -f /etc/debian_version ]]; then
                apt-get update
                apt-get install -y nginx
                systemctl enable nginx
            fi

            log "✓ Nginx instalado"
        fi
    fi
}

# Función para configurar Apache
configure_apache() {
    log "Configurando Apache..."

    # Determinar directorio de configuración
    if [[ -d /etc/httpd/conf.d ]]; then
        CONF_DIR="/etc/httpd/conf.d"
        SERVICE_NAME="httpd"
    elif [[ -d /etc/apache2/sites-available ]]; then
        CONF_DIR="/etc/apache2/sites-available"
        SERVICE_NAME="apache2"
    else
        error "No se encontró el directorio de configuración de Apache"
    fi

    # Crear configuración
    CONF_FILE="$CONF_DIR/documentation-${ENVIRONMENT}.conf"

    cat > "$CONF_FILE" << EOF
# Documentation ${ENVIRONMENT} - Generated on ${TIMESTAMP}
Listen ${WEB_PORT}

<VirtualHost *:${WEB_PORT}>
    ServerName docs.soporteclientes.net
    DocumentRoot ${INSTALL_DIR}

    <Directory ${INSTALL_DIR}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted

        # Habilitar DirectoryIndex para archivos Markdown
        DirectoryIndex index.html index.md README.md

        # Configurar tipos MIME para Markdown
        AddType text/markdown .md
        AddType text/markdown .markdown
    </Directory>

    # Logging
    ErrorLog /var/log/httpd/docs-${ENVIRONMENT}-error.log
    CustomLog /var/log/httpd/docs-${ENVIRONMENT}-access.log combined

    # Compresión
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript text/markdown
    </IfModule>

    # Caché
    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType text/markdown "access plus 1 hour"
        ExpiresByType text/html "access plus 1 hour"
    </IfModule>
</VirtualHost>
EOF

    # Habilitar sitio en Debian/Ubuntu
    if [[ -d /etc/apache2/sites-available ]]; then
        a2ensite "documentation-${ENVIRONMENT}.conf" 2>/dev/null || true
    fi

    # Verificar configuración
    if command -v apachectl &> /dev/null; then
        apachectl configtest || error "Error en la configuración de Apache"
    elif command -v apache2ctl &> /dev/null; then
        apache2ctl configtest || error "Error en la configuración de Apache"
    fi

    # Reiniciar Apache
    systemctl restart "$SERVICE_NAME"

    log "✓ Apache configurado en puerto $WEB_PORT"
}

# Función para configurar Nginx
configure_nginx() {
    log "Configurando Nginx..."

    CONF_DIR="/etc/nginx/conf.d"
    CONF_FILE="$CONF_DIR/documentation-${ENVIRONMENT}.conf"

    cat > "$CONF_FILE" << EOF
# Documentation ${ENVIRONMENT} - Generated on ${TIMESTAMP}

server {
    listen ${WEB_PORT};
    server_name docs.soporteclientes.net;

    root ${INSTALL_DIR};
    index index.html index.md README.md;

    # Logs
    access_log /var/log/nginx/docs-${ENVIRONMENT}-access.log;
    error_log /var/log/nginx/docs-${ENVIRONMENT}-error.log;

    # Compresión
    gzip on;
    gzip_types text/plain text/css text/javascript application/javascript text/markdown;

    # Configurar tipos MIME para Markdown
    types {
        text/markdown md markdown;
    }

    location / {
        try_files \$uri \$uri/ =404;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
    }

    # Caché para archivos estáticos
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1h;
        add_header Cache-Control "public, immutable";
    }

    # Seguridad
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF

    # Verificar configuración
    nginx -t || error "Error en la configuración de Nginx"

    # Reiniciar Nginx
    systemctl restart nginx

    log "✓ Nginx configurado en puerto $WEB_PORT"
}

# Función para configurar firewall
configure_firewall() {
    log "Configurando firewall..."

    if command -v firewall-cmd &> /dev/null; then
        # Abrir puerto
        firewall-cmd --permanent --add-port="${WEB_PORT}/tcp" 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
        log "✓ Puerto $WEB_PORT abierto en firewall"
    else
        warn "firewalld no está disponible, verifica manualmente el firewall"
    fi
}

# Función para generar archivo de información del deployment
generate_deployment_info() {
    log "Generando información del deployment..."

    INFO_FILE="$INSTALL_DIR/.deployment-info"

    cat > "$INFO_FILE" << EOF
# Deployment Information
# Generated on: $(date)

ENVIRONMENT=$ENVIRONMENT
BRANCH=$BRANCH
DEPLOY_DATE=$TIMESTAMP
GIT_COMMIT=$(git -C "$INSTALL_DIR" rev-parse HEAD)
GIT_BRANCH=$(git -C "$INSTALL_DIR" branch --show-current)
WEB_SERVER=$WEB_SERVER
WEB_PORT=$WEB_PORT
INSTALL_DIR=$INSTALL_DIR

# Last Deployment
DEPLOYED_BY=$(whoami)
DEPLOYED_FROM=$(hostname)
EOF

    log "✓ Información del deployment guardada en $INFO_FILE"
}

# Función para verificar deployment
verify_deployment() {
    log "Verificando deployment..."

    # Verificar que el directorio existe
    if [[ ! -d "$INSTALL_DIR" ]]; then
        error "El directorio de instalación no existe: $INSTALL_DIR"
    fi

    # Verificar que hay archivos
    FILE_COUNT=$(find "$INSTALL_DIR" -name "*.md" | wc -l)
    if [[ $FILE_COUNT -lt 5 ]]; then
        error "No se encontraron suficientes archivos de documentación"
    fi

    # Verificar servidor web si aplica
    if [[ "$WEB_SERVER" != "none" ]]; then
        if [[ "$WEB_SERVER" == "apache" ]]; then
            SERVICE_NAME="httpd"
            [[ -f /etc/debian_version ]] && SERVICE_NAME="apache2"
        else
            SERVICE_NAME="nginx"
        fi

        if ! systemctl is-active --quiet "$SERVICE_NAME"; then
            error "El servidor web $SERVICE_NAME no está activo"
        fi

        # Verificar que el puerto está escuchando
        if ! netstat -tuln 2>/dev/null | grep -q ":$WEB_PORT " && ! ss -tuln 2>/dev/null | grep -q ":$WEB_PORT "; then
            warn "El puerto $WEB_PORT no parece estar escuchando"
        fi
    fi

    log "✓ Deployment verificado correctamente"
}

# Función para mostrar resumen
show_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}✓ DEPLOYMENT COMPLETADO EXITOSAMENTE${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Entorno:           $ENVIRONMENT"
    echo "Rama:              $BRANCH"
    echo "Directorio:        $INSTALL_DIR"
    echo "Servidor Web:      $WEB_SERVER"
    if [[ "$WEB_SERVER" != "none" ]]; then
        echo "Puerto:            $WEB_PORT"
        echo "URL Local:         http://localhost:$WEB_PORT"
        echo "URL Servidor:      http://$(hostname -I | awk '{print $1}'):$WEB_PORT"
    fi
    echo ""
    echo "Archivos MD:       $(find "$INSTALL_DIR" -name "*.md" | wc -l)"
    echo "Último Commit:     $(git -C "$INSTALL_DIR" log -1 --pretty=format:'%h - %s')"
    echo "Log File:          $LOG_FILE"
    if [[ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        echo "Backup:            $BACKUP_DIR"
    fi
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [[ "$WEB_SERVER" != "none" ]]; then
        echo ""
        info "Accede a la documentación en: http://$(hostname -I | awk '{print $1}'):$WEB_PORT"
    fi

    echo ""
}

# Función de limpieza en caso de error
cleanup_on_error() {
    error "El deployment ha fallado. Revisa el log: $LOG_FILE"

    # Si existe un backup reciente, preguntar si restaurar
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/docs_backup_*.tar.gz 2>/dev/null | head -1)
    if [[ -n "$LATEST_BACKUP" ]]; then
        warn "Hay un backup disponible: $LATEST_BACKUP"
        echo "Para restaurar, ejecuta: tar -xzf $LATEST_BACKUP -C $(dirname "$INSTALL_DIR")"
    fi
}

################################################################################
# Parsear argumentos
################################################################################

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -b|--branch)
            BRANCH="$2"
            shift 2
            ;;
        -d|--directory)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -u|--url)
            GIT_REPO="$2"
            shift 2
            ;;
        -w|--web-server)
            WEB_SERVER="$2"
            shift 2
            ;;
        -p|--port)
            WEB_PORT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Opción desconocida: $1\nUsa -h o --help para ver las opciones disponibles"
            ;;
    esac
done

################################################################################
# Validar argumentos
################################################################################

if [[ "$ENVIRONMENT" != "production" && "$ENVIRONMENT" != "staging" ]]; then
    error "Entorno inválido: $ENVIRONMENT (debe ser 'production' o 'staging')"
fi

if [[ "$WEB_SERVER" != "apache" && "$WEB_SERVER" != "nginx" && "$WEB_SERVER" != "none" ]]; then
    error "Servidor web inválido: $WEB_SERVER (debe ser 'apache', 'nginx' o 'none')"
fi

################################################################################
# Ejecución Principal
################################################################################

# Trap para manejar errores
trap cleanup_on_error ERR

# Banner
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  DEPLOYMENT DE DOCUMENTACIÓN - $(echo "$ENVIRONMENT" | tr '[:lower:]' '[:upper:]')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Crear directorio de logs si no existe
mkdir -p "$(dirname "$LOG_FILE")"

# Iniciar log
log "Iniciando deployment de documentación..."
log "Entorno: $ENVIRONMENT"
log "Rama: $BRANCH"

# Ejecutar pasos del deployment
check_requirements
create_backup
deploy_documentation
set_permissions

# Configurar servidor web si se requiere
if [[ "$WEB_SERVER" != "none" ]]; then
    install_web_server

    if [[ "$WEB_SERVER" == "apache" ]]; then
        configure_apache
    elif [[ "$WEB_SERVER" == "nginx" ]]; then
        configure_nginx
    fi

    configure_firewall
fi

generate_deployment_info
verify_deployment
show_summary

log "Deployment completado exitosamente"

exit 0
