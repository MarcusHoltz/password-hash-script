#!/bin/bash
########################################################
###################   TO - DO   ########################
## - Turn the lengthy survey into a function          ##
## - Call the function instead of repeating survey    ##
## - Use the array to create dirs                     ##
## - Remove benchmark and test if speeds can improve  ##
## - Produce mnemonic for remembering argon2 prefs    ##
##   *  13 + 4 = 17                                   ##
##      13 interations, 4 cores, N^17 memory          ##
########################################################
########################################################
#####          What does this script do?           #####
########################################################
## Inspired by: https://github.com/pashword/pashword ##
## This script hopes to create a hashed password     ##
## that cannot be found in a rainbow table           ##
#######################################################
## This script requires 135MB of free RAM            ##
## Be sure you have installed:                       ##
##       zip openssl argon2 gocryptfs fuse           ##
#######################################################
## What directory do you want to                     ##
## store your password files in?                     ##
#######################################################
PASSWORD_FILES_LOCATION=~/Documents/.passwords
ENCRYPTED_PASSWORD_FILES_LOCATION=~/Documents/.passencrypted-on-disk
# password_directories=("$(PASSWORD_FILES_LOCATION)" "$(ENCRYPTED_PASSWORD_FILES_LOCATION)")
#######################################################
### Do we even need directories, or is this a quick hash?
read -p "Do you want a quick hash?  (Y/n)   - e.g. (this will not store a password) " hashOrNot
hashOrNot="${hashOrNot:-Y}"

if [[ $hashOrNot == "Y" || $hashOrNot == "y" ]]; then

    echo -e "(Example: seniorclass, mymom, personalstuff)\nEnter group to use for this password:"
    read -s PASWRD1_phrase
    echo -e "Great!\n"; echo -e "Now enter your age:"
    read -s PASWRD1_age
    echo -e "Is this a marketing survey, or a password generator...\n"; echo -e "Next, with the **first letter capitalized**, \nEnter the name of the **Website or Service** you're creating a password for:"
    read -s PASWRD1_service
    echo -e "\nBe sure that first character was a capital letter!";
    echo -e "This script will insert a colon now     :     \n"
    echo -e "Now enter your username, tied to the service above:"
    read -s PASWRD1_username
    echo -e "Last Step.\n\nEnter a password that you can remember:\n"
    read -s PASWRD1_password
    PASWRD1_full=${PASWRD1_phrase}${PASWRD1_age}${PASWRD1_service}:${PASWRD1_username}${PASWRD1_password}
    PASWRD1_salt=${PASWRD1_service}${PASWRD1_username}
    clear;
    echo -e "Your hashed password is:"
    echo -n $PASWRD1_full | openssl dgst -sha3-384 | echo -n $(awk '{print $2}') | argon2 ${PASWRD1_salt} -id -e -t 13 -m 17 -p 4 -l 32 | sed 's/.*\$//'
exit;

fi


if [ ! -d "$ENCRYPTED_PASSWORD_FILES_LOCATION" ]; then
    mkdir -p "$ENCRYPTED_PASSWORD_FILES_LOCATION"
fi
### Are the directories needed, created?
## Check if PASSWORD_FILES_LOCATION exists
if [ ! -d "$PASSWORD_FILES_LOCATION" ]; then
    mkdir -p "$PASSWORD_FILES_LOCATION"
fi
###
## Check if ENCRYPTED_PASSWORD_FILES_LOCATION exists
if [ ! -d "$ENCRYPTED_PASSWORD_FILES_LOCATION" ]; then
    mkdir -p "$ENCRYPTED_PASSWORD_FILES_LOCATION"
fi
###
### Directories are created, using an array and loop:
## Loop through the directories
# for current_directory in "${password_directories[@]}"; do
#     if [ ! -d "$current_directory" ]; then
#         mkdir -p "$current_directory"
#     fi
# done
###
# How fast is this machine? Benchmark for sleep length assignment
VAR_MIPS_SPEED=$(lscpu | grep -oP "BogoMIPS:\s+\K\w+")
# Check if VAR_MIPS_SPEED is in one of the specified ranges
if ((VAR_MIPS_SPEED >= 0 && VAR_MIPS_SPEED <= 5000)); then
  ENCRYPTION_SPEED=SLOW
elif ((VAR_MIPS_SPEED >= 5001 && VAR_MIPS_SPEED <= 7999)); then
  ENCRYPTION_SPEED=OK
elif ((VAR_MIPS_SPEED >= 8000 && VAR_MIPS_SPEED <= 11000)); then
  ENCRYPTION_SPEED=GOOD
else
  ENCRYPTION_SPEED=GREAT
fi
# Define an associative array to map ENCRYPTION_SPEED values to sleep durations
declare -A sleep_times
sleep_times["SLOW"]=8
sleep_times["OK"]=4
sleep_times["GOOD"]=3
sleep_times["GREAT"]=2
# Check if gocrypt folder has been initialized
if [ ! -e "$ENCRYPTED_PASSWORD_FILES_LOCATION/gocryptfs.conf" ]; then
echo -e "****************************************************\nTo begin, please encrypt your passwords directory.\n              Use a STRONG password.\nAnd write down your MASTER KEY, when it appears.\n****************************************************"
echo -e "Enter password to encrypt/decypt your passwords folder ( $PASSWORD_FILES_LOCATION ) with:"
gocryptfs -init $ENCRYPTED_PASSWORD_FILES_LOCATION -deterministic-names -longnamemax 63
if [ $? -ne 0 ]; then
    echo "Please re-run script. The passwords you typed did not match. The process has failed."
  exit;
