#!/bin/bash
########################################################
#####          What does this script do?           #####
########################################################
## Inspired by: https://github.com/pashword/pashword ##
## This script hopes to create a hashed password     ##
## that cannot be found in a rainbow table           ##
#######################################################
## This script requires 270MB of free RAM            ##
## Be sure you have installed:                       ##
##          zip, openssl, argon2                     ##
#######################################################
## What directory do you want to                     ##
## store your password files in?                     ##
#######################################################
PASSWORD_FILES_LOCATION=~/Documents/.passwords
#######################################################
# How fast is this machine?
COMPOOTER_SPEED=$(lscpu | grep -oP "BogoMIPS:\s+\K\w+")
# Check if COMPOOTER_SPEED is in one of the specified ranges
if ((COMPOOTER_SPEED >= 0 && COMPOOTER_SPEED <= 5000)); then
  ENCRYPTION_SPEED=SLOW
elif ((COMPOOTER_SPEED >= 5001 && COMPOOTER_SPEED <= 7999)); then
  ENCRYPTION_SPEED=OK
elif ((COMPOOTER_SPEED >= 8000 && COMPOOTER_SPEED <= 11000)); then
  ENCRYPTION_SPEED=GOOD
else
  ENCRYPTION_SPEED=GREAT
fi
# Define an associative array to map ENCRYPTION_SPEED values to sleep durations
declare -A sleep_times
sleep_times["SLOW"]=30
sleep_times["OK"]=17
sleep_times["GOOD"]=8
sleep_times["GREAT"]=5
# Done with benchmark for sleep length assignment
echo -e "\n**************************************************************************\nWelcome to password generator, please follow instructions below\n**************************************************************************"
echo -e "(Example: seniorclass, mymom, personalstuff)\nEnter group to use for this password:"
read -s PASWRD1_phrase
echo -e "Great!\n"; sleep .5; echo -e "Now enter your age:"
read -s PASWRD1_age
echo -e "Is this a marketing survey, or a password generator...\n"; sleep .5; echo -e "Next, with the **first letter capitalized**, \nEnter the name of the **Website or Service** you're creating a password for:"
read -s PASWRD1_service
echo -e "\nBe sure that first character was a capital letter!"; sleep 1
echo -e "This script will insert a colon now     :     \n"
echo -e "Now enter your username, tied to the service above:"
read -s PASWRD1_username
echo -e "Last Step.\n\nEnter a password that you can remember:"
read -s PASWRD1_password
echo -e "\nGreat!"; sleep .5; echo -e "We're done entering our information!"
sleep 1;
echo -e "\n**********************************************************************\n   Let's pass this data into our hash  (may take up to 30 seconds)\n**********************************************************************"; sleep 1;
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
mkfifo ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username} && echo -n $PASWRD1_full | openssl dgst -sha3-384 | sed 's/.*[[:space:]]//' | argon2 ${PASWRD1_salt} -id -e -t 16 -m 18 -p 8 -l 32 | sed 's/.*\$//' > ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username} &
# Sleep for as long as the hash takes, to keep our file open in the pipe
sleep ${sleep_times["$ENCRYPTION_SPEED"]};
# ZIP up both files, original and hash, with the password that was chosen above.
zip --fifo --junk-paths -u -P ${PASWRD1_password} ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}.zip ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username}.txt ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username} > /dev/null 2>&1; rm ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username}.txt ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username}
sleep 3;
# remove files in memory
rm ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username}.txt ${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}--${PASWRD1_username} > /dev/null 2>&1;
echo ""; sleep 2;
echo -e "\n*************************\n**********DONE!**********\n*************************"; sleep .5;
echo -e "An archive of your password was created.\nPlease take care to properly encrypt this folder."; sleep .5;
echo -e "It is currently only encrypted as a zip,\nwith 'the password that you can remember' you gave earlier.\n"; sleep 1;
echo -e "Your hashed and unhashed information is stored in:"
echo -e "${PASSWORD_FILES_LOCATION}/.${PASWRD1_phrase}/.password-${PASWRD1_service}.zip\n"
echo -e "Your final hashed password is:"
echo -n $PASWRD1_full | openssl dgst -sha3-384 | sed 's/.*[[:space:]]//' | argon2 ${PASWRD1_salt} -id -e -t 16 -m 18 -p 8 -l 32 | sed 's/.*\$//'
