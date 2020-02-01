#!/bin/bash
################################################################################
# Author: Praveen Gattu
# Created: 25-JAN-2020
# Version: 1.3
#
# Description: This program connects to the Tesla car and checks its range in
#              order to notify whether the car needs to be charged.
#
# Pre-requisites: Install packages jq (command-line JSON processor), python
#                 (sudo apt-get install jq python)
################################################################################

# EDIT THE FOLLOWING PARAMETERS.
# Refer to the README file for further information about the below parameters.
#

# The battery range (in miles), below which you want to be notified
BATTERY_THRESHOLD="90"

# Email receipients for the email notification.  Separate multiple recipients
# using a comma.
# Example: "your_email_1@gmail.com, your_phone_num@tmomail.net"
EMAIL_RECIPIENTS=""

# The FROM address for the email notifications.
# Example: "Your Tesla <your_email@gmail.com>"
EMAIL_FROM=""

# The access code for Notify Me for Alexa
NOTIFY_ME_CODE=""

# Login email for your tesla.com account
TESLA_USER=""

# Login password for your tesla.com account
TESLA_PSWD=""

# Location of the directory where the script is stored.
# Example: /home/pi/TeslaIntegration
SCRIPT_DIR=""

# STOP. DO NOT EDIT BELOW THIS LINE.

# Declare variables
#
JSON_DIR=${SCRIPT_DIR}/tesla_json
LOG_DIR=${SCRIPT_DIR}/logs
LOG_FILE=${LOG_DIR}/tesla_range_$(date +%Y-%m-%d).log
TESLA_HOST="https://owner-api.teslamotors.com"
LOGIN_REQUEST='{ "grant_type": "password",
  "client_id": "81527cff06843c8634fdc09e8ac0abefb46ac849f38fe1e431c2ef2106796384",
  "client_secret": "c7257eb71a564034f9419ee651c7d0e5f7aa6bfbd18bafb5c5c033b093bb2fa3",
  "email": "'${TESLA_USER}'",
  "password": "'${TESLA_PSWD}'" }'
NOTIFY_ME_URL="https://api.notifymyecho.com/v1/NotifyMe"

################################################################################
# Reusable functions...
################################################################################

# Function: log
# Input parameters: message [required]
# Writes a message to the log file.
#
function log() {
  MESSAGE=${1}
  MESSAGE_TYPE=${2}

  # if log file does not exist, then create it.
  if [ ! -e ${LOG_FILE} ]; then
    touch ${LOG_FILE}
  fi

  # append the message to the log file
  echo -e "[$(date '+%x %X')] ${MESSAGE}" >> ${LOG_FILE}

  # if it's an error message, then print to screen and exit.
  if [ "${MESSAGE_TYPE}" == "ERROR" ]; then
    echo -e ${MESSAGE}
    exit 1
  fi
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

  if [ "${ACCESS_TOKEN}" == 'null' -o "${ACCESS_TOKEN}" == "" ]; then
    log "Login to Tesla failed. Check your Tesla login data and ${JSON_DIR}/login.out\n" "ERROR"
  fi

} # end function: login

################################################################################
# End of functions.
################################################################################


# Validate parameters
if [ "${SCRIPT_DIR}" == "" ] || [ ! -w ${SCRIPT_DIR} ]; then
  echo -e "Script directory (${SCRIPT_DIR}) must be writable.\n"
  exit 1
elif [ "${BATTERY_THRESHOLD}" == "" ]; then
  echo -e "Battery range threshold is not set.  Using default value.\n"
  BATTERY_THRESHOLD=60
elif [ "${TESLA_USER}" == "" ]; then
  echo -e "ERROR: Parameter TESLA_USER is required.\n"
  exit 1
elif [ "${TESLA_PSWD}" == "" ]; then
  echo -e "ERROR: Parameter TESLA_PSWD is required.\n"
  exit 1
fi


# Check whether the log directory exists.  If not, create it.
if [ ! -d ${LOG_DIR} ]; then
  mkdir ${LOG_DIR}
  log "Created log directory.\n"
fi

# Check whether the json directory exists.  If not, create it.
if [ ! -d ${JSON_DIR} ]; then
  mkdir ${JSON_DIR}
  log "Created json directory.\n"
fi


log "==== Check Tesla Range ====\n"


# Check whether jq exists


# Check whether python exists


