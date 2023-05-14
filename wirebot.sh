#!/bin/bash
#

####################################################
#### Switch desired function on or off (0 or 1).####
####################################################
user_join=0
user_leave=0
wordfilter=1
common_reply=1
####################################################

####################################################
######### Watch a directory for new files ##########
####################################################
watcher=1
watchdir="/PATH/TO/DIR"
####################################################

####################################################
####################### GPT ########################
####################################################
gpt=edge
#Options: edge, openai
openai_token="YOUR_TOKEN"
####################################################

####################################################
##################### EdgeGPT ######################
####################################################
edgegpt=1
style=balanced
#Options: creative, balanced, precise
edgegpt_reconnect=1
#In case of an Engine crash, start again.
edgegpt_version="0.3.8.1"
####################################################

####################################################
################# RSS Feed On/Off ##################
####################################################
rssfeed=1
interval=5m
####################################################
macrumors=1
tarnkappe=1
####################################################

####################################################
### Let these users (login-name) control the bot ###
####################################################
admin_user="admin,luigi,peter"
####################################################

####################################################
############ Monitoring EdgeGPT Engine #############
####################################################
if [[ "$1" = "monitor" ]]; then
  if [ ! -f edgegpt.history ]; then
    echo 0 > edgegpt.history
  fi
  while true
  do
    if ! pgrep -f "edgegpt.py" > /dev/null
    then
      screen -S wirebot -p0 -X stuff "<n><b>💥 GPT Engine crashed! 💥 Please send again.</b></n>"^M
      bash wirebot.sh edgegpt_init
    fi
    sleep 10
  done
fi
####################################################

