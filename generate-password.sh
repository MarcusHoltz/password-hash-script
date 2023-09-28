#!/bin/bash
########################################################
###################   NOTES    #########################
##   -  Mnemonic for remembering argon2 prefs         ##
##         13       +      4     =    17              ##
##         13 interations, 4 cores, N^17 memory       ##
########################################################
########################################################
#####          What does this script do?           #####
########################################################
## Inspired by: https://github.com/pashword/pashword ##
## This script hopes to create a hashed password     ##
## that cannot be found in a rainbow table           ##
#######################################################
## This script requires 136MB of free RAM            ##
## Be sure you have installed:                       ##
##       zip openssl argon2 gocryptfs fuse           ##
#######################################################
## What directory do you want to                     ##
## store your password files in?                     ##
#######################################################
PASSWORD_FILES_LOCATION=~/Documents/.passwords
ENCRYPTED_PASSWORD_FILES_LOCATION=~/Documents/.passencrypted-on-disk
#######################################################
#######################################################
#### == Begin script - no need to edit anything == ####
#######################################################
### Directories are created, using an array and loop:
password_directories=("$PASSWORD_FILES_LOCATION" "$ENCRYPTED_PASSWORD_FILES_LOCATION")
## Loop through password_directories, if current_directory doesnt exist, create it.
for current_directory in "${password_directories[@]}"; do
    if [ ! -d "$current_directory" ]; then
        mkdir -p "$current_directory"
    fi
done
###
#######################################################
#### Benchmark for sleep length assignments
#######################################################
### Check if VAR_MIPS_SPEED is in one of the specified ranges
### Then, assign it an appropriately opinionated value
VAR_MIPS_SPEED=$(lscpu | grep -oP "BogoMIPS:\s+\K\w+")
if ((VAR_MIPS_SPEED >= 0 && VAR_MIPS_SPEED <= 3000)); then
  ENCRYPTION_SPEED=SLOW
elif ((VAR_MIPS_SPEED >= 3001 && VAR_MIPS_SPEED <= 5999)); then
  ENCRYPTION_SPEED=OK
elif ((VAR_MIPS_SPEED >= 6000 && VAR_MIPS_SPEED <= 9000)); then
  ENCRYPTION_SPEED=GOOD
else
  ENCRYPTION_SPEED=GREAT
fi
### Define an associative array to map ENCRYPTION_SPEED opinionated values to sleep durations
declare -A sleep_times
sleep_times["SLOW"]=12
sleep_times["OK"]=6
sleep_times["GOOD"]=4
sleep_times["GREAT"]=2
###
#######################################################
### The purpose of this function is to read user input and store it in a variable specified as an argument to the function.
#######################################################
function read_data {
  local data_name="$1"
  echo -e "Enter data for $data_name to use in this hash:"
  read -s $data_name
  declare -g $data_name
}
###
#######################################################
### Do we even need directories, or is this a quick hash?
#######################################################
read -p "Do you want a quick hash?  (Y/n)   - e.g. (this will not store a password) " hashOrNot
hashOrNot="${hashOrNot:-Y}"
if [[ $hashOrNot == "Y" || $hashOrNot == "y" ]]; then
echo -e "*************************************************************\nAnswer each prompt to generate a hash.\n\n(Example for Group: seniorclass, mymom, personalstuff)"
    read_data GROUP
    read_data AGE
    read_data WEBSITE_or_SERVICE
    read_data USERNAME
    read_data ZIP_PASSWORD
    clear
        PASWRD1_full=${GROUP}${AGE}${WEBSITE_or_SERVICE}:${USERNAME}${ZIP_PASSWORD}
        PASWRD1_salt=${GROUP}${WEBSITE_or_SERVICE}${USERNAME}
    echo -e "Your hashed password is:"
        echo -n $PASWRD1_full | openssl dgst -sha3-384 | echo -n $(awk '{print $2}') | argon2 ${PASWRD1_salt} -id -e -t 13 -m 17 -p 4 -l 32 | sed 's/.*\$//'
exit;
fi
###
#######################################################
### gocrypt fuse based stacked filesystem for encrypted data at rest
#######################################################
### Check if gocrypt folder has been initialized
### Run `gocryptfs -init` if no config file exists
### Nag screen for the user along with sleep timer
### Include for errors like: already mounted, incorrect password
umount $PASSWORD_FILES_LOCATION 2>/dev/null
if [ ! -e "$ENCRYPTED_PASSWORD_FILES_LOCATION/gocryptfs.conf" ]; then
    echo -e "****************************************************\nTo begin, please encrypt your passwords directory.\n              Use a STRONG password.\nAnd write down your MASTER KEY, when it appears.\n****************************************************"
    echo -e "Enter password to encrypt/decypt your passwords folder ( $PASSWORD_FILES_LOCATION ) with:"
    gocryptfs -init $ENCRYPTED_PASSWORD_FILES_LOCATION -deterministic-names -longnamemax 63
if [ $? -ne 0 ]; then
    echo "Please re-run script. The passwords you typed did not match. The process has failed."
  exit;
else
  echo -e "\n\nBe SURE you have WRITTEN DOWN or COPIED your MASTER KEY.\n\n"
fi
sleep 1; read -t 30 -p "... I am going to wait for only 30 seconds ...             (skip ahead with ENTER)"; echo "";
fi
###
### If a gocryptfs folder has been initialized
### Mount gocryptfs folder unencrypted to a read/write location
echo -e -n "**************************************************************\n   Access your on disk gocryptfs encrypted passwords folder\n**************************************************************\nEnter Password:"
gocryptfs $ENCRYPTED_PASSWORD_FILES_LOCATION $PASSWORD_FILES_LOCATION 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Password incorrect. Please re-run script. This process has failed."
  exit;