# get the access_token
#
log "Checking access_token in file..."
if [ -e "${JSON_DIR}/login.out" ]; then
  CURRENT_DATE=$(date +%Y%m%d)
  get_access_data

  log "Retrived access_token from file.\n"

  if [ $CURRENT_DATE -ge ${EXPIRY_DATE} ]; then
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
  log "\nNo vehicle data is received.  Access token may be invalid. Exiting.\n" "ERROR"
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
  log "\nNo charging data is received. Access token or vehicle ID may be invalid. Exiting.\n" "ERROR"
fi

write_to_file "${CHARGING_RESPONSE}" "${JSON_DIR}/charge.out" "json"
BATTERY_RANGE=$(get_json_value "response.battery_range" "${JSON_DIR}/charge.out")
# convert battery range from float (decimal number) to integer
BATTERY_RANGE=${BATTERY_RANGE%.*}
CHARGING_STATE=$(get_json_value "response.charging_state" "${JSON_DIR}/charge.out")

log "Battery Range Threshold: ${BATTERY_THRESHOLD} miles"
log "Battery Range: ${BATTERY_RANGE} miles"
log "Charging State: ${CHARGING_STATE}\n"


# check if battery range is retrieved
if [ "${BATTERY_RANGE}" == 'null' -o "${BATTERY_RANGE}" == "" ]; then
  log "Battery range could not be read. Exiting.\n" "ERROR"
fi


# check the battery range and charging state
#
if [ "${BATTERY_RANGE}" -lt "${BATTERY_THRESHOLD}" -a \
     "${CHARGING_STATE}" == "Disconnected" ]
then
  log "Tesla needs to be charged.\n" >> $LOG_FILE

  # send an email if EMAIL_RECIPIENTS is not blank
  if [ "${EMAIL_RECIPIENTS}" != "" ]; then
    # set the From email address
    if [ "${EMAIL_FROM}" != ""]; then
      log "Set From email address to: ${EMAIL_FROM}. Sending email."
      EMAIL_FROM="-aFrom:${EMAIL_FROM}"
    else
      log "There is not From email address. Using default."
    fi

    log "Sending email to: ${EMAIL_RECIPIENTS}"
    mail -s "Tesla needs to be charged" ${EMAIL_FROM} ${EMAIL_RECIPIENTS} <<_EOF
Tesla needs to be charged.  Battery range is ${BATTERY_RANGE} miles. Charger is not connected.

(Battery range threshold is set to ${BATTERY_THRESHOLD} miles)
_EOF

  else
    log "Email address is blank. No email will be sent.\n"

  fi # Email recipients is not blank

  # Send Alexa notification if Notify My Echo Access Code is not blank
  if [ "${NOTIFY_ME_CODE}" != "" ]; then
    log "Sending notification to Notify My Echo.\n"

    NOTIFY_ME_REQUEST='{
      "notification": "Your Tesla needs a charge.  Battery range is "'${BATTERY_RANGE}'" miles.",
      "accessCode": "'${NOTIFY_ME_CODE}'"
    }'

    NOTIFY_ME_RESPONSE=`curl --silent --data ${NOTIFY_ME_REQUEST} \
      --header "Content-Type: application/json" --location --request POST \
      ${NOTIFY_ME_URL}`
    write_to_file "${NOTIFY_ME_RESPONSE}" "${JSON_DIR}/notify_me.out" "json"

  else
    log "Notify My Echo Access Code is blank. No notification will be sent to Notify My Echo.\n"

  fi # Notify Me Access Code is not blank

  # The following snippet of code is commented out.  It only applies to users
  # with a ISY home automation hub.
  #
  # Set Tesla_needs_charging variable to 1, so that Alexa can announce at home.
  #
  # In the below API, 2 is for state variables, 8 is the ID for the variable
  # named "Tesla_Needs_Charging", and 1 represents the value we want to set
  # the variable to. An Alexa routine must be setup to read the variable and
  # make an announcement to charge the car.
  #
  # ISY_RESPONSE=`curl --silent --location --user ${ISY_USER}:${ISY_PSWD} \
  #  http://${ISY_HOSTNAME}/rest/vars/set/2/8/1`
  # write_to_file "${ISY_RESPONSE}" "${JSON_DIR}/isy.out" "xml"

else
  log "No need to charge.\n"

fi # end if: check battery range and charging state


# Delete log files older than 15 days
#
log "Deleting log files older than 30 days..."
find ${LOG_DIR} -type f -name 'tesla_range*.log' -mtime +30 -exec rm {} \;
log "End of execution.\n"