####################################################
############# Send Request to EdgeGPT ##############
####################################################
if [[ "$1" = "edgegpt" ]]; then
nick=$( cat wirebot.cmd | sed 's/-###.*//g' | xargs )
say=$( cat edgegpt.txt | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' | sed -e 's/Bot://g' -e 's/You://g' -e 's/"/“/g' | grep -v '^\[' | sed -e 's/\[.*\]//g' -e 's/[[:space:]]\{1,\}\./\./g' -e 's/$/<\/br>/' -e 's/\s*$//' | xargs )
say="<u><b>${nick}</b></u></br>${say}" 

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
  screen -S wirebot -p0 -X stuff "/clear"^M
  line="<n>${line}</n>"
  screen -S wirebot -p0 -X stuff "$line"^M
done

exit
fi
####################################################

SELF=$(SELF=$(dirname "$0") && bash -c "cd \"$SELF\" && pwd")
cd "$SELF"

nick=$( cat wirebot.cmd | sed 's/-###.*//g' | xargs )
nick_low=$( echo "$nick" | tr '[:upper:]' '[:lower:]' )
command=$( cat wirebot.cmd | sed 's/.*-###-//g' | xargs )

################ Function Section ################

function print_msg {
  screen -S wirebot -p0 -X stuff "$say"^M
}

function rnd_answer {
  size=${#answ[@]}
  index=$(($RANDOM % $size))
  say=$( echo ${answ[$index]} )
  print_msg
}

function kill_screen {
  if [ -f watcher.pid ]; then
    rm watcher.pid
  fi
  if [ -f wirebot.stop ]; then
    rm wirebot.stop
  fi
  if [ -f wirebot.pid ]; then
    rm wirebot.pid
  fi
  if [ -f rss.pid ]; then
    rm rss.pid
  fi
  if [ -f edgegpt.pid ]; then
    rm edgegpt.pid
  fi
  screen -XS wirebot quit
}

function watcher_def {
  inotifywait -m -e create,moved_to "$watchdir" | while read DIRECTORY EVENT FILE; do
    say=$( echo "$FILE" |sed -e 's/.*CREATE\ //g' -e 's/.*MOVED_TO\ //g' -e 's/.*ISDIR\ //g' )
    say=$( echo ":floppy_disk: New Stuff has arrived: $say" )
    print_msg
  done
}

function watcher_start {
  check=$( ps ax | grep -v grep | grep "inotifywait" | grep "$watchdir" )
  if [ "$check" = "" ]; then
    if ! [ -d "$watchdir" ]; then
      echo -e "The watch path \"$watchdir\" is not valid/available.\nPlease change it in wirebot.sh first and try again (./wirebotctl watch)."
      exit
    fi
    if screen -S wirebot -x -X screen -t watcher bash -c "bash "$SELF"/wirebot.sh watcher_def; exec bash"; then
      sleep 1
      ps ax | grep -v grep | grep "inotifywait*.* $watchdir" | sed 's/\ .*//g' | xargs > watcher.pid
      echo "Watcher started."
    else
      echo "Error on starting watcher. Make sure to run wirebot first! (./wirebotctl start)"
    fi
  fi
}

function watcher_stop {
  if ! [ -f watcher.pid ]; then
    echo "Watcher is not running!"
  else
    screen -S wirebot -p "watcher" -X kill
    rm watcher.pid
    echo "Watcher stopped."
  fi
}


function watcher_init {
  if [ "$watcher" = 1 ]; then
    if [ -d "$watchdir" ]; then
      watcher_start
    else
      echo -e "The watch path \"$watch=dir\" is not valid/available.\nPlease change it in wirebot.sh first and try again (./wirebotctl watch)."
    fi
  fi
}

function edgegpt_init {
  screen -S wirebot -p "edgegpt" -X kill
  pkill -f "wirebot.sh monitor"
  if [ "$edgegpt" = 1 ]; then
    screen -S wirebot -x -X screen -t edgegpt bash -c "python "$SELF"/edgegpt.py --cookie-file edgegpt.cookies --enter-once --no-stream --rich --style $style; exec bash" &
    sleep 1
    ps ax | grep -v grep | grep -v sleep | grep "./edgegpt.py" | grep -v "exec bash" | sed 's/\ .*//g' | xargs > edgegpt.pid
    if [ $? = 0 ]; then
      echo "Edge-GPT started."
      if [ "$edgegpt_reconnect" = 1 ]; then
        bash wirebot.sh monitor &
      fi
    else
      echo "Error!!! Edge-GPT could not be started. Please try again."
    fi
  fi
}

function rssfeed_def {
  ./rss.sh
}

function rssfeed_start {
  check=$( ps ax | grep -v grep | grep "./rss.sh" )
  if [ "$check" = "" ]; then
    screen -S wirebot -x -X screen -t rss bash -c "bash "$SELF"/wirebot.sh rssfeed_def; exec bash" &
    sleep 2
    ps ax | grep -v grep | grep -v sleep | grep "rssfeed_def; exec bash" | sed 's/\ .*//g' | xargs > rss.pid
    echo "RSS feed started."
  else
    echo "RSS feed is already running!"
    exit
  fi
}

function rssfeed_stop {
  if ! [ -f rss.pid ]; then
    echo "RSS feed is not running!"
  else
    screen -S wirebot -p "rss" -X kill
    rm rss.pid
    echo "RSS feed stopped."
  fi
}

function rssfeed_init {
  if [ "$rssfeed" = 1 ]; then
    rssfeed_start
  fi
}

if [[ "$command" = "#"* ]]; then
  conversation=$( echo "$command" | sed -e 's/b:\ //g' -e 's/B:\ //g' -e 's/#//g' )
  
  if [ "$gpt" = "edge" ]; then
    gpt_check=$( ps ax | grep -v grep | grep -v sleep | grep "./edgegpt.py" | grep -v "exec bash" | sed 's/\ .*//g' | xargs )
    if [[ $gpt_check != "" ]]; then
      if [[ "$command" = "#xreset" ]]; then
        say="<n><b>Conversation reset ...</b></n>"
        print_msg
        say=$( screen -S wirebot -p "edgegpt" -X stuff "xreset"^M )
        exit
      fi
      if [[ "$command" = "#status" ]]; then
        date_diff=$(($(date +%s) - $(stat -c %Y edgegpt.pid )))
        edgegpt_up=$( printf "%02d/%02d:%02d:%02d\n" "$((date_diff / 86400))" "$((date_diff / 3600 % 24))" "$((date_diff / 60 % 60))" "$((date_diff % 60))"  )
        date_diff=$(($(date +%s) - $(stat -c %Y edgegpt.history )))
        edgegpt_last=$( printf "%02d/%02d:%02d:%02d\n" "$((date_diff / 86400))" "$((date_diff / 3600 % 24))" "$((date_diff / 60 % 60))" "$((date_diff % 60))" )
        edgegpt_no_requests=$(head -n 1 edgegpt.history)
        say="<n><b><u>Status</b></u></br></br>Style&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: $style</br>Runtime&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: $edgegpt_up</br>Last Request: $edgegpt_last</br>N° Requests&nbsp;:&nbsp;$edgegpt_no_requests</br>Version&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: <a href="https://github.com/acheong08/EdgeGPT/tree/master">$edgegpt_version</a></n>"
        print_msg
        exit
      fi
      if [[ "$command" = "#style"* ]]; then
        if [[ "$command" = "#style creative" ]]; then
   	    style="creative"
   	  fi
        if [[ "$command" = "#style balanced" ]]; then
   	    style="balanced"
   	  fi
         if [[ "$command" = "#style precise" ]]; then
   	    style="precise"
   	  fi
        say="<n><b>Style changed to '$style'</b></n>"
        sed -i "0,/.*style=.*/ s/.*style=.*/style=$style/g" wirebot.sh
        print_msg
   	  screen -S wirebot -p "edgegpt" -X kill
        edgegpt_init
        exit
      fi
      if [[ "$command" = "#help" ]]; then
  	  say="<n><b><u>Available Commands</b></u></br></br>1) <span style="font-family:Courier">#YOUR TEXT</span> (Talk with Bot)</br>2) <span style="font-family:Courier">#style <b>creative|balanced|precise</b></span></br>3) <span style="font-family:Courier">#status</span></br>4) <span style="font-family:Courier">#xreset</span> (Reset conversation)</n>"
        print_msg
        exit
      fi
      screen -S wirebot -p "edgegpt" -X stuff "$conversation"^M
      screen -S wirebot -p "wirebot" -X stuff "/afk"^M
  	  date >> edgegpt.history
      echo "$nick": "$conversation" >> edgegpt.history
  	  value=$(head -n 1 edgegpt.history)
  	  new_value=$((value + 1))
  	  sed -i "1s/.*/$new_value/" edgegpt.history
      exit
    else
      screen -S wirebot -p "edgegpt" -X kill
      screen -S wirebot -x -X screen -t edgegpt bash -c "python "$SELF"/edgegpt.py --cookie-file edgegpt.cookies --enter-once --no-stream --rich --style $style; exec bash"
      sleep 1
      screen -S wirebot -p "edgegpt" -X stuff "$conversation"^M
      screen -S wirebot -p "wirebot" -X stuff "/afk"^M
      date >> edgegpt.history
  	  echo "$nick": "$conversation" >> edgegpt.history
  	  value=$(head -n 1 edgegpt.history)
  	  new_value=$((value + 1))
  	  sed -i "1s/.*/$new_value/" edgegpt.history
      exit
    fi
  fi

  say=$( python chatgpt.py "$conversation" )

  if [ "$say" = "" ]; then
    say=$( echo "📡 Can't connect to openAI Network. Resource busy. :(" )
    print_msg
    exit
  fi

  if [[ "$say" == *"https"* ]]; then
    pic_url=$( echo "$say" | grep http | sed -e 's/.*(//g' -e 's/)//g' | tail -n 1 )
    cd imgur
    curl -s "$pic_url" > picture
    convert picture -resize 400 picture.jpg
    
    if [ "$?" != "0" ]; then
      say="🚫 Error fetching Image. Please try again. 🚫"
      rm picture* ._* > /dev/null
      print_msg
      exit
    fi
    
    imgur_url=$( ./imgur.sh picture.jpg )
    say=$( echo "<img src=\"$imgur_url\"></img>" )
    rm picture* ._* > /dev/null
    print_msg
    exit
  fi
  
  say=$( echo "$say" | sed -e 's/.*/<br>&<\/br>/' | tr '\n' ' ' | sed -e 's/  /\&nbsp;\&nbsp;/g' )
  say=$( echo "<b><u>$nick: </u></b>" "<p>$say</p>" )
  print_msg
  exit
fi

################ Option Section ################

function user_join_on {
  sed -i '0,/.*user_join=.*/ s/.*user_join=.*/user_join=1/g' wirebot.sh
}

function user_join_off {
  sed -i '0,/.*user_join=.*/ s/.*user_join=.*/user_join=0/g' wirebot.sh
}

function user_leave_on {
  sed -i '0,/.*user_leave=.*/ s/.*user_leave=.*/user_leave=1/g' wirebot.sh
}

function user_leave_off {
  sed -i '0,/.*user_leave=.*/ s/.*user_leave=.*/user_leave=0/g' wirebot.sh
}

function wordfilter_on {
  sed -i '0,/.*wordfilter=.*/ s/.*wordfilter=.*/wordfilter=1/g' wirebot.sh
}

function wordfilter_off {
  sed -i '0,/.*wordfilter=.*/ s/.*wordfilter=.*/wordfilter=0/g' wirebot.sh
}

function common_reply_on {
  sed -i '0,/.*common_reply=.*/ s/.*common_reply=.*/common_reply=1/g' wirebot.sh
}

function common_reply_off {
  sed -i '0,/.*common_reply=.*/ s/.*common_reply=.*/common_reply=0/g' wirebot.sh
}

function rssfeed_on {
  sed -i '0,/.*rssfeed=.*/ s/.*rssfeed=.*/rssfeed=1/g' wirebot.sh
}

function rssfeed_off {
  sed -i '0,/.*rssfeed=.*/ s/.*rssfeed=.*/rssfeed=0/g' wirebot.sh
}

################ Phrase Section ################

#### User join server (user_join) ####
if [ $user_join = 1 ]; then
  if [[ "$command" == *" has joined" ]]; then
    nick=$( cat "$out_file" | sed -e 's/.*\]\ //g' -e 's/\ has\ joined//g' -e 's/;0m//g' | xargs )
    say="Hi $nick 😁"
    print_msg
  fi
fi

#### User leave server (user_leave) ####
if [ $user_leave = 1 ]; then
  if [[ "$command" == *" has left" ]]; then
    nick=$( cat "$out_file" | sed -e 's/.*\]\ //g' -e 's/\ has\ left//g' -e 's/;0m//g' | xargs )
    say="Bye $nick 😔"
    print_msg
  fi
fi

#### wordfilter (wordfilter)####
if [[ "$command" == *"Hey, why did you"* ]]; then
  exit
fi

if [ $wordfilter = 1 ]; then
  if [ "$command" = "shit" ] || [[ "$command" = *"fuck"* ]] || [ "$command" = "asshole" ] || [ "$command" = "ass" ] || [ "$command" = "dick" ]; then
    answ[0]="$nick, don't be rude please... 👎"
    answ[1]="Very impolite! 😠"
    answ[2]="Hey, why did you say \"$command\" ? 😧 😔"
    rnd_answer
    exit
  fi
fi

#### Common (common_reply) ####
if [ $common_reply = 1 ]; then
  if [[ "$command" = "wired" ]]; then
    answ[0]="Uh? What's "Wired" $nick? ‍😖"
    answ[1]="Ooooh, Wired! The magazine ? 😟"
    rnd_answer
  fi
  if [[ "$command" = "shut up bot" ]] ; then
    answ[0]="Moooooo 😟"
    answ[1]="Oh no 😟"
    answ[2]="Nooooo 😥"
    rnd_answer
    exit
  fi
  if [[ "$command" = "bot" ]]; then
    answ[0]="Do you talked to me $nick?"
    answ[1]="Bot? What's a bot?"
    answ[2]="Bots are silly programs. 🙈"
    answ[3]="…"
    answ[4]="hides!"
    answ[5]="runs!"
    rnd_answer
  fi
  if [ "$command" = "hello" ] || [ "$command" = "hey" ] || [ "$command" = "hi" ]; then
    answ[0]="Hey $nick. 😁"
    answ[1]="Hello $nick. 👋"
    answ[2]="Hi $nick. 😃"
    answ[3]="Yo $nick. 😊"
    answ[4]="Yo man ... whazzup? ✌️"
    rnd_answer
  fi
fi

################ Admin Section ################

if [[ "$command" = \!* ]]; then
  login=""
  say="/clear"
  print_msg
  say="/info \"$nick\""
  print_msg
  sleep 0.5
  screen -S wirebot -p0 -X hardcopy "$SELF"/wirebot.login
  login=$( cat wirebot.login | grep -v grep | grep "Login:" | sed 's/.*Login:\ //g' | xargs )
  rm wirebot.login
  
  if [[ "$login" != "" ]]; then
    if [[ "$admin_user" == *"$login"* ]]; then
      allowed=1
    else
      allowed=0
      say="🚫 You are not allowed to do this $nick 🚫"
      print_msg
      exit
    fi
  fi
fi

if [ "$allowed" = 1 ]; then
  if [ "$command" = "!" ]; then
    say="⛔ This command is not valid. ⛔"
    print_msg
  fi
  if [ "$command" = "!sleep" ]; then
    answ[0]="💤"
    answ[1]=":sleeping: … Time for a nap."
    rnd_answer
    say="/afk"
    print_msg
  fi
  if [ "$command" = "!start" ]; then
    answ[0]="Yes, my lord."
    answ[1]="I need more blood.👺"
    answ[2]="Ready to serve.👽"
    rnd_answer
  fi
  if [ "$command" = "!stop" ]; then
    answ[0]="Ping me when you need me. 🙂"
    answ[1]="I jump ❗"
    rnd_answer
    say="/afk"
    print_msg
    touch wirebot.stop
  fi
  if [ "$command" = "!userjoin on" ]; then
    user_join_on
  fi
  if [ "$command" = "!userjoin off" ]; then
    user_join_off
  fi  
  if [ "$command" = "!userleave on" ]; then
    user_leave_on
  fi
  if [ "$command" = "!userleave off" ]; then
    user_leave_off
  fi 
  fi
    if [ "$command" = "!kill_screen" ]; then
    say="Cya."
    kill_screen
  fi

  if [ -f wirebot.stop ]; then
    if [ "$command" = "!start" ]; then
          rm wirebot.stop
    elif [ "$command" = "!stop" ]; then
      say="/afk"
      print_msg
      exit
    else
      exit
    fi
  elif [ ! -f wirebot.stop ]; then
    if [ "$command" = "!start" ]; then
          exit
    fi
  fi

  if [[ "$command" == *"Using timestamp"* ]]; then
    if [ -f wirebot.stop ]; then
      rm wirebot.stop
  fi
 
fi

$1
