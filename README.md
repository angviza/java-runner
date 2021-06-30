# java-runner
shell for java runner

## Usage:

1. Put this script somewhere in your project or public script dir
2. Make .env file in your project root dir
```sh
APP_MAINCLASS =     #~optional app main class,if not has mainfest,must set
APP_PARAMS    =     #~optional app params for main args
APP_LIBS      =     #~optional app lib jar path
JAVA_HOME = /path/to/java/home
JAVA_OPTS =      #~optional
HOOK_STARTED   = #hook for started,like watch
HOOK_STOPPED   = #hook for stopped,like watch
APP_BIN            = #bin path
APP_BACKUP         = #backup path
```
3. run
```sh
./run.sh restart
#or 
/path/to/run.sh restart /path/.env
```