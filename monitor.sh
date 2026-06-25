#!/bin/bash

USER_NAME=${USER:-$(whoami)}
BASE_DIR="/opt/monitoring-lab/$USER_NAME"
REPORT_DIR="$BASE_DIR/reports/run-$(date +%Y%m%d-%H%M%S)"
LATEST_LINK="$BASE_DIR/reports/latest"
LOG_DATA_DIR="/var/log/monitoring-lab/data"
TREE_DIR="/var/log/monitoring-lab/tmp/tree"

START_TIME=$(date)
MACHINE_NAME=$(hostname)

function log_step() {
    echo "[+] $1"
}

function log_done() {
    echo "[+] Fin de $1 (status : Ok)"
}

echo "L'heure de debut : $START_TIME"
echo "Le nom de la machine : $MACHINE_NAME"
echo "L'utilisateur courant : $USER_NAME"
echo ""

log_step "Lancement de la mise en place des dossiers rapports"
mkdir -p "$REPORT_DIR"
ln -sfn "$REPORT_DIR" "$LATEST_LINK"
log_done "lancement des dossiers rapport"

cd "$REPORT_DIR" || exit 1

log_step "Vérification des services"
cat <<EOF > services.txt
RUN : $(date)
MACHINE : $MACHINE_NAME
UTILISATEUR COURANT : $USER_NAME / root

FAKE-API est $(systemctl is-active --quiet fake-api && echo "{Ok}" || echo "{Nok}")
LOG-GENERATOR est $(systemctl is-active --quiet log-generator && echo "{Ok}" || echo "{Nok}")
NOISY-WORKERS est $(systemctl is-active --quiet noisy-workers && echo "{Ok}" || echo "{Nok}")
EOF
log_done "vérification des services"

log_step "Lecture des logs"
echo "--- Dernières 30 lignes fake-api ---" > journald.txt
journalctl -u fake-api -n 30 >> journald.txt
echo "--- Dernières 30 lignes log-generator ---" >> journald.txt
journalctl -u log-generator -n 30 >> journald.txt
journalctl -u fake-api -u log-generator -p err..emerg > journald_errors.txt
log_done "lecture des logs"

log_step "Observation des processus"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 11 > top_cpu.txt
ps aux | grep "[c]pu-hog.sh" > hogs.txt
log_done "observation des processus"

log_step "Analyse de app.log"
APP_LOG="$LOG_DATA_DIR/app.log"
if [ -f "$APP_LOG" ]; then
    TOTAL_LINES=$(wc -l < "$APP_LOG")
    ERROR_LINES=$(grep -c "ERROR" "$APP_LOG")
    CRIT_LINES=$(grep -c "CRITICAL" "$APP_LOG")
    TOP_HOSTS=$(awk '{print $1}' "$APP_LOG" | sort | uniq -c | sort -nr | head -n 5)
    
    cat <<EOF > app_summary.txt
Nombre total de lignes : $TOTAL_LINES
Nombre total de lignes ERROR : $ERROR_LINES
Nombre total de lignes CRITICAL : $CRIT_LINES

Top 5 des hotes :
$TOP_HOSTS
EOF

    sed -E 's/SECRET=[a-zA-Z0-9]+/SECRET=**REDACTED**/g' "$APP_LOG" > app_redacted.log
fi
log_done "analyse de app.log"

log_step "Analyse de metrics.csv"
METRICS_CSV="$LOG_DATA_DIR/metrics.csv"
if [ -f "$METRICS_CSV" ]; then
    M_TOTAL_LINES=$(wc -l < "$METRICS_CSV")
    M_HIGH_CPU=$(awk -F',' '$3 >= 95 {print}' "$METRICS_CSV" | wc -l)
    M_ANOMALIES=$(awk -F',' '$3 >= 95 {print}' "$METRICS_CSV" | head -n 5)
    
    cat <<EOF > metrics_summary.txt
Nombre total de lignes : $M_TOTAL_LINES
Nombre de lignes ou cpu_pct >= 95 : $M_HIGH_CPU

Les 5 premieres lignes anormales :
$M_ANOMALIES
EOF
fi
log_done "analyse de metrics.csv"

log_step "Recherche avec find et xargs"
if [ -d "$TREE_DIR" ]; then
    find "$TREE_DIR" -type f -name "*.bak" > tree_bak.txt
    find "$TREE_DIR" -type f -print0 | xargs -0 grep -l "SECRET=" > tree_secret.txt
fi
log_done "recherche avec find et xargs"

log_step "Contrôle des fichiers générés"
FILES_TO_CHECK=("services.txt" "journald.txt" "journald_errors.txt" "top_cpu.txt" "hogs.txt" "app_summary.txt" "app_redacted.log" "metrics_summary.txt" "tree_bak.txt" "tree_secret.txt")

MISSING=0
for f in "${FILES_TO_CHECK[@]}"; do
    if [ ! -f "$f" ]; then
        echo "ERREUR: Le fichier $f est manquant."
        MISSING=$((MISSING + 1))
    fi
done

if [ $MISSING -eq 0 ]; then
    echo "Contrôle terminé : Tous les fichiers requis sont présents."
else
    echo "Contrôle terminé : Il manque $MISSING fichier(s)."
fi
log_done "contrôle des fichiers générés"

echo "Script terminé avec succès."
