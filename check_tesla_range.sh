#!/bin/bash
################################################################################
# Author: Praveen Gattu
# Created: 25-JAN-2020
# Version: 1.0
#
# Description: This program connects to the Tesla car and checks its range in
#              order to notify whether the car needs to be charged.
#
# Pre-requisites: Install packages jq (command-line JSON processor), python
#                 (sudo apt-get install jq python)
################################################################################

# Setup parameters (EDIT THESE)
#

# The battery range (in miles), below which you want to be notified
BATTERY_THRESHOLD="90"

# Email receipients for the email notification.  Separate multiple recipients
# using a comma.
EMAIL_RECIPIENTS="your_email_1@gmail.com, your_email_2@gmail.com"

# The FROM address for the email notifications.
EMAIL_FROM="Your Tesla<your_email@gmail.com>"

# Login email for your tesla.com account
TESLA_USER="tesla_login@gmail.com"

# Login password for your tesla.com account
TESLA_PSWD="tesla_pswd"

# Login username for the ISY
ISY_USER="isy_user"

# Login password for the ISY
ISY_PSWD="isy_pswd"

# Location for log files.  It must be write permissions.
LOG_DIR=~pi/scripts/logs

# Location for json files.  It must be read/write permissions.
JSON_DIR=~pi/scripts/tesla_json


# Variables (DO NOT EDIT BELOW THIS LINE)
LOG_FILE=${LOG_DIR}/chk_tesla_range_$(date +%Y-%m-%d).log
TESLA_HOST="https://owner-api.teslamotors.com"
LOGIN_REQUEST='{ "grant_type": "password",
  "client_id": "81527cff06843c8634fdc09e8ac0abefb46ac849f38fe1e431c2ef2106796384",
  "client_secret": "c7257eb71a564034f9419ee651c7d0e5f7aa6bfbd18bafb5c5c033b093bb2fa3",
  "email": "'${TESLA_USER}'",
  "password": "'${TESLA_PSWD}'" }'


# Function: log
# Input parameters: message [required]
# Writes a message to the log file.
#
function log() {
  MESSAGE=${1}

  # if log file does not exist, then create it.
  if [ ! -e ${LOG_FILE} ]; then
    touch ${LOG_FILE}
  fi

  # append the message to the log file
  echo -e "[$(date '+%x %X')] ${MESSAGE}" >> ${LOG_FILE}
}  # end function: log


# Function: get_json_value
# Input parameters: JSON key [required], JSON file name [required]
# Gets the value for a json key from a given file name.  It also
# removes double-quotes around the value using "tr" command.
#
function get_json_value() {
  JSON_KEY=${1}
  JSON_FILE=${2}

  VALUE=`cat "${JSON_FILE}" | jq ".${JSON_KEY}" | tr -d '"'`

  echo ${VALUE}

} # end function: get_json_value


# Function: write_to_file
# Input parameters: data [required], file name [required], data_type [optional]
# Writes data to a file.  If the data type is JSON, it will format the JSON
# data.
#
function write_to_file() {
  DATA=${1}
  FILE_NAME=${2}
  DATA_TYPE=${3}

  if [ "${DATA_TYPE}" == "json" -o "${DATA_TYPE}" == "JSON" ]; then
    echo ${DATA} | python -m json.tool > ${FILE_NAME}
  elif [ "${DATA_TYPE}" == "xml" -o "${DATA_TYPE}" == "XML" ]; then
    echo ${DATA} | python -c 'import sys; import xml.dom.minidom; s=sys.stdin.read(); print(xml.dom.minidom.parseString(s).toprettyxml())' > ${FILE_NAME}
  else
    echo ${DATA} > ${FILE_NAME}
  fi

} # end function: write_to_file


# Function: get_access_data
# Input parameters: none
# Reads the access data from the login file.
#
function get_access_data() {
  # get data from the login file
  ACCESS_TOKEN=$(get_json_value "access_token" "${JSON_DIR}/login.out")
  local CREATED_AT=$(get_json_value "created_at" "${JSON_DIR}/login.out")
  local EXPIRES_IN=$(get_json_value "expires_in" "${JSON_DIR}/login.out")

  # calculate the expiry date based on created_at and expires_in
  EXPIRY_TS=$((CREATED_AT + EXPIRES_IN))
  EXPIRY_DATE=$(date -d @${EXPIRY_TS} +%Y%m%d)

} # end function: get_access_data


# Function: login
# Input parameters: none
# This function is invoked if there is no access_token stored in the file.
#
function login() {
  log "Login to Tesla.\n"

  LOGIN_RESPONSE=`curl --silent --data "${LOGIN_REQUEST}" --header \
    "Content-Type: application/json" --location --request POST \
    ${TESLA_HOST}/oauth/token`

  write_to_file "${LOGIN_RESPONSE}" "${JSON_DIR}/login.out" "json"

  # set the access variables
  get_access_data

} # end function: login


# End of functions.  Let's execute.
#
log "==== Check Tesla Range ====\n"

