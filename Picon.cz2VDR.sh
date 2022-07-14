#!/bin/env bash

# Skript zum verlinken der PICON-Kanallogos (Enigma2)

# Die Dateinamen passen nicht zum VDR-Schema. Darum erzeugt das Skript
# aus der 'channels.conf' so genannte Service-Namen (PICON), um die Logos dann
# passend zu verlinken. Im Logoverzeichnis des Skins liegen dann nur Symlinks.

# Die Logos liegen im PNG-Format vor.
# Es müssen die Varialen 'LOGODIR' und 'CHANNELSCONF' angepasst werden.
# Das Skript am besten ein mal pro Woche ausführen (/etc/cron.weekly)
VERSION=220714

# Sämtliche Einstellungen werden in der *.conf vorgenommen.
# ---> Bitte ab hier nichts mehr ändern! <---

### Variablen
SELF="$(readlink /proc/$$/fd/255)" || SELF="$0"  # Eigener Pfad (besseres $0)
SELF_NAME="${SELF##*/}"
PICON_URL='https://picon.cz/download-picons'  #/picon-transparent-220x132/'
USER_AGENT='Mozilla/5.0 (Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0'
WGET_OPT=('--cookies=on' --keep-session-cookies --quiet "--user-agent=$USER_AGENT")
msgERR='\e[1;41m FEHLER! \e[0;1m' ; nc='\e[0m'   # Anzeige "FEHLER!"
msgINF='\e[42m \e[0m' ; msgWRN='\e[103m \e[0m'   # " " mit grünem/gelben Hintergrund
printf -v RUNDATE '%(%d.%m.%Y %R)T' -1  # Aktuelles Datum und Zeit
printf -v NOW '%(%s)T' -1               # Aktuelle Zeit in Sekunden

