#!/bin/bash

################################################################################
# Script de Rollback de Documentación
# Hosting Management Platform Documentation Rollback Script
#
# Uso: ./rollback-documentacion.sh [opciones]
#
# Opciones:
#   -d, --directory DIR      Directorio de instalación (default: /var/www/docs)
#   -b, --backup FILE        Archivo de backup específico a restaurar
#   -l, --list               Listar backups disponibles
#   -c, --commit HASH        Volver a un commit específico
#   -h, --help               Mostrar ayuda
#
################################################################################

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
INSTALL_DIR="/var/www/docs"
BACKUP_DIR="/var/backups/docs"
LOG_FILE="/var/log/rollback-docs.log"
BACKUP_FILE=""
GIT_COMMIT=""
LIST_ONLY=false

# Funciones
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

show_help() {
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Script de Rollback de Documentación
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

USAGE:
    $0 [opciones]

OPTIONS:
    -d, --directory DIR      Directorio de instalación (default: /var/www/docs)
    -b, --backup FILE        Archivo de backup a restaurar
    -l, --list               Listar backups disponibles
    -c, --commit HASH        Volver a un commit Git específico
    -h, --help               Mostrar ayuda

EXAMPLES:
    # Listar backups disponibles
    $0 -l

    # Restaurar último backup
    $0

    # Restaurar backup específico
    $0 -b /var/backups/docs/docs_backup_20251023_120000.tar.gz

    # Volver a un commit específico
    $0 -c abc1234

EOF
}

list_backups() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  BACKUPS DISPONIBLES"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        warn "No hay backups disponibles en $BACKUP_DIR"
        return 1
    fi

    ls -lh "$BACKUP_DIR"/docs_backup_*.tar.gz | awk '{print $9, "(" $5 ")", $6, $7, $8}' | nl -w2 -s'. '
    echo ""
}

restore_from_backup() {
    local backup_file="$1"

    if [[ ! -f "$backup_file" ]]; then
        error "Archivo de backup no encontrado: $backup_file"
    fi

    log "Restaurando desde backup: $backup_file"

    # Crear backup del estado actual antes de restaurar
    info "Creando backup de seguridad del estado actual..."
    local safety_backup="$BACKUP_DIR/pre_rollback_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$safety_backup" -C "$(dirname "$INSTALL_DIR")" "$(basename "$INSTALL_DIR")" 2>/dev/null || true

    # Restaurar backup
    log "Extrayendo backup..."
    tar -xzf "$backup_file" -C "$(dirname "$INSTALL_DIR")"

    # Verificar restauración
    if [[ -d "$INSTALL_DIR" ]]; then
        log "✓ Backup restaurado exitosamente"
        log "Backup de seguridad guardado en: $safety_backup"
    else
        error "Error al restaurar backup"
    fi
}

rollback_git() {
    local commit="$1"

    if [[ ! -d "$INSTALL_DIR/.git" ]]; then
        error "No es un repositorio Git: $INSTALL_DIR"
    fi

    cd "$INSTALL_DIR"

    log "Volviendo al commit: $commit"

    # Crear backup antes de rollback
    info "Creando backup antes del rollback..."
    local backup_file="$BACKUP_DIR/pre_git_rollback_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$backup_file" -C "$(dirname "$INSTALL_DIR")" "$(basename "$INSTALL_DIR")" 2>/dev/null || true

    # Hacer rollback
    git checkout "$commit"

    log "✓ Rollback completado al commit: $(git rev-parse --short HEAD)"
    log "Backup creado en: $backup_file"
}

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--directory)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -b|--backup)
            BACKUP_FILE="$2"
            shift 2
            ;;
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        -c|--commit)
            GIT_COMMIT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Opción desconocida: $1"
            ;;
    esac
done

# Verificar permisos
if [[ $EUID -ne 0 ]]; then
    error "Este script debe ejecutarse como root o con sudo"
fi

# Listar backups si se solicita
if [[ "$LIST_ONLY" == true ]]; then
    list_backups
    exit 0
fi

# Banner
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ROLLBACK DE DOCUMENTACIÓN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ejecutar rollback
if [[ -n "$GIT_COMMIT" ]]; then
    # Rollback usando Git
    rollback_git "$GIT_COMMIT"
elif [[ -n "$BACKUP_FILE" ]]; then
    # Restaurar backup específico
    restore_from_backup "$BACKUP_FILE"
else
    # Restaurar último backup
    log "Buscando último backup..."
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/docs_backup_*.tar.gz 2>/dev/null | head -1)

    if [[ -z "$LATEST_BACKUP" ]]; then
        error "No se encontraron backups en $BACKUP_DIR"
    fi

    info "Último backup: $LATEST_BACKUP"
    restore_from_backup "$LATEST_BACKUP"
fi

# Reiniciar servidor web
if systemctl is-active --quiet httpd 2>/dev/null; then
    log "Reiniciando Apache..."
    systemctl restart httpd
elif systemctl is-active --quiet apache2 2>/dev/null; then
    log "Reiniciando Apache..."
    systemctl restart apache2
elif systemctl is-active --quiet nginx 2>/dev/null; then
    log "Reiniciando Nginx..."
    systemctl restart nginx
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✓ ROLLBACK COMPLETADO${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

log "Rollback completado exitosamente"

exit 0
