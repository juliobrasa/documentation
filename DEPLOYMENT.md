# Guía de Deployment de Documentación

Esta guía explica cómo desplegar la documentación del Hosting Management Platform en servidores de producción o staging.

## Tabla de Contenidos

- [Requisitos](#requisitos)
- [Instalación Rápida](#instalación-rápida)
- [Uso del Script](#uso-del-script)
- [Ejemplos](#ejemplos)
- [Configuración](#configuración)
- [Troubleshooting](#troubleshooting)

## Requisitos

### Software Requerido

- **Sistema Operativo**: CentOS 7+, RHEL 7+, AlmaLinux 8+, Ubuntu 18.04+
- **Git**: 2.x o superior
- **Servidor Web**: Apache 2.4+ o Nginx 1.18+ (opcional)
- **Permisos**: Acceso root o sudo

### Puertos

- Puerto para documentación (default: 8080)
- Puerto SSH (22) para acceso al servidor

## Instalación Rápida

### 1. Descargar el Script

```bash
# Opción 1: Clonar el repositorio completo
git clone https://github.com/juliobrasa/documentation.git
cd documentation
chmod +x desplegar-documentacion.sh

# Opción 2: Descargar solo el script
wget https://raw.githubusercontent.com/juliobrasa/documentation/main/desplegar-documentacion.sh
chmod +x desplegar-documentacion.sh
```

### 2. Ejecutar Deployment

```bash
# Deployment básico en staging
sudo ./desplegar-documentacion.sh

# Deployment en producción
sudo ./desplegar-documentacion.sh -e production -b main
```

## Uso del Script

### Sintaxis

```bash
./desplegar-documentacion.sh [opciones]
```

### Opciones Disponibles

| Opción | Descripción | Default | Valores |
|--------|-------------|---------|---------|
| `-e, --environment` | Entorno de deployment | `staging` | `production`, `staging` |
| `-b, --branch` | Rama Git a desplegar | `main` | Cualquier rama válida |
| `-d, --directory` | Directorio de instalación | `/var/www/docs` | Ruta absoluta |
| `-u, --url` | URL del repositorio Git | GitHub repo | URL Git válida |
| `-w, --web-server` | Servidor web a configurar | `apache` | `apache`, `nginx`, `none` |
| `-p, --port` | Puerto del servidor web | `8080` | 1024-65535 |
| `-h, --help` | Mostrar ayuda | - | - |

## Ejemplos

### Ejemplo 1: Deployment Básico en Staging

```bash
sudo ./desplegar-documentacion.sh
```

Esto desplegará:
- Entorno: staging
- Rama: main
- Directorio: /var/www/docs
- Servidor: Apache en puerto 8080

### Ejemplo 2: Deployment en Producción

```bash
sudo ./desplegar-documentacion.sh \
  -e production \
  -b main \
  -w apache \
  -p 8080
```

### Ejemplo 3: Deployment en Staging con Rama Develop

```bash
sudo ./desplegar-documentacion.sh \
  -e staging \
  -b develop \
  -d /var/www/docs-staging \
  -p 8081
```

### Ejemplo 4: Deployment con Nginx

```bash
sudo ./desplegar-documentacion.sh \
  -e production \
  -w nginx \
  -p 8090
```

### Ejemplo 5: Deployment sin Servidor Web

Útil si solo quieres clonar/actualizar los archivos:

```bash
sudo ./desplegar-documentacion.sh \
  -e production \
  -w none \
  -d /opt/documentation
```

### Ejemplo 6: Deployment desde Repositorio Privado

```bash
sudo ./desplegar-documentacion.sh \
  -e production \
  -u git@github.com:tu-usuario/documentation.git \
  -b main
```

## Configuración

### Configuración mediante Archivo .env

Puedes crear un archivo `.env.deploy` para configurar valores por defecto:

```bash
# Copiar archivo de ejemplo
cp .env.deploy.example .env.deploy

# Editar configuración
nano .env.deploy
```

Ejemplo de `.env.deploy`:

```bash
DEPLOY_ENVIRONMENT=production
DEPLOY_BRANCH=main
DEPLOY_INSTALL_DIR=/var/www/docs-production
DEPLOY_WEB_SERVER=apache
DEPLOY_WEB_PORT=8080
```

Luego el script puede leer estos valores automáticamente.

### Configuración de Firewall

El script automáticamente configura `firewalld` si está disponible. Si usas `iptables`:

```bash
# Abrir puerto manualmente
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
sudo service iptables save
```

### Configuración de SELinux

Si tienes SELinux en modo enforcing:

```bash
# Permitir que Apache sirva contenido desde el directorio
sudo semanage fcontext -a -t httpd_sys_content_t "/var/www/docs(/.*)?"
sudo restorecon -Rv /var/www/docs

# Permitir conexiones de red si es necesario
sudo setsebool -P httpd_can_network_connect 1
```

## Lo que Hace el Script

El script ejecuta los siguientes pasos automáticamente:

1. **Verificación de Requisitos**
   - Comprueba que se ejecuta como root
   - Verifica que Git está instalado
   - Comprueba disponibilidad del servidor web

2. **Backup Automático**
   - Crea backup de la instalación actual
   - Guarda en `/var/backups/docs/`
   - Mantiene los últimos 5 backups

3. **Deployment del Código**
   - Clona el repositorio (primera vez)
   - Actualiza repositorio existente
   - Cambia a la rama especificada

4. **Configuración de Permisos**
   - Establece propietario correcto (www-data)
   - Configura permisos de archivos y directorios

5. **Instalación del Servidor Web** (si aplica)
   - Instala Apache o Nginx si no está presente
   - Configura virtual host o server block
   - Habilita compresión y caché

6. **Configuración de Firewall**
   - Abre puerto necesario en firewalld
   - Recarga reglas de firewall

7. **Verificación**
   - Comprueba que los archivos existen
   - Verifica que el servidor web está activo
   - Confirma que el puerto está escuchando

8. **Generación de Información**
   - Crea archivo `.deployment-info`
   - Registra detalles del deployment
   - Genera logs detallados

## Estructura de Archivos Generados

Después del deployment, se generan los siguientes archivos:

```
/var/www/docs/
├── .deployment-info          # Información del deployment
├── .git/                     # Repositorio Git
├── README.md                 # Documentación principal
├── api/                      # Documentación API
├── architecture/             # Documentación de arquitectura
├── deployment/               # Guías de deployment
└── guides/                   # Guías de usuario

/var/log/
└── deploy-docs.log          # Log del deployment

/var/backups/docs/
├── docs_backup_20251023_120000.tar.gz
├── docs_backup_20251023_150000.tar.gz
└── ...                      # Últimos 5 backups

/etc/httpd/conf.d/  (o /etc/nginx/conf.d/)
└── documentation-production.conf  # Configuración del servidor web
```

## Acceder a la Documentación

### Desde el Servidor Local

```bash
# Con Apache/Nginx
curl http://localhost:8080

# Navegador en el servidor
firefox http://localhost:8080
```

### Desde Navegador Externo

```bash
# Obtener IP del servidor
ip addr show | grep inet

# Acceder desde navegador
http://TU_IP_SERVIDOR:8080
```

### Configurar Dominio

Para acceder mediante dominio (ejemplo: docs.tudominio.com):

1. Configura DNS A record apuntando al servidor
2. Modifica la configuración del servidor web:

```bash
# Apache
sudo nano /etc/httpd/conf.d/documentation-production.conf
# Cambiar ServerName a tu dominio

# Nginx
sudo nano /etc/nginx/conf.d/documentation-production.conf
# Cambiar server_name a tu dominio

# Reiniciar servidor web
sudo systemctl restart httpd  # o nginx
```

## Actualización de la Documentación

Para actualizar a la última versión:

```bash
# El script detecta automáticamente instalaciones existentes
# y actualiza en lugar de clonar de nuevo
sudo ./desplegar-documentacion.sh -e production
```

El proceso de actualización:
1. Crea backup de la versión actual
2. Hace `git pull` de los últimos cambios
3. Reinicia el servidor web
4. Mantiene la configuración existente

## Rollback a Versión Anterior

Si necesitas volver a una versión anterior:

### Opción 1: Restaurar desde Backup

```bash
# Listar backups disponibles
ls -lh /var/backups/docs/

# Restaurar un backup específico
sudo tar -xzf /var/backups/docs/docs_backup_20251023_120000.tar.gz -C /var/www/

# Reiniciar servidor web
sudo systemctl restart httpd
```

### Opción 2: Usar Git

```bash
cd /var/www/docs

# Ver commits anteriores
git log --oneline

# Volver a un commit específico
sudo git checkout <commit-hash>

# O volver al commit anterior
sudo git checkout HEAD~1

# Reiniciar servidor web
sudo systemctl restart httpd
```

## Troubleshooting

### Problema: "Git no está instalado"

**Solución:**
```bash
# CentOS/RHEL/AlmaLinux
sudo yum install -y git

# Ubuntu/Debian
sudo apt-get install -y git
```

### Problema: "Puerto ya en uso"

**Solución:**
```bash
# Verificar qué está usando el puerto
sudo netstat -tulpn | grep :8080

# Cambiar a un puerto diferente
sudo ./desplegar-documentacion.sh -e production -p 8090
```

### Problema: "Permisos denegados"

**Solución:**
```bash
# Asegurarse de ejecutar con sudo
sudo ./desplegar-documentacion.sh

# Verificar permisos del directorio
sudo chown -R www-data:www-data /var/www/docs
```

### Problema: "No se puede acceder desde el navegador"

**Verificaciones:**

1. Comprobar que el servidor web está activo:
```bash
sudo systemctl status httpd  # o nginx
```

2. Verificar que el puerto está escuchando:
```bash
sudo netstat -tulpn | grep :8080
```

3. Verificar firewall:
```bash
sudo firewall-cmd --list-all
```

4. Verificar logs:
```bash
sudo tail -f /var/log/httpd/docs-production-error.log
sudo tail -f /var/log/deploy-docs.log
```

### Problema: "Error 403 Forbidden"

**Solución:**
```bash
# Verificar permisos
ls -la /var/www/docs/

# Corregir permisos
sudo chown -R www-data:www-data /var/www/docs
sudo find /var/www/docs -type d -exec chmod 755 {} \;
sudo find /var/www/docs -type f -exec chmod 644 {} \;

# Si usas SELinux
sudo restorecon -Rv /var/www/docs
```

### Problema: "Error al clonar repositorio privado"

**Solución:**
```bash
# Configurar SSH keys
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub  # Añadir a GitHub

# O usar deploy keys en GitHub
# Settings > Deploy keys > Add deploy key

# Usar URL SSH en lugar de HTTPS
sudo ./desplegar-documentacion.sh \
  -u git@github.com:usuario/documentation.git
```

### Problema: "Conflictos de Git en actualización"

**Solución:**
```bash
cd /var/www/docs

# Ver cambios locales
git status

# Guardar cambios locales
git stash

# Actualizar
git pull

# Aplicar cambios guardados (si es necesario)
git stash pop
```

## Logs y Monitoreo

### Ver Logs del Deployment

```bash
# Log del script de deployment
sudo tail -f /var/log/deploy-docs.log

# Logs del servidor web
sudo tail -f /var/log/httpd/docs-production-error.log
sudo tail -f /var/log/httpd/docs-production-access.log
```

### Monitorear el Servicio

```bash
# Estado del servidor web
sudo systemctl status httpd

# Ver últimos logs
sudo journalctl -u httpd -n 50 -f

# Verificar conectividad
curl -I http://localhost:8080
```

## Automatización

### Deployment Automático con Cron

Para actualizar automáticamente cada día:

```bash
# Editar crontab
sudo crontab -e

# Añadir línea (actualización diaria a las 2 AM)
0 2 * * * /path/to/desplegar-documentacion.sh -e production -b main >> /var/log/auto-deploy-docs.log 2>&1
```

### Webhook de GitHub

Para deployment automático cuando hay push a GitHub:

1. Instalar webhook listener
2. Configurar endpoint
3. Llamar al script desde el webhook

Ejemplo con webhook simple:

```bash
# Crear script webhook
cat > /usr/local/bin/docs-webhook.sh << 'EOF'
#!/bin/bash
cd /var/www/docs && git pull
systemctl restart httpd
EOF

chmod +x /usr/local/bin/docs-webhook.sh
```

## Seguridad

### Mejores Prácticas

1. **Usar HTTPS**: Configurar SSL con Let's Encrypt
2. **Restringir acceso**: Usar firewall y autenticación
3. **Backups regulares**: Mantener backups fuera del servidor
4. **Monitoreo**: Configurar alertas de cambios
5. **Deploy keys**: Usar deploy keys de solo lectura en GitHub

### Configurar SSL con Let's Encrypt

```bash
# Instalar Certbot
sudo yum install -y certbot python3-certbot-apache

# Obtener certificado
sudo certbot --apache -d docs.tudominio.com

# Auto-renovación
sudo certbot renew --dry-run
```

### Restringir Acceso por IP

Editar configuración de Apache:

```apache
<Directory /var/www/docs>
    Require ip 192.168.1.0/24
    Require ip 10.0.0.0/8
</Directory>
```

## Soporte

Para problemas o preguntas:

1. Revisar logs: `/var/log/deploy-docs.log`
2. Consultar [Troubleshooting Guide](guides/troubleshooting.md)
3. Contactar al equipo de desarrollo
4. Abrir issue en GitHub

## Changelog

### v1.0.0 (2025-10-23)
- Release inicial del script de deployment
- Soporte para Apache y Nginx
- Backups automáticos
- Configuración de firewall
- Verificación de deployment
- Logs detallados

---

*Para más información sobre la documentación, ver [README.md](README.md)*
