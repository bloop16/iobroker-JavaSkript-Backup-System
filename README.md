# ioBroker Skript Backup System

Automatisches Backup-System für ioBroker JavaScript-Dateien mit Versionskontrolle, GitHub-Integration und Schutz vor sensiblen Daten.

## Funktionen

- 🔄 Automatische Sicherung von JavaScript-Dateien aus ioBroker
- 📁 Beibehaltung der originalen Ordnerstruktur
- ⏱️ Optionale Versionskontrolle mit Zeitstempeln
- 🔧 Konfigurierbare Anzahl von Backup-Versionen (optional)
- 🔒 Automatische Schwärzung von Passwörtern und sensitiven Daten
- 🔑 Schutz sensitiver Zugangsdaten
- 📥 Git-Integration mit automatischen Commits (optional)
- 🔄 Echtzeit-Dateiüberwachung
- 🗑️ Automatische Bereinigung alter Versionen (optional)

## Voraussetzungen

- Linux-System mit Bash-Shell
- Git installiert (optional)
- inotify-tools Paket
- SSH-Zugang zu GitHub (optional)
- GitHub-Konto (optional)

## Funktionen im Detail

### Initiales Backup

- Erstellt komplettes Backup aller .js Dateien
- Behält originale Verzeichnisstruktur bei
- Initialisiert Git-Repository (optional)
- Führt initialen Commit auf GitHub durch (optional)

### Kontinuierliche Überwachung

- Überwacht Dateiänderungen in Echtzeit
- Erstellt neues Backup bei Dateiänderung
- Behält konfigurierte Anzahl von Versionen (optional)
- Committet Änderungen automatisch zu GitHub (optional)

### Versionskontrolle (optional)

- Jedes Backup enthält Zeitstempel
- Behält konfigurierte Anzahl von Versionen
- Entfernt älteste Versionen automatisch
- Git-Commit-Nachrichten enthalten:
  - Skriptname
  - Zeitstempel
  - Vorgenommene Änderungen

### Sensitive Daten

- Erkennt und schwärzt Passwörter, API-Keys und andere sensible Daten in JavaScript-Dateien.
Variablen (```const, Var, let```), Direktzuweisungen, Objekt-Eigenschaften, Json Style wird auf folgende Textphrasen überprüft:
   * ```password```
   * ```pass```
   * ```passwort```
   * ```passwd```
   * ```user```
   * ```benutzer```
   * ```apikey```
   * ```secret```


## Installation

1. Skript herunterladen:
   ```bash
   sudo wget -O /usr/local/bin/backup_iobroker_skripts.sh https://github.com/bloop16/iobroker-JavaSkript-Backup-System/blob/v1.0.0/backup_iobroker_skripts
   ```

2. Skript ausführbar machen:
```bash
sudo chmod +x /usr/local/bin/backup_iobroker_skripts.sh
```

3. Benötigte Pakete installieren:
```bash
sudo apt-get update
sudo apt-get install git inotify-tools
```

4. JavaSkript Adapter Spiegelungen Aktivieren
In den Einstellungen des JavaSkript Adapters muss die Spiegelung aktiviert werden. Der Dafür eingetragene Ordner ist in den den Skript Konfigurationen anzupassen. ```SOURCE_DIR```


4. SSH-Schlüssel für GitHub generieren (optional):
```bash
ssh-keygen -t ed25519 -C "ihre-github-email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

5. SSH-Schlüssel zu GitHub hinzufügen (optional):
   - Öffentlichen Schlüssel kopieren:
     ```bash
     cat ~/.ssh/id_ed25519.pub
     ```
   - GitHub → Einstellungen → SSH und GPG Schlüssel
   - "Neuer SSH-Schlüssel" klicken
   - Kopierten Schlüssel einfügen
   - Mit Titel "IobrokerBackup" speichern

6. GitHub-Repository erstellen (optional):
   - Name: `Repository Name`
     

## Konfiguration

Bei Bedarf folgende Variablen im Skript anpassen:

```bash
SOURCE_DIR="/opt/iobroker/skriptMirror/"
TARGET_DIR="/opt/iobroker/backupSkripts/"
REPO_NAME="[RepoName]"
GITHUB_USER="[UserName]"
SCRIPT_PATH="/usr/local/bin/backup_iobroker_skripts.sh"

MAX_BACKUPS=10           # Maximale Anzahl der Backups pro Skript (nur bei USE_VERSIONS=true)
USE_GIT=true            # Git-Integration aktivieren/deaktivieren
USE_VERSIONS=true       # Versionierung mit Zeitstempeln aktivieren/deaktivieren
```

## Verzeichnisstruktur

**Mit Versionskontrolle (USE_VERSIONS=true):**

```
/opt/iobroker/backupSkripts/
└── pfad/zum/skript/
    └── skriptname/
        ├── skriptname_20250406_123456.js
        ├── skriptname_20250406_123789.js
        └── ...
```

**Ohne Versionskontrolle (USE_VERSIONS=false):**

```
/opt/iobroker/backupSkripts/
└── pfad/zum/skript/
    └── skriptname.js
```

## Installation als Systemdienst

1. Systemd Service-Datei erstellen:
```bash
sudo nano /etc/systemd/system/backup-iobroker-skripts.service
```

2. Folgenden Inhalt in die Service-Datei einfügen:
```ini
[Unit]
Description=ioBroker Scripts Backup Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/backup_iobroker_skripts.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

3. Systemd neu laden und Service aktivieren:
```bash
# Systemd neu laden
sudo systemctl daemon-reload

# Service aktivieren (Start bei Boot)
sudo systemctl enable backup-iobroker-skripts.service

# Service starten
sudo systemctl start backup-iobroker-skripts.service
```

4. Service-Status überprüfen:
```bash
sudo systemctl status backup-iobroker-skripts.service
```