# Download-Links für die Logopakete (Transparent 220x132, ...)
declare -A DL_INDEX=(
[transparent_220x132_skylink]=1211 [transparent_220x132_freeSAT]=1206 [transparent_220x132_digiczsk]=1199
[transparent_220x132_antiksat]=1197 [transparent_220x132_dvbtCZSK]=1204 [transparent_220x132_DTTitaly]=1202
[transparent_220x132_9.0E]=1094 [transparent_220x132_81.5E]=1195 [transparent_220x132_85.0E]=1193
[transparent_220x132_8.0W]=1092 [transparent_220x132_75.0E]=1190 [transparent_220x132_74.9E]=1188
[transparent_220x132_70.5E]=1186 [transparent_220x132_7.0W]=1090 [transparent_220x132_7.0E]=1087
[transparent_220x132_68.5E]=1184 [transparent_220x132_66.0E]=1182 [transparent_220x132_62.0E]=1180
[transparent_220x132_56.0E]=1177 [transparent_220x132_54.9E]=1175 [transparent_220x132_53.0E]=1173
[transparent_220x132_52.5E]=1171 [transparent_220x132_52.0E]=1168 [transparent_220x132_51.5E]=1166
[transparent_220x132_5.0W]=1085 [transparent_220x132_46.0E]=1164 [transparent_220x132_45.0W]=1161
[transparent_220x132_45.0E]=1159 [transparent_220x132_42.0E]=1157 [transparent_220x132_4.9E]=1083
[transparent_220x132_4.8E]=1081 [transparent_220x132_4.0W]=1079 [transparent_220x132_39.0E]=1155
[transparent_220x132_36.0E]=1153 [transparent_220x132_33.0E]=1151 [transparent_220x132_31.5E]=1149
[transparent_220x132_30.5E]=1147 [transparent_220x132_30.0W]=1145 [transparent_220x132_3.1E]=1077
[transparent_220x132_3.0W]=1074 [transparent_220x132_3.0E]=1072 [transparent_220x132_28.2E]=1143
[transparent_220x132_27.5W]=1141 [transparent_220x132_26.0E]=1139 [transparent_220x132_24.5W]=1135
[transparent_220x132_23.5E]=1133 [transparent_220x132_22.0W]=1131 [transparent_220x132_21.5E]=1129
[transparent_220x132_PolandDTT]=1127 [transparent_220x132_19.2E]=1125 [transparent_220x132_18.0W]=1123
[transparent_220x132_16.0E]=1121 [transparent_220x132_15.0W]=1119 [transparent_220x132_14.0W]=1103
[transparent_220x132_13.0E]=1105 [transparent_220x132_12.5W]=1101 [transparent_220x132_11.0W]=1099
[transparent_220x132_10.0E]=1096 [transparent_220x132_1.9E]=1070 [transparent_220x132_1.0W]=1068
[transparent_220x132_0.8W]=1066)
DL_INDEX+=(
[transparentdark_220x132_skylink]=4690 [transparentdark_220x132_freeSAT]=4986 [transparentdark_220x132_digiczsk]=4680
[transparentdark_220x132_antiksat]=4678 [transparentdark_220x132_dvbtCZSK]=4684 [transparentdark_220x132_DTTitaly]=4682
[transparentdark_220x132_9.0E]=4594 [transparentdark_220x132_81.5E]=4676 [transparentdark_220x132_85.0E]=4674
[transparentdark_220x132_8.0W]=4592 [transparentdark_220x132_75.0E]=4672 [transparentdark_220x132_74.9E]=4670
[transparentdark_220x132_70.5E]=4668 [transparentdark_220x132_7.0W]=4590 [transparentdark_220x132_7.0E]=4588
[transparentdark_220x132_68.5E]=4666 [transparentdark_220x132_66.0E]=4664 [transparentdark_220x132_62.0E]=4662
[transparentdark_220x132_56.0E]=4660 [transparentdark_220x132_54.9E]=4658 [transparentdark_220x132_53.0E]=4656
[transparentdark_220x132_52.5E]=4654 [transparentdark_220x132_52.0E]=4652 [transparentdark_220x132_51.5E]=4650
[transparentdark_220x132_5.0W]=4586 [transparentdark_220x132_46.0E]=4648 [transparentdark_220x132_45.0W]=4646
[transparentdark_220x132_45.0E]=4644 [transparentdark_220x132_42.0E]=4642 [transparentdark_220x132_4.9E]=4584
[transparentdark_220x132_4.8E]=4582 [transparentdark_220x132_4.0W]=4580 [transparentdark_220x132_39.0E]=4640
[transparentdark_220x132_36.0E]=4638 [transparentdark_220x132_33.0E]=4636 [transparentdark_220x132_31.5E]=4634
[transparentdark_220x132_30.5E]=4632 [transparentdark_220x132_30.0W]=4630 [transparentdark_220x132_3.1E]=4578
[transparentdark_220x132_3.0W]=4576 [transparentdark_220x132_3.0E]=4574 [transparentdark_220x132_28.2E]=4628
[transparentdark_220x132_27.5W]=4626 [transparentdark_220x132_26.0E]=4624 [transparentdark_220x132_24.5W]=4622
[transparentdark_220x132_23.5E]=4620 [transparentdark_220x132_22.0W]=4618 [transparentdark_220x132_21.5E]=4616
[transparentdark_220x132_PolandDTT]=4614 [transparentdark_220x132_19.2E]=4612 [transparentdark_220x132_18.0W]=4610
[transparentdark_220x132_16.0E]=4608 [transparentdark_220x132_15.0W]=4606 [transparentdark_220x132_14.0W]=4604
[transparentdark_220x132_13.0E]=4602 [transparentdark_220x132_12.5W]=4600 [transparentdark_220x132_11.0W]=4598
[transparentdark_220x132_10.0E]=4596 [transparentdark_220x132_1.9E]=4572 [transparentdark_220x132_1.0W]=4570
[transparentdark_220x132_0.8W]=4568)

