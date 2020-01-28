# TeslaIntegration
Integrate Tesla car with your home.  The programs in this project are designed to run in a Bash shell environment on a Raspberry Pi.  In theory, they should run on any Linux OS or Mac OS, but I have not tested them.

This project includes the following integrations:

1. If the battery range is below the chosen number of miles and your car is not connected to a charger, get notified to charge the car via email, SMS or Alexa notifications.

## Pre-Requisites
The following Linux packages are required by the programs in this project.

1. Install **jq**, a JSON processor for shell.  Issue the following at your Raspberry Pi command prompt.
```
sudo apt-get install jq
```

2. Install **python**.  Issue the following at your Raspberry Pi command prompt.
```
sudo apt-get install python
```

## Installation
To install and setup the programs, navigate to a directory where you want to install the programs.  Perform the following:

```
git clone https://github.com/pgattu/TeslaIntegration.git
cd TeslaIntegration
chmod +x *.sh
mkdir logs
mkdir tesla_json

```

## Configure Parameters


## Troubleshooting Installation

## Known Limitations
- Currently works with one Tesla car only.  If there is demand for this feature, I will add it.  Send me a message at pgattu@gmail.com if you need this.
- I believe that the programs would work in a Mac OS terminal. I have not tested it though. If anyone of you test it, please report findings to me at pgattu@gmail.com.
