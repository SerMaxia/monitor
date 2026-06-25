# Script de Monitoring Linux (`monitor.sh`)

Script Bash d'audit et de monitoring système. Permet de générer un rapport sur l'état des services, des logs applicatifs et de la charge système.

## Fonctionnalités principales

1. **Services** : Vérification du statut des services cibles (`fake-api`, `log-generator`, `noisy-workers`).
2. **Logs système** : Extraction des erreurs récentes via `journalctl`.
3. **Processus** : Identification des processus les plus lourds en CPU.
4. **Analyse applicative** : Parsing de `app.log` et `metrics.csv` (comptage d'erreurs, détection de surcharge hôte).
5. **Sécurité** : Recherche de fichiers `.bak` et masquage (redaction) des secrets.

## Utilisation

### Lancement manuel

```bash
chmod +x monitor.sh
sudo ./monitor.sh
```

Les rapports sont stockés dans `/opt/monitoring-lab/$USER/reports/`.
Un raccourci `latest` pointe vers le rapport le plus récent :
```bash
cd /opt/monitoring-lab/root/reports/latest
```

### Fichiers de sortie

- **`services.txt`** : État des services (Ok/Nok).
- **`top_cpu.txt`** : Top 10 des processus (tri par CPU).
- **`journald_errors.txt`** : Erreurs journald (`emerg` à `err`).
- **`app_summary.txt`** : Statistiques des logs `app.log`.
- **`app_redacted.log`** : Version filtrée de `app.log` (sans secrets).

## Automatisation (Systemd / Cron)

### Via Systemd (Service + Timer)

1. **Installation du script et du service** :
```bash
sudo cp monitor.sh /usr/local/bin/monitor.sh
sudo cp student-monitor.service /etc/systemd/system/
sudo systemctl daemon-reload
```

2. **Configuration du Timer (exécutions périodiques)** :
Créer `/etc/systemd/system/student-monitor.timer` :
```ini
[Unit]
Description=Timer monitor.sh

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
```

Activer le timer :
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now student-monitor.timer
```

### Via Cron (Alternative)

Pour exécuter le script à chaque heure fixe via Cron :
```bash
sudo crontab -e
```
Ajouter la ligne :
```bash
0 * * * * /opt/monitoring-lab/root/monitor.sh
```

## Mode Test

Un script de test est fourni pour simuler un environnement :
```bash
sudo ./setup_mock.sh
sudo ./monitor.sh
```

## Mise à jour

Récupération de la dernière version :
```bash
git pull origin main
```

Mise à jour automatique (tous les jours à 2h00) via Cron :
```bash
0 2 * * * cd /chemin/vers/linux_monitoring_project && git pull origin main
```
