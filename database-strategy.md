# Stratégies Base de Données pour OJS

## 🎯 Recommandations par environnement

### 🧪 Développement/Test
- **Docker Compose MySQL** (inclus dans docker-compose.yml)
- Données perdues à chaque redémarrage si nécessaire
- Facile à réinitialiser et tester

### 🚀 Production - Option 1: Resource Coolify (Recommandé)
```yaml
# Dans Coolify:
# 1. Créer Resource → Database → MySQL 8.0
# 2. Connecter à votre application
# 3. Backups automatiques configurés
```

**Avantages:**
- ✅ Gestion simplifiée via interface Coolify
- ✅ Backups automatiques
- ✅ Monitoring intégré
- ✅ Mise à jour automatique des patches sécurité

**Inconvénients:**
- ❌ Moins de contrôle granulaire
- ❌ Dépendant de l'infrastructure Coolify

### 🚀 Production - Option 2: Base Managée Externe
```bash
# Examples de services managés:
# - AWS RDS MySQL/Aurora
# - DigitalOcean Managed Database
# - Google Cloud SQL
# - Azure Database for MySQL
```

**Avantages:**
- ✅ Haute disponibilité
- ✅ Backups automatiques multi-régions
- ✅ Scaling automatique
- ✅ Support professionnel
- ✅ Sécurité renforcée

**Inconvénients:**
- ❌ Plus coûteux
- ❌ Configuration plus complexe

## 📊 Configuration recommandée

### MySQL 8.0 (Recommandé)
```sql
-- Paramètres optimaux pour OJS
SET GLOBAL innodb_buffer_pool_size = 512M;
SET GLOBAL max_connections = 200;
SET GLOBAL query_cache_size = 64M;

-- Character set UTF8MB4 pour support emoji/unicode complet
ALTER DATABASE ojs CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### PostgreSQL (Alternative)
```sql
-- Si vous préférez PostgreSQL
-- Plus robuste pour les opérations complexes
-- Meilleur support JSON
CREATE DATABASE ojs WITH ENCODING 'UTF8';
```

## 🔒 Sécurité Base de Données

### Configuration réseau
```bash
# Restreindre l'accès uniquement aux IPs Coolify
# Dans votre service DB managé:
# - Autoriser seulement les IPs de votre instance Coolify
# - Activer SSL/TLS forcé
# - Désactiver l'accès public
```

### Utilisateurs et permissions
```sql
-- Créer un utilisateur spécifique pour OJS
CREATE USER 'ojs_app'@'%' IDENTIFIED BY 'mot_de_passe_fort';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX, DROP 
  ON ojs.* TO 'ojs_app'@'%';

-- Utilisateur backup (lecture seule)
CREATE USER 'ojs_backup'@'%' IDENTIFIED BY 'autre_mot_de_passe';
GRANT SELECT, LOCK TABLES ON ojs.* TO 'ojs_backup'@'%';
```

## 📦 Migration et Backup

### Script de backup automatique
```bash
#!/bin/bash
# docker/backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_DATABASE | gzip > /backup/ojs_$DATE.sql.gz

# Nettoyer les backups > 7 jours
find /backup -name "*.sql.gz" -mtime +7 -delete

# Upload vers S3/Cloud Storage (optionnel)
# aws s3 cp /backup/ojs_$DATE.sql.gz s3://your-bucket/backups/
```

### Migration des données
```bash
# Export depuis l'ancienne DB
mysqldump -h ancien_host -u user -p ancienne_db > migration.sql

# Import vers nouvelle DB
mysql -h nouveau_host -u user -p nouvelle_db < migration.sql

# Vérifier l'intégrité
php tools/upgrade.php check
```

## ⚡ Optimisation Performance

### Index recommandés
```sql
-- Index pour améliorer les performances OJS
ALTER TABLE submissions ADD INDEX idx_status_context (status, context_id);
ALTER TABLE articles ADD INDEX idx_published (date_published);
ALTER TABLE users ADD INDEX idx_username (username);
```

### Configuration MySQL optimale
```ini
# my.cnf
[mysqld]
innodb_buffer_pool_size = 1G        # 70% de la RAM disponible
innodb_log_file_size = 256M
max_connections = 300
query_cache_size = 128M
tmp_table_size = 128M
max_heap_table_size = 128M
```

## 🔧 Variables d'environnement

### Docker Compose
```yaml
environment:
  - DB_HOST=db
  - DB_PORT=3306
  - DB_USER=ojs
  - DB_PASSWORD=secure_password
  - DB_DATABASE=ojs
```

### Coolify avec DB externe
```bash
# Dans l'interface Coolify
DB_HOST=your-rds-endpoint.amazonaws.com
DB_PORT=3306
DB_USER=ojs_app
DB_PASSWORD=your_secure_password
DB_DATABASE=ojs_production
DB_SSL_MODE=required  # Pour les DB managées
```

## 🚨 Disaster Recovery

1. **Backups automatiques** : Quotidiens minimum
2. **Test de restauration** : Mensuel
3. **Réplication** : Master-slave pour haute disponibilité
4. **Monitoring** : Alertes sur échec backup/performance

## 💡 Ma recommandation finale

**Pour démarrer** : Resource MySQL Coolify
**Pour production intensive** : AWS RDS ou équivalent managé

Cette approche vous permet de commencer simplement et d'évoluer selon vos besoins sans refactoring majeur.