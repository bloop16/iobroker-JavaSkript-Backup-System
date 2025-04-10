#!/bin/bash

# Quell- und Zielverzeichnisse festlegen
SOURCE_DIR="/opt/iobroker/skriptMirror/"
TARGET_DIR="/opt/iobroker/backupSkripts/"
REPO_NAME="iobroker-Skripts-AmRing"
GITHUB_USER="[UserName]"
SCRIPT_PATH="/usr/local/bin/backup_iobroker_skripts.sh"

# Konfiguration
MAX_BACKUPS=10           # Maximale Anzahl der Backups pro Skript
USE_GIT=true           # Git-Integration aktivieren/deaktivieren
USE_VERSIONS=true       # Versionierung mit Zeitstempeln aktivieren/deaktivieren

# Sensitive Begriffe definieren
SENSITIVE_PATTERNS=(
    # Variablen-Deklarationen mit const/let/var
    's/\(const\|let\|var\)\s*\(password\|pass\|passwort\|passwd\|user\|benutzer\|apikey\|secret\)\s*=\s*["\x27]\([^\x27"]*\)["\x27]/\1 \2="XXXXXX"/g'
    
    # Direkte Zuweisungen
    's/\(password\|pass\|passwort\|passwd\|user\|benutzer\|apikey\|secret\)\s*=\s*["\x27]\([^\x27"]*\)["\x27]/\1="XXXXXX"/g'
    
    # Objekt-Eigenschaften
    's/\(password\|pass\|passwort\|passwd\|user\|benutzer\|apikey\|secret\):\s*["\x27]\([^\x27"]*\)["\x27]/\1:"XXXXXX"/g'
    
    # JSON-Style-Zuweisungen
    's/"\(password\|pass\|passwort\|passwd\|user\|benutzer\|apikey\|secret\)"\s*:\s*["\x27]\([^\x27"]*\)["\x27]/"\1":"XXXXXX"/g'
)
# Funktion zum Schwaerzen sensitiver Daten
sanitize_file() {
    local SOURCE="$1"
    local TARGET="$2"
    local FOUND=0
    
    # Kopiere Datei zunaechst
    cp "${SOURCE}" "${TARGET}"
    
    # Durchsuche nach sensitiven Variablennamen und ersetze sie
    for pattern in "${SENSITIVE_PATTERNS[@]}"; do
        # Fuehre sed aus und pruefe den Rueckgabewert
        if sed -i "${pattern}" "${TARGET}"; then
            FOUND=1
            echo "Sensitives Muster gefunden und geschwaerzt"
        fi
    done
    
    if [ $FOUND -eq 1 ]; then
        echo "   Sensitive Daten wurden in ${SOURCE##*/} geschwaerzt"
        echo "   Original: ${SOURCE}"
        echo "   Geschwaerzt: ${TARGET}"
        diff "${SOURCE}" "${TARGET}" || true
    fi
}
# Git Funktionen
git_init() {
    if [ "$USE_GIT" = true ] && [ ! -d "${TARGET_DIR}/.git" ]; then
        cd "${TARGET_DIR}"
        git init
        git remote add origin "git@github.com:${GITHUB_USER}/${REPO_NAME}.git"
        git branch -M main
        git pull origin main --allow-unrelated-histories || true
        echo "Git Repository initialisiert"
    fi
}

git_commit_push() {
    if [ "$USE_GIT" = true ]; then
        local message="$1"
        local diff="$2"
        cd "${TARGET_DIR}"
        git add .
        if [ -n "$diff" ]; then
            git commit -m "$message" -m "Aenderungen:" -m "$diff"
        else
            git commit -m "$message"
        fi
        git push origin main || git push -f origin main
    fi
}

# Funktion zum Backup des Skripts selbst
backup_self() {
    cp "${SCRIPT_PATH}" "${TARGET_DIR}backup_iobroker_skripts.sh"
    
    if [ "$USE_GIT" = true ]; then
        local DIFF_CONTENT=$(diff "${SCRIPT_PATH}" "${TARGET_DIR}backup_iobroker_skripts.sh" 2>/dev/null || echo "Neue Version")
        git_commit_push "Backup-Skript aktualisiert" "${DIFF_CONTENT}"
    fi
    echo "Backup-Skript aktualisiert"
}

# Sicherstellen, dass das Zielverzeichnis existiert und Git initialisiert ist
mkdir -p "${TARGET_DIR}"
git_init

# Nach Git-Init das Skript initial sichern
backup_self

# Ueberwache auch das Skript selbst im Hintergrund
(inotifywait -m -e modify "${SCRIPT_PATH}" | while read path action file
do
    backup_self
done) &

