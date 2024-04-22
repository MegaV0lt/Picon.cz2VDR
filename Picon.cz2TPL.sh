#!/bin/env bash

# Skript zum erstellen von TPL-Logos für OSCam. Logos im PNG-Format von picon.cz
# Update der Logos erfolgt ein mal pro Woche

# Die Logos liegen im PNG-Format vor
# Es müssen die Varialen 'LOGODIR', 'LOGO_TYPE', 'LOGO_SIZE' und 'LOGO_PACKAGE'
# angepasst werden. Das Skript am besten ein mal pro Woche ausführen (/etc/cron.weekly)
VERSION=240331

# Sämtliche Einstellungen werden in der *.conf vorgenommen
# ---> Bitte ab hier nichts mehr ändern! <---

### Variablen
SELF="$(readlink /proc/$$/fd/255)" || SELF="$0"  # Eigener Pfad (besseres $0)
SELF_NAME="${SELF##*/}"
PICON_URL='https://picon.cz/download-picons'  #/picon-transparent-220x132/'
USER_AGENT='Mozilla/5.0 (Linux x86_64; rv:103.0) Gecko/20100101 (vdr-picon-script) Firefox/103.0'
WGET_OPT=('--cookies=on' --keep-session-cookies --quiet "--user-agent=$USER_AGENT")
msgERR='\e[1;41m FEHLER! \e[0;1m' ; nc='\e[0m'   # Anzeige "FEHLER!"
msgINF='\e[42m \e[0m' ; msgWRN='\e[103m \e[0m'   # " " mit grünem/gelben Hintergrund
printf -v RUNDATE '%(%d.%m.%Y %R)T' -1  # Aktuelles Datum und Zeit
declare -A DL_INDEX BUILD_INDEX         # Download-Links für die Logopakete und Erstellungs Datum

### Funktionen
f_log() {     # Gibt die Meldung auf der Konsole und im Syslog aus
  local logger=(logger --tag "$SELF_NAME") msg="${*:2}"
  case "${1^^}" in
    'ERR'*|'FATAL') if [[ -t 2 ]] ; then
                      echo -e "$msgERR ${msg:-$1}${nc}" >&2
                    else
                      "${logger[@]}" --priority user.err "$*"
                      echo "FEHLER: ${msg:-$1}" >&2  # Für cron eMails
                    fi ;;
    'WARN'*) [[ -t 1 ]] && { echo -e "$msgWRN ${msg:-$1}" ;} || "${logger[@]}" "$*" ;;
    'DEBUG') [[ -t 1 ]] && { echo -e "\e[1m${msg:-$1}${nc}" ;} || "${logger[@]}" "$*" ;;
    'INFO'*) [[ -t 1 ]] && { echo -e "$msgINF ${msg:-$1}" ;} || "${logger[@]}" "$*" ;;
    *) [[ -t 1 ]] && { echo -e "$*" ;} || "${logger[@]}" "$*" ;;  # Nicht angegebene
  esac
  [[ -n "$LOGFILE" && -w "$LOGFILE" ]] && printf '%(%d.%m.%Y %T)T: %b\n' -1 "$*" >> "$LOGFILE"  # Log in Datei
}

f_extract_links() {
  local build package url tmpsrc='/tmp/~websrc.htm' websrc="$1"
  local re_url='picon.cz/download/(.*)/' re_name='picon(.*)_by_chocholousek.7z'
  local re_build='Build ([0-9]*)'
  # Seite laden
  if [[ ! "$websrc" =~ picon-transparent-220x132 ]] ; then
    websrc="${websrc/picon-/picon}"  # Workaround
  fi
  wget "${WGET_OPT[@]}" --load-cookies="${SRC_DIR}/cookie.txt" --referer="$PICON_URL" \
    --output-document="$tmpsrc" "$websrc"

  while read -r ; do  # BUILD und URL in 1. Zeile, NAME in der 2. Zeile
    if [[ "$REPLY" =~ $re_url ]] ; then  # In der Zeile enthalten
      [[ -n "$url" ]] && f_log WARN "Download-Link ohne Name gefunden! (/download/${url})"
      url="${BASH_REMATCH[1]}"  # 1125
      if [[ "$REPLY" =~ $re_build ]] ; then
        build="${BASH_REMATCH[1]}"  # 230105
      fi
      continue
    fi
    if [[ "$REPLY" =~ $re_name ]] ; then  # In der Zeile enthalten
      package="${BASH_REMATCH[1]}"  # simpleblack-220x132-30.0W
      if [[ -n "$url" ]] ; then
        DL_INDEX+=([$package]=${url})
        BUILD_INDEX+=([$package]=${build})
        unset -v 'build' 'url'
      else
        f_log WARN "Kein Download-Link für Paket $package gefunden!"
      fi
    fi
  done < "$tmpsrc"
}

