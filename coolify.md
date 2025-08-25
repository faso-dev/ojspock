# Configuration Coolify pour OJS

## 🎯 Déploiement avec Coolify

### Option 1: Utiliser Docker Compose (Recommandé)

1. **Créer une nouvelle application** dans Coolify
2. **Source**: Connecter votre repository GitHub
3. **Type**: Sélectionner "Docker Compose"
4. **Fichier**: `docker-compose.yml`

### Option 2: Utiliser Nixpacks

1. **Créer une nouvelle application** dans Coolify
2. **Source**: Repository GitHub
3. **Type**: Nixpacks
4. **Build Command**: `composer install --no-dev --optimize-autoloader`
5. **Start Command**: `php-fpm & nginx -g 'daemon off;'`

## 🔧 Variables d'environnement Coolify

```bash
# Base de données
DB_HOST=<hostname_db_coolify>
DB_PORT=3306
DB_USER=<user_db>
DB_PASSWORD=<password_db>
DB_DATABASE=<nom_database>

# Application
APP_URL=https://votre-domaine.com
APP_ENV=production

# Limites fichiers
MAX_FILE_SIZE=100M
MEMORY_LIMIT=512M
```

## 📂 Volumes persistants dans Coolify

Configurer ces volumes dans l'interface Coolify:

- `/var/www/html/storage` → Volume persistant pour les fichiers uploadés
- `/var/www/html/cache` → Volume pour le cache (optionnel)
- `/var/www/html/public` → Volume pour les fichiers publics

## 🗄️ Base de données

### Option A: Resource DB Coolify (Recommandé)
- Créer une resource MySQL 8.0 dans Coolify
- Connecter à votre application
- Coolify gère automatiquement les backups

### Option B: DB externe (Managed)
- AWS RDS, DigitalOcean Managed Database, etc.
- Plus fiable pour la production
- Backups automatiques inclus

## 🔐 Configuration domaine et SSL

1. **Domaine**: Configurer dans Coolify
2. **SSL**: Automatique via Let's Encrypt
3. **CDN**: Optionnel (CloudFlare)

## 📊 Monitoring

Ajouter ces services optionnels:
- **Logs**: Coolify intégré
- **Metrics**: Prometheus/Grafana
- **Uptime**: UptimeRobot

## 🔄 CI/CD

Coolify déclenchera automatiquement un redéploiement à chaque push sur la branche main.

### Git Hooks (optionnel)
```bash
# .coolify/deploy.sh
#!/bin/bash
composer install --no-dev --optimize-autoloader
php tools/upgrade.php check
```

## ⚡ Optimisations

1. **Cache Redis**: Activer dans config.inc.php
2. **OPcache**: Activé dans le Dockerfile
3. **Nginx Gzip**: Activé pour les assets statiques
4. **CDN**: Recommandé pour les fichiers statiques

## 🚨 Sécurité

- Variables sensibles dans l'environnement Coolify
- Accès DB restreint aux IPs Coolify
- Certificats SSL automatiques
- Headers de sécurité configurés dans Nginx