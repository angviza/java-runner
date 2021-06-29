# java-runner
shell for java runner

## Usage:

1. Put this script somewhere in your project or public script dir
2. Make .env file in your project root dir
```sh
MAINCLASS =     ~optional app main class,if not has mainfest,must set
PARAMS    =     ~optional app params for main args
LIBS      =     ~optional app lib jar path
JAVA_HOME =     
JAVA_OPTS =     ~optional
HOOK_STARTED   = hook for started,like watch
HOOK_STOPPED   = hook for stopped,like watch
BIN            = ~optional bin path default bin
BACKUP         = ~optional backup path default backup
```
3. run
```sh
./run.sh restart  #
#or 
./run.sh restart ../path/to/.env
```