### Funktionen
f_log() {     # Gibt die Meldung auf der Konsole und im Syslog aus
  local logger=(logger --tag "$SELF_NAME") msg="${*:2}"
  case "${1^^}" in
    'ERR'*|'FATAL') [[ -t 2 ]] && { echo -e "$msgERR ${msg:-$1}${nc}" ;} \
                      || "${logger[@]}" --priority user.err "$*" ;;
    'WARN'*) [[ -t 1 ]] && { echo -e "$msgWRN ${msg:-$1}" ;} || "${logger[@]}" "$*" ;;
    'DEBUG') [[ -t 1 ]] && { echo -e "\e[1m${msg:-$1}${nc}" ;} || "${logger[@]}" "$*" ;;
    'INFO'*) [[ -t 1 ]] && { echo -e "$msgINF ${msg:-$1}" ;} || "${logger[@]}" "$*" ;;
    *) [[ -t 1 ]] && { echo -e "$*" ;} || "${logger[@]}" "$*" ;;  # Nicht angegebene
  esac
  [[ -n "$LOGFILE" ]] && printf '%(%d.%m.%Y %T)T: %b\n' -1 "$*" 2>/dev/null >> "$LOGFILE"  # Log in Datei
}

### Start
SCRIPT_TIMING[0]=$SECONDS  # Startzeit merken (Sekunden)

# Testen, ob Konfiguration angegeben wurde (-c …)
while getopts ":c:" opt ; do
  case "$opt" in
    c) if [[ -f "${CONFIG:=$OPTARG}" ]] ; then  # Konfig wurde angegeben und existiert
         source "$CONFIG" ; CONFLOADED='Angegebene' ; break
       else
         f_log ERR "Fehler! Die angegebene Konfigurationsdatei fehlt! (\"${CONFIG}\")"
         exit 1
       fi
    ;;
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

SRC_DIR="${LOGODIR}/.source"  # Verzeichnis für PIcon Pakete und Cookies
LOGO_PATH="${SRC_DIR}/Logos"  # Alle Logos in das gleiche Verzeichnis
if [[ ! -d "$LOGO_PATH" ]] ; then
  mkdir --parents "$LOGO_PATH" || { f_log ERR "Fehler beim erstellen von $LOGO_PATH" ; exit 1 ;}
fi

if [[ -f "$CHANNELSCONF" ]] ; then
  mapfile -t channelsconf < "$CHANNELSCONF"         # Kanalliste in Array einlesen
else
  f_log ERR "Datei $CHANNELSCONF nicht gefunden!" ; exit 1
fi

# Alle Symlinks im Logoverzeichnis löschen
find "$LOGODIR" -type l -delete

# 1. Aufruf der Seite um Cookie zu erhalten
wget "${WGET_OPT[@]}" --save-cookies="${SRC_DIR}/cookie.txt" \
  --output-document="${SRC_DIR}/download-picons.html" "${PICON_URL}/"

for package in "${LOGO_PACKAGE[@]}" ; do
  # Archivname und Downloadlink festlegen
  LOGO_ARCH="${LOGO_TYPE}_${LOGO_SIZE}_${package}"  # transparent_220x132_19.2E
  DL_URL="${DL_INDEX[${LOGO_ARCH}]}"
  [[ -z "$DL_URL" ]] && { f_log ERR "Download-Link für $LOGO_ARCH nicht gefunden!" ; exit 1 ;}

  # Prüfen, ob geladene Logopakete älter als 1 Woche sind
  if [[ $(stat --format=%Y "${SRC_DIR}/${LOGO_ARCH}.7z" 2>/dev/null) -le $((NOW - 60*60*24*7)) ]] ; then
    f_log INFO "Lade Logo-Paket für ${package}…"

    # Laden der Datei
    wget "${WGET_OPT[@]}" --load-cookies="${SRC_DIR}/cookie.txt" --referer="$PICON_URL" \
      --output-document="${SRC_DIR}/${LOGO_ARCH}.7z" "https://picon.cz/download/${DL_URL}"

    # Archiv Entpacken
    f_log INFO "Entpacke Logo-Paket für ${package}…"
    7z e -bd -o"${LOGO_PATH}/" "${SRC_DIR}/${LOGO_ARCH}.7z" -y >> "${LOGFILE:-/dev/null}" \
      || f_log ERR "Fehler beim entpacken von ${SRC_DIR}/${LOGO_ARCH}.7z"
  else
    f_log INFO "Logopaket ${LOGO_ARCH}.7z ist bereits aktuell!"
  fi  # stat
