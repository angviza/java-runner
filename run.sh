#!/bin/sh
# java runner.©2013-2021 by Quinn.Zhang (angviza@gmail.com)
#
# [Github] https://github.com/angviza/
# [Github] https://github.com/legoomd/
# Usage:
#
# 1. Put this script somewhere in your project
# 2. Make .env file
# $APP_MAINCLASS =     ~optional app main class,if not has mainfest,must set
# $APP_PARAMS    =     ~optional app params for main args
# $APP_LIBS      =     ~optional app lib jar path
# $JAVA_HOME =
# $JAVA_OPTS =     ~optional
# $HOOK_STARTED   = hook for started,like watch
# $HOOK_STOPPED   = hook for stopped,like watch
# $APP_BIN            = bin path
# $APP_BACKUP         = backup path
# 3. ./run.sh restart  or
#     /path/to/run.sh restart /path/to/.env
#
psid=0
printc() { echo -e "${@:1}\033[0m"; }
printd() { printc "\033[1;36m" "$(echo ${@:1})"; }
xenv() { set -a && source "$ENV" && shift && "$@"; }
if [ -n "$2" ]; then
   if [[ $2 == *".env" ]]; then
       env_path=$2
   else
       env_path="$2/.env"
   fi
   ENV="$(readlink -f $env_path)"
   DIR="$(dirname $(readlink -f $env_path))"
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

xenv
APP_BIN=${APP_BIN:-bin}
APP_BIN="$DIR/$APP_BIN"
APP_BACKUP_DIR=${APP_BACKUP_DIR:-backup}
APP_BACKUP_DIR="$DIR/$APP_BACKUP_DIR"


if [ -z $APP_LIBS ]; then
   CLASSPATH="$APP_BIN/$(ls -lt $APP_BIN | awk '{if ($9) printf("%s\n",$9)}' | head -n 1)"
else
   for i in $APP_LIBS/*.jar; do
      CLASSPATH="$CLASSPATH":$i
   done

   for i in $DIR/bin/*.jar; do
      CLASSPATH="$CLASSPATH":$i
   done
fi

if [ -z $APP_MAINCLASS ]; then
   op=jar
else
   op=classpath
fi

run() {
   nohup $JAVA_HOME/bin/java $JAVA_OPTS -$op $CLASSPATH $APP_MAINCLASS $APP_PARAMS >app.log 2>&1 &
   sleep ${STARTINTWAIT:-10s}
}

info() {
   DATE=$(date +%Y-%m-%d" "%H:%M:%S%z\(%Z\))
   printd "\n┌───────────────────────────────────────────────────┐\n"
   printd " ♨ [java-runner]: https://github.com/angviza/        ♨\n"
   printd "LOAD CONFIG 　: \033[1;33m $ENV"
   printd "APP_HOME　　　: \033[1;33m $DIR"
   printd "MAINCLASS 　　: \033[1;33m $APP_MAINCLASS"
   printd "CLASSPATH　　 : \033[1;33m $CLASSPATH"
   printd "JAVA_HOME 　　: \033[1;33m $JAVA_HOME"
   printd "$(uname -a)"
   printd "\n└───────────$DATE───────────┘\n\n"
}

checkpid() {
   javaps=$(ps -ef | grep -F "$CLASSPATH" | grep -v grep | awk '{print $2}')
   psid=${javaps:-0}
   if [ $psid -ne 0 ]; then
      printc "\033[1;36m✔\033[0m $APP_MAINCLASS is running! (pid=$psid)"
   else
      printc "\033[1;31m✘\033[0m $APP_MAINCLASS is \033[1;31;36mnot running"
   fi
}

start() {
   printd "\n ▶ ..\n"
   checkpid
   if [ $psid == 0 ]; then
      printc "\033[5;36mStarting $APP_MAINCLASS ..."
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
      printc "\033[6;31mStopping $APP_MAINCLASS ...(pid=$psid)"
      kill $psid
      sleep 1s
      stop
   else
      $HOOK_STOPPED
      printc "\033[1;31m $APP_MAINCLASS Stopped"
   fi
}
backup() {
   printc "\033[5;36m [Backuping]:\033[0m $APP_BIN \033[1;31m➜\033[0m $APP_BACKUP_DIR"
   mkdir -p ${APP_BACKUP_DIR}
   tar -cv $APP_BIN | gzip >${APP_BACKUP_DIR}/$(date +%Y-%m-%d"_"%H_%M_%S).tar.gz
   find ${APP_BACKUP_DIR} -mtime +${APP_BACKUP_DAY:-3} -name "*.sql.gz" -exec rm -f {} \;
   printc "\033[1;36m [Backuped]\033[0m [Sucess]"
}

status() {
   checkpid
}

log() {
   tail -100f app.log
}
main() {
   case "$1" in
   'run')
      run
      ;;
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
   'backup')
      backup
      ;;
   'test')
      test
      ;;
   *)
      echo "Usage: $0 {start|stop|restart|status|info|log} "
      exit 1
      ;;
   esac
   exit 0
}
if [ $(head -188 $0 | md5sum | awk '{printf "%s",$1}') == "c2bfaec1e32924af4ba3616285087743" ]; then
   info
   main $1
else
   echo "$0 1: syntax error near unexpected token 1, do not edit this script file"
fi
