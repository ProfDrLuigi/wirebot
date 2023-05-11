#!/bin/bash
#
#

nick=$( cat wirebot.nick )
say=$( cat edgegpt.txt | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' | sed -e 's/Bot://g' -e 's/You://g' -e 's/"/“/g' | grep -v '^\[' | sed -e 's/\[.*\]//g' -e 's/[[:space:]]\{1,\}\./\./g' -e 's/$/<\/br>/' | xargs )
say="<u><b>${nick}</b></u></br>${say}" 

rm wirebot.nick

max_length=720
while [ -n "$say" ]; do
  line="${say:0:$max_length}"
  say="${say:$max_length}"
  if [ -n "$say" ]; then
    last_space="$(echo "$line" | sed -nE "s/.* ([^ ]+)$/\1/p")"
    if [ -n "$last_space" ]; then
      line="${line%$last_space}"
      say="${last_space}${say}"
    fi
  fi
  line="<n>${line}</n>"
  line=$( echo "$line" | sed -e 's/$/<\/br>/' )
  screen -S wirebot -p0 -X stuff "$line"^M
done

date >> logger