done  # LOGO_PACKAGE

# Logos optimieren
f_log INFO "Optimiere Logos mit pngquant…"
pngquant --force --strip --ext .png "${LOGO_PATH}/*.png" >> "${LOGFILE:-/dev/null}"

# Kanalname den Picon zuordnen
for i in "${!channelsconf[@]}" ; do
  [[ "${channelsconf[i]:0:1}" == : ]] && { ((grp++)) ; continue ;}     # Kanalgruppe
  [[ "${channelsconf[i]}" =~ OBSOLETE ]] && { ((obs++)) ; continue ;}  # Als 'OBSOLETE' markierter Kanal
  [[ "${channelsconf[i]%%;*}" == '.' ]] && { ((bl++)) ; continue ;}    # '.' als Kanalname
  unset -v 'sid' 'tid' 'nid' 'namespace' 'channeltype'
  ((cnt++)) ; [[ -t 1 ]] && echo -ne "$msgINF Prüfe Kanal #${cnt}"\\r
  IFS=':' read -r -a vdrchannel <<< "${channelsconf[i]}"

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
  vdr_channelname="${channelname[0]%,*}"       # Kanalname ohne Kurzname

  # Kanalname: $vdr_channelname PICON: ${serviceref}.png
  logohist+=("$vdr_channelname -> $serviceref")

  # Kanal verlinken, wenn Logo existiert
  if [[ -e "${LOGO_PATH}/${serviceref}.png" ]] ; then  # Picon vorhanden?
    if [[ "${TOLOWER:-ALL}" == 'ALL' ]] ; then
      servicename="${vdr_channelname,,}"       # Alles in kleinbuchstaben
    else
      servicename="${vdr_channelname,,[A-Z]}"  # In Kleinbuchstaben (Außer Umlaute)
    fi  # TOLOWER
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
    ((nologo++))
  fi
done  # CHANNELSCONF

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

# Leere Verzeichnisse löschen
find "$LOGODIR" -type d -empty -delete

# Statistik anzeigen
[[ "$nologo" -gt 0 ]] && f_log "==> $nologo Kanäle ohne Logo"
[[ "$double" -gt 0 ]] && f_log "==> $double Kanäle mit unterschiedlichen Logos"
[[ "$obs" -gt 0 || "$bl" -gt 0 ]] && f_log "==> Übersprungen: 'OBSOLETE' (${obs:-0}), '.' (${bl:-0})"
f_log "==> ${symlink:-0} verlinkte Logos"
SCRIPT_TIMING[2]=$SECONDS  # Zeit nach der Statistik
SCRIPT_TIMING[10]=$((SCRIPT_TIMING[2] - SCRIPT_TIMING[0]))  # Gesamt
f_log "==> Skriptlaufzeit: $((SCRIPT_TIMING[10] / 60)) Minute(n) und $((SCRIPT_TIMING[10] % 60)) Sekunde(n)"

if [[ -e "$LOGFILE" ]] ; then  # Log-Datei umbenennen, wenn zu groß
  FILESIZE="$(stat --format=%s "$LOGFILE")"
  [[ $FILESIZE -gt $MAXLOGSIZE ]] && mv --force "$LOGFILE" "${LOGFILE}.old"
fi

exit 0
