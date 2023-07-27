#!/bin/bash
##

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
watchdir="/PATH/TO/FILES"
####################################################

####################################################
####################### GPT ########################
####################################################
gpt=bard
#Options: edgegpt, chatgpt, bard, none
####################################################

####################################################
##################### EdgeGPT ######################
####################################################
style=balanced
#Options: creative, balanced, precise
####################################################
edgegpt_name="EdgeGPT"
edgegpt_reconnect=1
#In case of an Engine crash, start again.
edgegpt_version="0.12.1"
#Shows up if '#status' is written in chat
####################################################

####################################################
####################### Bard #######################
####################################################
bard_name="Google Bard"
PSID=
PSIDTS=
bard_reconnect=1
#In case of an Engine crash, start again.
bard_version="2.1.0"
#Shows up if '#status' is written in chat
####################################################

####################################################
##################### ChatGPT ######################
####################################################
chatgpt_name="ChatGPT"
chatgpt_reconnect=1
#In case of an Engine crash, start again.
chatgpt_version="6.8.6"
#Shows up if '#status' is written in chat
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

SELF=$(SELF=$(dirname "$0") && bash -c "cd \"$SELF\" && pwd")
cd "$SELF"

if [ "$gpt" = "edgegpt" ]; then
  engine_name="EdgeGPT"
elif [ "$gpt" = "bard" ]; then
  engine_name="Google Bard"
elif [ "$gpt" = "chatgpt" ]; then
  engine_name="ChatGPT"
fi

####################################################
############## Monitoring GPT Engine ###############
####################################################
if [[ "$1" = "monitor_gpt" ]]; then
  if [ ! -f gpt.requests ]; then
    echo -e "bard=0\nedgegpt=0\nchatgpt=0" > gpt.requests
  fi
  while true
  do
    if [ "$gpt" = "edgegpt" ]; then
      if ! pgrep -f "EdgeGPT.EdgeGPT" > /dev/null
      then
        screen -S wirebot -p0 -X stuff "<n><b>💥 GPT Engine crashed! 💥 Please send again.</b></n>"^M
        bash wirebot.sh edgegpt_init
      fi
    fi
    if [ "$gpt" = "bard" ]; then
      if ! pgrep -f "Bard" > /dev/null
      then
        screen -S wirebot -p0 -X stuff "<n><b>💥 Bard Engine crashed! 💥 Please send again.</b></n>"^M
        bash wirebot.sh bard_init
      fi
    fi
    if [ "$gpt" = "chatgpt" ]; then
      if ! pgrep -f "ChatGPT" > /dev/null
      then
        screen -S wirebot -p0 -X stuff "<n><b>💥 ChatGPT Engine crashed! 💥 Please send again.</b></n>"^M
        bash wirebot.sh chatgpt_init
      fi
    fi
    sleep 10
  done
fi
####################################################

nick=$( cat wirebot.cmd | sed 's/-###.*//g' | xargs )
nick_low=$( echo "$nick" | tr '[:upper:]' '[:lower:]' )
command=$( cat wirebot.cmd | sed 's/.*-###-//g' | xargs )

function text_parser
{
  if [[ "$command" = *"Conversation"* ]] || [[ "$command" = *"Style changed"* ]] || [[ "$command" = *"[wirebot]"* ]]; then
    exit
  fi

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
}

####################################################
############# Send Request to EdgeGPT ##############
####################################################
if [[ "$1" = "edgegpt" ]]; then
  say=$( cat gpt.history | awk -v RS='Bot:' 'END{print "Bot:" $0}' | awk -v RS='You:' 'NR==1{print $0}' | sed -e 's/Bot://g' -e 's/Searching.*//g' -e 's/.*json//g' -e 's/Generating\ answers.*//g' -e 's/{[^}]*}//g' -e 's/`//g' -e 's/\[[^]]*\]//g' | grep -v '^\[' | grep -v '^\]' | grep -v http |sed -e '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' -e 's/\ .\ /.\ /g' -e 's/.*}//g' | xargs )

  if [ "$say" = "" ]; then
    exit
  fi

  text_parser

fi
####################################################