else
    echo -e "\n"
fi
###
#######################################################
### Begin reading data from the user for a hash
#######################################################
# I wish I could restore cursor position before sending welcome banner
echo -e "**************************************************************************\n     Welcome to password generator, please follow instructions below\n**************************************************************************\nAnswer each prompt to generate a hash."
echo -e "\n(Example of a Group: seniorclass, mymom, personalstuff)"
    read_data GROUP
    read_data AGE
    read_data WEBSITE_or_SERVICE
    read_data USERNAME
    read_data ZIP_PASSWORD
        PASWRD1_full=${GROUP}${AGE}${WEBSITE_or_SERVICE}:${USERNAME}${ZIP_PASSWORD}
        PASWRD1_salt=${GROUP}${WEBSITE_or_SERVICE}${USERNAME}
echo -e "\n**********************************************************************\n   Let's pass this data into our hash  (may take up to 30 seconds)\n**********************************************************************"; sleep 1;
### If the group directory already exists compliment the user, or create the directory
if [ -d ${PASSWORD_FILES_LOCATION}/.${GROUP} ]
then
    echo "I am glad you like this script."
else
    mkdir -p ${PASSWORD_FILES_LOCATION}/.${GROUP}
fi
###
#######################################################
### Use a fifo to store data while being hashed and zipped
#######################################################
### Use a fifo (a named pipe), instead of writing to disk
### We'll be piping to stdin directly. The only gotcha is
### You have to pipe the data to fifo, to the background.
### You need this data to remains in memory for as long
### As the hashing takes before it can be encrypted.
#######################################################
### This `.txt` file created below is the plain text of the answers originally given above in the read_data function
mkfifo ${PASSWORD_FILES_LOCATION}/.${GROUP}/.password-${WEBSITE_or_SERVICE}--${USERNAME}.txt && echo -n $PASWRD1_full > ${PASSWORD_FILES_LOCATION}/.${GROUP}/.password-${WEBSITE_or_SERVICE}--${USERNAME}.txt &
sleep .5
### The file containing the finished hash is named without the `.txt`
mkfifo ${PASSWORD_FILES_LOCATION}/.${GROUP}/.password-${WEBSITE_or_SERVICE}--${USERNAME} && echo -n $PASWRD1_full | openssl dgst -sha3-384 | echo -n $(awk '{print $2}') | argon2 ${PASWRD1_salt} -id -e -t 13 -m 17 -p 4 -l 32 | sed 's/.*\$//' > ${PASSWORD_FILES_LOCATION}/.${GROUP}/.password-${WEBSITE_or_SERVICE}--${USERNAME} &
### Sleep for as long as the hash takes, to keep our file open in the pipe
sleep ${sleep_times["$ENCRYPTION_SPEED"]};
### ZIP up both files, `.txt` and hash, with the password that was chosen above.
zip --fifo --junk-paths -u -P ${ZIP_PASSWORD} ${PASSWORD_FILES_LOCATION}/.${GROUP}/.password-${WEBSITE_or_SERVICE}.zip ${PASSWORD_FILES_LOCATION}/.${GROUP}/.password-${WEBSITE_or_SERVICE}--${USERNAME}.txt ${PASSWORD_FILES_LOCATION}/.${GROUP}/.password-${WEBSITE_or_SERVICE}--${USERNAME} > /dev/null 2>&1; rm ${PASSWORD_FILES_LOCATION}/.${GROUP}/.password-${WEBSITE_or_SERVICE}--${USERNAME}.txt ${PASSWORD_FILES_LOCATION}/.${GROUP}/.password-${WEBSITE_or_SERVICE}--${USERNAME}
### Zip time is very fast
sleep .5;
### Zip is complete, files are now stored
### Remove all files used from memory
rm ${PASSWORD_FILES_LOCATION}/.${GROUP}/.password-${WEBSITE_or_SERVICE}--${USERNAME}.txt ${PASSWORD_FILES_LOCATION}/.${GROUP}/.password-${WEBSITE_or_SERVICE}--${USERNAME} > /dev/null 2>&1;
sleep .5
#######################################################
### Unmount unencypted gocryptfs folder and notify user
#######################################################
echo -e "\n*************************\n**********DONE!**********\n*************************"; sleep .5;
echo -e "An archive of your password was created.\nPlease take care to keep this gocrypt folder properly encrypted."; sleep .5;
umount $PASSWORD_FILES_LOCATION 2>/dev/null
echo -e "\nYour passwords folder is currently encrypted, and has a passworded zip\nwith 'the zip password' that you set earlier.\n"; sleep 1;
echo -e "You can access the encrypted passwords folder again with the command:"
echo -e "gocryptfs $ENCRYPTED_PASSWORD_FILES_LOCATION $PASSWORD_FILES_LOCATION"
echo -e "\nYour hashed and unhashed information is stored in:"
echo -e "${PASSWORD_FILES_LOCATION}/.${GROUP}/.password-${WEBSITE_or_SERVICE}.zip\n"
### Password is hashed one more time for display in the terminal
echo -e "Your final hashed password is:"
echo -n $PASWRD1_full | openssl dgst -sha3-384 | echo -n $(awk '{print $2}') | argon2 ${PASWRD1_salt} -id -e -t 13 -m 17 -p 4 -l 32 | sed 's/.*\$//'