# get the access_token
#
log "Checking access_token in file..."
if [ -e "${JSON_DIR}/login.out" ]; then
  CURRENT_DATE=$(date +%Y%m%d)
  get_access_data

  log "Retrived access_token from file.\n"

  if [ ${CURRENT_DATE} -ge ${EXPIRY_DATE} ]; then
    # login since the access_token has expired
    log "The access token has expired. A new access token is required."
    login
  fi

fi  # end if: login file exists


# if access_token is blank, then login and get new access_token
#
if [ "${ACCESS_TOKEN}" == "" ]; then
  log "Unable to retrieve access_token from file.\n"
  login
fi

log "Access Token: ${ACCESS_TOKEN}"
log "Access Token Expires: $(date -d @${EXPIRY_TS} +%x)"


# get vehicles
#
VEHICLES_RESPONSE=`curl --silent \
  --header "Authorization: Bearer ${ACCESS_TOKEN}" --location \
  ${TESLA_HOST}/api/1/vehicles`

if [ "${VEHICLES_RESPONSE}" == "" ]; then
  log "\nNo vehicle data is received.  Access token may be invalid. Exiting.\n"
  echo "ERROR: No vehicle data is received."
  exit 1
fi

write_to_file "${VEHICLES_RESPONSE}" "${JSON_DIR}/vehicles.out" "json"
TESLA_ID=$(get_json_value "response[0].id" "${JSON_DIR}/vehicles.out")
log "Vehicle ID: ${TESLA_ID}\n"


# wake up car
#
log "Wake up Tesla.\n"
WAKE_RESPONSE=`curl --silent --header "Authorization: Bearer ${ACCESS_TOKEN}" \
  --location --request POST ${TESLA_HOST}/api/1/vehicles/${TESLA_ID}/wake_up`

write_to_file "${WAKE_RESPONSE}" "${JSON_DIR}/wake_up.out" "json"

# sleep for a few seconds to allow the car to wake up
sleep 5

# get charging state
#
CHARGING_RESPONSE=`curl --silent --header "Authorization: Bearer $ACCESS_TOKEN"\
  --location ${TESLA_HOST}/api/1/vehicles/${TESLA_ID}/data_request/charge_state`

if [ "${CHARGING_RESPONSE}" == "" ]; then
  log "\nNo charging data is received. Access token or vehicle ID may \
    be invalid. Exiting.\n"
  echo "ERROR: No charging data is received. Exiting."
  exit 1
fi

write_to_file "${CHARGING_RESPONSE}" "${JSON_DIR}/charge.out" "json"
BATTERY_RANGE=$(get_json_value "response.battery_range" "${JSON_DIR}/charge.out")
# convert battery range from float (decimal number) to integer
BATTERY_RANGE=${BATTERY_RANGE%.*}
CHARGING_STATE=$(get_json_value "response.charging_state" "${JSON_DIR}/charge.out")
log "Battery Range: ${BATTERY_RANGE} miles"
log "Charging State: ${CHARGING_STATE}\n"


# check if battery range is retrieved
if [ "${BATTERY_RANGE}" == 'null' -o "${BATTERY_RANGE}" == "" ]; then
  log "Battery range could not be read. Exiting.\n"
  echo -e "ERROR: Battery range could not be read. Exiting.\n"
  exit 1
fi


# check the battery range and charging state
#
if [ "${BATTERY_RANGE}" -lt "${BATTERY_THRESHOLD}" -a \
     "${CHARGING_STATE}" == "Disconnected" ]
then
  log "Battery range (${BATTERY_RANGE} miles) is lower than the threshold (${BATTERY_THRESHOLD} miles). The car is not connected to a charger. Tesla needs charging.\n" >> $LOG_FILE

  # send an email
  mail -s "Tesla needs charging" -a"From:${EMAIL_FROM}" ${EMAIL_RECIPIENTS} <<_EOF
Tesla needs charging.  Battery range is ${BATTERY_RANGE} miles. Charger is not connected.

Battery range threshold is set to ${BATTERY_THRESHOLD} miles.
_EOF

  # Set Tesla_needs_charging variable to 1, so that Alexa can announce at home.
  #
  # In the below API, 2 is for state variables, 8 is the ID for the variable
  # named "Tesla_Needs_Charging", and 1 represents the value we want to set
  # the variable to.
  #
  ISY_RESPONSE=`curl --silent --location --user ${ISY_USER}:${ISY_PSWD} \
    http://192.168.1.232/rest/vars/set/2/8/1`
  write_to_file "${ISY_RESPONSE}" "${JSON_DIR}/isy.out" "xml"

else
  log "Battery range is ${BATTERY_RANGE} miles. Battery range threshold is ${BATTERY_THRESHOLD} miles. No need to charge.\n"

fi # end if: check battery range and charging state


# Delete log files older than 15 days
#
log "Deleting log files older than 15 days..."
find ${LOG_DIR} -type f -name 'chk_tesla_range*.log' -mtime +15 -exec rm {} \;
log "Completed.\n"