# TeslaIntegration
Integrate Tesla car with your home.  The programs in this project are designed to run in a Bash shell environment on a Raspberry Pi.  In theory, they should run on any Linux OS or Mac OS X, but I have not tested them.

This project includes the following integrations:

1. If the battery range is below the chosen number of miles and your car is not connected to a charger, get notified to charge the car via email, SMS or Alexa notifications.

## Pre-Requisites
You need a computer with Linux OS that's always on, such as a Raspberry Pi.

The following Linux packages are required by this project.

1. Install [**jq**](https://stedolan.github.io/jq/download/), a command-line JSON processor.  Issue the following at your Raspberry Pi command prompt to install it.
```
sudo apt-get install jq
```

***Mac Note-****: If you are using a Mac, install brew first and then install jq.*

2. Install **python**.  Issue the following at your Raspberry Pi command prompt to install it.
```
sudo apt-get install python
```

3. Your computer must be setup to send mail to any email address if you want to receive email notifications.

## Installation
To install and setup the program, navigate to a directory where you want to install it and do the following:

```
# Download the code from github
git clone https://github.com/pgattu/TeslaIntegration.git

# Navigate to the newly-created directory
cd TeslaIntegration

# Change permissions to make the shell scripts executable
chmod +x *.sh

# Create the directories used by the programs
mkdir logs tesla_json

```

Your installation is complete.  You need to configure parameters before using the program.

## Configure Parameters
Edit the file `check_tesla_range.sh` using your preferred text editor.

- **BATTERY_THRESHOLD**: The battery range (in miles), below whcih you should be notified. For example, if you want to be notified when the car has less than 50 miles of range and it is not connected to a charger:

```
BATTERY_THRESHOLD="50"
```

- **EMAIL_RECIPIENTS**: 

## Schedule the Job


## Known Limitations
- Currently works with one Tesla car only.  If there is demand for checking more than one car, I will add it.  Send me a message at pgattu@gmail.com if you need this.
- I believe that the programs would work in a Mac OS X terminal. I have not tested it though. If anyone of you test it, please report findings to me at pgattu@gmail.com.
- Login information is not stored in an encrypted form yet.  However, the script is on your personal computer and you should have a firewall preventing hackers from getting into your computer. Note that all communications between the program and Tesla servers are secured by HTTPS protocol.


## TO DO
- Include link to instructions for setting up email.