####################################################
############## Send Request to Bard ################
####################################################
if [[ "$1" = "bard" ]]; then
  say=$( cat gpt.history |sed -e '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' | sed 's/.*\[0m/•\ /g' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' | sed 's/•/<\/br>•/g' |xargs )

  if [ "$say" = "" ]; then
    exit
  fi

  text_parser
fi
####################################################

####################################################
############ Send Request to ChatGPT ###############
####################################################
if [[ "$1" = "chatgpt" ]]; then
  say=$( cat gpt.history | grep -v "1mChatbot:" | sed 's/^ \([0-9]\)/ <\/br><\/br>\1/1' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' | xargs )

  if [ "$say" = "" ]; then
    exit
  fi

  text_parser
fi
####################################################

################ Function Section ################

function print_msg {
  screen -S wirebot -p wirebot -X stuff "$say"^M
}

function decline_chat {
  screen -S wirebot -p wirebot -X stuff "/close"^M
  date > /tmp/yo
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
  if [ -f gpt.pid ]; then
    rm gpt.pid
  fi
  pkill -f edgegpt_init
  pkill -f bard_init
  pkill -f "wirebot.sh monitor_gpt"
  pkill -f "wirebot.sh monitor_gpt"
  screen -ls | grep "wirebot" | cut -d. -f1 | awk '{print $1}' | xargs -I {} screen -S {} -X quit
  pkill -f wirebot
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
      ps ax | grep -v grep | grep "inotifywait*.* $watchdir" | xargs | sed 's/\ .*//g' > watcher.pid
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
  screen -S wirebot -p "gpt" -X kill
  pkill -f "wirebot.sh monitor_gpt"
  > gpt.history
  sed -i '0,/.*gpt=.*/ s/.*gpt=.*/gpt=edgegpt/g' wirebot.sh
  gpt="edgegpt"
  if [ "$gpt" = "edgegpt" ]; then
    #if [ -f gpt.requests ]; then
	#    sed -i ':a;N;$!ba;s/\n//g; s/x//g' gpt.requests
    #fi
    screen -S wirebot -x -X screen -t gpt bash -c "python -m EdgeGPT.EdgeGPT --history-file ~/.wirebot/gpt.history --cookie-file ~/.wirebot/edgegpt.cookies --enter-once --style $style; exec bash" &
    sleep 1
    ps ax | grep -v grep | grep -v sleep | grep "EdgeGPT.EdgeGPT" | grep -v "exec bash" | xargs | sed 's/\ .*//g' > gpt.pid
    if [ $? = 0 ]; then
      echo "EdgeGPT started."
      if [[ "$command" != "#style"* ]]; then
        say="🤖 Switched GPT Engine succesful to 'EdgeGPT' 🤖"
        print_msg
        say="/nick Wirebot (GPT: EdgeGPT)"
        print_msg
      fi
      if [ "$edgegpt_reconnect" = 1 ]; then
        bash wirebot.sh monitor_gpt &
      fi
    else
      echo "Error!!! Edge-GPT could not be started. Please try again."
    fi
  fi
}

function bard_init {
  screen -S wirebot -p "gpt" -X kill
  pkill -f "wirebot.sh monitor_gpt"
  > gpt.history
  sed -i '0,/.*gpt=.*/ s/.*gpt=.*/gpt=bard/g' wirebot.sh
  gpt="bard"
  if [ "$gpt" = "bard" ]; then
    #if [ -f gpt.requests ]; then
	#    sed -i ':a;N;$!ba;s/\n//g; s/x//g' gpt.requests
    #fi
    screen -S wirebot -x -X screen -t gpt bash -c "python3 -m Bard --session "$PSID" --session_ts "$PSIDTS"; exec bash" &
    sleep 1
    ps ax | grep -v grep | grep -v sleep | grep "Bard" | grep -v "exec bash" | xargs | sed 's/\ .*//g' > gpt.pid
    if [ $? = 0 ]; then
      echo "Google Bard started."
      if [[ "$command" != "#style"* ]]; then
        say="🤖 Switched GPT Engine succesful to 'Google Bard' 🤖"
        print_msg
        say="/nick Wirebot (GPT: Google Bard)"
        print_msg
      fi
      if [ "$bard_reconnect" = 1 ]; then
        bash wirebot.sh monitor_gpt &
      fi
    else
      echo "Error!!! Google Bard could not be started. Please try again."
    fi
  fi
}

function chatgpt_init {
  screen -S wirebot -p "gpt" -X kill
  pkill -f "wirebot.sh monitor_gpt"
  > gpt.history
  sed -i '0,/.*gpt=.*/ s/.*gpt=.*/gpt=chatgpt/g' wirebot.sh
  gpt="chatgpt"
  if [ "$gpt" = "chatgpt" ]; then
    #if [ -f gpt.requests ]; then
	#    sed -i ':a;N;$!ba;s/\n//g; s/x//g' gpt.requests
    #fi
    screen -S wirebot -x -X screen -t gpt bash -c "python3 -m revChatGPT.V1; exec bash" &
    sleep 1
    ps ax | grep -v grep | grep -v sleep | grep "ChatGPT" | grep -v "exec bash" | xargs | sed 's/\ .*//g' > gpt.pid
    if [ $? = 0 ]; then
      echo "ChatGPT started."
      if [[ "$command" != "#style"* ]]; then
        say="🤖 Switched GPT Engine succesful to 'ChatGPT' 🤖"
        print_msg
        say="/nick Wirebot (GPT: ChatGPT)"
        print_msg
      fi
      if [ "$chatgpt_reconnect" = 1 ]; then
        bash wirebot.sh monitor_gpt &
      fi
    else
      echo "Error!!! ChatGPT could not be started. Please try again."
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
    ps ax | grep -v grep | grep -v sleep | grep "rssfeed_def; exec bash" | xargs | sed 's/\ .*//g' > rss.pid
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

if [ "$gpt" != "none" ]; then
  if [[ "$command" = "#"* ]]; then
    if [ "$gpt" = "bard" ]; then
      gpt_version="$bard_version"
      gpt_repo="https://github.com/acheong08/Bard/tree/master"
    fi
    if [ "$gpt" = "edgegpt" ]; then
      gpt_version="$edgegpt_version"
      gpt_repo="https://github.com/acheong08/EdgeGPT/tree/master"
    fi
    if [ "$gpt" = "chatgpt" ]; then
      gpt_version="$chatgpt_version"
      gpt_repo="https://github.com/acheong08/ChatGPT/tree/master"
    fi
    if [[ "$command" = "#engine"* ]]; then
      if [[ "$command" = *"bard"* ]]; then
        if [[ "$gpt" != "bard" ]]; then
          bard_init
        else
          say="<b>🚫 This engine is already active. 🚫</b>"
          print_msg
          exit
        fi
      #fi  
      elif [[ "$command" = *"edgegpt"* ]]; then
        if [[ "$gpt" != "edgegpt" ]]; then
          edgegpt_init
        else
          say="<b>🚫 This engine is already active. 🚫</b>"
          print_msg
          exit
        fi
      #fi
      elif [[ "$command" = *"chatgpt"* ]]; then
		if [[ "$gpt" != "chatgpt" ]]; then
          chatgpt_init
        else
          say="<b>🚫 This engine is already active. 🚫</b>"
          print_msg
          exit
        fi
      else
        say="Error! You must enter a valid engine. Type #help in Chat to see options"
        print_msg
      fi
      exit
    fi
    if [[ "$command" = "#status" ]]; then
      date_diff=$(($(date +%s) - $(stat -c %Y gpt.pid )))
      gpt_up=$( printf "%02d/%02d:%02d:%02d\n" "$((date_diff / 86400))" "$((date_diff / 3600 % 24))" "$((date_diff / 60 % 60))" "$((date_diff % 60))"  )
      date_diff=$(($(date +%s) - $(stat -c %Y gpt.history )))
      gpt_last=$( printf "%02d/%02d:%02d:%02d\n" "$((date_diff / 86400))" "$((date_diff / 3600 % 24))" "$((date_diff / 60 % 60))" "$((date_diff % 60))" )

      if [ "$gpt" = "bard" ]; then
        gpt_no_requests=$( cat gpt.requests | grep -w "bard" | sed 's/.*=//g' )
      fi
      if [ "$gpt" = "edgegpt" ]; then
        gpt_no_requests=$( cat gpt.requests | grep -w "edgegpt" | sed 's/.*=//g' )
      fi
      if [ "$gpt" = "chatgpt" ]; then
        gpt_no_requests=$( cat gpt.requests | grep -w "chatgpt" | sed 's/.*=//g' )
      fi
      
      say="<n><b><u>Status</b></u></br></br>Engine&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: $engine_name</br>Style&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: $style</br>Runtime&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: $gpt_up</br>Last Request: $gpt_last</br>N° Requests&nbsp;:&nbsp;$gpt_no_requests</br>Version&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: <a href="$gpt_repo">$gpt_version</a></n>"
      
      if [ "$gpt" != "edgegpt" ]; then
        say=$( echo "$say" | sed 's/Style.*<\/br>Runtime/Runtime/g' )
      fi 
      
      print_msg
      exit
    fi
    if [[ "$command" = "#help" ]]; then
      say="<n><b><u>Available Commands</b></u></br></br>1) <span style="font-family:Courier">#YOUR TEXT</span> (Talk with Bot)</br>2) <span style="font-family:Courier">#engine</span> <b>[bard|edgegpt|chatgpt]</b></br>3) <span style="font-family:Courier">#style <b>[creative|balanced|precise] --> Only for EdgeGPT <-- </b></span></br>4) <span style="font-family:Courier">#status</span></br>5) <span style="font-family:Courier">#reset</span> (Reset conversation)</n>"
      print_msg
      exit
    fi
    conversation=$( echo "$command" | sed -e 's/b:\ //g' -e 's/B:\ //g' -e 's/#//g' )
    if [ "$gpt" = "edgegpt" ]; then
    	if [ -f gpt.pause ]; then
			screen -S wirebot -p0 -X stuff "⏱️ $nick: GPT request queue full. Please try again in 60 seconds. ⏱️"^M
			exit	
		fi
		
    if [ "$command" != "#help"* ] && [ "$command" != "#engine"* ] && [ "$command" != "#status"* ] && [ "$command" != "#style"* ] && [ "$command" != "#reset"* ]; then
    	echo "x" >> gpt.requests
    fi

    
    count=$(grep -o "x" gpt.requests | wc -l)
		if [[ $count -gt 200 ]]; then
    		file_age=$(($(date +%s) - $(stat -c %Y gpt.requests)))
    	if [[ $file_age -lt 6000 ]]; then
    		screen -S wirebot -p0 -X stuff "💭️ $nick: GPT Request limit reached ... waiting $((60 - file_age)) s 💭"^M
        	touch gpt.pause
        	sleep $((6000 - file_age))
        	rm gpt.pause
        	#sed -i ':a;N;$!ba;s/\n//g; s/x//g' gpt.requests
    	fi
		else
			if [ "$command" != "#help"* ] && [ "$command" != "#engine"* ] && [ "$command" != "#status"* ] && [ "$command" != "#style"* ] && [ "$command" != "#reset"* ]; then
    			echo "x" >> gpt.requests
    	fi
		fi


      gpt_check=$( ps ax | grep -v grep | grep -v sleep | grep "EdgeGPT.EdgeGPT" | grep -v "exec bash" | sed 's/\ p.*//g' | xargs )

      if [[ $gpt_check != "" ]]; then
        
        if [[ "$command" = "#reset" ]]; then
          say="<n><b>Conversation reset ...</b></n>"
          print_msg
          say=$( screen -S wirebot -p "$gpt" -X stuff "!reset"^M )
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
     	  screen -S wirebot -p "gpt" -X kill
          edgegpt_init
          exit
        fi
        screen -S wirebot -p "gpt" -X stuff "$conversation"^M
        screen -S wirebot -p "wirebot" -X stuff "/afk"^M

        value=$( cat gpt.requests | grep "$gpt" | sed 's/.*=//g' )
        new_value=$(($value + 1))
        sed -i "0,/.*$gpt=.*/ s/.*$gpt=.*/$gpt=$new_value/g" gpt.requests
        
      else
        screen -S wirebot -p "gpt" -X kill
        screen -S wirebot -x -X screen -t "gpt" bash -c "python -m EdgeGPT.EdgeGPT --history-file ~/.wirebot/gpt.history --cookie-file ~/.wirebot/edgegpt.cookies --enter-once --style $style; exec bash"
        sleep 1
        screen -S wirebot -p "gpt" -X stuff "$conversation"^M
        screen -S wirebot -p "wirebot" -X stuff "/afk"^M
    	  value=$( cat gpt.requests | grep "$gpt" | sed 's/.*=//g' )
    	  new_value=$((value + 1))
    	  sed -i "0,/.*$gpt=.*/ s/.*$gpt=.*/$gpt=$new_value/g" gpt.requests
        exit
      fi
    fi
    if [ "$gpt" = "bard" ]; then
      screen -S wirebot -p "gpt" -X stuff "$conversation\033\015"
      screen -S wirebot -p "wirebot" -X stuff "/afk"^M

      value=$( cat gpt.requests | grep "$gpt" | sed 's/.*=//g' )
      new_value=$((value + 1))
      sed -i "0,/.*$gpt=.*/ s/.*$gpt=.*/$gpt=$new_value/g" gpt.requests
    fi
    if [ "$gpt" = "chatgpt" ]; then
      screen -S wirebot -p "gpt" -X stuff "$conversation\033\015"
      screen -S wirebot -p "wirebot" -X stuff "/afk"^M

      value=$( cat gpt.requests | grep "$gpt" | sed 's/.*=//g' )
      new_value=$((value + 1))
      sed -i "0,/.*$gpt=.*/ s/.*$gpt=.*/$gpt=$new_value/g" gpt.requests
    fi
    if [ "$gpt" = "chatgpt_old" ]; then
      say="$conversation"
    
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

  fi
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
