#!/bin/sh
#
# java runner.©2013-2021 by Quinn.Zhang (angviza@gmail.com)
# Usage:
#
# 1. Put this script somewhere in your project
# 2. Make .env file
# $MAINCLASS =     ~optional app main class,if not has mainfest,must set
# $PARAMS    =     ~optional app params for main args
# $LIBS      =     ~optional app lib jar path
# $JAVA_HOME =     
# $JAVA_OPTS =     ~optional
# $HOOK_STARTED   = hook for started,like watch
# $HOOK_STOPPED   = hook for stopped,like watch
# $BIN            = bin path
# $BACKUP         = backup path
# 3. ./run.sh restart  or ./run.sh restart ../path/to/.env
printc() { echo -e "${@:1}\033[0m"; }
printd() { printc "\033[1;36m" "$(echo ${@:1})"; }
xenv() { set -a && source "$ENV" && shift && "$@"; }
if [ -n "$2" ]; then
   ENV="$(readlink -f $2)"
   DIR="$(dirname $(readlink -f $2))"
else
   PWD="$0"
   while [ -h "$PWD" ]; do 
      DIR="$(cd -P "$(dirname "$PWD")" && pwd)"
      PWD="$(readlink "$PWD")"
      [[ $PWD != /* ]] && PWD="$DIR/$PWD" 
   done
   DIR="$(cd -P "$(dirname "$PWD")" && pwd)"
   ENV="$DIR/.env"
fi

printd "load run config from　 　: \033[1;33m $ENV "
printd "work dir　 　 　 　 　 　: \033[1;33m $DIR "
xenv
BIN=${BIN:-bin}
BIN="$DIR/$BIN"
BACKUP=${BACKUP:-backup}
BACKUP="$DIR/$BACKUP"
psid=0

if [ -z $MAINCLASS ]; then
   CLASSPATH="$BIN/$(ls -lt $BIN | awk '{if ($9) printf("%s\n",$9)}' | head -n 1)"
   op="jar"
else
   for i in $LIBS/*.jar; do
      CLASSPATH="$CLASSPATH":$i
   done

   for i in $DIR/bin/*.jar; do
      CLASSPATH="$CLASSPATH":$i
   done
   op=classpath
fi

run() {
   nohup $JAVA_HOME/bin/java $JAVA_OPTS -$op $CLASSPATH $MAINCLASS $PARAMS >app.log 2>&1 &
   sleep ${STARTINTWAIT:-10s}
}

checkpid() {
   javaps=$(ps -ef | grep -F "$CLASSPATH" | grep -v grep | awk '{print $2}')
   psid=${javaps:-0}
   if [ $psid -ne 0 ]; then
      printc "\033[1;36m✔\033[0m $MAINCLASS is running! (pid=$psid)"
   else
      printc "\033[1;31m✘\033[0m $MAINCLASS is \033[1;31;36mnot running ☠ "
   fi
   printc "\033[8;31m$psid"
}

start() {
   checkpid
   if [ $psid -eq 0 ]; then
      printc "\033[5;36mStarting $MAINCLASS ..."
      run
      cnt=0
      while [ $cnt -le 100 ]; do
         checkpid
         if [ $psid -ne 0 ]; then
            $HOOK_STARTED
            break
         fi
         sleep 1s
         cnt=$(($cnt + 1))
      done

      if [ $psid -eq 0 ]; then
         echo "[Failed]"
      fi
   fi
}

stop() {
   checkpid

   if [ $psid -ne 0 ]; then
      printc "\033[6;31mStopping $MAINCLASS ...(pid=$psid) "
      kill $psid
      if [ $? -eq 0 ]; then
         echo "[OK]"
      else
         echo "[Failed]"
      fi
      $HOOK_STOPPED
      sleep 1s
      checkpid
      if [ $psid -ne 0 ]; then
         stop
      fi
   fi
}
backup() {
   printc "\033[5;36m back $BIN to $BACKUP"
   mkdir -p ${BACKUP}
   tar -cv $BIN | gzip >${BACKUP}/$(date +%Y-%m-%d"_"%H_%M_%S).tar.gz
   find ${BACKUP} -mtime +3 -name "*.sql.gz" -exec rm -f {} \;
   printc "\033[1;36m back sucess"
}
info() {
   printc "\033[1;31;42m" "System Information:"
   printc "\033[1;36m****************************"
   printc "$(head -n 1 /etc/issue)"
   printc "$(uname -a)"
   printc "JAVA_HOME=$JAVA_HOME"
   printc "$($JAVA_HOME/bin/java -version)"
   printc "APP_HOME=$DIR"
   printc "MAINCLASS=\033[5;31;46m$MAINCLASS"
   printc "\033[1;36m****************************"
}
status() {
   checkpid
}

log() {
   tail -100f app.log
}

case "$1" in
'start')
   start
   ;;
'stop')
   stop
   ;;
'restart')
   stop
   start
   ;;
'status')
   status
   ;;
'info')
   info
   ;;
'log')
   log
   ;;
'update')
   update
   ;;
'check')
   checkpid
   ;;
'backup')
   backup
   ;;
'test')
   test
   ;;
*)
   echo "Usage: $0 {start|stop|restart|status|info|log}"
   exit 1
   ;;
esac
exit 0