else
  echo -e "\n\nBe SURE you have WRITTEN DOWN and TATTOOED your MASTER KEY.\n\n"
fi
sleep 1; read -t 30 -p "... I am going to wait for only 30 seconds ...             (skip ahead with ENTER)"; echo "";
fi
# mount encrypted passwords folder
# gocryptfs $ENCRYPTED_PASSWORD_FILES_LOCATION $PASSWORD_FILES_LOCATION 2>&1
umount $PASSWORD_FILES_LOCATION 2>/dev/null
echo -e -n "**************************************************************\n   Access your on disk gocryptfs encrypted passwords folder\n**************************************************************\nEnter Password:"
gocryptfs $ENCRYPTED_PASSWORD_FILES_LOCATION $PASSWORD_FILES_LOCATION 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Password incorrect. Please re-run script. This process has failed."
  exit;
else
    echo -e "\n"
fi
# I wish I could restore cursor position before sending welcome banner
echo -e "**************************************************************************\n     Welcome to password generator, please follow instructions below\n**************************************************************************"
echo -e "(Example: seniorclass, mymom, personalstuff)\nEnter group to use for this password:"
read -s PASWRD1_phrase
echo -e "Great!\n"; sleep .25; echo -e "Now enter your age:"
read -s PASWRD1_age
echo -e "Is this a marketing survey, or a password generator...\n"; sleep .25; echo -e "Next, with the **first letter capitalized**, \nEnter the name of the **Website or Service** you're creating a password for:"
read -s PASWRD1_service
echo -e "\nBe sure that first character was a capital letter!"; sleep .25
echo -e "This script will insert a colon now     :     \n"
echo -e "Now enter your username, tied to the service above:"
read -s PASWRD1_username
echo -e "Last Step.\n\nEnter a password that you can remember:"
read -s PASWRD1_password
echo -e "\nGreat!"; sleep .25; echo -e "We're done entering our information!"
sleep 1;
echo -e "\n**********************************************************************\n   Let's pass this data into our hash  (may take up to 30 seconds)\n**********************************************************************"; sleep 1;
# Make sure that directory exists, or create it
if [ -d ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase} ]
then
    echo "I am glad you like this script."
else
    mkdir -p ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}
fi
# Done with directory concerns
# Record the variables we need later on
PASWRD1_full=${PASWRD1_phrase}${PASWRD1_age}${PASWRD1_service}:${PASWRD1_username}${PASWRD1_password}
PASWRD1_salt=${PASWRD1_service}${PASWRD1_username}
# Use a fifo (a named pipe), instead of writing to disk -- we'll be piping to stdin directly. The only gotcha is you have to pipe the data to fifo, to the background, so you need this data to remains in memory for as long as the hashing takes before it can be encrypted.
# .txt file created are the plain text answers that were given above, for reference
mkfifo ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username}.txt && echo -n $PASWRD1_full > ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username}.txt &
sleep 2;
# the file containing the hash is named without the .txt
mkfifo ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username} && echo -n $PASWRD1_full | openssl dgst -sha3-384 | echo -n $(awk '{print $2}') | argon2 ${PASWRD1_salt} -id -e -t 13 -m 17 -p 4 -l 32 | sed 's/.*\$//' > ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username} &
# Sleep for as long as the hash takes, to keep our file open in the pipe
sleep ${sleep_times["$ENCRYPTION_SPEED"]};
# ZIP up both files, original and hash, with the password that was chosen above.
zip --fifo --junk-paths -u -P ${PASWRD1_password} ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}.zip ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username}.txt ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username} > /dev/null 2>&1; rm ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username}.txt ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username}
sleep 3;
# remove files in memory
rm ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username}.txt ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username} > /dev/null 2>&1;
echo ""; sleep 2;
echo -e "\n*************************\n**********DONE!**********\n*************************"; sleep .5;
echo -e "An archive of your password was created.\nPlease take care to keep this gocrypt folder properly encrypted."; sleep .5;
umount $PASSWORD_FILES_LOCATION 2>&1
echo -e "\nYour passwords folder is currently encrypted, and has a passworded zip\nwith 'the password that you can remember' you gave earlier.\n"; sleep 1;
echo -e "You can access the encrypted passwords folder again with:"
echo -e "gocryptfs $ENCRYPTED_PASSWORD_FILES_LOCATION $PASSWORD_FILES_LOCATION" 
echo -e "\nYour hashed and unhashed information is stored in:"
echo -e "${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}.zip\n"
echo -e "Your final hashed password is:"
echo -n $PASWRD1_full | openssl dgst -sha3-384 | echo -n $(awk '{print $2}') | argon2 ${PASWRD1_salt} -id -e -t 13 -m 17 -p 4 -l 32 | sed 's/.*\$//'

