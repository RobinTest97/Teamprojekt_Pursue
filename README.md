# Teamprojekt_Pursue Audioevaluierung
## Zu installierende Software
### [Peaqb-fast von akinori-ito](https://github.com/akinori-ito/peaqb-fast)

Für die objektive Audioevaluierung wurde sich für eine Implementation des [PEAQ Verfahrens](https://www.itu.int/rec/R-REC-BS.1387) entschieden. Dabei wurde sich für "peaqb-fast" entschieden. Weitere Implementationen, für die sich nicht entschieden wurden, sind:

* [MATLAB Version von P. Kabal](http://www-mmsp.ece.mcgill.ca/Documents/Software/)
* [Python Version von Matthew Cohen and Stephen Welch](https://github.com/stephencwelch/Perceptual-Coding-In-Python)
* [EAQUAL von A. Lerch](http://www.mp3-tech.org/programmer/sources/eaqual.tgz) 
#### Schritt 1:
Peaqb-fast erfordert einen C Compiler. Unter Ubuntu lässt sich „[gcc](https://gcc.gnu.org/)“, falls noch kein C Compiler vorhanden ist, mit dem folgenden Befehl installieren:

  `$sudo apt install build-essential`

Bestimmte Versionen können mit dem folgenden Befehl installiert werden:

  `$sudo apt install gcc-9`

In der Installationsdatei ist keine explizite Version von „[gcc](https://gcc.gnu.org/)“ vorgegeben. Die Installation wurde mit der Version 9.3.0 getestet und durchgeführt.

#### Schritt 2:
Die Dateien für die in C geschriebene Peaqb-fast Variante des PEAQ-Verfahrens müssen von der [Github Seite von „akinori-ito“](https://github.com/akinori-ito/peaqb-fast) heruntergeladen werden. Die Dateien können entweder mit der vorhandenen Archivverwaltung oder mit dem „unzip“ Befehl entpackt werden.

`$unzip peaqb-master-fast.zip`

#### Schritt 3:
Durch das Entpacken der Dateien steht ein neuer Ordner zur Verfügung: „peaqb-fast-master“. In diesem Ordner muss die „configure“ Datei ausgeführt werden.

`$./configure`

Bei der configure Datei handelt es sich um eine von dem Werkzeug „Autoconf“ erzeugte Datei. Autoconf erzeugt Shell-Skripte zur automatischen Konfiguration von Software-Quellcode-Paketen. Diese Skripte können die Pakete an verschiedene auf Unix basierende Systeme anpassen, ohne dass der Benutzer manuell eingreifen muss. Die Skripte fragen das System nach Umgebungseinstellungen und der Plattformarchitektur und speichern diese gesammelten Informationen in einer Datei, um auf Basis der Ergebnisse ein „Makefile“ zur erstellen.



#### Schritt 4:
Mit dem make Werkzeug werden aus dem Quellcode in dem Makefile Binärdateien kompiliert und erstellt. Diese Binärdateien werden anschließend mit „make install“ in das im Makefile angegebene Verzeichnis abgelegt und für den Nutzer zugänglich gemacht.

`$sudo make`

`$sudo make install`

#### Schritt 5:
Das fertige Programm wird im Verzeichnis „/usr/local/bin“ eingerichtet. Falls dies nicht der Fall sein sollte kann die Datei mit dem Befehl „whereis“ gesucht werden.

`$whereis peaqb`

### [PulseAudio](https://www.freedesktop.org/wiki/Software/PulseAudio/)

PulseAudio ist ein Sound-Server, der als Vermittler zwischen Anwendungen und Hardware-Geräten eines Linux Systems läuft, beispielsweise mit [ALSA](https://wiki.ubuntuusers.de/ALSA/). Dieser Sound-Server ermöglich das direkte Aufnehmen von Audiosignalen von den Audioausgabegeräten des Systems wie die Lautsprecher.

#### Schritt 1:
PulseAudio kann auf den meisten Unix Systemen mit dem folgendem Befehl installiert werden:

`$sudo apt-get install pulseaudio`

Für Systeme wie Debian stehen [optionale Pakete](https://wiki.ubuntuusers.de/PulseAudio/) zur Verfügung.

#### Schritt 2:

PulseAudio muss nach der Installation mit folgendem Befehl gestartet werden:

`$pulseaudio -D`

