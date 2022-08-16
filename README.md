# Picon.cz2VDR

Picons für den VDR

Skript zum erzeugen und verlinken der PICON-Kanallogos (Enigma2)

Die benötigten Picons (https://picon.cz) werden vom Skript lokal in einem Unterordner auf die Festplatte gespeichert und bei jedem Start aktualisiert (Maximal ein mal pro Woche).

Die Dateinamen der Picons passen nicht zum VDR-Schema. Darum erstellt das Skript mit Hilfe der "channels.conf" Symlinks zu den Logos.

Im VDR-Logoverzeichnis wird ein Ordner ".source" angelegt, der die Kanallogos enthält. 

In der *.conf müssen einige Variablen angepasst werden:

LOGODIR -> Verzeichnis, wo das Skin die Kanallogos erwartet (/var/lib/vdr/channellogos)

CHANNELSCONF -> Die Kanalliste vom VDR (/var/lib/vdr/channels.conf)

LOGO_TYPE -> Hintergrund (Vorgabe transparent)

LOGO_SIZE -> Logogröße (Vorgabe: 220x132)

LOGO_PACKAGE -> Empfangsart (Vorgabe: 19.2E) Beispiel bei Empfang von 2 Satelliten: LOGO_PACKAGE=(19.2E 9.0E)

Picons mit folgenden Hintergründen:

Transparent, Transparent Black, White, noName, Mirroglass, SRHD, Freeze Frame, Freeze White, Monochromatic oder Pool RainBow

Abmessungen:

50×30, 96×64, 100×60, 132×46, 150×90, 220×132, 400×170, 400×240 und 500×300

Übersicht: https://picon.cz/plugin/