# Beim ersten Start alle Inhalte kopieren
if [ ! -f "${TARGET_DIR}.initialized" ]; then
    echo "Erster Start: Alle Dateien werden gesichert"
    
    # Fuer jede .js Datei im Quellverzeichnis
    find "${SOURCE_DIR}" -type f -name "*.js" -o -name "*.ts"| while read FILE; do
        REL_PATH=$(realpath --relative-to="${SOURCE_DIR}" "${FILE}")
        REL_DIR=$(dirname "${REL_PATH}")
        SCRIPT_NAME=$(basename "${FILE}")
        EXTENSION="${SCRIPT_NAME##*.}"
        SCRIPT_NAME=$(basename "${SCRIPT_NAME}" ".$EXTENSION")
        
        if [ "$USE_VERSIONS" = true ]; then
            SCRIPT_DIR="${TARGET_DIR}${REL_DIR}/${SCRIPT_NAME}/"
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            BACKUP_FILE="${SCRIPT_DIR}${SCRIPT_NAME}_${TIMESTAMP}.${EXTENSION}"
        else
            SCRIPT_DIR="${TARGET_DIR}${REL_DIR}/"
            BACKUP_FILE="${SCRIPT_DIR}${SCRIPT_NAME}.${EXTENSION}"
        fi
        
        mkdir -p "${SCRIPT_DIR}"
        sanitize_file "${FILE}" "${BACKUP_FILE}"
        echo "Initiales Backup erstellt: ${BACKUP_FILE}"
    done
    
    if [ "$USE_GIT" = true ]; then
        git_commit_push "Initiales Backup aller Skripte $(date +%Y-%m-%d)"
    fi
    
    touch "${TARGET_DIR}.initialized"
    echo "Erstsicherung abgeschlossen!"
fi

# Hauptschleife: Ueberwache Aenderungen im Quellverzeichnis
inotifywait -m -r -e modify,create,delete "${SOURCE_DIR}" --format '%w%f' | while read FILE
do
    # Nur .js Dateien verarbeiten
    if [[ "${FILE}" != *.js && "${FILE}" != *.ts ]]; then
        continue
    fi

    # Zielstruktur aufbauen
    REL_PATH=$(realpath --relative-to="${SOURCE_DIR}" "${FILE}")
    REL_DIR=$(dirname "${REL_PATH}")
    SCRIPT_NAME=$(basename "${FILE}")
    EXTENSION="${SCRIPT_NAME##*.}"
    SCRIPT_NAME=$(basename "${SCRIPT_NAME}" ".$EXTENSION")
    
    if [ "$USE_VERSIONS" = true ]; then
        SCRIPT_DIR="${TARGET_DIR}${REL_DIR}/${SCRIPT_NAME}/"
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        BACKUP_FILE="${SCRIPT_DIR}${SCRIPT_NAME}_${TIMESTAMP}.${EXTENSION}"
    else
        SCRIPT_DIR="${TARGET_DIR}${REL_DIR}/"
        BACKUP_FILE="${SCRIPT_DIR}${SCRIPT_NAME}.${EXTENSION}"
    fi

    # Wenn die Datei existiert, sichere sie
    if [ -f "${FILE}" ]; then
        mkdir -p "${SCRIPT_DIR}"
        sanitize_file "${FILE}" "${BACKUP_FILE}"
        echo "Gespeichert: ${BACKUP_FILE}"
        
        if [ "$USE_VERSIONS" = true ]; then
            # Alte Versionen aufraeumen
            BACKUP_FILES=($(ls -t "${SCRIPT_DIR}"*.js 2>/dev/null))
            if [ ${#BACKUP_FILES[@]} -gt $MAX_BACKUPS ]; then
                for ((i=${MAX_BACKUPS}; i<${#BACKUP_FILES[@]}; i++)); do
                    echo "Alte Version wird geloescht: ${BACKUP_FILES[i]}"
                    rm -f "${BACKUP_FILES[i]}"
                done
            fi
        fi
        
        # Git Commit wenn aktiviert
        if [ "$USE_GIT" = true ]; then
            DIFF_CONTENT=$(diff "${FILE}" "${BACKUP_FILE}" 2>/dev/null || echo "Neue Datei")
            git_commit_push "Update ${SCRIPT_NAME}" "${DIFF_CONTENT}"
            echo "Aenderungen auf GitHub hochgeladen"
        fi
    else
        echo "Datei geloescht oder nicht verfuegbar: ${FILE}"
        if [ "$USE_GIT" = true ]; then
            git_commit_push "Datei ${SCRIPT_NAME} geloescht"
        fi
    fi
done
