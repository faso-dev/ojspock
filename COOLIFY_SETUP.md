# 🚀 Guide Complet Coolify pour OJS

## 📋 **Étapes de déploiement**

### 1. **Créer l'application dans Coolify**

1. **Applications** → **+ New**
2. **Source** : GitHub → Connecter votre repo `ojspock`
3. **Type** : Docker Compose
4. **Port** : `3000`
5. **Domain** : `ojs.votre-domaine.com`

### 2. **Configurer les volumes persistants**

Dans Coolify → **Storage** → **+ Add Volume** :

```
Source: /var/lib/docker/volumes/ojs_storage/_data
Destination: /var/www/html/storage
```

**Volumes nécessaires** :
- `storage` → `/var/www/html/storage` ✅ **CRITIQUE pour config persistante**
- `cache` → `/var/www/html/cache` 
- `public` → `/var/www/html/public`

### 3. **Variables d'environnement OBLIGATOIRES**

```bash
# Base de données (OBLIGATOIRE)
DB_HOST=db-hostname-or-ip
DB_PORT=3306
DB_USER=ojs_user
DB_PASSWORD=votre_password_secure
DB_DATABASE=ojs

# Application (OBLIGATOIRE)
APP_URL=https://ojs.votre-domaine.com

# Email Production (RECOMMANDÉ)
SMTP_METHOD=smtp
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_AUTH=On
SMTP_USERNAME=votre-email@gmail.com
SMTP_PASSWORD=votre-app-password
SMTP_ENCRYPTION=tls
SMTP_FROM_EMAIL=noreply@votre-domaine.com
```

### 4. **Base de données - 2 options**

#### **Option A : Resource Coolify** (Facile)
1. **Resources** → **+ Database** → **MySQL 8.0**
2. Connecter à votre application
3. Variables automatiquement configurées

#### **Option B : DB Externe** (Production)
- AWS RDS, DigitalOcean, etc.
- Plus fiable pour gros volume

### 5. **Première installation**

Après le premier déploiement :

1. **Accéder au container** : Coolify → Application → **Terminal**
2. **Vérifier la config** :
   ```bash
   ls -la /var/www/html/config.inc.php
   cat /var/www/html/storage/config.inc.php
   ```
3. **Installer OJS** (si pas encore fait) :
   ```bash
   php tools/install.php
   ```

## 🔧 **Comment ça marche**

### **Configuration automatique** :
1. **Premier déploiement** : Config générée depuis vos variables d'environnement
2. **Sauvegarde** : Config copiée vers `/storage/config.inc.php` (volume persistant)
3. **Redéploiements** : Config rechargée depuis le volume persistant

### **Personnalisation après déploiement** :
```bash
# Éditer la config persistante
vi /var/www/html/storage/config.inc.php

# Redémarrer pour appliquer
# (Coolify → Application → Restart)
```

## ✅ **Avantages de cette approche**

- ✅ **Automatique** : Configuration créée depuis vos variables
- ✅ **Persistante** : Survit aux redéploiements
- ✅ **Modifiable** : Éditez `/storage/config.inc.php` si nécessaire
- ✅ **Sécurisée** : Pas de secrets dans le code
- ✅ **Production-ready** : Support email, SSL, cache

## 🚨 **Points importants**

1. **Volume storage** : OBLIGATOIRE pour la persistance
2. **Variables DB** : Doivent être correctes dès le premier déploiement
3. **Premier accès** : Peut prendre 2-3 minutes (installation)
4. **Email** : Configurez SMTP pour production (pas `log`)

## 🔍 **Debugging**

### Logs à vérifier :
```bash
# Logs du container
tail -f /var/log/nginx/error.log
tail -f /var/log/supervisor/supervisord.log

# Config générée
cat /var/www/html/config.inc.php
```

### Problèmes courants :
- **"no available server"** → Vérifier port 3000 dans Coolify
- **Erreurs DB** → Vérifier variables d'environnement DB
- **Config reset** → Volume storage pas monté

## 🎯 **Résultat final**

- **URL** : `https://ojs.votre-domaine.com`
- **Admin** : Interface d'installation OJS
- **Config** : Automatique et persistante
- **Emails** : Fonctionnels (si SMTP configuré)
- **Uploads** : Persistants dans volume storage