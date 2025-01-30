#_ECHO_OFF

# TO RUN:
# cd $DEMO_HOME; demorunner app-advisor.sh 1

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

#sdk install java 21.0.3-graal
#sdk use java 21.0.3-graal

VERSION=1.1.2
GROUP_ID=com.vmware.tanzu.spring
# rm ~/bin/advisor; rm ~/jar/tanzu-spring-server.jar
# Assumes username and password for commercial library access is in ~/.m2/settings.xml
getServer() { echo "Downloading App Advisor Server v${VERSION}" && FILE=tanzu-spring-server-${VERSION}.jar && mvn -q dependency:get -Dartifact=${GROUP_ID}:tanzu-spring-server:${VERSION}:jar -Dtransitive=false -Ddest=. && mv ${FILE} ~/jar/tanzu-spring-server.jar; }
getCLI() { echo "Downloading App Advisor CLI v${VERSION}" && FILE=application-advisor-cli-macos-arm64-${VERSION}.tar && mvn -q dependency:get -Dartifact=${GROUP_ID}:application-advisor-cli-macos-arm64:${VERSION}:tar -Dtransitive=false -Ddest=. && tar -xf ${FILE} --strip-components=1 --exclude=./META-INF && mv advisor ~/bin/ && rm ${FILE}; }

export ADVISOR_SERVER=http://localhost:9003
export TANZU_HUB_URL=https://www.platform-dev.tanzu.broadcom.com

export TANZU_PLATFORM_CSP_URL=https://console-stg.tanzu.broadcom.com    # Svc to generate an access token from app id and app secret (not needed in prod env)
export TANZU_PLATFORM_INTEGRATION_ENABLED=true
export TANZU_PLATFORM_URL=https://data.platform-dev.tanzu.broadcom.com  # Use dev env to use the latest release available internally
export TANZU_PLATFORM_ORG_ID=$(op read "op://Personal/paty5smylp5kqqyovpkw2ww4xy/tanzuHub-nimbusOrg-ID")   # Org: Tanzu_Hub_BE_Nimbus_Org
export TANZU_PLATFORM_APP_ID=$(op read "op://Personal/paty5smylp5kqqyovpkw2ww4xy/tanzuHub-nimbusOrg-app-advisor-cora-oauthAppID")
export TANZU_PLATFORM_APP_SECRET=$(op read "op://Personal/paty5smylp5kqqyovpkw2ww4xy/tanzuHub-nimbusOrg-app-advisor-cora-oauthAppSecret")

