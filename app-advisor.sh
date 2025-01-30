#_ECHO_OFF

# TO RUN:
# cd $DEMO_HOME; demorunner app-advisor 1

export DEMO_NAME="app-advisor"

echo "DEMO_NAME=${DEMO_NAME}"
# Set DEMO_HOME in your shell profile script (e.g. add "export DEMO_HOME=~/workspace/demorunner-scripts" to ~/.zprofile or ~/.bash_profile)
echo "DEMO_HOME=${DEMO_HOME}"
export DEMO_TEMP="${DEMO_HOME}/tmp/${DEMO_NAME}"
echo "DEMO_TEMP=${DEMO_TEMP}"
tabset --title ${DEMO_NAME}
rm -rf ${DEMO_TEMP}
mkdir -p ${DEMO_TEMP}
if [ -n "$(find files/${DEMO_NAME} -mindepth 1 -print -quit 2>/dev/null)" ]; then cp -R files/${DEMO_NAME}/* ${DEMO_TEMP}; else echo "No files in files/${DEMO_NAME} to copy"; fi
cd ${DEMO_TEMP}

DEMO_DELAY=0

export VERSION=1.1.2
export ARTIFACT=com.vmware.tanzu.spring:tanzu-spring-server
getTanzuSpringServer() { echo "Getting Tanzu Spring Server..."; if [[ -f "tanzu-spring-server.jar" ]]; then echo "Tanzu Spring Server already downloaded"; else mvn dependency:get -Dartifact=$ARTIFACT:$VERSION -Ddest=. > /dev/null 2>&1 && mv tanzu-spring-server-$VERSION.jar tanzu-spring-server.jar; fi }
startTanzuSpringServer() { echo "Starting Tanzu Spring Server..."; java -jar -Dserver.port=9003 tanzu-spring-server.jar > /dev/null 2>&1 & }
stopTanzuSpringServer() { echo "Stopping Tanzu Spring Server..."; PID=$(ps aux | grep 'tanzu-spring-server.jar' | grep -v grep | awk '{print $2}'); if [[ -n "$PID" ]]; then kill -9 $PID; else echo "Tanzu Spring Server is not running"; fi }

getTanzuSpringServer
stopTanzuSpringServer
startTanzuSpringServer

#_ECHO_ON
open http://localhost:9003/actuator/health

#_ECHO_# Questions?
#_ECHO_#
#_ECHO_#
#_ECHO_#
