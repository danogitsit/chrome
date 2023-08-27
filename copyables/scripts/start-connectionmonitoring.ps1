###############################################################
##
## Connection Monitor
##
###############################################################

# Shared Functions

function writeMessage($message){
     $message >> /scripts/connectionMonitor.log
}

# Script start

writeMessage "INFO: $(get-date) Script started"

# Global Vars

# Maximum Disconnect - the time in which the script will initiate a post response from the time of disconnection

[int]$maxDisconnect = $env:VNC_MAX_INACTIVE_SEC

writeMessage "VAR: VNC_MAX_INACTIVE_SEC=$maxDisconnect"

# Script Sleep - the time between each executions of this script

[int]$scriptSleep = $env:VNC_MAX_INACTIVE_CHECK

writeMessage "VAR: VNC_MAX_INACTIVE_CHECK=$scriptSleep"

# Report URL - the url to post a response to on inactivity

[string]$reportUrl = $env:VNC_MAX_INACTIVE_REPORTURL

writeMessage "VAR: VNC_MAX_INACTIVE_REPORTURL=$reportUrl"

# containerName - the identity of this container in which to include to the reporting Url

[string]$containerName = $env:VNC_CONTAINER_NAME

writeMessage "VAR: VNC_CONTAINER_NAME=$containerName"

# Internal Vars

$i = 0
$activeTime = get-date
$disconnectTime = $null

# Script loop

while($true){

     # Start process
     
     # Counter

     $i++

     # Information

     writeMessage "INFO: $(get-date) Starting sleep of $scriptSleep seconds before executing..."

     # Sleep for next output

     start-sleep -seconds $scriptSleep

     # Long run garbage collection

     if (($i % 200) -eq 0)
     {
          [System.GC]::Collect()
     }

     # Check VNC connections

     $result = Invoke-Command -ScriptBlock {
          x11vnc -query client_count -display :1
     }

     if($result -notlike "aro=client_count:*"){
          writeMessage "ERROR: $(get-date) Result from x11vnc was not in the correct format, skipping and assuming active..."
          $activeTime = get-date
          $disconnectTime = $null          
          continue
     }

     try{
          [int]$pResult = ($result -split ":")[1]}
     catch{
          writeMessage "ERROR: $(get-date) Result from x11vnc could not be parsed"
          continue
     }

     if($pResult){
          writeMessage "`tVNC connection is ACTIVE"
          $activeTime = get-date
          $disconnectTime = $null
     }else{    
          writeMessage "`tVNC connection is NOT active"
          
          if($disconnectTime){

               $dPeriod = $((New-TimeSpan -start $activeTime -end $disconnectTime).TotalSeconds)

               writeMessage "`tTime since last active was $([math]::Round($dPeriod)) seconds ago"

               # Identify disconnection exceedence

               if($dPeriod -ge $maxDisconnect){

                    writeMessage "INFO: $(get-date) Container has exceeded the disconnect time of $maxDisconnect"    

                    try{

                         $response = Invoke-WebRequest -Uri $reportUrl -Method Post -body (@{
                              name=$containerName
                              disconnectTime=$maxDisconnect
                              checkTime=$scriptSleep
                              disconnectPeriod=$dPeriod
                         } | ConvertTo-Json) -ContentType "application/json" -errorAction Stop

                         writeMessage "INFO: $(get-date) Sucessfully posted the monitoring status to the endpoint with response: $($response.Content)"
                         
                         # Reset the active time

                         $activeTime = get-date

                    }catch{
                         writeMessage "ERROR: $(get-date) There was an error posting the monitoring status to the endpoint"
                    }
                    
               }

          }

          $disconnectTime = get-date
     }

} 