export TANZU_PLATFORM_APP_ID=y3IswVnwPBCVt5SeMCNU0F1rZoZlUJJUkbK    # OAuth App: app-advisor-cora
if [ -z $TANZU_PLATFORM_APP_SECRET ]; then export TANZU_PLATFORM_APP_SECRET=$(op read op://Work/GitHub/access-token-app-advisor); fi
export TANZU_PLATFORM_APP_SECRET=WxftRY1tOkcSa0X0LXTw4erFVNipbSbeBjDb4pJolKJDdrDpgA

# If running, stop server
pid=$(pgrep -f tanzu-spring-server.jar) && echo "Stopping App Advisor Server [pid=$pid]" && pkill -9 -f tanzu-spring-server.jar
# Install or update server and CLI versions, if necessary
command -v advisor &> /dev/null && advisor --version 2> /dev/null | grep -q "Version: ${VERSION}" || { getServer && getCLI; } || exit 1
# Start server
export ADVISOR_SERVER_LOG=/tmp/advisor-server-9003.log
echo -e "\n\n STARTING SERVER FROM $PWD ON $(date) \n\n" >> ${ADVISOR_SERVER_LOG}
nohup java -jar -Dserver.port=9003 ~/jar/tanzu-spring-server.jar > ${ADVISOR_SERVER_LOG} 2>&1 &
echo "Started App Advisor Server [pid=$(pgrep -f tanzu-spring-server.jar), log=${ADVISOR_SERVER_LOG}]"

echo "Setting GIT_TOKEN_FOR_PRS (for pull requests)"
if [ -z $GIT_TOKEN_FOR_PRS ]; then export GIT_TOKEN_FOR_PRS=$(op read op://Work/GitHub/access-token-app-advisor); fi

rm -rf app-advisor-demo
gh repo delete ciberkleid/app-advisor-demo --yes
# Use Neven's repo:
gh repo fork nevenc/familycashcard-spring-application-advisor-demo --fork-name app-advisor-demo --default-branch-only --clone -- --depth=1
cd app-advisor-demo

# Try with App Advisor demo version of petclinic
# Notes: This repo does not allow forks and it generates a plan with only one step so actually not a good fit for this script
#gh repo clone pivotal-cf/spring-petclinic && cd spring-petclinic && git checkout 2.7.3-demo
#gh repo create ciberkleid/app-advisor-demo --private
#git remote set-url origin git@github.com:ciberkleid/app-advisor-demo.git
#git push -u origin main
#cd ..
#rm -rf spring-petclinic
#gh repo clone ciberkleid/app-advisor-demo

clear
#_ECHO_ON
advisor --help
echo $ADVISOR_SERVER
http -b $ADVISOR_SERVER/actuator/info
# http -b $ADVISOR_SERVER/actuator/health
#env | sort | grep TANZU | grep -v SECRET

clear
#_ECHO_# Step 1: Evaluate your app dependencies (libs & tools)
ls
head -n 21 pom.xml
advisor build-config get
ls target/.advisor  # Generated SBOM (CycloneDX)
cat target/.advisor/build-config.json | jq 'keys'
cat target/.advisor/build-config.json | jq '.tools'
cat target/.advisor/build-config.json | jq '.sbom'

clear
#_ECHO_# Optional: upload to UI (evaluates Spring/micrometer & transitive dependencies)
advisor build-config publish
cat $ADVISOR_SERVER_LOG
open $TANZU_HUB_URL/repositories/list

clear
#_ECHO_# Step 2: Use the file to generate an upgrade plan
advisor upgrade-plan get

#_ECHO_# Step 3: Apply the first step in the plan (manual commit/push example)
advisor upgrade-plan apply
git diff
git commit -am "Spring App Advisor demo - iteration 1" && git push

clear
#_ECHO_# Step 4: Rinse & Repeat! First, regenerate the upgrade plan
advisor build-config get && advisor upgrade-plan get
#_ECHO_#  Then, apply the next step, this time with an automatic Pull Request!
advisor upgrade-plan apply --push --token=$GIT_TOKEN_FOR_PRS

#_ECHO_# Merge the PR!

########## MANUALLY:
########## Click on the link to the PR in the output above
########## Merge the PR and delete the branch

git restore . && git clean -fd && git pull
#_ECHO_# Then repeat! (third out of four cycles...)
advisor build-config get && advisor upgrade-plan apply
git commit -am "Spring App Advisor demo - iteration 3" && git push

#_ECHO_# How are we doing? Let's check using the UI
advisor build-config get && advisor build-config publish
open $TANZU_HUB_URL/repositories/list

##_ECHO_# And finally, the last step!
#advisor build-config get && advisor upgrade-plan apply
#git commit -am "Spring App Advisor demo - iteration 4" && git push
##_ECHO_# Check out the final result
#advisor build-config get && advisor upgrade-plan get
#advisor build-config publish && open $TANZU_PLATFORM_URL

clear
#_ECHO_# App Advisor in GitHub Actions
#_ECHO_OFF
open https://github.com/pivotal-cf/spring-petclinic/pull/3177/files
open https://github.com/pivotal-cf/spring-petclinic/actions/runs/9562036835/job/26357557327
open https://github.com/pivotal-cf/spring-petclinic/actions/runs/9562036835/workflow
#_ECHO_ON

#_ECHO_# Questions?
pkill -9 -f tanzu-spring-server.jar
#_ECHO_# Questions?
#_ECHO_#
#_ECHO_#
