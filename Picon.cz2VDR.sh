#!/bin/env bash

# Skript zum verlinken der PICON-Kanallogos (Enigma2) von https://picon.cz
# Update der Logos erfolgt ein mal pro Woche

# Die Dateinamen der Logos passen nicht zum VDR-Schema. Darum erzeugt das Skript
# aus der 'channels.conf' so genannte Service-Namen (PICON), um die Logos dann
# passend zu verlinken. Im Logoverzeichnis des Skins liegen dann nur Symlinks

# Die Logos liegen im PNG-Format vor
# Es müssen die Varialen 'LOGODIR' und 'CHANNELSCONF' angepasst werden
# Das Skript am besten ein mal pro Woche ausführen (/etc/cron.weekly)
VERSION=250520

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
declare -A DL_INDEX BUILD_INDEX         # Download-Links für die Logopakete und Erstalldatum

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
  # Sicherheits-Check: $tmpsrc darf nicht leer sein und muss in /tmp/ liegen
  if [[ -n "$tmpsrc" && "$tmpsrc" == /tmp/* && -f "$tmpsrc" ]]; then
    rm --force "$tmpsrc" || f_log ERR "Fehler beim löschen von $tmpsrc"
  else
    f_log ERR "Sicherheits-Check fehlgeschlagen: $tmpsrc wird nicht gelöscht!"
  fi

  if ! wget "${WGET_OPT[@]}" --load-cookies="${SRC_DIR}/cookie.txt" --referer="$PICON_URL" \
                             --output-document="$tmpsrc" "$websrc"; then
    f_log ERR "Fehler beim Download! (${websrc})"
  fi

  while read -r ; do  # URL in 1. Zeile, NAME in der 2. Zeile
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
    if [[ "$prev_build_date" -ne "$BUILD_DATE" ]] ; then  # Just compare because 700101 can happen
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
         # shellcheck source=Picon.cz2VDR.conf.dist
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
needprogs=(7z bc find sort stat wget)
for prog in "${needprogs[@]}" ; do
  type "$prog" &>/dev/null || MISSING+=("$prog")
done
if [[ -n "${MISSING[*]}" ]] ; then  # Fehlende Programme anzeigen
  f_log ERR "Sie benötigen \"${MISSING[*]}\" zur Ausführung dieses Skriptes!"
  exit 1
fi

# Benötigte Variablen prüfen
for var in CHANNELSCONF LOGODIR ; do
  [[ -z "${!var}" ]] && { f_log ERROR "Variable $var ist nicht gesetzt!" ; exit 1 ;}
done

SRC_DIR="${LOGODIR}/.source"  # Verzeichnis für PIcon Pakete und Cookies
LOGO_PATH="${SRC_DIR}/Logos"  # Alle Logos in das gleiche Verzeichnis
if [[ ! -d "$LOGO_PATH" ]] ; then
  mkdir --parents "$LOGO_PATH" || { f_log ERR "Fehler beim erstellen von $LOGO_PATH" ; exit 1 ;}
fi

# Alte Dateien löschen
f_log INFO "Lösche alte Daten aus ${SRC_DIR}…"
{ find "$SRC_DIR" \( -name '*.build' -o -name '*.7z' \) -type f -mtime +360 -print -delete  # Alte Pakete
  find "$LOGO_PATH" -name '*.png' -type f -mtime +360 -print -delete               # Alte Logos
  find "$LOGODIR" -type d -empty -mtime +360 -print -delete                        # Leere Verzeichnisse löschen
} 2>/dev/null >> "${LOGFILE:-/dev/null}"

if [[ -f "$CHANNELSCONF" ]] ; then
  mapfile -t channelsconf < "$CHANNELSCONF"         # Kanalliste in Array einlesen
else
  f_log ERR "Datei $CHANNELSCONF nicht gefunden!" ; exit 1
fi

# Vorgaben
: "${LOGO_TYPE:=transparent}" ; : "${LOGO_SIZE:=220x132}"
[[ -z "${LOGO_PACKAGE[*]}" ]] && LOGO_PACKAGE=(19.2E)

# Alle Symlinks im Logoverzeichnis löschen
find "$LOGODIR" -type l -delete

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

  # Build-Datum prüfen
  # # Erstelldatum einlesen und mit prüfen, ob älter als die geladene…
  if f_check_build_date ; then
    optimize='true'  # Nur bei neuen Logos optimieren

    # Laden der Datei
    f_log INFO "Lade Logo-Paket für ${package}…"
    wget "${WGET_OPT[@]}" --load-cookies="${SRC_DIR}/cookie.txt" --referer="$PICON_URL" \
      --output-document="${SRC_DIR}/${LOGO_ARCH}.7z" "https://picon.cz/download/${DL_URL}"

    # Prüfen, ob die Datei existiert und nicht leer ist
    if [[ ! -s "${SRC_DIR}/${LOGO_ARCH}.7z" ]]; then
      f_log ERR "Download fehlgeschlagen oder Datei ist leer: ${SRC_DIR}/${LOGO_ARCH}.7z"
      exit 1
    fi

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

if [[ "$optimize" == 'true' ]] ; then  # Logos optimieren
  if type pngquant &>/dev/null ; then
    f_log INFO "Optimiere Logos mit pngquant…"
    for logo in "${LOGO_PATH}"/*.png ; do
      pngquant --ext .png --force --skip-if-larger --strip "$logo" >> "${LOGFILE:-/dev/null}"
    done
  else
    f_log WARN 'pngquant nicht gefunden. Logos werden nicht optimiert!'
  fi
fi

# Kanalname den Picon zuordnen und verlinken
for i in "${!channelsconf[@]}" ; do
  [[ "${channelsconf[i]:0:1}" == : ]] && { ((grp++)) ; continue ;}     # Kanalgruppe
  [[ "${channelsconf[i]}" =~ OBSOLETE ]] && { ((obs++)) ; continue ;}  # Als 'OBSOLETE' markierter Kanal
  [[ "${channelsconf[i]%%;*}" == '.' ]] && { ((bl++)) ; continue ;}    # '.' als Kanalname
  unset -v 'sid' 'tid' 'nid' 'namespace' 'channeltype' 'servicename'
  ((cnt++)) ; [[ -t 1 ]] && echo -ne "$msgINF Prüfe Kanal #${cnt}"\\r
  IFS=':' read -r -a vdrchannel <<< "${channelsconf[i]}"               # DELUXE MUSIC,DELUXE;BetaDigital

  case ${vdrchannel[3]} in
    *'W') namespace=$(bc -l <<< "scale=0 ; 3600 - ${vdrchannel[3]//[^0-9.]} * 10")
          printf -v namespace '%X' "${namespace%.*}" ;;
    *'E') namespace=$(bc -l <<< "scale=0 ; ${vdrchannel[3]//[^0-9.]} * 10")
          printf -v namespace '%X' "${namespace%.*}" ;;
     'T') namespace='EEEE' ;;
     'C') namespace='FFFF' ;;
       *) f_log WARN "Unbekannte Empfangsart: ${vdrchannel[3]} (${vdrchannel[0]})"
          ((nologo++)) ; continue ;;
  esac
  case ${vdrchannel[5]} in      # Info: Service_Reference_Code.txt
      '0') channeltype='2' ;;   # Radio
    *'=2') channeltype='1' ;;   # MPEG2 (SD) Alternativ 16 MPEG (SD)
   *'=27') channeltype='19' ;;  # H.264 (HD)
   *'=36') channeltype='1F' ;;  # H.265 (UHD)
        *) f_log WARN "Unbekannter Kanaltyp (VPID): ${vdrchannel[5]} (${vdrchannel[0]})"
           ((nologo++)) ; continue ;;
  esac

  printf -v sid '%X' "${vdrchannel[9]}"
  printf -v tid '%X' "${vdrchannel[11]}"
  printf -v nid '%X' "${vdrchannel[10]}"

  unique_id="${sid:=NULL}_${tid:=NULL}_${nid:=NULL}_${namespace}"
  serviceref="1_0_${channeltype}_${unique_id}0000_0_0_0"
  IFS=';' read -r -a channelname <<< "${vdrchannel[0]}"
  vdr_channelname="${channelname[0]%,*}"       # Kanalname ohne Kurzname (DELUXE MUSIC)

  # Kanalname: $vdr_channelname PICON: ${serviceref}.png
  logohist+=("$vdr_channelname -> $serviceref")

  # Kanal verlinken, wenn Logo existiert
  if [[ -e "${LOGO_PATH}/${serviceref}.png" ]] ; then  # Picon vorhanden?
    case "${TOLOWER^^}" in
      'A-Z') servicename="${vdr_channelname,,[A-Z]}" ;;  # In Kleinbuchstaben (Außer Umlaute)
      'FALSE') servicename="$vdr_channelname" ;;         # Nicht umwandeln
      *) servicename="${vdr_channelname,,}" ;;           # Alles in kleinbuchstaben (ALL und Leer)
    esac
    servicename="${servicename//|/:}"          # Kanal mit | im Namen
    if [[ "$servicename" =~ / ]] ; then        # Kanal mit / im Namen
      ch_path="${servicename%/*}"              # Der Teil vor dem lezten /
      mkdir --parents "${LOGODIR}/${ch_path}" \
        || f_log ERROR "Ordner ${LOGODIR}/${ch_path} konnte nicht erstellt werden!"
    fi
    if [[ -e "${LOGODIR}/${servicename}.png" ]] ; then
      f_log WARN "Symlink für ${LOGODIR}/${servicename}.png wurde bereits erstellt!"
      ((double++))
    else
      # Symlink erstellen       v Quelle                         v Ziel (Linkname)
      ln --relative --symbolic "${LOGO_PATH}/${serviceref}.png" "${LOGODIR}/${servicename}.png"
      ((symlink++))
    fi  # -e servicename.png
  else
    f_log WARN "Logo ${LOGO_PATH}/${serviceref}.png nicht gefunden (${vdr_channelname})"
    nologo+=("$vdr_channelname -> $serviceref")  # Nicht gefundene Logos
  fi
done  # CHANNELSCONF

# Eigentümer und Berechtigungen setzen
chown --no-dereference --recursive "${LOGO_USER:-vdr}:${LOGO_GROUP:-vdr}" "$LOGODIR" 2> "${LOGFILE:-/dev/null}" \
  || f_log ERR "Eigentümer/Gruppe ${LOGO_USER:-vdr}:${LOGO_GROUP:-vdr} konnte nicht gesetzt werden!"
chmod --recursive 644 "${LOGODIR}"/*.png 2> "${LOGFILE:-/dev/null}" \
  || f_log ERR "Berechtigungen ${LOGODIR} konnten nicht gesetzt werden!"

# Zupordnungen in Liste speichern
if [[ -n "$LOGO_HIST" ]] ; then
  f_log INFO "Speichere Zuordnungen in ${LOGO_HIST}…"
  [[ ! "$LOGO_HIST" =~ / ]] && LOGO_HIST="${SRC_DIR}/${LOGO_HIST}"
  if [[ -f "$LOGO_HIST" ]] ; then
    mapfile -t logo_hist < "$LOGO_HIST"  # Vorherige Daten einlesen
    logohist+=("${logo_hist[@]}")        # Aktuelle hinzufügen
  fi
  printf '%s\n' "${logohist[@]}" | sort --unique > "$LOGO_HIST"  # Neue DB schreiben
fi

printf '%s\n' "${nologo[@]}" | sort --unique > "${SRC_DIR}/No_Logo.txt"  # Nicht gefundene Logos

# Statistik anzeigen
[[ "${#nologo[@]}" -gt 0 ]] && f_log "==> ${#nologo[@]} Kanäle ohne Logo"
[[ "$double" -gt 0 ]] && f_log "==> $double Kanäle mit unterschiedlichen Logos"
[[ "$obs" -gt 0 || "$bl" -gt 0 ]] && f_log "==> Übersprungen: 'OBSOLETE' (${obs:-0}), '.' (${bl:-0})"
f_log "==> ${symlink:-0} verlinkte Logos"
SCRIPT_TIMING[2]=$SECONDS  # Zeit nach der Statistik
SCRIPT_TIMING[10]=$((SCRIPT_TIMING[2] - SCRIPT_TIMING[0]))  # Gesamt
f_log "==> Skriptlaufzeit: $((SCRIPT_TIMING[10] / 60)) Minute(n) und $((SCRIPT_TIMING[10] % 60)) Sekunde(n)"

if [[ -e "$LOGFILE" ]] ; then  # Log-Datei umbenennen, wenn zu groß
  FILESIZE="$(stat --format=%s "$LOGFILE" 2>/dev/null)"
  [[ $FILESIZE -gt $MAXLOGSIZE ]] && mv --force "$LOGFILE" "${LOGFILE}.old"
fi

exit 0
