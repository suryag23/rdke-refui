#!/bin/bash

LOGFILE=/opt/logs/residentapp.log

log()
{
    echo "$(date '+%Y %b %d %H:%M:%S.%6N') [#$$]: ${FUNCNAME[1]}: $*" >> $LOGFILE
}

# Check if all the commands used in this script are available
commandsRequired="echo date WPEFrameworkSecurityUtility awk sed curl exit tr sleep"
for cmd in $commandsRequired; do
    if ! command -v $cmd > /dev/null; then
        log "Required command '$cmd' not found; cannot proceed, exiting."
        exit 1
    fi
done

TOKEN=`WPEFrameworkSecurityUtility | sed -r 's/[{:",}]/ /g' | awk '{print $2}'`

if [ $# -gt 0 ]; then
   if [[ $1 == "stop" ]]; then
      curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" 'http://127.0.0.1:9998/jsonrpc' -d '{"jsonrpc": "2.0","id": 4,"method": "org.rdk.RDKShell.1.destroy", "params": {"callsign":"ResidentApp","type": "ResidentApp"}}' >>$LOGFILE 2>&1
      log "Stop called. Exiting gracefully"
      exit 0
   fi
fi

appurl="http://127.0.0.1:50050/lxresui/index.html#splash"

log "Selected reference app is $appurl"

getRDKShellPluginStatus()
{
    output=$(curl -sS -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" --request POST --data '{"jsonrpc":"2.0","id":1,"method":"Controller.1.status@org.rdk.RDKShell"}' http://127.0.0.1:9998/jsonrpc)
    echo $(echo $output | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'state'\042/){print $(i+1)}}}' | tr -d '"')
}

waitForRDKShellPluginUp()
{
    while true
    do
        status=$(getRDKShellPluginStatus)
        if [ "$status" = "activated" ]; then
            log "RDKShell plugin activated"
            break
        else
            log "RDKShell plugin state is $status. Waiting for plugin to be activated"
            sleep 1
        fi
    done
}

curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" 'http://127.0.0.1:9998/jsonrpc' -d '{"jsonrpc": "2.0","id": 4,"method": "org.rdk.RDKShell.1.launch", "params": {"callsign":"ResidentApp","type": "ResidentApp","visible": true,"focus": true,"uri":'"$appurl?data=$partnerApps"'}}' >>$LOGFILE 2>&1
