# TeslaIntegration
Integrate Tesla car with your home.  The programs in this project are designed to run in a Bash shell environment on a Raspberry Pi.  In theory, they should run on any Linux OS or Mac OS X, but I have not tested them.

This project includes the following integrations:

1. If the battery range is below the chosen number of miles and your car is not connected to a charger, get notified to charge the car via email, SMS or Alexa notifications.

## Pre-Requisites
You need a computer with Linux OS that's always on, such as a Raspberry Pi.

The following Linux packages are required by this project.

1. Install [**jq**](https://stedolan.github.io/jq), a command-line JSON processor.  Issue the following at your Raspberry Pi command prompt to install it.
```
sudo apt-get install jq
```

***Note for Mac users*** *: You have to install HomeBrew first, and then install jq.*

2. Install **python**.  Issue the following at your Raspberry Pi command prompt to install it.
```
sudo apt-get install python
```

3. Your computer must be setup to send emails if you want to receive email notifications.

## Installation
To install and setup the program, navigate to a directory where you want to install it and do the following:

```
# Download the code from github. The below command will create a new directory
# named "TeslaIntegration" and download the code to that directory.
git clone https://github.com/pgattu/TeslaIntegration.git

# Navigate to the newly-created directory
cd TeslaIntegration

# Change permissions to make the shell scripts executable
chmod +x *.sh

```

Your installation is complete.  You need to configure parameters before using the program.

## Configure Parameters
Edit the file `check_tesla_range.sh` using your preferred text editor to setup the following parameters.

- **BATTERY_THRESHOLD** (optional): The battery range (in miles), below whcih you should be notified. If no value is provided, then a default value will be used. For example, if you want to be notified when the car has less than 50 miles of range and it is not connected to a charger, then enter:

```
BATTERY_THRESHOLD="50"
```

- **EMAIL_RECIPIENTS** (optional): Email addresses of the recipients for the notification. If no email recipients are provided, then email will not be sent. For multiple recipients, separate email address with a comma.  If you would like a SMS notification on your cell phone, then enter the email address for your cell phone.  Use https://email2sms.info to find the email address for your cell phone.  For example, if you would like to receive a email notification and SMS notification, then enter:

```
EMAIL_RECIPIENTS="my_email@gmail.com, 3105551212@tmomail.net"
```

- **EMAIL_FROM** (optional): The From address shown on the email notifications. If this is left blank, the default From address of your computer will be used. Syntax is `Name <me@email.com>`

- **NOTIFY_ME_CODE** (optional): To receive notifications on your Alexa devices, enter the Notify My Echo Access Code. If this is left blank, then Alexa notification will not be sent. For instructions on how to use Notify My Echo to receive notifications on your Alexa, see https://github.com/pgattu/TeslaIntegration/wiki/Alexa-Notification-using-Notify-Me.

- **TESLA_USER** (required): Login email for your tesla.com account

- **TESLA_PSWD** (required): Password for your tesla.com account.  Password is saved on your computer within your network.  Communications between your computer and tesla.com are secured by HTTPS.

- **SCRIPT_DIR** (required): Full path to the location of the TelsaIntegration folder. For example:

```
SCRIPT_DIR="/home/pi/TeslaIntegration"
```

Your configuration is complete.  Run a test to confirm that the program works.

## Run a Test

You can test the program by typing `./check_tesla_range.sh` at the command prompt.  You should not see any errors on your screen.  Also, check the log file located in the `logs` directory -- there shouldn't be any errors.  If there are errors, it could be because of missing pre-requisites or bad configuration.  If you cannot resolve the errors on your own, then create an issue at https://github.com/pgattu/TeslaIntegration/issues.

If there are no errors, then schedule the job in order to receive regular notifications.

## Schedule the Job
Schedule the job using cron to check for the battery range.  I recommend checking no more than a few times a day. I scheduled my checks to run twice a day.  Every time you check for battery range, the car is woken up to provide the data and that consumes battery power.

If you have solar panels that power your home's electricity, it's a good idea to charge your car during the day when solar power is available.

To add a cronjob, launch the crontab by typing `crontab -e` at the command prompt. To schedule the job to run at 9 am every day, add the following entry at the bottom of your file.  Save and close the crontab.

```
# Check whether Tesla needs to be charged every day at 9 am
0 9 * * * /path/to/TeslaIntegration/check_tesla_range.sh
```

## Upgrade to Latest Version
To upgrade to the latest version, navigate to the directory where you originally installed the TeslaIntegration programs.  Issue the following commands to upgrade your files:

```
# Navigate to the TeslaIntegration directory
cd /path/to/TeslaIntegration

# Download the latest code from github. It will overwrite all the project files.
git fetch --all
git reset --hard origin/master

# Change permissions to make the shell scripts executable
chmod +x *.sh
```

***Note*** *: The above commands will overwrite all your files.  That means, you have to [configure parameters](https://github.com/pgattu/TeslaIntegration#configure-parameters) again.*

## Known Limitations
- Currently works with one Tesla car only.  If there is demand for checking more than one car, I will add it.  Send me a message at pgattu@gmail.com if you need this.
