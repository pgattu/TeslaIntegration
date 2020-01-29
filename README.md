# TeslaIntegration
Integrate Tesla car with your home.  The programs in this project are designed to run in a Bash shell environment on a Raspberry Pi.  In theory, they should run on any Linux OS or Mac OS, but I have not tested them.

This project includes the following integrations:

1. If the battery range is below the chosen number of miles and your car is not connected to a charger, get notified to charge the car via email, SMS or Alexa notifications.

## Pre-Requisites
You need a Linux-based computer that's always on, like a Raspberry Pi.

The following Linux packages are required by this project.

1. Install [**jq**](https://stedolan.github.io/jq/download/), a command-line JSON processor.  Issue the following at your Raspberry Pi command prompt to install it.
```
sudo apt-get install jq
```

2. Install **python**.  Issue the following at your Raspberry Pi command prompt to install it.
```
sudo apt-get install python
```

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

## Configure Parameters


## Troubleshooting Installation

## Known Limitations
- Currently works with one Tesla car only.  If there is demand for this feature, I will add it.  Send me a message at pgattu@gmail.com if you need this.
- I believe that the programs would work in a Mac OS terminal. I have not tested it though. If anyone of you test it, please report findings to me at pgattu@gmail.com.
