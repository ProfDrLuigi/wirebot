#!/bin/bash
#

wirebot=$( cat wirebot.sh )
macrumors=$( echo "$wirebot" | grep "macrumors=" | sed 's/macrumors=//g' )
tarnkappe=$( echo "$wirebot" | grep "tarnkappe=" | sed 's/tarnkappe=//g' ) 
interval=$( echo "$wirebot" | grep "interval=" | sed 's/interval=//g' )

function macrumors_rss {
  macrumors_feed=$( curl --silent "https://feeds.macrumors.com/MacRumors-All" | \
  grep -E '(title>|description>)' | \
  tail -n +4 | \
  sed -e 's/^[ \t]*//' | \
  sed -e 's/<title>//' -e 's/<\/title>//' -e 's/<description>/  /' -e 's/<\/description>//' | head -n 1 | sed -e 's/.*CDATA\[//g' -e 's/<br\/>//g' | tr -dc '[[:print:]]\n' )
  macrumors_say=$( echo -e "<n><b><u>+++ Macrumors Breaking News +++</u></b><br>""$macrumors_feed""</n>" )
}

function tarnkappe_rss {
  #tarnkappe_feed=$( rsstail -e 0 -u https://feeds.feedburner.com/tarnkappe/ERFS -d -n 1 | sed -e 's/<p>Der\ Artikel\ //g' -e 's/\ erschien\ zuerst\ auf\ <a\ rel.*//g' )
  tarnkappe_feed=$( curl -s https://feeds.feedburner.com/tarnkappe/ERFS | sed -e 's/<p>Der\ Artikel\ //g' -e 's/\ erschien\ zuerst\ auf\ <a\ rel.*//g' )
  #title=$( echo "$tarnkappe_feed" | grep "Title:" | sed 's/Title:\ //g' )
  title=$( echo "$tarnkappe_feed" | grep "<title>" | head -n3 | tail -n1 | sed 's/<\/*title>//g' | xargs 2>/dev/null )
  #descr=$( echo "$tarnkappe_feed" | sed 's/.*Description\:\ //g' | sed -e 's/\.html".*/\.html">Ganzen Artikel bei Tarnkappe lesen<\/a>/g' |grep -v "Title: " )
  #descr=$( echo "$tarnkappe_feed" | grep "<description>" | head -n2 | tail -n1 | sed 's/<\/*description>//g' | xargs | sed -e 's/.*<p>//g' -e 's/<\/p>//g' )
  url=$( echo "$tarnkappe_feed" | grep -v "Datenschutz" | xargs 2>/dev/null | sed -e 's/*.<description>//g' -e 's/<\/description>.*//g' -e 's/.*<p>Der\ Artikel/<p>Der\ Artikel/g' | sed 's/<\/*description>//g' | xargs | sed -e 's/.*<p>//g' -e 's/<\/p>//g' -e 's/].*//g' )
  tarnkappe_say=$( echo -e "<b><u>""$title""</u></b><br>""$descr""$url" | sed ':a;N;$!ba;s/\n//g' )
}

if [ "$macrumors" = "1" ]; then
  macrumors_rss
fi
if [ "$tarnkappe" = "1" ]; then
  tarnkappe_rss
fi

while true
do
  if [ "$macrumors" = "1" ]; then
    macrumors_now=$( curl "https://feeds.macrumors.com/MacRumors-All" 2> /dev/null | grep pubDate | head -1 )
  fi
  if [ "$tarnkappe" = "1" ]; then
    tarnkappe_rss
    tarnkappe_now=$( echo "$title" )
  fi

  if [ -f rss.brain ]; then
    macrumors_check=$( cat rss.brain | grep -v grep | grep "$macrumors_now" )
    tarnkappe_check=$( cat rss.brain | grep -v grep | grep "$tarnkappe_now" )
  fi

  if  [ "$macrumors_check" = "" ]; then
    if [ "$macrumors" = "1" ]; then
      macrumors_rss
      screen -S wirebot -p0 -X stuff "$macrumors_say"^M
      screen -S wirebot -p0 -X stuff "/afk"^M
      echo "$macrumors_now" >> rss.brain
    fi
  fi

  if  [ "$tarnkappe_check" = "" ]; then
    if [ "$tarnkappe" = "1" ]; then
      tarnkappe_rss
      screen -S wirebot -p0 -X stuff "$tarnkappe_say"^M
      screen -S wirebot -p0 -X stuff "/afk"^M
      echo "$tarnkappe_now" >> rss.brain
    fi
  fi

  sleep "$interval"
done