f_check_build_date() {  # Erstelldatum einlesen und mit prüfen, ob älter als die geladene…
  local prev_build="${SRC_DIR}/${LOGO_ARCH}.build" prev_build_date
  [[ -z "$BUILD_DATE" ]] && { f_log ERR "BUILD_DATE ist leer! (${LOGO_ARCH})" ; return 1 ;}
  if [[ -e "$prev_build" ]] ; then
    read -r prev_build_date < "$prev_build"
    if [[ "$prev_build_date" -lt "$BUILD_DATE" ]] ; then
      echo "$BUILD_DATE" > "$prev_build"
    else
      return 1  #  Palket nicht laden
    fi
  else
    echo "$BUILD_DATE" > "$prev_build"  # Datei erstellen
  fi
  return 0  # Paket laden
}

### Start
SCRIPT_TIMING[0]=$SECONDS  # Startzeit merken (Sekunden)

# Testen, ob Konfiguration angegeben wurde (-c …)
while getopts ":c:" opt ; do
  case "$opt" in
    c) if [[ -f "${CONFIG:=$OPTARG}" ]] ; then  # Konfig wurde angegeben und existiert
         # shellcheck source=Picon.cz2TPL.conf.dist
         source "$CONFIG" ; CONFLOADED='Angegebene' ; break
       else
         f_log ERR "Fehler! Die angegebene Konfigurationsdatei fehlt! (\"${CONFIG}\")"
         exit 1
       fi ;;
    ?) ;;
  esac
done

# Konfigurationsdatei laden [Wenn Skript=mp_logos.sh Konfig=mp_logos.conf]
if [[ -z "$CONFLOADED" ]] ; then  # Konfiguration wurde noch nicht geladen
  # Suche Konfig im aktuellen Verzeichnis, im Verzeichnis des Skripts und im eigenen etc
  CONFIG_DIRS=('.' "${SELF%/*}" "${HOME}/etc" "${0%/*}") ; CONFIG_NAME="${SELF_NAME%.*}.conf"
  for dir in "${CONFIG_DIRS[@]}" ; do
    CONFIG="${dir}/${CONFIG_NAME}"
    if [[ -f "$CONFIG" ]] ; then
      # shellcheck source=Picon.cz2VDR.conf.dist
      source "$CONFIG" ; CONFLOADED='Gefundene'
      break  # Die erste gefundene Konfiguration wird verwendet
    fi
  done
  if [[ -z "$CONFLOADED" ]] ; then  # Konfiguration wurde nicht gefunden
    f_log ERR "Fehler! Keine Konfigurationsdatei gefunden! (\"${CONFIG_DIRS[*]}\")"
    exit 1
  fi
fi

f_log INFO "==> $RUNDATE - $SELF_NAME #${VERSION} - Start…"
f_log INFO "$CONFLOADED Konfiguration: ${CONFIG}"

# Benötigte Programme vorhanden?
needprogs=(7z find sort stat wget)
for prog in "${needprogs[@]}" ; do
  type "$prog" &>/dev/null || MISSING+=("$prog")
done
if [[ -n "${MISSING[*]}" ]] ; then  # Fehlende Programme anzeigen
  f_log ERR "$msgERR Sie benötigen \"${MISSING[*]}\" zur Ausführung dieses Skriptes!"
  exit 1
fi

# Benötigte Variablen prüfen
for var in LOGODIR ; do
  [[ -z "${!var}" ]] && { f_log ERROR "Variable $var ist nicht gesetzt!" ; exit 1 ;}
done

SRC_DIR="${LOGODIR}/.source"  # Verzeichnis für PIcon Pakete und Cookies
LOGO_PATH="${SRC_DIR}/Logos"  # Alle Logos in das gleiche Verzeichnis
if [[ ! -d "$LOGO_PATH" ]] ; then
  mkdir --parents "$LOGO_PATH" || { f_log ERR "Fehler beim erstellen von $LOGO_PATH" ; exit 1 ;}
fi

# Alte Dateien löschen
f_log INFO "Lösche alte Daten aus ${SRC_DIR}…"
{ find "$SRC_DIR" -name '*.build' -name '*.7z' -type f -mtime +30 -print -delete  # Alte Pakete
  find "$LOGO_PATH" -name '*.png' -type f -mtime +30 -print -delete               # Alte Logos
} 2>/dev/null >> "${LOGFILE:-/dev/null}"

