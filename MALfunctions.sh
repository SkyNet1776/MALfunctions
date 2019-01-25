#!/bin/bash
#Just source this file and than run the commands in terminal. Or better yet, put it in your .bashrc

 USERAGENT="$HOSTNAME $0"
 REFERER=""
 LOGIN_STATUS=0

 MALfunctions(){
          echo -e "\nLogin         -     Logs in"
          echo      "Logout        -     Logs out"
          echo      "LoginStatus   -     Displays current login status"
          echo      "UpdateCSRF    -     Updates CSRF Token"
          echo      "NewComment    -     Make a comment on another user's profile"
          echo      "NewReply      -     Make a reply in a thread"
          echo      "NewThread     -     Make a new thread"
          echo -e "\nIf posting isn't working and you're logged in, try UpdateCSRF"
}
 
Login() {
          set -f
          echo -e "\nEnter username:"
          read -r USERNAME            #this is your username
          echo -e "\nEnter password:"
          read -r PASSWORD            #this is your password, dumbshit
          
          if [ $LOGIN_STATUS -gt 0 ]; then
                    echo -e "\nYou're already logged in!"; return 1; fi
                    
          BUFF=$(curl -s -c - https://myanimelist.net/)
          CSRF_TOKEN=$( printf "%s" "$BUFF" | grep csrf_token | awk -F "'" '{print $4}')
          MALSESSIONID=$(printf "%s" "$BUFF" | grep MALSESSIONID | awk -F "\t" '{print $7}')

          BUFF=$(curl -s -c - "https://myanimelist.net/login.php?from=%2F" -H "authority: myanimelist.net" -H "pragma: no-cache" -H "cache-control: no-cache" -H "origin: https://myanimelist.net" -H "upgrade-insecure-requests: 1" -H "dnt: 1" -H "content-type: application/x-www-form-urlencoded" -H "user-agent: $USERAGENT" -H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" -H "referer: $REFERER" -H "accept-encoding: gzip, deflate, br" -H "accept-language: en-US,en;q=0.9" -H "cookie: MALSESSIONID=$MALSESSIONID" --data "user_name=$USERNAME&password=$PASSWORD&sublogin=Login&submit=1&csrf_token=$CSRF_TOKEN" --compressed)
          
          LOGIN_STATUS=$(printf "%s" "$BUFF" | grep -c  is_logged_in)
          if [ $LOGIN_STATUS == 0 ]; then
                    echo -e "\nLogin failed!"; return 1; fi
          
          CSRF_TOKEN=$(printf "%s" "$BUFF" | grep csrf_token | awk -F "'" '{print $4}')
          MALSESSIONID=$(printf "%s" "$BUFF" | grep MALSESSIONID | awk -F "\t" '{print $7}')
          MALHLOGSESSID=$(printf "%s" "$BUFF" | grep MALHLOGSESSID | awk -F "\t" '{print $7}')

          BUFF=$(curl -s "https://myanimelist.net/" -H "authority: myanimelist.net" -H "pragma: no-cache" -H "cache-control: no-cache" -H "upgrade-insecure-requests: 1" -H "dnt: 1" -H "user-agent: $USERAGENT" -H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" -H "referer: $REFERER" -H "accept-encoding: gzip, deflate, br" -H "accept-language: en-US,en;q=0.9" -H "cookie: MALHLOGSESSID=$MALHLOGSESSID; MALSESSIONID=$MALSESSIONID; is_logged_in=1" --compressed)
          CSRF_TOKEN=$( printf "%s" "$BUFF" | grep csrf_token | awk -F "'" '{print $4}')

          echo -e "\n$USERNAME is logged in."
          set +f
}

UpdateCSRF() {
          if [ $LOGIN_STATUS == 0 ]; then
                    echo -e "You're not logged in!"; return 1; fi

          BUFF=$(curl -s "https://myanimelist.net/" -H "authority: myanimelist.net" -H "pragma: no-cache" -H "cache-control: no-cache" -H "upgrade-insecure-requests: 1" -H "dnt: 1" -H "user-agent: $USERAGENT" -H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" -H "referer: $REFERER" -H "accept-encoding: gzip, deflate, br" -H "accept-language: en-US,en;q=0.9" -H "cookie: MALHLOGSESSID=$MALHLOGSESSID; MALSESSIONID=$MALSESSIONID; is_logged_in=1" --compressed)
          CSRF_TOKEN=$( printf "%s" "$BUFF" | grep csrf_token | awk -F "'" '{print $4}')
}

Logout() {
            if [ $LOGIN_STATUS == 0 ]; then
                    echo -e "You're not logged in!"; return 1; fi

          UpdateCSRF

          curl -s "https://myanimelist.net/logout.php" -H "authority: myanimelist.net" -H "pragma: no-cache" -H "cache-control: no-cache" -H "origin: https://myanimelist.net" -H "upgrade-insecure-requests: 1" -H "dnt: 1" -H "content-type: application/x-www-form-urlencoded" -H "user-agent: $USERAGENT" -H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" -H "referer: $REFERER" -H "accept-encoding: gzip, deflate, br" -H "accept-language: en-US,en;q=0.9" -H "cookie: $MALHLOGSESSID; MALSESSIONID=$MALSESSIONID; is_logged_in=1; _gat=1" --data "csrf_token=$CSRF_TOKEN" --compressed > /dev/null 2>&1

          LOGIN_STATUS="0"
}

NewComment(){
          if [ $LOGIN_STATUS == 0 ]; then
                    echo -e "You're not logged in!"; return 1; fi

          set -f
          echo -e "\nEnter name of user profile to comment on:"
          read -r USER
          echo -e "\nEnter the text of the message (use \\\n for a line break):"
          read -r TEXT       
          TEXT=$(echo $TEXT | sed "s/%/%25/g" | sed 's/\\n/%0A/g' | sed 's/\\/%5C/g' | sed "s/:/%3A/g"|  sed "s/{/%7B/g" | sed "s/}/%7D/g" | sed 's/?/%3F/g' | sed "s/,/%2C/g" | sed 's/</%3C/g' | sed "s/>/%3E/g" | sed "s/@/%40/g" | sed "s/#/%23/g" | sed "s/\\$/%24/g" | sed "s/\^/%5E/g" | sed "s/&/%26/g" | sed "s/+/%2B/g" | sed "s/=/%3D/g" | sed "s/'/'/g" | sed 's/"/%22/g' | sed "s/\[/%5B/g" | sed "s/]/%5D/g" | sed "s/|/%7C/g" | sed "s/\`/%60/g")
          
          BUFF=$(curl -s -c - https://myanimelist.net/profile/$USER)
          USERID=$( printf "%s" "$BUFF" | grep comments.php?id= | tr '\n' ' ' | awk -F "=" '{print $3}' |  awk -F '"' '{print $1}')

          curl -s "https://myanimelist.net/addcomment.php" -H "cookie: MALSESSIONID=$MALSESSIONID; is_logged_in=1" -H "origin: https://myanimelist.net" -H "accept-encoding: gzip, deflate, br" -H "accept-language: en-US,en;q=0.9" -H "x-requested-with: XMLHttpRequest" -H "pragma: no-cache" -H "user-agent: $USERAGENT" -H "content-type: application/x-www-form-urlencoded; charset=UTF-8" -H "accept: */*" -H "cache-control: no-cache" -H "authority: myanimelist.net" -H "referer: $REFERER" -H "dnt: 1" --data "commentSubmit=1&profileMemId=$USERID&profileUsername=$USER&commentText=$TEXT&area=2&csrf_token=$CSRF_TOKEN" --compressed
          set +f
}

NewReply(){
           if [ $LOGIN_STATUS == 0 ]; then
                    echo -e "You're not logged in!"; return 1; fi
                    
          set -f
          echo -e "\nEnter thread number:"
          read -r THREAD
          
          echo -e "\nEnter the text of the message (use \\\n for a line break):"
          read -r TEXT       
          TEXT=$(echo $TEXT | sed "s/%/%25/g" | sed 's/\\n/%0A/g' | sed 's/\\/%5C/g' | sed "s/:/%3A/g"|  sed "s/{/%7B/g" | sed "s/}/%7D/g" | sed 's/?/%3F/g' | sed "s/,/%2C/g" | sed 's/</%3C/g' | sed "s/>/%3E/g" | sed "s/@/%40/g" | sed "s/#/%23/g" | sed "s/\\$/%24/g" | sed "s/\^/%5E/g" | sed "s/&/%26/g" | sed "s/+/%2B/g" | sed "s/=/%3D/g" | sed "s/'/'/g" | sed 's/"/%22/g' | sed "s/\[/%5B/g" | sed "s/]/%5D/g" | sed "s/|/%7C/g" | sed "s/\`/%60/g")
          
          curl -s "https://myanimelist.net/forum/?action=message&topic_id=$THREAD" -H "authority: myanimelist.net" -H "pragma: no-cache" -H "cache-control: no-cache" -H "origin: https://myanimelist.net" -H "upgrade-insecure-requests: 1" -H "dnt: 1" -H "content-type: application/x-www-form-urlencoded" -H "user-agent: $USERAGENT" -H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" -H "referer: $REFERER" -H "accept-encoding: gzip, deflate, br" -H "accept-language: en-US,en;q=0.9" -H "cookie: MALSESSIONID=$MALSESSIONID; is_logged_in=1; " --data "msg_text=$TEXT&submit=Submit&board_id=&subboard_id=&csrf_token=$CSRF_TOKEN" --compressed
          set +f
}

NewThread(){
           if [ $LOGIN_STATUS == 0 ]; then
                    echo -e "You're not logged in!"; return 1; fi
          set -f
          echo -e "\nBoards:"
          echo      "Anime Discussion                    -     1"
          echo      "Manga Discussion                    -     2"
          echo      "Support                             -     3"
          echo      "Suggestions                         -     4"
          echo      "Updates and Announcments            -     5"
          echo      "Current Events                      -     6"
          echo      "Games, Computers & Tech Support     -     7"
          echo      "Introductions                       -     8"
          echo      "Forum Games                         -     9"
          echo      "Music & Entertainment               -     10"
          echo      "Casual Discussion                   -     11"
          echo      "Creative Corner                     -     12"
          echo      "MAL Contests                        -     13"
          echo      "MAL Guidelines & FAQ                -     14"
          echo      "News Discussion                     -     15"
          echo      "Anime and Manga Rec.                -     16"
          echo -e "DB Modifcation Requests             -     17\n"
          
          echo      "Sub Boards:"
          echo      "Anime - Series Discussion           -     1     (Board not supported)"
          echo      "DB Mod Req - Anime                  -     2"
          echo      "DB Mod Req - Character & People     -     3"
          echo      "Manga - Series Discussion           -     4     (Board not supported)"
          echo -e "DB Mod Req - Manga                  -     5\n"

                                        
          echo -e "\nEnter board number (leave blank if posting on a Sub Board):"
          read -r  BOARD                                                           
          
          echo -e "\nEnter sub-board number (leave blank if posting on a Main Board):"
          read -r  SUBBOARD
          
          echo -e "\nEnter subject:"
          read -r  SUBJECT
          SUBJECT=$( echo $SUBJECT | sed "s/%/%25/g" | sed 's/\\n/%0A/g' | sed 's/\\/%5C/g' | sed "s/:/%3A/g"|  sed "s/{/%7B/g" | sed "s/}/%7D/g" | sed 's/?/%3F/g' | sed "s/,/%2C/g" | sed 's/</%3C/g' | sed "s/>/%3E/g" | sed "s/@/%40/g" | sed "s/#/%23/g" | sed "s/\\$/%24/g" | sed "s/\^/%5E/g" | sed "s/&/%26/g" | sed "s/+/%2B/g" | sed "s/=/%3D/g" | sed "s/'/'/g" | sed 's/"/%22/g' | sed "s/\[/%5B/g" | sed "s/]/%5D/g" | sed "s/|/%7C/g" | sed "s/\`/%60/g")
          
          echo -e "\nEnter the text of the message (use \\\n for a line break):"
          read -r  TEXT       
          TEXT=$(echo $TEXT | sed "s/%/%25/g" | sed 's/\\n/%0A/g' | sed 's/\\/%5C/g' | sed "s/:/%3A/g"|  sed "s/{/%7B/g" | sed "s/}/%7D/g" | sed 's/?/%3F/g' | sed "s/,/%2C/g" | sed 's/</%3C/g' | sed "s/>/%3E/g" | sed "s/@/%40/g" | sed "s/#/%23/g" | sed "s/\\$/%24/g" | sed "s/\^/%5E/g" | sed "s/&/%26/g" | sed "s/+/%2B/g" | sed "s/=/%3D/g" | sed "s/'/'/g" | sed 's/"/%22/g' | sed "s/\[/%5B/g" | sed "s/]/%5D/g" | sed "s/|/%7C/g" | sed "s/\`/%60/g")      
          
          curl -s "https://myanimelist.net/forum/?action=post&boardid=$BOARD" -H "authority: myanimelist.net" -H "pragma: no-cache" -H "cache-control: no-cache" -H "origin: https://myanimelist.net" -H "upgrade-insecure-requests: 1" -H "dnt: 1" -H "content-type: application/x-www-form-urlencoded" -H "user-agent: $USERAGENT" -H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" -H "referer: $REFERER" -H "accept-encoding: gzip, deflate, br" -H "accept-language: en-US,en;q=0.9" -H "cookie: MALSESSIONID=$MALSESSIONID; is_logged_in=1" --data "topic_title=$SUBJECT&msg_text=$TEXT&pollQuestion=&pollOption%5B%5D=&submit=Submit&board_id=$BOARD&subboard_id=$SUBBOARD&csrf_token=$CSRF_TOKEN" --compressed
          set +f
}

LoginStatus(){
echo "Status: $LOGIN_STATUS"
}