# Vorgaben
: "${LOGO_TYPE:=transparent}" ; : "${LOGO_SIZE:=220x132}"
[[ -z "${LOGO_PACKAGE[*]}" ]] && LOGO_PACKAGE=(19.2E)

# 1. Aufruf der Seite um Cookie zu erhalten
wget "${WGET_OPT[@]}" --save-cookies="${SRC_DIR}/cookie.txt" \
  --output-document="${SRC_DIR}/download-picons.html" "${PICON_URL}/"

# Seite mit den Links laden und Links extrahieren
f_extract_links "${PICON_URL}/picon-${LOGO_TYPE}-${LOGO_SIZE}"

for package in "${LOGO_PACKAGE[@]}" ; do
  # Archivname und Downloadlink festlegen
  LOGO_ARCH="${LOGO_TYPE}-${LOGO_SIZE}-${package}"  # transparent-220x132-19.2E
  DL_URL="${DL_INDEX[${LOGO_ARCH}]}"                # 1125
  [[ -z "$DL_URL" ]] && { f_log ERR "Download-Link für $LOGO_ARCH nicht gefunden!" ; exit 1 ;}
  BUILD_DATE="${BUILD_INDEX[${LOGO_ARCH}]}"         # 230105

  # Erstelldatum einlesen und mit prüfen, ob älter als die geladene…
  if f_check_build_date ; then
    # Laden der Datei
    f_log INFO "Lade Logo-Paket für ${package}…"
    wget "${WGET_OPT[@]}" --load-cookies="${SRC_DIR}/cookie.txt" --referer="$PICON_URL" \
      --output-document="${SRC_DIR}/${LOGO_ARCH}.7z" "https://picon.cz/download/${DL_URL}"

    # Archiv Entpacken
    f_log INFO "Entpacke Logo-Paket für ${package}…"
    if ! 7z e -bd -o"${LOGO_PATH}/" "${SRC_DIR}/${LOGO_ARCH}.7z" -y 2>/dev/null >> "${LOGFILE:-/dev/null}" ; then
      f_log ERR "Fehler beim entpacken von ${SRC_DIR}/${LOGO_ARCH}.7z"
      exit 1
    fi
  else
    f_log INFO "Logopaket ${LOGO_ARCH}.7z ist bereits aktuell! (Erstelldatum: ${BUILD_DATE})"
  fi  # stat
done  # LOGO_PACKAGE

# Picon zuordnen und nach TPL konvertieren
for logo in "${LOGO_PATH}"/*.png ; do
  IFS='_' read -r -a PICON <<< "$logo"
  while [[ "${#PICON[3]}" -lt 4 ]] ; do
    PICON[3]="0${PICON[3]}"  # Führende 0 hinzufügen
  done
  TPL_FILE="IC_0000_${PICON[3]}.tpl"

  if [[ "$logo" -nt "${LOGODIR}/${TPL_FILE}" ]] ; then
    f_log "Konvertiere ${logo}…"
    # The "GIMP" default (radius=6, amount=0.5, threshold=0) for unsharp is equivalent to "-unsharp 12x6+0.5+0",
    # and this is correct (other than ignoring that GIMP sets a hard radius at twice sigma). However remember you
    # really do not need to specify the kernel radius in ImageMagick, so a value of "-unsharp 0x6+0.5+0" will work better.
    { echo -n 'data:image/png;base64,'
      convert "$logo" -adaptive-resize "${TPL_SIZE:=100x60}" -unsharp 0x6+0.5+0 PNG32:- | base64 -i -w 0
    } > "${LOGODIR}/${TPL_FILE}"
  fi
done

# Statistik anzeigen
SCRIPT_TIMING[2]=$SECONDS  # Zeit nach der Statistik
SCRIPT_TIMING[10]=$((SCRIPT_TIMING[2] - SCRIPT_TIMING[0]))  # Gesamt
f_log "==> Skriptlaufzeit: $((SCRIPT_TIMING[10] / 60)) Minute(n) und $((SCRIPT_TIMING[10] % 60)) Sekunde(n)"

if [[ -e "$LOGFILE" ]] ; then  # Log-Datei umbenennen, wenn zu groß
  FILESIZE="$(stat --format=%s "$LOGFILE" 2>/dev/null)"
  [[ $FILESIZE -gt $MAXLOGSIZE ]] && mv --force "$LOGFILE" "${LOGFILE}.old"
fi

exit 0
